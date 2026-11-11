extends Control

const BG := Color("#101827")
const PANEL := Color("#1c2b40")
const ACCENT := Color("#d8b878")
const TEXT_MAIN := Color("#f3f1eb")
const TEXT_MUTED := Color("#aab6c6")
const PLAYER_SPRITE_PATH := "res://assets/character/koi_chibi_sprite_transparent-1.png"
const NPC_IMAGE_PATH := "res://assets/character/npc/aiko/file_00000000a6b48207b9d35d50cf590e0d.png"
const NPC_EYES_OPEN_PATH := "res://assets/character/npc/aiko/portrait/eyes_open.jpeg"
const NPC_EYES_HALF_CLOSED_PATH := "res://assets/character/npc/aiko/portrait/eyes_half_closed.jpeg"
const NPC_EYES_CLOSED_PATH := "res://assets/character/npc/aiko/portrait/eyes_closed.jpeg"

var page_host: Control
var current_page := "Home"
var chat_log: VBoxContainer
var chat_input: LineEdit
var city_player: TextureRect
var city_move_dir := Vector2.ZERO
var city_anim_time := 0.0
var city_walk_frame := 0
var city_walk_direction := "down"
var city_world: Control

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
const WORLD_TILESET_PATH := "res://assets/tileset/IMG_20261111_185922.jpg"

func _build_map_page() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	page_host.add_child(scroll)

	var map_root := Control.new()
	map_root.custom_minimum_size = Vector2(1536, 1536)
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

	var city_button := Button.new()
	city_button.text = "PUSAT KOTA\nMasuk"
	city_button.position = Vector2(648, 715)
	city_button.custom_minimum_size = Vector2(240, 106)
	city_button.size = Vector2(240, 106)
	city_button.add_theme_font_size_override("font_size", 22)
	city_button.pressed.connect(_open_city_center)
	map_root.add_child(city_button)

	var hint := Label.new()
	hint.text = "Geser peta untuk menjelajah • Ketuk Pusat Kota untuk masuk"
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

func _open_city_center() -> void:
	for child in page_host.get_children():
		page_host.remove_child(child)
		child.queue_free()
	_build_city_center()

func _build_city_center() -> void:
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 8)
	page_host.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var back_button := Button.new()
	back_button.text = "← Kembali ke Map"
	back_button.pressed.connect(_show_page.bind("Map"))
	header.add_child(back_button)

	var title := Label.new()
	title.text = "PUSAT KOTA"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)

	city_world = Control.new()
	city_world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	city_world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	city_world.custom_minimum_size = Vector2(0, 420)
	city_world.clip_contents = true
	layout.add_child(city_world)

	var ground := TextureRect.new()
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(WORLD_TILESET_PATH):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(WORLD_TILESET_PATH)
		atlas.region = Rect2(0, 0, 768, 858)
		ground.texture = atlas
	city_world.add_child(ground)

	city_player = TextureRect.new()
	city_player.name = "KoiPlayer"
	city_player.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	city_player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	city_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	city_player.size = Vector2(74, 96)
	city_player.position = Vector2(120, 190)
	city_world.add_child(city_player)
	_set_city_player_frame("down", 0)

	var instruction := Label.new()
	instruction.text = "Tahan tombol arah untuk berjalan"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_color_override("font_color", TEXT_MUTED)
	layout.add_child(instruction)

	var dpad := GridContainer.new()
	dpad.columns = 3
	dpad.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dpad.add_theme_constant_override("h_separation", 8)
	dpad.add_theme_constant_override("v_separation", 5)
	layout.add_child(dpad)

	var spacer_left := Control.new()
	spacer_left.custom_minimum_size = Vector2(62, 48)
	dpad.add_child(spacer_left)
	_add_city_direction_button(dpad, "↑", Vector2.UP)
	var spacer_right := Control.new()
	spacer_right.custom_minimum_size = Vector2(62, 48)
	dpad.add_child(spacer_right)

	_add_city_direction_button(dpad, "←", Vector2.LEFT)
	var center_mark := Label.new()
	center_mark.text = "✦"
	center_mark.custom_minimum_size = Vector2(62, 48)
	center_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_mark.add_theme_color_override("font_color", ACCENT)
	dpad.add_child(center_mark)
	_add_city_direction_button(dpad, "→", Vector2.RIGHT)

	var spacer_bottom_left := Control.new()
	spacer_bottom_left.custom_minimum_size = Vector2(62, 48)
	dpad.add_child(spacer_bottom_left)
	_add_city_direction_button(dpad, "↓", Vector2.DOWN)
	var spacer_bottom_right := Control.new()
	spacer_bottom_right.custom_minimum_size = Vector2(62, 48)
	dpad.add_child(spacer_bottom_right)

