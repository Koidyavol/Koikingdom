extends Node2D

var wander_target := Vector2.ZERO
var wander_timer := 0.0
var speed := 28.0
var npc_name := "Villager"

func _ready() -> void:
    _choose_target()

func _process(delta: float) -> void:
    wander_timer -= delta
    if wander_timer <= 0.0 or global_position.distance_to(wander_target) < 5.0:
        _choose_target()
    global_position = global_position.move_toward(wander_target, speed * delta)
    queue_redraw()

func _choose_target() -> void:
    wander_timer = randf_range(2.0, 5.0)
    wander_target = global_position + Vector2(randf_range(-90, 90), randf_range(-45, 45))

func _draw() -> void:
    draw_circle(Vector2(0, 9), 6, Color(0, 0, 0, 0.18))
    draw_circle(Vector2(0, -9), 6, Color("#e8c5a4"))
    draw_rect(Rect2(-7, -3, 14, 14), Color("#8d9c70"))
