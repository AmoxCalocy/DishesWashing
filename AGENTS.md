# Repository Guidelines

## Project Structure & Scope

This project uses Godot 4.7.2, GDScript, Compatibility rendering, and Blender 5.3.0. It has a kitchen scene viewer and a separate gameplay entry with WASD walking and player collision; mouse look and washing gameplay remain planned. MVP covers plates and mugs; additional tableware and classification are post-MVP.

- `project.godot`: project entry point; main scene is `Scenes/kitchen-game.tscn`.
- `Scenes/kitchen-game.tscn`: hand-authored gameplay entry inheriting the kitchen layout, with the viewer script removed and viewer overlay hidden. Generators must not overwrite this file.
- `Scenes/game-hud.tscn`: hand-authored crosshair and basic Esc interface, instanced only by the gameplay entry; generators must not overwrite it.
- `Scenes/player.tscn`: hand-authored CharacterBody3D with a capsule and player camera. `Scenes/kitchen-walk-collision.tscn` contains player-only floor, cabinet, wall and boundary blockers; generators must not overwrite either scene.
- `Scenes/kitchen-demo.tscn`: generated viewer scene; open it separately to inspect assets and use viewer controls.
- `Scripts/`: viewer control in `kitchen_viewer.gd`; input intentions in `Input/game_input.gd`; walking in `Player/player_controller.gd`; crosshair/menu binding in `UI/game_hud.gd`; shared Resource schemas in `Data/` and per-attempt RefCounted data in `State/`. Order state and cleanliness are not yet attached to the gameplay scene.
- `Resources/Examples/`: verification fixtures for dishes, layout and an order; these are not the production order list or complete kitchen slot registry.
- `Tools/`: Blender generators, Godot assembly scripts, and PowerShell texture tooling.
- `Assets/`: editable `.blend` sources, exported `.glb` models, and textures, grouped by purpose.
- `Docs/memory-bank/`: design and technology documents. `Docs/assets/` and `Docs/scenes/` contain delivery notes and previews; `Docs/references/` contains visual references.

## Build, Test, and Development Commands

Run PowerShell from the repository root. Adjust these local executable paths as needed:

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
$blenderExe = 'D:\Blender\blender.exe'
& $blenderExe --background --factory-startup --python-exit-code 1 --python Tools/build_kitchen_scene.py
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script Tools/build_kitchen_demo.gd
& $godotExe --headless --path . --quit-after 60
```

These commands assemble/render the kitchen, import resources, rebuild the viewer scene, and smoke-test the default gameplay entry, respectively. Run Python generators through Blender, not standalone Python. Preserve manual edits before rebuilding: generators overwrite outputs. Open `project.godot` and press F5 for the gameplay entry; open `Scenes/kitchen-demo.tscn` and press F6 for interactive viewing. Gameplay has WASD walking, player collision, a crosshair and a basic Esc interface; mouse look remains planned.

After importing new scripts/resources, verify configuration and runtime-state isolation:

```powershell
& $godotExe --headless --path . --script Tools/verify_runtime_state.gd
```

Success prints `RUNTIME_STATE_OK` and exits with code 0. It checks independent dish/region/slot/tool data, fresh initial values, and unchanged shared configuration without modifying scenes or saves.

Verify weighted cleanliness and the actual 95% requirement separately:

```powershell
& $godotExe --headless --path . --script Tools/verify_cleanliness.gd
```

Success prints `CLEANLINESS_OK` and exits with code 0. It checks unequal initial stain amounts, zero dirt, per-region bounds, foam independence, and 94.9%/95%/95.1% boundaries. Use `DishState.meets_cleanliness_requirement()` for the cleanliness gate; the rounded display percentage must not authorize placement. Full slot-placement rules remain planned.

Verify input bindings, context routing and GUI consumption:

```powershell
& $godotExe --headless --path . --script Tools/verify_game_input.gd
```

Success prints `GAME_INPUT_OK` and exits with code 0. Verify real mouse capture, Esc/resume and focus release interactively using F5. `GameInput` emits intentions through unhandled input; `PlayerController` reads its movement vector instead of polling global key state. The current interface blocks input but does not pause the scene tree or freeze gameplay state.

Verify walking and kitchen collision with the real gameplay scene:

```powershell
& $godotExe --headless --path . --script Tools/verify_player_movement.gd
```

Success prints `PLAYER_MOVEMENT_OK` and exits with code 0 after about 20 seconds. It checks safe spawn, camera ownership, WASD/diagonal speed, 30/120 Hz physics rates, camera-heading projection, mode restrictions, kitchen blockers and task-area paths. Player collision is on layer 2 with mask 16; walk blockers use layer 5 (value 16). Future interaction rays must exclude these layers and use actual surface/occlusion geometry instead of the coarse cabinet blocker.

## Coding Style & Naming Conventions

Use tabs in GDScript and four spaces in Python/PowerShell. Prefer typed GDScript signatures, `snake_case` functions/scripts, and kebab-case asset filenames such as `plate-standard.glb`. Preserve exported node names, including `Rack_Slot_01`, and meter-based dimensions. Update the matching generator when changing procedural assets or scenes. No formatter/linter is configured; check whitespace with `git diff --check`.

## Testing Guidelines

No dedicated test framework or coverage threshold exists. Use generator assertions and the import/startup checks above. Name new standalone Godot checks `Tools/verify_<feature>.gd` and document their invocation. Visually inspect changed assets for intersections, materials, and camera clipping; verify viewer keys 1–4, R, right-drag, and focus release. `Tools/capture_kitchen_demo.gd` requires graphics mode, not `--headless`.

## Commit & Pull Request Guidelines

History uses `feat:` and `docs:` prefixes with concise Chinese summaries. Follow that pattern and keep commits focused. PRs should explain the change, link relevant issues, list validation commands/results, and include screenshots for visual changes. Update affected asset notes and previews. Commit `.blend`, `.glb`, `.uid`, and asset-side `.import` files; exclude `.godot/`, backups, logs, credentials, and build outputs.
