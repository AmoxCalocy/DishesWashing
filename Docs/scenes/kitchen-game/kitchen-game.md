# 厨房可玩入口

> 第 1～9 步：行走、观察、盘杯表面与槽位注册｜2026-11-24｜用户已确认验证通过

## 打开方式

打开项目根目录的 [project.godot](../../../project.godot)，等待资源导入后按 F5，运行 [kitchen-game.tscn](../../../Scenes/kitchen-game.tscn)。

此入口复用厨房布局，已接入输入分派、准星、Esc 界面、WASD 行走碰撞及鼠标直接看向。玩家从水槽前方安全出生，水平可连续转身，俯仰限制为 ±80°；地面、柜体、后墙与边界阻止穿行或走出场地。

走近左侧托盘，将中央准星对准餐具，距离内显示“餐盘 1”“餐盘 2”或“马克杯”。默认查询距离为相机起点 1.5 米，超距或被环境、前景餐具挡住时不能选中。可玩场景隐藏原展示餐具，沥水架八个位初始为空。

水槽内新增“临时盘位”“临时杯位”圆环与名称，走近后瞄准可显示对应准星名称。临时位识别要求为空，射线先命中真实盆底；占用、超距或有遮挡时清除目标。当前可以识别位置，实际拿起和放置仍在后续。

空手或单独持泵瓶时，按住右键临时放大观察，默认 FOV 从 53.7° 收窄至 35°，松开恢复按下前的值。放大不移动玩家或相机，仍可转动镜头；持餐具时右键继续用于旋转，不同时放大。真实拿取和持瓶尚未实现，相关上下文由验证脚本设置。

启动时捕获鼠标，Esc 或失焦时显示菜单、释放鼠标并停止移动与观察，同时取消临时放大；点击“继续游戏”后需重新按移动键或右键。恢复捕获会丢弃首个位移，避免镜头突跳。此界面只阻止输入，不暂停场景树。

第 3、4 步的 OrderState 与 DishState 清洁度规则尚未绑定此场景。第 9 步已接入完整布局、独立槽位占用和临时位识别，实际拿起由第 10 步实现，尚未开始。后续 F 拉近餐具及滚轮调整餐具距离，与右键 FOV 放大分别实现。

原 [kitchen-demo.tscn](../../../Scenes/kitchen-demo.tscn)继续作为独立展示器：在编辑器打开它，按 F6 运行，使用 1～4、R、右键拖动和失焦释放操作。

## 实现与文件边界

可玩入口继承现有展示场景以复用 GLB、定位和灯光。根节点清除浏览脚本、隐藏 ViewerOverlay 并停用原相机，组装 GameInput、GameHUD、Player、WalkCollision、PlayableDishes、SurfaceCollision、KitchenSlots 和 DishTargeting；实际相机为 Player/ViewCamera。原展示场景与浏览脚本保持原样。

