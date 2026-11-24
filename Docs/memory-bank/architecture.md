# 项目架构与文件职责

> 更新日期：2026-11-24｜第 1～9 步及追加右键放大已由用户验收

## 当前实现边界

项目默认入口现为 [project.godot](../../project.godot)加载 [kitchen-game.tscn](../../Scenes/kitchen-game.tscn)。此场景继承 [kitchen-demo.tscn](../../Scenes/kitchen-demo.tscn)的布局，在自身根节点覆盖为空脚本并隐藏 ViewerOverlay，复用已有 GLB 与灯光而不启用展示输入。第 2 步入口隔离于 2026-11-23 通过验收，第 6 步改由独立玩家相机查看场景。

单独打开 kitchen-demo.tscn 按 F6，仍由 [kitchen_viewer.gd](../../Scripts/kitchen_viewer.gd)控制展示。两个入口分别实例化节点，原展示场景与浏览脚本未改；场景不在运行时打开 Blender 总场景或执行建模脚本。

第 3、4 步建立独立数据层及清洁度规则，第 5～7 步接入输入、界面、行走碰撞、鼠标直接看向及右键临时观察放大，第 8 步接入盘杯身份与真实表面，第 9 步注册 13 个槽位及临时位识别，均已由用户验证通过。OrderState 与 DishState 尚未绑定场景，当前占用由槽位注册器的 SlotState 记录。实际拿取与清洗、完整放置与订单流程、评分和存档仍待实现；第 10 步未开始。

## 入口、运行文件与元数据

| 文件 | 当前作用 |
| --- | --- |
| [project.godot](../../project.godot) | 项目配置，F5 默认启动 kitchen-game.tscn；保存 16 个 game_ 前缀输入映射，关闭 .blend 自动导入，沿用 Compatibility、1600 × 900 视口和 1280 × 720 窗口覆盖。 |
| [Scenes/kitchen-game.tscn](../../Scenes/kitchen-game.tscn) | 手工维护的可玩入口，组装输入、HUD、玩家、步行碰撞、PlayableDishes、SurfaceCollision、KitchenSlots 与 DishTargeting。隐藏全部原展示餐具，设置三件独立盘杯的初始槽位 ID，由注册器读取模型定位点摆放；保持相机与展示输入隔离。 |
| [Scenes/player.tscn](../../Scenes/player.tscn) | 手工维护的 CharacterBody3D 玩家，包含胶囊及眼高 1.62 m 的 ViewCamera，挂载 PlayerController。 |
| [Scenes/kitchen-walk-collision.tscn](../../Scenes/kitchen-walk-collision.tscn) | 手工维护的 StaticBody3D，六个碰撞形状限制地面、柜体与台面、后墙及边界；仅供玩家行走阻挡，不是交互表面。 |
| [Scripts/Player/player_controller.gd](../../Scripts/Player/player_controller.gd) | 处理 GameInput 的观察和临时放大意图：玩家水平转向、相机俯仰限制、捕获恢复防突跳及 FOV 缓存/复原；原物理回调继续处理水平行走、重力和滑动碰撞。 |
| [Scenes/game-hud.tscn](../../Scenes/game-hud.tscn) | 手工维护的 CanvasLayer 界面，包含不拦截输入的中央准星及 TargetName 标签、全屏菜单背景与继续按钮；独立于生成的展示器提示层。 |
| [Scripts/Input/game_input.gd](../../Scripts/Input/game_input.gd) | 继承 Node 的输入分派器；处理未被 UI 消费的事件，按上下文发出动作意图，管理按住状态和鼠标模式；右键在餐具旋转与临时观察放大之间分派。 |
| [Scripts/UI/game_hud.gd](../../Scripts/UI/game_hud.gd) | 用 input_path 查找 GameInput，监听模式变化并连接继续按钮；可选 targeting_path 连接餐具及临时位变化，共用 TargetName 显示名称，清除槽位时恢复当前餐具或清空。独立输入测试不要求绑定目标查询。 |
| [Scenes/kitchen-demo.tscn](../../Scenes/kitchen-demo.tscn) | 已组装的展示场景，引用房间壳、独立道具与餐具 GLB，保存摆放、灯光、环境、相机和展示提示。由 Godot 组装脚本生成，会被重建覆盖。 |
| [Scripts/kitchen_viewer.gd](../../Scripts/kitchen_viewer.gd) | 场景浏览控制：1～4 预设机位、R 复位、右键拖动、角度限制、Esc 和失焦释放鼠标。没有玩家行走或清洗逻辑。 |
| [Scripts/kitchen_viewer.gd.uid](../../Scripts/kitchen_viewer.gd.uid) | 上述脚本的 Godot 稳定资源标识元数据，随脚本保留。 |
| [Tools/build_kitchen_demo.gd.uid](../../Tools/build_kitchen_demo.gd.uid) | Godot 场景组装脚本的稳定资源标识元数据。 |
| [Tools/capture_kitchen_demo.gd.uid](../../Tools/capture_kitchen_demo.gd.uid) | Godot 截图脚本的稳定资源标识元数据。 |
| [game_input.gd.uid](../../Scripts/Input/game_input.gd.uid)、[game_hud.gd.uid](../../Scripts/UI/game_hud.gd.uid) | 第 5 步两个运行脚本的稳定资源标识，随源码保留。 |
| [player_controller.gd.uid](../../Scripts/Player/player_controller.gd.uid) | 玩家控制脚本的稳定资源标识，随源码保留。 |
| 各资产旁的 .import 文件 | Godot 导入设置和源资源映射，随资产保留；与可重新生成的 .godot 缓存不同。 |
| [AGENTS.md](../../AGENTS.md) | 仓库工作约定、固定版本、生成与验证方法、命名和提交要求。 |
| [.gitignore](../../.gitignore) | 排除 .godot、Blender 备份、日志、本地配置和构建输出，保留源模型、GLB、UID 与资产侧导入元数据。 |

