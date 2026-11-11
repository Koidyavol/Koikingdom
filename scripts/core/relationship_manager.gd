extends Node

var bonds: Dictionary = {}
var _social_accumulator := 0.0
var next_child_number := 1
var last_birth_days: Dictionary = {}

func simulate(citizens: Array, delta: float) -> void:
    _social_accumulator += delta
    if _social_accumulator < 8.0:
        return
    _social_accumulator = 0.0
    for i in range(citizens.size()):
        var first = citizens[i]
        if not is_instance_valid(first):
            continue
        for j in range(i + 1, citizens.size()):
            var second = citizens[j]
            if not is_instance_valid(second):
                continue
            if first.global_position.distance_to(second.global_position) > 68.0:
                continue
            _meet(first, second)

func _meet(first: Node, second: Node) -> void:
    var key := _pair_key(first.npc_id, second.npc_id)
    if not bonds.has(key):
        bonds[key] = {"a": first.npc_id, "b": second.npc_id, "affinity": 0, "meetings": 0}
    var bond: Dictionary = bonds[key]
    bond["affinity"] = mini(100, int(bond.get("affinity", 0)) + _affinity_gain(first, second))
    bond["meetings"] = int(bond.get("meetings", 0)) + 1
    bonds[key] = bond
    var score := int(bond["affinity"])
    if score >= 25:
        _add_friend(first, second.npc_id)
        _add_friend(second, first.npc_id)
    if score >= 70 and first.partner_id.is_empty() and second.partner_id.is_empty():
        if first.gender != second.gender and first.age >= 18 and second.age >= 18:
            first.partner_id = second.npc_id
            second.partner_id = first.npc_id
            first.relationship_status = "Partner"
            second.relationship_status = "Partner"
    if score >= 100 and first.partner_id == second.npc_id and second.partner_id == first.npc_id:
        first.relationship_status = "Married"
        second.relationship_status = "Married"

func _affinity_gain(first: Node, second: Node) -> int:
    var gain := 2
    if first.personality == "Kind" or second.personality == "Kind":
        gain += 1
    if first.personality == "Shy" and second.personality == "Shy":
        gain = 1
    if first.personality == "Cheerful" or second.personality == "Cheerful":
        gain += 1
    return gain

func _add_friend(citizen: Node, friend_id: String) -> void:
    if not citizen.friends.has(friend_id):
        citizen.friends.append(friend_id)


func process_family_day(citizens: Array, current_day: int) -> Array[Dictionary]:
    var births: Array[Dictionary] = []
    var by_id: Dictionary = {}
    for citizen in citizens:
        if not is_instance_valid(citizen):
            continue
        by_id[citizen.npc_id] = citizen
        var elapsed := current_day - int(citizen.last_age_day)
        if elapsed >= 365:
            var years := int(elapsed / 365)
            citizen.age += years
            citizen.last_age_day += years * 365
            if citizen.age >= 7 and citizen.job == "Child":
                citizen.job = "Student"
            elif citizen.age >= 18 and citizen.job == "Student":
                citizen.job = "Farmer"
    for citizen in citizens:
        if not is_instance_valid(citizen) or citizen.relationship_status != "Married":
            continue
        var partner = by_id.get(citizen.partner_id)
        if partner == null or citizen.npc_id > partner.npc_id:
            continue
        if citizen.age < 20 or partner.age < 20:
            continue
        var couple_key := _pair_key(citizen.npc_id, partner.npc_id)
        var married_day := maxi(int(citizen.married_day), int(partner.married_day))
        var last_birth_day := int(last_birth_days.get(couple_key, married_day))
        if current_day - married_day < 30 or current_day - last_birth_day < 120:
            continue
        if births.size() >= 2:
            break
        var child_gender := "Female" if randi() % 2 == 0 else "Male"
        var child_name := "Hana" if child_gender == "Female" else "Ren"
        var child_id := "child_%04d" % next_child_number
        next_child_number += 1
        var child_race := citizen.race if randi() % 2 == 0 else partner.race
        births.append({
            "id": child_id, "name": child_name, "race": child_race,
            "gender": child_gender, "age": 0, "job": "Child",
            "personality": "Cheerful", "hunger": 90.0, "energy": 100.0,
            "social": 80.0, "position": [
                (citizen.position.x + partner.position.x) * 0.5,
                (citizen.position.y + partner.position.y) * 0.5
            ], "parent_ids": [citizen.npc_id, partner.npc_id],
            "last_age_day": current_day, "married_day": 0
        })
        last_birth_days[couple_key] = current_day
    return births

func get_bond(first_id: String, second_id: String) -> Dictionary:
    return bonds.get(_pair_key(first_id, second_id), {})

func get_save_data() -> Dictionary:
    return {"bonds": bonds.duplicate(true), "next_child_number": next_child_number, "last_birth_days": last_birth_days.duplicate(true)}

func apply_state(state: Dictionary) -> void:
    bonds = state.get("bonds", {}).duplicate(true)
    next_child_number = maxi(1, int(state.get("next_child_number", 1)))
    last_birth_days = state.get("last_birth_days", {}).duplicate(true)

func reset() -> void:
    bonds.clear()
    last_birth_days.clear()
    next_child_number = 1
    _social_accumulator = 0.0

func _pair_key(first_id: String, second_id: String) -> String:
    return first_id + "|" + second_id if first_id < second_id else second_id + "|" + first_id
