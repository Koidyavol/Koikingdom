extends Node2D

const NPC_SCRIPT := preload("res://scripts/characters/npc.gd")
const STARTING_NPC_COUNT := 8
const FIRST_NAMES := ["Aoi", "Ren", "Hana", "Yuki", "Akira", "Mei", "Haruto", "Sora", "Rin", "Kaito", "Emi", "Daichi"]
const RACES := ["Human", "Elf", "Beastkin", "Dwarf"]
const JOBS := ["Farmer", "Merchant", "Guard", "Student", "Blacksmith", "Healer", "Fisher"]
const PERSONALITIES := ["Kind", "Cheerful", "Shy", "Hardworking", "Curious", "Calm"]

var camera: Camera2D
var hud: CanvasLayer
var clock_label: Label
var profile_label: Label
var kingdom_label: Label
var diplomacy_panel: PanelContainer
var diplomacy_content: VBoxContainer
var diplomacy_button: Button
var adventure_panel: PanelContainer
var adventure_content: VBoxContainer
var adventure_button: Button
var player: CharacterBody2D
var citizens: Array[Node] = []
var social_simulation_timer := 0.0
var _last_family_day := 0

func _ready() -> void:
    randomize()
    player = get_node("Player")
    var saved := SaveManager.load_game()
    if not saved.is_empty():
        var pos: Array = saved.get("player_position", [640.0, 360.0])
        if pos.size() >= 2:
            player.position = Vector2(float(pos[0]), float(pos[1]))
        var time_state: Dictionary = saved.get("time", {})
        if not time_state.is_empty():
            TimeManager.apply_state(time_state)

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    player.add_child(camera)
    camera.make_current()

    RelationshipManager.apply_state(saved.get("relationships", {}))
    KingdomManager.apply_state(saved.get("kingdom", {}))
    AdventureManager.apply_state(saved.get("adventure", {}))
    _spawn_npcs(saved.get("citizens", []))
    KingdomManager.process_day(citizens, TimeManager.day)
    _last_family_day = TimeManager.day
    _build_hud()
    queue_redraw()

func _process(delta: float) -> void:
    RelationshipManager.simulate(citizens, delta)
    if TimeManager.day != _last_family_day:
        _simulate_family_day()
    if is_instance_valid(clock_label):
        clock_label.text = TimeManager.formatted_time()

func _draw() -> void:
    var tile_w := 96.0
    var tile_h := 48.0
    for y in range(-35, 36):
        for x in range(-45, 46):
            var p := Vector2(640 + (x - y) * tile_w * 0.5, 360 + (x + y) * tile_h * 0.5)
            var points := PackedVector2Array([
                p + Vector2(0, -tile_h * 0.5), p + Vector2(tile_w * 0.5, 0),
                p + Vector2(0, tile_h * 0.5), p + Vector2(-tile_w * 0.5, 0)
            ])
            var tile_color := Color("#73966a") if (x + y) % 2 == 0 else Color("#7da272")
            draw_colored_polygon(points, tile_color)
            draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color("#66865e"), 1.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(510, 300), Vector2(770, 300), Vector2(840, 370), Vector2(580, 370)
    ]), Color("#b9aa8b"))
    draw_rect(Rect2(680, 190, 110, 95), Color("#8b5e4a"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(665, 195), Vector2(735, 135), Vector2(805, 195)
    ]), Color("#593f45"))

func _spawn_npcs(saved_citizens: Array) -> void:
    var spawn_count := mini(32, maxi(STARTING_NPC_COUNT, saved_citizens.size()))
    for i in range(spawn_count):
        var npc = NPC_SCRIPT.new()
        add_child(npc)
        var data: Dictionary
        if i < saved_citizens.size() and saved_citizens[i] is Dictionary:
            data = saved_citizens[i]
        else:
            data = _make_citizen(i)
        npc.setup(data)
        npc.selected.connect(_show_citizen_profile)
        citizens.append(npc)