原展示场景中 Models 保存 8 个环境或道具实例，Dishes 保存 5 盘、2 杯的展示实例。可玩入口隐藏全部 Dishes，避免架内装饰占据任务位置；PlayableDishes 中两盘一杯由注册器放入托盘，沥水与临时位初始为空。当前仍是固定三件布置，未绑定生产订单。原展示器相机为根 ViewCamera，提示位于 ViewerOverlay；可玩入口停用根相机，实际使用 Player/ViewCamera，重命名时须区分两个入口。

## 游戏输入与基础界面（第 5 步）

只有可玩入口实例化 GameInput 和 GameHUD。输入通过 _unhandled_input 接入，让 GUI 优先消费事件；不使用全局按键轮询执行交互。WASD 对应四个移动动作，左右鼠标键、F、E、1～3、Q、Tab、Esc、滚轮上下对应另外十二个动作；鼠标移动独立分派为观察、旋转或工具光标信号。

| GameInput 接口或状态 | 当前职责 |
| --- | --- |
| set_context | 接收持有模式、已筛选目标类别及工具选择。模式为 EMPTY、CARRYING、CLOSE_UP、SOAP_BOTTLE、TRANSITION；DishTargeting 按距离和遮挡提供 DISH、空临时位的 SLOT 或 NONE，其余世界目标与完整放置尚未接入。 |
| command_requested | 发出动作意图及按下/停止标志。拿取、放置、泵压等为单次意图；润湿、工具使用和旋转有停止通知。意图不代表已执行或通过全部玩法校验。 |
| get_movement_vector、movement_changed | 提供归一化二维移动输入；界面、近距离及过渡期间为零。PlayerController 已在物理回调中读取该向量。 |
| look_requested、rotation_requested、tool_cursor_moved | look_requested 已连接 PlayerController，实现直接观察；餐具旋转与工具光标仍只有分派意图。独立盘杯节点已存在，实际持物、旋转与工具跟随尚未接入。 |
| set_interface_open、mode_changed | 控制界面与鼠标模式并通知 HUD。菜单或失焦清除旧输入并结束持续使用，恢复需重新按下；持有模式改变也清除旧按住状态，单独切工具不丢失移动键。 |

左键按上下文只选择拿餐具、润湿、放置、使用工具或泵压中的一个；E 区分龙头、订单板和空手拿瓶，Q 区分退出近距离、返回餐具和归位泵瓶。game_tool_ 动作只发出选择意图，不自行修改 ToolState。后续消费者负责实际状态更新、动画及玩法限制，并通过 set_context 同步输入上下文。

右键继续复用 game_rotate 输入映射：CARRYING、CLOSE_UP 分派 rotate_dish，EMPTY、SOAP_BOTTLE 分派 zoom_view。两者都使用按下/停止通知；_clear_held 在界面、失焦或持有模式切换时结束放大意图，目标更新则保留按住放大，避免观察过程中反复复原。

GameHUD 在普通游戏输入模式显示准星，近距离和过渡时隐藏；界面模式显示菜单并释放鼠标。“继续游戏”返回输入模式，普通状态恢复捕获，近距离保持可见光标。当前界面不暂停场景树，不代替第 18 步的运行状态冻结，也不提供正式订单面板。

## 玩家行走与碰撞（第 6 步）

PlayerController 每个物理帧读取过滤后的输入，将玩家相机的前向投影到 XZ 平面并归一化，再得到正交的左右方向；水平速度上限为 1.6 m/s。相机俯仰不参与垂直移动，重力按时间累积，move_and_slide 处理实际位移和碰撞。第 7 步已接入观察信号，行走方向随玩家的当前水平观察朝向变化。

