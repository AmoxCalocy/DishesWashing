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

第 7 步及追加右键放大已通过用户验收。[鼠标观察验证脚本](../Tools/verify_mouse_look.gd)检查直接看向、水平转身、俯仰、边走边转、恢复捕获和旧展示器回归，并覆盖右键按住放大、松开及中断后复原。F5 中空手、只持工具或测试持瓶时右键临时放大；持餐具时不旋转或放大。第 16 步已统一两态中键旋转，沉浸另保留 Q/E；持瓶仍由脚本构造上下文。

## 盘杯与目标识别验证

第 8 步已通过用户验收。[盘杯验证脚本](../Tools/verify_dish_targeting.gd)检查独立身份、真实表面与法线、杯内和孔洞、架槽、托盘及水槽内腔、距离、遮挡和展示器隔离。F5 走近左侧托盘，准星分别显示“餐盘 1”“餐盘 2”“马克杯”；当前范围为 2 米，覆盖地面餐具，超距、遮挡、菜单和失焦后清除目标。文件职责与碰撞分层见 [架构说明](memory-bank/architecture.md)，命令与验收来源见 [进度记录](memory-bank/progress.md)。

## 托盘初始点与架位验证

第 9 步建立注册器，第 12 步按用户修正移除两个固定水槽位及标记。[正式布局](../Resources/Kitchen/kitchen-layout.tres)现为 3 个托盘初始点和 8 个架位，固定放置目标只保留沥水架。[槽位专项](../Tools/verify_kitchen_slots.gd)检查 11 项完整姿态、独立占用、实际承托与网格穿插、无水槽固定标记、施液意图及展示器隔离。水槽使用 G 物理松手，已移除预览，F6 原展示布置保持不变；G 物理松手及固定架位确认已于第 14 步验收，泵压仍待后续。

## 双持与沉浸操作验证

第 10 步及追加需求已通过用户验收。[搬运专项](../Tools/verify_dish_carry.gd)检查当前来源占用、原实例、安全位置、近裁剪和障碍；[双持专项](../Tools/verify_dual_wield.gd)检查左右手顺序、餐具加工具、F、中键与 Q/E、两工具自由移动及 E 归回。沉浸工具不自动吸附，按 F 才回固定手位；背景模糊已于第 17 步验收，第 14 步已改为 G 物理松手，供水、去污和软管避障仍待后续。现行操作、图形预览和命令见 [可玩入口说明](scenes/kitchen-game/kitchen-game.md)。

第 15 步于 2026-11-27 通过用户验收。[F 切换专项](../Tools/verify_close_transition.gd)覆盖盘杯、两工具、左右手顺序与五组站位／朝向共 40 组往返，以及真实空间／路径、原实例／状态／视角保留、喷头范围、重复输入和进入／退出中断。F 返回须取得新的安全姿态，受阻保留沉浸；自由工具不再挡住另一手返回，菜单后完成进入不重置光标。专项与 7 项相关回归、导入、默认启动和图形检查通过，成功标识 CLOSE_TRANSITION_OK；第 16 步旋转与滚轮现也已通过验收。

## 餐具旋转与滚轮验证

第 16 步及普通中键修正于 2026-11-27 通过用户验收。普通与沉浸统一用中键拖动旋转，普通只操作 1／2 当前餐具；沉浸 Q/E 保留。滚轮仅沉浸调距，每格 0.02 m，盘 0.40～0.56 m、杯 0.36～0.52 m，默认 0.45 m；旋转／调距检查真实空间与近裁剪，F 往返保留所选距离／角度，调整后需重新按左键使用工具。

[旋转与调距专项](../Tools/verify_dish_manipulation.gd)覆盖 8 组盘杯／工具／手位、正反面与杯内、倾斜工具接触、障碍、中断及 30／120 Hz Q/E。实施阶段专项及 7 项回归、导入、默认启动和图形检查通过；中键修正后重跑专项、输入、镜头及图形，成功标识 DISH_MANIPULATION_OK。[中键右手旋转](scenes/kitchen-game/step16-selected-right.png)、[盘背最近距离](scenes/kitchen-game/step16-plate-near-back.png)和[杯内最近距离](scenes/kitchen-game/step16-mug-near-inside.png)保留当时画面。

## 沉浸背景模糊验证

第 17 步于 2026-11-27 通过用户验收。Compatibility 下随 F 约 0.2 秒淡入／淡出背景模糊，原餐具、工具与 HUD 清晰；相机位置、朝向、FOV 和真实交互保持原规则，退出恢复原渲染层并停止额外视口。

