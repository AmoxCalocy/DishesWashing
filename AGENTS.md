# Repository Guidelines

## Project Structure & Scope

This project uses Godot 4.7.2, GDScript, Compatibility rendering, Blender 5.3.0 and the built-in Jolt backend. It has a kitchen viewer and separate gameplay entry with WASD, collision, mouse look/zoom, real-surface targeting, 11 registered origin/rack poses and two stable hand slots. Steps 1–16 and additions are accepted as of 2026-11-27. Ordinary 1/2 selects a dish; middle drag rotates that dish in both ordinary and immersive modes, and G releases it into gravity outside immersion. Only the rack retains fixed placement. Ordinary Q return and all placement previews are removed. Keep physical tools, verified F round trips, immersive Q/E, type-specific close wheel ranges and free immersive tool movement. Actual washing is planned; MVP covers plates and mugs, with extra types/classification post-MVP.

- `project.godot`: project entry point; main scene is `Scenes/kitchen-game.tscn`.
- `Scenes/kitchen-game.tscn`: hand-authored gameplay entry inheriting the kitchen layout, with the viewer script removed and viewer overlay hidden. Generators must not overwrite this file.
- `Scenes/game-hud.tscn`: hand-authored crosshair, target-name label and basic Esc interface, instanced only by the gameplay entry; generators must not overwrite it.
- `Scenes/player.tscn`: hand-authored CharacterBody3D with a capsule and player camera. `Scenes/kitchen-walk-collision.tscn` contains player-only floor, cabinet, wall and boundary blockers; generators must not overwrite either scene.
- `Scenes/Dishes/plate.tscn` and `mug.tscn`: hand-authored StaticBody3D wrappers reusing formal GLBs. Assign a unique `instance_id` and an `initial_slot_id` for gameplay initialization. The registry places the three initial dishes at complete tray marker poses. All inherited display dishes are hidden only in gameplay, leaving the rack empty.
- `Scenes/kitchen-slots.tscn`: hand-authored registry entry with layout and basin paths, without temporary markers. `Resources/Kitchen/kitchen-layout.tres` lists 3 tray initialization origins and 8 rack slots. Only the rack offers fixed placement targets; the basin uses continuous real-surface positions for either dish type. Generators must not overwrite these files.
- `Scenes/kitchen-demo.tscn`: generated viewer scene; open it separately to inspect assets and use viewer controls.
- `Scripts/Dishes/dish_carry.gd` owns two stable hand slots and the original carried nodes; `hand_item.gd` stores each pickup's actual source kind/pose/optional slot, bounds and safe-pose caches. DishBody tracks REGISTERED/HELD/WORLD and an independent motion_body; free position follows its simulated transform. `Scripts/Tools/cleaning_tool.gd` stores identity/home and validates return; `world_cleaning_tools.gd` wraps the existing sponge/head after surface assembly and provides a visual hose. Do not leave old environment collision at a picked-up tool's home.
- `Scripts/Slots/placement_rules.gd` and `placement_result.gd` provide read-only registered-pose authorization through `DishCarry.check_placement`; thin real-triangle space checks also guard G release. Slot dimensions include handles. Preview source, free-surface final-pose rules and static stack sampling are removed; G commits the original body and state.
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

These commands assemble/render the kitchen, import resources, rebuild the viewer scene, and smoke-test the default gameplay entry, respectively. Run Python generators through Blender, not standalone Python. Preserve manual edits before rebuilding: generators overwrite outputs. Open `project.godot` and press F5 for the gameplay entry; open `Scenes/kitchen-demo.tscn` and press F6 for interactive viewing. Gameplay supports WASD, direct mouse look, player collision, a crosshair and a basic Esc interface. Right mouse zooms when empty-handed, holding only a tool or holding soap; held dishes rotate with middle drag in both modes. Ordinary 1/2 selects left/right dishes. Wheel distance adjustment is immersive only.

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

Success prints `MOUSE_LOOK_OK` and exits with code 0. It checks yaw/pitch, walking while looking, mode/focus recovery, FOV restoration and viewer right-drag/presets. Right mouse uses `game_rotate` only for `zoom_view` when empty, carrying only a tool or holding soap; held dishes neither rotate nor zoom with right mouse. Middle mouse retains the action name `game_rotate_close` and now rotates dishes in both modes. Right release must not end a middle drag; immersive right mouse also must not cancel tool use. Zoom caches the original FOV, defaults to 35 degrees and restores on release, UI, focus loss or hand-mode change. Keep FOV zoom separate from F and immersive wheel distance. Test real capture and zoom interactively with F5.

