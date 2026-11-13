extends Control

const BG := Color("#101827")
const PANEL := Color("#1c2b40")
const ACCENT := Color("#d8b878")
const TEXT_MAIN := Color("#f3f1eb")
const TEXT_MUTED := Color("#aab6c6")
const NPC_IMAGE_PATH := "res://assets/character/npc/aiko/file_00000000a6b48207b9d35d50cf590e0d.png"
const NPC_EYES_OPEN_PATH := "res://assets/character/npc/aiko/portrait/eyes_open.jpeg"
const NPC_EYES_HALF_CLOSED_PATH := "res://assets/character/npc/aiko/portrait/eyes_half_closed.jpeg"
const NPC_EYES_CLOSED_PATH := "res://assets/character/npc/aiko/portrait/eyes_closed.jpeg"


class DungeonBattleStage extends Control:
	var party_names: Array = []
	var party_hp: Dictionary = {}
	var party_max_hp: Dictionary = {}
	var monster_name := "Monster"
	var monster_hp := 1
	var monster_max_hp := 1
	var floor_number := 1
	var attack_flash := false
	var elapsed := 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color("#18283a"))
		draw_rect(Rect2(Vector2(0, h * 0.72), Vector2(w, h * 0.28)), Color("#263b45"))
		draw_line(Vector2(0, h * 0.72), Vector2(w, h * 0.72), Color("#71828a"), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(12, 22), "LANTAI %d" % floor_number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8c98d"))
		var party_count := mini(party_names.size(), 4)
		for i in range(party_count):
			var name := str(party_names[i])
			var x := w * (0.13 + float(i) * 0.13)
			var bob := sin(elapsed * 5.0 + float(i)) * 2.0
			var center := Vector2(x, h * 0.57 + bob)
			var tint := [Color("#6eb8df"), Color("#d98fb0"), Color("#91c98c"), Color("#c5a4e8")][i]
			_draw_hero(center, tint, attack_flash and i == int(elapsed * 2.0) % maxi(1, party_count))
			var hp := int(party_hp.get(name, 0))
			var max_hp := int(party_max_hp.get(name, 1))
			_draw_hp_bar(Vector2(x - 28, h * 0.78), 56.0, hp, max_hp, Color("#71d18b"))
			draw_string(ThemeDB.fallback_font, Vector2(x - 35, h * 0.91), name.left(9), HORIZONTAL_ALIGNMENT_LEFT, 70, 10, Color("#f1f2ed"))
		var enemy_x := w * 0.79
		var enemy_y := h * 0.55 + (sin(elapsed * 3.0) * 3.0)
		_draw_monster(Vector2(enemy_x, enemy_y), attack_flash)
		_draw_hp_bar(Vector2(w * 0.62, h * 0.78), w * 0.32, monster_hp, monster_max_hp, Color("#e36e70"))
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.62, h * 0.91), monster_name.left(20), HORIZONTAL_ALIGNMENT_LEFT, w * 0.34, 11, Color("#f1f2ed"))

	func _draw_hero(c: Vector2, tint: Color, attacking: bool) -> void:
		var shift := Vector2(13, -2) if attacking else Vector2.ZERO
		draw_circle(c + Vector2(0, -27) + shift, 10, Color("#f0c7a8"))
		draw_arc(c + Vector2(0, -29) + shift, 11, PI, TAU, 16, Color("#493a39"), 5.0)
		draw_rect(Rect2(c + Vector2(-10, -16) + shift, Vector2(20, 25)), tint)
		draw_line(c + Vector2(-6, 8) + shift, c + Vector2(-9, 22) + shift, Color("#d7dce5"), 5.0)
		draw_line(c + Vector2(6, 8) + shift, c + Vector2(9, 22) + shift, Color("#d7dce5"), 5.0)
		draw_line(c + Vector2(8, -10) + shift, c + Vector2(20, -20) + shift, Color("#d8dce5"), 3.0)

	func _draw_monster(c: Vector2, hit: bool) -> void:
		var body := Color("#c45f62") if hit else Color("#8c6cc0")
		draw_circle(c, 25, body)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-19, -15), c + Vector2(-29, -37), c + Vector2(-5, -24)]), body.lightened(0.18))
		draw_colored_polygon(PackedVector2Array([c + Vector2(19, -15), c + Vector2(29, -37), c + Vector2(5, -24)]), body.lightened(0.18))
		draw_circle(c + Vector2(-8, -3), 3, Color.WHITE)
		draw_circle(c + Vector2(8, -3), 3, Color.WHITE)
		draw_line(c + Vector2(-7, 9), c + Vector2(7, 9), Color("#392b38"), 2.0)

	func _draw_hp_bar(pos: Vector2, width: float, hp: int, max_hp: int, fill: Color) -> void:
		draw_rect(Rect2(pos, Vector2(width, 7)), Color("#10151d"))
		var ratio := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
		draw_rect(Rect2(pos + Vector2(1, 1), Vector2((width - 2.0) * ratio, 5)), fill)

var page_host: Control
var current_page := "Home"
var chat_log: VBoxContainer
var chat_input: LineEdit
var map_dragging := false
var map_drag_last := Vector2.ZERO
var academy_data: Dictionary = {"students": {}, "last_school_check": ""}
var academy_status_label: Label
var guild_data: Dictionary = {"members": {}, "completed_missions": 0, "active_mission": {}}
var guild_status_label: Label
var guild_member_select: OptionButton
var guild_mission_select: OptionButton
var guild_timer: Timer
var dungeon_timer: Timer
var dungeon_battle_timer: Timer
var dungeon_status_label: Label
var dungeon_log_label: Label
var dungeon_rewards_label: Label
var dungeon_battle_stage: DungeonBattleStage
var dungeon_data: Dictionary = {"active": {}, "completed": 0, "failed": 0, "gold": 0, "materials": 0, "history": []}

# Base attributes for the player character and all registered NPCs.
var character_stats: Dictionary = {
	"player": {"name": "Karakter Utama", "ATK": 10, "DEF": 10, "MAG": 10, "DEX": 10, "INT": 10},
	"aiko": {"name": "Aiko Nakamura", "ATK": 8, "DEF": 8, "MAG": 12, "DEX": 11, "INT": 13},
	"haruka": {"name": "Haruka Sato", "ATK": 6, "DEF": 9, "MAG": 15, "DEX": 10, "INT": 18},
	"receptionist": {"name": "Miyuki Tanaka", "ATK": 5, "DEF": 7, "MAG": 12, "DEX": 11, "INT": 16}
}

const NPC_DATA := {
	"name": "Aiko Nakamura",
	"japanese_name": "中村 愛子",
	"gender": "Perempuan",
	"origin": "Jepang",
	"type": "NPC"
}

func _ready() -> void:
	_build_shell()
	_load_academy_data()
	_load_guild_data()
	_load_dungeon_data()
	randomize()
	_check_academy_schedule()
	dungeon_timer = Timer.new()
	dungeon_timer.wait_time = 12.0
	dungeon_timer.timeout.connect(_advance_dungeon_expedition)
	dungeon_timer.autostart = true
	add_child(dungeon_timer)
	dungeon_battle_timer = Timer.new()
	dungeon_battle_timer.wait_time = 1.2
	dungeon_battle_timer.timeout.connect(_advance_dungeon_battle)
	dungeon_battle_timer.autostart = true
	add_child(dungeon_battle_timer)
	_advance_dungeon_expedition()
	var academy_timer := Timer.new()
	academy_timer.wait_time = 30.0
	academy_timer.timeout.connect(_check_academy_schedule)
	academy_timer.autostart = true
	add_child(academy_timer)
	_show_page("Home")

func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var heading := Label.new()
	heading.text = "KOI LIFE"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", ACCENT)
	heading.add_theme_font_size_override("font_size", 23)
	layout.add_child(heading)

	page_host = Control.new()
	page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(page_host)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", Color("#34445a"))
	layout.add_child(divider)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 5)
	layout.add_child(nav)

	for page in ["Map", "Job", "Karakter", "Profil"]:
		var button := Button.new()
		button.text = page
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 58)
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(_on_menu_pressed.bind(page))
		nav.add_child(button)

