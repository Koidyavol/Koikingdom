extends Node

var treasury: int = 250
var food: int = 180
var tax_rate: float = 0.10
var tax_policy := "Balanced"
var happiness: float = 72.0
var stability: float = 80.0
var king_id := ""
var queen_id := ""
var heir_id := ""
var council_ids: Array[String] = []
var imperial_knight_ids: Array[String] = []
var garrison_count := 0
var defense_rating := 0
var military_morale: float = 75.0
var foreign_kingdoms: Array[Dictionary] = []
var last_processed_day := 0
var world_history: Array[String] = []
var world_day := 1

func process_day(citizens: Array, current_day: int) -> void:
    _ensure_foreign_kingdoms()
    if current_day <= last_processed_day:
        assign_government(citizens)
        return
    var elapsed := mini(30, maxi(1, current_day - last_processed_day))
    assign_government(citizens)
    for _day in range(elapsed):
        var farmers := 0
        var merchants := 0
        var workers := 0
        for citizen in citizens:
            if not is_instance_valid(citizen) or citizen.age < 7:
                continue
            match citizen.job:
                "Farmer":
                    farmers += 1
                "Merchant":
                    merchants += 1
                _:
                    workers += 1
        var population := citizens.size()
        food += farmers * 4 - population * 2
        var taxable_workers := farmers + merchants + workers
        treasury += 3 + int(float(taxable_workers) * 2.0 * tax_rate * 10.0)
        var simulated_day := current_day - elapsed + _day + 1
        _process_diplomacy_day(simulated_day)
        _process_neighbor_kingdoms(simulated_day)
        var upkeep := garrison_count + imperial_knight_ids.size() * 2
        if treasury >= upkeep:
            treasury -= upkeep
            military_morale = minf(100.0, military_morale + 0.5)
        else:
            military_morale = maxf(0.0, military_morale - 2.0)
            stability = maxf(0.0, stability - 0.2)
        if tax_rate >= 0.20:
            happiness = maxf(0.0, happiness - 0.35)
            stability = maxf(0.0, stability - 0.1)
        elif tax_rate <= 0.05:
            happiness = minf(100.0, happiness + 0.2)
        if food < 0:
            happiness = maxf(0.0, happiness - 4.0)
            stability = maxf(0.0, stability - 2.0)
            food = 0
        elif food > population * 8:
            happiness = minf(100.0, happiness + 0.5)
        else:
            happiness = minf(100.0, happiness + 0.15)
        if treasury < 0:
            stability = maxf(0.0, stability - 1.0)
        else:
            stability = minf(100.0, stability + 0.1)
        treasury = maxi(0, treasury)
    last_processed_day = current_day
    assign_government(citizens)

func assign_government(citizens: Array) -> void:
    var adults: Array = []
    for citizen in citizens:
        if is_instance_valid(citizen):
            citizen.kingdom_role = "Citizen"
            if citizen.age >= 18:
                adults.append(citizen)
    if adults.is_empty():
        king_id = ""
        queen_id = ""
        heir_id = ""
        council_ids.clear()
        imperial_knight_ids.clear()
        garrison_count = 0
        defense_rating = 0
        return
    var king = _oldest_by_gender(adults, "Male")
    var queen = _oldest_by_gender(adults, "Female")
    king_id = king.npc_id if king != null else ""
    queen_id = queen.npc_id if queen != null else ""
    if king != null:
        king.kingdom_role = "King"
    if queen != null:
        queen.kingdom_role = "Queen"
    heir_id = ""
    for citizen in citizens:
        if not is_instance_valid(citizen) or citizen.age < 7:
            continue
        if citizen.parent_ids.has(king_id) or citizen.parent_ids.has(queen_id):
            heir_id = citizen.npc_id
            citizen.kingdom_role = "Heir" if citizen.age < 18 else "Royal Family"
            break
    council_ids.clear()
    var preferred_jobs := ["Guard", "Merchant", "Farmer", "Blacksmith", "Healer"]
    for wanted_job in preferred_jobs:
        for citizen in adults:
            if citizen.job == wanted_job and citizen.npc_id != king_id and citizen.npc_id != queen_id and not council_ids.has(citizen.npc_id):
                council_ids.append(citizen.npc_id)
                citizen.kingdom_role = "Council"
                break
        if council_ids.size() >= 5:
            break
    imperial_knight_ids.clear()
    garrison_count = 0
    for citizen in adults:
        if citizen.job == "Guard":
            garrison_count += 1
            if citizen.npc_id != king_id and citizen.npc_id != queen_id and not council_ids.has(citizen.npc_id) and imperial_knight_ids.size() < 3:
                imperial_knight_ids.append(citizen.npc_id)
                citizen.kingdom_role = "Imperial Knight"
    defense_rating = garrison_count * 10 + imperial_knight_ids.size() * 15

