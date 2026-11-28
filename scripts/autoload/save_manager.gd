extends Node

const SAVE_PATH := "user://koi_kingdom_save.json"
const TEMP_PATH := "user://koi_kingdom_save.tmp"
const BACKUP_PATH := "user://koi_kingdom_save.backup.json"
const SCHEMA_VERSION := 3


func load_game() -> Dictionary:
	var primary := _read_json_file(SAVE_PATH)
	if not primary.is_empty():
		return _normalize_data(primary)

	var backup := _read_json_file(BACKUP_PATH)
	if not backup.is_empty():
		push_warning("Save utama tidak valid. Memakai file cadangan.")
		return _normalize_data(backup)

	return _default_save()


func save_game(
	clock_state: Dictionary,
	world_state: Dictionary,
	citizen_state: Dictionary = {},
	map_state: Dictionary = {}
) -> bool:
	var data := {
		"schema_version": SCHEMA_VERSION,
		"clock": clock_state.duplicate(true),
		"world": world_state.duplicate(true),
		"citizens": citizen_state.duplicate(true),
		"map": map_state.duplicate(true),
		"meta": {
			"last_unix_timestamp": int(Time.get_unix_time_from_system())
		}
	}

	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Tidak dapat membuka file sementara save: %s" % FileAccess.get_open_error())
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()

	var save_absolute := ProjectSettings.globalize_path(SAVE_PATH)
	var temp_absolute := ProjectSettings.globalize_path(TEMP_PATH)
	var backup_absolute := ProjectSettings.globalize_path(BACKUP_PATH)
	var had_previous_save := FileAccess.file_exists(SAVE_PATH)

	if had_previous_save:
		if _is_valid_json_file(SAVE_PATH):
			if FileAccess.file_exists(BACKUP_PATH):
				var remove_backup_error := DirAccess.remove_absolute(backup_absolute)
				if remove_backup_error != OK:
					_remove_temp_file()
					push_warning("Tidak dapat membersihkan save cadangan lama: %s" % remove_backup_error)
					return false

			var backup_error := DirAccess.rename_absolute(save_absolute, backup_absolute)
			if backup_error != OK:
				_remove_temp_file()
				push_warning("Tidak dapat membuat save cadangan: %s" % backup_error)
				return false
		else:
			var remove_corrupt_error := DirAccess.remove_absolute(save_absolute)
			if remove_corrupt_error != OK:
				_remove_temp_file()
				push_warning("Tidak dapat mengganti save yang rusak: %s" % remove_corrupt_error)
				return false

	var replace_error := DirAccess.rename_absolute(temp_absolute, save_absolute)
	if replace_error != OK:
		if had_previous_save and FileAccess.file_exists(BACKUP_PATH) and not FileAccess.file_exists(SAVE_PATH):
			DirAccess.rename_absolute(backup_absolute, save_absolute)
		_remove_temp_file()
		push_warning("Tidak dapat memasang save baru: %s" % replace_error)
		return false

	return true


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)


func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed is Dictionary:
		return parsed
	return {}


func _is_valid_json_file(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed is Dictionary


func _normalize_data(raw: Dictionary) -> Dictionary:
	var normalized := _default_save()
	normalized["schema_version"] = SCHEMA_VERSION

	for section in ["clock", "world", "citizens", "map", "meta"]:
		var value: Variant = raw.get(section, {})
		if value is Dictionary:
			normalized[section] = value.duplicate(true)
		elif section == "citizens" and value is Array:
			normalized[section] = {"citizens": value.duplicate(true)}

	return normalized


func _default_save() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"clock": {
			"total_game_minutes": 7 * 60
		},
		"world": {},
		"citizens": {},
		"map": {},
		"meta": {
			"last_unix_timestamp": 0
		}
	}


func _remove_temp_file() -> void:
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))
