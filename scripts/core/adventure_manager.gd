extends Node

var level := 1
var experience := 0
var health := 100
var max_health := 100
var mana := 40
var max_mana := 40
var skill_points := 0
var unlocked_skills: Array[String] = []
var guard_stance := false
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
var guild_reputation := 0
var guild_rank := "Pemula"
var guild_quests: Array[Dictionary] = []
var monster_is_boss := false
var _guild_board_day := -1

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
    _record_quest_progress("floor", dungeon_floor)
    last_result = "Memasuki dungeon"
    return true

func _spawn_monster() -> void:
    var index := mini(MONSTERS.size() - 1, maxi(0, dungeon_floor - 1))
    var template: Dictionary = MONSTERS[index]
    monster_is_boss = dungeon_floor % 5 == 0
    monster_name = ("Boss " if monster_is_boss else "") + str(template.name)
    var scale := dungeon_floor - index - 1
    var boss_multiplier := 2 if monster_is_boss else 1
    monster_max_health = (int(template.hp) + scale * 12) * boss_multiplier
    monster_health = monster_max_health
    monster_attack = (int(template.attack) + scale * 2) * boss_multiplier
    monster_defense = (int(template.defense) + scale) * boss_multiplier
    
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
    last_result = "BOSS DIKALAHKAN! Reputasi guild +20" if monster_is_boss else ""
    if monster_is_boss:
        gained_exp *= 3
        gained_gold *= 3
        guild_reputation += 20
    experience += gained_exp
    gold += gained_gold
    _add_loot()
    last_result += " | %s dikalahkan! +%d EXP, +%d emas" % [monster_name, gained_exp, gained_gold]
    _record_quest_progress("kill", 1)
    _check_level_up()
    dungeon_floor += 1
    _spawn_monster()
    _record_quest_progress("floor", dungeon_floor)

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
        _record_quest_progress("collect", 1)
        last_result += " | Mendapat Bijih Besi"
    elif roll < 70:
        _add_item("Kristal Ajaib", "material")
        _record_quest_progress("collect", 1)
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
        if weapon_name != "Pedang Kayu" and EQUIPMENT.has(weapon_name):
            _add_item(weapon_name, "equipment")
        weapon_name = item_name
        weapon_bonus = int(item.attack)
    else:
        if armor_name != "Pakaian Petualang" and EQUIPMENT.has(armor_name):
            _add_item(armor_name, "equipment")
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
        max_mana += 5
        mana = max_mana
        skill_points += 1
        health = max_health
        base_attack += 3
        base_defense += 2
        _recalculate_equipment_stats()
        last_result += " | LEVEL UP %d!" % level

func unlock_skill(skill_name: String) -> bool:
    var required_level := 99
    if skill_name == "Power Strike":
        required_level = 2
    elif skill_name == "Guard Stance":
        required_level = 3
    elif skill_name == "Healing Light":
        required_level = 4
    else:
        last_result = "Skill tidak dikenal"
        return false
    if unlocked_skills.has(skill_name):
        last_result = "Skill sudah dipelajari"
        return false
    if level < required_level or skill_points <= 0:
        last_result = "Butuh level %d dan 1 skill point" % required_level
        return false
    skill_points -= 1
    unlocked_skills.append(skill_name)
    last_result = "Skill %s berhasil dipelajari" % skill_name
    return true

func use_skill(skill_name: String) -> bool:
    var mana_cost := 0
    if skill_name == "Power Strike":
        mana_cost = 10
    elif skill_name == "Guard Stance":
        mana_cost = 8
    elif skill_name == "Healing Light":
        mana_cost = 15
    else:
        last_result = "Skill tidak dikenal"
        return false
    if not unlocked_skills.has(skill_name):
        last_result = "Skill belum dipelajari"
        return false
    if mana < mana_cost:
        last_result = "MP tidak cukup"
        return false
    if not dungeon_active:
        last_result = "Skill hanya dapat digunakan di dungeon"
        return false
    mana -= mana_cost
    if skill_name == "Power Strike":
        var damage := maxi(1, attack * 2 - monster_defense)
        monster_health = maxi(0, monster_health - damage)
        last_result = "Power Strike memberikan %d damage" % damage
        if monster_health <= 0:
            _win_battle()
            return true
    elif skill_name == "Guard Stance":
        guard_stance = true
        last_result = "Guard Stance aktif"
    elif skill_name == "Healing Light":
        var restored := mini(45, max_health - health)
        health += restored
        last_result = "Healing Light memulihkan %d HP" % restored
    var incoming := maxi(1, monster_attack + randi_range(-2, 2) - defense)
    if guard_stance:
        incoming = maxi(1, int(ceil(incoming * 0.5)))
        guard_stance = false
    health = maxi(0, health - incoming)
    if health <= 0:
        dungeon_active = false
        health = maxi(1, int(max_health / 2))
        last_result += " | Mundur dari dungeon"
    else:
        last_result += " | Monster membalas %d" % incoming
    return true

func use_potion() -> bool:
    if health >= max_health:
        last_result = "HP masih penuh"
        return false
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


func _update_guild_rank() -> void:
    if guild_reputation >= 900:
        guild_rank = "Platinum"
    elif guild_reputation >= 500:
        guild_rank = "Emas"
    elif guild_reputation >= 250:
        guild_rank = "Perak"
    elif guild_reputation >= 100:
        guild_rank = "Perunggu"
    else:
        guild_rank = "Pemula"