| 配置 | 当前值与用途 |
| --- | --- |
| 出生位置 | kitchen-game.tscn 中 Player 的世界位置为（0，0.03，1.18），略高于地面后落地。 |
| 身体与相机 | 胶囊半径 0.22 m、高 1.75 m，根节点代表脚底；相机局部眼高 1.62 m，初始俯角约 26.37°。 |
| 玩家碰撞 | Player 位于物理层 2，掩码为 16；WalkCollision 位于物理层 5（位值 16），掩码为 0。 |
| 步行代理 | 地面 5×5 m，顶部为世界 Y=0；柜体与台面合用箱体，后墙及侧面、前方边界限制行走范围。尺寸对应当前房间布局，资产变化后需重新核对。 |
| 输入限制 | 菜单、近距离、过渡与失焦时水平输入为零；重力仍运行，完整冻结留在暂停步骤。实际持物尚未实现，相关模式由验证脚本设置。 |

步行代理与交互碰撞分别维护。整柜箱体阻止身体进入操作台下方，但不描述水槽内腔或盘杯表面；第 8 步真实目标射线已排除玩家层 2 和步行代理层 5，另检测餐具层 1 与环境表面层 3。新增表面均不进入玩家的行走掩码。

## 鼠标观察与临时放大（第 7 步）

PlayerController 在就绪时连接观察、模式及动作信号。水平位移改变玩家根节点的 Y 轴朝向，并将角度循环归一化，允许连续转身；垂直位移只改变相机 X 轴俯仰，范围为 ±80°，不产生侧倾或位置变化。默认 look_sensitivity 为每像素 0.0025 弧度，鼠标位移不再乘帧时间。

_look_enabled 依据界面和持有模式控制观察。菜单、近距离或过渡导致允许状态变化时重新设置首包丢弃标志；恢复捕获后的首个鼠标位移被忽略，旧增量不累计。单独更新目标、工具或在允许观察的持有模式之间切换，不反复丢弃鼠标输入。持餐具右键旋转由输入分派层拦截观察信号。

zoom_view 按下时缓存当前相机 FOV 并收窄视野，默认从 53.7° 变为 35°；重复按下不覆盖缓存。松开或收到取消意图时恢复缓存原值。放大期间继续允许观察和行走，不修改玩家或相机位置。它与 F 拉近餐具、近距离滚轮调整餐具距离分开，后两者尚未实现。

实际运行默认空手，准星可识别距离内可见的托盘餐具和空临时位；持餐具、持瓶和近距离等分派上下文仍由验证脚本设置。后续持物状态必须使用 set_context 同步，确保旧旋转、放大和按住输入被正确结束。

## 盘杯身份、真实表面与目标查询（第 8 步）

| 文件 | 当前职责 |
| --- | --- |
| [Scenes/Dishes/plate.tscn](../../Scenes/Dishes/plate.tscn) | 手工维护的 StaticBody3D 餐盘封装，挂载 DishBody，Model 子节点实例化正式 plate-standard.glb；默认类型 plate、名称“餐盘”。 |
| [Scenes/Dishes/mug.tscn](../../Scenes/Dishes/mug.tscn) | 手工维护的 StaticBody3D 杯子封装，复用 mug-standard.glb；默认类型 mug、名称“马克杯”，保留杯体、杯柄和表面定位节点。 |
| [Scripts/Dishes/dish_body.gd](../../Scripts/Dishes/dish_body.gd) | 每个实例保存 instance_id、initial_slot_id、dish_type 和 display_name；就绪时检查身份、设置查询层并生成真实表面碰撞。initial_slot_id 供注册器初始化使用，不是运行中的当前槽位；此类尚未关联 DishState。 |
| [Scripts/Interaction/mesh_surface_collision.gd](../../Scripts/Interaction/mesh_surface_collision.gd) | 从可见 MeshInstance3D 读取三角面，为目标 StaticBody3D 添加 ConcavePolygonShape3D 与 CollisionShape3D；保留网格相对身体的完整变换，提供查询层常量及小面精度处理。 |
| [Scripts/Interaction/kitchen_surface_collision.gd](../../Scripts/Interaction/kitchen_surface_collision.gd) | 按 visual_roots 为 Models、Dishes 下可见实例添加真实环境遮挡；第 9 步全部原展示餐具被隐藏，故不再生成它们的碰撞。临时位标记不在扫描根节点内，不生成遮挡。 |
| [Scripts/Interaction/dish_targeting.gd](../../Scripts/Interaction/dish_targeting.gd) | 从玩家相机中央发出默认 1.5 米射线，先识别第一处 DishBody，否则查询命中盆底附近的空临时位；保存 current_dish/current_slot，分别发出 target_changed/slot_changed，并同步 GameInput。query_dish 仍仅即时返回餐具，不执行拿取或清洁。 |
| [dish_body.gd.uid](../../Scripts/Dishes/dish_body.gd.uid)、[mesh_surface_collision.gd.uid](../../Scripts/Interaction/mesh_surface_collision.gd.uid)、[kitchen_surface_collision.gd.uid](../../Scripts/Interaction/kitchen_surface_collision.gd.uid)、[dish_targeting.gd.uid](../../Scripts/Interaction/dish_targeting.gd.uid) | 四个新增运行脚本的 Godot 稳定资源标识，随源码保存。 |

