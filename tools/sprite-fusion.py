#!/usr/bin/env python3
"""Call the Sprite Fusion API and save what it returns into assets/art_raw/.

ART.md, pipeline step 1. One subcommand per API operation, plus two free
reads. The API contract is Sprite Fusion's public docs
(spritefusion.com/docs/pixel-art-generator/api); nothing here goes beyond it.

Every generation reserves credits and cannot be undone, so a generation is
a dry run unless --spend is passed: it prints the request it would send and
stops. CLAUDE.md: the destructive mode is the flag, and spending is the
irreversible thing here. Writing over an existing delivery also needs
--overwrite.

An input (--input) is a local image path or a Sprite Fusion asset id. A path
that exists is sent inline as a data URL; anything else is sent as an asset
id. Staged uploads (POST /uploads) are not implemented: they only matter for
inputs over the 1,000,000-byte inline limit, which a 64 px sprite never is.

Each delivery is written untouched as NAME_<index>.<ext>, plus
NAME_<index>_sheet.png for an animation's spritesheet. Every request is
appended to assets/art_raw/sprite-fusion-log.jsonl (request id, operation,
prompt, inputs, outputs), which is the record the API's agent guide asks
for and the way to find an asset id to edit or animate later.

A stream that ends before "completed" is never retried: an output may
already have been saved and charged. `assets` lists what the account holds.

The key comes from SPRITE_FUSION_API_KEY and is never printed or logged.

Usage:
    tools/sprite-fusion.py credits
    tools/sprite-fusion.py assets [--limit N]
    tools/sprite-fusion.py generate --name NAME --prompt TEXT --size {16,32,64} [--spend]
    tools/sprite-fusion.py edit --name NAME --prompt TEXT --input X [--input X ...] [--size N] [--spend]
    tools/sprite-fusion.py style-reference --name NAME --prompt TEXT --input X [...] [--size N] [--spend]
    tools/sprite-fusion.py direction-set --name NAME --input X [--size N] [--spend]
    tools/sprite-fusion.py animate --name NAME --prompt TEXT --input X [--frames N] [--colors N] [--spend]
Common to the generation subcommands: [--out DIR] [--overwrite].

Standard library only.
"""
from __future__ import annotations

import argparse
import base64
import datetime
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

API = "https://www.spritefusion.com/api/v1"
REPO = Path(__file__).resolve().parent.parent
DEFAULT_OUT = REPO / "assets" / "art_raw"
LOG_NAME = "sprite-fusion-log.jsonl"
INLINE_LIMIT_BYTES = 1_000_000  # the API's decoded inline image limit
SIZES = (16, 32, 64)
# media.spritefusion.com answers 403 to urllib's default User-Agent.
USER_AGENT = "volta-redux-sprite-fusion/1"


def _key() -> str:
    key = os.environ.get("SPRITE_FUSION_API_KEY", "")
    if not key:
        sys.exit("sprite-fusion.py: SPRITE_FUSION_API_KEY is not set")
    return key


def _request(method: str, path: str, body: dict | None = None) -> urllib.request.Request:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method)
    req.add_header("Authorization", "Bearer " + _key())
    req.add_header("User-Agent", USER_AGENT)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    return req


def _open(req: urllib.request.Request):
    try:
        return urllib.request.urlopen(req, timeout=600)
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")
        retry = e.headers.get("Retry-After")
        hint = f" (Retry-After: {retry}s)" if retry else ""
        sys.exit(f"sprite-fusion.py: HTTP {e.code}{hint}: {detail}")


def _get_json(path: str) -> dict:
    with _open(_request("GET", path)) as resp:
        return json.load(resp)


def _input(value: str) -> tuple[dict, str]:
    """The API input object, and what to record in the log in its place."""
    path = Path(value)
    if not path.is_file():
        return {"asset_id": value}, value
    raw = path.read_bytes()
    if len(raw) > INLINE_LIMIT_BYTES:
        sys.exit(f"sprite-fusion.py: {value} is over the inline limit; staged uploads are not implemented")
    mime = mimetypes.guess_type(path.name)[0] or "image/png"
    data_url = f"data:{mime};base64," + base64.b64encode(raw).decode()
    return {"data_url": data_url}, str(path)


