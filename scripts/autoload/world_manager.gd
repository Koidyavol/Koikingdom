extends Node

signal kingdom_updated(kingdom_id: String)
signal world_day_processed(day_number: int)

const KINGDOM_ORDER := ["asteria", "mizuhara", "verdantia", "drakemont"]
const MAX_RESOURCE := 999999999
const MAX_POPULATION := 100000000
const MAX_CATCHUP_DAYS := 3650

var kingdoms: Dictionary = {}
var last_processed_day := 1


func _ready() -> void:
	kingdoms = build_default_kingdoms()


func build_default_kingdoms() -> Dictionary:
	return {
		"asteria": {
			"id": "asteria",
			"name": "Asteria",
			"ruler": "Ratu Elara",
			"population": 1200,
			"treasury": 4200,
			"food": 5200,
			"farms": 12,
			"guard_count": 18,
			"tax_rate": 0.020,
			"stability": 78.0,
			"growth_remainder": 0.0
		},
		"mizuhara": {
			"id": "mizuhara",
			"name": "Mizuhara",
			"ruler": "Raja Haruto",
			"population": 980,
			"treasury": 3900,
			"food": 4600,
			"farms": 10,
			"guard_count": 16,
			"tax_rate": 0.022,
			"stability": 82.0,
			"growth_remainder": 0.0
		},
		"verdantia": {
			"id": "verdantia",
			"name": "Verdantia",
			"ruler": "Ratu Sylva",
			"population": 1100,
			"treasury": 3600,
			"food": 5000,
			"farms": 14,
			"guard_count": 14,
			"tax_rate": 0.018,
			"stability": 86.0,
			"growth_remainder": 0.0
		},
		"drakemont": {
			"id": "drakemont",
			"name": "Drakemont",
			"ruler": "Raja Kael",
			"population": 870,
			"treasury": 5100,
			"food": 4100,
			"farms": 9,
			"guard_count": 22,
			"tax_rate": 0.025,
			"stability": 74.0,
			"growth_remainder": 0.0
		}
	}


func apply_state(state: Dictionary) -> void:
	var merged := build_default_kingdoms()
	var saved_kingdoms: Variant = state.get("kingdoms", {})

	if saved_kingdoms is Dictionary:
		for kingdom_id in KINGDOM_ORDER:
			var saved: Variant = saved_kingdoms.get(kingdom_id, {})
			if saved is Dictionary:
				merged[kingdom_id] = _sanitize_kingdom(saved, merged[kingdom_id])

	kingdoms = merged
	last_processed_day = clampi(int(state.get("last_processed_day", 1)), 1, 100000)


func get_state() -> Dictionary:
	return {
		"kingdoms": kingdoms.duplicate(true),
		"last_processed_day": last_processed_day
	}


func get_kingdom(kingdom_id: String) -> Dictionary:
	var value: Variant = kingdoms.get(kingdom_id, {})
	if value is Dictionary:
		return value.duplicate(true)
	return {}


func advance_to_day(target_day: int) -> void:
	var safe_target := maxi(last_processed_day, target_day)
	var days_to_process := mini(safe_target - last_processed_day, MAX_CATCHUP_DAYS)

	for _day_index in range(days_to_process):
		for kingdom_id in KINGDOM_ORDER:
			_simulate_kingdom_day(kingdom_id)

		last_processed_day += 1
		world_day_processed.emit(last_processed_day)