func _on_menu_pressed(page: String) -> void:
	_show_page(page)

func _show_page(page: String) -> void:
	current_page = page
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_host.add_child(center)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(column)

	if page == "Map":
		_build_map_page()
		return
	elif page == "Home":
		_build_home(column)
	elif page == "Karakter":
		_build_npc_page(column)
	else:
		_build_placeholder_page(column, page)

func _build_home(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Home"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", TEXT_MAIN)
	title.add_theme_font_size_override("font_size", 27)
	parent.add_child(title)

	var character_panel := PanelContainer.new()
	character_panel.custom_minimum_size = Vector2(0, 570)
	character_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(18)
	style.set_border_width_all(1)
	style.border_color = Color("#40516a")
	character_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(character_panel)

	var placeholder := CenterContainer.new()
	character_panel.add_child(placeholder)

	var hint := Label.new()
	hint.text = "GAMBAR KARAKTER UTAMA\n\nAset gambar akan ditambahkan nanti"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", TEXT_MUTED)
	hint.add_theme_font_size_override("font_size", 19)
	placeholder.add_child(hint)

	var status_row := HBoxContainer.new()
	status_row.alignment = BoxContainer.ALIGNMENT_END
	parent.add_child(status_row)
	var status_button := Button.new()
	status_button.text = "🔍"
	status_button.tooltip_text = "Lihat status karakter utama"
	status_button.custom_minimum_size = Vector2(48, 44)
	status_button.pressed.connect(_open_character_status.bind("player", "Home"))
	status_row.add_child(status_button)

func _build_npc_page(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Karakter"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", TEXT_MAIN)
	title.add_theme_font_size_override("font_size", 24)
	parent.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(14)
	style.set_border_width_all(1)
	style.border_color = Color("#40516a")
	card.add_theme_stylebox_override("panel", style)
	list.add_child(card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var npc_image := TextureRect.new()
	npc_image.custom_minimum_size = Vector2(96, 116)
	npc_image.size = Vector2(96, 116)
	npc_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	npc_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(NPC_IMAGE_PATH):
		npc_image.texture = load(NPC_IMAGE_PATH)
	row.add_child(npc_image)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 5)
	row.add_child(details)

	var name_label := Label.new()
	name_label.text = NPC_DATA["name"]
	name_label.add_theme_color_override("font_color", ACCENT)
	name_label.add_theme_font_size_override("font_size", 18)
	details.add_child(name_label)

	var jp_label := Label.new()
	jp_label.text = NPC_DATA["japanese_name"]
	jp_label.add_theme_color_override("font_color", TEXT_MAIN)
	details.add_child(jp_label)

	var info := Label.new()
	info.text = "Perempuan · Jepang · NPC"
	info.add_theme_color_override("font_color", TEXT_MUTED)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(info)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	details.add_child(action_row)
	var talk_button := Button.new()
	talk_button.text = "Bicara"
	talk_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talk_button.custom_minimum_size = Vector2(0, 38)
	talk_button.pressed.connect(_open_aiko_chat)
	action_row.add_child(talk_button)
	var status_button := Button.new()
	status_button.text = "🔍"
	status_button.tooltip_text = "Lihat status Aiko"
	status_button.custom_minimum_size = Vector2(44, 38)
	status_button.pressed.connect(_open_character_status.bind("aiko", "Karakter"))
	action_row.add_child(status_button)

	_add_teacher_npc_card(list)
	_add_receptionist_npc_card(list)


func _add_receptionist_npc_card(parent: VBoxContainer) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(16)
	style.set_border_width_all(1)
	style.border_color = Color("#40516a")
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(88, 88)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color("#34445a")
	portrait_style.set_corner_radius_all(12)
	portrait.add_theme_stylebox_override("panel", portrait_style)
	row.add_child(portrait)
	var initials := Label.new()
	initials.text = "美"
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initials.add_theme_color_override("font_color", ACCENT)
	initials.add_theme_font_size_override("font_size", 36)
	portrait.add_child(initials)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 5)
	row.add_child(details)
	var name_label := Label.new()
	name_label.text = "Miyuki Tanaka"
	name_label.add_theme_color_override("font_color", ACCENT)
	name_label.add_theme_font_size_override("font_size", 19)
	details.add_child(name_label)
	var role := Label.new()
	role.text = "田中 美雪 · Resepsionis Guild"
	role.add_theme_color_override("font_color", TEXT_MAIN)
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(role)
	var info := Label.new()
	info.text = "Mengurus pendaftaran dan papan misi petualang."
	info.add_theme_color_override("font_color", TEXT_MUTED)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(info)
	var status_button := Button.new()
	status_button.text = "🔍"
	status_button.tooltip_text = "Lihat status Miyuki"
	status_button.custom_minimum_size = Vector2(44, 42)
	status_button.pressed.connect(_open_character_status.bind("receptionist", "Karakter"))
	details.add_child(status_button)


func _add_teacher_npc_card(parent: VBoxContainer) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(16)
	style.set_border_width_all(1)
	style.border_color = Color("#40516a")
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(88, 88)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color("#34445a")
	portrait_style.set_corner_radius_all(12)
	portrait.add_theme_stylebox_override("panel", portrait_style)
	row.add_child(portrait)

	var initials := Label.new()
	initials.text = "春"
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initials.add_theme_color_override("font_color", ACCENT)
	initials.add_theme_font_size_override("font_size", 36)
	portrait.add_child(initials)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 5)
	row.add_child(details)

	var name_label := Label.new()
	name_label.text = "Haruka Sato"
	name_label.add_theme_color_override("font_color", ACCENT)
	name_label.add_theme_font_size_override("font_size", 19)
	details.add_child(name_label)

	var role := Label.new()
	role.text = "佐藤 春香 · Guru Akademi"
	role.add_theme_color_override("font_color", TEXT_MAIN)
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(role)

	var info := Label.new()
	info.text = "Pengajar dan pembimbing seluruh kelas."
	info.add_theme_color_override("font_color", TEXT_MUTED)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(info)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	details.add_child(action_row)
	var talk := Button.new()
	talk.text = "Profil Guru"
	talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talk.custom_minimum_size = Vector2(0, 42)
	talk.pressed.connect(_open_teacher_profile)
	action_row.add_child(talk)
	var status_button := Button.new()
	status_button.text = "🔍"
	status_button.tooltip_text = "Lihat status Haruka"
	status_button.custom_minimum_size = Vector2(44, 42)
	status_button.pressed.connect(_open_character_status.bind("haruka", "Karakter"))
	action_row.add_child(status_button)