def _events(resp):
    """Yield each JSON event from the SSE stream, skipping heartbeats."""
    lines: list[str] = []
    for raw in resp:
        line = raw.decode().rstrip("\r\n")
        if line:
            if line.startswith("data:"):
                lines.append(line[5:].lstrip())
            continue
        if lines:
            yield json.loads("\n".join(lines))
            lines = []
    if lines:
        yield json.loads("\n".join(lines))


def _download(url: str, dest: Path) -> str | None:
    """Save url to dest. Returns an error message instead of raising, so a
    failed download never loses the asset id the log needs to recover it."""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=120) as resp:
            dest.write_bytes(resp.read())
    except (urllib.error.URLError, OSError) as e:
        return f"{type(e).__name__}: {e}"
    return None


def _ext(url: str, fallback: str) -> str:
    suffix = Path(url.split("?")[0]).suffix
    return suffix or fallback


def _generate(args: argparse.Namespace, body: dict, logged_inputs: list[str]) -> None:
    out: Path = args.out
    existing = sorted(out.glob(f"{args.name}_*"))
    if existing and not args.overwrite:
        sys.exit(f"sprite-fusion.py: {existing[0]} already exists; pass --overwrite to replace deliveries named {args.name}")

    if not args.spend:
        shown = json.loads(json.dumps(body))
        for item in shown.get("inputs", []):
            if "data_url" in item:
                item["data_url"] = item["data_url"][:40] + "..."
        print(json.dumps(shown, indent=2))
        print("dry run: nothing sent. Pass --spend to send it and spend credits.")
        return

    out.mkdir(parents=True, exist_ok=True)
    record = {
        "time": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "name": args.name,
        "operation": body["operation"],
        "prompt": body.get("prompt"),
        "params": {k: v for k, v in body.items() if k not in ("operation", "prompt", "inputs")},
        "inputs": logged_inputs,
        "outputs": [],
    }
    completed = None
    try:
        with _open(_request("POST", "/generate", body)) as resp:
            for event in _events(resp):
                kind = event.get("type")
                if kind == "started":
                    record["request_id"] = event.get("request_id")
                    print(f"started {event.get('request_id')}, credits {event.get('credits')}")
                elif kind == "progress":
                    print(event.get("message", "progress"))
                elif kind == "output":
                    record["outputs"].append(_save_output(event, args.name, out))
                elif kind == "completed":
                    completed = event
    finally:
        record["completed"] = completed
        with (out / LOG_NAME).open("a") as log:
            log.write(json.dumps(record) + "\n")

    if completed is None:
        sys.exit(f"sprite-fusion.py: stream interrupted before completion. Do not retry blindly; outputs may already be saved and charged. Check `tools/sprite-fusion.py assets`. Request {record.get('request_id')}")
    got, expected = len(record["outputs"]), completed.get("output_count")
    print(f"{completed.get('status')}: {got} of {expected} outputs saved, credits {completed.get('credits')}")
    if completed.get("status") != "succeeded" or got != expected:
        sys.exit(f"sprite-fusion.py: incomplete: {completed.get('error') or 'output count mismatch'}")
    failed = [o["index"] for o in record["outputs"] if "download_error" in o]
    if failed:
        sys.exit(f"sprite-fusion.py: generated and charged, but downloads failed for {failed}. The URLs are in {LOG_NAME}.")