PlayableDishes 当前包含固定实例 tray_plate_01、tray_plate_02、tray_mug_01，显示“餐盘 1”“餐盘 2”“马克杯”。它们复用原托盘完整姿态，没有额外叠加半高；实例身份与 GLB 的共享网格、材质分开。共享模型不包含清洁进度，本次也未加载 Resources/Examples 订单作为生产数据。

| 物理对象 | 所在层与位值 | 用途 |
| --- | --- | --- |
| DishBody | 层 1，位值 1，掩码 0 | 可识别餐具的真实表面。 |
| 环境 SurfaceCollision | 层 3，位值 4，掩码 0 | 环境、工具和架内展示餐具的真实遮挡。 |
| Player | 层 2，位值 2，掩码 16 | 玩家身体，仅与步行代理碰撞。 |
| WalkCollision | 层 5，位值 16，掩码 0 | 粗略地面、柜体、墙与边界阻挡。 |
| DishTargeting 查询 | 掩码 5，即位值 1 与 4 | 排除玩家和步行箱体；环境首先命中时停止，不向后寻找餐具。 |

所有表面使用实际三角面，不把杯口、杯柄、架槽或托盘封成凸包。小三角面曾在近距离短射线下漏检，因此将碰撞局部顶点坐标乘 100，再对形状施加 0.01 等比缩放；最终世界位置与尺寸不变，原 GLB、网格资源和材质均不修改。专项验证同时检查短射线、表面法线、平移旋转后的杯内和外部开口，不以只命中包围盒作为通过条件。

DishTargeting 每个物理帧更新目标，当前仅在 EMPTY、SOAP_BOTTLE 查询餐具或空临时位，界面和其他模式清除目标。有效类别通过 set_context 更新，同类餐具或临时位之间的变化分别通过信号通知 HUD；放大不会延长距离。完整槽位瞄准与搬运预览、龙头、水流和泵瓶等目标尚未接入，扩展时协调现有 DISH/SLOT/NONE 路由，不能让多个组件互相覆盖上下文。实际动作执行前应再次查询，不能只相信缓存。

环境形状在就绪时按网格姿态生成，跟随其所属身体；后续若动画改变把手、喷头或泵头等子网格的相对姿态，需同步对应碰撞，不能假定已有形状会自动重建。可复用盘杯场景和本节脚本均由手工维护，现有生成器不覆盖它们。

## 完整槽位布局与注册（第 9 步）

| 文件 | 当前职责 |
| --- | --- |
| [Resources/Kitchen/kitchen-layout.tres](../../Resources/Kitchen/kitchen-layout.tres) | 可玩场景的完整布局配置，列出托盘 3 位、沥水架 8 位及临时 2 位的身份、显示名称、类别、兼容类型和 fixture_path。它与数据验证用的 Examples 布局分开，不包含运行占用。 |
| [Scenes/kitchen-slots.tscn](../../Scenes/kitchen-slots.tscn) | 手工维护的 KitchenSlotRegistry 场景，绑定完整布局和场景路径；包含两个已校准完整姿态的临时 Marker3D、各自的 SelectionSurface、圆环和 Label3D。视觉标记不参与碰撞，不是落位预览。 |
| [Scripts/Slots/kitchen_slot.gd](../../Scripts/Slots/kitchen_slot.gd) | RefCounted 包装，关联一个 SlotConfig、独立新建的 SlotState 及实际定位节点。get_pose 读取节点完整 global_transform，accepts/is_empty 只读取兼容与占用，不做完整放置判定。 |
| [Scripts/Slots/kitchen_slot_registry.gd](../../Scripts/Slots/kitchen_slot_registry.gd) | 按配置查找定位节点，校验身份与兼容信息，为每场景新建 13 个 KitchenSlot；根据 DishBody.initial_slot_id 记录三件初始占用并摆放。find_temporary_slot 只从真实盆底命中筛选空临时位。 |
| [kitchen_slot.gd.uid](../../Scripts/Slots/kitchen_slot.gd.uid)、[kitchen_slot_registry.gd.uid](../../Scripts/Slots/kitchen_slot_registry.gd.uid) | 两个新运行脚本的 Godot 稳定资源标识，随源码保存。 |

| 槽位 ID | 数量与兼容 | 姿态及初始占用 |
| --- | --- | --- |
| Dirty_Plate_01、02 / Dirty_Mug_01 | 2 盘、1 杯 | 读取 Models/DirtyTray 的完整节点姿态；分别占用 tray_plate_01、tray_plate_02、tray_mug_01。 |
| Rack_Slot_01～06 / Rack_Cup_Slot_01、02 | 6 盘、2 杯 | 读取 Models/DishRack 的完整姿态，保留竖盘、倒扣杯的方向；初始全部为空。 |
| Sink_Plate_01 / Sink_Mug_01 | 1 盘、1 杯 | KitchenSlots 下手工维护的根姿态；初始均为空。 |