Verify independent dish identities, real surfaces and crosshair targeting:

```powershell
& $godotExe --headless --path . --script Tools/verify_dish_targeting.gd
```

Success prints `DISH_TARGETING_OK` and exits with code 0. It checks two plates and one mug, full poses, short-ray surface hits/normals, transformed cups, open cup/handle/rack/tray/sink geometry, range, occlusion, target-name feedback, menu/focus clearing and viewer isolation. F5: approach the left tray and aim at each dish; names disappear when looking away or beyond the current 2 m range. Pickup, placement and free-dish repick are accepted; actual washing remains pending.

Dish surfaces use layer 1 (value 1), environment surfaces layer 3 (value 4) and physical cleaning tools layer 4 (value 8), all with mask 0. `DishTargeting` uses mask 13 and accepts only the first hit. G uses the first real surface or a short forward point for release; every foreground object continues to occlude. `MeshSurfaceCollision` scales triangle coordinates by 10 with reciprocal uniform shape scaling to preserve metre dimensions and short-ray precision. Occluders snapshot mesh poses on ready; future animated parts must synchronize their shapes. Coordinate DISH/SLOT/CLEANING_TOOL/NONE routing; actual actions must requery rather than trust cached targets.

Verify registered origins/rack poses and real support:

```powershell
& $godotExe --headless --path . --script Tools/verify_kitchen_slots.gd
```

Success prints `KITCHEN_SLOTS_OK` and exits with code 0. It checks 3 tray origins and 8 rack slots, compatible types, full poses, independent occupancy and 11 simultaneous real dish poses for surface-edge intersections and approximately 0.5 mm support gaps. It also checks removal of fixed basin markers, placed-dish soap intentions and viewer isolation. F5 has an empty rack and no basin plate/cup markers; F6 keeps the original display. Actual placement and pump execution are not implemented by this check.

`KitchenSlot.get_pose()` returns the complete marker transform; do not add another half-height. Free dish poses follow physics, without slot IDs or static support records. `accepts` and `is_empty` are partial checks; use the shared DishCarry checks. The registry owns per-scene SlotState occupancy; future OrderState integration must share or explicitly replace it. `initial_slot_id` is initialization data, not the current position or most recent pickup origin. World queries exclude all held RIDs. In CLOSE_UP/TRANSITION, DishTargeting must not overwrite DishCarry's surface target. Preserve the per-step acceptance workflow: steps 1–16 and additions are accepted; step 17 background blur has not begun.

## Dual-hand, ordinary tool and immersive verification

```powershell
& $godotExe --headless --path . --script Tools/verify_dish_carry.gd
& $godotExe --headless --path . --script Tools/verify_dual_wield.gd
& $godotExe --headless --path . --script Tools/verify_world_tool_use.gd
```

Success prints `DISH_CARRY_OK` / `DUAL_WIELD_OK` and exits 0. The first item goes left, the second right; retain the other item’s hand on return. Allow two dishes or one dish plus a cleaning tool; soap remains exclusive and unimplemented. Pickup releases any current registered SlotState and stores the actual registered/world source per hand; `initial_slot_id` is initialization only. `held_dish` and `origin_slot_id` remain first-dish compatibility getters. Use `selected_dish`, `selected_dish_hand` and `get_selected_dish_item()` for G release.

Use world left-click/E to pick up a tool. When holding a tool, ordinary left hold uses it on the first placed dish hit by the crosshair, while walking and looking remain available. All held RIDs are excluded. The sponge supplies a continuous scrub animation; the sprayer aims its real nozzle. Ordinary release restores that tool's safe hand pose. Invalid hits stop contact but preserve the held intention for re-entry; UI, focus loss or mode/tool changes require a fresh press. `contact_dish` identifies the current surface recipient; this is not actual washing or water.

