# 订单夹板与纸面

2026-11-17 使用 Blender 5.3.0 CLI 制作。圆角暖木板配黄铜色夹具，纸张是带真实厚度、轻微卷角的独立网格。默认显示“早餐之后：两盘一杯”的中文示例订单，同时提供空白纸面贴图。

## 交付文件

| 文件 | 用途 |
| --- | --- |
| [order-clipboard.blend](../../../Assets/Kitchen/order-clipboard.blend) | 可编辑源文件，独立模型与预览布光 |
| [order-clipboard.glb](../../../Assets/Kitchen/order-clipboard.glb) | 导入 Godot 的模型、材质、订单贴图与定位节点 |
| [build_order_clipboard.py](../../../Tools/build_order_clipboard.py) | 重建模型、检查几何、导出与渲染预览 |
| [build_order_paper_textures.ps1](../../../Tools/build_order_paper_textures.ps1) | 生成中文示例订单与空白纸面贴图 |
| [示例订单贴图](../../../Assets/Kitchen/Textures/order-paper-breakfast.png) | 两盘一杯、初始完成数量 0/3 |
| [空白纸面贴图](../../../Assets/Kitchen/Textures/order-paper-blank.png) | 无文字与图标的同色纸底 |
| [夹板全貌](order-clipboard-overview.png) | 板体、金属夹与订单纸面 |
| [夹具特写](order-clipboard-clip-detail.png) | 挂孔、铰链销、铆钉和压纸边 |
| [空白纸面](order-clipboard-blank.png) | 使用同一网格替换贴图后的外观 |
| [正前方玩家视角](order-clipboard-player.png) | 右侧墙面安装位置与满载沥水区 |
| [普通拿起视角](order-clipboard-carry.png) | 持有标准餐盘时检查订单板遮挡 |
| [向右查看](order-clipboard-look-right.png) | 原站位转向订单板，保持相同视野角度 |

## 尺寸与结构

| 项目 | 尺寸或做法 |
| --- | --- |
| 木板 | 宽 230 × 高 330 × 厚 12 mm；轮廓圆角半径 12 mm，边缘倒角 1 mm |
| 整体包围尺寸 | 宽 230 × 高约 332.84 × 深 25 mm；含背垫、前侧夹具和略高出板体的夹片顶端 |
| 背垫 | 四个独立网格岛合为一件，厚 3 mm，后表面定义安装基准 |
| 夹具 | 黄铜色固定底板、夹片、压纸边、铰链销和铆钉分件；挂孔为真实开孔 |
| 纸张 | 宽 198 × 高 280 × 厚 0.45 mm；右下角末端最多向前卷起 3 mm |
| 纸面间距 | 平整区域背面与木板前表面相距 0.35 mm，避免共面闪烁 |
| 贴图 | 两张 1024 × 1448 PNG；主内容区保持平整，顶部留空供夹具覆盖 |

正式资产为 **2,598 个源顶点、5,152 个三角形、8 个网格、13 个节点、5 个材质**。所有网格具有 UV。木板采用基础暖木色，尚未加入木纹贴图；金属使用黄铜色 PBR 材质。夹具保持静态关闭姿态，未制作开合动画或弹簧模拟。

纸面文字、图标与数字来自贴图，没有拆成文字网格。两张 PNG 均打包进 `.blend`，示例订单贴图内嵌于 GLB；使用 GLB 的默认外观无需额外查找贴图。空白 PNG 留作后续替换使用。

## 原点与安装

`.blend` 和 GLB 的 `Order_Clipboard` 根节点均位于原点，保持单位缩放。根节点位于板体宽高中心对应的背垫后接触面。安装时设置以下世界位置，保持零旋转：

| 环境 | 根节点位置，单位米 |
| --- | --- |
| Blender | `(1.2205, 0.398, 1.24)` |
| Godot | `(1.2205, 1.24, -0.398)` |

坐标映射为 Blender `(x, y, z)` → Godot `(x, z, -y)`。板面正面朝 Blender **−Y** / Godot **+Z**，板面上方朝 Blender **+Z** / Godot **+Y**。板体在 Blender 局部 `y=-0.015～-0.003`，背垫最后端为 `y=0`。

安装位置相较旧灰盒的板体略小、略低，使整个模型进入默认玩家镜头。木板左缘 `x=1.1055`，与原窗台最右缘 `x=1.085` 留约 20.5 mm；后垫距离现有墙面约 2 mm。后续调整窗台或墙体时应一并复核。

