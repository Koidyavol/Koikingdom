extends Node

const SAVE_PATH := "user://world_state.json"
const TEMP_PATH := "user://world_state.json.tmp"
const BACKUP_PATH := "user://world_state.backup.json"
const SCHEMA_VERSION := 1

var _data: Dictionary = {}


func _ready() -> void:
	load_world()


func load_world() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		if _read_json_file(SAVE_PATH):
			_normalize_data()
			return true

		push_warning("Save utama Koi Kingdom tidak valid. Mencoba cadangan.")
		if FileAccess.file_exists(BACKUP_PATH) and _read_json_file(BACKUP_PATH):
			_normalize_data()
			save_world()
			return true

		push_warning("File save utama dan cadangan tidak dapat dibaca. Mencoba migrasi save lama.")
		var migration := _read_legacy_data()
		_data = migration["data"]
		_normalize_data()
		if bool(migration["found"]):
			return save_world()
		return false

	var migration := _read_legacy_data()
	_data = migration["data"]
	_normalize_data()
	if bool(migration["found"]):
		return save_world()
	return true


func get_section(section: String, fallback: Dictionary = {}) -> Dictionary:
	var value: Variant = _data.get(section, fallback)
	if value is Dictionary:
		return value.duplicate(true)
	return fallback.duplicate(true)


func set_section(section: String, value: Dictionary) -> bool:
	if section.strip_edges().is_empty():
		push_warning("Nama bagian save tidak boleh kosong.")
		return false

	_data[section] = value.duplicate(true)
	_data["schema_version"] = SCHEMA_VERSION
	return save_world()


func save_world() -> bool:
	_normalize_data()

	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Tidak dapat membuka file sementara save: " + str(FileAccess.get_open_error()))
		return false

	file.store_string(JSON.stringify(_data, "\t"))
	file.flush()
	file.close()

	var save_absolute := ProjectSettings.globalize_path(SAVE_PATH)
	var temp_absolute := ProjectSettings.globalize_path(TEMP_PATH)
	var backup_absolute := ProjectSettings.globalize_path(BACKUP_PATH)
	var had_previous_save := FileAccess.file_exists(SAVE_PATH)

	if had_previous_save:
		if FileAccess.file_exists(BACKUP_PATH):
			var remove_backup_error := DirAccess.remove_absolute(backup_absolute)
			if remove_backup_error != OK:
				DirAccess.remove_absolute(temp_absolute)
				push_warning("Tidak dapat membersihkan file cadangan lama: " + str(remove_backup_error))
				return false

		var backup_error := DirAccess.rename_absolute(save_absolute, backup_absolute)
		if backup_error != OK:
			DirAccess.remove_absolute(temp_absolute)
			push_warning("Tidak dapat membuat cadangan save: " + str(backup_error))
			return false

	var replace_error := DirAccess.rename_absolute(temp_absolute, save_absolute)
	if replace_error != OK:
		if had_previous_save and FileAccess.file_exists(BACKUP_PATH):
			DirAccess.rename_absolute(backup_absolute, save_absolute)
		if FileAccess.file_exists(TEMP_PATH):
			DirAccess.remove_absolute(temp_absolute)
		push_warning("Tidak dapat memasang file save baru: " + str(replace_error))
		return false

	return true


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func _read_json_file(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if not (parsed is Dictionary):
		return false

	_data = parsed
	return true


func _normalize_data() -> void:
	if _data.is_empty():
		_data = _default_data()

	_data["schema_version"] = SCHEMA_VERSION

	var defaults := _default_data()
	for section in ["academy", "guild", "dungeon"]:
		if not (_data.get(section) is Dictionary):
			_data[section] = defaults[section].duplicate(true)


func _default_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"academy": {
			"students": {},
			"last_school_check": ""
		},
		"guild": {
			"members": {},
			"completed_missions": 0,
			"active_mission": {}
		},
		"dungeon": {
			"active": {},
			"completed": 0,
			"failed": 0,
			"gold": 0,
			"materials": 0,
			"history": []
		}
	}


func _read_legacy_data() -> Dictionary:
	var migrated := _default_data()
	var found := false

	var academy_config := ConfigFile.new()
	if academy_config.load("user://academy.cfg") == OK:
		var academy_saved: Variant = academy_config.get_value("academy", "data", {})
		if academy_saved is Dictionary:
			migrated["academy"] = academy_saved.duplicate(true)
			found = true

	var guild_config := ConfigFile.new()
	if guild_config.load("user://guild.cfg") == OK:
		var guild_saved := {
			"members": guild_config.get_value("guild", "members", {}),
			"completed_missions": guild_config.get_value("guild", "completed_missions", 0),
			"active_mission": guild_config.get_value("guild", "active_mission", {})
		}
		if guild_saved["members"] is Dictionary and guild_saved["active_mission"] is Dictionary:
			migrated["guild"] = guild_saved
			found = true

	var dungeon_config := ConfigFile.new()
	if dungeon_config.load("user://dungeon.cfg") == OK:
		var dungeon_saved := {
			"active": dungeon_config.get_value("dungeon", "active", {}),
			"completed": dungeon_config.get_value("dungeon", "completed", 0),
			"failed": dungeon_config.get_value("dungeon", "failed", 0),
			"gold": dungeon_config.get_value("dungeon", "gold", 0),
			"materials": dungeon_config.get_value("dungeon", "materials", 0),
			"history": dungeon_config.get_value("dungeon", "history", [])
		}
		if dungeon_saved["active"] is Dictionary and dungeon_saved["history"] is Array:
			migrated["dungeon"] = dungeon_saved
			found = true

	return {
		"data": migrated,
		"found": found
	}
