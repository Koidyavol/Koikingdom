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
var inventory: Array[Dictionary] = []
var dungeon_floor := 0
var monster_name := ""
var monster_health := 0
var monster_max_health := 0
var monster_attack := 0
var monster_defense := 0
var dungeon_active := false
var last_result := "Siap berpetualang"

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

func _add_loot() -> void:
    var roll := randi_range(0, 99)
    if roll < 35:
        inventory.append({"name": "Ramuan Kecil", "type": "potion", "amount": 1})
        last_result += " | Mendapat Ramuan"
    elif roll < 55:
        inventory.append({"name": "Bijih Besi", "type": "material", "amount": 1})
        last_result += " | Mendapat Bijih Besi"
    elif roll < 65:
        inventory.append({"name": "Kristal Ajaib", "type": "material", "amount": 1})
        last_result += " | Mendapat Kristal"

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
        "attack": attack, "defense": defense, "gold": gold, "weapon_name": weapon_name,
        "armor_name": armor_name, "inventory": inventory.duplicate(true),
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
    attack = maxi(1, int(state.get("attack", 12)))
    defense = maxi(0, int(state.get("defense", 5)))
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
    inventory.clear()
    dungeon_floor = 0
    monster_name = ""
    monster_health = 0
    monster_max_health = 0
    monster_attack = 0
    monster_defense = 0
    dungeon_active = false
    last_result = "Siap berpetualang"
