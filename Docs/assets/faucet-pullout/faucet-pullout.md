# 水龙头、抽拉喷头和把手

2026-11-13 开始制作，2026-11-16 使用 Blender 5.3.0 CLI 完成。沿用正式水槽的安装点，提供弯颈水龙头、可独立移动的喷头、右侧台面拨杆开关，以及归位和固定拉出两种软管展示形态。

## 交付文件

| 文件 | 用途 |
| --- | --- |
| [faucet-pullout.blend](../../../Assets/Kitchen/faucet-pullout.blend) | 可编辑的分件模型、UV、基础材质、定位点与软管形态键 |
| [faucet-pullout.glb](../../../Assets/Kitchen/faucet-pullout.glb) | Godot 导入资产，仅含本轮模型、节点和软管变形数据 |
| [build_faucet.py](../../../Tools/build_faucet.py) | 建模、几何检查、导出和预览脚本 |
| [龙头全貌](faucet-pullout-overview.png) | 弯管、喷头和独立把手的整体比例 |
| [喷嘴特写](faucet-nozzle-detail.png) | 侧面按钮、十八个出水小孔和中央收口圈 |
| [把手开启](faucet-handle-open.png) | 把手向玩家方向拨动后的姿态 |
| [归位玩家视角](faucet-docked-player.png) | 与正式水槽、台面和灰盒背景的配合 |
| [拉出清洁视角](faucet-pullout-clean.png) | 悬空喷头朝向近距离餐盘的固定展示姿态 |

## 尺寸与结构

| 部位 | 尺寸或做法 |
| --- | --- |
| 龙头高度 | 台面以上约 487.5 mm |
| 主底座 | 最大直径 82 mm，接触面位于根节点高度 |
| 弯颈管 | 外径 35 mm、内径 27 mm，有实际管壁和管腔 |
| 喷头外壳 | 最大直径 50 mm，独立于固定弯管和归位套圈 |
| 出水底片 | 直径 39 mm、厚 2 mm；十八个直径 2.3 mm 的小孔及一个中央孔，均为真实开孔 |
| 中央出水口 | 底片中央孔直径 13 mm，金属收口圈净口直径 12.6 mm |
| 喷头侧面按钮 | 14 × 6 × 32 mm，独立网格，预留朝 Blender 局部 +Y 的按压方向 |
| 抽拉软管 | 直径 9 mm；固定拉出展示形态的中心线长度约 1.079 m |
| 独立把手 | 底座直径 68 mm，中心在主底座右侧 145 mm |
| 把手转轴 | 高出台面 63 mm；握头顶端距转轴 122 mm |
| 把手角度 | 绕局部 X 轴由关闭 10° 转至开启 45°，向玩家方向拨动 |

模型共 **11,083 个源顶点、22,198 个三角形**，十八个网格、三个基础 PBR 材质。弯管和外壳使用缎面钢材质，装饰圈及接头更亮，软管、握头与按钮使用深灰橡胶材质。所有网格已展开 UV，无外部贴图依赖。

`.blend` 和 `.glb` 均以喷头归位、把手关闭、软管形态键为 0 的状态交付。喷头、拨杆与固定底座分开，可在后续接入时分别控制。

## 节点与安装

主要节点如下，固定金属件与密封圈省略部分子网格名称。

```text
Faucet_Assembly
├── Faucet_Base_Contact
├── Faucet_Base / Faucet_Neck / Spray_Dock_Collar
├── Spray_Dock
├── Spray_Inspection_Pose
├── Hose_Exit
├── Pullout_Hose
├── Spray_Head
│   ├── Hose_Attach
│   ├── Spray_Nozzle_Point
│   ├── Spray_Interaction
│   ├── Spray_Shell / Spray_Hose_Coupling
│   ├── Spray_Mode_Button
│   └── Spray_Outlet_Plate / Spray_Outlet_Rim / Spray_Aerator_Ring
└── Handle_Assembly
    ├── Handle_Base_Contact
    ├── Handle_Base / Handle_Valve_Body / Handle_Hinge
    └── Handle_Pivot
        ├── Handle_Lever
        ├── Handle_Grip
        └── Handle_Interaction
```

根原点位于主底座与台面的接触面中心。安装时，将 `Faucet_Assembly` 放在 Blender 世界坐标 **`(0.16, 0.32, 0.90)`** / Godot 世界坐标 **`(0.16, 0.90, -0.32)`**，保持单位缩放和默认朝向。这与[正式水槽](../sink-countertop/sink-countertop.md)的 `Faucet_Mount` 一致。

`Handle_Assembly` 相对根节点向右偏移 0.145 m，安装后与水槽的 `Faucet_Switch_Mount` 对齐，即 Blender 世界坐标 `(0.305, 0.32, 0.90)`。保持整个龙头组合的相对位置，无需再单独给把手添加安装偏移。弯管后侧在窗台所在高度与灰盒窗台前缘保留约 7.5 mm 的间距。

下表的局部坐标以各节点的父节点为基准，单位为米。Blender 至 Godot 的坐标映射为 `(x, z, -y)`。

