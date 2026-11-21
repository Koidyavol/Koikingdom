extends Control

const BACKGROUND_COLOR := Color("#101827")
const PANEL_COLOR := Color("#1c2b40")
const ACCENT_COLOR := Color("#d8b878")
const MAIN_TEXT_COLOR := Color("#f3f1eb")
const MUTED_TEXT_COLOR := Color("#aab6c6")

var _clock_label: Label
var _status_label: Label
var _kingdom_labels: Dictionary = {}
var _save_elapsed := 0.0


func _ready() -> void:
	var saved := SaveManager.load_game()
	var clock_data: Variant = saved.get("clock", {})
	var world_data: Variant = saved.get("world", {})
	var citizen_data: Variant = saved.get("citizens", {})

	SimulationClock.apply_state(clock_data if clock_data is Dictionary else {})
	WorldManager.apply_state(world_data if world_data is Dictionary else {})
	CitizenManager.apply_state(
		citizen_data if citizen_data is Dictionary else {},
		SimulationClock.total_game_minutes
	)

	SimulationClock.day_changed.connect(WorldManager.advance_to_day)
	WorldManager.advance_to_day(SimulationClock.get_day_number())
	SimulationClock.minute_advanced.connect(CitizenManager.advance_to_minute)

	var meta: Dictionary = saved.get("meta", {})
	var last_saved_unix := int(meta.get("last_unix_timestamp", 0))
	if last_saved_unix > 0:
		SimulationClock.apply_offline_progress(last_saved_unix)

	_build_ui()
	SimulationClock.minute_advanced.connect(_refresh_ui)
	_refresh_ui()


func _process(delta: float) -> void:
	_save_elapsed += delta
	if _save_elapsed >= 30.0:
		_save_elapsed = 0.0
		_save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_game()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var heading := Label.new()
	heading.text = "KOI KINGDOM"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", ACCENT_COLOR)
	heading.add_theme_font_size_override("font_size", 28)
	layout.add_child(heading)

	_clock_label = Label.new()
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock_label.add_theme_color_override("font_color", MAIN_TEXT_COLOR)
	_clock_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(_clock_label)

	_status_label = Label.new()
	_status_label.text = "12 warga contoh menjalankan jadwal dan kebutuhan otonom"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	layout.add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	var cards := VBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 10)
	scroll.add_child(cards)

	for kingdom_id in WorldManager.KINGDOM_ORDER:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = PANEL_COLOR
		style.set_corner_radius_all(12)
		style.set_content_margin_all(14)
		panel.add_theme_stylebox_override("panel", style)
		cards.add_child(panel)

		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", MAIN_TEXT_COLOR)
		label.add_theme_font_size_override("font_size", 16)
		panel.add_child(label)
		_kingdom_labels[kingdom_id] = label

	var footer := Label.new()
	footer.text = "Save otomatis setiap 30 detik · Offline progress dibatasi 2 jam nyata"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(footer)


func _refresh_ui(_value: Variant = null) -> void:
	if _clock_label == null:
		return

	_clock_label.text = "Hari %d · %s" % [
		SimulationClock.get_day_number(),
		SimulationClock.get_clock_text()
	]

	for kingdom_id in WorldManager.KINGDOM_ORDER:
		var label: Label = _kingdom_labels.get(kingdom_id)
		if label == null:
			continue

		var kingdom := WorldManager.get_kingdom(kingdom_id)
		var citizen_summary := CitizenManager.get_summary_for_kingdom(kingdom_id)
		var activity_counts: Dictionary = citizen_summary.get("activity_counts", {})
		label.text = "%s  ·  %s\nPemimpin: %s\nPenduduk: %s  |  Emas: %s  |  Pangan: %s\nPajak: %.1f%%  |  Stabilitas: %.1f%%\nWarga contoh: %d  |  Kerja: %d  |  Tidur: %d  |  Sosial: %d" % [
			str(kingdom.get("name", kingdom_id)),
			kingdom_id.to_upper(),
			str(kingdom.get("ruler", "-")),
			str(kingdom.get("population", 0)),
			str(kingdom.get("treasury", 0)),
			str(kingdom.get("food", 0)),
			float(kingdom.get("tax_rate", 0.0)) * 100.0,
			float(kingdom.get("stability", 0.0)),
			int(citizen_summary.get("count", 0)),
			int(activity_counts.get("Bekerja", 0)),
			int(activity_counts.get("Tidur", 0)),
			int(activity_counts.get("Bersosialisasi", 0))
		]


func _save_game() -> void:
	SaveManager.save_game(
		SimulationClock.get_state(),
		WorldManager.get_state(),
		CitizenManager.get_state()
	)
