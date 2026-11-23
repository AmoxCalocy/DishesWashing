# 项目架构与文件职责

> 更新日期：2026-11-23｜第 1～4 步已由用户验收

## 当前实现边界

项目默认入口现为 [project.godot](../../project.godot)加载 [kitchen-game.tscn](../../Scenes/kitchen-game.tscn)。此场景继承 [kitchen-demo.tscn](../../Scenes/kitchen-demo.tscn)的布局，在自身根节点覆盖为空脚本并隐藏 ViewerOverlay，复用已有 GLB、相机和灯光而不启用展示输入。用户已于 2026-11-23 确认第 2 步验证通过。

单独打开 kitchen-demo.tscn 按 F6，仍由 [kitchen_viewer.gd](../../Scripts/kitchen_viewer.gd)控制展示。两个入口分别实例化节点，原展示场景与浏览脚本未改；场景不在运行时打开 Blender 总场景或执行建模脚本。

第 3 步已建立独立数据层：Resource 保存共享配置，RefCounted 保存每次订单的可变状态；第 4 步在 DishState 中加入清洁度计算、整数显示值和实际门槛，均已由用户验证通过。数据层未绑定场景，不改变 F5 画面。WASD、鼠标直接看向、玩家碰撞、拿取与清洗、完整订单流程、评分和存档仍待实现；第 5 步配置游戏输入未开始。

## 入口、运行文件与元数据

| 文件 | 当前作用 |
| --- | --- |
| [project.godot](../../project.godot) | 项目配置，F5 默认启动 kitchen-game.tscn；关闭 .blend 自动导入，沿用 Compatibility、1600 × 900 视口和 1280 × 720 窗口覆盖。 |
| [Scenes/kitchen-game.tscn](../../Scenes/kitchen-game.tscn) | 手工维护的可玩入口，继承展示布局、明确清除根浏览脚本并隐藏 ViewerOverlay。现有生成器不写入此文件，后续玩法在这里接入。 |
| [Scenes/kitchen-demo.tscn](../../Scenes/kitchen-demo.tscn) | 已组装的展示场景，引用房间壳、独立道具与餐具 GLB，保存摆放、灯光、环境、相机和展示提示。由 Godot 组装脚本生成，会被重建覆盖。 |
| [Scripts/kitchen_viewer.gd](../../Scripts/kitchen_viewer.gd) | 场景浏览控制：1～4 预设机位、R 复位、右键拖动、角度限制、Esc 和失焦释放鼠标。没有玩家行走或清洗逻辑。 |
| [Scripts/kitchen_viewer.gd.uid](../../Scripts/kitchen_viewer.gd.uid) | 上述脚本的 Godot 稳定资源标识元数据，随脚本保留。 |
| [Tools/build_kitchen_demo.gd.uid](../../Tools/build_kitchen_demo.gd.uid) | Godot 场景组装脚本的稳定资源标识元数据。 |
| [Tools/capture_kitchen_demo.gd.uid](../../Tools/capture_kitchen_demo.gd.uid) | Godot 截图脚本的稳定资源标识元数据。 |
| 各资产旁的 .import 文件 | Godot 导入设置和源资源映射，随资产保留；与可重新生成的 .godot 缓存不同。 |
| [AGENTS.md](../../AGENTS.md) | 仓库工作约定、固定版本、生成与验证方法、命名和提交要求。 |
| [.gitignore](../../.gitignore) | 排除 .godot、Blender 备份、日志、本地配置和构建输出，保留源模型、GLB、UID 与资产侧导入元数据。 |

场景的 Models 节点保存 8 个环境或道具实例；Dishes 节点保存 5 盘、2 杯的展示实例。托盘上的两盘一杯与架内三盘一杯均为展示布置，不是已经生成的任务订单。相机为 ViewCamera，提示位于 ViewerOverlay；浏览脚本直接引用这些节点，重命名时需同步处理。

## 配置资源与独立运行状态

### 共享配置

Scripts/Data 的类型均继承 Resource，供 .tres 文件复用。它们描述初始数据与静态规则，运行中的清洁进度、施液、泡沫、占用和工具开关不得写入这些配置。