func _simulate_family_day() -> void:
    _last_family_day = TimeManager.day
    var births := RelationshipManager.process_family_day(citizens, TimeManager.day)
    KingdomManager.process_day(citizens, TimeManager.day)
    _refresh_kingdom_hud()
    _refresh_diplomacy_panel()
    for child_data in births:
        if citizens.size() >= 32:
            break
        var child = NPC_SCRIPT.new()
        add_child(child)
        child.setup(child_data)
        child.selected.connect(_show_citizen_profile)
        citizens.append(child)
    KingdomManager.assign_government(citizens)

func _make_citizen(index: int) -> Dictionary:
    var gender := "Female" if randi() % 2 == 0 else "Male"
    return {
        "id": "citizen_%03d" % (index + 1),
        "name": FIRST_NAMES[randi_range(0, FIRST_NAMES.size() - 1)],
        "race": RACES[randi_range(0, RACES.size() - 1)],
        "gender": gender,
        "age": randi_range(18, 60),
        "job": JOBS[randi_range(0, JOBS.size() - 1)],
        "personality": PERSONALITIES[randi_range(0, PERSONALITIES.size() - 1)],
        "hunger": randf_range(65.0, 100.0),
        "energy": randf_range(65.0, 100.0),
        "social": randf_range(55.0, 100.0),
        "position": [randf_range(420, 900), randf_range(250, 500)]
    }

func _show_citizen_profile(profile: Dictionary) -> void:
    if not is_instance_valid(profile_label):
        return
    profile_label.text = "%s  |  %s %s, %d\\nPeran: %s  |  Pekerjaan: %s\\nSifat: %s  |  Aktivitas: %s\\nRelasi: %s  |  Teman: %d\\nLapar %d%%  Energi %d%%  Sosial %d%%" % [
        profile.name, profile.gender, profile.race, profile.age, profile.kingdom_role, profile.job,
        profile.personality, profile.activity, profile.relationship_status,
        profile.friends.size(), profile.hunger, profile.energy, profile.social
    ]

func _build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 14)
    hud.add_child(panel)
    clock_label = Label.new()
    clock_label.text = TimeManager.formatted_time()
    clock_label.add_theme_font_size_override("font_size", 20)
    panel.add_child(clock_label)

    profile_label = Label.new()
    profile_label.text = "Ketuk warga untuk melihat identitas dan kebutuhannya."
    profile_label.position = Vector2(16, 82)
    profile_label.add_theme_color_override("font_color", Color.WHITE)
    profile_label.add_theme_font_size_override("font_size", 14)
    hud.add_child(profile_label)

    kingdom_label = Label.new()
    kingdom_label.text = KingdomManager.get_summary() + "\n" + KingdomManager.get_diplomacy_summary()
    kingdom_label.position = Vector2(16, 190)
    kingdom_label.add_theme_color_override("font_color", Color("#f2d9a6"))
    kingdom_label.add_theme_font_size_override("font_size", 13)
    hud.add_child(kingdom_label)

    var hint := Label.new()
    hint.text = "WASD / tombol arah untuk bergerak"
    hint.position = Vector2(16, 250)
    hint.add_theme_color_override("font_color", Color.WHITE)
    hud.add_child(hint)
    _add_diplomacy_controls()
    _add_adventure_controls()
    _add_touch_controls()

func _add_diplomacy_controls() -> void:
    diplomacy_button = Button.new()
    diplomacy_button.text = "Diplomasi"
    diplomacy_button.position = Vector2(1080, 18)
    diplomacy_button.size = Vector2(170, 48)
    hud.add_child(diplomacy_button)
    diplomacy_button.pressed.connect(_toggle_diplomacy_panel)

    diplomacy_panel = PanelContainer.new()
    diplomacy_panel.position = Vector2(820, 76)
    diplomacy_panel.custom_minimum_size = Vector2(420, 0)
    diplomacy_panel.visible = false
    hud.add_child(diplomacy_panel)

    diplomacy_content = VBoxContainer.new()
    diplomacy_content.add_theme_constant_override("separation", 8)
    diplomacy_panel.add_child(diplomacy_content)
    _refresh_diplomacy_panel()

