# Repository Guidelines

## Project Structure & Scope

This project uses Godot 4.7.2, GDScript, Compatibility rendering, and Blender 5.3.0. It has a kitchen scene viewer and a separate gameplay entry with WASD, collision, mouse look, hold-to-zoom, real-surface targeting, 13 registered slots and two stable hand slots. Step 10 and its requested additions have accepted dual-hand pickup, F immersion, close-up rotation and free tool movement. Full placement and actual washing remain planned. MVP covers plates and mugs; additional tableware and classification are post-MVP.

- `project.godot`: project entry point; main scene is `Scenes/kitchen-game.tscn`.
- `Scenes/kitchen-game.tscn`: hand-authored gameplay entry inheriting the kitchen layout, with the viewer script removed and viewer overlay hidden. Generators must not overwrite this file.
- `Scenes/game-hud.tscn`: hand-authored crosshair, target-name label and basic Esc interface, instanced only by the gameplay entry; generators must not overwrite it.
- `Scenes/player.tscn`: hand-authored CharacterBody3D with a capsule and player camera. `Scenes/kitchen-walk-collision.tscn` contains player-only floor, cabinet, wall and boundary blockers; generators must not overwrite either scene.
- `Scenes/Dishes/plate.tscn` and `mug.tscn`: hand-authored StaticBody3D wrappers reusing formal GLBs. Assign a unique `instance_id` and an `initial_slot_id` for gameplay initialization. The registry places the three initial dishes at complete tray marker poses. All inherited display dishes are hidden only in gameplay, leaving the rack empty.
- `Scenes/kitchen-slots.tscn`: hand-authored registry entry with calibrated temporary plate/mug poses and visible markers. `Resources/Kitchen/kitchen-layout.tres` lists all 13 tray/rack/temporary slots. Generators must not overwrite these files.
- `Scenes/kitchen-demo.tscn`: generated viewer scene; open it separately to inspect assets and use viewer controls.
- `Scripts/Dishes/dish_carry.gd` owns two stable hand slots and the original carried nodes; `hand_item.gd` caches each hand's origin, bounds and safe pose. `Scripts/Tools/cleaning_tool.gd` stores identity/home and validates return; `world_cleaning_tools.gd` wraps the existing sponge/head after surface assembly and provides a visual hose. Do not leave old environment collision at a picked-up tool's home.
- `Scripts/`: viewer control in `kitchen_viewer.gd`; input intentions in `Input/game_input.gd`; walking, look and zoom in `Player/player_controller.gd`; HUD bindings in `UI/game_hud.gd`; instance identity in `Dishes/dish_body.gd`; surface collision and targeting in `Interaction/`; marker/config/state registration in `Slots/`; shared Resources in `Data/` and RefCounted data in `State/`. The registry uses independent SlotState objects; OrderState and DishState cleanliness are not yet attached to the gameplay scene.
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

These commands assemble/render the kitchen, import resources, rebuild the viewer scene, and smoke-test the default gameplay entry, respectively. Run Python generators through Blender, not standalone Python. Preserve manual edits before rebuilding: generators overwrite outputs. Open `project.godot` and press F5 for the gameplay entry; open `Scenes/kitchen-demo.tscn` and press F6 for interactive viewing. Gameplay supports WASD, direct mouse look, player collision, a crosshair and a basic Esc interface. Hold right mouse to zoom while empty-handed or holding soap; dish modes retain right-drag rotation intentions.

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

Success prints `PLAYER_MOVEMENT_OK` and exits with code 0 after about 20 seconds. It checks safe spawn, camera ownership, WASD/diagonal speed, 30/120 Hz physics rates, camera-heading projection, mode restrictions, kitchen blockers and task-area paths. Player collision is on layer 2 with mask 16; walk blockers use layer 5 (value 16). Interaction rays exclude both layers and use actual surface/occlusion geometry instead of the coarse cabinet blocker.

Verify direct mouse look, hold-to-zoom and the original viewer controls:

```powershell
& $godotExe --headless --path . --script Tools/verify_mouse_look.gd
```

Success prints `MOUSE_LOOK_OK` and exits with code 0. It checks yaw/pitch, walking while looking, mode/focus recovery, FOV restoration and viewer right-drag/presets. Right mouse reuses `game_rotate`: `zoom_view` when empty, carrying only a tool or holding soap; `rotate_dish` with a dish or in close-up. Zoom caches the original FOV, defaults to 35 degrees and restores on release, UI, focus loss or hand-mode change. Keep it separate from the implemented F dish-distance transition. Test real capture and zoom interactively with F5.

Verify independent dish identities, real surfaces and crosshair targeting:

```powershell
& $godotExe --headless --path . --script Tools/verify_dish_targeting.gd
```

Success prints `DISH_TARGETING_OK` and exits with code 0. It checks two plates and one mug, full poses, short-ray surface hits/normals, transformed cups, open cup/handle/rack/tray/sink geometry, range, occlusion, target-name feedback, menu/focus clearing and viewer isolation. F5: approach the left tray and aim at each dish; names disappear when looking away or beyond 1.5 m. Step 10 pickup is accepted; full placement and actual washing are still pending.

