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

## Run
1. Open this repository in Godot 4.3 or newer.
2. Import the project and run `scenes/main/MainMenu.tscn`.

## Android
Android export is not configured yet. The GitHub Actions workflow currently performs a project validation attempt and uploads source artifacts; it is not an APK build.

## Roadmap
1. Expand NPC identity and simulation
2. Relationships, friendship, dating, family, and generations
3. Kingdom roles, leadership, economy, and diplomacy
4. Combat, dungeons, crafting, and exploration
5. Android export and performance testing
