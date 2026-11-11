extends Node

var level := 1
var experience := 0
var health := 100
var max_health := 100
var attack := 12
var defense := 5
var gold := 0
var weapon_name := "Pedang Kayu"
var armor_name := "Pakaian Petualang"
var weapon_bonus := 0
var armor_bonus := 0
var base_attack := 12
var base_defense := 5
var inventory: Array[Dictionary] = []
var dungeon_floor := 0
var monster_name := ""
var monster_health := 0
var monster_max_health := 0
var monster_attack := 0
var monster_defense := 0
var dungeon_active := false
var last_result := "Siap berpetualang"

const EQUIPMENT := {
    "Pedang Besi": {"slot": "weapon", "attack": 6, "defense": 0, "price": 45},
    "Pedang Baja": {"slot": "weapon", "attack": 12, "defense": 0, "price": 110},
    "Jubah Kulit": {"slot": "armor", "attack": 0, "defense": 4, "price": 40},
    "Zirah Besi": {"slot": "armor", "attack": 0, "defense": 9, "price": 100}
}
const RECIPES := {
    "Pedang Besi": {"Bijih Besi": 3, "Kristal Ajaib": 1},
    "Jubah Kulit": {"Bijih Besi": 2}
}
const MONSTERS := [
    {"name": "Slime Hutan", "hp": 28, "attack": 5, "defense": 1, "exp": 12, "gold": 6},
    {"name": "Serigala Liar", "hp": 42, "attack": 8, "defense": 2, "exp": 18, "gold": 10},
    {"name": "Goblin Penjaga", "hp": 58, "attack": 10, "defense": 4, "exp": 25, "gold": 15},
    {"name": "Ksatria Bayangan", "hp": 85, "attack": 14, "defense": 6, "exp": 38, "gold": 24},
    {"name": "Naga Muda", "hp": 125, "attack": 19, "defense": 8, "exp": 60, "gold": 40}
]

func enter_dungeon() -> bool:
    if dungeon_active:
        return false
    dungeon_active = true
    dungeon_floor = 1
    health = max_health
    _spawn_monster()
    last_result = "Memasuki dungeon"
    return true

func _spawn_monster() -> void:
    var index := mini(MONSTERS.size() - 1, maxi(0, dungeon_floor - 1))
    var template: Dictionary = MONSTERS[index]
    monster_name = str(template.name)
    monster_max_health = int(template.hp) + (dungeon_floor - index - 1) * 12
    monster_health = monster_max_health
    monster_attack = int(template.attack) + (dungeon_floor - index - 1) * 2
    monster_defense = int(template.defense) + (dungeon_floor - index - 1)
    
func attack_monster() -> String:
    if not dungeon_active or monster_health <= 0:
        return "Tidak ada monster untuk dilawan"
    var damage := maxi(1, attack + randi_range(-3, 4) - monster_defense)
    monster_health = maxi(0, monster_health - damage)
    if monster_health <= 0:
        _win_battle()
        return last_result
    var incoming := maxi(1, monster_attack + randi_range(-2, 2) - defense)
    health = maxi(0, health - incoming)
    if health <= 0:
        dungeon_active = false
        var lost_gold := mini(gold, 5 + dungeon_floor * 2)
        gold -= lost_gold
        health = maxi(1, max_health / 2)
        last_result = "Kamu mundur dari dungeon. Emas hilang: %d" % lost_gold
    else:
        last_result = "Serangan %d | %s membalas %d" % [damage, monster_name, incoming]
    return last_result

func _win_battle() -> void:
    var index := mini(MONSTERS.size() - 1, maxi(0, dungeon_floor - 1))
    var template: Dictionary = MONSTERS[index]
    var gained_exp := int(template.exp) + dungeon_floor * 2
    var gained_gold := int(template.gold) + dungeon_floor
    experience += gained_exp
    gold += gained_gold
    _add_loot()
    last_result = "%s dikalahkan! +%d EXP, +%d emas" % [monster_name, gained_exp, gained_gold]
    _check_level_up()
    dungeon_floor += 1
    _spawn_monster()

