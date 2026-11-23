# 项目架构与文件职责

> 更新日期：2026-11-23｜基于实施计划第 1 步已核查、用户已验收的厨房展示基线

## 当前实现边界

项目目前是厨房场景查看器。运行链路为 [project.godot](../../project.godot)加载 [kitchen-demo.tscn](../../Scenes/kitchen-demo.tscn)，场景根节点挂载 [kitchen_viewer.gd](../../Scripts/kitchen_viewer.gd)。场景引用独立 GLB，不在运行时打开 Blender 总场景或执行建模脚本。

WASD、鼠标直接看向、玩家碰撞、拿取与清洗、订单、评分和存档是已规划的基础游戏功能，尚无对应运行实现。后续可玩入口应与已有展示器分开；本文件不提前创建或指定这些未来脚本。

## 入口、运行文件与元数据

| 文件 | 当前作用 |
| --- | --- |
| [project.godot](../../project.godot) | 项目名称、主场景、窗口与 Compatibility 渲染配置；关闭 .blend 自动导入。当前视口为 1600 × 900、窗口覆盖为 1280 × 720。 |
| [Scenes/kitchen-demo.tscn](../../Scenes/kitchen-demo.tscn) | 已组装的展示场景，引用房间壳、独立道具与餐具 GLB，保存摆放、灯光、环境、相机和展示提示。由 Godot 组装脚本生成，会被重建覆盖。 |
| [Scripts/kitchen_viewer.gd](../../Scripts/kitchen_viewer.gd) | 场景浏览控制：1～4 预设机位、R 复位、右键拖动、角度限制、Esc 和失焦释放鼠标。没有玩家行走或清洗逻辑。 |
| [Scripts/kitchen_viewer.gd.uid](../../Scripts/kitchen_viewer.gd.uid) | 上述脚本的 Godot 稳定资源标识元数据，随脚本保留。 |
| [Tools/build_kitchen_demo.gd.uid](../../Tools/build_kitchen_demo.gd.uid) | Godot 场景组装脚本的稳定资源标识元数据。 |
| [Tools/capture_kitchen_demo.gd.uid](../../Tools/capture_kitchen_demo.gd.uid) | Godot 截图脚本的稳定资源标识元数据。 |
| 各资产旁的 .import 文件 | Godot 导入设置和源资源映射，随资产保留；与可重新生成的 .godot 缓存不同。 |
| [AGENTS.md](../../AGENTS.md) | 仓库工作约定、固定版本、生成与验证方法、命名和提交要求。 |
| [.gitignore](../../.gitignore) | 排除 .godot、Blender 备份、日志、本地配置和构建输出，保留源模型、GLB、UID 与资产侧导入元数据。 |

场景的 Models 节点保存 8 个环境或道具实例；Dishes 节点保存 5 盘、2 杯的展示实例。托盘上的两盘一杯与架内三盘一杯均为展示布置，不是已经生成的任务订单。相机为 ViewCamera，提示位于 ViewerOverlay；浏览脚本直接引用这些节点，重命名时需同步处理。

## 总场景组装和截图工具

| 文件 | 输入、输出与职责 |
| --- | --- |
| [Tools/build_kitchen_scene.py](../../Tools/build_kitchen_scene.py) | 通过 Blender 读取灰盒和已有独立 .blend，保留房间结构、追加正式道具并按槽位摆餐具；输出 Assets/Scenes/kitchen-room-shell.glb、Assets/Scenes/kitchen-demo.blend 和四张 Blender 场景预览。它不生成 Godot 主场景。 |
| [Tools/build_kitchen_demo.gd](../../Tools/build_kitchen_demo.gd) | 在 Godot 资源导入后加载独立 GLB，按槽位完整变换摆放餐具，创建灯光、相机及查看提示并绑定浏览脚本，覆盖 Scenes/kitchen-demo.tscn。 |
| [Tools/capture_kitchen_demo.gd](../../Tools/capture_kitchen_demo.gd) | 在图形模式实例化现有展示场景，调用两个预设视角，覆盖 Docs/scenes/kitchen-demo/godot-player.png 和 godot-overview.png；不重建场景，不支持无头截图。 |