func _open_character_status(character_id: String, return_page: String) -> void:
	var stats: Dictionary = character_stats.get(character_id, {})
	if stats.is_empty():
		push_warning("Status karakter tidak ditemukan: " + character_id)
		return
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_host.add_child(scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 10)
	scroll.add_child(layout)

	var title := Label.new()
	title.text = "STATUS KARAKTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 23)
	layout.add_child(title)
	var name_label := Label.new()
	name_label.text = str(stats.get("name", "Karakter"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", TEXT_MAIN)
	name_label.add_theme_font_size_override("font_size", 19)
	layout.add_child(name_label)

	for stat_name in ["ATK", "DEF", "MAG", "DEX", "INT"]:
		var stat_row := HBoxContainer.new()
		stat_row.add_theme_constant_override("separation", 8)
		layout.add_child(stat_row)
		var stat_label := Label.new()
		stat_label.text = stat_name
		stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_label.add_theme_color_override("font_color", ACCENT)
		stat_row.add_child(stat_label)
		var value_label := Label.new()
		value_label.text = str(int(stats.get(stat_name, 0)))
		value_label.add_theme_color_override("font_color", TEXT_MAIN)
		stat_row.add_child(value_label)

	var effects: Dictionary = _calculate_character_effects(stats)
	var effect_title := Label.new()
	effect_title.text = "PENGARUH STATUS"
	effect_title.add_theme_color_override("font_color", ACCENT)
	effect_title.add_theme_font_size_override("font_size", 17)
	layout.add_child(effect_title)
	for effect_text in [
		"Serangan fisik: %s" % effects["physical_attack"],
		"Pengurangan damage fisik: %s%%" % effects["physical_reduction"],
		"Kekuatan sihir: %s" % effects["magic_power"],
		"Akurasi: %s%%" % effects["accuracy"],
		"Peluang menghindar: %s%%" % effects["evasion"],
		"Peluang kritis: %s%%" % effects["critical"],
		"Maksimum MP: %s" % effects["max_mp"],
		"Bonus efek sihir: %s%%" % effects["magic_bonus"],
		"Resistensi efek status: %s%%" % effects["status_resistance"]
	]:
		var effect_label := Label.new()
		effect_label.text = effect_text
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_label.add_theme_color_override("font_color", TEXT_MAIN)
		layout.add_child(effect_label)

	var back := Button.new()
	back.text = "Kembali"
	back.custom_minimum_size = Vector2(0, 48)
	back.pressed.connect(_show_page.bind(return_page))
	layout.add_child(back)


func _make_character_stats(character_name: String, atk: int = 10, defense: int = 10, mag: int = 10, dex: int = 10, intelligence: int = 10) -> Dictionary:
	return {"name": character_name, "ATK": maxi(0, atk), "DEF": maxi(0, defense), "MAG": maxi(0, mag), "DEX": maxi(0, dex), "INT": maxi(0, intelligence)}


# Shared calculations for future combat and skill systems.
func _calculate_character_effects(stats: Dictionary) -> Dictionary:
	var atk := maxi(0, int(stats.get("ATK", 0)))
	var defense := maxi(0, int(stats.get("DEF", 0)))
	var mag := maxi(0, int(stats.get("MAG", 0)))
	var dex := maxi(0, int(stats.get("DEX", 0)))
	var intelligence := maxi(0, int(stats.get("INT", 0)))
	return {
		"physical_attack": atk,
		"physical_reduction": mini(75, int(floor(defense * 0.5))),
		"magic_power": mag + int(floor(intelligence * 0.25)),
		"accuracy": mini(100, 80 + int(floor(dex * 0.5))),
		"evasion": mini(50, int(floor(dex * 0.4))),
		"critical": mini(50, int(floor(dex * 0.25))),
		"max_mp": 20 + intelligence * 3,
		"magic_bonus": mini(75, int(floor(intelligence * 0.25))),
		"status_resistance": mini(60, int(floor(intelligence * 0.2)))
	}


func _open_teacher_profile() -> void:
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_host.add_child(center)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 12)
	center.add_child(layout)

	var title := Label.new()
	title.text = "Haruka Sato · 佐藤 春香"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 23)
	layout.add_child(title)

	var description := Label.new()
	description.text = "Guru Akademi\nBertugas mengajar dan membimbing murid kelas 1, 2, dan 3."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", TEXT_MAIN)
	layout.add_child(description)

	var back := Button.new()
	back.text = "Kembali ke Karakter"
	back.custom_minimum_size = Vector2(0, 50)
	back.pressed.connect(_show_page.bind("Karakter"))
	layout.add_child(back)


func _open_academy() -> void:
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_host.add_child(scroll)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 10)
	scroll.add_child(layout)

	var title := Label.new()
	title.text = "AKADEMI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 26)
	layout.add_child(title)

	academy_status_label = Label.new()
	academy_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	academy_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	academy_status_label.add_theme_color_override("font_color", TEXT_MUTED)
	layout.add_child(academy_status_label)
	_update_academy_status()

	_add_academy_section(layout, "GURU AKADEMI", "Haruka Sato (佐藤 春香)\nGuru yang mengajar dan membimbing seluruh tingkatan kelas.")
	_add_academy_section(layout, "RUANG KELAS", "Kelas 1 · Materi dasar\nKelas 2 · Materi lanjutan\nKelas 3 · Materi tingkat lanjut dan persiapan kelulusan")
	_add_academy_section(layout, "JADWAL & PAPAN PENGUMUMAN", "Sekolah Senin–Sabtu pukul 08.00. Minggu libur.\nUjian semester setiap 6 bulan.\nUjian kelulusan setelah 6 semester (3 tahun).")

	var registration_title := Label.new()
	registration_title.text = "PENDAFTARAN MURID"
	registration_title.add_theme_color_override("font_color", ACCENT)
	registration_title.add_theme_font_size_override("font_size", 19)
	layout.add_child(registration_title)

	var name_input := LineEdit.new()
	name_input.placeholder_text = "Masukkan nama karakter"
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(name_input)

	var register_button := Button.new()
	register_button.text = "Daftarkan ke Kelas 1"
	register_button.custom_minimum_size = Vector2(0, 48)
	register_button.pressed.connect(_register_academy_student.bind(name_input))
	layout.add_child(register_button)

	var attendance_title := Label.new()
	attendance_title.text = "DAFTAR MURID & ABSENSI"
	attendance_title.add_theme_color_override("font_color", ACCENT)
	attendance_title.add_theme_font_size_override("font_size", 19)
	layout.add_child(attendance_title)

	var student_list := VBoxContainer.new()
	student_list.name = "AcademyStudentList"
	student_list.add_theme_constant_override("separation", 8)
	layout.add_child(student_list)
	_refresh_academy_student_list(student_list)

	var back := Button.new()
	back.text = "Kembali ke Pusat Kota"
	back.custom_minimum_size = Vector2(0, 52)
	back.pressed.connect(_open_city_center)
	layout.add_child(back)


func _load_academy_data() -> void:
	var config := ConfigFile.new()
	if config.load("user://academy.cfg") == OK:
		var saved = config.get_value("academy", "data", {"students": {}, "last_school_check": ""})
		if saved is Dictionary:
			academy_data = saved
	if not academy_data.has("students") or not academy_data["students"] is Dictionary:
		academy_data["students"] = {}


func _save_academy_data() -> void:
	var config := ConfigFile.new()
	config.set_value("academy", "data", academy_data)
	var error := config.save("user://academy.cfg")
	if error != OK:
		push_warning("Gagal menyimpan data Akademi: " + str(error))


func _register_academy_student(name_input: LineEdit) -> void:
	var student_name := name_input.text.strip_edges()
	if student_name.is_empty():
		_update_academy_status("Masukkan nama karakter terlebih dahulu.")
		return
	var students: Dictionary = academy_data["students"]
	if students.has(student_name):
		_update_academy_status(student_name + " sudah terdaftar di Akademi.")
		return
	var now := Time.get_datetime_dict_from_system()
	students[student_name] = {
		"name": student_name,
		"class_level": 1,
		"semester": 1,
		"iq": 10,
		"enrolled_date": "%04d-%02d-%02d" % [now.year, now.month, now.day],
		"last_attendance": "",
		"attendance": [],
		"exam_results": [],
		"status": "Aktif"
	}
	academy_data["students"] = students
	_save_academy_data()
	name_input.clear()
	_update_academy_status(student_name + " berhasil didaftarkan ke Kelas 1.")
	_open_academy()


func _check_academy_schedule() -> void:
	if academy_data.is_empty() or not academy_data.has("students"):
		return
	var now := Time.get_datetime_dict_from_system()
	if now.hour < 8 or now.weekday == 0:
		return
	var today := "%04d-%02d-%02d" % [now.year, now.month, now.day]
	if str(academy_data.get("last_school_check", "")) == today:
		return
	var students: Dictionary = academy_data["students"]
	for student_name in students.keys():
		var student: Dictionary = students[student_name]
		if str(student.get("status", "Aktif")) != "Aktif":
			continue
		if str(student.get("last_attendance", "")) == today:
			continue
		var attendance: Array = student.get("attendance", [])
		var attendance_status := "Hadir" if now.hour < 9 else "Tidak hadir"
		attendance.append({"date": today, "status": attendance_status})
		student["attendance"] = attendance
		student["last_attendance"] = today
		if attendance_status == "Hadir":
			student["iq"] = int(student.get("iq", 10)) + 1
		students[student_name] = student
	academy_data["students"] = students
	academy_data["last_school_check"] = today
	_process_academy_exams(now)
	_save_academy_data()
	if current_page == "Map" or current_page == "Karakter":
		return
	if current_page == "Home":
		return
	if academy_status_label != null and is_instance_valid(academy_status_label):
		_update_academy_status("Kegiatan sekolah hari ini telah dicatat.")