func _add_item(item_name: String, item_type: String, amount: int = 1) -> void:
    for item in inventory:
        if str(item.get("name", "")) == item_name:
            item["amount"] = int(item.get("amount", 1)) + amount
            return
    inventory.append({"name": item_name, "type": item_type, "amount": amount})

func _add_loot() -> void:
    var roll := randi_range(0, 99)
    if roll < 35:
        _add_item("Ramuan Kecil", "potion")
        last_result += " | Mendapat Ramuan"
    elif roll < 58:
        _add_item("Bijih Besi", "material")
        last_result += " | Mendapat Bijih Besi"
    elif roll < 70:
        _add_item("Kristal Ajaib", "material")
        last_result += " | Mendapat Kristal"
    elif roll < 78:
        _add_item("Pedang Besi", "equipment")
        last_result += " | Mendapat Pedang Besi"
    elif roll < 86:
        _add_item("Jubah Kulit", "equipment")
        last_result += " | Mendapat Jubah Kulit"

func _recalculate_equipment_stats() -> void:
    attack = base_attack + weapon_bonus
    defense = base_defense + armor_bonus

func equip_item(item_name: String) -> bool:
    if not EQUIPMENT.has(item_name):
        last_result = "Peralatan tidak dikenal"
        return false
    var inventory_index := -1
    for index in range(inventory.size()):
        if str(inventory[index].get("name", "")) == item_name and int(inventory[index].get("amount", 1)) > 0:
            inventory_index = index
            break
    if inventory_index < 0:
        last_result = "Item tidak ada di inventaris"
        return false
    var item: Dictionary = EQUIPMENT[item_name]
    if str(item.slot) == "weapon":
        weapon_name = item_name
        weapon_bonus = int(item.attack)
    else:
        armor_name = item_name
        armor_bonus = int(item.defense)
    _recalculate_equipment_stats()
    inventory[inventory_index]["amount"] = int(inventory[inventory_index].get("amount", 1)) - 1
    if int(inventory[inventory_index]["amount"]) <= 0:
        inventory.remove_at(inventory_index)
    last_result = "%s berhasil dipakai" % item_name
    return true

func craft_item(item_name: String) -> bool:
    if not RECIPES.has(item_name):
        last_result = "Resep belum tersedia"
        return false
    var recipe: Dictionary = RECIPES[item_name]
    for material_name in recipe:
        if _count_item(str(material_name)) < int(recipe[material_name]):
            last_result = "Bahan tidak cukup untuk %s" % item_name
            return false
    for material_name in recipe:
        _remove_item(str(material_name), int(recipe[material_name]))
    _add_item(item_name, "equipment")
    last_result = "%s berhasil dibuat" % item_name
    return true

func _count_item(item_name: String) -> int:
    for item in inventory:
        if str(item.get("name", "")) == item_name:
            return int(item.get("amount", 0))
    return 0

func _remove_item(item_name: String, amount: int) -> void:
    for index in range(inventory.size() - 1, -1, -1):
        if str(inventory[index].get("name", "")) == item_name:
            var remaining := int(inventory[index].get("amount", 0)) - amount
            if remaining <= 0:
                inventory.remove_at(index)
            else:
                inventory[index]["amount"] = remaining
            return

func _check_level_up() -> void:
    while experience >= level * 50:
        experience -= level * 50
        level += 1
        max_health += 12
        health = max_health
        attack += 3
        defense += 2
        last_result += " | LEVEL UP %d!" % level

func use_potion() -> bool:
    for index in range(inventory.size()):
        if str(inventory[index].get("type", "")) == "potion":
            health = mini(max_health, health + 35)
            inventory[index]["amount"] = int(inventory[index].get("amount", 1)) - 1
            if int(inventory[index]["amount"]) <= 0:
                inventory.remove_at(index)
            last_result = "Ramuan digunakan. HP %d/%d" % [health, max_health]
            return true
    last_result = "Tidak ada ramuan"
    return false

