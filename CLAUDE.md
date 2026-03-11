# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**99 Jahre im Wald** is a 3D survival horror game built with **Godot 4.6** (GDScript), inspired by "99 Nights in the Forest" on Roblox. Target platform is iPad (iOS), with PC keyboard/mouse support for development.

## Running the Game

- Open Godot: `godot --path game/` or open `/Applications/Godot.app` and import the `game/` folder
- Run: Press **F5** in the Godot editor
- The Godot project root is `game/`, not the repository root

## Architecture

Single scene architecture with one main scene (`scenes/main.tscn`) and GDScript files in `scripts/`.

**Core orchestration:**
- `game_manager.gd` — Central controller. Wires up all signals between player, day/night cycle, deer monster, camera, and HUD. Manages game state and UI updates.

**Player & Camera:**
- `player.gd` — CharacterBody3D with WASD movement relative to camera yaw, HP system, wood inventory, torch crafting. Movement direction computed from `camera_yaw` angle passed by game_manager.
- `camera_controller.gd` — Separate Node3D that follows the player. Handles orbit rotation (arrow keys, touch drag, right-click), zoom via pinch/scroll/Shift+arrows. Zooming past threshold switches to first-person view.

**World:**
- `day_night_cycle.gd` — Controls sun rotation, light color/intensity, and sky color across day phases. Emits `night_started`/`day_started` signals.
- `forest_generator.gd` — Procedurally generates 300 trees at startup using a fixed seed. Creates StaticBody3D nodes with tree_resource.gd script attached.
- `tree_resource.gd` — Harvestable tree. Finds child nodes dynamically (not @onready) since trees are created procedurally. Respawns after 30s.
- `campfire.gd` — Safe zone with flickering OmniLight3D. Area3D triggers safe zone enter/exit on player.

**Enemies:**
- `deer_monster.gd` — State machine (INACTIVE/ROAMING/CHASING/ATTACKING/FLEEING). Activated at night by game_manager, deactivated at dawn. Flees from campfire safe zone.

**UI & Input:**
- `touch_joystick.gd` — Virtual joystick for touch input (left side of screen)
- `joystick_visual.gd` — @tool script that generates circle textures procedurally for joystick UI
- `ambient_music.gd` — Procedural audio via AudioStreamGenerator (drone tones, wind, random creaking)

## Key Patterns

- **GDScript type inference:** Always use explicit types (`var x: float = ...`) instead of `:=` when calling methods on dynamically-typed variables (e.g., nodes from groups). Godot 4.6 is strict about this.
- **Procedural nodes:** Trees created by forest_generator use dynamic child lookup (iterating `get_children()`) rather than `@onready $NodeName`, since node names aren't guaranteed when created via code.
- **Signal wiring:** All signal connections happen in `game_manager._ready()`, not in individual scripts.
- **Groups:** Player is in group `"player"`, trees are in group `"tree"`.

## Workflow Rules

- **Git commits:** Commit progress regularly after completing a feature, fixing a bug, or making significant changes. Do not wait for the user to ask — commit proactively.
- **PROGRESS.md:** Must be updated after every development step. Documents all changes made, bugs fixed, and important decisions with dates. Append new entries at the bottom.

## Documentation

- `game-design.md` — Full design document: MVP roadmap, enemy descriptions, biome plans, class system design
- `PROGRESS.md` — Fortlaufende Entwicklungsdokumentation (see Workflow Rules)

## Language

The game UI, variable names, comments, and commit messages are in **German**. Code structure (function names, Godot API) is in English.
