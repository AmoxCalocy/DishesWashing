# Repository Guidelines

## Project Structure & Scope

This project uses Godot 4.7.2, GDScript, Compatibility rendering, and Blender 5.3.0. It has a kitchen scene viewer and a separate gameplay entry with WASD, collision, mouse look, hold-to-zoom, real-surface targeting, 11 registered origin/rack poses and two stable hand slots. Steps 1–13, including basin stacking and previous additions, are accepted as of 2026-11-26. Ordinary 1/2 selects dishes; shared read-only rules drive free basin previews and fixed rack previews. Ordinary held-tool use, F immersion, middle-drag/Q/E rotation and free immersive tool movement remain available. Actual placement and basin stacking are implemented; Q safe return and actual washing remain planned. MVP covers plates and mugs; additional tableware and classification are post-MVP.

- `project.godot`: project entry point; main scene is `Scenes/kitchen-game.tscn`.
- `Scenes/kitchen-game.tscn`: hand-authored gameplay entry inheriting the kitchen layout, with the viewer script removed and viewer overlay hidden. Generators must not overwrite this file.
- `Scenes/game-hud.tscn`: hand-authored crosshair, target-name label and basic Esc interface, instanced only by the gameplay entry; generators must not overwrite it.
- `Scenes/player.tscn`: hand-authored CharacterBody3D with a capsule and player camera. `Scenes/kitchen-walk-collision.tscn` contains player-only floor, cabinet, wall and boundary blockers; generators must not overwrite either scene.
- `Scenes/Dishes/plate.tscn` and `mug.tscn`: hand-authored StaticBody3D wrappers reusing formal GLBs. Assign a unique `instance_id` and an `initial_slot_id` for gameplay initialization. The registry places the three initial dishes at complete tray marker poses. All inherited display dishes are hidden only in gameplay, leaving the rack empty.
- `Scenes/kitchen-slots.tscn`: hand-authored registry entry with layout and basin paths, without temporary markers. `Resources/Kitchen/kitchen-layout.tres` lists 3 tray initialization origins and 8 rack slots. Only the rack offers fixed placement targets; the basin uses continuous real-surface positions for either dish type. Generators must not overwrite these files.
- `Scenes/kitchen-demo.tscn`: generated viewer scene; open it separately to inspect assets and use viewer controls.
- `Scripts/Dishes/dish_carry.gd` owns two stable hand slots and the original carried nodes; `hand_item.gd` stores each pickup's origin_kind, complete origin_pose and optional origin_slot_id, plus bounds and safe-pose caches. DishBody tracks REGISTERED/BASIN/HELD location, placement bounds and supporting dish IDs; free position is its global transform. `Scripts/Tools/cleaning_tool.gd` stores identity/home and validates return; `world_cleaning_tools.gd` wraps the existing sponge/head after surface assembly and provides a visual hose. Do not leave old environment collision at a picked-up tool's home.
- `Scripts/Slots/placement_rules.gd` and `placement_result.gd` provide shared read-only authorization through `DishCarry.check_placement` (registered pose) and `check_surface_placement` (free basin hit). `SlotConfig.maximum_dish_size` describes canonical local bounds including handles for all 11 registered poses. `HandItem` lazily caches real mesh triangles, thin query shapes and eight bottom-ring support points. `placement_preview.gd` copies only visual meshes, with independent green/red material and HUD reasons. Checks and previews never reserve or place dishes; confirmation alone commits the original body and state.
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

These commands assemble/render the kitchen, import resources, rebuild the viewer scene, and smoke-test the default gameplay entry, respectively. Run Python generators through Blender, not standalone Python. Preserve manual edits before rebuilding: generators overwrite outputs. Open `project.godot` and press F5 for the gameplay entry; open `Scenes/kitchen-demo.tscn` and press F6 for interactive viewing. Gameplay supports WASD, direct mouse look, player collision, a crosshair and a basic Esc interface. Right mouse zooms when empty-handed, holding only a tool or holding soap; ordinary held dishes retain rotation intentions, and immersion uses middle-drag. Ordinary 1/2 selects left/right dishes.

After importing new scripts/resources, verify configuration and runtime-state isolation:

```powershell
& $godotExe --headless --path . --script Tools/verify_runtime_state.gd
```

Success prints `RUNTIME_STATE_OK` and exits with code 0. It checks independent dish/region/slot/tool data, fresh initial values, and unchanged shared configuration without modifying scenes or saves.

Verify weighted cleanliness and the actual 95% requirement separately:

