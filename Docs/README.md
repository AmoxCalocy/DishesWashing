# 《洗碗时光》文档导航

核心设计、实施计划、进度与架构文档保存在 `memory-bank/`；各模型的交付说明与预览图放在 `assets/` 对应文件夹中；已组装场景的说明与预览放在 `scenes/`；场景参考图放在 `references/`。

## 核心文档

| 文档 | 内容 |
| --- | --- |
| [游戏设计文档](memory-bank/game-design-document.md) | 游戏目标、WASD 与鼠标视角、清洗流程和验收规则 |
| [技术栈](memory-bank/tech-stack.md) | 技术方案与制作流程 |
| [实施计划](memory-bank/implementation-plan.md) | 分步开发指令与每步验证条件 |
| [开发进度](memory-bank/progress.md) | 已完成工作、用户验收记录与当前进度 |
| [项目架构](memory-bank/architecture.md) | 当前文件职责、生成依赖与架构洞察 |
| [厨房资产计划](kitchen-asset-plan.md) | 建模优先级、交付进度与操作区灰盒说明 |

## 数据层验证

第 3、4 步已通过用户验收。[独立状态验证脚本](../Tools/verify_runtime_state.gd)检查共享配置、运行数据隔离和新建状态初始值；[清洁度验证脚本](../Tools/verify_cleanliness.gd)检查加权结果、零污渍、上下限、泡沫独立及实际 95% 门槛。

[进度记录](memory-bank/progress.md)包含运行命令与验收来源，[架构说明](memory-bank/architecture.md)列出配置、状态、清洁度接口及验证文件职责。订单状态与清洁度尚未绑定运行场景。

## 输入与界面验证

第 5 步已通过用户验收。[输入验证脚本](../Tools/verify_game_input.gd)检查键鼠映射、上下文分派、准星和 GUI 事件消费；[可玩入口说明](scenes/kitchen-game/kitchen-game.md)记录 F5 准星、Esc 菜单、鼠标捕获与失焦检查。

## 行走与碰撞验证

第 6 步已通过用户验收。[行走验证脚本](../Tools/verify_player_movement.gd)加载真实可玩场景，检查安全出生、WASD、斜向速度、相机水平朝向、物理频率、模式限制和厨房碰撞。运行命令和结果来源见 [progress.md](memory-bank/progress.md)。

## 鼠标观察与右键放大验证

第 7 步及追加右键放大已通过用户验收。[鼠标观察验证脚本](../Tools/verify_mouse_look.gd)检查直接看向、水平转身、俯仰、边走边转、恢复捕获和旧展示器回归，并覆盖右键按住放大、松开及中断后复原。F5 中空手或持泵瓶时右键临时放大，持餐具时仍旋转餐具；真实持物尚未实现，其上下文由脚本设置。第 8 步尚未开始。

## 已组装场景

| 场景 | 说明与打开方式 | 预览 |
| --- | --- | --- |
| 简单厨房场景 | [Godot 运行、Blender 编辑与组装说明](scenes/kitchen-demo/kitchen-demo.md) | [Godot 全貌](scenes/kitchen-demo/godot-overview.png) / [Godot 玩家视角](scenes/kitchen-demo/godot-player.png) / [Blender 全貌](scenes/kitchen-demo/kitchen-demo-overview.png) |
| 厨房可玩入口 | [F5 行走观察、右键放大、生成边界与验收](scenes/kitchen-game/kitchen-game.md) | 行走、镜头、碰撞与基础界面已由用户验收；历史预览见展示场景 |

## 模型说明与预览

每个资产文件夹集中保存该模型的说明和全部预览。可编辑模型与 Godot 导入文件仍位于项目根目录的 [Assets](../Assets/)，重建脚本位于 [Tools](../Tools/)。

| 资产 | 说明 | 全貌预览 |
| --- | --- | --- |
| 操作区灰盒 | [灰盒交付说明](kitchen-asset-plan.md#操作区灰盒交付) | [操作区全貌](assets/kitchen-graybox/kitchen-graybox-overview.png) |
| 标准餐盘 | [尺寸、节点与接入](assets/plate-standard/plate-standard.md) | [正反面](assets/plate-standard/plate-standard-overview.png) |
| 海绵 | [材质、擦洗面与压缩形态](assets/sponge-standard/sponge-standard.md) | [正反面](assets/sponge-standard/sponge-standard-overview.png) |
| 马克杯 | [内腔、杯柄与接入](assets/mug-standard/mug-standard.md) | [外观与内腔](assets/mug-standard/mug-standard-overview.png) |
| 水槽、排水口与台面 | [开孔、尺寸与安装点](assets/sink-countertop/sink-countertop.md) | [组合全貌](assets/sink-countertop/sink-countertop-overview.png) |
| 水龙头、抽拉喷头与把手 | [活动部件、软管形态与接入](assets/faucet-pullout/faucet-pullout.md) | [组合全貌](assets/faucet-pullout/faucet-pullout-overview.png) |
| 洗洁精泵瓶 | [按压动画、接液位置与接入](assets/soap-dispenser/soap-dispenser.md) | [泵瓶全貌](assets/soap-dispenser/soap-dispenser-overview.png) |
| 沥水架与待洗托盘 | [槽位、承托与接入](assets/rack-and-tray/rack-and-tray.md) | [沥水架满载](assets/rack-and-tray/dish-rack-loaded.png) / [托盘摆放](assets/rack-and-tray/dirty-tray-loaded.png) |
| 订单夹板与纸面 | [纸面替换、安装与接入](assets/order-clipboard/order-clipboard.md) | [夹板全貌](assets/order-clipboard/order-clipboard-overview.png) |

## 场景参考

- [厨房场景参考图](references/kitchen-scene-reference.png)
- [洗碗台环境设定](references/洗碗台环境设定.png)
- [洗碗台建模资产标注](references/洗碗台建模资产标注.png)

参考图用于风格与布局，实际制作范围和最新进度以[厨房资产计划](kitchen-asset-plan.md)为准。

## 目录约定

```text
Docs/
├── README.md
├── memory-bank/
│   ├── game-design-document.md
│   ├── tech-stack.md
│   ├── implementation-plan.md
│   ├── progress.md
│   └── architecture.md
├── kitchen-asset-plan.md
├── assets/
│   ├── kitchen-graybox/
│   ├── plate-standard/
│   ├── sponge-standard/
│   ├── mug-standard/
│   ├── sink-countertop/
│   ├── faucet-pullout/
│   ├── soap-dispenser/
│   ├── rack-and-tray/
│   └── order-clipboard/
├── scenes/
│   ├── kitchen-demo/
│   └── kitchen-game/
└── references/
```

新增模型时，在 `assets/<资产名>/` 中保存同名说明文档与预览图，并将其加入本页及资产计划。建模脚本的预览输出路径应指向相同文件夹。这里只归档说明和预览，模型源文件、导出文件及贴图继续保存在项目的 `Assets/` 中。

重新生成预览时，请运行各交付说明中的建模脚本。现有 `.blend` 保存的历史渲染路径会在下次重建时更新；直接用这些文件输出渲染结果时，请将保存位置设为当前资产文件夹。