托盘和架位直接读取正式 GLB 的餐具根定位节点，不重新推算半高。临时位则根据水槽 Plate_Return_Surface、Mug_Return_Surface 的表面参考，使用盘杯网格与盆底测量后校准；根姿态与表面参考不能混用。当前布局中临时盘根位置为（-0.23，0.667577，-0.045）米，杯根位置为（0.23，0.708443，-0.1）米，均为直立单位旋转；最小承托余量约 0.5 mm。盆底或模型变化后需重新测量，不能机械叠加半高或沿用旧余量。

SelectionSurface 是盆底瞄准参考，圆环略高于表面，Label3D 提供位置名称。find_temporary_slot 要求首个碰撞属于指定水槽实例，且命中点距对应表面参考的水平距离不超过 0.06 米、高度差小于 0.006 米，同时槽位为空；整体射线仍受 1.5 米限制。餐具先命中时保持 DISH，不再选择其下方临时位。这些条件只使临时位可识别，未开放实际放置、所有架位瞄准或幽灵餐具预览。

注册器创建的 SlotState 是当前场景占用记录，三件初始盘杯保留固定身份，未接入 OrderState/DishState 或正式订单列表。共享 KitchenLayoutConfig 只描述布局，不承载占用。以后接入订单时应明确共用或替换同一套 SlotState，不能让注册器和 OrderState 各维护一套占用。initial_slot_id 也只描述初始化；拿起时需读当前槽位、解除占用并另存本次取出位置供 Q 使用。

当前可玩入口的 Dishes 全部隐藏，避免旧架内展示餐具堵住任务位或误计占用；原展示器单独加载时仍保留所有布置。新场景、资源与脚本均不由现有生成器覆盖；当前布局加载的是 13 个正式槽位配置，Resources/Examples 仍仅供数据规则验证。

## 配置资源与独立运行状态

### 共享配置

Scripts/Data 的类型均继承 Resource，供 .tres 文件复用。它们描述初始数据与静态规则，运行中的清洁进度、施液、泡沫、占用和工具开关不得写入这些配置。

| 文件 | 职责 |
| --- | --- |
| [stain_region_config.gd](../../Scripts/Data/stain_region_config.gd) | 污渍区域 ID、残渣或油渍类型、初始量及泡沫汇总权重。 |
| [dish_config.gd](../../Scripts/Data/dish_config.gd) | 餐具类型、名称、共享模型与污渍区域配置数组。 |
| [slot_config.gd](../../Scripts/Data/slot_config.gd) | 槽位 ID、显示名称、待洗/临时/沥水类别、兼容餐具类型和所属 fixture_path；槽位 ID 对应 fixture 下的定位节点名。 |
| [kitchen_layout_config.gd](../../Scripts/Data/kitchen_layout_config.gd) | 厨房槽位配置集合，与具体订单内容分开。 |
| [order_item_config.gd](../../Scripts/Data/order_item_config.gd) | 单件任务餐具的实例 ID、餐具配置引用和初始槽位 ID。 |
| [order_config.gd](../../Scripts/Data/order_config.gd) | 订单 ID、名称、条目数组、基础点数及首次额外点数；未实现奖励发放。 |

第 3 步只建立配置与状态结构，第 9 步已由 KitchenSlotRegistry 将完整布局解析为实际定位节点与占用。注册与临时位识别不代表已完成完整放置判定；距离、空间、占用、清洁门槛及确认落位仍须在对应步骤组合。

### 每次订单的状态

Scripts/State 的类型均继承 RefCounted，不依赖场景树或自动加载单例。每次尝试用同一份订单及布局配置构造新的 OrderState，各层按值初始化，不保留可变进度对源 Resource 的回写。

| 文件 | 职责 |
| --- | --- |
| [stain_region_state.gd](../../Scripts/State/stain_region_state.gd) | 每个区域独立的初始量快照、剩余量、类型、泡沫量和权重。 |
| [dish_state.gd](../../Scripts/State/dish_state.gd) | 单件餐具的实例 ID、类型、当前槽位、是否手持、施液资格及独立区域状态字典；按当前区域量计算实际清洁度、整数显示值和清洁度达标结果。 |
| [slot_state.gd](../../Scripts/State/slot_state.gd) | 槽位身份、类别和当前占用者 ID；不实现碰撞、吸附或完成资格。 |
| [tool_state.gd](../../Scripts/State/tool_state.gd) | 工具选择、海绵干湿、龙头开关与泵瓶持有状态；新建时分别为收起、干燥、关闭和归位。 |
| [order_state.gd](../../Scripts/State/order_state.gd) | 按实例 ID 建立餐具字典、按槽位 ID 建立占用字典，为本次尝试新建 ToolState，并根据订单条目初始化占用。构造时检查重复身份、缺失初始槽位和重复占位。 |

OrderState 创建的是内存数据，尚未绑定餐具节点或重开按钮。第 9 步实际场景通过 KitchenSlotRegistry 新建独立 SlotState 并隐藏展示餐具，与 OrderState 的样例初始化仍分开。实际订单重置与统一状态接入属于后续流程；清洁度已在 DishState 实现，奖励算法尚未加入本层。

### 清洁度读取接口（第 4 步）

