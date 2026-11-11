extends CharacterBody2D

@export var move_speed := 230.0
var touch_direction := Vector2.ZERO

func _physics_process(_delta: float) -> void:
    var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var wasd := Vector2(
        float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
        float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
    )
    var direction := keyboard if keyboard.length() > 0.1 else (wasd if wasd.length() > 0.1 else touch_direction)
    # Convert screen input into an isometric-feeling movement vector.
    var iso_direction := Vector2(direction.x - direction.y, (direction.x + direction.y) * 0.5)
    velocity = iso_direction.normalized() * move_speed if iso_direction.length() > 0.01 else Vector2.ZERO
    move_and_slide()
    queue_redraw()

func set_touch_direction(value: Vector2) -> void:
    touch_direction = value

func _draw() -> void:
    draw_circle(Vector2(0, 12), 9, Color(0, 0, 0, 0.22))
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, -25), Vector2(15, -7), Vector2(0, 8), Vector2(-15, -7)
    ]), Color("#f0c58c"))
    draw_circle(Vector2(0, -17), 8, Color("#f4d7b8"))
    draw_rect(Rect2(-9, -8, 18, 20), Color("#426b91"))
