extends Control

const WORLD_SCENE := "res://scenes/world/World.tscn"

func _ready() -> void:
    _build_ui()

func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("#172536")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var center := VBoxContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    center.position = Vector2(-190, -155)
    center.size = Vector2(380, 310)
    center.add_theme_constant_override("separation", 20)
    add_child(center)

    var title := Label.new()
    title.text = "KOI KINGDOM"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 46)
    title.add_theme_color_override("font_color", Color("#f2d9a6"))
    center.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "A Living Kingdom • Isometric Life Simulation"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 15)
    subtitle.add_theme_color_override("font_color", Color("#c5d3df"))
    center.add_child(subtitle)

    _add_button(center, "MULAI PETUALANGAN", _start_game)
    _add_button(center, "LANJUTKAN", _load_game)
    _add_button(center, "KELUAR", _quit_game)

func _add_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(340, 58)
    button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    button.add_theme_font_size_override("font_size", 20)
    button.pressed.connect(action)
    parent.add_child(button)

func _start_game() -> void:
    SaveManager.clear_save()
    TimeManager.reset_clock()
    RelationshipManager.reset()
    KingdomManager.reset()
    get_tree().change_scene_to_file(WORLD_SCENE)

func _load_game() -> void:
    if not SaveManager.has_save():
        return
    var data := SaveManager.load_game()
    TimeManager.apply_state(data.get("time", {}))
    get_tree().change_scene_to_file(WORLD_SCENE)

func _quit_game() -> void:
    get_tree().quit()