func _toggle_diplomacy_panel() -> void:
    diplomacy_panel.visible = not diplomacy_panel.visible
    if diplomacy_panel.visible:
        _refresh_diplomacy_panel()

func _refresh_diplomacy_panel() -> void:
    if not is_instance_valid(diplomacy_content):
        return
    for child in diplomacy_content.get_children():
        child.queue_free()
    var heading := Label.new()
    heading.text = "DIPLOMASI KERAJAAN"
    heading.add_theme_font_size_override("font_size", 18)
    diplomacy_content.add_child(heading)

    var tax_heading := Label.new()
    tax_heading.text = "Kebijakan pajak: %s (%d%%)" % [KingdomManager.tax_policy, roundi(KingdomManager.tax_rate * 100.0)]
    diplomacy_content.add_child(tax_heading)
    var tax_row := HBoxContainer.new()
    diplomacy_content.add_child(tax_row)
    _add_tax_button(tax_row, "Rendah 5%", 0.05)
    _add_tax_button(tax_row, "Normal 10%", 0.10)
    _add_tax_button(tax_row, "Tinggi 20%", 0.20)

    var treasury_label := Label.new()
    treasury_label.text = "Emas kerajaan: %d (hadiah diplomasi 25 emas)" % KingdomManager.treasury
    diplomacy_content.add_child(treasury_label)

    for kingdom in KingdomManager.foreign_kingdoms:
        var kingdom_id := str(kingdom.get("id", ""))
        var kingdom_name := str(kingdom.get("name", "Kerajaan"))
        var relation := int(kingdom.get("relation", 0))
        var is_trading := bool(kingdom.get("trade_active", false))
        var info := Label.new()
        info.text = "%s | Hubungan: %d | %s%s" % [
            kingdom_name, relation, str(kingdom.get("status", "Neutral")),
            " | Dagang aktif" if is_trading else ""
        ]
        info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        diplomacy_content.add_child(info)

        var actions := HBoxContainer.new()
        diplomacy_content.add_child(actions)
        var improve := Button.new()
        improve.text = "Kirim hadiah (25)"
        improve.disabled = KingdomManager.treasury < 25 or relation >= 100
        actions.add_child(improve)
        improve.pressed.connect(func():
            KingdomManager.improve_relations(kingdom_id)
            _refresh_diplomacy_panel()
            _refresh_kingdom_hud()
        )

        var trade := Button.new()
        trade.text = "Akhiri dagang" if is_trading else "Ajukan dagang"
        trade.disabled = (not is_trading and relation < 30)
        actions.add_child(trade)
        trade.pressed.connect(func():
            if is_trading:
                KingdomManager.end_trade(kingdom_id)
            else:
                KingdomManager.propose_trade(kingdom_id)
            _refresh_diplomacy_panel()
            _refresh_kingdom_hud()
        )

    var close_button := Button.new()
    close_button.text = "Tutup"
    diplomacy_content.add_child(close_button)
    close_button.pressed.connect(func(): diplomacy_panel.visible = false)

func _add_tax_button(parent: HBoxContainer, caption: String, rate: float) -> void:
    var button := Button.new()
    button.text = caption
    parent.add_child(button)
    button.pressed.connect(func():
        KingdomManager.set_tax_rate(rate)
        _refresh_diplomacy_panel()
        _refresh_kingdom_hud()
    )

func _refresh_kingdom_hud() -> void:
    if is_instance_valid(kingdom_label):
        kingdom_label.text = KingdomManager.get_summary() + "\n" + KingdomManager.get_diplomacy_summary()

