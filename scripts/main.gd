extends Control

const BG := Color("#101827")
const PANEL := Color("#1c2b40")
const ACCENT := Color("#d8b878")
const TEXT_MAIN := Color("#f3f1eb")
const TEXT_MUTED := Color("#aab6c6")

var page_host: Control
var current_page := "Home"

const NPC_DATA := {
	"name": "Aiko Nakamura",
	"japanese_name": "中村 愛子",
	"gender": "Perempuan",
	"origin": "Jepang",
	"type": "NPC"
}

func _ready() -> void:
	_build_shell()
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

	if page == "Home":
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

func _build_npc_page(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Karakter NPC"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", TEXT_MAIN)
	title.add_theme_font_size_override("font_size", 27)
	parent.add_child(title)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(16)
	style.set_border_width_all(1)
	style.border_color = Color("#40516a")
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 9)
	card.add_child(details)

	var name_label := Label.new()
	name_label.text = NPC_DATA["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", ACCENT)
	name_label.add_theme_font_size_override("font_size", 23)
	details.add_child(name_label)

	var jp_label := Label.new()
	jp_label.text = NPC_DATA["japanese_name"]
	jp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jp_label.add_theme_color_override("font_color", TEXT_MAIN)
	jp_label.add_theme_font_size_override("font_size", 18)
	details.add_child(jp_label)

	for key in ["gender", "origin", "type"]:
		var info := Label.new()
		info.text = "%s: %s" % [key.capitalize(), NPC_DATA[key]]
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.add_theme_color_override("font_color", TEXT_MUTED)
		details.add_child(info)

	var portrait_hint := Label.new()
	portrait_hint.text = "Gambar NPC belum ditambahkan"
	portrait_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_hint.add_theme_color_override("font_color", TEXT_MUTED)
	parent.add_child(portrait_hint)

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
