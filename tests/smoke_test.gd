extends SceneTree


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var world_script: Script = load("res://scripts/autoload/world_manager.gd")
	var world: Object = world_script.new()
	var world_node := world as Node
	root.add_child(world_node)

	var errors: PackedStringArray = world.call("validate_state")
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		world_node.queue_free()
		quit(1)
		return

	var kingdom_data: Dictionary = world.get("kingdoms")
	if kingdom_data.size() != 4:
		push_error("Smoke test gagal: harus ada empat kerajaan.")
		world_node.queue_free()
		quit(1)
		return

	world.call("advance_to_day", 2)
	if int(world.get("last_processed_day")) != 2:
		push_error("Smoke test gagal: simulasi harian tidak maju.")
		world_node.queue_free()
		quit(1)
		return

	var clock_script: Script = load("res://scripts/autoload/simulation_clock.gd")
	var clock: Object = clock_script.new()
	var clock_node := clock as Node
	root.add_child(clock_node)

	var one_hour_minutes: int = int(clock.call("calculate_offline_minutes", 100, 3700))
	var capped_minutes: int = int(clock.call("calculate_offline_minutes", 100, 86500))
	var negative_minutes: int = int(clock.call("calculate_offline_minutes", 200, 100))

	if one_hour_minutes != 7200:
		push_error("Smoke test gagal: konversi satu jam offline salah.")
		clock_node.queue_free()
		world_node.queue_free()
		quit(1)
		return

	if capped_minutes != 14400:
		push_error("Smoke test gagal: batas offline dua jam tidak diterapkan.")
		clock_node.queue_free()
		world_node.queue_free()
		quit(1)
		return

	if negative_minutes != 0:
		push_error("Smoke test gagal: waktu negatif harus diabaikan.")
		clock_node.queue_free()
		world_node.queue_free()
		quit(1)
		return

	print("KOI KINGDOM SMOKE TEST: PASS")
	clock_node.queue_free()
	world_node.queue_free()
	quit(0)
