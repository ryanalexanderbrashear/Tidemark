extends SceneTree
## Saves the detective's frames as a sprite sheet for review:
##   godot --headless --path . -s res://editor/art/detective_sheet.gd -- --out=<file.png> [--scale=6]
## Top row idle, bottom row walk, on the market's night blue.


func _init() -> void:
	var out: String = "user://detective-sheet.png"
	var scale: int = 6
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--scale="):
			scale = arg.trim_prefix("--scale=").to_int()
	var det: GDScript = load("res://game/art_test/art_detective.gd")
	var size: Vector2i = det.SIZE
	var cols: int = det.WALK_FRAMES
	var pad: int = 4
	var sheet: Image = Image.create_empty((size.x + pad) * cols + pad, (size.y + pad) * 2 + pad, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("111b2b"))
	for f: int in range(det.IDLE_FRAMES):
		var img: Image = det.idle(f)
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, size), Vector2i(pad + f * (size.x + pad), pad))
	for f: int in range(det.WALK_FRAMES):
		var img: Image = det.walk(f)
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, size), Vector2i(pad + f * (size.x + pad), size.y + pad * 2))
	sheet.resize(sheet.get_width() * scale, sheet.get_height() * scale, Image.INTERPOLATE_NEAREST)
	sheet.save_png(out)
	print("saved ", out)
	quit()
