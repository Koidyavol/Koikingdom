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

## Run
1. Open this repository in Godot 4.3 or newer.
2. Import the project and run `scenes/main/MainMenu.tscn`.

## Android
Android export is not configured yet. The GitHub Actions workflow currently performs a project validation attempt and uploads source artifacts; it is not an APK build.

## Roadmap
1. Expand NPC identity and simulation
2. Relationships, friendship, dating, family, and generations
3. Expand kingdom roles, leadership, economy, and diplomacy
4. Combat, dungeons, crafting, and exploration
5. Android export and performance testing
