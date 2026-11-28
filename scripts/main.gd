extends Control

const WORLD_VIEW_SCRIPT = preload("res://scripts/world/isometric_world.gd")

const PANEL_COLOR := Color("#1c2b40")
const ACCENT_COLOR := Color("#d8b878")
const MAIN_TEXT_COLOR := Color("#f3f1eb")
const MUTED_TEXT_COLOR := Color("#aab6c6")

var _world_view
var _clock_label: Label
var _kingdom_label: Label
var _citizen_label: Label
var _hint_label: Label
var _save_elapsed := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var saved := SaveManager.load_game()
	var clock_data: Variant = saved.get("clock", {})
	var world_data: Variant = saved.get("world", {})
	var citizen_data: Variant = saved.get("citizens", {})
	var map_data: Variant = saved.get("map", {})

	SimulationClock.apply_state(clock_data if clock_data is Dictionary else {})
	WorldManager.apply_state(world_data if world_data is Dictionary else {})
	CitizenManager.apply_state(
		citizen_data if citizen_data is Dictionary else {},
		SimulationClock.total_game_minutes
	)

	SimulationClock.minute_advanced.connect(CitizenManager.advance_to_minute)
	SimulationClock.day_changed.connect(WorldManager.advance_to_day)
	WorldManager.advance_to_day(SimulationClock.get_day_number())

	var meta: Dictionary = saved.get("meta", {})
	var last_saved_unix := int(meta.get("last_unix_timestamp", 0))
	if last_saved_unix > 0:
		SimulationClock.apply_offline_progress(last_saved_unix)

	_build_world_view(map_data if map_data is Dictionary else {})
	_build_ui()
	_refresh_ui()


func _process(delta: float) -> void:
	_save_elapsed += delta
	if _save_elapsed >= 30.0:
		_save_elapsed = 0.0
		_save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_game()


func _build_world_view(map_state: Dictionary) -> void:
	_world_view = WORLD_VIEW_SCRIPT.new()
	_world_view.position = Vector2.ZERO
	add_child(_world_view)
	_world_view.apply_state(map_state)
	_world_view.sync_citizens(CitizenManager.citizens)
	_world_view.citizen_selected.connect(_on_citizen_selected)
	SimulationClock.minute_advanced.connect(_on_minute_advanced)


func _build_ui() -> void:
	_clock_label = Label.new()
	_clock_label.add_theme_font_size_override("font_size", 22)
	_clock_label.add_theme_color_override("font_color", ACCENT_COLOR)
	_add_panel(_clock_label, 20.0, 20.0, 380.0, 115.0, false)

	_kingdom_label = Label.new()
	_kingdom_label.add_theme_font_size_override("font_size", 13)
	_kingdom_label.add_theme_color_override("font_color", MAIN_TEXT_COLOR)
	_kingdom_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_panel(_kingdom_label, -380.0, 20.0, -20.0, 190.0, true)

	_citizen_label = Label.new()
	_citizen_label.add_theme_font_size_override("font_size", 14)
	_citizen_label.add_theme_color_override("font_color", MAIN_TEXT_COLOR)
	_citizen_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_panel(_citizen_label, 20.0, -170.0, 420.0, -20.0, false, true)

	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	_hint_label.text = "Ketuk tanah untuk bergerak\nKetuk warga untuk melihat profil"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_panel(_hint_label, -350.0, -100.0, -20.0, -20.0, true, true)


func _add_panel(
	label: Label,
	left_offset: float,
	top_offset: float,
	right_offset: float,
	bottom_offset: float,
	anchor_right: bool = false,
	anchor_bottom: bool = false
) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 1.0 if anchor_right else 0.0
	panel.anchor_right = 1.0 if anchor_right else 0.0
	panel.anchor_top = 1.0 if anchor_bottom else 0.0
	panel.anchor_bottom = 1.0 if anchor_bottom else 0.0
	panel.offset_left = left_offset
	panel.offset_top = top_offset
	panel.offset_right = right_offset
	panel.offset_bottom = bottom_offset

	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)


func _on_minute_advanced(_minute: int) -> void:
	if _world_view != null:
		_world_view.sync_citizens(CitizenManager.citizens)
	_refresh_ui()


func _on_citizen_selected(citizen_id: String) -> void:
	_refresh_selected_citizen(citizen_id)


func _refresh_ui() -> void:
	if _clock_label == null:
		return
	_clock_label.text = "KOI KINGDOM\nHari %d · %s" % [
		SimulationClock.get_day_number(),
		SimulationClock.get_clock_text()
	]
	_refresh_kingdoms()
	if _world_view != null:
		_refresh_selected_citizen(_world_view.get_selected_id())


func _refresh_kingdoms() -> void:
	if _kingdom_label == null:
		return
	var lines := PackedStringArray(["Empat Kerajaan"])
	for kingdom_id in WorldManager.KINGDOM_ORDER:
		var kingdom := WorldManager.get_kingdom(kingdom_id)
		var summary := CitizenManager.get_summary_for_kingdom(kingdom_id)
		lines.append("%s · Penduduk %s · Pangan %s" % [
			str(kingdom.get("name", kingdom_id)),
			str(kingdom.get("population", 0)),
			str(kingdom.get("food", 0))
		])
		lines.append("Warga contoh: %d · Kerja %d · Tidur %d" % [
			int(summary.get("count", 0)),
			int(summary.get("activity_counts", {}).get("Bekerja", 0)),
			int(summary.get("activity_counts", {}).get("Tidur", 0))
		])
	_kingdom_label.text = "\n".join(lines)


func _refresh_selected_citizen(citizen_id: String) -> void:
	if _citizen_label == null:
		return
	if citizen_id.is_empty():
		_citizen_label.text = "Pilih warga untuk melihat profil"
		return
	for citizen in CitizenManager.citizens:
		if str(citizen.get("id", "")) == citizen_id:
			_citizen_label.text = "%s · %s\n%s · %s · %s\nAktivitas: %s\nHunger %.0f · Energy %.0f · Social %.0f" % [
				str(citizen.get("name", "Warga")),
				str(citizen.get("age", 0)),
				str(citizen.get("job", "Warga")),
				str(citizen.get("race", "Human")),
				str(citizen.get("personality", "Biasa")),
				str(citizen.get("activity", "Santai")),
				float(citizen.get("hunger", 0.0)),
				float(citizen.get("energy", 0.0)),
				float(citizen.get("social", 0.0))
			]
			return
	_citizen_label.text = "Warga tidak ditemukan"


func _save_game() -> void:
	var map_state: Dictionary = _world_view.get_state() if _world_view != null else {}
	SaveManager.save_game(
		SimulationClock.get_state(),
		WorldManager.get_state(),
		CitizenManager.get_state(),
		map_state
	)