生成依赖按“独立资产源文件及导出 → Blender 总场景与房间壳 → Godot 导入 → Godot 场景组装 → 运行或截图”理解。只改独立 GLB 后可重新导入该资源；若槽位、节点名或摆放变化，还需同步组装逻辑。不要假定修改 Blender 总场景会自动改变 Godot 中的独立实例。

## 独立资产生成器

以下 Python 文件通过 Blender 运行，生成相应源模型、GLB 与资产预览；不可用普通 Python 代替。生成器可能覆盖既有输出，手工修改须先保护并同步到对应生成逻辑。

| 文件 | 职责及主要资产 |
| --- | --- |
| [Tools/build_kitchen_graybox.py](../../Tools/build_kitchen_graybox.py) | 制作原操作区灰盒、房间与定位参考，输出 Assets/Graybox 下的 kitchen-workstation 源文件和 GLB；总场景组装从其 .blend 读取结构。 |
| [Tools/build_standard_plate.py](../../Tools/build_standard_plate.py) | 标准餐盘的几何、材质、定位与预览，输出 Assets/Dishes/plate-standard。 |
| [Tools/build_standard_mug.py](../../Tools/build_standard_mug.py) | 开口马克杯、杯柄、定位与预览，输出 Assets/Dishes/mug-standard。 |
| [Tools/build_standard_sponge.py](../../Tools/build_standard_sponge.py) | 海绵两层结构、材质烘焙、压缩表现资源和预览，输出 Assets/Tools/sponge-standard 及贴图；没有干湿玩法判定。 |
| [Tools/build_sink_countertop.py](../../Tools/build_sink_countertop.py) | 水槽、排水口和开孔台面的几何与安装参考，输出 Assets/Kitchen/sink-countertop。 |
| [Tools/build_faucet.py](../../Tools/build_faucet.py) | 龙头、可移动喷头、把手、出水定位与软管展示形态，输出 Assets/Kitchen/faucet-pullout；不实现供水开关或清洁。 |
| [Tools/build_soap_dispenser.py](../../Tools/build_soap_dispenser.py) | 泵瓶、活动泵头、按压动画与出液定位，输出 Assets/Tools/soap-dispenser；历史接液预览不等于现行拿瓶施液玩法。 |
| [Tools/build_rack_and_tray.py](../../Tools/build_rack_and_tray.py) | 在共用 .blend 中制作沥水架与托盘，分别导出 dish-rack.glb、dirty-tray.glb，配置 6 盘 2 杯和 2 盘 1 杯姿态并检查几何。 |
| [Tools/build_order_clipboard.py](../../Tools/build_order_clipboard.py) | 墙上夹板与可替换纸面，输出 Assets/Kitchen/order-clipboard；静态示例纸面不是订单管理器。 |
| [Tools/build_order_paper_textures.ps1](../../Tools/build_order_paper_textures.ps1) | 在 PowerShell 中生成订单纸面贴图，供夹板模型使用。 |

## 源模型与运行资产

每对同名 .blend 与 .glb 中，前者为可编辑源文件，后者为 Godot 的导入输入。共用源文件及总场景的例外在表中注明，运行时不要把编辑源当作游戏逻辑。

