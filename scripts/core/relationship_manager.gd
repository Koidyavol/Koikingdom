extends Node

var bonds: Dictionary = {}
var _social_accumulator := 0.0

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

func get_bond(first_id: String, second_id: String) -> Dictionary:
    return bonds.get(_pair_key(first_id, second_id), {})

func get_save_data() -> Dictionary:
    return {"bonds": bonds.duplicate(true)}

func apply_state(state: Dictionary) -> void:
    bonds = state.get("bonds", {}).duplicate(true)

func reset() -> void:
    bonds.clear()
    _social_accumulator = 0.0

func _pair_key(first_id: String, second_id: String) -> String:
    return first_id + "|" + second_id if first_id < second_id else second_id + "|" + first_id
