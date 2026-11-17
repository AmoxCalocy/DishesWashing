# 洗洁精泵瓶

2026-11-16 开始制作，2026-11-17 使用 Blender 5.3.0 CLI 完成。采用圆肩透明瓶壳、绿色液体和暖白泵头，瓶身、液体、固定瓶盖与活动泵头分开建模，提供按压动画和标准海绵接液定位。

## 交付文件

| 文件 | 用途 |
| --- | --- |
| [soap-dispenser.blend](../../../Assets/Tools/soap-dispenser.blend) | 可编辑源模型、UV、基础材质、定位点与泵头动画 |
| [soap-dispenser.glb](../../../Assets/Tools/soap-dispenser.glb) | Godot 导入资产，包含本轮模型和按压动画 |
| [build_soap_dispenser.py](../../../Tools/build_soap_dispenser.py) | 建模、几何检查、导出与预览脚本 |
| [泵瓶全貌](soap-dispenser-overview.png) | 瓶壳、绿色液面、吸液管与泵头比例 |
| [泵头按压特写](soap-dispenser-pump-detail.png) | 压下状态、固定瓶盖与出液口 |
| [玩家视角](soap-dispenser-player.png) | 泵瓶与正式水槽、水龙头及操作区的配合 |
| [普通拿起视角](soap-dispenser-carry.png) | 持盘时瓶子交互位置的可见性 |
| [海绵接液特写](soap-dispenser-dose.png) | 黄色层朝上接液，检查压下后泵嘴与海绵的间距 |

## 尺寸与材质

| 部位 | 尺寸或做法 |
| --- | --- |
| 瓶身 | 最大宽 78 mm、深 67.08 mm，瓶壳高 191 mm，椭圆截面与圆肩 |
| 整体高度 | 泵头归位时 245 mm，完全压下时 233 mm |
| 瓶壳 | 有实际内外壁、底部厚度与开放瓶口；主体壁厚约 1.5 mm，底部约 4 mm |
| 瓶口 | 外径 28 mm、内径 25 mm，由独立瓶盖覆盖 |
| 液面 | 中心距瓶底 143 mm，边缘有浅弯月面；绿色液体为固定独立网格 |
| 吸液管 | 外径 6.6 mm、内径 4.4 mm，固定在瓶内 |
| 泵头行程 | 沿 Blender 局部 -Z / Godot 局部 -Y 下压 12 mm |
| 出液口 | 净孔直径 4.4 mm，向下开口；出液定位点位于瓶轴前方 64 mm |
| 海绵接液间距 | 泵头归位时约 29 mm，完全压下时约 17 mm |

模型共 **3,868 个源顶点、7,720 个三角形、9 个网格、19 个资产节点**，使用 5 个基础 PBR 材质。所有网格已展开 UV，无外部贴图依赖。

`Soap_Clear_PET` 以 Alpha 0.10 表现简化透明瓶壳，不依赖折射。Godot 导入后使用 `Alpha Depth Pre-Pass` 透明模式，Alpha 值保持 0.10。绿色液体使用不透明实体材质，保留清楚的液面和颜色；泵头为暖白塑料，吸液管与密封圈另设材质。当前没有液体流动、液面晃动或用量耗尽模拟。

## 节点与安装

```text
Soap_Dispenser
├── Bottle_Base_Contact
├── Bottle_Shell
├── Soap_Liquid
├── Dip_Tube
├── Closure_Gasket
├── Closure_Cap
├── Soap_Interaction
├── Liquid_Surface
├── Pump_Rest
├── Pump_Pressed
├── Sponge_Dose_Pose
└── Pump_Actuator
    ├── Pump_Stem
    ├── Pump_Head
    ├── Pump_Nozzle_Arm
    ├── Pump_Outlet
    ├── Pump_Interaction
    └── Soap_Nozzle_Point
```

根原点位于瓶底接触面的中心。放入现有操作区时，将 `Soap_Dispenser` 设为 Blender 世界坐标 **`(0.535, 0.26, 0.90)`** / Godot 世界坐标 **`(0.535, 0.90, -0.26)`**，保持单位缩放与默认朝向。相比旧灰盒占位向右移动 15 mm，使瓶身与正式水槽盆沿留出空间；瓶底直接落在 0.90 m 高的台面上。

泵嘴朝向玩家，即 Blender 的 -Y / Godot 的 +Z。下表坐标均为米，以所述父节点为基准；Blender 至 Godot 的坐标映射为 `(x, z, -y)`。