## 节点与纸面替换

```text
Order_Clipboard
├── Board_Body
├── Board_Back_Pads
├── Order_Paper
├── Board_Wall_Contact
├── Order_Interaction
├── Paper_Surface
└── Clip_Assembly
    ├── Clip_Base
    ├── Clip_Jaw
    ├── Clip_Paper_Lip
    ├── Clip_Hinge_Pin
    └── Clip_Rivets
```

| 定位节点 | Blender 局部位置 | Godot 局部位置 | 用途 |
| --- | --- | --- | --- |
| `Board_Wall_Contact` | `(0, 0, 0)` | `(0, 0, 0)` | 后安装面参考 |
| `Order_Interaction` | `(0, -0.021, -0.012)` | `(0, -0.012, 0.021)` | 订单交互区域参考 |
| `Paper_Surface` | `(0, -0.0158, -0.012)` | `(0, -0.012, 0.0158)` | 平整纸面中心；Blender 节点绕 X 轴旋转 90° |

`Order_Paper` 的 **材质槽 0 / `Order_Paper_Print`** 用于正面内容，材质槽 1 / `Order_Paper_Back` 用于背面和侧边。正面 UV 覆盖完整 0～1：横向对应纸面左右，竖向对应纸面上下，示例图案导出后保持正向。

在 Godot 中可复制纸面正面材质，替换其 `albedo_texture`，再通过 `set_surface_override_material(0, material)` 仅覆盖正面。避免修改导入的共享材质资源，以免多个订单板实例同时变化。空白 PNG 可作为新订单图案的底图；动态完成数量也可在后续使用同宽高比的 UI 纹理更新。

`Order_Interaction` 只提供目标定位，不包含碰撞体或输入处理。纸面中的 0/2、0/1、0/3 是静态示例，实际订单选择、进度更新、E 交互、Tab 面板和结算需要在 Godot 中接入。

## 验证与范围

- 检查各网格岛闭合性、非退化面、正体积与 UV；通过射线确认夹片挂孔贯通、纸面可被命中。
- 默认 16:9 玩家相机中全部模型顶点位于画面内，订单板位于右上侧。
- 在沥水架满载六盘两杯、玩家普通拿起餐盘的状态下，从原机位射向纸面 56 个位置，均首先命中纸张，未被窗台、架内餐具或持有餐盘挡住。
- Godot 4.7.2 成功读取 GLB，核对根节点单位变换、节点层级、米制尺寸、8 个网格、13 个节点、5,152 个三角形及 5 个材质；未导出预览相机、灯光或碰撞体。
- Godot 检查确认正面朝 +Z、UV 覆盖完整 0～1，图案向右为 +X、向上为 +Y，没有镜像；默认订单 PNG 以 1024 × 1448 嵌入 GLB。
- 在 Godot 中实际复制正面材质并将槽 0 覆盖为空白贴图，纸背材质、板体材质和原共享材质均保持不变。

默认视角以识别订单板和餐具图标为目标；远处细小文字仍应通过后续 E 或 Tab 放大的订单界面阅读。向右查看预览只改变朝向，没有移动玩家或拉近镜头。

`01_Order_Clipboard_Asset` 为正式模型集合；`90_Preview_Studio` 的相机、灯光和背景不导出。操作区预览只在内存中替换灰盒占位，原灰盒及其他资产源文件没有被覆盖，正式主场景整体组装仍待进行。预览由 Blender 渲染；Godot 验证使用无界面的数据检查，实时灯光下的外观需在接入时复核。

## 重建

在项目根目录运行以下命令，会重新生成本资产的 `.blend`、GLB、两张贴图与六张预览。脚本读取现有灰盒、餐盘、水槽、水龙头、泵瓶、海绵和沥水架/托盘源文件用于布局预览。手动编辑后应先另存版本，再执行重建。

```powershell
& 'D:\Blender\blender.exe' --background --factory-startup --python-exit-code 1 --python 'Tools/build_order_clipboard.py'
```

建模脚本会调用 `build_order_paper_textures.ps1`。贴图脚本使用 Windows 自带 `System.Drawing` 和本机微软雅黑生成文字，无额外 Python 依赖，也不复制字体文件；调用中的 `RemoteSigned` 只作用于本次 PowerShell 子进程。若在其他系统重建，可先保留已生成 PNG，再另行替换贴图生成步骤。
