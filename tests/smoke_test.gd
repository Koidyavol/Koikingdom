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

	var citizen_script: Script = load("res://scripts/autoload/citizen_manager.gd")
	var citizen: Object = citizen_script.new()
	var citizen_node := citizen as Node
	root.add_child(citizen_node)
	citizen.call("apply_state", {}, 420)

	var citizen_state: Dictionary = citizen.call("get_state")
	var citizen_list: Array = citizen_state.get("citizens", [])
	if citizen_list.size() != 12:
		push_error("Smoke test gagal: roster awal harus memiliki 12 warga.")
		citizen_node.queue_free()
		clock_node.queue_free()
		world_node.queue_free()
		quit(1)
		return

	var seen_ids := {}
	for citizen_data in citizen_list:
		var citizen_id := str(citizen_data.get("id", ""))
		if citizen_id.is_empty() or seen_ids.has(citizen_id):
			push_error("Smoke test gagal: ID warga kosong atau duplikat.")
			citizen_node.queue_free()
			clock_node.queue_free()
			world_node.queue_free()
			quit(1)
			return
		seen_ids[citizen_id] = true
		if str(citizen_data.get("gender", "")).is_empty() or str(citizen_data.get("race", "")).is_empty():
			push_error("Smoke test gagal: gender dan ras warga harus terisi.")
			citizen_node.queue_free()
			clock_node.queue_free()
			world_node.queue_free()
			quit(1)
			return

	var asteria_summary: Dictionary = citizen.call("get_summary_for_kingdom", "asteria")
	if int(asteria_summary.get("count", 0)) != 3:
		push_error("Smoke test gagal: Asteria harus memiliki 3 warga contoh.")
		citizen_node.queue_free()
		clock_node.queue_free()
		world_node.queue_free()
		quit(1)
		return

	citizen.call("advance_to_minute", 540)
	var work_summary: Dictionary = citizen.call("get_summary_for_kingdom", "asteria")
	var activity_counts: Dictionary = work_summary.get("activity_counts", {})
	if int(activity_counts.get("Bekerja", 0)) != 3:
		push_error("Smoke test gagal: jadwal kerja Asteria pukul 09.00 tidak berjalan.")
		citizen_node.queue_free()
		clock_node.queue_free()
		world_node.queue_free()
		quit(1)
		return

	var offline_target := 420 + 14400
	citizen.call("advance_to_minute", offline_target)
	var citizen_after_catchup: Dictionary = citizen.call("get_state")
	if int(citizen_after_catchup.get("last_processed_total_game_minutes", -1)) != offline_target:
		push_error("Smoke test gagal: penanda catch-up warga tidak sesuai target.")
		citizen_node.queue_free()
		clock_node.queue_free()
		world_node.queue_free()
		quit(1)
		return

	var restored: Object = citizen_script.new()
	var restored_node := restored as Node
	root.add_child(restored_node)
	restored.call("apply_state", citizen_after_catchup, offline_target)
	var restored_summary: Dictionary = restored.call("get_summary_for_kingdom", "asteria")
	if int(restored_summary.get("count", 0)) != 3:
		push_error("Smoke test gagal: roster warga tidak pulih setelah load.")
		restored_node.queue_free()
		citizen_node.queue_free()
		clock_node.queue_free()
		world_node.queue_free()
		quit(1)
		return

	print("KOI KINGDOM SMOKE TEST: PASS")
	restored_node.queue_free()
	citizen_node.queue_free()
	clock_node.queue_free()
	world_node.queue_free()
	quit(0)
