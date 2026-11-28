extends Node2D

signal citizen_selected(citizen_id: String)

const MAP_SIZE := 18
const TILE_WIDTH := 64.0
const TILE_HEIGHT := 32.0
const PLAYER_SPEED := 4.2
const NPC_SPEED := 0.8
const MAX_NPC_COUNT := 64

const KINGDOM_CENTERS := {
	"asteria": Vector2(3.0, 3.0),
	"mizuhara": Vector2(14.0, 3.0),
	"verdantia": Vector2(3.0, 14.0),
	"drakemont": Vector2(14.0, 14.0)
}

var _player_grid := Vector2(8.5, 8.5)
var _player_target := Vector2(8.5, 8.5)
var _citizens: Array = []
var _npc_positions: Dictionary = {}
var _selected_id := ""
var _camera: Camera2D


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.zoom = Vector2(1.0, 1.0)
	add_child(_camera)
	_camera.make_current()
	_camera.position = _grid_to_world(_player_grid)
	queue_redraw()


func apply_state(state: Dictionary) -> void:
	_player_grid = _clamp_grid(Vector2(
		float(state.get("player_x", 8.5)),
		float(state.get("player_y", 8.5))
	))
	_player_target = _player_grid
	var saved_positions: Variant = state.get("npc_positions", {})
	_npc_positions = saved_positions.duplicate(true) if saved_positions is Dictionary else {}
	_selected_id = str(state.get("selected_id", ""))
	if _camera != null:
		_camera.position = _grid_to_world(_player_grid)
	queue_redraw()


func get_state() -> Dictionary:
	return {
		"player_x": _player_grid.x,
		"player_y": _player_grid.y,
		"selected_id": _selected_id,
		"npc_positions": _npc_positions.duplicate(true)
	}


func get_selected_id() -> String:
	return _selected_id


func sync_citizens(citizens: Array) -> void:
	_citizens = citizens
	var valid_ids: Dictionary = {}
	var processed := 0

	for citizen in _citizens:
		if not citizen is Dictionary:
			continue
		var citizen_id := str(citizen.get("id", ""))
		if citizen_id.is_empty():
			continue
		valid_ids[citizen_id] = true
		processed += 1
		if processed > MAX_NPC_COUNT:
			break

		if not _npc_positions.has(citizen_id):
			var start_grid := _initial_grid_for(citizen)
			var target_grid := _target_for(citizen)
			_npc_positions[citizen_id] = {
				"x": start_grid.x,
				"y": start_grid.y,
				"tx": target_grid.x,
				"ty": target_grid.y
			}
		else:
			var position_data: Dictionary = _npc_positions[citizen_id]
			var target_grid := _target_for(citizen)
			var old_target := Vector2(
				float(position_data.get("tx", target_grid.x)),
				float(position_data.get("ty", target_grid.y))
			)
			if old_target.distance_to(target_grid) > 0.05:
				position_data["tx"] = target_grid.x
				position_data["ty"] = target_grid.y

	var keys := _npc_positions.keys()
	for key in keys:
		if not valid_ids.has(str(key)):
			_npc_positions.erase(key)
	if not valid_ids.has(_selected_id):
		_selected_id = ""
	queue_redraw()


