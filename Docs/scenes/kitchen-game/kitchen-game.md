# 厨房可玩入口

> 入口隔离、行走与第 7 步鼠标观察及右键放大｜2026-11-24｜用户已确认验证通过

## 打开方式

打开项目根目录的 [project.godot](../../../project.godot)，等待资源导入后按 F5，运行 [kitchen-game.tscn](../../../Scenes/kitchen-game.tscn)。

此入口复用厨房布局，已接入输入分派、准星、Esc 界面、WASD 行走碰撞及鼠标直接看向。玩家从水槽前方安全出生，水平可连续转身，俯仰限制为 ±80°；地面、柜体、后墙与边界阻止穿行或走出场地。

空手或单独持泵瓶时，按住右键临时放大观察，默认 FOV 从 53.7° 收窄至 35°，松开恢复按下前的值。放大不移动玩家或相机，仍可转动镜头；持餐具时右键继续用于旋转，不同时放大。真实拿取和持瓶尚未实现，相关上下文由验证脚本设置。

启动时捕获鼠标，Esc 或失焦时显示菜单、释放鼠标并停止移动与观察，同时取消临时放大；点击“继续游戏”后需重新按移动键或右键。恢复捕获会丢弃首个位移，避免镜头突跳。此界面只阻止输入，不暂停场景树。

第 3、4 步的订单状态与清洁度规则尚未绑定此场景。目标射线、拿取与清洗仍待后续实现；第 8 步尚未开始。后续 F 拉近餐具及滚轮调整餐具距离，与本步右键 FOV 放大分别实现。

原 [kitchen-demo.tscn](../../../Scenes/kitchen-demo.tscn)继续作为独立展示器：在编辑器打开它，按 F6 运行，使用 1～4、R、右键拖动和失焦释放操作。

## 实现与文件边界

可玩入口继承现有展示场景以复用独立 GLB、摆放和灯光，不复制模型或浏览脚本。根节点清除浏览脚本、隐藏 ViewerOverlay 并停用原相机，另加入 GameInput、GameHUD、Player 和 WalkCollision；实际相机为 Player/ViewCamera。原展示场景与浏览脚本保持原样。

| 文件 | 所有权与覆盖范围 |
| --- | --- |
| [Scenes/kitchen-game.tscn](../../../Scenes/kitchen-game.tscn) | 手工维护的可玩入口，组装输入、HUD、玩家与碰撞，并设置安全出生位置，不由生成器写入。 |
| [Scenes/player.tscn](../../../Scenes/player.tscn) | 玩家胶囊及眼高 1.62 m 的相机，挂载 PlayerController。 |
| [Scenes/kitchen-walk-collision.tscn](../../../Scenes/kitchen-walk-collision.tscn) | 仅用于玩家行走的地面、整柜、后墙和边界阻挡，使用物理层 5。 |
| [Scripts/Player/player_controller.gd](../../../Scripts/Player/player_controller.gd) | 行走与重力碰撞、鼠标水平转向和俯仰、捕获恢复，以及临时放大的 FOV 缓存和复原。 |
| [Tools/verify_player_movement.gd](../../../Tools/verify_player_movement.gd) | 在真实场景中验证行走、出生点、相机、模式限制、碰撞与通路。 |
| [Tools/verify_mouse_look.gd](../../../Tools/verify_mouse_look.gd) | 验证直接观察、边走边转、模式和失焦恢复、按住放大及复原，并回归旧展示器操作。 |
| [Scenes/game-hud.tscn](../../../Scenes/game-hud.tscn) | 手工维护的中央准星与菜单界面；准星忽略鼠标事件，菜单按钮优先消费点击。 |
| [Scripts/Input/game_input.gd](../../../Scripts/Input/game_input.gd) | 只处理未被 UI 消费的事件，按上下文分派意图；右键在餐具旋转与观察放大之间选择，统一管理按住、取消和鼠标模式。 |
| [Scripts/UI/game_hud.gd](../../../Scripts/UI/game_hud.gd) | 通过 input_path 关联同级 GameInput，响应模式变化，并连接继续按钮。 |
| [Tools/verify_game_input.gd](../../../Tools/verify_game_input.gd) | 独立 SubViewport 中注入键鼠事件，验证映射、分派、准星布局及 GUI 消费。 |
| [project.godot](../../../project.godot) | 默认启动可玩场景，保存 16 个 game_ 输入映射；现有组装脚本不改写此配置。 |
| [Scenes/kitchen-demo.tscn](../../../Scenes/kitchen-demo.tscn) | Godot 组装脚本覆盖的展示场景，也是新入口的布局来源。 |
| [Scripts/kitchen_viewer.gd](../../../Scripts/kitchen_viewer.gd) | 仅独立展示器启用；可玩入口不运行它，鼠标捕获及游戏键位由独立 GameInput 管理。 |

