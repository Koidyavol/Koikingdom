extends Node

var treasury: int = 250
var food: int = 180
var tax_rate: float = 0.10
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
var last_processed_day := 0

func process_day(citizens: Array, current_day: int) -> void:
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
        var upkeep := garrison_count + imperial_knight_ids.size() * 2
        if treasury >= upkeep:
            treasury -= upkeep
            military_morale = minf(100.0, military_morale + 0.5)
        else:
            military_morale = maxf(0.0, military_morale - 2.0)
            stability = maxf(0.0, stability - 0.2)
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
        "treasury": treasury, "food": food, "tax_rate": tax_rate,
        "happiness": happiness, "stability": stability,
        "king_id": king_id, "queen_id": queen_id, "heir_id": heir_id,
        "council_ids": council_ids, "imperial_knight_ids": imperial_knight_ids,
        "garrison_count": garrison_count, "defense_rating": defense_rating,
        "military_morale": military_morale, "last_processed_day": last_processed_day
    }

func apply_state(state: Dictionary) -> void:
    treasury = maxi(0, int(state.get("treasury", 250)))
    food = maxi(0, int(state.get("food", 180)))
    tax_rate = clampf(float(state.get("tax_rate", 0.10)), 0.0, 0.30)
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
    last_processed_day = int(state.get("last_processed_day", 0))

func reset() -> void:
    treasury = 250
    food = 180
    tax_rate = 0.10
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
    last_processed_day = 0