func leave_dungeon() -> void:
    dungeon_active = false
    dungeon_floor = 0
    monster_name = ""
    monster_health = 0
    last_result = "Keluar dari dungeon"

func get_summary() -> String:
    return "Lv.%d | HP %d/%d | ATK %d | DEF %d | EXP %d/%d | Emas %d" % [
        level, health, max_health, attack, defense, experience, level * 50, gold
    ]

func get_inventory_summary() -> String:
    if inventory.is_empty():
        return "Inventaris: Kosong"
    var counts: Dictionary = {}
    for item in inventory:
        var item_name := str(item.get("name", "Item"))
        counts[item_name] = int(counts.get(item_name, 0)) + int(item.get("amount", 1))
    var parts: PackedStringArray = []
    for item_name in counts:
        parts.append("%s x%d" % [item_name, counts[item_name]])
    return "Inventaris: " + ", ".join(parts)

func get_save_data() -> Dictionary:
    return {
        "level": level, "experience": experience, "health": health, "max_health": max_health,
        "attack": attack, "defense": defense, "base_attack": base_attack, "base_defense": base_defense,
        "weapon_bonus": weapon_bonus, "armor_bonus": armor_bonus,
        "gold": gold, "weapon_name": weapon_name, "armor_name": armor_name,
        "inventory": inventory.duplicate(true),
        "dungeon_floor": dungeon_floor, "monster_name": monster_name,
        "monster_health": monster_health, "monster_max_health": monster_max_health,
        "monster_attack": monster_attack, "monster_defense": monster_defense,
        "dungeon_active": dungeon_active, "last_result": last_result
    }

func apply_state(state: Dictionary) -> void:
    level = maxi(1, int(state.get("level", 1)))
    experience = maxi(0, int(state.get("experience", 0)))
    max_health = maxi(1, int(state.get("max_health", 100)))
    health = clampi(int(state.get("health", max_health)), 1, max_health)
    base_attack = maxi(1, int(state.get("base_attack", state.get("attack", 12))))
    base_defense = maxi(0, int(state.get("base_defense", state.get("defense", 5))))
    weapon_bonus = maxi(0, int(state.get("weapon_bonus", 0)))
    armor_bonus = maxi(0, int(state.get("armor_bonus", 0)))
    attack = maxi(1, int(state.get("attack", base_attack + weapon_bonus)))
    defense = maxi(0, int(state.get("defense", base_defense + armor_bonus)))
    gold = maxi(0, int(state.get("gold", 0)))
    weapon_name = str(state.get("weapon_name", "Pedang Kayu"))
    armor_name = str(state.get("armor_name", "Pakaian Petualang"))
    inventory.clear()
    for item in state.get("inventory", []):
        if item is Dictionary:
            inventory.append(item.duplicate(true))
    dungeon_floor = maxi(0, int(state.get("dungeon_floor", 0)))
    monster_name = str(state.get("monster_name", ""))
    monster_max_health = maxi(0, int(state.get("monster_max_health", 0)))
    monster_health = clampi(int(state.get("monster_health", 0)), 0, monster_max_health)
    monster_attack = maxi(0, int(state.get("monster_attack", 0)))
    monster_defense = maxi(0, int(state.get("monster_defense", 0)))
    dungeon_active = bool(state.get("dungeon_active", false))
    last_result = str(state.get("last_result", "Siap berpetualang"))
    _recalculate_equipment_stats()

func reset() -> void:
    level = 1
    experience = 0
    health = 100
    max_health = 100
    attack = 12
    defense = 5
    gold = 0
    weapon_name = "Pedang Kayu"
    armor_name = "Pakaian Petualang"
    weapon_bonus = 0
    armor_bonus = 0
    base_attack = 12
    base_defense = 5
    inventory.clear()
    dungeon_floor = 0
    monster_name = ""
    monster_health = 0
    monster_max_health = 0
    monster_attack = 0
    monster_defense = 0
    dungeon_active = false
    last_result = "Siap berpetualang"