清洁度由当前区域数据即时推导，不另存可变进度百分比。各区域的剩余量在计算时限制于 0 与自身初始量之间，再按剩余总量与初始总量计算；无初始污渍时为 100%，极小的正初始量仍按非零处理。读取不修改区域数据，泡沫量、泡沫权重和施液资格均不参与计算。

| DishState 接口 | 职责 |
| --- | --- |
| get_cleanliness | 返回 0～1 的实际清洁度，供规则及后续进度显示使用。 |
| get_cleanliness_percent | 返回四舍五入后的整数百分比，只供显示。 |
| meets_cleanliness_requirement | 将实际值与 REQUIRED_CLEANLINESS（0.95）直接比较，不以整数显示或近似相等判断。只代表清洁门槛，不包含槽位兼容、占用、距离或遮挡。 |

94.9%、95%、95.1% 的整数显示均为 95%，但只有后两者达标。后续放置预览、确认放置、Q 返回及完成统计应复用实际门槛；HUD 已显示目标名称，清洁度显示与完整放置逻辑尚未接入。

### 验证配置与脚本

| 文件 | 职责 |
| --- | --- |
| [plate-config-example.tres](../../Resources/Examples/plate-config-example.tres) | 验证用餐盘配置，引用现有模型，含正面残渣、正面油渍和背面油渍数据。 |
| [mug-config-example.tres](../../Resources/Examples/mug-config-example.tres) | 验证用马克杯配置，引用现有模型与杯内两类污渍数据。 |
| [layout-config-example.tres](../../Resources/Examples/layout-config-example.tres) | 验证用布局，包含 3 个托盘位及各 1 个盘、杯沥水位；不是全厨房槽位清单。 |
| [order-config-example.tres](../../Resources/Examples/order-config-example.tres) | 验证用两盘一杯条目，两件盘子共享同一份 DishConfig；点数 100 和首次额外点数 25 只用于检查配置隔离，不代表正式订单平衡。 |
| [Tools/verify_runtime_state.gd](../../Tools/verify_runtime_state.gd) | 构造多份运行状态，修改及删除其中一份的进度、泡沫、位置、占用、工具和集合内容，检查其他实例、新状态与源配置。成功输出 RUNTIME_STATE_OK、退出 0，失败报告原因并退出 1。 |
| [Tools/verify_cleanliness.gd](../../Tools/verify_cleanliness.gd) | 用内存配置检查加权清洁度、零污渍、越界与只读行为、泡沫独立、整数显示及实际 95% 门槛；不依赖模型加载。成功输出 CLEANLINESS_OK、退出 0，失败报告原因并退出 1。 |
| [Tools/verify_game_input.gd](../../Tools/verify_game_input.gd) | 独立 SubViewport 注入键鼠事件，检查 16 个映射、上下文分派、重复输入、移动与鼠标信号、HUD 布局及 GUI 消费；成功输出 GAME_INPUT_OK、退出 0，失败报告原因并退出 1。真实窗口捕获与失焦另作图形检查。 |
| [Tools/verify_player_movement.gd](../../Tools/verify_player_movement.gd) | 加载真实可玩场景，注入移动意图并运行物理帧，检查出生、相机、方向、斜向速度、30/120 Hz 物理频率、模式限制、碰撞和任务区通路；约 20 秒，成功输出 PLAYER_MOVEMENT_OK 并退出 0，失败退出 1。 |
| [Tools/verify_mouse_look.gd](../../Tools/verify_mouse_look.gd) | 加载真实可玩场景，注入鼠标及移动事件，检查水平转身、俯仰、模式锁定、恢复、边走边转、右键放大及中断复原；再单独载入旧展示器回归右键拖动和机位。成功输出 MOUSE_LOOK_OK 并退出 0，失败退出 1。 |
| [Tools/verify_dish_targeting.gd](../../Tools/verify_dish_targeting.gd) | 加载真实可玩场景，检查三件身份与姿态、盘杯表面法线及变换、孔洞和内腔、距离、放大不延长距离、真实遮挡、查询层、HUD 中断恢复及展示器隔离；只改内存，成功输出 DISH_TARGETING_OK 并退出 0，失败退出 1。 |
| [Tools/verify_kitchen_slots.gd](../../Tools/verify_kitchen_slots.gd) | 检查 13 位配置、完整姿态及独立占用；同时放入正式盘杯检查网格边线与环境及其他餐具相交、最低处承托，再测临时位识别、中断恢复、盘杯施液瞄准意图与展示器隔离。只改内存，成功输出 KITCHEN_SLOTS_OK 并退出 0，失败退出 1。 |

上述 11 个数据类与七份验证脚本各有同名 .gd.uid，保存 Godot 稳定资源标识，随源码提交；[verify_mouse_look.gd.uid](../../Tools/verify_mouse_look.gd.uid)、[verify_dish_targeting.gd.uid](../../Tools/verify_dish_targeting.gd.uid)、[verify_kitchen_slots.gd.uid](../../Tools/verify_kitchen_slots.gd.uid) 分别对应观察、盘杯和槽位验证。Examples 验证用 .tres 不被主场景加载，正式 kitchen-layout.tres 已由 KitchenSlots 加载；先导入新增类型，再按 [progress.md](progress.md) 重跑验证。