| 文件 | 作用 |
| --- | --- |
| [Assets/Graybox/kitchen-workstation.blend](../../Assets/Graybox/kitchen-workstation.blend) | 原灰盒源场景，提供结构、相机、锚点与早期布局，是 Blender 总场景生成器的输入。 |
| [Assets/Graybox/kitchen-workstation.glb](../../Assets/Graybox/kitchen-workstation.glb) | 灰盒导出版本；当前 Godot 主场景不直接引用它。 |
| [Assets/Scenes/kitchen-demo.blend](../../Assets/Scenes/kitchen-demo.blend) | 追加独立资产后的 Blender 总场景，用于编辑检查与离线预览；独立源资产更新后需重新组装。 |
| [Assets/Scenes/kitchen-room-shell.glb](../../Assets/Scenes/kitchen-room-shell.glb) | 房间壳、柜体、背景和临时海绵支架导出，是 Godot 房间实例来源。 |
| [plate-standard.blend](../../Assets/Dishes/plate-standard.blend)、[plate-standard.glb](../../Assets/Dishes/plate-standard.glb) | 标准餐盘源模型和运行导入资产，当前重复实例用于展示。 |
| [mug-standard.blend](../../Assets/Dishes/mug-standard.blend)、[mug-standard.glb](../../Assets/Dishes/mug-standard.glb) | 标准马克杯源模型和运行导入资产，保留杯内与杯柄形状。 |
| [sink-countertop.blend](../../Assets/Kitchen/sink-countertop.blend)、[sink-countertop.glb](../../Assets/Kitchen/sink-countertop.glb) | 水槽、开孔台面和安装定位。 |
| [faucet-pullout.blend](../../Assets/Kitchen/faucet-pullout.blend)、[faucet-pullout.glb](../../Assets/Kitchen/faucet-pullout.glb) | 龙头、喷头、把手和软管资源；动态随动与供水尚待运行脚本接入。 |
| [soap-dispenser.blend](../../Assets/Tools/soap-dispenser.blend)、[soap-dispenser.glb](../../Assets/Tools/soap-dispenser.glb) | 泵瓶模型、按压动画及出液节点；尚无拿瓶和施液判定。 |
| [sponge-standard.blend](../../Assets/Tools/sponge-standard.blend)、[sponge-standard.glb](../../Assets/Tools/sponge-standard.glb) | 海绵模型、材质及形态资源；尚无湿润或擦洗状态。 |
| [dish-rack-and-tray.blend](../../Assets/Kitchen/dish-rack-and-tray.blend) | 沥水架和托盘共用的编辑源文件。 |
| [dish-rack.glb](../../Assets/Kitchen/dish-rack.glb) | 沥水架独立导出，含 Rack_Slot_01～06 和 Rack_Cup_Slot_01～02 定位节点。 |
| [dirty-tray.glb](../../Assets/Kitchen/dirty-tray.glb) | 托盘独立导出，含 Dirty_Plate_01、02 和 Dirty_Mug_01 定位节点。 |
| [order-clipboard.blend](../../Assets/Kitchen/order-clipboard.blend)、[order-clipboard.glb](../../Assets/Kitchen/order-clipboard.glb) | 夹板源模型与独立导出，纸面显示静态内容。 |

Assets/Tools/Textures 中 sponge-foam、sponge-pad 各自的 basecolor、normal、roughness PNG 分别提供海绵两层的颜色、法线和粗糙度。Assets/Kitchen/Textures/order-paper-blank.png 与 order-paper-breakfast.png 提供空白和早餐示例纸面。资产目录中带模型前缀的伴随 PNG 以及其 .import 属于导出、导入依赖，不能仅按内容相似判定为可删除重复文件；以模型实际引用为准。

## 文档及预览文件