func _process_academy_exams(now: Dictionary) -> void:
	var students: Dictionary = academy_data["students"]
	var current_date := "%04d-%02d-%02d" % [now.year, now.month, now.day]
	for student_name in students.keys():
		var student: Dictionary = students[student_name]
		if str(student.get("status", "Aktif")) != "Aktif":
			continue
		var enrolled := str(student.get("enrolled_date", current_date))
		var elapsed_months := _months_between(enrolled, current_date)
		var exam_month := int(floor(float(elapsed_months) / 6.0)) * 6
		if exam_month < 6 or exam_month <= int(student.get("last_exam_month", 0)):
			continue
		var attendance: Array = student.get("attendance", [])
		var present_count := 0
		for record in attendance:
			if str(record.get("status", "")) == "Hadir":
				present_count += 1
		var expected_days := maxi(1, int(elapsed_months * 26 / 12))
		var attendance_rate := minf(1.0, float(present_count) / float(expected_days))
		var exam_score := int(round(60.0 + attendance_rate * 40.0))
		var current_semester := int(student.get("semester", 1))
		var results: Array = student.get("exam_results", [])
		results.append({"semester": current_semester, "score": exam_score, "passed": exam_score >= 75, "date": current_date})
		student["exam_results"] = results
		student["last_exam_month"] = exam_month
		if exam_score >= 75:
			var next_semester := current_semester + 1
			student["semester"] = next_semester
			student["class_level"] = int(ceil(float(next_semester) / 2.0))
			if next_semester > 6:
				student["status"] = "Lulus"
		students[student_name] = student
	academy_data["students"] = students


func _months_between(start_date: String, end_date: String) -> int:
	var a := start_date.split("-")
	var b := end_date.split("-")
	if a.size() != 3 or b.size() != 3:
		return 0
	var months := (int(b[0]) - int(a[0])) * 12 + int(b[1]) - int(a[1])
	if int(b[2]) < int(a[2]):
		months -= 1
	return maxi(0, months)


func _refresh_academy_student_list(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	var students: Dictionary = academy_data.get("students", {})
	if students.is_empty():
		var empty := Label.new()
		empty.text = "Belum ada murid terdaftar."
		empty.add_theme_color_override("font_color", TEXT_MUTED)
		container.add_child(empty)
		return
	for student_name in students.keys():
		var student: Dictionary = students[student_name]
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = PANEL
		style.set_corner_radius_all(12)
		card.add_theme_stylebox_override("panel", style)
		container.add_child(card)
		var details := VBoxContainer.new()
		details.add_theme_constant_override("separation", 4)
		card.add_child(details)
		var title := Label.new()
		title.text = str(student_name) + " · Kelas " + str(student.get("class_level", 1))
		title.add_theme_color_override("font_color", ACCENT)
		details.add_child(title)
		var attendance: Array = student.get("attendance", [])
		var results: Array = student.get("exam_results", [])
		var status := Label.new()
		status.text = "Semester %s/6 · IQ %s · Hadir %s kali · %s" % [student.get("semester", 1), student.get("iq", 10), attendance.size(), student.get("status", "Aktif")]
		status.add_theme_color_override("font_color", TEXT_MAIN)
		details.add_child(status)
		var history := Label.new()
		history.text = "Absensi terakhir: %s" % str(student.get("last_attendance", "-"))
		history.add_theme_color_override("font_color", TEXT_MUTED)
		details.add_child(history)
		if not results.is_empty():
			var exam_label := Label.new()
			var last_exam: Dictionary = results[results.size() - 1]
			exam_label.text = "Nilai ujian terakhir: %s (%s)" % [last_exam.get("score", 0), "Lulus" if last_exam.get("passed", false) else "Belum lulus"]
			exam_label.add_theme_color_override("font_color", TEXT_MUTED)
			details.add_child(exam_label)


func _update_academy_status(message: String = "") -> void:
	if academy_status_label == null or not is_instance_valid(academy_status_label):
		return
	var now := Time.get_datetime_dict_from_system()
	var school_day := "Libur (Minggu)" if now.weekday == 0 else "Hari sekolah"
	var status_text := "%s · %02d:%02d\nSekolah mulai pukul 08.00. %s" % [school_day, now.hour, now.minute, "Minggu libur." if now.weekday == 0 else "Sekolah berjalan Senin–Sabtu."]
	academy_status_label.text = status_text if message.is_empty() else status_text + "\n" + message


func _add_academy_section(parent: VBoxContainer, heading: String, body: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(14)
	style.set_border_width_all(1)
	style.border_color = Color("#40516a")
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	panel.add_child(content)

	var title := Label.new()
	title.text = heading
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 18)
	content.add_child(title)

	var note := Label.new()
	note.text = body
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", TEXT_MAIN)
	content.add_child(note)

func _open_aiko_chat() -> void:
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_host.add_child(center)

	var chat_page := VBoxContainer.new()
	chat_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_page.add_theme_constant_override("separation", 12)
	center.add_child(chat_page)

	var title := Label.new()
	title.text = "Percakapan dengan Aiko"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 22)
	chat_page.add_child(title)

	var speech_panel := PanelContainer.new()
	speech_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	speech_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var speech_style := StyleBoxFlat.new()
	speech_style.bg_color = PANEL
	speech_style.set_corner_radius_all(14)
	speech_panel.add_theme_stylebox_override("panel", speech_style)
	chat_page.add_child(speech_panel)

	var speech_layout := VBoxContainer.new()
	speech_layout.add_theme_constant_override("separation", 10)
	speech_panel.add_child(speech_layout)

	var portrait_row := HBoxContainer.new()
	portrait_row.alignment = BoxContainer.ALIGNMENT_END
	speech_layout.add_child(portrait_row)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(104, 104)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(NPC_EYES_OPEN_PATH):
		portrait.texture = load(NPC_EYES_OPEN_PATH)
	portrait_row.add_child(portrait)
	_start_aiko_blink(portrait)

	chat_log = VBoxContainer.new()
	chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	speech_layout.add_child(chat_log)
	_add_chat_line("Aiko", "こんにちは！ Aku Aiko. Senang bertemu denganmu!")

	var input_row := HBoxContainer.new()
	chat_page.add_child(input_row)

	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Tulis pesan..."
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.text_submitted.connect(_send_chat_message)
	input_row.add_child(chat_input)

	var send_button := Button.new()
	send_button.text = "Kirim"
	send_button.pressed.connect(_send_chat_message)
	input_row.add_child(send_button)

	var back_button := Button.new()
	back_button.text = "Kembali"
	back_button.pressed.connect(_show_page.bind("Karakter"))
	chat_page.add_child(back_button)

func _start_aiko_blink(portrait: TextureRect) -> void:
	if not ResourceLoader.exists(NPC_EYES_OPEN_PATH):
		push_warning("Aiko eye portrait assets are missing.")
		return
	_animate_aiko_blink(portrait)