## 总场景组装和截图工具

| 文件 | 输入、输出与职责 |
| --- | --- |
| [Tools/build_kitchen_scene.py](../../Tools/build_kitchen_scene.py) | 通过 Blender 读取灰盒和已有独立 .blend，保留房间结构、追加正式道具并按槽位摆餐具；输出 Assets/Scenes/kitchen-room-shell.glb、Assets/Scenes/kitchen-demo.blend 和四张 Blender 场景预览。它不生成 Godot 主场景。 |
| [Tools/build_kitchen_demo.gd](../../Tools/build_kitchen_demo.gd) | 在 Godot 资源导入后加载独立 GLB，按槽位完整变换摆放餐具，创建灯光、相机及查看提示并绑定浏览脚本，覆盖 Scenes/kitchen-demo.tscn。 |
| [Tools/capture_kitchen_demo.gd](../../Tools/capture_kitchen_demo.gd) | 在图形模式实例化现有展示场景，调用两个预设视角，覆盖 Docs/scenes/kitchen-demo/godot-player.png 和 godot-overview.png；不重建场景，不支持无头截图。 |

生成依赖按“独立资产源文件及导出 → Blender 总场景与房间壳 → Godot 导入 → Godot 场景组装 → 运行或截图”理解。只改独立 GLB 后可重新导入该资源；若槽位、节点名或摆放变化，还需同步组装逻辑。不要假定修改 Blender 总场景会自动改变 Godot 中的独立实例。

现有三个总场景工具不覆盖 kitchen-game.tscn、game-hud.tscn、player.tscn、kitchen-walk-collision.tscn、kitchen-slots.tscn、盘杯封装、正式布局配置、项目配置或新增运行脚本。可玩入口会继承重建后的布局；若生成器改变尺寸、定位节点或路径，须同时核对步行代理、出生点、注册路径、临时位承托及两个入口。

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
| [plate-standard.blend](../../Assets/Dishes/plate-standard.blend)、[plate-standard.glb](../../Assets/Dishes/plate-standard.glb) | 标准餐盘源模型和运行导入资产，由原展示器与可玩盘子场景共享；第 8 步未改模型。 |
| [mug-standard.blend](../../Assets/Dishes/mug-standard.blend)、[mug-standard.glb](../../Assets/Dishes/mug-standard.glb) | 标准马克杯源模型和运行导入资产，由展示器与可玩杯子场景共享，保留杯内与杯柄形状；第 8 步未改模型。 |
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
| [implementation-plan.md](implementation-plan.md) | 62 个实施步骤与验证条件，第 1～9 步及追加右键放大已通过，第 10 步未开始。 |
| [progress.md](progress.md) | 实际完成记录、测试执行者及来源、当前状态与后续衔接。 |
| [architecture.md](architecture.md) | 当前文件职责、依赖和重建边界；新增或改变职责时更新。 |
| [Docs/README.md](../README.md) | 文档导航，连接 memory-bank、资产说明、场景说明与参考图。 |
| [Docs/kitchen-asset-plan.md](../kitchen-asset-plan.md) | 资产制作范围与交付进度，包括原操作区灰盒说明。 |
| [厨房场景说明](../scenes/kitchen-demo/kitchen-demo.md) | 现有展示场景的打开方式、位置、布局、重建步骤与历史验证。 |
| [可玩入口说明](../scenes/kitchen-game/kitchen-game.md) | F5/F6 使用区别、生成边界，以及准星名称、盘杯与临时位识别、槽位注册、菜单、WASD、鼠标、右键放大和碰撞验证方法。 |
| [餐盘说明](../assets/plate-standard/plate-standard.md)、[马克杯说明](../assets/mug-standard/mug-standard.md) | 对应餐具尺寸、原点、节点和资产接入说明。 |
| [海绵说明](../assets/sponge-standard/sponge-standard.md)、[泵瓶说明](../assets/soap-dispenser/soap-dispenser.md) | 工具结构、动画或形态、定位、材质与历史预览。 |
| [水槽说明](../assets/sink-countertop/sink-countertop.md)、[龙头说明](../assets/faucet-pullout/faucet-pullout.md) | 安装、开孔、活动部件、喷嘴及软管接入限制。 |
| [架与托盘说明](../assets/rack-and-tray/rack-and-tray.md)、[夹板说明](../assets/order-clipboard/order-clipboard.md) | 槽位、兼容几何、纸面和安装说明。 |
| Docs/assets 中的预览 PNG | 对应生成器输出的模型与操作姿态图，供视觉对照，不是运行状态证明。 |
| Docs/scenes/kitchen-demo 下的厨房预览 PNG | kitchen-demo- 前缀为 Blender 预览，godot- 前缀为 Godot 图形模式截图；生成脚本会覆盖对应文件。 |
| Docs/references 中的 PNG | 美术和布局参考，不是场景生成输入或玩法配置。 |
| [Docs/.gdignore](../.gdignore) | 将文档及预览目录排除在 Godot 资源导入之外。 |