```powershell
& $godotExe --headless --path . --script Tools/verify_cleanliness.gd
```

Success prints `CLEANLINESS_OK` and exits with code 0. It checks unequal initial stain amounts, zero dirt, per-region bounds, foam independence, and 94.9%/95%/95.1% boundaries. Use `DishState.meets_cleanliness_requirement()` for the cleanliness gate; the rounded display percentage must not authorize placement. Step 11 shared rules use this gate for rack slots; confirmation uses the same actual gate without defaulting unknown state to clean.

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

Success prints `MOUSE_LOOK_OK` and exits with code 0. It checks yaw/pitch, walking while looking, mode/focus recovery, FOV restoration and viewer right-drag/presets. Right mouse uses `game_rotate`: `zoom_view` when empty, carrying only a tool or holding soap; rotation intention when ordinarily carrying a dish. Middle mouse uses the separate `game_rotate_close` action only in immersion. Immersive right mouse does not rotate, zoom or cancel tool use. Zoom caches the original FOV, defaults to 35 degrees and restores on release, UI, focus loss or hand-mode change. Keep it separate from the implemented F dish-distance transition. Test real capture and zoom interactively with F5.

Verify independent dish identities, real surfaces and crosshair targeting:

```powershell
& $godotExe --headless --path . --script Tools/verify_dish_targeting.gd
```

Success prints `DISH_TARGETING_OK` and exits with code 0. It checks two plates and one mug, full poses, short-ray surface hits/normals, transformed cups, open cup/handle/rack/tray/sink geometry, range, occlusion, target-name feedback, menu/focus clearing and viewer isolation. F5: approach the left tray and aim at each dish; names disappear when looking away or beyond 1.5 m. Pickup, placement and free-dish repick are accepted; actual washing remains pending.

Dish surfaces use layer 1 (value 1), environment surfaces layer 3 (value 4) and physical cleaning tools layer 4 (value 8), all with mask 0. `DishTargeting` uses mask 13 and accepts only the first hit. Basin positions require a real interior hit or an eligible visible BASIN dish support; tools and non-basin dishes continue to occlude. `MeshSurfaceCollision` scales triangle coordinates by 100 with reciprocal uniform shape scaling to preserve metre dimensions and short-ray precision. Occluders snapshot mesh poses on ready; future animated parts must synchronize their shapes. Coordinate DISH/SLOT/PLACEMENT_SURFACE/STACKABLE_DISH/CLEANING_TOOL/NONE routing; actual actions must requery rather than trust cached targets.

Verify registered origins/rack poses and real support:

```powershell
& $godotExe --headless --path . --script Tools/verify_kitchen_slots.gd
```

Success prints `KITCHEN_SLOTS_OK` and exits with code 0. It checks 3 tray origins and 8 rack slots, compatible types, full poses, independent occupancy and 11 simultaneous real dish poses for surface-edge intersections and approximately 0.5 mm support gaps. It also checks removal of fixed basin markers, placed-dish soap intentions and viewer isolation. F5 has an empty rack and no basin plate/cup markers; F6 keeps the original display. Actual placement and pump execution are not implemented by this check.

`KitchenSlot.get_pose()` returns the complete marker transform; do not add another half-height. Basin poses are solved from the current real hit and dish support geometry, without a slot ID. `accepts` and `is_empty` are partial checks; use the shared DishCarry checks. The registry owns per-scene SlotState occupancy; future OrderState integration must share or explicitly replace it. `initial_slot_id` is initialization data, not the current position or most recent pickup origin. World queries exclude all held RIDs. In CLOSE_UP/TRANSITION, DishTargeting must not overwrite DishCarry's surface target. Preserve the per-step acceptance workflow: steps 1–13 and additions are accepted; step 14 has not begun.

## Dual-hand, ordinary tool and immersive verification

```powershell
& $godotExe --headless --path . --script Tools/verify_dish_carry.gd
& $godotExe --headless --path . --script Tools/verify_dual_wield.gd
& $godotExe --headless --path . --script Tools/verify_world_tool_use.gd
```

Success prints `DISH_CARRY_OK` / `DUAL_WIELD_OK` and exits 0. The first item goes left, the second right; retain the other item’s hand on return. Allow two dishes or one dish plus a cleaning tool; soap remains exclusive and unimplemented. Pickup releases any current registered SlotState and stores the actual registered/basin source per hand; `initial_slot_id` is initialization only. `held_dish` and `origin_slot_id` remain first-dish compatibility getters. Use `selected_dish`, `selected_dish_hand` and `get_selected_dish_item()` for placement and future Q return.