| 文件 | 职责 |
| --- | --- |
| [stain_region_config.gd](../../Scripts/Data/stain_region_config.gd) | 污渍区域 ID、残渣或油渍类型、初始量及泡沫汇总权重。 |
| [dish_config.gd](../../Scripts/Data/dish_config.gd) | 餐具类型、名称、共享模型与污渍区域配置数组。 |
| [slot_config.gd](../../Scripts/Data/slot_config.gd) | 槽位 ID、待洗/临时/沥水类别、兼容餐具类型和所属 fixture_path；槽位 ID 对应资产中已有定位节点名。 |
| [kitchen_layout_config.gd](../../Scripts/Data/kitchen_layout_config.gd) | 厨房槽位配置集合，与具体订单内容分开。 |
| [order_item_config.gd](../../Scripts/Data/order_item_config.gd) | 单件任务餐具的实例 ID、餐具配置引用和初始槽位 ID。 |
| [order_config.gd](../../Scripts/Data/order_config.gd) | 订单 ID、名称、条目数组、基础点数及首次额外点数；未实现奖励发放。 |

槽位配置引用现有 fixture 和定位节点，完整目标姿态仍由资产节点提供；第 3 步未解析场景变换或注册可交互槽位。后续接入时不得将这些数据记录误认为已完成的放置判定。

### 每次订单的状态

Scripts/State 的类型均继承 RefCounted，不依赖场景树或自动加载单例。每次尝试用同一份订单及布局配置构造新的 OrderState，各层按值初始化，不保留可变进度对源 Resource 的回写。

| 文件 | 职责 |
| --- | --- |
| [stain_region_state.gd](../../Scripts/State/stain_region_state.gd) | 每个区域独立的初始量快照、剩余量、类型、泡沫量和权重。 |
| [dish_state.gd](../../Scripts/State/dish_state.gd) | 单件餐具的实例 ID、类型、当前槽位、是否手持、施液资格及独立区域状态字典；按当前区域量计算实际清洁度、整数显示值和清洁度达标结果。 |
| [slot_state.gd](../../Scripts/State/slot_state.gd) | 槽位身份、类别和当前占用者 ID；不实现碰撞、吸附或完成资格。 |
| [tool_state.gd](../../Scripts/State/tool_state.gd) | 工具选择、海绵干湿、龙头开关与泵瓶持有状态；新建时分别为收起、干燥、关闭和归位。 |
| [order_state.gd](../../Scripts/State/order_state.gd) | 按实例 ID 建立餐具字典、按槽位 ID 建立占用字典，为本次尝试新建 ToolState，并根据订单条目初始化占用。构造时检查重复身份、缺失初始槽位和重复占位。 |

OrderState 创建的是内存数据，未生成餐具节点、改变展示餐具或接入重开按钮。重新构造可恢复初始状态；实际订单重置与场景更新属于后续流程。清洁度已在 DishState 实现，奖励算法尚未加入本层。

### 清洁度读取接口（第 4 步）

清洁度由当前区域数据即时推导，不另存可变进度百分比。各区域的剩余量在计算时限制于 0 与自身初始量之间，再按剩余总量与初始总量计算；无初始污渍时为 100%，极小的正初始量仍按非零处理。读取不修改区域数据，泡沫量、泡沫权重和施液资格均不参与计算。

| DishState 接口 | 职责 |
| --- | --- |
| get_cleanliness | 返回 0～1 的实际清洁度，供规则及后续进度显示使用。 |
| get_cleanliness_percent | 返回四舍五入后的整数百分比，只供显示。 |
| meets_cleanliness_requirement | 将实际值与 REQUIRED_CLEANLINESS（0.95）直接比较，不以整数显示或近似相等判断。只代表清洁门槛，不包含槽位兼容、占用、距离或遮挡。 |

94.9%、95%、95.1% 的整数显示均为 95%，但只有后两者达标。后续放置预览、确认放置、Q 返回及完成统计应复用实际门槛；HUD 和完整放置逻辑尚未接入。

### 验证配置与脚本

