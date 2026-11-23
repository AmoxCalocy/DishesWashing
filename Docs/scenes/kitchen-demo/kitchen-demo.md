# 简单厨房场景

2026-11-20 将已有模型组装为可编辑的 Blender 场景与可运行的 Godot 展示场景。布局保持左侧待洗、中央水槽、右侧沥水，订单夹板挂在右侧墙面；加入基础环境光、主光和补光，便于检查比例、材质与摆放。

## 打开与查看

在 Godot 4.7.2 项目管理器中导入项目根目录的 [project.godot](../../../project.godot)，等待 GLB 导入完成后打开项目，按 **F5** 运行。主场景已设置为 [kitchen-demo.tscn](../../../Scenes/kitchen-demo.tscn)，也可在编辑器中打开它并按 F6 查看当前场景。初次运行使用 Compatibility 渲染器。

| 操作 | 效果 |
| --- | --- |
| 按住鼠标右键并拖动 | 从当前机位环顾，松开后恢复鼠标指针 |
| `1` | 默认操作区视角 |
| `2` | 厨房全貌视角 |
| `3` | 转向左侧待洗区 |
| `4` | 转向右侧沥水区 |
| `R` | 恢复默认操作区视角 |
| `Esc` | 结束鼠标捕获，恢复鼠标指针 |

这是场景浏览操作。没有移动角色、拿取餐具或清洗的输入；全貌视角用于检查布局，不是新增的玩家移动能力。默认、待洗区和沥水区视角共用固定站位，眼高为 1.62 m。

在 Blender 中直接打开 [kitchen-demo.blend](../../../Assets/Scenes/kitchen-demo.blend) 可查看和调整整个场景。保存时默认使用玩家相机，文件内还保留全貌、左侧和右侧相机。

## 文件与预览

| 文件 | 用途 |
| --- | --- |
| [project.godot](../../../project.godot) | Godot 项目入口、默认场景与渲染设置 |
| [kitchen-demo.tscn](../../../Scenes/kitchen-demo.tscn) | 外部 GLB 实例、摆放、灯光、相机和查看提示 |
| [kitchen_viewer.gd](../../../Scripts/kitchen_viewer.gd) | 环顾和预设视角切换 |
| [kitchen-demo.blend](../../../Assets/Scenes/kitchen-demo.blend) | 已组装的 Blender 编辑场景，贴图打包在文件内 |
| [kitchen-room-shell.glb](../../../Assets/Scenes/kitchen-room-shell.glb) | 从灰盒整理出的柜体、墙窗、地面及临时海绵托架，共 27 个网格 |
| [build_kitchen_scene.py](../../../Tools/build_kitchen_scene.py) | 组装 Blender 场景、导出房间壳与渲染预览 |
| [build_kitchen_demo.gd](../../../Tools/build_kitchen_demo.gd) | 从现有 GLB 重建 Godot 主场景 |
| [capture_kitchen_demo.gd](../../../Tools/capture_kitchen_demo.gd) | 在图形模式下输出 Godot 实际运行截图 |
| [Godot 玩家视角](godot-player.png) | 实际运行画面，包含场景查看提示 |
| [Godot 厨房全貌](godot-overview.png) | 实际运行的全貌视角 |
| [默认玩家视角](kitchen-demo-player.png) | 操作区构图 |
| [厨房全貌](kitchen-demo-overview.png) | 厨房主体与左右分区 |
| [待洗区](kitchen-demo-left.png) | 托盘、餐盘和直立杯 |
| [沥水区](kitchen-demo-right.png) | 竖放餐盘、倒扣杯和空槽 |

`godot-` 开头的两张 PNG 是 Godot 实际运行截图；`kitchen-demo-` 开头的四张 PNG 由 Blender 渲染。两者使用各自的灯光与渲染设置。

## 组装内容

Godot 场景的 `Models` 下放置房间壳、水槽与台面、水龙头、洗洁精瓶、海绵、沥水架、待洗托盘和订单夹板；`Dishes` 下共有 **5 个餐盘和 2 个马克杯**。场景通过外部 GLB 实例复用既有模型，餐具实例共享原有资源。