func _oldest_by_gender(citizens: Array, wanted_gender: String):
    var selected = null
    for citizen in citizens:
        if citizen.gender != wanted_gender:
            continue
        if selected == null or citizen.age > selected.age:
            selected = citizen
    return selected

func set_tax_rate(new_rate: float) -> void:
    tax_rate = clampf(new_rate, 0.0, 0.30)
    if tax_rate <= 0.05:
        tax_policy = "Low Tax"
    elif tax_rate >= 0.20:
        tax_policy = "High Tax"
    else:
        tax_policy = "Balanced"

func _ensure_foreign_kingdoms() -> void:
    if not foreign_kingdoms.is_empty():
        return
    foreign_kingdoms = [
        {"id": "sakura", "name": "Sakura", "relation": 20, "trade_active": false, "trade_days": 0, "status": "Neutral", "treasury": 180, "food": 150, "population": 120, "prosperity": 62, "war_active": false, "war_days": 0, "migration_total": 0},
        {"id": "tsukiyo", "name": "Tsukiyo", "relation": 5, "trade_active": false, "trade_days": 0, "status": "Neutral", "treasury": 220, "food": 130, "population": 105, "prosperity": 58, "war_active": false, "war_days": 0, "migration_total": 0},
        {"id": "akatsuki", "name": "Akatsuki", "relation": -10, "trade_active": false, "trade_days": 0, "status": "Neutral", "treasury": 160, "food": 190, "population": 135, "prosperity": 54, "war_active": false, "war_days": 0, "migration_total": 0}
    ]

func _process_diplomacy_day(day_number: int) -> void:
    if day_number <= 0:
        return
    for kingdom in foreign_kingdoms:
        if day_number % 15 == 0:
            kingdom["relation"] = clampi(int(kingdom.get("relation", 0)) + randi_range(-2, 2), -100, 100)
        var relation := int(kingdom.get("relation", 0))
        var trade_active := bool(kingdom.get("trade_active", false))
        if trade_active:
            kingdom["trade_days"] = int(kingdom.get("trade_days", 0)) + 1
            treasury += 2
            food += 1
            if relation < -35:
                kingdom["trade_active"] = false
                kingdom["trade_days"] = 0
        kingdom["status"] = "Friendly" if relation >= 60 else ("Tense" if relation <= -40 else "Neutral")
        var at_war := bool(kingdom.get("war_active", false))
        if at_war:
            kingdom["war_days"] = int(kingdom.get("war_days", 0)) + 1
            if int(kingdom["war_days"]) >= 30 or relation >= -20:
                kingdom["war_active"] = false
                kingdom["war_days"] = 0
                kingdom["relation"] = maxi(-100, relation - 10)
                _record_world_event("Gencatan senjata dengan %s setelah konflik perbatasan" % str(kingdom.get("name", "kerajaan")))
        elif day_number % 30 == 0 and relation <= -65 and not trade_active and randf() < 0.20:
            kingdom["war_active"] = true
            kingdom["war_days"] = 0
            kingdom["trade_active"] = false
            _record_world_event("Konflik perbatasan pecah dengan %s" % str(kingdom.get("name", "kerajaan")))