func _animate_aiko_blink(portrait: TextureRect) -> void:
	while is_instance_valid(portrait):
		await get_tree().create_timer(randf_range(2.8, 4.8)).timeout
		if not is_instance_valid(portrait):
			return
		if ResourceLoader.exists(NPC_EYES_HALF_CLOSED_PATH):
			portrait.texture = load(NPC_EYES_HALF_CLOSED_PATH)
		await get_tree().create_timer(0.08).timeout
		if not is_instance_valid(portrait):
			return
		if ResourceLoader.exists(NPC_EYES_CLOSED_PATH):
			portrait.texture = load(NPC_EYES_CLOSED_PATH)
		await get_tree().create_timer(0.10).timeout
		if not is_instance_valid(portrait):
			return
		if ResourceLoader.exists(NPC_EYES_HALF_CLOSED_PATH):
			portrait.texture = load(NPC_EYES_HALF_CLOSED_PATH)
		await get_tree().create_timer(0.08).timeout
		if not is_instance_valid(portrait):
			return
		portrait.texture = load(NPC_EYES_OPEN_PATH)

func _send_chat_message(message: String = "") -> void:
	var text := message.strip_edges()
	if text.is_empty() and chat_input != null:
		text = chat_input.text.strip_edges()
	if text.is_empty():
		return
	_add_chat_line("Kamu", text)
	if chat_input != null:
		chat_input.clear()

	var lower := text.to_lower()
	var reply := "そうなんだ！ Ceritakan lagi, aku ingin mendengarnya."
	if lower.contains("halo") or lower.contains("hai") or lower.contains("こんにちは"):
		reply = "Halo juga! Bagaimana harimu?"
	elif lower.contains("nama"):
		reply = "Namaku Aiko Nakamura. Kamu boleh memanggilku Aiko!"
	elif lower.contains("apa kabar") or lower.contains("kabar"):
		reply = "Aku baik, terima kasih sudah bertanya!"
	elif lower.contains("terima kasih") or lower.contains("makasih"):
		reply = "どういたしまして！ Sama-sama!"
	_add_chat_line("Aiko", reply)

func _add_chat_line(speaker: String, message: String) -> void:
	var line := Label.new()
	line.text = "%s: %s" % [speaker, message]
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_color_override("font_color", TEXT_MAIN if speaker == "Aiko" else ACCENT)
	chat_log.add_child(line)

func _build_placeholder_page(parent: VBoxContainer, page: String) -> void:
	var title := Label.new()
	title.text = page
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", TEXT_MAIN)
	title.add_theme_font_size_override("font_size", 27)
	parent.add_child(title)

	var note := Label.new()
	note.text = "Halaman %s" % page
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", TEXT_MUTED)
	note.add_theme_font_size_override("font_size", 17)
	parent.add_child(note)


const WORLD_MAP_PATH := "res://assets/map/Gemini_Generated_Image_ghfufvghfufvghfu.jpeg"

func _build_map_page() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.gui_input.connect(_on_map_scroll_input.bind(scroll))
	page_host.add_child(scroll)

	var map_root := Control.new()
	map_root.custom_minimum_size = Vector2(1536, 1536)
	map_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(map_root)

	var map_image := TextureRect.new()
	map_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_image.stretch_mode = TextureRect.STRETCH_SCALE
	map_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(WORLD_MAP_PATH):
		map_image.texture = load(WORLD_MAP_PATH)
	else:
		push_warning("World map image is missing: " + WORLD_MAP_PATH)
	map_root.add_child(map_image)

	# Hotspot is positioned in map-image coordinates, so it moves with the map while dragging.
	var city_hotspot := Button.new()
	city_hotspot.text = "PUSAT KOTA"
	city_hotspot.position = Vector2(540, 155)
	city_hotspot.size = Vector2(190, 92)
	city_hotspot.custom_minimum_size = Vector2(190, 92)
	city_hotspot.add_theme_font_size_override("font_size", 19)
	city_hotspot.add_theme_color_override("font_color", TEXT_MAIN)
	city_hotspot.pressed.connect(_open_city_center)
	map_root.add_child(city_hotspot)

	# Dungeon entrance hotspot, fixed to the world map so it follows touch-drag scrolling.
	var dungeon_hotspot := Button.new()
	dungeon_hotspot.text = "DUNGEON"
	dungeon_hotspot.position = Vector2(1050, 850)
	dungeon_hotspot.size = Vector2(190, 82)
	dungeon_hotspot.custom_minimum_size = Vector2(190, 82)
	dungeon_hotspot.add_theme_font_size_override("font_size", 19)
	dungeon_hotspot.add_theme_color_override("font_color", Color("#ffd6d6"))
	dungeon_hotspot.pressed.connect(_open_dungeon)
	map_root.add_child(dungeon_hotspot)


	var hint := Label.new()
	hint.text = "Geser peta untuk menjelajah"
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 12
	hint.offset_top = 10
	hint.offset_right = -12
	hint.add_theme_color_override("font_color", TEXT_MAIN)
	hint.add_theme_font_size_override("font_size", 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_host.add_child(hint)

	scroll.set_deferred("scroll_horizontal", 408)
	scroll.set_deferred("scroll_vertical", 408)

func _on_map_scroll_input(event: InputEvent, scroll: ScrollContainer) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			map_dragging = true
			map_drag_last = event.position
		else:
			map_dragging = false
		scroll.accept_event()
	elif event is InputEventScreenDrag:
		if map_dragging:
			var drag_delta: Vector2 = event.position - map_drag_last
			scroll.scroll_horizontal = clampi(scroll.scroll_horizontal - int(drag_delta.x), 0, maxi(0, int(scroll.get_h_scroll_bar().max_value - scroll.get_h_scroll_bar().page)))
			scroll.scroll_vertical = clampi(scroll.scroll_vertical - int(drag_delta.y), 0, maxi(0, int(scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page)))
			map_drag_last = event.position
		scroll.accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			map_dragging = true
			map_drag_last = event.position
		else:
			map_dragging = false
		scroll.accept_event()
	elif event is InputEventMouseMotion and map_dragging:
		var drag_delta: Vector2 = event.position - map_drag_last
		scroll.scroll_horizontal = maxi(0, scroll.scroll_horizontal - int(drag_delta.x))
		scroll.scroll_vertical = maxi(0, scroll.scroll_vertical - int(drag_delta.y))
		map_drag_last = event.position
		scroll.accept_event()


func _open_dungeon() -> void:
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_host.add_child(scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 10)
	scroll.add_child(layout)
	var title := Label.new()
	title.text = "DUNGEON · GUA PEMULA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#ff8585"))
	title.add_theme_font_size_override("font_size", 23)
	layout.add_child(title)
	var note := Label.new()
	note.text = "Pertarungan otomatis berlangsung secara real-time. Tuan cukup menonton."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", TEXT_MUTED)
	layout.add_child(note)
	dungeon_battle_stage = DungeonBattleStage.new()
	dungeon_battle_stage.custom_minimum_size = Vector2(0, 270)
	dungeon_battle_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(dungeon_battle_stage)
	dungeon_status_label = Label.new()
	dungeon_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dungeon_status_label.add_theme_color_override("font_color", TEXT_MAIN)
	layout.add_child(dungeon_status_label)
	var log_title := Label.new()
	log_title.text = "LOG PERTARUNGAN"
	log_title.add_theme_color_override("font_color", ACCENT)
	log_title.add_theme_font_size_override("font_size", 17)
	layout.add_child(log_title)
	dungeon_log_label = Label.new()
	dungeon_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dungeon_log_label.add_theme_color_override("font_color", TEXT_MAIN)
	layout.add_child(dungeon_log_label)
	var reward_title := Label.new()
	reward_title.text = "CATATAN DUNGEON"
	reward_title.add_theme_color_override("font_color", ACCENT)
	reward_title.add_theme_font_size_override("font_size", 17)
	layout.add_child(reward_title)
	dungeon_rewards_label = Label.new()
	dungeon_rewards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dungeon_rewards_label.add_theme_color_override("font_color", TEXT_MAIN)
	layout.add_child(dungeon_rewards_label)
	var back := Button.new()
	back.text = "Kembali ke Map"
	back.custom_minimum_size = Vector2(0, 50)
	back.pressed.connect(_show_page.bind("Map"))
	layout.add_child(back)
	_refresh_dungeon_ui()