| 文件 | 职责 |
| --- | --- |
| [plate-config-example.tres](../../Resources/Examples/plate-config-example.tres) | 验证用餐盘配置，引用现有模型，含正面残渣、正面油渍和背面油渍数据。 |
| [mug-config-example.tres](../../Resources/Examples/mug-config-example.tres) | 验证用马克杯配置，引用现有模型与杯内两类污渍数据。 |
| [layout-config-example.tres](../../Resources/Examples/layout-config-example.tres) | 验证用布局，包含 3 个托盘位及各 1 个盘、杯沥水位；不是全厨房槽位清单。 |
| [order-config-example.tres](../../Resources/Examples/order-config-example.tres) | 验证用两盘一杯条目，两件盘子共享同一份 DishConfig；点数 100 和首次额外点数 25 只用于检查配置隔离，不代表正式订单平衡。 |
| [Tools/verify_runtime_state.gd](../../Tools/verify_runtime_state.gd) | 构造多份运行状态，修改及删除其中一份的进度、泡沫、位置、占用、工具和集合内容，检查其他实例、新状态与源配置。成功输出 RUNTIME_STATE_OK、退出 0，失败报告原因并退出 1。 |
| [Tools/verify_cleanliness.gd](../../Tools/verify_cleanliness.gd) | 用内存配置检查加权清洁度、零污渍、越界与只读行为、泡沫独立、整数显示及实际 95% 门槛；不依赖模型加载。成功输出 CLEANLINESS_OK、退出 0，失败报告原因并退出 1。 |

上述 11 个数据类与两份验证脚本各有同名 .gd.uid，保存 Godot 稳定资源标识，随源码提交；新增的 [verify_cleanliness.gd.uid](../../Tools/verify_cleanliness.gd.uid) 对应清洁度验证脚本。验证用 .tres 不被当前主场景加载；先导入新增类型，再按 [progress.md](progress.md) 的命令重跑验证。

## 总场景组装和截图工具

| 文件 | 输入、输出与职责 |
| --- | --- |
| [Tools/build_kitchen_scene.py](../../Tools/build_kitchen_scene.py) | 通过 Blender 读取灰盒和已有独立 .blend，保留房间结构、追加正式道具并按槽位摆餐具；输出 Assets/Scenes/kitchen-room-shell.glb、Assets/Scenes/kitchen-demo.blend 和四张 Blender 场景预览。它不生成 Godot 主场景。 |
| [Tools/build_kitchen_demo.gd](../../Tools/build_kitchen_demo.gd) | 在 Godot 资源导入后加载独立 GLB，按槽位完整变换摆放餐具，创建灯光、相机及查看提示并绑定浏览脚本，覆盖 Scenes/kitchen-demo.tscn。 |
| [Tools/capture_kitchen_demo.gd](../../Tools/capture_kitchen_demo.gd) | 在图形模式实例化现有展示场景，调用两个预设视角，覆盖 Docs/scenes/kitchen-demo/godot-player.png 和 godot-overview.png；不重建场景，不支持无头截图。 |

生成依赖按“独立资产源文件及导出 → Blender 总场景与房间壳 → Godot 导入 → Godot 场景组装 → 运行或截图”理解。只改独立 GLB 后可重新导入该资源；若槽位、节点名或摆放变化，还需同步组装逻辑。不要假定修改 Blender 总场景会自动改变 Godot 中的独立实例。