func _process_neighbor_kingdoms(day_number: int) -> void:
    world_day = day_number
    for index in range(foreign_kingdoms.size()):
        var kingdom: Dictionary = foreign_kingdoms[index]
        var population := maxi(1, int(kingdom.get("population", 100)))
        var food_reserve := maxi(0, int(kingdom.get("food", 100)))
        var farmers := maxi(2, int(population * 0.12))
        food_reserve = mini(population * 8, maxi(0, food_reserve + farmers * 3 - int(population * 2 / 10)))
        var local_treasury := maxi(0, int(kingdom.get("treasury", 100)))
        local_treasury = mini(100000, local_treasury + maxi(1, int(population * 0.025)))
        var prosperity := clampf(float(kingdom.get("prosperity", 50.0)), 0.0, 100.0)
        if food_reserve <= 0:
            population = maxi(40, population - maxi(1, int(population * 0.01)))
            prosperity = maxf(0.0, prosperity - 1.5)
        elif food_reserve > int(population * 1.5):
            if day_number % 30 == 0:
                population = mini(600, population + 1)
            prosperity = minf(100.0, prosperity + 0.25)
        else:
            prosperity = minf(100.0, prosperity + 0.05)
        if bool(kingdom.get("trade_active", false)) and int(kingdom.get("relation", 0)) >= 30 and food_reserve > 0:
            food_reserve = maxi(0, food_reserve - 1)
            local_treasury += 2
            prosperity = minf(100.0, prosperity + 0.1)
        if day_number % 30 == 0:
            if bool(kingdom.get("war_active", false)):
                population = maxi(40, population - maxi(1, int(population * 0.005)))
                local_treasury = maxi(0, local_treasury - 8)
                prosperity = maxf(0.0, prosperity - 2.0)
            elif prosperity >= 65.0 and food_reserve > int(population * 2):
                population = mini(600, population + 2)
                kingdom["migration_total"] = int(kingdom.get("migration_total", 0)) + 2
                _record_world_event("Migrasi masuk ke %s: +2 penduduk" % str(kingdom.get("name", "kerajaan")))
            elif prosperity < 35.0 or food_reserve < int(population * 0.3):
                var migration_out := mini(3, maxi(1, int(population * 0.01)))
                population = maxi(40, population - migration_out)
                kingdom["migration_total"] = int(kingdom.get("migration_total", 0)) - migration_out
                _record_world_event("Migrasi keluar dari %s: -%d penduduk" % [str(kingdom.get("name", "kerajaan")), migration_out])
        kingdom["population"] = population
        kingdom["food"] = food_reserve
        kingdom["treasury"] = local_treasury
        kingdom["prosperity"] = prosperity
        foreign_kingdoms[index] = kingdom
        if day_number % 30 == 0:
            _record_world_event("%s: populasi %d, kemakmuran %d%%" % [str(kingdom.get("name", "Kerajaan")), population, roundi(prosperity)])

func _record_world_event(event_text: String) -> void:
    world_history.append("Hari %d: %s" % [world_day, event_text])
    while world_history.size() > 12:
        world_history.pop_front()

func get_world_history_summary() -> String:
    if world_history.is_empty():
        return "Belum ada catatan sejarah dunia."
    return "SEJARAH DUNIA\n" + "\n".join(world_history)

func propose_trade(kingdom_id: String) -> bool:
    for index in range(foreign_kingdoms.size()):
        var kingdom: Dictionary = foreign_kingdoms[index]
        if str(kingdom.get("id", "")) != kingdom_id:
            continue
        if int(kingdom.get("relation", 0)) < 30 or bool(kingdom.get("trade_active", false)):
            return false
        kingdom["trade_active"] = true
        kingdom["trade_days"] = 0
        foreign_kingdoms[index] = kingdom
        return true
    return false

func improve_relations(kingdom_id: String) -> bool:
    if treasury < 25:
        return false
    for index in range(foreign_kingdoms.size()):
        var kingdom: Dictionary = foreign_kingdoms[index]
        if str(kingdom.get("id", "")) != kingdom_id:
            continue
        treasury -= 25
        kingdom["relation"] = clampi(int(kingdom.get("relation", 0)) + 10, -100, 100)
        foreign_kingdoms[index] = kingdom
        return true
    return false

func end_trade(kingdom_id: String) -> bool:
    for index in range(foreign_kingdoms.size()):
        var kingdom: Dictionary = foreign_kingdoms[index]
        if str(kingdom.get("id", "")) != kingdom_id:
            continue
        kingdom["trade_active"] = false
        kingdom["trade_days"] = 0
        foreign_kingdoms[index] = kingdom
        return true
    return false