| 区域 | 当前摆放 |
| --- | --- |
| 左侧托盘 | `Dirty_Plate_01`、`Dirty_Plate_02` 各放一盘，`Dirty_Mug_01` 放一个直立杯 |
| 中央操作区 | 水槽、开孔台面、归位喷头、关闭把手、未按压泵瓶和收纳状态海绵 |
| 右侧沥水架 | `Rack_Slot_01`、`03`、`05` 各放一盘，`Rack_Cup_Slot_01` 放一个倒扣杯；其余槽位留空 |
| 右墙 | 已有订单夹板，显示静态“两盘一杯”示例订单 |

餐具使用对应槽位的完整位置和旋转，保持已有资产的承托高度。托盘上的餐具目前仍为素色材质，“待洗区”表示布置用途，尚未添加污渍效果。

安装位置沿用各资产交付说明。以下为 **Godot 世界坐标**，单位为米：

| 实例 | 位置 |
| --- | --- |
| `RoomShell` | `(0, 0, 0)` |
| `SinkCountertop` | `(0, 0.90, 0)` |
| `Faucet` | `(0.16, 0.90, -0.32)` |
| `SoapDispenser` | `(0.535, 0.90, -0.26)` |
| `Sponge` | `(-0.30, 0.9285, -0.17)` |
| `DishRack` | `(0.88, 0.90, -0.035)` |
| `DirtyTray` | `(-0.89, 0.90, 0.025)` |
| `OrderClipboard` | `(1.2205, 1.24, -0.398)` |

Blender 与 Godot 的坐标映射为 `(x, y, z)` → `(x, z, -y)`。Blender 总场景通过追加既有 `.blend` 集合组装，修改原资产后需要重新运行组装脚本才能更新总场景；Godot 则引用各独立 GLB，模型重新导出后可由编辑器重新导入。若槽位布局变化，应同时重建 Godot 场景中的餐具摆放。

## 当前范围

本次完成模型组装和场景浏览。柜体、门板、墙窗、地面和海绵托架沿用灰盒轮廓，并调整基础颜色；墙面与地面适当延展，用于左右查看时保持背景连续。它们还不是资产计划中 P2 厨房主体的正式模型。

水槽、餐具、工具和订单板使用已有正式资产；已移除总场景中对应的旧占位道具。原操作区灰盒及各独立资产源文件保留，新的总场景另存于 `Assets/Scenes/`。

拿取与两种持有状态、擦洗与污渍、水流与泡沫、泵瓶和喷头交互、订单进度、碰撞与餐具入架逻辑仍待实现。已有模型中的定位节点和动画资源保留，但本场景浏览脚本不会触发这些玩法。

## 验证

- Blender 组装脚本确认七个餐具实例与对应摆放节点的完整变换一致，并排除已替代的占位道具；四个视角预览已生成。
- Godot 4.7.2 成功导入并实例化场景，确认 15 个外部 GLB 实例、88 个网格；主场景启动检查正常退出，没有脚本错误。
- Godot 核对七件餐具的摆放变换及最低高度：托盘中的三件餐具为世界 `y=0.9125 m`，架内三盘为 `0.9365 m`，倒扣杯为 `0.928 m`，与既有槽位和承托余量一致。
- 通过脚本事件验证四个视角快捷键、`R` 复位、右键环顾角度限制和失焦释放。左右环顾限制为 ±60°，俯仰范围为 −60°～20°。
- 使用图形模式生成 Godot 玩家视角与全貌截图，以实际渲染检查模型、灯光和查看提示。

这些检查针对静态组装与场景浏览，没有测定目标机器帧率，也没有验证动态清洗或物理放置。

## 重建

在项目根目录按以下顺序运行。重建会覆盖本次生成的总场景、房间壳及预览；若已手工调整总场景，先另存副本。

1. 使用既有 Blender 源模型组装场景并生成房间壳、四张预览：

   ```powershell
   & 'D:\Blender\blender.exe' --background --factory-startup --python-exit-code 1 --python 'Tools/build_kitchen_scene.py'
   ```

2. 让 Godot 导入资源，再重建主场景：

   ```powershell
   & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path . --quit
   & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script 'Tools/build_kitchen_demo.gd'
   ```

项目关闭了 Godot 对 `.blend` 的自动导入；运行时使用显式导出的 GLB。中文查看提示优先使用本机微软雅黑，也配置了 CJK 字体回退；项目没有复制系统字体文件。

如需重新生成 Godot 实际运行截图，在支持图形显示的环境中执行以下命令。此步骤不能加 `--headless`；完成两张截图后程序自动退出。

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script 'Tools/capture_kitchen_demo.gd'
```
