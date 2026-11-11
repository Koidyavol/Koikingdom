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

var page_host: Control
var current_page := "Home"
var chat_log: VBoxContainer
var chat_input: LineEdit
var map_dragging := false
var map_drag_last := Vector2.ZERO

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

	var npc_image := TextureRect.new()
	npc_image.custom_minimum_size = Vector2(0, 230)
	npc_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	npc_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(NPC_IMAGE_PATH):
		npc_image.texture = load(NPC_IMAGE_PATH)
	else:
		npc_image.texture = null
	details.add_child(npc_image)

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

	var talk_button := Button.new()
	talk_button.text = "Bicara"
	talk_button.custom_minimum_size = Vector2(0, 48)
	talk_button.pressed.connect(_open_aiko_chat)
	parent.add_child(talk_button)

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
