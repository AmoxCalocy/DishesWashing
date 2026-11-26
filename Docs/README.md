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

第 7 步及追加右键放大已通过用户验收。[鼠标观察验证脚本](../Tools/verify_mouse_look.gd)检查直接看向、水平转身、俯仰、边走边转、恢复捕获和旧展示器回归，并覆盖右键按住放大、松开及中断后复原。F5 中空手或持泵瓶时右键临时放大，持餐具时不触发 FOV 放大；沉浸中的旋转已接入，普通搬运旋转留待第 16 步。持瓶仍由脚本构造上下文。

## 盘杯与目标识别验证

第 8 步已通过用户验收。[盘杯验证脚本](../Tools/verify_dish_targeting.gd)检查独立身份、真实表面与法线、杯内和孔洞、架槽、托盘及水槽内腔、距离、遮挡和展示器隔离。F5 走近左侧托盘，准星分别显示“餐盘 1”“餐盘 2”“马克杯”；默认范围为 1.5 米，超距、遮挡、菜单和失焦后清除目标。文件职责与碰撞分层见 [架构说明](memory-bank/architecture.md)，命令与验收来源见 [进度记录](memory-bank/progress.md)。

## 托盘初始点与架位验证

第 9 步建立注册器，第 12 步按用户修正移除两个固定水槽位及标记。[正式布局](../Resources/Kitchen/kitchen-layout.tres)现为 3 个托盘初始点和 8 个架位，固定放置目标只保留沥水架。[槽位专项](../Tools/verify_kitchen_slots.gd)检查 11 项完整姿态、独立占用、实际承托与网格穿插、无水槽固定标记、施液意图及展示器隔离。水槽预览自由跟随真实命中，F6 原展示布置保持不变；实际放置已于第 13 步接入，泵压仍待后续。

## 双持与沉浸操作验证

第 10 步及追加需求已通过用户验收。[搬运专项](../Tools/verify_dish_carry.gd)检查当前来源占用、原实例、安全位置、近裁剪和障碍；[双持专项](../Tools/verify_dual_wield.gd)检查左右手顺序、餐具加工具、F、中键与 Q/E、两工具自由移动及 E 归回。沉浸工具不自动吸附，按 F 才回固定手位；背景模糊仍待第 17 步，实际放置已在第 13 步接入，供水、去污和软管避障仍待后续。现行操作、图形预览和命令见 [可玩入口说明](scenes/kitchen-game/kitchen-game.md)。

## 普通模式工具操作验证

2026-11-26 追加需求已通过用户验收。[普通工具专项](../Tools/verify_world_tool_use.gd)检查两工具和左右手、已放置盘杯接触、占用不变、持续瞄准、行走／观察、遮挡、距离、菜单／失焦和 F 共存。持工具后按住左键操作，松开回原手位；E 对准餐具且有空手时拿取，其他持工具情形尝试归回。沉浸拖动旋转已改为中键，右键不再旋转；新增映射及按钮隔离由输入与双持专项覆盖。当前仍是动作与接触反馈，真实清洗条件留待后续。

## 统一放置判定与手位选择验证

第 1～13 步及水槽堆放等追加需求已验收，下一项是第 14 步 Q 安全返回。[统一放置专项](../Tools/verify_placement_rules.gd)验证现有 11 个注册姿态、实际 95% 门槛、泡沫独立、注册／类型／尺寸、占用、距离／可见性、真实空间和只读结果，输出 PLACEMENT_RULES_OK。普通搬运按 1／2 选择左右餐具，HUD 标注“当前”，空手或工具不可选；缺少清洁状态不授权入架。

## 水槽自由落点与架位预览验证

第 12 步已通过用户验收。[预览专项](../Tools/verify_placement_preview.gd)输出 PLACEMENT_PREVIEW_OK，覆盖盘杯多个连续水槽落点、底部支撑、真实空间、8 个固定架位、当前手位、无碰撞／拾取／占用、遮挡、超距、菜单／失焦、工具排除及 F 恢复。F5 拿起餐具后瞄准水槽内部，预览随准星移动并显示绿／红原因；沥水架保留完整固定姿态。实际左键放置、自由位置记录及水槽交叠堆放已在第 13 步验收，Q 返回在第 14 步，具体命令和画面见[可玩入口说明](scenes/kitchen-game/kitchen-game.md)。

## 实际放置与水槽堆放验证

第 13 步及水槽重叠堆放追加需求已通过用户验收。[确认专项](../Tools/verify_dish_placement.gd)输出 DISH_PLACEMENT_OK，覆盖最新目标与手位、实际提交、8 架位、原实例、再次拿取、另一手、状态同步、失效预览及重复请求；[堆放专项](../Tools/verify_basin_stacking.gd)输出 BASIN_STACKING_OK，覆盖两盘一杯交叠、真实支撑／空间、上到下拿取和工具优先级。只有沥水架提供固定位置；水槽自由位置与支撑身份由原餐具记录，不创建槽位。生产清洁状态引用仍为空，架位未知状态继续拒绝。运行命令、[叠放画面](scenes/kitchen-game/step13-stack-placed.png)和已知清洁状态夹具说明见[可玩入口](scenes/kitchen-game/kitchen-game.md)；下一项为第 14 步 Q 安全返回。

## 已组装场景

| 场景 | 说明与打开方式 | 预览 |
| --- | --- | --- |
| 简单厨房场景 | [Godot 运行、Blender 编辑与组装说明](scenes/kitchen-demo/kitchen-demo.md) | [Godot 全貌](scenes/kitchen-demo/godot-overview.png) / [Godot 玩家视角](scenes/kitchen-demo/godot-player.png) / [Blender 全貌](scenes/kitchen-demo/kitchen-demo-overview.png) |
| 厨房可玩入口 | [F5 放置、堆放、工具及沉浸验收说明](scenes/kitchen-game/kitchen-game.md) | [叠放预览](scenes/kitchen-game/step13-stack-preview.png) / [实际堆放](scenes/kitchen-game/step13-stack-placed.png) / [下层提示](scenes/kitchen-game/step13-stack-lower-pickup.png) / [上层拿取](scenes/kitchen-game/step13-stack-top-pickup.png) |

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
