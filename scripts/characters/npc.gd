extends Node2D

signal selected(profile: Dictionary)

var npc_id := ""
var npc_name := "Villager"
var race := "Human"
var gender := "Female"
var age := 20
var job := "Farmer"
var personality := "Kind"
var hunger := 100.0
var energy := 100.0
var social := 75.0
var partner_id := ""
var relationship_status := "Single"
var friends: Array[String] = []
var parent_ids: Array = []
var married_day := 0
var last_age_day := 1

var speed := 34.0
var wander_target := Vector2.ZERO
var wander_timer := 0.0
var need_timer := 0.0
var current_activity := "Relaxing"
var body_color := Color("#8d9c70")
var _last_schedule_hour := -1

func setup(data: Dictionary) -> void:
    npc_id = str(data.get("id", ""))
    npc_name = str(data.get("name", "Villager"))
    race = str(data.get("race", "Human"))
    gender = str(data.get("gender", "Female"))
    age = int(data.get("age", 20))
    job = str(data.get("job", "Farmer"))
    personality = str(data.get("personality", "Kind"))
    hunger = clampf(float(data.get("hunger", 100.0)), 0.0, 100.0)
    energy = clampf(float(data.get("energy", 100.0)), 0.0, 100.0)
    social = clampf(float(data.get("social", 75.0)), 0.0, 100.0)
    partner_id = str(data.get("partner_id", ""))
    relationship_status = str(data.get("relationship_status", "Single"))
    married_day = int(data.get("married_day", 0))
    last_age_day = int(data.get("last_age_day", TimeManager.day))
    parent_ids = data.get("parent_ids", []).duplicate()
    friends.clear()
    for friend_id in data.get("friends", []):
        friends.append(str(friend_id))
    if data.has("position") and data.position is Array and data.position.size() >= 2:
        position = Vector2(float(data.position[0]), float(data.position[1]))
    _choose_activity(true)

func _ready() -> void:
    if npc_id.is_empty():
        npc_id = "citizen_%d" % randi()
    _choose_target()

func _process(delta: float) -> void:
    var hour := TimeManager.hour
    if hour != _last_schedule_hour:
        _choose_activity(false)
    wander_timer -= delta
    if wander_timer <= 0.0 or global_position.distance_to(wander_target) < 7.0:
        _choose_target()
    global_position = global_position.move_toward(wander_target, speed * delta)

    need_timer += delta
    if need_timer >= 12.0:
        need_timer = 0.0
        hunger = maxf(0.0, hunger - 1.0)
        energy = maxf(0.0, energy - (0.5 if current_activity == "Working" else 0.25))
        social = maxf(0.0, social - 0.35)
        if current_activity == "Eating":
            hunger = minf(100.0, hunger + 4.0)
        elif current_activity == "Sleeping":
            energy = minf(100.0, energy + 5.0)
        elif current_activity == "Socializing":
            social = minf(100.0, social + 4.0)
    queue_redraw()

func _choose_activity(force: bool) -> void:
    _last_schedule_hour = TimeManager.hour
    var hour := TimeManager.hour
    if age < 7:
        current_activity = "Playing"
    elif energy < 18.0 or hour >= 22 or hour < 6:
        current_activity = "Sleeping"
    elif hunger < 28.0 or hour == 12:
        current_activity = "Eating"
    elif hour >= 7 and hour < 17:
        current_activity = "Working"
    elif hour >= 17 and hour < 21:
        current_activity = "Socializing"
    else:
        current_activity = "Relaxing"
    if force:
        _choose_target()

func _choose_target() -> void:
    wander_timer = randf_range(2.5, 5.0)
    var center := Vector2(640, 360)
    match current_activity:
        "Working":
            match job:
                "Farmer": center = Vector2(330, 470)
                "Merchant": center = Vector2(760, 350)
                "Guard": center = Vector2(660, 235)
                "Student": center = Vector2(850, 245)
                "Blacksmith": center = Vector2(520, 250)
                "Healer": center = Vector2(890, 390)
                "Fisher": center = Vector2(300, 300)
                _: center = Vector2(640, 360)
        "Eating": center = Vector2(600, 390)
        "Sleeping": center = Vector2(640, 360)
        "Playing": center = Vector2(640, 440)
        "Socializing": center = Vector2(690, 420)
        _: center = Vector2(640, 360)
    wander_target = center + Vector2(randf_range(-55, 55), randf_range(-28, 28))

func get_profile() -> Dictionary:
    return {
        "id": npc_id, "name": npc_name, "race": race, "gender": gender,
        "age": age, "job": job, "personality": personality,
        "activity": current_activity, "hunger": roundi(hunger),
        "partner_id": partner_id, "relationship_status": relationship_status, "friends": friends,
        "parent_ids": parent_ids, "married_day": married_day, "last_age_day": last_age_day,
        "energy": roundi(energy), "social": roundi(social)
    }

func get_save_data() -> Dictionary:
    var data := get_profile()
    data["position"] = [position.x, position.y]
    return data

func _input(event: InputEvent) -> void:
    var tapped := false
    var tap_position := Vector2.ZERO
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        tapped = true
        tap_position = get_global_mouse_position()
    elif event is InputEventScreenTouch and event.pressed:
        tapped = true
        tap_position = get_canvas_transform().affine_inverse() * event.position
    if tapped and global_position.distance_to(tap_position) < 28.0:
        selected.emit(get_profile())

func _draw() -> void:
    draw_circle(Vector2(0, 9), 7, Color(0, 0, 0, 0.18))
    draw_circle(Vector2(0, -9), 6, Color("#e8c5a4"))
    draw_rect(Rect2(-7, -3, 14, 14), body_color)
    draw_circle(Vector2(-2, -10), 1.0, Color("#493b35"))
    draw_circle(Vector2(2, -10), 1.0, Color("#493b35"))
