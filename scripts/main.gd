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
var academy_data: Dictionary = {"students": {}, "last_school_check": ""}
var academy_status_label: Label

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
	_check_academy_schedule()
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

	var talk_button := Button.new()
	talk_button.text = "Bicara"
	talk_button.custom_minimum_size = Vector2(0, 38)
	talk_button.pressed.connect(_open_aiko_chat)
	details.add_child(talk_button)

	_add_teacher_npc_card(list)


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

	var talk := Button.new()
	talk.text = "Profil Guru"
	talk.custom_minimum_size = Vector2(0, 42)
	talk.pressed.connect(_open_teacher_profile)
	details.add_child(talk)


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
	if location_name == "Akademi":
		_open_academy()
		return
	if location_name == "Balai Kota":
		_open_town_hall_board()
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