With a tool and a free hand, ordinary E aimed at a dish picks it up; other held-tool contexts attempt return within 1.5 m and line of sight, preserving the other hand. Only F enters/exits immersion for a dish+tool pair; Q/E hold left/right rotation there, and middle-drag also rotates. Keys 1/2/3 do not select, generate or return physical tools. In immersion both tools freely follow the cursor while idle/off-surface/rotating, and only active left use attaches/aims at the current held dish; F restores carry anchors. Immersive free tool movement must stay visible at viewport edges and clear the near plane.

The ordinary tool check prints `WORLD_TOOL_USE_OK` and exits 0. It covers both tools and hand sides, plate/cup surfaces, unchanged target occupancy, continuous aiming, walking/look, first-hit occlusion, range, UI/focus interruption, E pickup during use and F coexistence. Ordinary tool poses also check near-plane clearance, space and approach paths; tray rims may require an approach above the surface. Sprayers retain a 1.5 m home-distance limit. Full hose collision and length simulation remain planned.

Background blur is still step 17; ordinary middle rotation and immersive wheel bounds were accepted in step 16. Pause currently blocks input without freezing the scene. Hose links must scale their local Y length after orientation, not world Y; continuity/radius checks are not collision/length simulation. Water, wetness eligibility, dirt removal, soap and orders are not yet scene gameplay. Details and current screenshots are in `Docs/scenes/kitchen-game/kitchen-game.md`.

## Dish rotation and close distance (step 16)

```powershell
& $godotExe --headless --path . --script Tools/verify_dish_manipulation.gd
```

Success prints `DISH_MANIPULATION_OK` and exits 0. It checks ordinary selected-hand middle drag, unchanged camera/other hand, right-release isolation, ordinary wheel/Q inactivity, both dish types/tools/hand orders, real front/back/cup-interior hits, tilted tool contact, near-plane clearance, obstacle-limited rotation/translation, UI/focus interruption, F angle/distance/state retention and Q/E at 30/120 Hz.

`DishBody.close_min_distance` / `close_max_distance` default to plate limits 0.40–0.56 m; `Scenes/Dishes/mug.tscn` sets 0.36–0.52 m. `HandItem.close_distance` starts at 0.45 m and belongs to that pickup, retaining the chosen value across F. Only immersive wheel moves the dish, 0.02 m per pulse; ordinary/transition/UI wheel cannot. Rotation is split into at most 3-degree increments with radius-based arc clearance and a near + 0.015 m bound. Stop at unsafe geometry rather than preventing full face/back access. Wheel also checks the actual translation path; rejected input keeps the current distance. Both adjustments stop old tool use. Selection/G/UI/focus end old middle holds; right release does not. No new input mapping was added, and ordinary right rotation must not return.

## F transition scene coverage (step 15)

```powershell
& $godotExe --headless --path . --script Tools/verify_close_transition.gd
```

Success prints `CLOSE_TRANSITION_OK` and exits 0. It covers 40 plate/mug, sponge/sprayer, pickup-order/hand and station/heading round trips; original identity/RID, source, occupancy, held motion body, camera pose/FOV, approximately 0.2 s transitions, blocked WASD, Q/E rotation, fresh input after exit, real wall/destination/travel space, return obstruction, sprayer home range and entry/exit interruptions. Known DishState dirt/foam/detergent values are injected only by the fixture; production remains unbound.

F validates translation paths in both directions with the dish's current angle. Exit must first obtain a fresh safe carry pose; failure keeps immersion and both original items with feedback. During F, carry solving excludes both held RIDs so a freely positioned tool cannot block the other hand's return; ordinary carry still uses its existing item avoidance and environment clearance. A real rack may shorten carry distance. Repeated F/G/E during transition cannot switch, drop or return anything. Completing entry behind a menu must not warp its cursor. Esc/focus clears old input, while the current Tween and world physics continue; full freezing remains step 18. F5 verifies actual capture, tool movement to both sides, stable hand restoration and menu/focus recovery.

## G release, rack rules and removed previews (step 14)

Steps 1–16 and requested additions are accepted as of 2026-11-27. The next task is step 17 background blur; do not restore the cancelled ordinary Q return or placement previews. G releases the selected 1/2 dish while retaining the other hand; ordinary left click picks up or uses a tool. Middle drag rotates dishes in both modes; Q/E remain immersive only. G is ignored in immersion, transitions and UI.

