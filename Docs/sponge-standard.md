# 标准海绵模型

2026-11-12 使用 Blender 5.3.0 CLI 制作，配合 25 cm 标准餐盘与悬空工具操作。黄色多孔海绵体下方是绿色擦洗层，底面作为实际接触面。

## 交付文件

| 文件 | 用途 |
| --- | --- |
| [sponge-standard.blend](../Assets/Tools/sponge-standard.blend) | 可编辑源模型，包含已打包贴图和压缩形态键 |
| [sponge-standard.glb](../Assets/Tools/sponge-standard.glb) | Godot 资产，贴图内嵌，无外部图片依赖 |
| [Textures](../Assets/Tools/Textures) | 黄色层、绿色层各自的颜色、切线法线和粗糙度 PNG，均为 1024 × 1024 |
| [build_standard_sponge.py](../Tools/build_standard_sponge.py) | 建模、展开 UV、程序材质烘焙、导出与预览脚本 |
| [独立正反面](sponge-standard-overview.png) | 左侧展示黄色层，右侧翻转展示绿色擦洗面 |
| [收纳状态](sponge-standard-rest.png) | 海绵放在现有灰盒收纳位 |
| [近距离清洁](sponge-standard-clean.png) | 与标准餐盘在 Clean_Anchor 下的实际画面占比 |
| [接触特写](sponge-standard-contact.png) | 斜视检查两层厚度、盘面接触及轻微压缩 |

## 规格与结构

- 常态外形 **110 × 70 × 32 mm**，黄色层有较柔和的上缘，绿色层有小圆角和粗糙表面。
- **792 个源顶点、1,576 个三角形**，两个封闭网格、两个材质；两层连接处少量重合以避免裂缝。
- 孔隙和擦洗层细纹通过颜色、法线与粗糙度贴图表现，未为每个孔洞增加几何。
- 根原点位于绿色底面中心，缩放为 1。Blender 中实体位于 `z=0…0.032`，导入 Godot 后位于 `y=0…0.032`。
- `01_Sponge_Asset` 集合包含模型；`90_Preview_Studio` 是独立预览副本与布光，不进入 GLB。

```text
Sponge_Standard
├── Sponge_Foam
├── Sponge_Scrub_Pad
└── Scrub_Contact
```

## 接触与压缩

`Scrub_Contact` 位于根原点，表示绿色擦洗面的中心。该节点的局部 Blender `+Z` / Godot `+Y` 指向底面外侧；在未旋转模型中，这对应整体的 Blender `-Z` / Godot `-Y`。

贴盘时，把根原点放到餐盘表面命中点，让海绵根节点的 Godot `+Y` 对齐餐盘朝外法线。这样黄色层位于表面外侧，绿色底面朝向餐盘。工具应沿实际网格命中法线贴合；接触节点的 `suggested_query_radius_m=0.018` 只是原型查询范围，不能直接代表整块海绵已经擦到的面积。

`Sponge_Foam` 上提供 `Contact_Compress` 形态键，默认值为 0。权重从 0 到 1 时，黄色层以自身底部为基准缩短 18%，长宽轻微扩张 1.2%；总高由 32 mm 变为约 27.05 mm。绿色层及接触原点保持不动。预览使用 0.65 权重，实际按压反馈可在 Godot 中通过 `MeshInstance3D.set_blend_shape_value()` 驱动，无需骨骼。

形态键仅提供视觉压缩，不会自动产生清洁判定或更新物理碰撞。Godot 的网格包围盒包含形态变化范围，因此黄色层包围盒宽度略大于常态网格；摆放尺寸应以常态顶点或明确配置为准。

## 收纳与餐盘比例

现有收纳位为 15 × 10 cm，顶面 Blender `z=0.9285` 米。海绵原点在底面，因此预览位置为 `(-0.30, 0.17, 0.9285)`，不能直接使用旧占位海绵的中心高度 `0.946`。

海绵平面面积约为 25 cm 餐盘面积的 16%。近距预览将它略偏向盘心右下，保留周边可观察区域；侧面特写检查了绿色层与盘面的贴合。弯曲盘沿、杯内壁等位置仍需在玩法阶段实现表面跟随和接触范围限制。

## 验证与范围

- Blender 构建检查了封闭网格、非退化面、朝外法线、单位缩放和 UV 范围。
- 已查看独立正反面、收纳、近距擦洗和接触特写，检查两层接缝、孔隙可读性与遮挡。
- Godot 4.7.2 通过 `GLTFDocument` 成功读取并实例化最终 GLB，验证两个网格的常态尺寸、UV、颜色/法线/粗糙度纹理、接触方向和可设置的压缩形态键。
- GLB 含 4 个资产节点、2 个网格、6 张内嵌图片和 1 个压缩形态，未包含预览场景。

本次交付是海绵资产与接触、压缩准备。鼠标跟随、清洁判定、洗洁精、泡沫和声音需在游戏场景中接入。已有餐盘及灰盒源文件没有被预览过程覆盖。

## 重建

在项目根目录运行以下命令，会重新生成本海绵模型、六张贴图及四张预览。手动编辑源模型后，应先保留编辑版本再重建。

```powershell
& 'D:\Blender\blender.exe' --background --factory-startup --python-exit-code 1 --python 'Tools/build_standard_sponge.py'
```
