extends Node2D

const NPC_SCRIPT := preload("res://scripts/characters/npc.gd")
const NPC_COUNT := 8

var camera: Camera2D
var hud: CanvasLayer
var clock_label: Label
var player: CharacterBody2D

func _ready() -> void:
    randomize()
    player = get_node("Player")
    var saved := SaveManager.load_game()
    if not saved.is_empty():
        var pos: Array = saved.get("player_position", [640.0, 360.0])
        if pos.size() >= 2:
            player.position = Vector2(float(pos[0]), float(pos[1]))

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    player.add_child(camera)
    camera.make_current()

    _spawn_npcs()
    _build_hud()
    queue_redraw()

func _process(_delta: float) -> void:
    if is_instance_valid(clock_label):
        clock_label.text = TimeManager.formatted_time()

func _draw() -> void:
    # Large diamond-tile field: an initial isometric-style open-world test area.
    var tile_w := 96.0
    var tile_h := 48.0
    for y in range(-35, 36):
        for x in range(-45, 46):
            var p := Vector2(640 + (x - y) * tile_w * 0.5, 360 + (x + y) * tile_h * 0.5)
            var points := PackedVector2Array([
                p + Vector2(0, -tile_h * 0.5),
                p + Vector2(tile_w * 0.5, 0),
                p + Vector2(0, tile_h * 0.5),
                p + Vector2(-tile_w * 0.5, 0)
            ])
            var tile_color := Color("#73966a") if (x + y) % 2 == 0 else Color("#7da272")
            draw_colored_polygon(points, tile_color)
            draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color("#66865e"), 1.0)

    # Plaza and simple town landmark placeholders.
    draw_colored_polygon(PackedVector2Array([
        Vector2(510, 300), Vector2(770, 300), Vector2(840, 370), Vector2(580, 370)
    ]), Color("#b9aa8b"))
    draw_rect(Rect2(680, 190, 110, 95), Color("#8b5e4a"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(665, 195), Vector2(735, 135), Vector2(805, 195)
    ]), Color("#593f45"))

func _spawn_npcs() -> void:
    for i in range(NPC_COUNT):
        var npc := Node2D.new()
        npc.set_script(NPC_SCRIPT)
        npc.npc_name = "Villager %02d" % (i + 1)
        npc.position = Vector2(randf_range(420, 900), randf_range(250, 500))
        add_child(npc)

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

    var hint := Label.new()
    hint.text = "WASD / tombol arah untuk bergerak • Prototype"
    hint.position = Vector2(16, 58)
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
    SaveManager.save_game({
        "player_position": [player.position.x, player.position.y],
        "time": TimeManager.get_state()
    })

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
        _save_world()