func validate_state() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_names := {}

	if kingdoms.size() != KINGDOM_ORDER.size():
		errors.append("Jumlah kerajaan harus tepat empat.")

	for kingdom_id in KINGDOM_ORDER:
		if not kingdoms.has(kingdom_id):
			errors.append("Kerajaan wajib tidak ditemukan: %s." % kingdom_id)
			continue

		var kingdom: Dictionary = kingdoms[kingdom_id]
		var kingdom_name := str(kingdom.get("name", ""))
		if kingdom_name.is_empty():
			errors.append("Nama kerajaan %s kosong." % kingdom_id)
		elif seen_names.has(kingdom_name):
			errors.append("Nama kerajaan duplikat: %s." % kingdom_name)
		else:
			seen_names[kingdom_name] = true

		if int(kingdom.get("population", 0)) < 1:
			errors.append("Populasi %s harus minimal satu." % kingdom_id)
		if int(kingdom.get("treasury", -1)) < 0:
			errors.append("Perbendaharaan %s tidak boleh negatif." % kingdom_id)
		if int(kingdom.get("food", -1)) < 0:
			errors.append("Pangan %s tidak boleh negatif." % kingdom_id)

		var tax_rate := float(kingdom.get("tax_rate", -1.0))
		if tax_rate < 0.0 or tax_rate > 0.10:
			errors.append("Pajak %s harus berada pada rentang 0-10%%." % kingdom_id)

		var stability := float(kingdom.get("stability", -1.0))
		if stability < 0.0 or stability > 100.0:
			errors.append("Stabilitas %s harus berada pada rentang 0-100." % kingdom_id)

	return errors


func _sanitize_kingdom(saved: Dictionary, defaults: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)

	result["name"] = str(saved.get("name", defaults["name"]))
	result["ruler"] = str(saved.get("ruler", defaults["ruler"]))
	result["population"] = clampi(int(saved.get("population", defaults["population"])), 1, MAX_POPULATION)
	result["treasury"] = clampi(int(saved.get("treasury", defaults["treasury"])), 0, MAX_RESOURCE)
	result["food"] = clampi(int(saved.get("food", defaults["food"])), 0, MAX_RESOURCE)
	result["farms"] = clampi(int(saved.get("farms", defaults["farms"])), 0, 100000)
	result["guard_count"] = clampi(int(saved.get("guard_count", defaults["guard_count"])), 0, 100000)
	result["tax_rate"] = clampf(float(saved.get("tax_rate", defaults["tax_rate"])), 0.0, 0.10)
	result["stability"] = clampf(float(saved.get("stability", defaults["stability"])), 0.0, 100.0)
	result["growth_remainder"] = clampf(float(saved.get("growth_remainder", 0.0)), 0.0, 0.999999)
	return result


func _simulate_kingdom_day(kingdom_id: String) -> void:
	if not kingdoms.has(kingdom_id):
		return

	var kingdom: Dictionary = kingdoms[kingdom_id]
	var population := clampi(int(kingdom.get("population", 1)), 1, MAX_POPULATION)
	var farms := maxi(0, int(kingdom.get("farms", 0)))
	var guards := maxi(0, int(kingdom.get("guard_count", 0)))
	var tax_rate := clampf(float(kingdom.get("tax_rate", 0.02)), 0.0, 0.10)

	var food_produced := farms * 18
	var food_consumed := int(ceil(float(population) * 0.12))
	var food := clampi(
		int(kingdom.get("food", 0)) + food_produced - food_consumed,
		0,
		MAX_RESOURCE
	)

	var tax_income := int(round(float(population) * tax_rate * 2.0))
	var treasury := clampi(
		int(kingdom.get("treasury", 0)) + tax_income - guards,
		0,
		MAX_RESOURCE
	)

	var stability := float(kingdom.get("stability", 50.0))
	if food <= 0:
		stability -= 1.0
	elif food < food_consumed:
		stability -= 0.3
	else:
		stability += 0.05

	if tax_rate > 0.05:
		stability -= 0.15
	stability = clampf(stability, 0.0, 100.0)

	var growth_remainder := float(kingdom.get("growth_remainder", 0.0))
	if food > 0 and stability >= 50.0 and population < MAX_POPULATION:
		growth_remainder += float(population) * 0.0002
		var new_residents := int(floor(growth_remainder))
		if new_residents > 0:
			population = mini(population + new_residents, MAX_POPULATION)
			growth_remainder -= float(new_residents)

	kingdom["population"] = population
	kingdom["food"] = food
	kingdom["treasury"] = treasury
	kingdom["stability"] = stability
	kingdom["growth_remainder"] = growth_remainder
	kingdoms[kingdom_id] = kingdom
	kingdom_updated.emit(kingdom_id)