现有三个总场景工具的输出均不包含 kitchen-game.tscn 或 project.godot。可玩入口会继承重建后的展示布局，但其根脚本覆盖与提示隐藏保存在独立文件；如果生成器改变脚本挂载位置或 ViewerOverlay 路径，需同时回归该隔离约定，不能仅凭文件未被覆盖就认定输入仍隔离。

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
| [implementation-plan.md](implementation-plan.md) | 62 个实施步骤与验证条件，第 1～4 步已通过，第 5 步未开始。 |
| [progress.md](progress.md) | 实际完成记录、测试执行者及来源、当前状态与后续衔接。 |
| [architecture.md](architecture.md) | 当前文件职责、依赖和重建边界；新增或改变职责时更新。 |
| [Docs/README.md](../README.md) | 文档导航，连接 memory-bank、资产说明、场景说明与参考图。 |
| [Docs/kitchen-asset-plan.md](../kitchen-asset-plan.md) | 资产制作范围与交付进度，包括原操作区灰盒说明。 |
| [厨房场景说明](../scenes/kitchen-demo/kitchen-demo.md) | 现有展示场景的打开方式、位置、布局、重建步骤与历史验证。 |
| [可玩入口说明](../scenes/kitchen-game/kitchen-game.md) | 新入口的 F5/F6 使用区别、继承边界、生成输出清单与第 2 步用户验收方法。 |
| [餐盘说明](../assets/plate-standard/plate-standard.md)、[马克杯说明](../assets/mug-standard/mug-standard.md) | 对应餐具尺寸、原点、节点和资产接入说明。 |
| [海绵说明](../assets/sponge-standard/sponge-standard.md)、[泵瓶说明](../assets/soap-dispenser/soap-dispenser.md) | 工具结构、动画或形态、定位、材质与历史预览。 |
| [水槽说明](../assets/sink-countertop/sink-countertop.md)、[龙头说明](../assets/faucet-pullout/faucet-pullout.md) | 安装、开孔、活动部件、喷嘴及软管接入限制。 |
| [架与托盘说明](../assets/rack-and-tray/rack-and-tray.md)、[夹板说明](../assets/order-clipboard/order-clipboard.md) | 槽位、兼容几何、纸面和安装说明。 |
| Docs/assets 中的预览 PNG | 对应生成器输出的模型与操作姿态图，供视觉对照，不是运行状态证明。 |
| Docs/scenes/kitchen-demo 下的厨房预览 PNG | kitchen-demo- 前缀为 Blender 预览，godot- 前缀为 Godot 图形模式截图；生成脚本会覆盖对应文件。 |
| Docs/references 中的 PNG | 美术和布局参考，不是场景生成输入或玩法配置。 |
| [Docs/.gdignore](../.gdignore) | 将文档及预览目录排除在 Godot 资源导入之外。 |

## 已确认的架构洞察

1. **展示输入与玩家控制分别接入。** 浏览脚本用数字键切机位、右键拖相机，基础游戏将用这些键选工具和旋转餐具。第 2 步用继承场景清除根浏览脚本并隐藏提示，用户已确认此隔离及原展示操作正常；后续控制写在可玩入口，移动功能仍须单独实现和验收。
2. **场景生成器拥有其输出。** Godot 组装脚本会覆盖主展示场景，Blender 组装脚本会覆盖总场景、房间壳与预览。直接改生成结果而不处理生成器，重建会丢失改动；独立可玩逻辑应避开这些覆盖路径。
3. **定位节点描述姿态，数据层记录占用。** 资产节点提供完整餐具根变换，不能再加半高；第 3 步已将类别、兼容配置和占用者拆开记录，但尚未接入实际吸附、清洁门槛或完成判定。
4. **共享配置不承载可变进度。** 同一 DishConfig 可以服务多件盘子；每件区域状态、每次订单字典及 ToolState 均独立创建。第 3 步验证包含数值修改和删除集合元素，避免只检查顶层对象不同而遗漏嵌套数据共享。
5. **现有背景几何未证明可行走。** 灰盒与房间壳主要面向固定机位展示；WASD 纳入 MVP 后，需要在对应步骤补齐玩家碰撞、通道、边界、交互距离和超距处理，不能以已有地面网格替代这些验证。
6. **资产动画不等于玩法状态。** 泵头动画、喷嘴定位、软管展示形态和海绵形态均可复用，但缺少运行时供水、干湿、施液、清洁及评分判定。历史资产说明中的接液或固定站位方案若与当前设计冲突，玩法以 memory-bank 的现行设计为准，几何约定仍须遵守。
7. **性能目标与当前配置分开记录。** 开发机 1080p 默认画质、稳定 60 FPS 是后续测量目标；现有窗口配置和第 1 步展示验收不能证明该目标或最低配置已经满足。
8. **显示值与规则值分开。** 清洁度直接从区域状态计算，四舍五入只用于显示；实际 95% 门槛独立于泡沫及持有状态。清洁度达标不等于完整入架资格，后续槽位规则还需组合距离、兼容、占用和遮挡等条件。
9. **区域边界在汇总前处理。** 分别限制每个区域的剩余量，避免一处负值抵消另一处污渍；计算时限制范围但不改写进度。污渍初始量是清洁度权重，foam_weight 仅留给泡沫汇总，不能混用。