| 文件或文件组 | 作用 |
| --- | --- |
| [game-design-document.md](game-design-document.md) | 当前目标玩法与验收规则，包括 WASD、两种持有状态、清洗、泡沫评分与 MVP 边界；不能据此推断功能已完成。 |
| [tech-stack.md](tech-stack.md) | 固定工具链、运行状态与配置分离、交互、存档和验证方案。 |
| [implementation-plan.md](implementation-plan.md) | 62 个实施步骤与各步验证条件，第 1 步已通过。 |
| [progress.md](progress.md) | 实际完成记录、测试执行者及来源、当前状态与后续衔接。 |
| [architecture.md](architecture.md) | 当前文件职责、依赖和重建边界；新增或改变职责时更新。 |
| [Docs/README.md](../README.md) | 文档导航，连接 memory-bank、资产说明、场景说明与参考图。 |
| [Docs/kitchen-asset-plan.md](../kitchen-asset-plan.md) | 资产制作范围与交付进度，包括原操作区灰盒说明。 |
| [厨房场景说明](../scenes/kitchen-demo/kitchen-demo.md) | 现有展示场景的打开方式、位置、布局、重建步骤与历史验证。 |
| [餐盘说明](../assets/plate-standard/plate-standard.md)、[马克杯说明](../assets/mug-standard/mug-standard.md) | 对应餐具尺寸、原点、节点和资产接入说明。 |
| [海绵说明](../assets/sponge-standard/sponge-standard.md)、[泵瓶说明](../assets/soap-dispenser/soap-dispenser.md) | 工具结构、动画或形态、定位、材质与历史预览。 |
| [水槽说明](../assets/sink-countertop/sink-countertop.md)、[龙头说明](../assets/faucet-pullout/faucet-pullout.md) | 安装、开孔、活动部件、喷嘴及软管接入限制。 |
| [架与托盘说明](../assets/rack-and-tray/rack-and-tray.md)、[夹板说明](../assets/order-clipboard/order-clipboard.md) | 槽位、兼容几何、纸面和安装说明。 |
| Docs/assets 中的预览 PNG | 对应生成器输出的模型与操作姿态图，供视觉对照，不是运行状态证明。 |
| Docs/scenes/kitchen-demo 下的厨房预览 PNG | kitchen-demo- 前缀为 Blender 预览，godot- 前缀为 Godot 图形模式截图；生成脚本会覆盖对应文件。 |
| Docs/references 中的 PNG | 美术和布局参考，不是场景生成输入或玩法配置。 |
| [Docs/.gdignore](../.gdignore) | 将文档及预览目录排除在 Godot 资源导入之外。 |

## 已确认的架构洞察

1. **展示输入与玩家控制需要分开。** 浏览脚本用数字键切机位、右键拖相机；基础游戏用数字键选工具、右键旋转餐具，且要加入 WASD 与鼠标直接看向。沿用同一个控制入口会导致冲突，第 2 步应先隔离场景，不能把展示器验收等同于移动验收。
2. **场景生成器拥有其输出。** Godot 组装脚本会覆盖主展示场景，Blender 组装脚本会覆盖总场景、房间壳与预览。直接改生成结果而不处理生成器，重建会丢失改动；独立可玩逻辑应避开这些覆盖路径。
3. **定位节点描述姿态，不描述占用。** 槽位保存的是完整餐具根变换，不能再加半高；它们没有兼容、占用、清洁门槛或订单完成逻辑。后续运行状态需另建，不能靠场景节点存在就认定功能已完成。
4. **实例共享资产，任务状态应独立。** 现有盘杯复用模型资源。以后污渍、泡沫、施液和位置状态不能存进共享材质或配置导致多件联动；第 3 步先分离配置与运行状态。
5. **现有背景几何未证明可行走。** 灰盒与房间壳主要面向固定机位展示；WASD 纳入 MVP 后，需要在对应步骤补齐玩家碰撞、通道、边界、交互距离和超距处理，不能以已有地面网格替代这些验证。
6. **资产动画不等于玩法状态。** 泵头动画、喷嘴定位、软管展示形态和海绵形态均可复用，但缺少运行时供水、干湿、施液、清洁及评分判定。历史资产说明中的接液或固定站位方案若与当前设计冲突，玩法以 memory-bank 的现行设计为准，几何约定仍须遵守。
7. **性能目标与当前配置分开记录。** 开发机 1080p 默认画质、稳定 60 FPS 是后续测量目标；现有窗口配置和第 1 步展示验收不能证明该目标或最低配置已经满足。