继承只复用场景布局，不共享同一组运行节点。分别运行两个场景会各自实例化；现有 5 盘、2 杯仍是展示布置，待订单初始化步骤再处理，不提前建立任务状态。

现有生成器的输出清单如下，均不包含可玩入口、HUD、玩家、步行碰撞、运行脚本或项目配置：

| 工具 | 输出 |
| --- | --- |
| [build_kitchen_demo.gd](../../../Tools/build_kitchen_demo.gd) | Scenes/kitchen-demo.tscn |
| [build_kitchen_scene.py](../../../Tools/build_kitchen_scene.py) | Assets/Scenes/kitchen-demo.blend、kitchen-room-shell.glb，以及原场景的四张 Blender 预览 |
| [capture_kitchen_demo.gd](../../../Tools/capture_kitchen_demo.gd) | 原展示器的 godot-player.png 和 godot-overview.png |

继承依赖展示根节点及 ViewerOverlay 的约定：以后修改生成器的根脚本挂载位置或提示节点结构时，需同时检查新入口的移除、隐藏覆盖仍然有效。不要在被生成器覆盖的展示场景里新增玩法脚本。

## 当前入口验收（第 7 步及追加放大）

1. **可玩入口：** 按 F5，厨房正常，原提示隐藏，有准星且捕获鼠标。直接移动鼠标即可观察，不需右键；可连续转身，俯仰不翻转，WASD 与观察同时工作。1～4、R 不切展示机位。
2. **碰撞与通路：** 持续走向柜体、后墙、左右及前边界，不穿过、不掉落；沿台面可走近托盘、水槽、沥水架和订单板。
3. **按住放大：** 当前空手状态按住右键，视野放大且仍可观察；松开恢复。按住时打开菜单或 Alt+Tab，恢复游戏后不保留放大，需重新按右键。
4. **界面与失焦：** 行走或观察时按 Esc、Alt+Tab，应停止移动与转向并释放鼠标。继续游戏后无镜头突跳或自动行走。
5. **展示器回归：** 停止运行，打开 kitchen-demo.tscn 按 F6；仍需右键拖动，1～4、R 和失焦释放正常，不采用可玩入口的直接观察或右键放大。
6. **生成边界：** 核对上表与生成器保存路径。重建前保护手工修改，不应覆盖玩法文件；房间尺寸变化后核对步行代理与出生点。

在仓库根目录用 PowerShell 导入并验证观察与输入，各项退出码应为 0，两个脚本分别输出 MOUSE_LOOK_OK、GAME_INPUT_OK，且无脚本错误：

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path . --quit
$LASTEXITCODE
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script Tools/verify_mouse_look.gd
$LASTEXITCODE
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script Tools/verify_game_input.gd
$LASTEXITCODE
```

需要补充无头启动检查时可运行：

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --quit-after 60
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://Scenes/kitchen-demo.tscn --quit-after 60
```

无头验证不替代真实窗口的捕获、观察手感、放大和失焦检查。第 1～7 步及追加放大均已通过用户验收，结果来源记录在 [progress.md](../../memory-bank/progress.md)。当前预览图仍是原展示器历史交付，不代表新增玩家、HUD 和放大的截图；第 8 步尚未开始。
