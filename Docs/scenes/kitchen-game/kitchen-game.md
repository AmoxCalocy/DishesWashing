# 厨房可玩入口

> 入口隔离、输入界面与第 6 步行走碰撞｜2026-11-24｜用户已确认验证通过

## 打开方式

打开项目根目录的 [project.godot](../../../project.godot)，等待资源导入后按 F5，运行 [kitchen-game.tscn](../../../Scenes/kitchen-game.tscn)。

此入口复用厨房布局，已接入输入分派、中央准星、Esc 基础界面及第 6 步的 WASD 行走与玩家碰撞。玩家从水槽前方安全出生，相机随玩家平移；地面、柜体、后墙与边界阻止穿行或走出场地。

启动时捕获鼠标，Esc 显示菜单并释放鼠标、停止水平移动，点击“继续游戏”后需重新按下移动键；失焦时同样进入界面模式，清除旧按住状态。此界面只阻止输入，不暂停场景树。

第 3、4 步的订单状态与清洁度规则尚未绑定此场景。鼠标转向、目标射线、拿取与清洗仍待后续实现；第 7 步尚未开始。

原 [kitchen-demo.tscn](../../../Scenes/kitchen-demo.tscn)继续作为独立展示器：在编辑器打开它，按 F6 运行，使用 1～4、R、右键拖动和失焦释放操作。

## 实现与文件边界

可玩入口继承现有展示场景以复用独立 GLB、摆放和灯光，不复制模型或浏览脚本。根节点清除浏览脚本、隐藏 ViewerOverlay 并停用原相机，另加入 GameInput、GameHUD、Player 和 WalkCollision；实际相机为 Player/ViewCamera。原展示场景与浏览脚本保持原样。

| 文件 | 所有权与覆盖范围 |
| --- | --- |
| [Scenes/kitchen-game.tscn](../../../Scenes/kitchen-game.tscn) | 手工维护的可玩入口，组装输入、HUD、玩家与碰撞，并设置安全出生位置，不由生成器写入。 |
| [Scenes/player.tscn](../../../Scenes/player.tscn) | 玩家胶囊及眼高 1.62 m 的相机，挂载 PlayerController。 |
| [Scenes/kitchen-walk-collision.tscn](../../../Scenes/kitchen-walk-collision.tscn) | 仅用于玩家行走的地面、整柜、后墙和边界阻挡，使用物理层 5。 |
| [Scripts/Player/player_controller.gd](../../../Scripts/Player/player_controller.gd) | 在物理回调中读取过滤后的移动输入，按相机水平朝向行走并处理重力和碰撞。 |
| [Tools/verify_player_movement.gd](../../../Tools/verify_player_movement.gd) | 在真实场景中验证行走、出生点、相机、模式限制、碰撞与通路。 |
| [Scenes/game-hud.tscn](../../../Scenes/game-hud.tscn) | 手工维护的中央准星与菜单界面；准星忽略鼠标事件，菜单按钮优先消费点击。 |
| [Scripts/Input/game_input.gd](../../../Scripts/Input/game_input.gd) | 只处理未被 UI 消费的事件，按模式、目标及工具选择分派意图，管理按住状态和鼠标模式。 |
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

## 当前入口验收（第 6 步）

1. **可玩入口：** 按 F5 启动，厨房正常，原展示器提示隐藏，中央有准星且鼠标被捕获。WASD 正确行走，斜向不加速；鼠标尚不转动镜头，1～4、R 及右键拖动不切换展示视角。
2. **碰撞与通路：** 持续走向柜体、后墙、左右及前边界，不穿过、不掉落；沿台面可走近托盘、水槽、沥水架和订单板。
3. **界面与失焦：** 行走时按 Esc 或 Alt+Tab，应停止水平移动并释放鼠标。通过菜单继续后，不沿用旧按住状态，重新按键才行走。
4. **展示器回归：** 停止运行，打开 kitchen-demo.tscn 按 F6；原提示出现，1～4、R、右键拖动及失焦释放继续正常。
5. **生成边界：** 核对上表与生成器保存路径。若重建展示场景，先保护手工修改；重建不应覆盖玩法文件。房间尺寸变化后还需核对步行代理与出生点。

在仓库根目录用 PowerShell 导入并验证行走，每项退出码应为 0，约 20 秒后输出 PLAYER_MOVEMENT_OK 且无脚本错误：

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path . --quit
$LASTEXITCODE
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script Tools/verify_player_movement.gd
$LASTEXITCODE
```

需要补充无头启动检查时可运行：

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --quit-after 60
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://Scenes/kitchen-demo.tscn --quit-after 60
```

无头验证不替代真实窗口的行走、碰撞和失焦检查。第 2 步入口隔离及第 3～6 步均已通过用户验收，结果来源记录在 [progress.md](../../memory-bank/progress.md)。当前预览图仍为原展示器历史交付，不代表新增玩家和 HUD 的截图；第 7 步尚未开始。