Use world left-click/E to pick up a tool. When holding a tool, ordinary left hold uses it on the first placed dish hit by the crosshair, while walking and looking remain available. All held RIDs are excluded. The sponge supplies a continuous scrub animation; the sprayer aims its real nozzle. Ordinary release restores that tool's safe hand pose. Invalid hits stop contact but preserve the held intention for re-entry; UI, focus loss or mode/tool changes require a fresh press. `contact_dish` identifies the current surface recipient; this is not actual washing or water.

With a tool and a free hand, ordinary E aimed at a dish picks it up; other held-tool contexts attempt return within 1.5 m and line of sight, preserving the other hand. Only F enters/exits immersion for a dish+tool pair; Q/E hold left/right rotation there, and middle-drag also rotates. Keys 1/2/3 do not select, generate or return physical tools. In immersion both tools freely follow the cursor while idle/off-surface/rotating, and only active left use attaches/aims at the current held dish; F restores carry anchors. Immersive free tool movement must stay visible at viewport edges and clear the near plane.

The ordinary tool check prints `WORLD_TOOL_USE_OK` and exits 0. It covers both tools and hand sides, plate/cup surfaces, unchanged target occupancy, continuous aiming, walking/look, first-hit occlusion, range, UI/focus interruption, E pickup during use and F coexistence. Ordinary tool poses also check near-plane clearance, space and approach paths; tray rims may require an approach above the surface. Sprayers retain a 1.5 m home-distance limit. Full hose collision and length simulation remain planned.

Background blur is still step 17; ordinary carry rotation/scroll limits are incomplete step 16 work. Pause currently blocks input without freezing the scene. Hose links must scale their local Y length after orientation, not world Y; continuity/radius checks are not collision/length simulation. Water, wetness eligibility, dirt removal, soap and orders are not yet scene gameplay. Details and current screenshots are in `Docs/scenes/kitchen-game/kitchen-game.md`.

## Shared placement authorization (step 11)

```powershell
& $godotExe --headless --path . --script Tools/verify_placement_rules.gd
```

Success prints `PLACEMENT_RULES_OK` and exits 0. It covers all 11 registered poses, actual 94.9%/95%/95.1% boundaries, foam independence, missing/mismatched state, registry identity, type, actual enlarged geometry, occupancy/source release, range/occlusion, triangle-interior obstacles, handle openings, read-only results, explicit hand selection and UI blocking.

In ordinary carrying, 1 selects the left dish and 2 the right. A lone dish is selected automatically, a second pickup preserves selection, and selecting an empty/tool hand preserves the previous dish with feedback. HUD marks the selected name. Reuse the existing mappings; do not turn these keys back into physical tool switching or apply hand selection in immersion.

`DishCarry.check_placement` gates the ordinary/UI context and delegates the selected HandItem to `PlacementRules.evaluate`; `check_surface_placement` delegates free basin hits to `evaluate_surface`. Results include reason, pose, dish identity and hand index; free positions leave slot_id empty. Registered poses need compatible type, empty occupancy, released source, configured dimensions, range, visibility and actual final space. Rack slots additionally require the matching real `DishState` and `meets_cleanliness_requirement()`; missing state must not default to clean. Tray origins and free basin positions allow dirty dishes; foam never rejects placement. DishState/OrderState are still not bound to gameplay, and tests inject known states.

Formal dish-local maximum sizes are plate `(0.251, 0.025, 0.251)` and mug `(0.132, 0.106, 0.091)` metres, including the handle. Space checks use a box broad phase and thin real-triangle prisms, preserving openings. Do not reuse carry's 4 mm margin at slots with about 0.5 mm support gaps. These checks authorize a final pose, not a simulated insertion trajectory.

Rule checks and previews remain read-only. Step 13 confirmation requeries immediately before its synchronous commit; step 14 Q return must do the same using the selected HandItem's actual source. Q return remains unimplemented.

## Free basin and fixed rack previews (step 12)

```powershell
& $godotExe --headless --path . --script Tools/verify_placement_preview.gd
```

Success prints `PLACEMENT_PREVIEW_OK` and exits 0. It covers continuous plate/mug basin positions, selected meshes including the handle, independent edge-ray/support-gap checks, all 8 rack targets, type/cleanliness/occupancy changes, real dish overlap, walls, range, occlusion, UI/focus, held tool exclusions, F recovery and viewer isolation. The preview has no collision bodies and cannot be picked up or reserve occupancy. Preview queries do not place dishes; left-click confirmation is implemented in step 13, while Q remains unimplemented.