func _add_adventure_controls() -> void:
    adventure_button = Button.new()
    adventure_button.text = "Petualangan"
    adventure_button.position = Vector2(1080, 76)
    adventure_button.size = Vector2(170, 48)
    hud.add_child(adventure_button)
    adventure_button.pressed.connect(_toggle_adventure_panel)

    adventure_panel = PanelContainer.new()
    adventure_panel.position = Vector2(820, 134)
    adventure_panel.custom_minimum_size = Vector2(420, 0)
    adventure_panel.visible = false
    hud.add_child(adventure_panel)

    adventure_content = VBoxContainer.new()
    adventure_content.add_theme_constant_override("separation", 8)
    adventure_panel.add_child(adventure_content)
    _refresh_adventure_panel()

func _toggle_adventure_panel() -> void:
    adventure_panel.visible = not adventure_panel.visible
    if adventure_panel.visible:
        _refresh_adventure_panel()

func _refresh_adventure_panel() -> void:
    if not is_instance_valid(adventure_content):
        return
    for child in adventure_content.get_children():
        child.queue_free()
    var title := Label.new()
    title.text = "PETUALANGAN & DUNGEON"
    title.add_theme_font_size_override("font_size", 18)
    adventure_content.add_child(title)

    var stats := Label.new()
    stats.text = AdventureManager.get_summary()
    stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    adventure_content.add_child(stats)

    var equipment := Label.new()
    equipment.text = "Senjata: %s | Armor: %s" % [AdventureManager.weapon_name, AdventureManager.armor_name]
    equipment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    adventure_content.add_child(equipment)

    var inventory_label := Label.new()
    inventory_label.text = AdventureManager.get_inventory_summary()
    inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    adventure_content.add_child(inventory_label)

    for item in AdventureManager.inventory:
        var item_name := str(item.get("name", ""))
        if str(item.get("type", "")) == "equipment":
            _add_adventure_action(adventure_content, "Pakai: " + item_name, func(): _adventure_equip(item_name))

    var crafting_title := Label.new()
    crafting_title.text = "CRAFTING BLACKSMITH"
    adventure_content.add_child(crafting_title)
    _add_adventure_action(adventure_content, "Buat Pedang Besi (3 Bijih + 1 Kristal)", func(): _adventure_craft("Pedang Besi"))
    _add_adventure_action(adventure_content, "Buat Jubah Kulit (2 Bijih)", func(): _adventure_craft("Jubah Kulit"))

    var guild_heading := Label.new()
    guild_heading.text = AdventureManager.get_guild_summary()
    adventure_content.add_child(guild_heading)
    for quest in AdventureManager.guild_quests:
        var quest_label := Label.new()
        quest_label.text = "%s: %d/%d%s" % [str(quest.title), int(quest.progress), int(quest.target), " (selesai)" if bool(quest.completed) else (" (aktif)" if bool(quest.accepted) else "")]
        quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        adventure_content.add_child(quest_label)
        var quest_id := str(quest.id)
        if bool(quest.completed):
            _add_adventure_action(adventure_content, "Ambil hadiah: " + str(quest.title), func(): _adventure_claim_quest(quest_id))
        elif not bool(quest.accepted):
            _add_adventure_action(adventure_content, "Ambil quest: " + str(quest.title), func(): _adventure_accept_quest(quest_id))

    var skill_heading := Label.new()
    skill_heading.text = "SKILL (Poin: %d)" % AdventureManager.skill_points
    adventure_content.add_child(skill_heading)
    _add_adventure_action(adventure_content, "Pelajari Power Strike (Lv.2)", func(): _adventure_unlock_skill("Power Strike"))
    _add_adventure_action(adventure_content, "Pelajari Guard Stance (Lv.3)", func(): _adventure_unlock_skill("Guard Stance"))
    _add_adventure_action(adventure_content, "Pelajari Healing Light (Lv.4)", func(): _adventure_unlock_skill("Healing Light"))

    var result := Label.new()
    result.text = AdventureManager.last_result
    result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    adventure_content.add_child(result)

    if AdventureManager.dungeon_active:
        var monster := Label.new()
        monster.text = "Lantai %d | %s HP %d/%d" % [
            AdventureManager.dungeon_floor, AdventureManager.monster_name,
            AdventureManager.monster_health, AdventureManager.monster_max_health
        ]
        adventure_content.add_child(monster)
        _add_adventure_action(adventure_content, "Serang", _adventure_attack)
        for skill_name in ["Power Strike", "Guard Stance", "Healing Light"]:
            if AdventureManager.unlocked_skills.has(skill_name):
                _add_adventure_action(adventure_content, "Gunakan " + skill_name, func(): _adventure_use_skill(skill_name))
        _add_adventure_action(adventure_content, "Gunakan ramuan", _adventure_potion)
        _add_adventure_action(adventure_content, "Keluar dungeon", _adventure_leave)
    else:
        _add_adventure_action(adventure_content, "Masuk dungeon", _adventure_enter)
        _add_adventure_action(adventure_content, "Gunakan ramuan", _adventure_potion)
    _add_adventure_action(adventure_content, "Tutup", func(): adventure_panel.visible = false)

