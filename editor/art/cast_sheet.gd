extends SceneTree
## Saves review images of the cast (ArtCast):
##   godot --headless --path . -s res://editor/art/cast_sheet.gd -- --out=<dir> [--scale=4]
## Writes cast-lineup.png (everyone standing on the market's night blue, side
## by side, at whole-pixel scale), cast-anatomy.png (each character's bare
## body beside them dressed, over the 8-head chart's lines, a head apart) and
## <id>-sheet.png per character (one row per animation).


func _init() -> void:
	var out: String = "user://cast"
	var scale: int = 4
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--scale="):
			scale = arg.trim_prefix("--scale=").to_int()
	DirAccess.make_dir_recursive_absolute(out)
	var cast: GDScript = load("res://game/art_test/art_cast.gd")
	var ids: Array[String] = cast.IDS
	var px: GDScript = load("res://game/art_test/px.gd")

	# The line-up: soles on one line, a little room between each.
	var gap: int = 10
	var width: int = gap
	var height: int = 0
	for id: String in ids:
		var s: Vector2i = cast.size(id)
		width += s.x + gap
		height = maxi(height, s.y)
	var lineup: Image = Image.create_empty(width, height + 24, false, Image.FORMAT_RGBA8)
	lineup.fill(Color("111b2b"))
	lineup.fill_rect(Rect2i(0, height + 2 + 4, width, 18), Color("0b1220"))
	var x: int = gap
	for id: String in ids:
		var s: Vector2i = cast.size(id)
		var img: Image = cast.frame(id, "idle" if id != "vale" else "passenger", 0)
		lineup.blend_rect(img, Rect2i(Vector2i.ZERO, s), Vector2i(x, height + 4 - s.y))
		px.text(lineup, x + (s.x - px.text_width(id)) / 2, height + 12, id, Color("8a96a6"))
		x += s.x + gap
	_save(lineup, out.path_join("cast-lineup.png"), scale)

	# The anatomy chart: head lines a head apart up from the soles.
	var head: int = roundi(float(load("res://game/art_test/art_figure.gd").HEAD))
	var chart: Image = Image.create_empty(width * 2, height + 24, false, Image.FORMAT_RGBA8)
	chart.fill(Color("111b2b"))
	var sole: int = height + 2
	for k: int in range(9):
		chart.fill_rect(Rect2i(0, sole - k * head, chart.get_width(), 1), Color("26354b"))
	x = gap
	for id: String in ids:
		var s: Vector2i = cast.size(id)
		var bare: Image = cast.dummy(id)
		chart.blend_rect(bare, Rect2i(Vector2i.ZERO, s), Vector2i(x, height + 4 - s.y))
		var img: Image = cast.frame(id, "idle" if id != "vale" else "passenger", 0)
		chart.blend_rect(img, Rect2i(Vector2i.ZERO, s), Vector2i(x + s.x, height + 4 - s.y))
		px.text(chart, x + s.x - px.text_width(id) / 2, height + 12, id, Color("8a96a6"))
		x += s.x * 2 + gap
	_save(chart, out.path_join("cast-anatomy.png"), scale)

	for id: String in ids:
		var s: Vector2i = cast.size(id)
		var anims: Dictionary = cast.anims(id)
		var cols: int = 0
		for a: String in anims:
			cols = maxi(cols, anims[a])
		var pad: int = 4
		var sheet: Image = Image.create_empty((s.x + pad) * cols + pad, (s.y + pad) * anims.size() + pad, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("111b2b"))
		var row: int = 0
		for a: String in anims:
			for f: int in range(anims[a]):
				var img: Image = cast.frame(id, a, f)
				sheet.blend_rect(img, Rect2i(Vector2i.ZERO, s), Vector2i(pad + f * (s.x + pad), pad + row * (s.y + pad)))
			row += 1
		_save(sheet, out.path_join("%s-sheet.png" % id), scale)
	print("saved to ", out)
	quit()


func _save(img: Image, path: String, scale: int) -> void:
	img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	img.save_png(path)