Dish surfaces use layer 1 (value 1), environment surfaces layer 3 (value 4) and physical cleaning tools layer 4 (value 8), all with mask 0. `DishTargeting` uses mask 13 and accepts only the first hit. An empty temporary slot can be selected only from a real basin hit; a foreground dish takes priority. `MeshSurfaceCollision` scales triangle coordinates by 100 with reciprocal uniform shape scaling to preserve metre dimensions and short-ray precision. Occluders snapshot mesh poses on ready; future animated parts must synchronize their shapes. New target types must coordinate with DISH/SLOT/CLEANING_TOOL/NONE routing; actual actions must requery rather than trust cached targets.

Verify full slot registration, support and temporary targets:

```powershell
& $godotExe --headless --path . --script Tools/verify_kitchen_slots.gd
```

Success prints `KITCHEN_SLOTS_OK` and exits with code 0. It checks 3 tray, 8 rack and 2 temporary slots, compatible types, full poses, independent occupancy and 13 simultaneous real dish placements for surface-edge intersections and approximately 0.5 mm support gaps. It also checks temporary targeting, range/occlusion/menu handling, placed-dish soap intentions and viewer isolation. F5: inspect the two basin markers and crosshair names; the gameplay rack is empty. F6 keeps the original display. Actual pickup, placement and pump execution are not implemented by this check.

`KitchenSlot.get_pose()` returns the complete marker transform; do not add another half-height. Temporary poses are calibrated to actual basin geometry, with separate `SelectionSurface` points for aiming. `accepts` and `is_empty` are partial checks, not placement authorization. The registry currently owns per-scene SlotState occupancy; future OrderState integration must share or explicitly replace it. `initial_slot_id` is initialization data, not the current slot or the most recent pickup origin. World queries run in EMPTY/CARRYING/SOAP_BOTTLE and exclude all held RIDs. In CLOSE_UP/TRANSITION, DishTargeting must not overwrite the surface target owned by DishCarry. Full slot previews remain planned. Preserve the per-step acceptance workflow: steps 1–10 and the requested additions are accepted; step 11 has not begun.

## Dual-hand and immersive verification

```powershell
& $godotExe --headless --path . --script Tools/verify_dish_carry.gd
& $godotExe --headless --path . --script Tools/verify_dual_wield.gd
```

Success prints `DISH_CARRY_OK` / `DUAL_WIELD_OK` and exits 0. The first item goes left, the second right; retain the other item’s hand on return. Allow two dishes or one dish plus a cleaning tool; soap remains exclusive and unimplemented. Pickup releases the current occupied SlotState and stores the source per hand; `initial_slot_id` is initialization only. `held_dish` is a first-dish compatibility getter, not a confirmed two-dish placement selection rule. Define that rule before step 11.

Use world left-click/E to pick up a tool. In ordinary carrying E returns the held tool within 1.5 m and line of sight, without switching the other item’s hand. Only F enters/exits immersion for a dish+tool pair; Q/E hold left/right rotation there, and right-drag also rotates. Keys 1/2/3 do not select, generate or return physical tools. Both tools freely follow the cursor while idle/off-surface/rotating, and only active left use attaches/aims at the current dish; F restores carry anchors. Tool movement must stay visible at viewport edges and clear the near plane.

Background blur is still step 17; ordinary carry rotation/scroll limits are incomplete step 16 work. Pause currently blocks input without freezing the scene. Hose links must scale their local Y length after orientation, not world Y; continuity/radius checks are not collision/length simulation. Water, wetness eligibility, dirt removal, placement, soap and orders are not yet scene gameplay. Details and current screenshots are in `Docs/scenes/kitchen-game/kitchen-game.md`.
## Coding Style & Naming Conventions

Use tabs in GDScript and four spaces in Python/PowerShell. Prefer typed GDScript signatures, `snake_case` functions/scripts, and kebab-case asset filenames such as `plate-standard.glb`. Preserve exported node names, including `Rack_Slot_01`, and meter-based dimensions. Update the matching generator when changing procedural assets or scenes. No formatter/linter is configured; check whitespace with `git diff --check`.

## Testing Guidelines

No dedicated test framework or coverage threshold exists. Use generator assertions and the import/startup checks above. Name new standalone Godot checks `Tools/verify_<feature>.gd` and document their invocation. Visually inspect changed assets for intersections, materials, and camera clipping; verify viewer keys 1–4, R, right-drag, and focus release. `Tools/capture_kitchen_demo.gd` requires graphics mode, not `--headless`.

## Commit & Pull Request Guidelines

History uses `feat:` and `docs:` prefixes with concise Chinese summaries. Follow that pattern and keep commits focused. PRs should explain the change, link relevant issues, list validation commands/results, and include screenshots for visual changes. Update affected asset notes and previews. Commit `.blend`, `.glb`, `.uid`, and asset-side `.import` files; exclude `.godot/`, backups, logs, credentials, and build outputs.
