extends Node

const KINGDOM_ORDER := ["asteria", "mizuhara", "verdantia", "drakemont"]
const MAX_CITIZENS := 64
const MAX_CATCHUP_MINUTES := 1440
const STAT_MAX := 100.0

var citizens: Array[Dictionary] = []
var last_processed_total_game_minutes := 0


func apply_state(state: Dictionary, current_total_game_minutes: int) -> void:
	var defaults := _build_default_citizens()
	var merged: Array[Dictionary] = []
	var saved_list: Variant = state.get("citizens", [])
	var saved_by_id: Dictionary = {}

	if saved_list is Array:
		for raw in saved_list:
			if raw is Dictionary:
				var citizen_id := str(raw.get("id", ""))
				if not citizen_id.is_empty() and not saved_by_id.has(citizen_id):
					saved_by_id[citizen_id] = raw

	for default_citizen in defaults:
		var citizen_id: String = default_citizen["id"]
		var raw: Variant = saved_by_id.get(citizen_id, {})
		merged.append(_sanitize_citizen(raw, default_citizen) if raw is Dictionary else default_citizen.duplicate(true))
		saved_by_id.erase(citizen_id)

	for citizen_id in saved_by_id:
		if merged.size() >= MAX_CITIZENS:
			break
		var raw: Variant = saved_by_id[citizen_id]
		if raw is Dictionary:
			var extra_default := _make_fallback_citizen(raw, str(citizen_id))
			if not extra_default.is_empty():
				merged.append(_sanitize_citizen(raw, extra_default))

	citizens = merged
	last_processed_total_game_minutes = clampi(
		int(state.get("last_processed_total_game_minutes", current_total_game_minutes)),
		0,
		maxi(0, current_total_game_minutes)
	)
	if current_total_game_minutes - last_processed_total_game_minutes > MAX_CATCHUP_MINUTES:
		last_processed_total_game_minutes = current_total_game_minutes - MAX_CATCHUP_MINUTES


func get_state() -> Dictionary:
	var copy: Array[Dictionary] = []
	for citizen in citizens:
		copy.append(citizen.duplicate(true))
	return {
		"citizens": copy,
		"last_processed_total_game_minutes": last_processed_total_game_minutes
	}


func advance_to_minute(target_total_game_minutes: int) -> void:
	if target_total_game_minutes <= last_processed_total_game_minutes:
		return

	var start_minute := last_processed_total_game_minutes
	var delta_minutes := target_total_game_minutes - start_minute
	if delta_minutes > MAX_CATCHUP_MINUTES:
		start_minute = target_total_game_minutes - MAX_CATCHUP_MINUTES

	for minute in range(start_minute + 1, target_total_game_minutes + 1):
		_simulate_one_minute(minute)

	last_processed_total_game_minutes = target_total_game_minutes


func get_summary_for_kingdom(kingdom_id: String) -> Dictionary:
	var summary := {
		"count": 0,
		"activity_counts": {
			"Tidur": 0,
			"Makan": 0,
			"Bekerja": 0,
			"Bersosialisasi": 0,
			"Santai": 0
		},
		"average_hunger": 0.0,
		"average_energy": 0.0,
		"average_social": 0.0
	}
	var total_hunger := 0.0
	var total_energy := 0.0
	var total_social := 0.0

	for citizen in citizens:
		if str(citizen.get("kingdom_id", "")) != kingdom_id:
			continue
		summary["count"] += 1
		var activity := str(citizen.get("activity", "Santai"))
		var activity_counts: Dictionary = summary["activity_counts"]
		activity_counts[activity] = int(activity_counts.get(activity, 0)) + 1
		total_hunger += float(citizen.get("hunger", 100.0))
		total_energy += float(citizen.get("energy", 100.0))
		total_social += float(citizen.get("social", 100.0))

	var count := int(summary["count"])
	if count > 0:
		summary["average_hunger"] = total_hunger / count
		summary["average_energy"] = total_energy / count
		summary["average_social"] = total_social / count
	return summary