func _load_dungeon_data() -> void:
	var config := ConfigFile.new()
	if config.load("user://dungeon.cfg") == OK:
		dungeon_data = {
			"active": config.get_value("dungeon", "active", {}),
			"completed": config.get_value("dungeon", "completed", 0),
			"failed": config.get_value("dungeon", "failed", 0),
			"gold": config.get_value("dungeon", "gold", 0),
			"materials": config.get_value("dungeon", "materials", 0),
			"history": config.get_value("dungeon", "history", [])
		}


func _save_dungeon_data() -> void:
	var config := ConfigFile.new()
	config.set_value("dungeon", "active", dungeon_data.get("active", {}))
	config.set_value("dungeon", "completed", dungeon_data.get("completed", 0))
	config.set_value("dungeon", "failed", dungeon_data.get("failed", 0))
	config.set_value("dungeon", "gold", dungeon_data.get("gold", 0))
	config.set_value("dungeon", "materials", dungeon_data.get("materials", 0))
	config.set_value("dungeon", "history", dungeon_data.get("history", []))
	config.save("user://dungeon.cfg")


func _dungeon_available_characters() -> Array:
	var roster: Array = ["Karakter Utama", "Aiko Nakamura"]
	var members: Dictionary = guild_data.get("members", {})
	var active_guild_mission: Dictionary = guild_data.get("active_mission", {})
	var busy_member := str(active_guild_mission.get("member", ""))
	for member_name in members.keys():
		if str(member_name) != busy_member and not roster.has(str(member_name)):
			roster.append(str(member_name))
	return roster


func _dungeon_character_power(character_name: String) -> int:
	for stats in character_stats.values():
		if str(stats.get("name", "")) == character_name:
			return int(stats.get("ATK", 0)) + int(stats.get("DEF", 0)) + int(stats.get("MAG", 0)) + int(stats.get("DEX", 0)) + int(stats.get("INT", 0))
	return 50


func _advance_dungeon_expedition() -> void:
	# A new party is dispatched every 12 seconds when the previous expedition has ended.
	if not dungeon_data.get("active", {}).is_empty():
		return
	var roster := _dungeon_available_characters()
	if roster.is_empty():
		return
	roster.shuffle()
	var party_size := mini(roster.size(), randi_range(1, mini(4, roster.size())))
	var new_party: Array = roster.slice(0, party_size)
	var member_hp: Dictionary = {}
	var member_max_hp: Dictionary = {}
	for member_name in new_party:
		var stats := _dungeon_get_character_stats(str(member_name))
		var max_hp := 70 + int(stats.get("DEF", 10)) * 3
		member_max_hp[str(member_name)] = max_hp
		member_hp[str(member_name)] = max_hp
	var expedition_log: Array = ["Party terbentuk: " + ", ".join(PackedStringArray(new_party)), "Memasuki Gua Pemula."]
	dungeon_data["active"] = {"party": new_party, "floor": 0, "log": expedition_log, "member_hp": member_hp, "member_max_hp": member_max_hp, "battle": {}}
	_start_dungeon_battle()
	_save_dungeon_data()
	_refresh_dungeon_ui()


func _dungeon_get_character_stats(character_name: String) -> Dictionary:
	for stats in character_stats.values():
		if str(stats.get("name", "")) == character_name:
			return stats
	return {"name": character_name, "ATK": 10, "DEF": 10, "MAG": 10, "DEX": 10, "INT": 10}


func _start_dungeon_battle() -> void:
	var active: Dictionary = dungeon_data.get("active", {})
	if active.is_empty():
		return
	var floor_number := int(active.get("floor", 0)) + 1
	var monster_pool := [
		["Slime Lumut", "Kelelawar Gua", "Tikus Batu"],
		["Goblin Pengintai", "Serigala Kelam", "Laba-laba Gua"],
		["Orc Penjaga", "Kalajengking Besi", "Ghoul Pengembara"],
		["Ksatria Tengkorak", "Mimic Rakus", "Wraith Kelabu"]
	]
	var bosses := ["Raja Goblin Grumak", "Taring Batu Gorgor", "Ratu Laba-laba Vespera", "Ksatria Kematian Dargan", "Naga Gua Vermith"]
	var monster_name := str(monster_pool[mini(floor_number - 1, 3)][randi_range(0, 2)])
	var monster_max_hp := 48 + floor_number * 24
	var monster_attack := 7 + floor_number * 3
	var monster_defense := 2 + floor_number * 2
	if floor_number >= 5:
		monster_name = bosses[randi_range(0, bosses.size() - 1)]
		monster_max_hp = 210
		monster_attack = 19
		monster_defense = 12
	active["battle"] = {"monster": monster_name, "monster_hp": monster_max_hp, "monster_max_hp": monster_max_hp, "monster_attack": monster_attack, "monster_defense": monster_defense, "round": 0}
	var log: Array = active.get("log", [])
	log.append("Lantai %d: %s muncul!" % [floor_number, monster_name])
	active["log"] = log
	dungeon_data["active"] = active
	_refresh_dungeon_ui()


func _advance_dungeon_battle() -> void:
	var active: Dictionary = dungeon_data.get("active", {})
	if active.is_empty():
		return
	var battle: Dictionary = active.get("battle", {})
	if battle.is_empty():
		_start_dungeon_battle()
		return
	var party: Array = active.get("party", [])
	var member_hp: Dictionary = active.get("member_hp", {})
	var member_max_hp: Dictionary = active.get("member_max_hp", {})
	var living: Array = []
	for member_name in party:
		if int(member_hp.get(str(member_name), 0)) > 0:
			living.append(str(member_name))
	var log: Array = active.get("log", [])
	if living.is_empty():
		log.append("Seluruh party tumbang. Ekspedisi berakhir.")
		dungeon_data["failed"] = int(dungeon_data.get("failed", 0)) + 1
		active["log"] = log
		dungeon_data["active"] = active
		_finish_dungeon_expedition(false, log)
		return
	var round_number := int(battle.get("round", 0))
	var attacker := living[round_number % living.size()]
	var attacker_stats := _dungeon_get_character_stats(attacker)
	var attack_power := int(attacker_stats.get("ATK", 10)) + int(attacker_stats.get("MAG", 10)) / 4
	var damage := maxi(1, attack_power + randi_range(0, 5) - int(battle.get("monster_defense", 0)) / 3)
	battle["monster_hp"] = maxi(0, int(battle.get("monster_hp", 1)) - damage)
	log.append("%s menyerang %s (%d damage)." % [attacker, battle.get("monster", "Monster"), damage])
	if int(battle["monster_hp"]) <= 0:
		var floor_number := int(active.get("floor", 0)) + 1
		log.append("%s dikalahkan! Party melewati lantai %d." % [battle.get("monster", "Monster"), floor_number])
		active["floor"] = floor_number
		if floor_number >= 5:
			var gold_reward := randi_range(40, 90)
			var material_reward := randi_range(1, 3)
			dungeon_data["completed"] = int(dungeon_data.get("completed", 0)) + 1
			dungeon_data["gold"] = int(dungeon_data.get("gold", 0)) + gold_reward
			dungeon_data["materials"] = int(dungeon_data.get("materials", 0)) + material_reward
			log.append("Boss terakhir tumbang! Hadiah %d emas dan %d material." % [gold_reward, material_reward])
			active["log"] = log
			dungeon_data["active"] = active
			_finish_dungeon_expedition(true, log)
			return
		active["log"] = log
		active["battle"] = {}
		dungeon_data["active"] = active
		_start_dungeon_battle()
		_save_dungeon_data()
		_refresh_dungeon_ui()
		return
	var target := living[randi_range(0, living.size() - 1)]
	var target_stats := _dungeon_get_character_stats(target)
	var monster_damage := maxi(1, int(battle.get("monster_attack", 8)) + randi_range(0, 3) - int(target_stats.get("DEF", 10)) / 3)
	member_hp[target] = maxi(0, int(member_hp.get(target, 0)) - monster_damage)
	log.append("%s membalas dan mengenai %s (%d damage)." % [battle.get("monster", "Monster"), target, monster_damage])
	battle["round"] = round_number + 1
	active["battle"] = battle
	active["member_hp"] = member_hp
	active["log"] = log
	while log.size() > 14:
		log.pop_front()
	dungeon_data["active"] = active
	_save_dungeon_data()
	_refresh_dungeon_ui()