| 文件 | 所有权与覆盖范围 |
| --- | --- |
| [Scenes/kitchen-game.tscn](../../../Scenes/kitchen-game.tscn) | 手工维护的可玩入口，组装输入、HUD、玩家、碰撞、两盘一杯、槽位及目标查询；隐藏原展示餐具，以初始槽位 ID 交由注册器摆放，不由生成器写入。 |
| [Scenes/player.tscn](../../../Scenes/player.tscn) | 玩家胶囊及眼高 1.62 m 的相机，挂载 PlayerController。 |
| [Scenes/kitchen-walk-collision.tscn](../../../Scenes/kitchen-walk-collision.tscn) | 仅用于玩家行走的地面、整柜、后墙和边界阻挡，使用物理层 5。 |
| [Scripts/Player/player_controller.gd](../../../Scripts/Player/player_controller.gd) | 行走与重力碰撞、鼠标水平转向和俯仰、捕获恢复，以及临时放大的 FOV 缓存和复原。 |
| [Tools/verify_player_movement.gd](../../../Tools/verify_player_movement.gd) | 在真实场景中验证行走、出生点、相机、模式限制、碰撞与通路。 |
| [Tools/verify_mouse_look.gd](../../../Tools/verify_mouse_look.gd) | 验证直接观察、边走边转、模式和失焦恢复、按住放大及复原，并回归旧展示器操作。 |
| [Scenes/game-hud.tscn](../../../Scenes/game-hud.tscn) | 手工维护的中央准星、目标名称与菜单界面；准星和名称忽略鼠标事件，菜单按钮优先消费点击。 |
| [Scripts/Input/game_input.gd](../../../Scripts/Input/game_input.gd) | 只处理未被 UI 消费的事件，按上下文分派意图；右键在餐具旋转与观察放大之间选择，统一管理按住、取消和鼠标模式。 |
| [Scripts/UI/game_hud.gd](../../../Scripts/UI/game_hud.gd) | 通过 input_path 关联 GameInput，通过 targeting_path 监听餐具及临时位目标，共用准星名称并处理中断清除。 |
| [Scenes/Dishes/plate.tscn](../../../Scenes/Dishes/plate.tscn)、[mug.tscn](../../../Scenes/Dishes/mug.tscn) | 复用正式 GLB 的独立餐具封装，使用 DishBody 保存每件身份、类型和名称。 |
| [Scripts/Dishes/dish_body.gd](../../../Scripts/Dishes/dish_body.gd) | 保存独立身份、初始槽位 ID、类型和名称，生成表面碰撞；尚未绑定订单与清洁状态。 |
| [Scripts/Interaction/mesh_surface_collision.gd](../../../Scripts/Interaction/mesh_surface_collision.gd) | 根据可见网格生成真实三角面，保留相对变换与开口，并处理细面短射线精度。 |
| [Scripts/Interaction/kitchen_surface_collision.gd](../../../Scripts/Interaction/kitchen_surface_collision.gd) | 为可见环境与工具生成表面遮挡；隐藏的原展示餐具和未纳入扫描的临时标记不生成碰撞。 |
| [Scripts/Interaction/dish_targeting.gd](../../../Scripts/Interaction/dish_targeting.gd) | 按距离查询第一处真实表面，优先识别餐具，否则筛选真实盆底附近的空临时位，统一更新输入上下文。 |
| [Tools/verify_dish_targeting.gd](../../../Tools/verify_dish_targeting.gd) | 真实场景中的盘杯身份、表面、开口、距离、遮挡、HUD 中断及展示器隔离验证。 |
| [Scenes/kitchen-slots.tscn](../../../Scenes/kitchen-slots.tscn) | 手工维护的注册器入口、两个完整临时姿态及表面瞄准点、圆环和名称。 |
| [Resources/Kitchen/kitchen-layout.tres](../../../Resources/Kitchen/kitchen-layout.tres) | 正式 13 位布局，记录名称、类型兼容与定位来源；占用另存于场景状态。 |
| [Scripts/Slots/kitchen_slot.gd](../../../Scripts/Slots/kitchen_slot.gd) | 关联配置、独立 SlotState 和定位节点，读取完整姿态、兼容与空位。 |
| [Scripts/Slots/kitchen_slot_registry.gd](../../../Scripts/Slots/kitchen_slot_registry.gd) | 解析布局、初始化托盘占用与姿态，并筛选真实盆底命中的空临时位。 |
| [Tools/verify_kitchen_slots.gd](../../../Tools/verify_kitchen_slots.gd) | 13 位完整姿态、占用隔离、网格穿插与承托、临时位及施液瞄准的专项验证。 |
| [Tools/verify_game_input.gd](../../../Tools/verify_game_input.gd) | 独立 SubViewport 中注入键鼠事件，验证映射、分派、准星布局及 GUI 消费。 |
| [project.godot](../../../project.godot) | 默认启动可玩场景，保存 16 个 game_ 输入映射；现有组装脚本不改写此配置。 |
| [Scenes/kitchen-demo.tscn](../../../Scenes/kitchen-demo.tscn) | Godot 组装脚本覆盖的展示场景，也是新入口的布局来源。 |
| [Scripts/kitchen_viewer.gd](../../../Scripts/kitchen_viewer.gd) | 仅独立展示器启用；可玩入口不运行它，鼠标捕获及游戏键位由独立 GameInput 管理。 |

继承只复用场景布局，不共享运行节点。可玩入口隐藏全部原展示餐具，注册器将两盘一杯放入三个托盘定位节点，沥水及临时位为空；F6 仍显示原布置。当前三件是固定初始化，正式订单生成仍在后续处理。

槽位共 13 个：托盘 2 盘 1 杯、沥水架 6 盘 2 杯、水槽临时 1 盘 1 杯。托盘与架位直接使用模型节点完整姿态；临时位从现有水槽表面参考校准，正式盘杯最低处留约 0.5 mm 承托间隙，不额外叠加半高。注册器使用独立 SlotState 记录占用，initial_slot_id 仅用于初始化，不能当作餐具移动后的当前位置。

交互餐具使用层 1（位值 1），环境表面使用层 3（位值 4），查询掩码为 5；玩家层 2 和步行代理层 5 被排除。真实三角面保留杯内、杯柄孔、架槽、托盘和水槽内腔。碰撞内部顶点放大 100 倍并对形状等比缩小至 0.01，保证米制世界尺寸不变，改善细小三角面的短射线命中；模型文件未改动。

现有生成器的输出清单如下，均不包含可玩入口、HUD、玩家、步行碰撞、运行脚本或项目配置：