func get_citizens_for_kingdom(kingdom_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for citizen in citizens:
		if str(citizen.get("kingdom_id", "")) == kingdom_id:
			result.append(citizen.duplicate(true))
	return result


func _simulate_one_minute(total_game_minutes: int) -> void:
	var hour := int((total_game_minutes % 1440) / 60)
	for citizen in citizens:
		_decide_activity(citizen, hour)
		var hunger := float(citizen.get("hunger", 100.0))
		var energy := float(citizen.get("energy", 100.0))
		var social := float(citizen.get("social", 100.0))

		match str(citizen.get("activity", "Santai")):
			"Tidur":
				energy += 0.12
				hunger -= 0.02
				social -= 0.01
			"Makan":
				hunger += 0.18
				energy -= 0.02
				social += 0.01
			"Bekerja":
				energy -= 0.06
				hunger -= 0.035
				social -= 0.015
			"Bersosialisasi":
				energy -= 0.035
				hunger -= 0.025
				social += 0.09
			_:
				energy += 0.04
				hunger -= 0.025
				social += 0.015

		citizen["hunger"] = clampf(hunger, 0.0, STAT_MAX)
		citizen["energy"] = clampf(energy, 0.0, STAT_MAX)
		citizen["social"] = clampf(social, 0.0, STAT_MAX)


func _decide_activity(citizen: Dictionary, hour: int) -> void:
	var energy := float(citizen.get("energy", 100.0))
	var hunger := float(citizen.get("hunger", 100.0))
	var previous_activity := str(citizen.get("activity", ""))

	if hour >= 22 or hour < 6 or energy < 18.0 or (previous_activity == "Tidur" and energy < 65.0):
		citizen["activity"] = "Tidur"
		citizen["activity_detail"] = "Istirahat malam"
	elif hunger < 25.0 or hour == 12:
		citizen["activity"] = "Makan"
		citizen["activity_detail"] = "Makan"
	elif hour >= 8 and hour <= 16:
		citizen["activity"] = "Bekerja"
		citizen["activity_detail"] = str(citizen.get("job", "Pekerjaan"))
	elif hour >= 18 and hour <= 21:
		citizen["activity"] = "Bersosialisasi"
		citizen["activity_detail"] = "Bertemu warga"
	else:
		citizen["activity"] = "Santai"
		citizen["activity_detail"] = "Waktu luang"


func _build_default_citizens() -> Array[Dictionary]:
	var roster := [
		["asteria_001", "Mira", "asteria", "Petani", 29, "Tekun"],
		["asteria_002", "Leon", "asteria", "Pedagang", 34, "Ramah"],
		["asteria_003", "Hana", "asteria", "Penjaga", 26, "Berani"],
		["mizuhara_001", "Yuki", "mizuhara", "Petani", 24, "Tekun"],
		["mizuhara_002", "Ren", "mizuhara", "Pedagang", 31, "Cermat"],
		["mizuhara_003", "Akira", "mizuhara", "Penjaga", 28, "Disiplin"],
		["verdantia_001", "Sylvi", "verdantia", "Petani", 27, "Tenang"],
		["verdantia_002", "Arin", "verdantia", "Tabib", 35, "Peduli"],
		["verdantia_003", "Eira", "verdantia", "Penjaga", 22, "Berani"],
		["drakemont_001", "Kael", "drakemont", "Petani", 32, "Tekun"],
		["drakemont_002", "Neris", "drakemont", "Pedagang", 30, "Cermat"],
		["drakemont_003", "Doran", "drakemont", "Penjaga", 38, "Disiplin"]
	]
	var result: Array[Dictionary] = []
	for row in roster:
		result.append({
			"id": row[0],
			"name": row[1],
			"kingdom_id": row[2],
			"job": row[3],
			"age": row[4],
			"personality": row[5],
			"hunger": 100.0,
			"energy": 100.0,
			"social": 100.0,
			"activity": "Santai",
			"activity_detail": "Waktu luang"
		})
	return result


func _sanitize_citizen(saved: Dictionary, defaults: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	result["name"] = str(saved.get("name", defaults["name"]))
	result["job"] = str(saved.get("job", defaults["job"]))
	result["age"] = clampi(int(saved.get("age", defaults["age"])), 1, 120)
	result["personality"] = str(saved.get("personality", defaults["personality"]))
	result["hunger"] = clampf(float(saved.get("hunger", defaults["hunger"])), 0.0, STAT_MAX)
	result["energy"] = clampf(float(saved.get("energy", defaults["energy"])), 0.0, STAT_MAX)
	result["social"] = clampf(float(saved.get("social", defaults["social"])), 0.0, STAT_MAX)
	result["activity"] = str(saved.get("activity", defaults["activity"]))
	result["activity_detail"] = str(saved.get("activity_detail", defaults["activity_detail"]))
	return result


func _make_fallback_citizen(saved: Dictionary, citizen_id: String) -> Dictionary:
	var kingdom_id := str(saved.get("kingdom_id", ""))
	if not KINGDOM_ORDER.has(kingdom_id):
		return {}
	return {
		"id": citizen_id,
		"name": str(saved.get("name", citizen_id)),
		"kingdom_id": kingdom_id,
		"job": str(saved.get("job", "Warga")),
		"age": 18,
		"personality": "Biasa",
		"hunger": 100.0,
		"energy": 100.0,
		"social": 100.0,
		"activity": "Santai",
		"activity_detail": "Waktu luang"
	}
