# Koi Kingdom

Native Android-oriented 2D life-simulation RPG built with Godot 4.3.

## Current prototype
- Main menu and isometric-style test world
- Player movement with keyboard and on-screen touch controls
- Accelerated in-game clock
- Eight autonomous citizens with generated identity, race, gender, age, job, and personality
- Citizen routines: work, eat, socialize, relax, and sleep
- Basic needs: hunger, energy, and social
- Tap a citizen to inspect their profile
- Save/load for player position, world clock, citizen identity, needs, and positions
- Autonomous social meetings and persistent friendship bonds
- Adult male/female citizens can become partners and later marry
- Citizen profiles show relationship status and friend count
- Married adult citizens can have children after a waiting period
- Children age one year per 365 in-game days and progress from Child to Student to adult work
- Parent IDs, ages, child identities, and birth cooldowns persist in saves
- Population is capped at 32 citizens in the current prototype
- Basic kingdom government with an automatically selected King, Queen, Heir, and council
- Daily treasury, food production/consumption, tax income, happiness, and stability simulation
- Low, balanced, and high tax policies with corresponding citizen happiness and stability effects
- Kingdom status and citizen royal/council roles appear in the world HUD and citizen profiles
- Guard garrison, up to three Imperial Knights, defense rating, and military morale are simulated and saved
- Garrison upkeep is paid from the royal treasury; unpaid upkeep reduces morale and stability
- Three neighboring kingdoms have autonomous diplomatic relations and trade status
- Relations drift over time; trade agreements generate daily gold and food
- Diplomacy actions support improving relations, proposing trade, and ending trade
- In-game diplomacy panel exposes gift, trade, and tax-policy controls on touch devices
- Adventure progression with level, experience, health, attack, defense, and gold
- Dungeon floors with scaling fantasy monsters and turn-based player combat
- Dungeon victories award experience, gold, and random potion/material drops
- Inventory stacks consumables and crafting materials; potions restore health
- Dungeon monsters can drop usable weapons and armor
- Equipment can be equipped to increase attack or defense; replaced equipment returns to inventory
- Blacksmith crafting recipes convert iron ore and magic crystals into equipment
- Mana and skill points are earned through leveling
- Three learnable active combat skills: Power Strike, Guard Stance, and Healing Light
- Adventurer guild board with monster-hunt, dungeon-exploration, and material-gathering quests
- Quest acceptance, progress tracking, claimable EXP/gold/reputation rewards, and five guild ranks
- Dungeon bosses appear every five floors and award increased rewards and guild reputation
- Equipment and potion shop with gold prices, purchase validation, and inventory delivery
- Level-up stat increases persist independently from equipment bonuses
- Adventure stats, dungeon progress, equipment labels, and inventory persist in saves
- Touch-friendly adventure panel provides dungeon entry, attack, potion, and exit actions

## Run
1. Open this repository in Godot 4.3 or newer.
2. Import the project and run `scenes/main/MainMenu.tscn`.

## Android
Android export is not configured yet. The GitHub Actions workflow currently performs a project validation attempt and uploads source artifacts; it is not an APK build.

## Roadmap
1. Expand NPC identity and simulation
2. Relationships, friendship, dating, family, and generations
3. Expand kingdom roles, leadership, economy, and diplomacy
4. Expand adventure, equipment, crafting, and exploration
5. Multi-kingdom world simulation, trade routes, migration, and history
6. Android export and performance testing