def _save_output(event: dict, name: str, out: Path) -> dict:
    index = event.get("index", 0)
    asset = event.get("asset", {})
    entry = {"index": index, "asset_id": asset.get("id"), "type": asset.get("type"), "url": asset.get("assetUrl")}
    if asset.get("assetUrl"):
        dest = out / f"{name}_{index}{_ext(asset['assetUrl'], '.png')}"
        error = _download(asset["assetUrl"], dest)
        if error:
            entry["download_error"] = error
            print(f"  [{index}] {asset.get('id')} download failed: {error}")
        else:
            entry["path"] = str(dest.relative_to(REPO)) if dest.is_relative_to(REPO) else str(dest)
            print(f"  [{index}] {asset.get('id')} -> {entry['path']}")
    if asset.get("spritesheetUrl"):
        sheet = out / f"{name}_{index}_sheet{_ext(asset['spritesheetUrl'], '.png')}"
        error = _download(asset["spritesheetUrl"], sheet)
        entry["spritesheet_url"] = asset["spritesheetUrl"]
        entry["frame_count"] = asset.get("frameCount")
        entry["fps"] = asset.get("fps")
        if error:
            entry["download_error"] = error
            print(f"      sheet download failed: {error}")
        else:
            entry["spritesheet_path"] = str(sheet.relative_to(REPO)) if sheet.is_relative_to(REPO) else str(sheet)
            print(f"      sheet, {asset.get('frameCount')} frames -> {entry['spritesheet_path']}")
    return entry


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("credits", help="print the credit balance (free)")
    assets = sub.add_parser("assets", help="list saved assets, newest first (free)")
    assets.add_argument("--limit", type=int, default=20)

    def generation(name: str, prompt: bool, inputs: bool, size_required: bool = False) -> argparse.ArgumentParser:
        p = sub.add_parser(name, help=f"the {name} operation (spends credits with --spend)")
        p.add_argument("--name", required=True, help="delivery filename stem, e.g. hero_idle")
        if prompt:
            p.add_argument("--prompt", required=True)
        if inputs:
            p.add_argument("--input", action="append", required=True, help="local image path or asset id; repeatable")
        p.add_argument("--out", type=Path, default=DEFAULT_OUT)
        p.add_argument("--spend", action="store_true", help="actually send the request and spend credits")
        p.add_argument("--overwrite", action="store_true", help="replace existing deliveries with this name")
        return p

    generation("generate", prompt=True, inputs=False).add_argument("--size", type=int, choices=SIZES, required=True)
    generation("edit", prompt=True, inputs=True).add_argument("--size", type=int, choices=SIZES)
    generation("style-reference", prompt=True, inputs=True).add_argument("--size", type=int, choices=SIZES)
    generation("direction-set", prompt=False, inputs=True).add_argument("--size", type=int, choices=SIZES)
    animate = generation("animate", prompt=True, inputs=True)
    animate.add_argument("--frames", type=int, help="even, 2 to 16")
    animate.add_argument("--colors", type=int, help="2 to 256")

    args = parser.parse_args()

    if args.command == "credits":
        print(_get_json("/credits").get("credits"))
        return
    if args.command == "assets":
        for asset in _get_json(f"/assets?limit={args.limit}").get("assets", []):
            print(json.dumps(asset))
        return

    body: dict = {"operation": args.command}
    if getattr(args, "prompt", None) is not None:
        body["prompt"] = args.prompt
    logged: list[str] = []
    if getattr(args, "input", None):
        pairs = [_input(v) for v in args.input]
        body["inputs"] = [p[0] for p in pairs]
        logged = [p[1] for p in pairs]
    if getattr(args, "size", None) is not None:
        body["size"] = args.size

    limits = {"edit": 9, "style-reference": 20, "direction-set": 1, "animate": 1}
    if args.command in limits and len(logged) > limits[args.command]:
        sys.exit(f"sprite-fusion.py: {args.command} takes at most {limits[args.command]} inputs")
    if args.command == "animate":
        if args.frames is not None:
            if args.frames % 2 or not 2 <= args.frames <= 16:
                sys.exit("sprite-fusion.py: --frames must be even, 2 to 16")
            body["output_frames"] = args.frames
        if args.colors is not None:
            if not 2 <= args.colors <= 256:
                sys.exit("sprite-fusion.py: --colors must be 2 to 256")
            body["colors"] = args.colors

    _generate(args, body, logged)


if __name__ == "__main__":
    main()
