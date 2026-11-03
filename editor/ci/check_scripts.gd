extends SceneTree
## Loads every GDScript file outside addons/ and exits 1 if any fails to parse.
##
## Godot's own --check-only and --import exit 0 on a parse error, so CI runs this
## instead: godot --headless --path . -s res://editor/ci/check_scripts.gd


# _initialize, not _init: autoloads (Case) are registered between the
# two, and a script that names one fails to compile before then.
func _initialize() -> void:
	# Reloading this script while it runs corrupts the VM, so it skips itself.
	var own_path: String = (get_script() as Script).resource_path
	var checked: int = 0
	var failures: int = 0
	for path: String in _find_scripts("res://"):
		if path == own_path:
			continue
		checked += 1
		var script: GDScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate():
			push_error("Script failed to load: %s" % path)
			failures += 1
	print("check_scripts: %d checked, %d failed" % [checked, failures])
	quit(1 if failures > 0 else 0)


func _find_scripts(dir: String) -> Array[String]:
	var found: Array[String] = []
	for sub: String in DirAccess.get_directories_at(dir):
		if sub == "addons" or sub.begins_with("."):
			continue
		found.append_array(_find_scripts(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			found.append(dir.path_join(file))
	return found
