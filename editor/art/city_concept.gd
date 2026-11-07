extends SceneTree
## Saves the Halcyon Reach concept view (CityArt) as PNGs for review:
##   godot --headless --path . -s res://editor/art/city_concept.gd -- --out=<dir> [--scale=3]
## Writes city-concept-native.png (640 x 360) and city-concept.png (scaled up by
## whole pixels), both with a still of the rain.


func _init() -> void:
	var out: String = "user://"
	var scale: int = 3
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--scale="):
			scale = arg.trim_prefix("--scale=").to_int()
	DirAccess.make_dir_recursive_absolute(out)
	var city: GDScript = load("res://game/art_test/city_art.gd")
	var img: Image = city.compose(true)
	img.save_png(out.path_join("city-concept-native.png"))
	img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	img.save_png(out.path_join("city-concept.png"))
	print("saved to ", out)
	quit()