```powershell
& $godotExe --headless --path . --script Tools/verify_dish_drop.gd
& $godotExe --headless --path . --script Tools/verify_dish_placement.gd
& $godotExe --headless --path . --script Tools/verify_basin_stacking.gd
& $godotExe --headless --path . --script Tools/verify_placement_preview.gd
& $godotExe --headless --path . --script Tools/verify_placement_rules.gd
```

Success markers are DISH_DROP_OK, DISH_PLACEMENT_OK, BASIN_STACKING_OK, PLACEMENT_PREVIEW_OK and PLACEMENT_RULES_OK, all exit 0. There are 17 verification scripts, 46 unique script UIDs and 18 input mappings. The old preview check now verifies that the ghost and green/red label are absent. PlacementPreview source/UID, its scene node and HUD bindings have been removed.

DishBody retains its original StaticBody3D query mesh and identity. A separate RigidBody3D with cached convex decomposition handles movement, with REGISTERED/HELD/WORLD locations. On release the motion body becomes a sibling of the original dish; the original query body follows its full pose. Pickup freezes and reparents the motion body back under the dish. Never create replacement dish identities or leave independent motion bodies behind during cleanup.

Jolt is enabled in project.godot with penetration_slop=0.0005 m, speculative_contact_distance=0.002 m and position_steps=4. Physical dishes use layer 6 (32), WORLD mask 46 (environment 4, tools 8, other physical dishes 32, player 2); held motion bodies are frozen with layer/mask 0. Registered bodies are frozen on layer 32. Do not include walk-blocker layer 16: its coarse cabinet box seals the sink. Convex pieces preserve the physical cup/handle openings; the interaction triangles remain exact. Cache only shared geometry, never decisions or mutable progress.

G first requeries an aimed rack slot. Only the rack snaps to fixed full poses after check_placement/evaluate authorizes type, dimensions, empty occupancy, released source, current range, frustum/occlusion, actual space and actual 95% cleanliness. Missing/mismatched state never defaults to clean; foam does not reject. DishCarry.dish_states remains empty in production, with known states injected only by fixtures. Registry and future OrderState must share or explicitly replace the same occupancy ownership.

Other G releases use the current first surface normal and dish volume with about 6 cm release clearance, or a point 0.8 m ahead when no surface is hit. Check the release space, then let gravity determine the final position and angle on counters, tray, floor or basin. There is no surface-only basin authorization, final-pose solver, automatic basin search or origin return. Failure keeps holding with feedback; a same-physics-frame guard prevents releasing the other hand on duplicate input. Free motion has no SlotState or static supporting-dish dependency.

Use selected_dish, selected_dish_hand and get_selected_dish_item(); held_dish and origin_slot_id are first-dish compatibility getters. HandItem still records actual source kind/pose/optional slot, while initial_slot_id remains initialization only. The old check_surface_placement/evaluate_surface, bottom-ring/stack sampling and support_dish_ids were removed. Full pause, supply/wetness/soap/cleaning, background blur and performance targets remain in later steps.

## Coding Style & Naming Conventions

Use tabs in GDScript and four spaces in Python/PowerShell. Prefer typed GDScript signatures, `snake_case` functions/scripts, and kebab-case asset filenames such as `plate-standard.glb`. Preserve exported node names, including `Rack_Slot_01`, and meter-based dimensions. Update the matching generator when changing procedural assets or scenes. No formatter/linter is configured; check whitespace with `git diff --check`.

## Testing Guidelines

No dedicated test framework or coverage threshold exists. Use generator assertions and the import/startup checks above. Name new standalone Godot checks `Tools/verify_<feature>.gd` and document their invocation. Visually inspect changed assets for intersections, materials, and camera clipping; verify viewer keys 1–4, R, right-drag, and focus release. `Tools/capture_kitchen_demo.gd` requires graphics mode, not `--headless`.

## Commit & Pull Request Guidelines

History uses `feat:` and `docs:` prefixes with concise Chinese summaries. Follow that pattern and keep commits focused. PRs should explain the change, link relevant issues, list validation commands/results, and include screenshots for visual changes. Update affected asset notes and previews. Commit `.blend`, `.glb`, `.uid`, and asset-side `.import` files; exclude `.godot/`, backups, logs, credentials, and build outputs.
