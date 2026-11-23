# 厨房可玩入口

> 实施计划第 2 步｜2026-11-23｜用户已确认验证通过

## 打开方式

打开项目根目录的 [project.godot](../../../project.godot)，等待资源导入后按 F5，运行 [kitchen-game.tscn](../../../Scenes/kitchen-game.tscn)。

此入口目前只提供后续玩法开发所需的厨房布局。第 3 步的数据层已独立验证，但尚未绑定此场景；WASD、鼠标直接看向、拿取与清洁仍待实现，均不属于第 2 步验收范围，F5 画面不变。

原 [kitchen-demo.tscn](../../../Scenes/kitchen-demo.tscn)继续作为独立展示器：在编辑器打开它，按 F6 运行，使用 1～4、R、右键拖动和失焦释放操作。

## 实现与文件边界

可玩入口继承现有展示场景以复用同一套独立 GLB、摆放、灯光和相机，不复制模型或展示控制脚本。新场景在自身根节点明确清除浏览脚本，并隐藏 ViewerOverlay；原展示场景与浏览脚本保持原样。

| 文件 | 所有权与覆盖范围 |
| --- | --- |
| [Scenes/kitchen-game.tscn](../../../Scenes/kitchen-game.tscn) | 手工维护的可玩入口；后续玩法节点和脚本在这里接入，不由现有生成器写入。 |
| [project.godot](../../../project.godot) | 项目入口配置，默认启动可玩场景；现有组装脚本不改写此配置。 |
| [Scenes/kitchen-demo.tscn](../../../Scenes/kitchen-demo.tscn) | Godot 组装脚本覆盖的展示场景，也是新入口的布局来源。 |
| [Scripts/kitchen_viewer.gd](../../../Scripts/kitchen_viewer.gd) | 仅独立展示器启用；可玩入口不运行它，不消费展示键位或捕获鼠标。 |

继承只复用场景布局，不共享同一组运行节点。分别运行两个场景会各自实例化；现有 5 盘、2 杯仍是展示布置，待订单初始化步骤再处理，不提前建立任务状态。

现有生成器的输出清单如下，均不包含可玩入口或项目配置：

| 工具 | 输出 |
| --- | --- |
| [build_kitchen_demo.gd](../../../Tools/build_kitchen_demo.gd) | Scenes/kitchen-demo.tscn |
| [build_kitchen_scene.py](../../../Tools/build_kitchen_scene.py) | Assets/Scenes/kitchen-demo.blend、kitchen-room-shell.glb，以及原场景的四张 Blender 预览 |
| [capture_kitchen_demo.gd](../../../Tools/capture_kitchen_demo.gd) | 原展示器的 godot-player.png 和 godot-overview.png |

继承依赖展示根节点及 ViewerOverlay 的约定：以后修改生成器的根脚本挂载位置或提示节点结构时，需同时检查新入口的移除、隐藏覆盖仍然有效。不要在被生成器覆盖的展示场景里新增玩法脚本。

## 用户验收

1. **可玩入口：** 按 F5 启动，厨房模型、材质、灯光和默认构图正常，无资源或脚本错误；左上角不出现原展示器提示。按 1～4、R 或右键拖动不改变镜头，也不捕获鼠标。
2. **展示器回归：** 停止运行，打开 kitchen-demo.tscn 按 F6；原提示出现，1～4、R、右键拖动及失焦释放继续正常。
3. **生成边界：** 核对上表与对应生成器保存路径。若实际重建展示场景，重建前后 kitchen-game.tscn 和 project.godot 内容应一致；两个场景仍可按上述方式分别运行。

需要检查导入与无头启动时，在仓库根目录依次执行：

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path . --quit
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --quit-after 60
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://Scenes/kitchen-demo.tscn --quit-after 60
```

无头启动不替代上面的图形和键位检查。用户已于 2026-11-23 确认第 2 步验证通过，结果来源与静态检查范围记录在 [progress.md](../../memory-bank/progress.md)。当前预览图仍为原展示器历史交付；第 3 步数据层也已独立验证，第 4 步尚未开始。
