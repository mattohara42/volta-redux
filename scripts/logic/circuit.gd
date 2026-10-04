## Act 3's current, as a rule. Pure, so the tests can reach it.
##
## Pieces are numbered. A link joins two pieces: an embedded sword joins every
## piece its blade touches, which is how a sword bridges an insulating seam
## (`SPEC.md` → *Conduct*). Current runs from the sources along links, and
## every piece it reaches is live. Wood never appears here: it is not a piece,
## so it carries nothing.
class_name Circuit


## Every piece reachable from any source along `links`, as a set (the keys of
## the returned dictionary). `links` is an array of two-element arrays.
static func live(sources: Array, links: Array) -> Dictionary:
	var neighbours := {}
	for link in links:
		var a: int = link[0]
		var b: int = link[1]
		neighbours.get_or_add(a, []).append(b)
		neighbours.get_or_add(b, []).append(a)
	var seen := {}
	var queue: Array = sources.duplicate()
	for source in sources:
		seen[source] = true
	while not queue.is_empty():
		var piece: int = queue.pop_back()
		for next in neighbours.get(piece, []):
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return seen


## Whether current from `from` reaches `to`. The generator is shorted when its
## own output reaches its own return.
static func connected(from: int, to: int, links: Array) -> bool:
	return live([from], links).has(to)


## The links one embedded sword makes: it joins every piece it touches to each
## other, so a sword across a seam joins the two sides and a sword touching
## three pieces joins all three.
static func links_through(touching: Array) -> Array:
	var out: Array = []
	for i in touching.size():
		for j in range(i + 1, touching.size()):
			out.append([touching[i], touching[j]])
	return out
