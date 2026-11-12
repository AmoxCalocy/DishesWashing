# 标准餐盘模型

2026-11-12 使用 Blender 5.3.0 CLI 制作。外观沿用厨房参考图中的暖白素釉餐盘，适用于悬空搬运、近距离清洁、翻面和入架。

## 交付文件

| 文件 | 用途 |
| --- | --- |
| [plate-standard.blend](../Assets/Dishes/plate-standard.blend) | 可编辑源模型；`01_Plate_Asset` 是资产，`90_Preview_Studio` 是预览布光与副本 |
| [plate-standard.glb](../Assets/Dishes/plate-standard.glb) | Godot 导入资产，仅含餐盘网格、材质和定位节点 |
| [build_standard_plate.py](../Tools/build_standard_plate.py) | 旋转截面建模、UV、导出、几何检查和预览生成脚本 |
| [正反面预览](plate-standard-overview.png) | 左侧正面，右侧背面；均为同一份网格 |
| [普通拿起](plate-standard-carry.png) | 现有工作台相机与 Carry_Anchor |
| [近距离清洁](plate-standard-clean.png) | 现有工作台相机与 Clean_Anchor |
| [近距离翻面](plate-standard-back.png) | 同一清洁锚点，展示盘背和足圈 |

## 模型规格

- 外径 **250 mm**，总高 **24 mm**；盘心到盘沿最高点深 **14 mm**，中央陶瓷厚 **4 mm**。
- 盘面、盘沿、盘背、盘足是一个连续封闭网格，足圈接触面的外径约 **119 mm**。
- **5,250 个源顶点，10,496 个三角形**。圆周 128 段，用于近距离可旋转的主交互餐具。
- 原点位于外形包围盒中心，物体缩放为 1；足底比原点低 **12 mm**。
- 两个基础 PBR 材质：暖白釉面和较粗糙的无釉足底；无需外部纹理文件。
- 一套 `UV_Cleaning`：正面与背面为互不重叠的圆形 UV 岛，接缝在外缘。UV 半径按截面弧长分配；可用于后续污渍贴图或遮罩。
- Blender 中另有 `Clean_Front`、`Clean_Back` 顶点组，方便编辑选区；它们不是 Godot 清洁逻辑或分区数据。

## 节点与方向

```text
Plate_Standard
├── Plate_Surface
├── Placement_Base
├── Dirt_Front_Center
├── Dirt_Front_Rim
├── Dirt_Back_Center
└── Dirt_Back_Foot
```

`Plate_Standard` 是旋转中心。源模型平放时，正面朝 Blender `+Z`；导入 Godot 后正面朝 `+Y`，尺寸为 `(0.25, 0.024, 0.25)` 米。

`Placement_Base` 位于足圈接触平面中心，供平放时对齐台面或托盘。它是定位点，不是碰撞体。灰盒托盘表面在 Blender `z=0.9295` 米，平放时模型原点设为 `z=0.9415` 米。

四个 `Dirt_*` 节点位于正面盘心、正面盘沿、背面中心和足底，提供首轮污渍测试的附着位置。节点局部 Blender `+Z` / Godot `+Y` 表示朝外方向，`test_radius_m` 是建议测试范围。盘沿节点的法线只是定位参考，实际工具贴合应使用命中的网格法线；足底测试范围较小，避免污渍跨过足圈边界。

## 接入 Godot

将 GLB 实例放到普通拿起或近距离清洁锚点下。因为相机向局部 `-Z` 看、盘面默认朝 `+Y`，初始面向玩家时，将餐盘实例绕局部 X 轴旋转 **90°**。后续翻面和旋转作用于同一实例，两种拿起状态共用网格和清洁状态。

现有沥水架的槽距为 73 mm，架齿间净宽约 55 mm，大于餐盘总高 24 mm。竖放时以外径和槽位定位；平放时使用足底定位，不能直接套用旧圆柱占位的中心高度。

清洁射线需要与实际凹面、盘背对应的表面查询形状。覆盖整个餐盘的单个凸包无法准确反映浅凹盘心，搬运碰撞与清洁查询应按用途配置。

本次交付完成模型与污渍定位准备；污渍可见层、擦洗状态、输入和正式碰撞配置仍需在游戏场景中接入。工作台预览从已有灰盒加载并临时替换占位，灰盒源文件保持原样。

## 已检查项目

- 闭合网格、非退化面、朝外法线、实际尺寸和旋转原点。
- 从正面、背面和足底射线命中对应高度；正背面 UV 岛分离且位于 0–1 范围内。
- 普通拿起、近距离清洁及翻面时，餐盘完整处于相机视野内，并避开近裁剪面。
- 最终 GLB 在 Godot 4.7.2 中成功导入并实例化：实测尺寸为 `(0.25, 0.024, 0.25)` 米，两组材质表面和全部定位节点均存在；绕 X 轴 90° 后正面朝相机局部 `+Z`，预览地面与灯光未混入导出。

## 重建

在项目根目录执行，覆盖本餐盘的源模型、GLB 和四张预览：

```powershell
& 'D:\Blender\blender.exe' --background --factory-startup --python-exit-code 1 --python 'Tools/build_standard_plate.py'
```

手动修改 `.blend` 后，应先保留修改版本，再决定是否用脚本重建。