`KitchenSlotRegistry.is_basin_hit` identifies the real basin/drain shape owners, excluding the countertop and rim. Free poses follow the hit XZ; eight real bottom-ring probes settle the dish with about 0.5 mm clearance and align to shallow floor slopes. Support contacts must surround the centre; steep walls, insufficient support and final mesh intersections reject placement. Geometry is cached, but current-world queries and verdicts are recomputed. Fixed targeting selects only DRAINING_RACK poses; tray markers initialize dishes and are not manual placement targets. The old Sink_Plate_01/Sink_Mug_01 and SelectionSurface markers are removed from production.

Free dishes record BASIN location and can be repicked without SlotState; HandItem stores each actual source type/pose for step 14. Do not recreate fixed basin slots or use first-dish compatibility getters. Matching authoritative state references now belong to DishCarry.dish_states, which is empty in production until gameplay supplies them. Rack previews currently show unknown cleanliness as invalid; do not default to 100% or use Examples as production data. Actual washing, full pause, performance targets and insertion trajectories remain unverified by this preview check.

## Placement and basin stacking (step 13)

```powershell
& $godotExe --headless --path . --script Tools/verify_dish_placement.gd
& $godotExe --headless --path . --script Tools/verify_basin_stacking.gd
```

Success prints `DISH_PLACEMENT_OK` / `BASIN_STACKING_OK` and exits 0. They cover fresh target/hand/cleanliness/occupancy/space checks, original identity, 8 real rack commits, basin placement/repick, full sources, stable other hands, optional bound state flags, same-tick duplicate requests, UI/transition, both tools and F, real overlapping ceramic support, top-first pickup and changed supports. There are 14 verification scripts and 44 unique script UIDs.

Ordinary left click places on a free basin surface or rack. With a dish and no tool, aiming at an already placed basin dish routes STACKABLE_DISH: left click stacks, E picks up. Empty hands still left-click pickup; holding a tool keeps left-hold use on placed dishes and E pickup when a hand is free. Only BASIN dishes in PlayableDishes qualify as ceramic support; `is_basin_hit` means the real basin mesh, while `is_basin_support` also accepts those dishes. Tray/rack dishes remain occluders, not stacking targets.

Stack height starts from actual basin support, samples cached lowest real vertices in a 12-by-12 XZ partition, then corrects missed edge contacts with thin real-triangle intersections and bounded height refinement. Every query reads the current world; no validity is cached. Final space checks all environment/tool/dish geometry, preserving cup and handle openings. `support_dish_ids` records actual supporting dishes, and pickup rejects removing a supporting lower dish until its dependants are picked up. This is static automatic placement without rigid-body falling or balance simulation; rack slots retain exclusive occupancy.

`_place_dish` requeries the target and shared checks, then snaps the original body/collision to the authorized full pose, reparents to PlayableDishes, updates location/support data and optional matching DishState flags, releases only the selected hand, and clears the ghost. A same-physics-tick guard prevents duplicates placing the other item before moved collision bodies synchronize. Rejections keep holding/occupancy unchanged. Basin tool approach can lift in the safe carry orientation, test rotation clearance, cross above the rim and descend. Step 14 Q must reuse the selected HandItem source and current support/space rules.

## Coding Style & Naming Conventions

Use tabs in GDScript and four spaces in Python/PowerShell. Prefer typed GDScript signatures, `snake_case` functions/scripts, and kebab-case asset filenames such as `plate-standard.glb`. Preserve exported node names, including `Rack_Slot_01`, and meter-based dimensions. Update the matching generator when changing procedural assets or scenes. No formatter/linter is configured; check whitespace with `git diff --check`.

## Testing Guidelines

No dedicated test framework or coverage threshold exists. Use generator assertions and the import/startup checks above. Name new standalone Godot checks `Tools/verify_<feature>.gd` and document their invocation. Visually inspect changed assets for intersections, materials, and camera clipping; verify viewer keys 1–4, R, right-drag, and focus release. `Tools/capture_kitchen_demo.gd` requires graphics mode, not `--headless`.

## Commit & Pull Request Guidelines

History uses `feat:` and `docs:` prefixes with concise Chinese summaries. Follow that pattern and keep commits focused. PRs should explain the change, link relevant issues, list validation commands/results, and include screenshots for visual changes. Update affected asset notes and previews. Commit `.blend`, `.glb`, `.uid`, and asset-side `.import` files; exclude `.godot/`, backups, logs, credentials, and build outputs.