[模糊专项](../Tools/verify_immersion_focus.gd)及 7 项相关回归、导入、启动通过；图形模式另通过 12 组工具／站位／距离及 2 组透明材质／尺寸对照，成功标识 IMMERSION_FOCUS_OK。[清晰对照](scenes/kitchen-game/step17-focus-reference.png)、[模糊餐盘](scenes/kitchen-game/step17-focus-plate.png)、[杯内与喷头](scenes/kitchen-game/step17-focus-mug.png)和[透明边缘夹具](scenes/kitchen-game/step17-focus-alpha.png)可供比较。1080p／RTX 2080 Ti／关闭垂直同步各 30 帧初测 GPU 渲染均值约 0.587→0.984 ms，完整环境与方法见[性能记录](scenes/kitchen-game/step17-render-timing.json)和[进度记录](memory-bank/progress.md)；不是完整 MVP 性能验收。下一项为第 18 步暂停与失焦处理。

## 普通模式工具操作验证

2026-11-26 追加需求已通过用户验收。[普通工具专项](../Tools/verify_world_tool_use.gd)检查两工具和左右手、已放置盘杯接触、占用不变、持续瞄准、行走／观察、遮挡、距离、菜单／失焦和 F 共存。持工具后按住左键操作，松开回原手位；E 对准餐具且有空手时拿取，其他持工具情形尝试归回。沉浸拖动旋转已改为中键，右键不再旋转；新增映射及按钮隔离由输入与双持专项覆盖。当前仍是动作与接触反馈，真实清洗条件留待后续。

## 餐具松手、固定架位与无预览验证

第 1～17 步及追加需求已验收；第 14 步按用户修正取消普通 Q 返回和全部落位预览，改为 G 物理松手。台面、托盘、地面与水槽共用重力／碰撞，只有沥水架保留固定完整姿态；F 场景覆盖、两态中键／沉浸滚轮和背景模糊均已通过，下一项为第 18 步暂停与失焦处理。

| 检查 | 当前范围 |
| --- | --- |
| [G 松手专项](../Tools/verify_dish_drop.gd) | 盘杯下落与再次拿取、物理开口、原身份／状态、双手、重复请求、菜单／沉浸／过渡、工具及 F；DISH_DROP_OK |
| [固定架位专项](../Tools/verify_dish_placement.gd) | G 提交 8 架位、完整姿态与占用、未知／未达实际 95% 拒绝；DISH_PLACEMENT_OK |
| [物理堆放专项](../Tools/verify_basin_stacking.gd) | 两盘一杯重力、陶瓷碰撞、盆内叠放与再次拿取；BASIN_STACKING_OK |
| [原预览专项](../Tools/verify_placement_preview.gd) | 保留文件名，现验证幽灵与绿／红标签已删除、瞄准不提交／预留、展示器独立；PLACEMENT_PREVIEW_OK |
| [共用注册规则](../Tools/verify_placement_rules.gd) | 完整姿态、类型／尺寸／占用、真实空间、实际 95%／泡沫／未知状态和选中手位；PLACEMENT_RULES_OK |

当前 18 份验证脚本、48 个唯一 GDScript UID，另有 1 个着色器 UID；输入映射仍为 18 个。正式清洁状态未绑定，按 G 入架时未知状态继续拒绝。运行命令、当前[F 返回手位](scenes/kitchen-game/step17-return-carry.png)与[自然堆放画面](scenes/kitchen-game/step14-free-stack.png)、历史阶段说明见[可玩入口](scenes/kitchen-game/kitchen-game.md)；实现及来源见[进度记录](memory-bank/progress.md)。

## 已组装场景

| 场景 | 说明与打开方式 | 预览 |
| --- | --- | --- |
| 简单厨房场景 | [Godot 运行、Blender 编辑与组装说明](scenes/kitchen-demo/kitchen-demo.md) | [Godot 全貌](scenes/kitchen-demo/godot-overview.png) / [Godot 玩家视角](scenes/kitchen-demo/godot-player.png) / [Blender 全貌](scenes/kitchen-demo/kitchen-demo-overview.png) |
| 厨房可玩入口 | [F5 G 松手、中键／滚轮、背景模糊及工具验收说明](scenes/kitchen-game/kitchen-game.md) | [沉浸餐盘](scenes/kitchen-game/step17-focus-plate.png) / [沉浸杯内](scenes/kitchen-game/step17-focus-mug.png) / [透明边缘](scenes/kitchen-game/step17-focus-alpha.png) / [返回手位](scenes/kitchen-game/step17-return-carry.png) |

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