## 已确认的架构洞察

1. **展示输入与玩家控制分别接入。** 浏览脚本用数字键切机位、右键拖相机；可玩入口用独立 GameInput 分派动作，并已接入行走、鼠标直接看向和临时放大，继续清除根浏览脚本并隐藏展示提示。两个入口的鼠标行为分别回归，不把展示器操作改成游戏操作。
2. **场景生成器拥有其输出。** Godot 组装脚本会覆盖主展示场景，Blender 组装脚本会覆盖总场景、房间壳与预览。直接改生成结果而不处理生成器，重建会丢失改动；独立可玩逻辑应避开这些覆盖路径。
3. **定位节点描述姿态，状态记录占用。** 托盘和架位提供完整餐具根变换，不能再加半高；第 9 步通过注册器关联配置、节点和独立 SlotState。盆底表面参考另行校准为临时根姿态，识别表面点与放置根点不混用；实际吸附和完整判定仍在后续。
4. **共享配置不承载可变进度。** 同一 DishConfig 可以服务多件盘子；每件区域状态、每次订单字典及 ToolState 均独立创建。第 3 步验证包含数值修改和删除集合元素，避免只检查顶层对象不同而遗漏嵌套数据共享。
5. **可见几何与步行碰撞分别维护。** 第 6 步使用玩家专用代理验证通路，第 8 步另按实际网格生成交互表面并加入距离判断。碰撞尺寸、出生点和固定盘杯姿态对应当前布局，资产或生成布局变化后需分别核对。
6. **资产动画不等于玩法状态。** 泵头动画、喷嘴定位、软管展示形态和海绵形态均可复用，但缺少运行时供水、干湿、施液、清洁及评分判定。历史资产说明中的接液或固定站位方案若与当前设计冲突，玩法以 memory-bank 的现行设计为准，几何约定仍须遵守。
7. **性能目标与当前配置分开记录。** 开发机 1080p 默认画质、稳定 60 FPS 是后续测量目标；现有窗口配置和第 1 步展示验收不能证明该目标或最低配置已经满足。
8. **显示值与规则值分开。** 清洁度直接从区域状态计算，四舍五入只用于显示；实际 95% 门槛独立于泡沫及持有状态。清洁度达标不等于完整入架资格，后续槽位规则还需组合距离、兼容、占用和遮挡等条件。
9. **区域边界在汇总前处理。** 分别限制每个区域的剩余量，避免一处负值抵消另一处污渍；计算时限制范围但不改写进度。污渍初始量是清洁度权重，foam_weight 仅留给泡沫汇总，不能混用。
10. **输入意图与执行结果分开。** GameInput 只决定操作意图，目标需经世界查询筛选，消费者仍须验证并执行。PlayerController 已读取分派后的向量，后续扩展不能用全局按键轮询绕过 UI、近距离或过渡限制。
11. **界面消费与持续输入都要处理。** _unhandled_input 避免按钮点击落到场景，模式切换另清除按住状态并发送停止通知；只隐藏菜单或只释放鼠标不足以结束已启动的工具使用。独立输入验证通过真实 GUI 消费检查这条边界，窗口捕获仍由图形验收确认。
12. **身体阻挡与表面命中分层。** 玩家使用层 2、步行代理使用层 5；第 8 步查询掩码 5 只检查餐具层 1 与环境层 3，防止整柜代理封住水槽。真实环境和前景餐具仍阻挡目标，不能为方便拾取而只检测餐具层。
13. **临时镜头效果需要中断复原。** 右键放大缓存按下前的 FOV，由输入层统一在松开或模式中断时发送停止意图。镜头控制器恢复原值，不能用固定默认值覆盖当前视野，也不能让重复按下污染缓存；餐具拉近仍是另一套位置操作。
14. **小模型需要验证短射线。** 在米制尺寸下，杯底、杯壁和杯柄的细面曾发生短射线漏检。碰撞内部放大坐标并施加倒数等比缩放后，原位置和几何不变且专项通过；改表面生成方式时应保留内外表面、短射线和变换测试，不能用加长测试射线掩盖近距问题。
15. **识别对象与执行动作分开。** 盘杯身份、13 位注册和临时位识别已经接入，实际拿取、完整放置及订单仍未实现。目标缓存只供反馈，执行动作前重新校验；搬运预览和工具扩展需统一上下文更新，避免相互清除目标。
16. **占用只能有一份权威记录。** 当前注册器每场景新建 SlotState，配置只共享布局。接入 OrderState 时必须共用或明确替换这套状态；初始槽位 ID 与当前所在位置、最近一次拿起的返回位置是不同概念。
17. **验证所有槽位的实际承托。** 数量和标记姿态正确还不足以证明可放置。槽位专项用正式盘杯同时覆盖 13 位，检查最低处承托及网格边线相交；模型或盆底改变时重测，静态通过不替代后续移动轨迹与确认时的空间检查。