func _generate_guild_board() -> void:
    guild_quests = [
        {"id": "hunt", "title": "Pembasmi Monster", "description": "Kalahkan 3 monster", "kind": "kill", "target": 3, "progress": 0, "reward_exp": 45, "reward_gold": 35, "reward_rep": 15, "accepted": false, "completed": false},
        {"id": "explore", "title": "Penjelajah Dungeon", "description": "Capai lantai 5 dungeon", "kind": "floor", "target": 5, "progress": 0, "reward_exp": 70, "reward_gold": 50, "reward_rep": 25, "accepted": false, "completed": false},
        {"id": "gather", "title": "Pengumpul Material", "description": "Temukan 3 material", "kind": "collect", "target": 3, "progress": 0, "reward_exp": 35, "reward_gold": 30, "reward_rep": 12, "accepted": false, "completed": false}
    ]

func accept_guild_quest(quest_id: String) -> bool:
    for quest in guild_quests:
        if str(quest.id) == quest_id:
            if bool(quest.accepted) or bool(quest.completed):
                last_result = "Quest sudah diambil atau selesai"
                return false
            for other in guild_quests:
                if bool(other.accepted) and not bool(other.completed):
                    last_result = "Selesaikan quest aktif terlebih dahulu"
                    return false
            quest.accepted = true
            last_result = "Quest diterima: " + str(quest.title)
            return true
    last_result = "Quest tidak ditemukan"
    return false

func _record_quest_progress(kind: String, amount: int) -> void:
    for quest in guild_quests:
        if bool(quest.get("accepted", false)) and not bool(quest.get("completed", false)) and str(quest.get("kind", "")) == kind:
            quest.progress = mini(int(quest.target), int(quest.progress) + amount)
            if int(quest.progress) >= int(quest.target):
                quest.completed = true
                last_result += " | Quest selesai: " + str(quest.title)

func claim_guild_quest(quest_id: String) -> bool:
    for quest in guild_quests:
        if str(quest.id) == quest_id and bool(quest.get("completed", false)):
            experience += int(quest.reward_exp)
            gold += int(quest.reward_gold)
            guild_reputation += int(quest.reward_rep)
            _update_guild_rank()
            last_result = "Hadiah quest diterima: +%d EXP, +%d emas, +%d reputasi" % [int(quest.reward_exp), int(quest.reward_gold), int(quest.reward_rep)]
            _check_level_up()
            _generate_guild_board()
            return true
    last_result = "Quest belum selesai"
    return false

func process_guild_day(day: int) -> void:
    if guild_quests.is_empty():
        _generate_guild_board()
    _guild_board_day = day

func get_guild_summary() -> String:
    return "Guild Petualang | Rank %s | Reputasi %d" % [guild_rank, guild_reputation]

func get_summary() -> String:
    return "Lv.%d | HP %d/%d | MP %d/%d | ATK %d | DEF %d | EXP %d/%d | Emas %d" % [
        level, health, max_health, mana, max_mana, attack, defense, experience, level * 50, gold
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
        "mana": mana, "max_mana": max_mana, "skill_points": skill_points,
        "unlocked_skills": unlocked_skills, "guard_stance": guard_stance,
        "attack": attack, "defense": defense, "base_attack": base_attack, "base_defense": base_defense,
        "weapon_bonus": weapon_bonus, "armor_bonus": armor_bonus,
        "gold": gold, "weapon_name": weapon_name, "armor_name": armor_name,
        "inventory": inventory.duplicate(true),
        "dungeon_floor": dungeon_floor, "monster_name": monster_name,
        "monster_health": monster_health, "monster_max_health": monster_max_health,
        "monster_attack": monster_attack, "monster_defense": monster_defense,
        "dungeon_active": dungeon_active, "last_result": last_result,
        "guild_reputation": guild_reputation, "guild_rank": guild_rank,
        "guild_quests": guild_quests.duplicate(true), "guild_board_day": _guild_board_day,
        "monster_is_boss": monster_is_boss
    }

func apply_state(state: Dictionary) -> void:
    level = maxi(1, int(state.get("level", 1)))
    experience = maxi(0, int(state.get("experience", 0)))
    max_health = maxi(1, int(state.get("max_health", 100)))
    health = clampi(int(state.get("health", max_health)), 1, max_health)
    max_mana = maxi(1, int(state.get("max_mana", 40)))
    mana = clampi(int(state.get("mana", max_mana)), 0, max_mana)
    skill_points = maxi(0, int(state.get("skill_points", 0)))
    unlocked_skills.clear()
    for skill in state.get("unlocked_skills", []):
        unlocked_skills.append(str(skill))
    guard_stance = bool(state.get("guard_stance", false))
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
    guild_reputation = maxi(0, int(state.get("guild_reputation", 0)))
    guild_rank = str(state.get("guild_rank", "Pemula"))
    guild_quests.clear()
    for quest in state.get("guild_quests", []):
        if quest is Dictionary:
            guild_quests.append(quest.duplicate(true))
    _guild_board_day = int(state.get("guild_board_day", -1))
    monster_is_boss = bool(state.get("monster_is_boss", false))
    _update_guild_rank()
    if guild_quests.is_empty():
        _generate_guild_board()
    _recalculate_equipment_stats()

func reset() -> void:
    level = 1
    experience = 0
    health = 100
    max_health = 100
    mana = 40
    max_mana = 40
    skill_points = 0
    unlocked_skills.clear()
    guard_stance = false
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
    guild_reputation = 0
    guild_rank = "Pemula"
    guild_quests.clear()
    _guild_board_day = -1
    monster_is_boss = false