func get_diplomacy_summary() -> String:
    _ensure_foreign_kingdoms()
    var parts: PackedStringArray = []
    for kingdom in foreign_kingdoms:
        var trade_text := " | Dagang" if bool(kingdom.get("trade_active", false)) else ""
        var war_text := " | KONFLIK" if bool(kingdom.get("war_active", false)) else ""
        parts.append("%s: %d (%s)%s%s" % [
            str(kingdom.get("name", "Unknown")),
            int(kingdom.get("relation", 0)),
            str(kingdom.get("status", "Neutral")) + " | Pop " + str(kingdom.get("population", 100)) + " | Makmur " + str(roundi(float(kingdom.get("prosperity", 50.0)))) + "%",
            trade_text, war_text
        ])
    return "Diplomasi: " + "  •  ".join(parts)

func get_role(citizen_id: String) -> String:
    if citizen_id == king_id and not king_id.is_empty():
        return "King"
    if citizen_id == queen_id and not queen_id.is_empty():
        return "Queen"
    if citizen_id == heir_id and not heir_id.is_empty():
        return "Heir"
    if council_ids.has(citizen_id):
        return "Council"
    if imperial_knight_ids.has(citizen_id):
        return "Imperial Knight"
    return "Citizen"

func get_summary() -> String:
    return "Kerajaan | Emas %d | Pangan %d | Pajak %d%% | Bahagia %d%% | Stabil %d%%\nGarnisun %d | Ksatria %d | Pertahanan %d | Moral %d%%" % [
        treasury, food, roundi(tax_rate * 100.0), roundi(happiness), roundi(stability),
        garrison_count, imperial_knight_ids.size(), defense_rating, roundi(military_morale)
    ]

func get_save_data() -> Dictionary:
    return {
        "treasury": treasury, "food": food, "tax_rate": tax_rate, "tax_policy": tax_policy,
        "happiness": happiness, "stability": stability,
        "king_id": king_id, "queen_id": queen_id, "heir_id": heir_id,
        "council_ids": council_ids, "imperial_knight_ids": imperial_knight_ids,
        "garrison_count": garrison_count, "defense_rating": defense_rating,
        "military_morale": military_morale, "foreign_kingdoms": foreign_kingdoms.duplicate(true),
        "last_processed_day": last_processed_day, "world_history": world_history,
        "world_day": world_day
    }

func apply_state(state: Dictionary) -> void:
    treasury = maxi(0, int(state.get("treasury", 250)))
    food = maxi(0, int(state.get("food", 180)))
    set_tax_rate(float(state.get("tax_rate", 0.10)))
    tax_policy = str(state.get("tax_policy", tax_policy))
    happiness = clampf(float(state.get("happiness", 72.0)), 0.0, 100.0)
    stability = clampf(float(state.get("stability", 80.0)), 0.0, 100.0)
    king_id = str(state.get("king_id", ""))
    queen_id = str(state.get("queen_id", ""))
    heir_id = str(state.get("heir_id", ""))
    council_ids.clear()
    for citizen_id in state.get("council_ids", []):
        council_ids.append(str(citizen_id))
    imperial_knight_ids.clear()
    for knight_id in state.get("imperial_knight_ids", []):
        imperial_knight_ids.append(str(knight_id))
    garrison_count = maxi(0, int(state.get("garrison_count", 0)))
    defense_rating = maxi(0, int(state.get("defense_rating", 0)))
    military_morale = clampf(float(state.get("military_morale", 75.0)), 0.0, 100.0)
    foreign_kingdoms.clear()
    for kingdom in state.get("foreign_kingdoms", []):
        if kingdom is Dictionary:
            foreign_kingdoms.append(kingdom.duplicate(true))
    _ensure_foreign_kingdoms()
    last_processed_day = int(state.get("last_processed_day", 0))
    world_history.clear()
    for event_text in state.get("world_history", []):
        world_history.append(str(event_text))
    world_day = maxi(1, int(state.get("world_day", 1)))

func reset() -> void:
    treasury = 250
    food = 180
    tax_rate = 0.10
    tax_policy = "Balanced"
    happiness = 72.0
    stability = 80.0
    king_id = ""
    queen_id = ""
    heir_id = ""
    council_ids.clear()
    imperial_knight_ids.clear()
    garrison_count = 0
    defense_rating = 0
    military_morale = 75.0
    foreign_kingdoms.clear()
    _ensure_foreign_kingdoms()
    last_processed_day = 0
    world_history.clear()
    world_day = 1
