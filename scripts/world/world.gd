extends Node2D

const NPC_SCRIPT := preload("res://scripts/characters/npc.gd")
const STARTING_NPC_COUNT := 8
const FIRST_NAMES := ["Aoi", "Ren", "Hana", "Yuki", "Akira", "Mei", "Haruto", "Sora", "Rin", "Kaito", "Emi", "Daichi"]
const RACES := ["Human", "Elf", "Beastkin", "Dwarf"]
const JOBS := ["Farmer", "Merchant", "Guard", "Student", "Blacksmith", "Healer", "Fisher"]
const PERSONALITIES := ["Kind", "Cheerful", "Shy", "Hardworking", "Curious", "Calm"]

var camera: Camera2D
var hud: CanvasLayer
var clock_label: Label
var profile_label: Label
var kingdom_label: Label
var player: CharacterBody2D
var citizens: Array[Node] = []
var social_simulation_timer := 0.0
var _last_family_day := 0

func _ready() -> void:
    randomize()
    player = get_node("Player")
    var saved := SaveManager.load_game()
    if not saved.is_empty():
        var pos: Array = saved.get("player_position", [640.0, 360.0])
        if pos.size() >= 2:
            player.position = Vector2(float(pos[0]), float(pos[1]))
        var time_state: Dictionary = saved.get("time", {})
        if not time_state.is_empty():
            TimeManager.apply_state(time_state)

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    player.add_child(camera)
    camera.make_current()

    RelationshipManager.apply_state(saved.get("relationships", {}))
    KingdomManager.apply_state(saved.get("kingdom", {}))
    _spawn_npcs(saved.get("citizens", []))
    KingdomManager.process_day(citizens, TimeManager.day)
    _last_family_day = TimeManager.day
    _build_hud()
    queue_redraw()

func _process(delta: float) -> void:
    RelationshipManager.simulate(citizens, delta)
    if TimeManager.day != _last_family_day:
        _simulate_family_day()
    if is_instance_valid(clock_label):
        clock_label.text = TimeManager.formatted_time()

func _draw() -> void:
    var tile_w := 96.0
    var tile_h := 48.0
    for y in range(-35, 36):
        for x in range(-45, 46):
            var p := Vector2(640 + (x - y) * tile_w * 0.5, 360 + (x + y) * tile_h * 0.5)
            var points := PackedVector2Array([
                p + Vector2(0, -tile_h * 0.5), p + Vector2(tile_w * 0.5, 0),
                p + Vector2(0, tile_h * 0.5), p + Vector2(-tile_w * 0.5, 0)
            ])
            var tile_color := Color("#73966a") if (x + y) % 2 == 0 else Color("#7da272")
            draw_colored_polygon(points, tile_color)
            draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color("#66865e"), 1.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(510, 300), Vector2(770, 300), Vector2(840, 370), Vector2(580, 370)
    ]), Color("#b9aa8b"))
    draw_rect(Rect2(680, 190, 110, 95), Color("#8b5e4a"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(665, 195), Vector2(735, 135), Vector2(805, 195)
    ]), Color("#593f45"))

func _spawn_npcs(saved_citizens: Array) -> void:
    var spawn_count := mini(32, maxi(STARTING_NPC_COUNT, saved_citizens.size()))
    for i in range(spawn_count):
        var npc = NPC_SCRIPT.new()
        add_child(npc)
        var data: Dictionary
        if i < saved_citizens.size() and saved_citizens[i] is Dictionary:
            data = saved_citizens[i]
        else:
            data = _make_citizen(i)
        npc.setup(data)
        npc.selected.connect(_show_citizen_profile)
        citizens.append(npc)


func _simulate_family_day() -> void:
    _last_family_day = TimeManager.day
    var births := RelationshipManager.process_family_day(citizens, TimeManager.day)
    KingdomManager.process_day(citizens, TimeManager.day)
    if is_instance_valid(kingdom_label):
        kingdom_label.text = KingdomManager.get_summary() + "\n" + KingdomManager.get_diplomacy_summary()
    for child_data in births:
        if citizens.size() >= 32:
            break
        var child = NPC_SCRIPT.new()
        add_child(child)
        child.setup(child_data)
        child.selected.connect(_show_citizen_profile)
        citizens.append(child)
    KingdomManager.assign_government(citizens)

