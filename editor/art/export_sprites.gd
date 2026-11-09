extends SceneTree
## Exports the code-drawn cast (ArtCast, plus the detective) as files an
## artist can edit and the game can load:
##   godot --headless --path . -s res://editor/art/export_sprites.gd -- [--out=<dir>] [--only=<id>]
##
## For each character, into <out>/<id>/:
##   <id>.aseprite  layers (props, arms, legs, body, head, lights), one frame
##                  per animation frame, a tag per animation. Open in Aseprite.
##   <id>.png       the sprite sheet: one row per animation, one cell per
##                  frame, no padding (cell = the character's canvas size).
##   <id>.json      the sheet's frames and tags, in Aseprite's own JSON format.
##   <id>.tres      a Godot SpriteFrames over <id>.png, for AnimatedSprite2D.
##
## <out> defaults to res://art/characters, so the SpriteFrames' texture path
## is right. Exporting somewhere else writes the same files; the .tres still
## points at res://art/characters/<id>/<id>.png.

const WRITER = preload("res://editor/art/aseprite_writer.gd")
const RES_BASE: String = "res://art/characters"


func _init() -> void:
	var out: String = RES_BASE
	var only: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	var cast: GDScript = load("res://game/art/art_cast.gd")
	var figure: GDScript = load("res://game/art/art_figure.gd")
	var ids: Array[String] = cast.IDS
	for id: String in ids:
		if only != "" and id != only:
			continue
		var dir: String = out.path_join(id)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir) if dir.begins_with("res://") else dir)
		var err: Error = _export(cast, figure, id, dir)
		if err != OK:
			push_error("couldn't export %s: %s" % [id, error_string(err)])
			quit(1)
			return
		print("exported ", dir)
	quit()


func _export(cast: GDScript, figure: GDScript, id: String, dir: String) -> Error:
	var size: Vector2i = cast.size(id)
	var anims: Dictionary = cast.anims(id)
	var parts: Array[String] = []
	parts.assign(figure.PARTS)

	var cols: int = 0
	for a: String in anims:
		cols = maxi(cols, anims[a])
	var sheet: Image = Image.create_empty(size.x * cols, size.y * anims.size(), false, Image.FORMAT_RGBA8)
	var frames: Array[Dictionary] = []
	var durations: Array[int] = []
	var tags: Array[Array] = []
	var json_frames: Array = []
	var json_tags: Array = []
	var tres_anims: Array[String] = []
	var tres_subs: Array[String] = []
	var row: int = 0
	for a: String in anims:
		var fps: float = cast.FPS.get(a, 4.0)
		var ms: int = roundi(1000.0 / fps)
		var first: int = frames.size()
		var refs: Array[String] = []
		for f: int in range(anims[a]):
			var layers: Dictionary = {}
			var img: Image = cast.frame(id, a, f, layers)
			if layers.is_empty():
				layers["sprite"] = img
			frames.append(layers)
			durations.append(ms)
			var cell: Vector2i = Vector2i(f * size.x, row * size.y)
			sheet.blit_rect(img, Rect2i(Vector2i.ZERO, size), cell)
			json_frames.append({
				"filename": "%s %s %d" % [id, a, f],
				"frame": {"x": cell.x, "y": cell.y, "w": size.x, "h": size.y},
				"rotated": false, "trimmed": false,
				"spriteSourceSize": {"x": 0, "y": 0, "w": size.x, "h": size.y},
				"sourceSize": {"w": size.x, "h": size.y},
				"duration": ms,
			})
			var sub: String = "%s_%d" % [a, f]
			tres_subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("1_sheet")\nregion = Rect2(%d, %d, %d, %d)\n' % [sub, cell.x, cell.y, size.x, size.y])
			refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sub)
		tags.append([a, first, frames.size() - 1])
		json_tags.append({"name": a, "from": first, "to": frames.size() - 1, "direction": "forward"})
		tres_anims.append('{\n"frames": [%s],\n"loop": true,\n"name": &"%s",\n"speed": %s\n}' % [", ".join(refs), a, str(fps)])
		row += 1

	# Only keep layers something was drawn on.
	var used: Array[String] = []
	for part: String in parts:
		for f: Dictionary in frames:
			var img: Image = f.get(part)
			if img != null and img.get_used_rect().size.x > 0:
				used.append(part)
				break
	var err: Error = WRITER.write(dir.path_join(id + ".aseprite"), size, used, frames, durations, tags)
	if err != OK:
		return err
	err = sheet.save_png(dir.path_join(id + ".png"))
	if err != OK:
		return err
	var json: Dictionary = {
		"frames": json_frames,
		"meta": {
			"app": "Tidemark export_sprites.gd", "image": id + ".png", "format": "RGBA8888",
			"size": {"w": sheet.get_width(), "h": sheet.get_height()}, "scale": "1",
			"frameTags": json_tags, "layers": used.map(func(n: String) -> Dictionary: return {"name": n, "opacity": 255, "blendMode": "normal"}),
		},
	}
	var jf: FileAccess = FileAccess.open(dir.path_join(id + ".json"), FileAccess.WRITE)
	if jf == null:
		return FileAccess.get_open_error()
	jf.store_string(JSON.stringify(json, "\t"))
	jf.close()
	var tres: String = '[gd_resource type="SpriteFrames" format=3]\n\n[ext_resource type="Texture2D" path="%s" id="1_sheet"]\n\n%s\n[resource]\nanimations = [%s]\n' % [
		RES_BASE.path_join(id).path_join(id + ".png"), "\n".join(tres_subs), ", ".join(tres_anims)]
	var tf: FileAccess = FileAccess.open(dir.path_join(id + ".tres"), FileAccess.WRITE)
	if tf == null:
		return FileAccess.get_open_error()
	tf.store_string(tres)
	tf.close()
	return OK