func _add_city_direction_button(parent: GridContainer, label: String, direction: Vector2) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(62, 48)
	button.add_theme_font_size_override("font_size", 23)
	button.button_down.connect(_set_city_move_direction.bind(direction))
	button.button_up.connect(_clear_city_move_direction)
	parent.add_child(button)

func _set_city_move_direction(direction: Vector2) -> void:
	city_move_dir = direction
	if direction.y < 0:
		city_walk_direction = "up"
	elif direction.y > 0:
		city_walk_direction = "down"
	elif direction.x < 0:
		city_walk_direction = "left"
	else:
		city_walk_direction = "right"
	city_anim_time = 0.0
	city_walk_frame = 0

func _clear_city_move_direction() -> void:
	city_move_dir = Vector2.ZERO
	city_anim_time = 0.0
	city_walk_frame = 0
	_set_city_player_frame(city_walk_direction, 0)

func _process(delta: float) -> void:
	if not is_instance_valid(city_player) or not is_instance_valid(city_world):
		return
	if city_move_dir == Vector2.ZERO:
		return
	var movement := city_move_dir.normalized() * 155.0 * delta
	var max_x := maxf(0.0, city_world.size.x - city_player.size.x)
	var max_y := maxf(0.0, city_world.size.y - city_player.size.y)
	city_player.position.x = clampf(city_player.position.x + movement.x, 0.0, max_x)
	city_player.position.y = clampf(city_player.position.y + movement.y, 0.0, max_y)
	city_anim_time += delta
	if city_anim_time >= 0.12:
		city_anim_time = 0.0
		city_walk_frame = (city_walk_frame + 1) % 6
		_set_city_player_frame(city_walk_direction, city_walk_frame)

func _set_city_player_frame(direction: String, frame_index: int) -> void:
	if not is_instance_valid(city_player):
		return
	if not ResourceLoader.exists(PLAYER_SPRITE_PATH):
		return
	var atlas_texture := load(PLAYER_SPRITE_PATH) as Texture2D
	if atlas_texture == null:
		return
	var frame_rect := Rect2(29, 18, 133, 171)
	match direction:
		"up":
			var back_frames := [
				Rect2(22, 789, 109, 178), Rect2(146, 789, 109, 178),
				Rect2(269, 789, 109, 178), Rect2(393, 789, 109, 178),
				Rect2(516, 789, 109, 178), Rect2(639, 789, 109, 178)
			]
			frame_rect = back_frames[frame_index % back_frames.size()]
		"down":
			var front_frames := [
				Rect2(19, 592, 116, 194), Rect2(142, 592, 117, 194),
				Rect2(265, 592, 116, 194), Rect2(390, 592, 115, 194),
				Rect2(512, 592, 116, 194), Rect2(637, 592, 115, 194)
			]
			frame_rect = front_frames[frame_index % front_frames.size()]
		"left":
			var left_frames := [
				Rect2(31, 989, 105, 154), Rect2(153, 989, 105, 154),
				Rect2(277, 989, 105, 154), Rect2(401, 989, 105, 154),
				Rect2(524, 988, 105, 154), Rect2(638, 989, 105, 154)
			]
			frame_rect = left_frames[frame_index % left_frames.size()]
		"right":
			var right_frames := [
				Rect2(786, 989, 105, 154), Rect2(908, 989, 105, 154),
				Rect2(1030, 989, 105, 154), Rect2(1155, 989, 105, 154),
				Rect2(1278, 989, 105, 154), Rect2(1401, 989, 105, 154)
			]
			frame_rect = right_frames[frame_index % right_frames.size()]
	var atlas := AtlasTexture.new()
	atlas.atlas = atlas_texture
	atlas.region = frame_rect
	city_player.texture = atlas