| 节点 | Blender 局部坐标 / 用途 |
| --- | --- |
| `Bottle_Base_Contact` | 相对根节点 `(0, 0, 0)`，瓶底接触点 |
| `Soap_Interaction` | 相对根节点 `(0, -0.034, 0.12)`，瓶身正面的交互定位 |
| `Liquid_Surface` | 相对根节点 `(0, 0, 0.143)`，固定液面中心 |
| `Pump_Rest` | 相对根节点 `(0, 0, 0.212)`，泵头归位姿态 |
| `Pump_Pressed` | 相对根节点 `(0, 0, 0.200)`，泵头完全压下姿态 |
| `Pump_Interaction` | 相对活动泵头 `(0, -0.002, 0.034)`，跟随按压面移动 |
| `Soap_Nozzle_Point` | 相对活动泵头 `(0, -0.064, 0.012)`，跟随泵头移动的出液起点 |
| `Sponge_Dose_Pose` | 相对根节点 `(0, -0.09, 0.163)`，标准海绵的底部原点位置与朝向 |

`Soap_Nozzle_Point` 已绕 X 轴旋转 180°。其 **Blender 局部 +Z / Godot 局部 +Y** 指向出液方向，默认安装后朝世界下方；在 Godot 中可读取 `Soap_Nozzle_Point.global_basis.y.normalized()`。定位点的默认 Blender 世界坐标为 `(0.535, 0.196, 1.124)`，压下后降至 `z=1.112`。

## 按压与接液

`Pump_Press` 动画只移动 `Pump_Actuator` 及其子部件，固定瓶盖、瓶壳、吸液管和液体不随之运动。源文件按 30 fps 制作，Godot 导入后实测总长 **0.700 秒**，保留以下源帧时间：

| 源帧 | Godot 动画时间 | 状态 |
| --- | --- | --- |
| 1 | 约 0.0333 s | 归位 |
| 7 | 约 0.2333 s | 完全压下 12 mm |
| 13 | 约 0.4333 s | 保持压下 |
| 21 | 0.700 s | 回到归位位置 |

源模型默认停在第 1 帧。也可自行控制泵头位置：Godot 中将 `Pump_Actuator.position.y` 在 0.212 与 0.200 之间变化，或使用同一父节点下的 `Pump_Rest`、`Pump_Pressed` 变换。不要同时用动画和手动位置更新驱动同一个泵头。

接液预览使用已交付的 [110 × 70 × 32 mm 标准海绵](../sponge-standard/sponge-standard.md)。将海绵根节点的世界变换设为 `Sponge_Dose_Pose` 的世界变换，保持黄色层朝上、绿色擦洗层朝下；海绵顶面高度为瓶底以上 195 mm。完全压下时，出液点距黄色顶面约 17 mm，向下射线命中黄色层。海绵放在瓶子前方，其后缘与瓶身留有间距。

按现有[游戏设计](../../game-design-document.md)，补充洗洁精在未拿起或普通拿起状态进行；近距离清洁时需先返回普通拿起。当前只交付模型、定位与按压动画，尚未实现 E 键交互、海绵补液状态、水滴、泡沫、声音或碰撞。

## 验证与范围

- Blender 检查了 9 个网格的闭合性、非退化面和朝外法线，并用射线确认瓶口及泵嘴孔未封堵。
- 检查泵嘴完整下降 12 mm，瓶身保持固定；压下后泵头底面与固定瓶盖仍留约 8 mm 间隙。
- 以正式水槽盆沿和灰盒沥水架边界检查瓶身摆放范围。
- 在普通拿起餐盘时，从玩家相机射向瓶身交互点，首先命中 `Bottle_Shell`，未被盘子或其他物件遮挡。
- 按压状态下，从出液点向下射线命中海绵黄色顶面，间距约 17 mm。
- Godot 4.7.2 通过 `GLTFDocument` 成功读取并实例化最终 GLB，验证 9 个网格、19 个资产节点、7,720 个三角形、5 个材质、尺寸、UV 与法线；预览对象未进入导出。
- 在 Godot 中播放并定位 `Pump_Press`，验证泵头实际下压 12 mm、保持及复位，瓶身、固定瓶盖和液体保持不动，出液点跟随泵头移动。
- 验证 Godot 中瓶壳 Alpha 为 0.10、透明模式为 `Alpha Depth Pre-Pass`。本轮检查覆盖资产、动画和材质属性；预览图由 Blender 渲染，Godot 实时画面仍需在正式游戏灯光下复核。

`01_Soap_Dispenser_Asset` 为正式资产集合；`90_Preview_Studio` 中的相机、灯光和地面不进入 GLB。操作区预览临时加载正式水槽、水龙头、餐盘和海绵，其余背景使用灰盒；这些模型不会并入泵瓶导出文件。原灰盒与其他资产源文件未被覆盖，正式操作区整体组装仍待进行。

## 重建

在项目根目录运行，会覆盖本泵瓶的 `.blend`、`.glb` 和五张预览。脚本依赖已交付的灰盒、水槽、水龙头、餐盘和海绵源文件。手动编辑后，应先保存编辑版本再重建。

```powershell
& 'D:\Blender\blender.exe' --background --factory-startup --python-exit-code 1 --python 'Tools/build_soap_dispenser.py'
```