func _add_adventure_action(parent: VBoxContainer, caption: String, action: Callable) -> void:
    var button := Button.new()
    button.text = caption
    parent.add_child(button)
    button.pressed.connect(action)

func _adventure_accept_quest(quest_id: String) -> void:
    AdventureManager.accept_guild_quest(quest_id)
    _refresh_adventure_panel()

func _adventure_claim_quest(quest_id: String) -> void:
    AdventureManager.claim_guild_quest(quest_id)
    _refresh_adventure_panel()

func _adventure_enter() -> void:
    AdventureManager.enter_dungeon()
    _refresh_adventure_panel()

func _adventure_attack() -> void:
    AdventureManager.attack_monster()
    _refresh_adventure_panel()

func _adventure_potion() -> void:
    AdventureManager.use_potion()
    _refresh_adventure_panel()

func _adventure_unlock_skill(skill_name: String) -> void:
    AdventureManager.unlock_skill(skill_name)
    _refresh_adventure_panel()

func _adventure_use_skill(skill_name: String) -> void:
    AdventureManager.use_skill(skill_name)
    _refresh_adventure_panel()

func _adventure_equip(item_name: String) -> void:
    AdventureManager.equip_item(item_name)
    _refresh_adventure_panel()

func _adventure_craft(item_name: String) -> void:
    AdventureManager.craft_item(item_name)
    _refresh_adventure_panel()

func _adventure_leave() -> void:
    AdventureManager.leave_dungeon()
    _refresh_adventure_panel()

func _add_touch_controls() -> void:
    var base := Control.new()
    base.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    base.position = Vector2(24, -190)
    base.custom_minimum_size = Vector2(180, 170)
    hud.add_child(base)
    _make_direction_button(base, "↑", Vector2(60, 0), Vector2.UP)
    _make_direction_button(base, "↓", Vector2(60, 110), Vector2.DOWN)
    _make_direction_button(base, "←", Vector2(0, 55), Vector2.LEFT)
    _make_direction_button(base, "→", Vector2(120, 55), Vector2.RIGHT)

func _make_direction_button(parent: Control, caption: String, pos: Vector2, dir: Vector2) -> void:
    var button := Button.new()
    button.text = caption
    button.position = pos
    button.size = Vector2(56, 56)
    button.add_theme_font_size_override("font_size", 24)
    parent.add_child(button)
    button.button_down.connect(func(): player.set_touch_direction(dir))
    button.button_up.connect(func(): player.set_touch_direction(Vector2.ZERO))

func _save_world() -> void:
    if not is_instance_valid(player):
        return
    var citizen_data: Array = []
    for citizen in citizens:
        if is_instance_valid(citizen):
            citizen_data.append(citizen.get_save_data())
    SaveManager.save_game({
        "player_position": [player.position.x, player.position.y],
        "time": TimeManager.get_state(),
        "citizens": citizen_data,
        "relationships": RelationshipManager.get_save_data(),
        "kingdom": KingdomManager.get_save_data(),
        "adventure": AdventureManager.get_save_data()
    })

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
        _save_world()