| 节点 | Blender 局部坐标 / 用途 |
| --- | --- |
| `Spray_Dock` | 相对根节点 `(-0.28, -0.27, 0.30)`，喷头归位姿态 |
| `Spray_Inspection_Pose` | 相对根节点保存固定近距离展示的位置和旋转，与软管展示形态配套 |
| `Hose_Exit` | 相对根节点 `(-0.28, -0.27, 0.34)`，固定弯管内部的软管出口 |
| `Hose_Attach` | 相对喷头 `(0, 0, 0.009)`，跟随喷头移动的接管点 |
| `Spray_Nozzle_Point` | 相对喷头 `(0, 0, -0.085)`，水流起点；方向见下文 |
| `Spray_Interaction` | 相对喷头 `(0, -0.025, -0.04)`，拿取交互定位 |
| `Handle_Pivot` | 相对把手根节点 `(0, 0, 0.063)`，控制拨杆和握头，底座及阀体不随转 |
| `Handle_Interaction` | 相对把手转轴 `(0, 0, 0.110)`，随拨杆移动的交互定位 |

喷嘴定位点已旋转 180°，其 **Blender 局部 +Z / Godot 局部 +Y** 指向出水方向。读取节点的世界变换来取得方向；例如 Godot 中可使用 `Spray_Nozzle_Point.global_basis.y.normalized()`。归位时水流朝世界下方，喷头转动后该方向随之改变。默认安装位置下，喷嘴定位点位于 Blender 世界坐标 `(-0.12, 0.05, 1.115)`。

## 软管展示形态与接入范围

`Pullout_Hose` 带一个名为 `Pullout_Inspection` 的形态键。值为 0 时软管收在弯管内；值为 1 时使用预设曲线连接固定出口与近距离喷头。

在 Godot 中复现两种姿态时，`Spray_Head`、`Spray_Dock` 和 `Spray_Inspection_Pose` 应继续共用同一父节点：

- **固定拉出展示：** 将 `Spray_Head.transform` 设为 `Spray_Inspection_Pose.transform`，并把软管的 `Pullout_Inspection` 混合形状值设为 1。
- **归位：** 将 `Spray_Head.transform` 设为 `Spray_Dock.transform`，并把该混合形状值设为 0。

这是两个配套的静态展示姿态。当前没有任意目标位置的软管自动跟随，也没有完整的抽出、回收动画；不能仅移动喷头就期待软管自动更新。形态键在 0 与 1 之间的插值尚未作为连续动画验收。后续需要根据 `Hose_Exit`、`Hose_Attach` 和玩家操作范围在 Godot 中更新软管曲线，并处理长度及碰撞。

把手可通过设置 `Handle_Pivot.rotation_degrees.x` 在 10° 至 45° 之间转动。模型只提供部件、转轴与角度约定，未绑定水流状态。侧面按钮同样只提供独立模型及按压方向，模式切换、按压表现和交互判定待接入。

本次没有实现水流、冲洗判定、输入、碰撞、音效或完整玩法。近距离预览使用悬空喷头，不包含手部模型。游戏内需单独配置灯光和环境。

## 验证

- 检查十八个网格的闭合性、非退化面和朝外法线；用射线抽查底片中央孔及一个外围小孔保持畅通。
- 检查主底座与独立把手的安装点，喷头默认位置与归位节点一致。
- 在玩家相机下检查归位和固定拉出构图；拉出状态的喷嘴射线命中餐盘正面，喷嘴至盘面约 12.2 cm。
- 对固定拉出曲线逐段检查，软管中心线未穿过餐盘；此项不是完整软管体积碰撞或动态模拟验证。
- Godot 4.7.2 通过 `GLTFDocument` 成功读取并实例化 GLB，验证 31 个节点、18 个网格、22,198 个三角形、UV、法线、软管混合形状及喷头定位层级。
- 在 Godot 中验证把手由 10° 转至 45° 后握头朝玩家移动，底座保持固定；喷头移动至展示节点后，喷嘴方向随之更新。

`01_Faucet_Asset` 为正式资产集合，`90_Preview_Studio` 的相机、灯光和地面不进入 GLB。操作区预览临时加载了正式水槽和餐盘，其他背景仍使用灰盒；这些内容不包含在本轮龙头 GLB 中。原灰盒文件保持原样，正式操作区整体组装仍待进行。

## 重建

在项目根目录运行，会覆盖本组合的 `.blend`、`.glb` 和五张预览。脚本依赖已交付的灰盒、水槽和标准餐盘源文件，用它们生成集成预览。手动编辑模型后，应先保存编辑版本再重建。

```powershell
& 'D:\Blender\blender.exe' --background --factory-startup --python-exit-code 1 --python 'Tools/build_faucet.py'
```

## 可玩入口接入补充（2026-11-24）

上文仍描述原资产和固定展示姿态。第 10 步可玩入口现已使用 world_cleaning_tools.gd 包装实际 Spray_Head，移除旧头部环境形状并随原模型拿取；手位姿态单独设置，不复用餐盘方向。运行时以 16 段圆柱和实际 Hose_Exit／Hose_Attach 更新曲线，各段仅缩放局部 Y；已修正世界轴缩放导致的异常长条。归回恢复原模型软管。

沉浸中喷头与海绵一样自由跟随光标，左键主动命中时从持有侧瞄准，F 才恢复搬运手位。现有检查证明管段连接与横截面正常，尚无长度限制、餐具／环境避障或真实供水，不把历史固定预览的无相交结果当作动态软管已验证。原 .blend、GLB 和生成器未修改。现行操作和预览见 [可玩入口说明](../../scenes/kitchen-game/kitchen-game.md)。