func _finish_dungeon_expedition(victory: bool, expedition_log: Array) -> void:
	var history: Array = dungeon_data.get("history", [])
	history.append({"result": "Berhasil" if victory else "Mundur", "party": dungeon_data.get("active", {}).get("party", []), "log": expedition_log.duplicate()})
	while history.size() > 20:
		history.pop_front()
	dungeon_data["history"] = history
	dungeon_data["active"] = {}
	_save_dungeon_data()
	_refresh_dungeon_ui()


func _refresh_dungeon_ui() -> void:
	if dungeon_status_label == null or not is_instance_valid(dungeon_status_label):
		return
	var active: Dictionary = dungeon_data.get("active", {})
	if active.is_empty():
		dungeon_status_label.text = "Menunggu party berikutnya. Pemberangkatan otomatis setiap 12 detik."
		dungeon_log_label.text = "Belum ada pertarungan aktif."
		if dungeon_battle_stage != null and is_instance_valid(dungeon_battle_stage):
			dungeon_battle_stage.party_names = []
			dungeon_battle_stage.party_hp = {}
			dungeon_battle_stage.party_max_hp = {}
			dungeon_battle_stage.monster_name = "Menunggu party"
			dungeon_battle_stage.monster_hp = 0
			dungeon_battle_stage.monster_max_hp = 1
	else:
		var battle: Dictionary = active.get("battle", {})
		var party: Array = active.get("party", [])
		dungeon_status_label.text = "Party: %s\nProgres: Lantai %d / 5\nMusuh: %s" % [", ".join(PackedStringArray(party)), int(active.get("floor", 0)) + 1, battle.get("monster", "Bersiap")]
		dungeon_log_label.text = "\n".join(PackedStringArray(active.get("log", [])))
		if dungeon_battle_stage != null and is_instance_valid(dungeon_battle_stage):
			dungeon_battle_stage.party_names = party
			dungeon_battle_stage.party_hp = active.get("member_hp", {})
			dungeon_battle_stage.party_max_hp = active.get("member_max_hp", {})
			dungeon_battle_stage.monster_name = str(battle.get("monster", "Monster"))
			dungeon_battle_stage.monster_hp = int(battle.get("monster_hp", 0))
			dungeon_battle_stage.monster_max_hp = int(battle.get("monster_max_hp", 1))
			dungeon_battle_stage.floor_number = int(active.get("floor", 0)) + 1
	if dungeon_rewards_label != null and is_instance_valid(dungeon_rewards_label):
		dungeon_rewards_label.text = "Selesai: %d\nGagal: %d\nEmas: %d\nMaterial: %d" % [int(dungeon_data.get("completed", 0)), int(dungeon_data.get("failed", 0)), int(dungeon_data.get("gold", 0)), int(dungeon_data.get("materials", 0))]


func _open_city_center() -> void:
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = BG
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)
	page_host.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "PUSAT KOTA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 27)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Pilih lokasi yang ingin dikunjungi"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", TEXT_MUTED)
	layout.add_child(subtitle)

	_add_city_location_button(layout, "Akademi", "Tempat karakter belajar dan mengembangkan kemampuan.")
	_add_city_location_button(layout, "Guild Petualang", "Pusat quest, permintaan, dan aktivitas petualang.")
	_add_city_location_button(layout, "Balai Kota", "Pusat informasi dan administrasi kota.")
	_add_city_location_button(layout, "Pemukiman", "Area rumah dan kehidupan sehari-hari penduduk.")

	var back := Button.new()
	back.text = "Kembali ke Map"
	back.custom_minimum_size = Vector2(0, 54)
	back.pressed.connect(_show_page.bind("Map"))
	layout.add_child(back)


func _add_city_location_button(parent: VBoxContainer, location_name: String, description: String) -> void:
	var button := Button.new()
	button.text = location_name + "\\n" + description
	button.custom_minimum_size = Vector2(0, 82)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(_open_city_location.bind(location_name, description))
	parent.add_child(button)


func _open_city_location(location_name: String, description: String) -> void:
	if location_name == "Akademi":
		_open_academy()
		return
	if location_name == "Balai Kota":
		_open_town_hall_board()
		return
	if location_name == "Guild Petualang":
		_open_adventurer_guild()
		return

	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_host.add_child(center)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 16)
	center.add_child(layout)

	var title := Label.new()
	title.text = location_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 27)
	layout.add_child(title)

	var note := Label.new()
	note.text = description + "\\n\\nFasilitas lokasi ini akan dikembangkan berikutnya."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", TEXT_MUTED)
	layout.add_child(note)

	var back := Button.new()
	back.text = "Kembali ke Pusat Kota"
	back.custom_minimum_size = Vector2(0, 54)
	back.pressed.connect(_open_city_center)
	layout.add_child(back)



func _load_guild_data() -> void:
	var config := ConfigFile.new()
	if config.load("user://guild.cfg") == OK:
		guild_data = {
			"members": config.get_value("guild", "members", {}),
			"completed_missions": config.get_value("guild", "completed_missions", 0),
			"active_mission": config.get_value("guild", "active_mission", {})
		}


func _save_guild_data() -> void:
	var config := ConfigFile.new()
	config.set_value("guild", "members", guild_data.get("members", {}))
	config.set_value("guild", "completed_missions", guild_data.get("completed_missions", 0))
	config.set_value("guild", "active_mission", guild_data.get("active_mission", {}))
	config.save("user://guild.cfg")


func _adventurer_rank(points: int) -> String:
	if points >= 100: return "S"
	if points >= 60: return "A"
	if points >= 35: return "B"
	if points >= 20: return "C"
	if points >= 10: return "D"
	if points >= 5: return "E"
	return "F"


func _open_adventurer_guild() -> void:
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_host.add_child(scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 10)
	scroll.add_child(layout)
	var title := Label.new()
	title.text = "GUILD PETUALANG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 25)
	layout.add_child(title)
	_add_city_notice(layout, "RESEPSIONIS · MIYUKI TANAKA", "Miyuki mengurus pendaftaran anggota, menerima misi, dan memperbarui peringkat guild.")
	_add_city_notice(layout, "SISTEM RANK", "F → E → D → C → B → A → S. Poin diperoleh dari misi yang berhasil diselesaikan.")
	var registration_title := Label.new()
	registration_title.text = "PENDAFTARAN PETUALANG"
	registration_title.add_theme_color_override("font_color", ACCENT)
	registration_title.add_theme_font_size_override("font_size", 18)
	layout.add_child(registration_title)
	var name_input := LineEdit.new()
	name_input.placeholder_text = "Nama karakter yang akan didaftarkan"
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(name_input)
	var register_button := Button.new()
	register_button.text = "Daftarkan sebagai Petualang"
	register_button.custom_minimum_size = Vector2(0, 46)
	register_button.pressed.connect(_register_guild_member.bind(name_input))
	layout.add_child(register_button)
	var mission_title := Label.new()
	mission_title.text = "PAPAN MISI"
	mission_title.add_theme_color_override("font_color", ACCENT)
	mission_title.add_theme_font_size_override("font_size", 18)
	layout.add_child(mission_title)
	guild_member_select = OptionButton.new()
	guild_member_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(guild_member_select)
	guild_mission_select = OptionButton.new()
	guild_mission_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guild_mission_select.add_item("Memburu monster · 5 poin · 10 detik", 0)
	guild_mission_select.add_item("Mengumpulkan bahan · 3 poin · 8 detik", 1)
	guild_mission_select.add_item("Mengantar barang · 2 poin · 6 detik", 2)
	layout.add_child(guild_mission_select)
	var start_button := Button.new()
	start_button.text = "Mulai Misi"
	start_button.custom_minimum_size = Vector2(0, 48)
	start_button.pressed.connect(_start_guild_mission)
	layout.add_child(start_button)
	guild_status_label = Label.new()
	guild_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guild_status_label.add_theme_color_override("font_color", TEXT_MAIN)
	layout.add_child(guild_status_label)
	var leaderboard_title := Label.new()
	leaderboard_title.text = "PAPAN PERINGKAT"
	leaderboard_title.add_theme_color_override("font_color", ACCENT)
	leaderboard_title.add_theme_font_size_override("font_size", 18)
	layout.add_child(leaderboard_title)
	var leaderboard := VBoxContainer.new()
	leaderboard.name = "GuildLeaderboard"
	layout.add_child(leaderboard)
	_refresh_guild_ui(leaderboard)
	if not guild_data.get("active_mission", {}).is_empty():
		_resume_guild_mission()
	var back := Button.new()
	back.text = "Kembali ke Pusat Kota"
	back.custom_minimum_size = Vector2(0, 50)
	back.pressed.connect(_open_city_center)
	layout.add_child(back)