func _process(delta: float) -> void:
	var changed := false
	if _player_grid.distance_to(_player_target) > 0.01:
		_player_grid = _player_grid.move_toward(_player_target, PLAYER_SPEED * delta)
		changed = true

	for citizen in _citizens:
		if not citizen is Dictionary:
			continue
		var citizen_id := str(citizen.get("id", ""))
		if not _npc_positions.has(citizen_id):
			continue
		var position_data: Dictionary = _npc_positions[citizen_id]
		var current := Vector2(float(position_data.get("x", 0.0)), float(position_data.get("y", 0.0)))
		var target := Vector2(float(position_data.get("tx", current.x)), float(position_data.get("ty", current.y)))
		if current.distance_to(target) > 0.01:
			current = current.move_toward(target, NPC_SPEED * delta)
			position_data["x"] = current.x
			position_data["y"] = current.y
			changed = true

	if _camera != null:
		_camera.position = _grid_to_world(_player_grid)
	if changed:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_pointer(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(event.position)


func _handle_pointer(screen_position: Vector2) -> void:
	var world_position := get_canvas_transform().affine_inverse() * screen_position
	for citizen in _citizens:
		if not citizen is Dictionary:
			continue
		var citizen_id := str(citizen.get("id", ""))
		if not _npc_positions.has(citizen_id):
			continue
		var position_data: Dictionary = _npc_positions[citizen_id]
		var grid_position := Vector2(float(position_data.get("x", 0.0)), float(position_data.get("y", 0.0)))
		if world_position.distance_to(_grid_to_world(grid_position)) <= 28.0:
			_selected_id = citizen_id
			citizen_selected.emit(citizen_id)
			queue_redraw()
			return

	_selected_id = ""
	var target_grid := _clamp_grid(_world_to_grid(world_position))
	_player_target = target_grid
	queue_redraw()


func _draw() -> void:
	for x in range(MAP_SIZE):
		for y in range(MAP_SIZE):
			var grid := Vector2(float(x), float(y))
			var center := _grid_to_world(grid)
			var polygon := _tile_polygon(center)
			var tile_color := Color("#4b7659")
			if x >= 7 and x <= 10 and y >= 7 and y <= 10:
				tile_color = Color("#8b806a")
			elif x == 8 or y == 8 or x == 9 or y == 9:
				tile_color = Color("#71866d")
			elif (x + y) % 3 == 0:
				tile_color = Color("#507e60")
			draw_polygon(polygon, PackedColorArray([tile_color]))
			draw_polyline(polygon, Color("#2c4939"), 1.0, true)

	_draw_districts()
	_draw_citizens()
	_draw_player()


func _draw_districts() -> void:
	_draw_building(Vector2(3.0, 3.0), Color("#d5a56d"), "Asteria")
	_draw_building(Vector2(14.0, 3.0), Color("#9fb6d1"), "Mizuhara")
	_draw_building(Vector2(3.0, 14.0), Color("#9ec68b"), "Verdantia")
	_draw_building(Vector2(14.0, 14.0), Color("#d59b92"), "Drakemont")
	_draw_building(Vector2(8.5, 8.5), Color("#e3c57e"), "Plaza")


func _draw_building(grid: Vector2, roof_color: Color, label: String) -> void:
	var center := _grid_to_world(grid)
	var roof := PackedVector2Array([
		center + Vector2(0.0, -18.0),
		center + Vector2(22.0, -8.0),
		center + Vector2(0.0, 2.0),
		center + Vector2(-22.0, -8.0)
	])
	draw_polygon(roof, PackedColorArray([roof_color]))
	draw_polyline(roof, Color("#423d35"), 2.0, true)
	draw_string(ThemeDB.fallback_font, center + Vector2(-42.0, 25.0), label, HORIZONTAL_ALIGNMENT_CENTER, 84.0, 12, Color("#f5f0e4"))


func _draw_citizens() -> void:
	for citizen in _citizens:
		if not citizen is Dictionary:
			continue
		var citizen_id := str(citizen.get("id", ""))
		if not _npc_positions.has(citizen_id):
			continue
		var position_data: Dictionary = _npc_positions[citizen_id]
		var grid_position := Vector2(float(position_data.get("x", 0.0)), float(position_data.get("y", 0.0)))
		var world_position := _grid_to_world(grid_position)
		if citizen_id == _selected_id:
			draw_circle(world_position, 18.0, Color("#fff2a6"))
		draw_circle(world_position, 12.0, _activity_color(str(citizen.get("activity", "Santai"))))
		draw_circle(world_position, 5.0, Color("#17242a"))
		draw_string(ThemeDB.fallback_font, world_position + Vector2(-38.0, -18.0), str(citizen.get("name", "Warga")), HORIZONTAL_ALIGNMENT_CENTER, 76.0, 11, Color("#ffffff"))


func _draw_player() -> void:
	var world_position := _grid_to_world(_player_grid)
	draw_circle(world_position, 16.0, Color("#7ed4e8"))
	draw_circle(world_position, 8.0, Color("#163a50"))
	if _player_grid.distance_to(_player_target) > 0.15:
		draw_circle(_grid_to_world(_player_target), 7.0, Color("#ffffff"))


func _activity_color(activity: String) -> Color:
	match activity:
		"Bekerja":
			return Color("#82c78a")
		"Tidur":
			return Color("#8e9fcf")
		"Makan":
			return Color("#e5b878")
		"Bersosialisasi":
			return Color("#c89acb")
		_:
			return Color("#c3c9c4")


func _initial_grid_for(citizen: Dictionary) -> Vector2:
	var center := _kingdom_center(str(citizen.get("kingdom_id", "")))
	var jitter := _id_offset(str(citizen.get("id", "")))
	return _clamp_grid(center + jitter * 0.55)


func _target_for(citizen: Dictionary) -> Vector2:
	var citizen_id := str(citizen.get("id", ""))
	var center := _kingdom_center(str(citizen.get("kingdom_id", "")))
	var activity := str(citizen.get("activity", "Santai"))
	var job := str(citizen.get("job", ""))
	var target := center

	match activity:
		"Bersosialisasi":
			target = Vector2(8.5, 8.5)
		"Makan":
			target = center + Vector2(1.0, 1.0)
		"Tidur":
			target = center + Vector2(-1.0, 1.0)
		"Bekerja":
			target = center + _work_offset(job)
		_:
			target = center + Vector2(1.0, 0.5)

	return _clamp_grid(target + _id_offset(citizen_id) * 0.2)


func _work_offset(job: String) -> Vector2:
	match job:
		"Petani":
			return Vector2(2.0, 0.0)
		"Pedagang":
			return Vector2(0.0, 2.0)
		"Penjaga":
			return Vector2(-2.0, 0.0)
		"Tabib":
			return Vector2(0.0, -2.0)
		"Pelajar":
			return Vector2(2.0, 2.0)
		_:
			return Vector2(0.0, 0.0)


func _kingdom_center(kingdom_id: String) -> Vector2:
	var value: Vector2 = KINGDOM_CENTERS.get(kingdom_id, Vector2(8.5, 8.5))
	return value


func _id_offset(citizen_id: String) -> Vector2:
	var value := abs(citizen_id.hash())
	var x := int(value % 3) - 1
	var y := int(int(value / 3) % 3) - 1
	return Vector2(float(x), float(y))


func _clamp_grid(grid: Vector2) -> Vector2:
	return Vector2(clampf(grid.x, 0.0, float(MAP_SIZE - 1)), clampf(grid.y, 0.0, float(MAP_SIZE - 1)))


func _grid_to_world(grid: Vector2) -> Vector2:
	var center := Vector2((MAP_SIZE - 1) / 2.0, (MAP_SIZE - 1) / 2.0)
	var centered := grid - center
	return Vector2(
		(centered.x - centered.y) * TILE_WIDTH / 2.0,
		(centered.x + centered.y) * TILE_HEIGHT / 2.0
	)


func _world_to_grid(world_position: Vector2) -> Vector2:
	var centered := Vector2(world_position.x * 2.0 / TILE_WIDTH, world_position.y * 2.0 / TILE_HEIGHT)
	var grid_centered := Vector2(
		(centered.x + centered.y) / 2.0,
		(centered.y - centered.x) / 2.0
	)
	return grid_centered + Vector2((MAP_SIZE - 1) / 2.0, (MAP_SIZE - 1) / 2.0)


func _tile_polygon(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -TILE_HEIGHT / 2.0),
		center + Vector2(TILE_WIDTH / 2.0, 0.0),
		center + Vector2(0.0, TILE_HEIGHT / 2.0),
		center + Vector2(-TILE_WIDTH / 2.0, 0.0)
	])
