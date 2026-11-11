# Koi Kingdom

Native Android-oriented 2D life-simulation RPG built with Godot 4.

## Design
- 2D anime-inspired HD presentation (current prototype uses placeholder vector art)
- Isometric-style movement and diamond ground tiles
- Open-world foundation
- Autonomous NPC prototype

## Current stage
- Main menu
- Isometric-inspired test world
- Keyboard and on-screen touch movement
- Player character placeholder
- Autonomous wandering villagers
- Accelerated in-game clock
- Local JSON save/load for day, time, and player position

## Open the project
1. Install Godot 4.3 or newer.
2. Import this repository folder as a project.
3. Run `scenes/main/MainMenu.tscn`.

## Android
The project is structured for Android export using Godot's Android export templates and Android SDK/JDK configured in the Godot Editor. The current GitHub Actions workflow validates the project and uploads the source; it does **not** claim to produce an APK yet. Android export preset and signing configuration will be added after the project passes validation.

Suggested package ID: `com.koikingdom.game`.

## Notes
This is the first playable foundation, not the complete game. Character art, world tiles, buildings, NPC schedules, social systems, kingdom simulation, combat, and generational simulation are planned for later stages.