func _register_guild_member(name_input: LineEdit) -> void:
	var member_name := name_input.text.strip_edges()
	if member_name.is_empty():
		guild_status_label.text = "Masukkan nama karakter terlebih dahulu."
		return
	var members: Dictionary = guild_data.get("members", {})
	if members.has(member_name):
		guild_status_label.text = member_name + " sudah terdaftar di guild."
		return
	members[member_name] = {"points": 0, "completed": 0, "rank": "F"}
	guild_data["members"] = members
	_save_guild_data()
	name_input.clear()
	_refresh_guild_ui()
	guild_status_label.text = member_name + " resmi terdaftar sebagai petualang Rank F."


func _refresh_guild_ui(leaderboard: VBoxContainer = null) -> void:
	if guild_member_select != null and is_instance_valid(guild_member_select):
		guild_member_select.clear()
		var members: Dictionary = guild_data.get("members", {})
		for member_name in members.keys():
			guild_member_select.add_item(str(member_name))
		if guild_member_select.item_count > 0 and guild_member_select.selected < 0:
			guild_member_select.select(0)
	if leaderboard == null:
		var found := page_host.find_child("GuildLeaderboard", true, false)
		if found is VBoxContainer:
			leaderboard = found
	if leaderboard != null:
		for child in leaderboard.get_children():
			child.queue_free()
		var members: Dictionary = guild_data.get("members", {})
		var names: Array = members.keys()
		names.sort_custom(func(a, b): return int(members[a].get("points", 0)) > int(members[b].get("points", 0)))
		if names.is_empty():
			var empty := Label.new()
			empty.text = "Belum ada petualang terdaftar."
			empty.add_theme_color_override("font_color", TEXT_MUTED)
			leaderboard.add_child(empty)
		for index in range(names.size()):
			var member: Dictionary = members[names[index]]
			var line := Label.new()
			line.text = "%d. %s · Rank %s · %d misi selesai · %d poin" % [index + 1, names[index], member.get("rank", "F"), member.get("completed", 0), member.get("points", 0)]
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.add_theme_color_override("font_color", TEXT_MAIN)
			leaderboard.add_child(line)


func _start_guild_mission() -> void:
	if guild_member_select == null or guild_member_select.item_count == 0:
		guild_status_label.text = "Belum ada anggota. Daftarkan karakter terlebih dahulu."
		return
	if not guild_data.get("active_mission", {}).is_empty():
		guild_status_label.text = "Masih ada misi yang sedang berjalan."
		return
	var member_name := guild_member_select.get_item_text(guild_member_select.selected)
	var mission_id := guild_mission_select.selected
	var mission_names := ["Memburu monster", "Mengumpulkan bahan", "Mengantar barang"]
	var rewards := [5, 3, 2]
	var durations := [10.0, 8.0, 6.0]
	guild_data["active_mission"] = {"member": member_name, "name": mission_names[mission_id], "points": rewards[mission_id], "ends_at": Time.get_unix_time_from_system() + int(durations[mission_id])}
	_save_guild_data()
	guild_status_label.text = "%s sedang menjalankan misi: %s..." % [member_name, mission_names[mission_id]]
	guild_timer = Timer.new()
	guild_timer.one_shot = true
	guild_timer.wait_time = durations[mission_id]
	guild_timer.timeout.connect(_complete_guild_mission)
	add_child(guild_timer)
	guild_timer.start()


func _resume_guild_mission() -> void:
	var active: Dictionary = guild_data.get("active_mission", {})
	if active.is_empty():
		return
	var remaining := maxf(0.0, float(active.get("ends_at", Time.get_unix_time_from_system())) - Time.get_unix_time_from_system())
	if remaining <= 0.0:
		_complete_guild_mission()
		return
	if guild_status_label != null and is_instance_valid(guild_status_label):
		guild_status_label.text = "%s sedang menjalankan misi: %s..." % [active.get("member", ""), active.get("name", "Misi")]
	guild_timer = Timer.new()
	guild_timer.one_shot = true
	guild_timer.wait_time = remaining
	guild_timer.timeout.connect(_complete_guild_mission)
	add_child(guild_timer)
	guild_timer.start()


func _complete_guild_mission() -> void:
	var active: Dictionary = guild_data.get("active_mission", {})
	if active.is_empty():
		return
	var member_name := str(active.get("member", ""))
	var members: Dictionary = guild_data.get("members", {})
	if members.has(member_name):
		var member: Dictionary = members[member_name]
		member["points"] = int(member.get("points", 0)) + int(active.get("points", 0))
		member["completed"] = int(member.get("completed", 0)) + 1
		member["rank"] = _adventurer_rank(int(member["points"]))
		members[member_name] = member
		guild_data["members"] = members
	guild_data["completed_missions"] = int(guild_data.get("completed_missions", 0)) + 1
	guild_data["active_mission"] = {}
	_save_guild_data()
	if guild_status_label != null and is_instance_valid(guild_status_label):
		guild_status_label.text = "Misi selesai! %s mendapat hadiah poin dan progres rank diperbarui." % member_name
	_refresh_guild_ui()
	if guild_timer != null:
		guild_timer.queue_free()
		guild_timer = null


func _open_town_hall_board() -> void:
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_host.add_child(scroll)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	scroll.add_child(layout)

	var title := Label.new()
	title.text = "BALAI KOTA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 25)
	layout.add_child(title)

	var board_title := Label.new()
	board_title.text = "PAPAN INFORMASI KOTA"
	board_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_title.add_theme_color_override("font_color", TEXT_MAIN)
	board_title.add_theme_font_size_override("font_size", 19)
	layout.add_child(board_title)

	var date_label := Label.new()
	date_label.text = "Informasi diperbarui: " + Time.get_date_string_from_system()
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.add_theme_color_override("font_color", TEXT_MUTED)
	layout.add_child(date_label)

	_add_city_notice(layout, "PENGUMUMAN", "Selamat datang di pusat informasi kota. Periksa papan ini untuk mengetahui jadwal dan kabar fasilitas kota.")
	_add_city_notice(layout, "JADWAL AKADEMI", "Kegiatan belajar berlangsung setiap Senin–Sabtu mulai pukul 08.00. Hari Minggu merupakan hari libur.")
	_add_city_notice(layout, "INFORMASI FASILITAS", "Akademi sudah menyediakan pendaftaran murid dan pencatatan kegiatan belajar. Fasilitas Guild Petualang dan Pemukiman akan diumumkan saat sudah tersedia.")

	var back := Button.new()
	back.text = "Kembali ke Pusat Kota"
	back.custom_minimum_size = Vector2(0, 52)
	back.pressed.connect(_open_city_center)
	layout.add_child(back)


func _add_city_notice(parent: VBoxContainer, heading: String, message: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(13)
	style.set_border_width_all(1)
	style.border_color = Color("#40516a")
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	panel.add_child(content)

	var title := Label.new()
	title.text = heading
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 17)
	content.add_child(title)

	var body := Label.new()
	body.text = message
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", TEXT_MAIN)
	content.add_child(body)
