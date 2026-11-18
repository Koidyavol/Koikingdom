extends SceneTree


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var world_script: Script = load("res://scripts/autoload/world_manager.gd")
	var world: Node = world_script.new()
	root.add_child(world)

	var errors: PackedStringArray = world.validate_state()
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		world.queue_free()
		quit(1)
		return

	if world.kingdoms.size() != 4:
		push_error("Smoke test gagal: harus ada empat kerajaan.")
		world.queue_free()
		quit(1)
		return

	world.advance_to_day(2)
	if world.last_processed_day != 2:
		push_error("Smoke test gagal: simulasi harian tidak maju.")
		world.queue_free()
		quit(1)
		return

	var clock_script: Script = load("res://scripts/autoload/simulation_clock.gd")
	var clock: Node = clock_script.new()
	root.add_child(clock)

	var one_hour_minutes: int = clock.calculate_offline_minutes(100, 3700)
	var capped_minutes: int = clock.calculate_offline_minutes(100, 86500)
	var negative_minutes: int = clock.calculate_offline_minutes(200, 100)

	if one_hour_minutes != 7200:
		push_error("Smoke test gagal: konversi satu jam offline salah.")
		clock.queue_free()
		world.queue_free()
		quit(1)
		return

	if capped_minutes != 14400:
		push_error("Smoke test gagal: batas offline dua jam tidak diterapkan.")
		clock.queue_free()
		world.queue_free()
		quit(1)
		return

	if negative_minutes != 0:
		push_error("Smoke test gagal: waktu negatif harus diabaikan.")
		clock.queue_free()
		world.queue_free()
		quit(1)
		return

	print("KOI KINGDOM SMOKE TEST: PASS")
	clock.queue_free()
	world.queue_free()
	quit(0)
