## What the sword counter shows, as a pure function: one icon per sword you
## still own, in hand first, then the ones out in the world that can come back
## (flying, embedded, lying on the floor). A sword that is destroyed or killed
## something is gone and gets no icon. Never more than the cap.
class_name SwordTally


## One entry per icon, left to right: true for a sword in hand, false for one
## that is out.
static func icons(held: int, out: int, cap: int) -> Array[bool]:
	var result: Array[bool] = []
	for i in mini(maxi(held, 0), cap):
		result.append(true)
	for i in mini(maxi(out, 0), cap - result.size()):
		result.append(false)
	return result
