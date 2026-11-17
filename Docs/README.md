# 《洗碗时光》文档导航

核心设计文档保留在本目录；各模型的交付说明与预览图放在 `assets/` 对应文件夹中；场景参考图放在 `references/`。

## 核心文档

| 文档 | 内容 |
| --- | --- |
| [游戏设计文档](game-design-document.md) | 游戏目标、洗碗流程、悬空操作与两种拿起状态 |
| [技术栈](tech-stack.md) | 技术方案与制作流程 |
| [厨房资产计划](kitchen-asset-plan.md) | 建模优先级、交付进度与操作区灰盒说明 |

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
├── game-design-document.md
├── tech-stack.md
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
└── references/
```

新增模型时，在 `assets/<资产名>/` 中保存同名说明文档与预览图，并将其加入本页及资产计划。建模脚本的预览输出路径应指向相同文件夹。这里只归档说明和预览，模型源文件、导出文件及贴图继续保存在项目的 `Assets/` 中。

重新生成预览时，请运行各交付说明中的建模脚本。现有 `.blend` 保存的历史渲染路径会在下次重建时更新；直接用这些文件输出渲染结果时，请将保存位置设为当前资产文件夹。