| 工具 | 输出 |
| --- | --- |
| [build_kitchen_demo.gd](../../../Tools/build_kitchen_demo.gd) | Scenes/kitchen-demo.tscn |
| [build_kitchen_scene.py](../../../Tools/build_kitchen_scene.py) | Assets/Scenes/kitchen-demo.blend、kitchen-room-shell.glb，以及原场景的四张 Blender 预览 |
| [capture_kitchen_demo.gd](../../../Tools/capture_kitchen_demo.gd) | 原展示器的 godot-player.png 和 godot-overview.png |

继承依赖展示根节点及 ViewerOverlay 的约定：以后修改生成器的根脚本挂载位置或提示节点结构时，需同时检查新入口的移除、隐藏覆盖仍然有效。不要在被生成器覆盖的展示场景里新增玩法脚本。

## 当前入口验收（截至第 9 步）

1. **可玩入口：** 按 F5，厨房正常，原提示隐藏，有准星且捕获鼠标。直接移动鼠标即可观察，不需右键；可连续转身，俯仰不翻转，WASD 与观察同时工作。1～4、R 不切展示机位。
2. **碰撞与通路：** 持续走向柜体、后墙、左右及前边界，不穿过、不掉落；沿台面可走近托盘、水槽、沥水架和订单板。
3. **按住放大：** 当前空手状态按住右键，视野放大且仍可观察；松开恢复。按住时打开菜单或 Alt+Tab，恢复游戏后不保留放大，需重新按右键。
4. **界面与失焦：** 行走或观察时按 Esc、Alt+Tab，应停止移动与转向并释放鼠标。继续游戏后无镜头突跳或自动行走。
5. **展示器回归：** 停止运行，打开 kitchen-demo.tscn 按 F6；仍需右键拖动，1～4、R 和失焦释放正常，不采用可玩入口的直接观察或右键放大。
6. **生成边界：** 核对上表与生成器保存路径。重建前保护手工修改，不应覆盖玩法文件；房间尺寸变化后核对步行代理与出生点。
7. **盘杯识别：** F5 走近左侧托盘，分别瞄准两盘一杯，名称正确；移开准星或走远后清除，环境及架内装饰不显示任务名称。按住右键放大不增加可交互距离。
8. **目标中断：** 瞄准餐具后按 Esc 或 Alt+Tab，名称清除；继续游戏后重新查询，不保留旧目标。杯内、孔洞与柜墙遮挡由下方专项脚本覆盖；本步左键仅分派意图，餐具不会拿起。
9. **槽位与临时位：** F5 检查右侧沥水架为空，托盘仍有两盘一杯；走近水槽，两个临时圆环与名称可见。瞄准空临时位时准星名称正确，移开、走远、菜单和失焦后清除；恢复后重新查询。实际盘杯摆放与施液瞄准由槽位专项脚本构造验证，不要求此时能手动放置或泵压。

在仓库根目录用 PowerShell 导入并验证观察与输入，各项退出码应为 0，两个脚本分别输出 MOUSE_LOOK_OK、GAME_INPUT_OK，且无脚本错误：

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path . --quit
$LASTEXITCODE
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script Tools/verify_mouse_look.gd
$LASTEXITCODE
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script Tools/verify_game_input.gd
$LASTEXITCODE
```

第 8 步专项检查同样先导入，再运行以下命令；应输出 DISH_TARGETING_OK 且退出 0，无脚本错误：

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script Tools/verify_dish_targeting.gd
$LASTEXITCODE
```

它使用实际模型检查盘正反面、杯内壁与内底、外底及杯柄，验证变换后的表面、开口、范围、柜墙及前景餐具遮挡、层排除和展示器隔离；不会保存场景或进度。

第 9 步专项同样先导入，再执行以下命令；应输出 KITCHEN_SLOTS_OK、退出 0，且无脚本错误：

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script Tools/verify_kitchen_slots.gd
$LASTEXITCODE
```

它将正式盘杯同时放入全部 13 个姿态，检查边线与环境及其他餐具的相交和最低处承托；另检查独立占用、临时位距离与遮挡、菜单恢复、放置餐具的施液输入意图及 F6 隔离。它不保存场景、不实现实际放置与泵压，也不替代后续动态搬运和完整放置规则。

需要补充无头启动检查时可运行：

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --quit-after 60
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://Scenes/kitchen-demo.tscn --quit-after 60
```

无头验证不替代真实窗口的捕获、观察手感、标记外观和失焦检查。第 1～9 步及追加放大均已通过用户验收，结果来源记录在 [progress.md](../../memory-bank/progress.md)。当前预览图仍是原展示器历史交付，不代表新增玩家、HUD 或临时位标记的截图；第 10 步未开始。