func _make_citizen(index: int) -> Dictionary:
    var gender := "Female" if randi() % 2 == 0 else "Male"
    return {
        "id": "citizen_%03d" % (index + 1),
        "name": FIRST_NAMES[randi_range(0, FIRST_NAMES.size() - 1)],
        "race": RACES[randi_range(0, RACES.size() - 1)],
        "gender": gender,
        "age": randi_range(18, 60),
        "job": JOBS[randi_range(0, JOBS.size() - 1)],
        "personality": PERSONALITIES[randi_range(0, PERSONALITIES.size() - 1)],
        "hunger": randf_range(65.0, 100.0),
        "energy": randf_range(65.0, 100.0),
        "social": randf_range(55.0, 100.0),
        "position": [randf_range(420, 900), randf_range(250, 500)]
    }

func _show_citizen_profile(profile: Dictionary) -> void:
    if not is_instance_valid(profile_label):
        return
    profile_label.text = "%s  |  %s %s, %d\\nPeran: %s  |  Pekerjaan: %s\\nSifat: %s  |  Aktivitas: %s\\nRelasi: %s  |  Teman: %d\\nLapar %d%%  Energi %d%%  Sosial %d%%" % [
        profile.name, profile.gender, profile.race, profile.age, profile.kingdom_role, profile.job,
        profile.personality, profile.activity, profile.relationship_status,
        profile.friends.size(), profile.hunger, profile.energy, profile.social
    ]

func _build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 14)
    hud.add_child(panel)
    clock_label = Label.new()
    clock_label.text = TimeManager.formatted_time()
    clock_label.add_theme_font_size_override("font_size", 20)
    panel.add_child(clock_label)

    profile_label = Label.new()
    profile_label.text = "Ketuk warga untuk melihat identitas dan kebutuhannya."
    profile_label.position = Vector2(16, 82)
    profile_label.add_theme_color_override("font_color", Color.WHITE)
    profile_label.add_theme_font_size_override("font_size", 14)
    hud.add_child(profile_label)

    kingdom_label = Label.new()
    kingdom_label.text = KingdomManager.get_summary()
    kingdom_label.position = Vector2(16, 190)
    kingdom_label.add_theme_color_override("font_color", Color("#f2d9a6"))
    kingdom_label.add_theme_font_size_override("font_size", 13)
    hud.add_child(kingdom_label)

    var hint := Label.new()
    hint.text = "WASD / tombol arah untuk bergerak"
    hint.position = Vector2(16, 250)
    hint.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(hint)
    _add_touch_controls()

func _add_touch_controls() -> void:
    var base := Control.new()
    base.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    base.position = Vector2(24, -190)
    base.custom_minimum_size = Vector2(180, 170)
    hud.add_child(base)
    _make_direction_button(base, "↑", Vector2(60, 0), Vector2.UP)
    _make_direction_button(base, "↓", Vector2(60, 110), Vector2.DOWN)
    _make_direction_button(base, "←", Vector2(0, 55), Vector2.LEFT)
    _make_direction_button(base, "→", Vector2(120, 55), Vector2.RIGHT)

func _make_direction_button(parent: Control, caption: String, pos: Vector2, dir: Vector2) -> void:
    var button := Button.new()
    button.text = caption
    button.position = pos
    button.size = Vector2(56, 56)
    button.add_theme_font_size_override("font_size", 24)
    parent.add_child(button)
    button.button_down.connect(func(): player.set_touch_direction(dir))
    button.button_up.connect(func(): player.set_touch_direction(Vector2.ZERO))

func _save_world() -> void:
    if not is_instance_valid(player):
        return
    var citizen_data: Array = []
    for citizen in citizens:
        if is_instance_valid(citizen):
            citizen_data.append(citizen.get_save_data())
    SaveManager.save_game({
        "player_position": [player.position.x, player.position.y],
        "time": TimeManager.get_state(),
        "citizens": citizen_data,
        "relationships": RelationshipManager.get_save_data(),
        "kingdom": KingdomManager.get_save_data()
    })

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
        _save_world()
