class_name CastSprite
extends Sprite2D
## One of the cast (ArtCast) as a sprite: their animations drawn once, then
## shown by time (idle, work, passenger) or by distance walked (walk, run, so
## the planted foot stays still on the ground). Placed by the feet.

## Who this is (an ArtCast id).
var id: String
## The figure's frame size.
var frame_size: Vector2i
var _frames: Dictionary[String, Array] = {}


func _init(cast_id: String, anims: Array[String]) -> void:
	id = cast_id
	centered = false
	frame_size = ArtCast.size(id)
	for anim: String in anims:
		var list: Array[ImageTexture] = []
		for img: Image in ArtCast.frames(id, anim):
			list.append(ImageTexture.create_from_image(img))
		_frames[anim] = list
	texture = _frames[anims[0]][0]


func has_anim(anim: String) -> bool:
	return _frames.has(anim)


func frame_count(anim: String) -> int:
	return _frames[anim].size()


## Shows frame `f` of `anim` (wrapping).
func show_frame(anim: String, f: int) -> void:
	var list: Array = _frames[anim]
	texture = list[posmod(f, list.size())]


## Shows `anim` at its own pace (ArtCast.FPS), `offset` frames along so
## neighbours don't breathe together.
func play_at(anim: String, time: float, offset: int = 0) -> void:
	show_frame(anim, int(time * ArtCast.FPS[anim]) + offset)


## Shows the frame of a walk or run cycle for `distance` walked, one stride
## per cycle.
func step_at(anim: String, distance: float, stride: float) -> void:
	var n: int = frame_count(anim)
	show_frame(anim, int(distance / (stride / float(n))))


## Stands the figure with its feet at (`x`, `feet_y`) in the room, seen from
## `cam_x`. The sprites' last two rows are below the shoe line.
func place(x: float, feet_y: float, cam_x: float) -> void:
	position = Vector2(floorf(x - cam_x - frame_size.x * 0.5), floorf(feet_y) - frame_size.y + 2)
