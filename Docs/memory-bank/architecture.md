# 项目架构与文件职责

> 更新日期：2026-11-27｜第 1～15 步及 G 物理松手、无预览等追加需求已由用户验收

## 当前实现边界

项目默认入口现为 [project.godot](../../project.godot)加载 [kitchen-game.tscn](../../Scenes/kitchen-game.tscn)。此场景继承 [kitchen-demo.tscn](../../Scenes/kitchen-demo.tscn)的布局，在自身根节点覆盖为空脚本并隐藏 ViewerOverlay，复用已有 GLB 与灯光而不启用展示输入。第 2 步入口隔离于 2026-11-23 通过验收，第 6 步改由独立玩家相机查看场景。

单独打开 kitchen-demo.tscn 按 F6，仍由 [kitchen_viewer.gd](../../Scripts/kitchen_viewer.gd)控制展示。两个入口分别实例化节点，原展示场景与浏览脚本未改；场景不在运行时打开 Blender 总场景或执行建模脚本。

第 3～13 步建立数据、清洁度、输入、双持与放置基础。第 14 步于 2026-11-26 验收 G 物理松手和无预览，普通 Q 返回已按用户要求取消。第 15 步 F 场景覆盖与路径／返回修复于 2026-11-27 验收。生产 DishState／OrderState 尚未接入，未知清洁度不入架；下一项为第 16 步普通旋转及滚轮边界。

## 入口、运行文件与元数据

| 文件 | 当前作用 |
| --- | --- |
| [project.godot](../../project.godot) | 项目配置，F5 默认启动 kitchen-game.tscn；保存 18 个 game_ 前缀输入映射，其中 game_rotate_close 为沉浸中键旋转、game_drop 为 G 松手；关闭 .blend 自动导入，沿用 Compatibility、1600 × 900 视口和 1280 × 720 窗口覆盖。 |
| [Scenes/kitchen-game.tscn](../../Scenes/kitchen-game.tscn) | 手工维护的可玩入口，组装输入、HUD、玩家、步行碰撞、PlayableDishes、SurfaceCollision、WorldCleaningTools、KitchenSlots、DishTargeting 与 DishCarry；PlacementPreview 已移除。隐藏原展示餐具，由注册器读取模型定位点摆放初始两盘一杯；保持相机与展示输入隔离。 |
| [Scenes/player.tscn](../../Scenes/player.tscn) | 手工维护的 CharacterBody3D 玩家，包含胶囊、眼高 1.62 m 的 ViewCamera，以及其下 CarryAnchor、RightCarryAnchor、CleanAnchor 三个锚点，挂载 PlayerController。 |
| [Scenes/kitchen-walk-collision.tscn](../../Scenes/kitchen-walk-collision.tscn) | 手工维护的 StaticBody3D，六个碰撞形状限制地面、柜体与台面、后墙及边界；仅供玩家行走阻挡，不是交互表面。 |
| [Scripts/Player/player_controller.gd](../../Scripts/Player/player_controller.gd) | 处理 GameInput 的观察和临时放大意图：玩家水平转向、相机俯仰限制、捕获恢复防突跳及 FOV 缓存/复原；原物理回调继续处理水平行走、重力和滑动碰撞。 |
| [Scenes/game-hud.tscn](../../Scenes/game-hud.tscn) | 手工 CanvasLayer：中央准星、TargetName、左右手 HandStatus、操作 HandHint、菜单与继续按钮；PlacementHint 已移除，标签不拦截输入，独立于展示器提示层。 |
| [Scripts/Input/game_input.gd](../../Scripts/Input/game_input.gd) | 继承 Node 的输入分派器；处理未被 UI 消费的事件，按上下文发出动作意图，管理按住状态和鼠标模式；普通持工具左键持续使用、E 按目标与持有分派，沉浸中键独立旋转。 |
| [Scripts/UI/game_hud.gd](../../Scripts/UI/game_hud.gd) | 绑定输入、餐具／架位／工具目标与持物信号，显示左右手、“当前”、G 提示及短时反馈；已移除预览标签和 preview_path，独立输入测试可不绑定目标或持物路径。 |
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

原展示场景中 Models 保存 8 个环境或道具实例，Dishes 保存 5 盘、2 杯的展示实例。可玩入口隐藏全部 Dishes，避免架内装饰占据任务位置；PlayableDishes 中两盘一杯由注册器放入托盘，沥水架与水槽初始为空。当前仍是固定三件布置，未绑定生产订单。原展示器相机为根 ViewCamera，提示位于 ViewerOverlay；可玩入口停用根相机，实际使用 Player/ViewCamera，重命名时须区分两个入口。

## 游戏输入与基础界面（第 5 步起）

只有可玩入口实例化 GameInput 和 GameHUD。输入通过 _unhandled_input 接入，GUI 优先消费事件；不使用全局按键轮询。现有 18 个映射，新增 G 的 game_drop；Q/E 在沉浸模式复用为旋转轴，普通 Q 无返回意图。

| GameInput 接口或状态 | 当前职责 |
| --- | --- |
| set_context、mode_changed | 同步 EMPTY、CARRYING、CLOSE_UP、SOAP_BOTTLE、TRANSITION，以及目标与工具。持有模式或工具改变清除旧使用；目标改变通常结束主操作，但普通模式已按住的 use_tool 可跨目标保留，实际接触每帧重查。 |
| command_requested | 输入意图，不等于动作成功；DishCarry 接入拿取、普通／沉浸 use_tool、F、return_tool 及普通 1／2 的 select_left_dish／select_right_dish。drop_dish 接入 G 松手及架位确认，已移除 place_dish／return_dish；泵压、龙头等未实现意图仍不执行玩法。 |
| get_movement_vector、movement_changed | 归一化移动；界面、沉浸及过渡返回零，PlayerController 按物理时间读取。 |
| look_requested | 普通状态驱动 PlayerController 的直接观察；沉浸和过渡不转镜头。 |
| rotation_requested | 沉浸中键拖动的像素位移；DishCarry 当前只在沉浸时旋转餐具。普通持餐具右键仍只拦截观察并发意图，完整旋转留在第 16 步。 |
| get_dish_rotation_axis、rotation_axis_changed | 沉浸时 Q 为左、E 为右，同时按住抵消；释放、界面和模式切换清零。DishCarry 默认按每秒 90°、物理 delta 旋转。 |
| tool_cursor_moved | 沉浸中持续提供画面坐标；中键拖动时也更新光标，让自由工具跟随而不吸附餐具。 |
| carrying_dish、selected_tool | DishCarry 按真实持物同步；区分只持工具的观察放大与持餐具的旋转意图。selected_tool 在当前场景反映实际已拿工具，不代表远程生成模型。 |

普通未持工具时左键拿餐具或工具，E 也可按目标拿取；持工具时左键持续 use_tool，不分派拾取或放置。持工具、未持餐具且瞄准餐具时 E 先结束使用并拿到空手，其他持工具情形尝试归回原工具，距离或遮挡不合格则保持持有。普通持餐具时复用原 1／2 映射选择左右餐具，不新增映射；其他上下文及 3 保留原意图，均不切换或收起实体工具。沉浸中键及 Q/E 只旋转，只有 F 返回。泵瓶、龙头、订单等未来世界目标须保持上下文动作单一。

右键 game_rotate：普通空手、只持工具或持瓶时发 zoom_view，普通持餐具时发 rotate_dish 意图；中键 game_rotate_close 仅在沉浸时发 rotate_dish。沉浸右键不旋转、不放大，也不终止工具使用；其释放不能结束仍按住的中键旋转。界面、失焦或持有模式切换会结束放大和持续操作；只更新目标不取消放大。

GameHUD 普通状态显示中央准星及目标名称，沉浸与过渡隐藏准星、保留手位和操作提示。Esc 显示菜单并释放鼠标，继续后普通状态捕获、沉浸保持光标可见。当前只阻止输入，不冻结场景树、过渡或重力；完整暂停留在第 18 步。

## 玩家行走与碰撞（第 6 步）

PlayerController 每个物理帧读取过滤后的输入，将玩家相机的前向投影到 XZ 平面并归一化，再得到正交的左右方向；水平速度上限为 1.6 m/s。相机俯仰不参与垂直移动，重力按时间累积，move_and_slide 处理实际位移和碰撞。第 7 步已接入观察信号，行走方向随玩家的当前水平观察朝向变化。

| 配置 | 当前值与用途 |
| --- | --- |
| 出生位置 | kitchen-game.tscn 中 Player 的世界位置为（0，0.03，1.18），略高于地面后落地。 |
| 身体与相机 | 胶囊半径 0.22 m、高 1.75 m，根节点代表脚底；相机局部眼高 1.62 m，初始俯角约 26.37°。 |
| 玩家碰撞 | Player 位于物理层 2，掩码为 16；WalkCollision 位于物理层 5（位值 16），掩码为 0。 |
| 步行代理 | 地面 5×5 m，顶部为世界 Y=0；柜体与台面合用箱体，后墙及侧面、前方边界限制行走范围。尺寸对应当前房间布局，资产变化后需重新核对。 |
| 输入限制 | 菜单、近距离、过渡与失焦时水平输入为零；重力仍运行，完整冻结留在暂停步骤。双手持物和沉浸已在第 10 步接入；独占持瓶仍由验证脚本构造。 |

步行代理与交互碰撞分别维护。整柜箱体阻止身体进入操作台下方，但不描述水槽内腔或盘杯表面；第 8 步真实目标射线已排除玩家层 2 和步行代理层 5，另检测餐具层 1 与环境表面层 3。新增表面均不进入玩家的行走掩码。

## 鼠标观察与临时放大（第 7 步）

PlayerController 在就绪时连接观察、模式及动作信号。水平位移改变玩家根节点的 Y 轴朝向，并将角度循环归一化，允许连续转身；垂直位移只改变相机 X 轴俯仰，范围为 ±80°，不产生侧倾或位置变化。默认 look_sensitivity 为每像素 0.0025 弧度，鼠标位移不再乘帧时间。

_look_enabled 依据界面和持有模式控制观察。菜单、近距离或过渡导致允许状态变化时重新设置首包丢弃标志；恢复捕获后的首个鼠标位移被忽略，旧增量不累计。单独更新目标、工具或在允许观察的持有模式之间切换，不反复丢弃鼠标输入。持餐具右键旋转由输入分派层拦截观察信号。

zoom_view 按下时缓存当前相机 FOV 并收窄视野，默认从 53.7° 变为 35°；重复按下不覆盖缓存。松开或收到取消意图时恢复缓存原值。放大期间继续允许观察和行走，不修改玩家或相机位置。它与已接入的 F 拉近餐具分开；近距离滚轮调整仍待第 16 步实现。

实际运行默认空手，准星识别距离内餐具和清洗工具；普通持餐具时另可识别固定架位或水槽自由落点。双手持物与沉浸由真实交互进入，持瓶仍是测试构造的上下文。后续持物状态必须使用 set_context 同步，确保旧旋转、放大和按住输入被正确结束。

## 盘杯、真实表面与物理松手（第 8～14 步）

第 8～13 步建立身份、注册、双持、预览与静态落位；第 14 步按用户修正取消普通 Q 返回及所有落位预览，改为 G 物理松手。历史实现和验收范围保留在 [progress.md](progress.md)，本节描述当前代码。

| 文件／接口 | 当前职责 |
| --- | --- |
| [dish_body.gd](../../Scripts/Dishes/dish_body.gd) | 保留原 StaticBody3D 身份与真实查询三角面；REGISTERED／HELD／WORLD 位置类别；创建独立 motion_body 刚体与共享网格多凸体缓存。WORLD 时同步运动姿态，拿取时冻结，退出时清理独立运动体。 |
| [hand_item.gd](../../Scripts/Dishes/hand_item.gd) | 每手节点、实际来源类型／完整姿态／可选槽位、旋转、真实包围盒、安全搬运姿态与薄三角查询形状；旧底圈和叠放采样已删除。 |
| [mesh_surface_collision.gd](../../Scripts/Interaction/mesh_surface_collision.gd) | 从真实可见网格生成查询三角面，局部顶点乘 10、形状缩放 0.1，保持米制几何和短射线精度；不修改源 GLB 或封住孔洞。 |
| [dish_targeting.gd](../../Scripts/Interaction/dish_targeting.gd) | 世界准星范围 2 米；中央及四条偏移 0.1 mm 的平行射线取最近真实命中，处理 Jolt 共享顶点漏检。公开查询均重查并排除持物；仅架位有固定目标。 |
| [kitchen_slot_registry.gd](../../Scripts/Slots/kitchen_slot_registry.gd) | 每场景创建 3 个托盘初始点和 8 个架位的独立 SlotState，读取完整 marker 姿态、初始化占用；固定瞄准只选 DRAINING_RACK。旧水槽分类／支撑查询已移除。 |
| [dish_carry.gd](../../Scripts/Dishes/dish_carry.gd) | 两手拿取、来源与占用、selected_dish 手位、G 释放及架位提交、匹配状态引用、普通／沉浸工具、F、旋转、自由工具和 E 归回；不再执行普通 Q 返回或左键放置。 |
| [placement_rules.gd](../../Scripts/Slots/placement_rules.gd)、[placement_result.gd](../../Scripts/Slots/placement_result.gd) | 通过 check_placement → evaluate 检查注册姿态；同一真实空间函数检查松手位置。结果只读、不预留占用；旧 evaluate_surface、静态叠放高度求解与支撑依赖已删除。 |

### 碰撞、刚体与位置所有权

| 对象 | 层／掩码 | 作用 |
| --- | --- | --- |
| 原餐具查询身体 | 层 1，掩码 0 | 精确表面、杯内及杯柄孔；保留原查询 RID |
| 玩家／步行代理 | 层 2／层 5（值 16）；玩家掩码 16 | 只负责行走，粗柜体不参与餐具运动 |
| 环境／清洗工具表面 | 层 3（4）／层 4（8），掩码 0 | 使用真实几何，随所属身体姿态变化 |
| 餐具运动体 | 层 6（32），WORLD 掩码 46 | 接触环境 4、工具 8、玩家 2、其他运动体 32；排除查询身体 1 和粗柜体 16 |
| 持有餐具运动体 | 层／掩码 0，冻结 | 由原双手安全姿态控制，不继续下落 |
| 注册餐具运动体 | 层 32，掩码 0，冻结 | 保持完整标记姿态，可承受其他自由物件碰撞 |

Godot 4.7.2 使用内置 Jolt；Compatibility 渲染保持。project.godot 设置 penetration_slop=0.0005 m、speculative_contact_distance=0.002 m、position_steps=4，适配薄陶瓷。每个网格最多 32 个凸体、分解分辨率 100000、max_concavity=0.001、margin=0.0002 m，按共享 Mesh 缓存只读形状和局部姿态；专项验证物理杯口和杯柄孔均开放。

松手时原 DishBody 保留在 PlayableDishes，motion_body 成为同一世界父节点下的独立刚体，避免继承跟随节点的运动通知；原身体每物理帧跟随其完整变换。拿取冻结并收回刚体，继续移动同一原节点。额外刚体没有餐具身份，不能计作新餐具；未来订单重置需要清理两者，不仅移除可见网格。自由位置为 WORLD 与原节点姿态，不注册固定水槽槽位，也不保存静态支撑身份或上层拿取锁。

### G 松手与固定架位

GameInput 的 game_drop 绑定物理 G，普通持餐具时发出一次 drop_dish 并结束旧左键使用；按住或键盘重复不连发。普通 Q 无动作；沉浸中的 Q/E 仍旋转。没有 PlacementPreview 节点、脚本、UID、PlacementHint 标签或对应信号；PLACEMENT_SURFACE／STACKABLE_DISH 路由已移除，左键只拿取或使用工具。

DishCarry._drop_dish 先重新查询当前固定架位。有效架位通过共用判定后，_commit_placement 冻结原餐具并吸附完整姿态，同步唯一占用和匹配状态，仅清空选中手位。架位要求兼容、完整尺寸（含杯柄）、空位、来源已释放、当前 2 米范围、视锥／真实遮挡和真实最终空间。只有 DRAINING_RACK 检查实际 0.95，未知／错配状态不授权，泡沫不拒绝；托盘点不作为手动固定目标。

其余位置重查第一处真实命中，按当前餐具角度与包围盒，沿表面法线留出约 6 cm 释放余量；没有命中时在镜头前 0.8 m 松手。检查释放空间，不计算最终承托姿态，不限制为水槽内部或浅坡，不返回来源，也不自动寻找其他落点。成功后设置 WORLD、清空匹配状态的 current_slot_id／is_held，再由物理模拟下落、倾倒、滑动或堆放；被挡时保留持有并提示。同物理帧保护防止重复 G 释放另一手。

DishCarry.dish_states 是可选权威状态引用入口，生产仍为空；状态同步只改当前位置／持有，不改污渍、泡沫或施液。架位资格在专项中注入已知数据验证，不默认餐具洗净。正式订单接入仍须共用或明确替换注册器的 SlotState，不能各自维护占用。

### 双持、沉浸与工具

拿取前检查空手、组合、2 米最近真实表面及安全搬运空间。REGISTERED 从 find_occupied_slot 读取唯一来源，WORLD 允许没有 SlotState；成功后解除注册占用、冻结运动体并改为 HELD。HandItem 保留实际 origin_kind、origin_pose、origin_slot_id，initial_slot_id 仅初始化，不用于返回。held_dish／origin_slot_id 只是第一件兼容读取，G 必须使用 selected_dish／get_selected_dish_item。

左右搬运锚点为相机局部（-0.28，-0.22，-0.78）和（0.28，-0.22，-0.78）米，清洗锚点（0，-0.015，-0.45）。F 约 0.2 秒只移动同一餐具，不移动玩家、转相机或改 FOV。沉浸中键与 Q/E 旋转；闲置／离面／旋转后工具继续自由跟随，主动左键命中当前餐具才接触／瞄准。普通松开左键回工具手位；F 退出才恢复沉浸工具手位。普通右键旋转／滚轮边界待第 16 步。

第 15 步的 _transition_path_is_clear 使用保持当前餐具角度的包围盒与 cast_motion 检查平移路径，排除两手已持 RID；进入另保留清洗锚点周围的空间检查。退出须 _solve_pose 成功并通过路径检查才启动 Tween，受阻留在沉浸并提示，不使用旧 safe_pose。F 返回期间 _solve_pose 排除另一手自由工具，避免双方互挡到近镜头；普通搬运仍保留原有物品间避障，真实环境始终参与检查。过渡中忽略重复操作，菜单／失焦清除旧输入；菜单后完成进入时不 warp 光标。当前 Tween 与自由刚体仍可运行，冻结留给第 18 步。

世界工具包装发生在环境表面生成之后，删除原海绵／喷头碰撞再包装原模型，避免幽灵原位。普通工具目标实时查询，姿态检查近裁剪、真实空间和越沿接近路径；WORLD 餐具可使用水槽越沿路线。喷头距原位仍限 1.5 米。动态软管为 16 段圆柱，只缩放局部 Y；仍没有完整长度约束、避障或供水。接触反馈不代表实际清洗。

### 验证入口

| 脚本 | 当前范围与成功标识 |
| --- | --- |
| [verify_close_transition.gd](../../Tools/verify_close_transition.gd) | 40 组盘杯／工具／手位／站位朝向 F 往返，视角与状态保留、双向空间／路径、喷头原位范围、重复输入、进入／退出中断及正常手位返回；CLOSE_TRANSITION_OK |
| [verify_dish_drop.gd](../../Tools/verify_dish_drop.gd) | G 重力、盘杯在盆体／托盘／台面边缘／地面落下及再拿取、物理孔洞、来源／状态、双持、重复请求、阻止上下文、两工具及 F；DISH_DROP_OK |
| [verify_dish_placement.gd](../../Tools/verify_dish_placement.gd) | G 提交全部 8 架位、完整姿态／原身份／占用／再拿取，左键不放置、未知及实际门槛拒绝；DISH_PLACEMENT_OK |
| [verify_basin_stacking.gd](../../Tools/verify_basin_stacking.gd) | 两盘一杯真实重力／陶瓷碰撞、盆内交叠、无固定槽位与再次拿取；BASIN_STACKING_OK |
| [verify_placement_preview.gd](../../Tools/verify_placement_preview.gd) | 保留脚本名检查预览及绿／红标签已移除，瞄准不提交／预留、展示器隔离；PLACEMENT_PREVIEW_OK |
| [verify_placement_rules.gd](../../Tools/verify_placement_rules.gd) | 注册完整姿态、实际 95%／泡沫／未知状态、兼容／占用／空间／遮挡、只读与选中手位；PLACEMENT_RULES_OK |
| [verify_dish_carry.gd](../../Tools/verify_dish_carry.gd)、[verify_dual_wield.gd](../../Tools/verify_dual_wield.gd)、[verify_world_tool_use.gd](../../Tools/verify_world_tool_use.gd) | 原实例、双手、安全搬运、普通接触、F、旋转、自由工具、软管及中断；DISH_CARRY_OK／DUAL_WIELD_OK／WORLD_TOOL_USE_OK |

现有 16 份验证脚本、45 个唯一 GDScript UID、18 个输入映射。源码与 UID 一同提交，.godot 缓存和临时捕获／探针不入库。第 15 步实际执行新增专项及 7 项相关回归，另有导入、默认启动和图形检查；各步验收来源及预览见 [progress.md](progress.md)。

## 配置资源与独立运行状态

### 共享配置

Scripts/Data 的类型均继承 Resource，供 .tres 文件复用。它们描述初始数据与静态规则，运行中的清洁进度、施液、泡沫、占用和工具开关不得写入这些配置。

| 文件 | 职责 |
| --- | --- |
| [stain_region_config.gd](../../Scripts/Data/stain_region_config.gd) | 污渍区域 ID、残渣或油渍类型、初始量及泡沫汇总权重。 |
| [dish_config.gd](../../Scripts/Data/dish_config.gd) | 餐具类型、名称、共享模型与污渍区域配置数组。 |
| [slot_config.gd](../../Scripts/Data/slot_config.gd) | 槽位 ID、显示名称、待洗/临时/沥水类别、兼容餐具类型、maximum_dish_size 和所属 fixture_path；槽位 ID 对应 fixture 下的定位节点名。 |
| [kitchen_layout_config.gd](../../Scripts/Data/kitchen_layout_config.gd) | 厨房槽位配置集合，与具体订单内容分开。 |
| [order_item_config.gd](../../Scripts/Data/order_item_config.gd) | 单件任务餐具的实例 ID、餐具配置引用和初始槽位 ID。 |
| [order_config.gd](../../Scripts/Data/order_config.gd) | 订单 ID、名称、条目数组、基础点数及首次额外点数；未实现奖励发放。 |

第 3 步建立配置与状态结构，第 9 步解析定位与占用，第 11 步组合判定，第 12 步接入水槽自由预览并移除旧临时配置。目标识别与预览本身不构成确认授权，第 14 步由 G 释放原餐具为 WORLD 或同步提交架位占用；注册判定本身仍只读，预览已删除。

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

94.9%、95%、95.1% 的整数显示均为 95%，但只有后两者达标。第 11 步已在共用判定中使用该门槛，G 架位确认及未来完成统计继续复用；HUD 目前显示目标与选中手位，清洁度显示仍未接入，G 物理松手与架位确认已在第 14 步验收。

### 验证配置与脚本

| 文件 | 职责 |
| --- | --- |
| [plate-config-example.tres](../../Resources/Examples/plate-config-example.tres) | 验证用餐盘配置，引用现有模型，含正面残渣、正面油渍和背面油渍数据。 |
| [mug-config-example.tres](../../Resources/Examples/mug-config-example.tres) | 验证用马克杯配置，引用现有模型与杯内两类污渍数据。 |
| [layout-config-example.tres](../../Resources/Examples/layout-config-example.tres) | 验证用布局，包含 3 个托盘位及各 1 个盘、杯沥水位；不是全厨房槽位清单。 |
| [order-config-example.tres](../../Resources/Examples/order-config-example.tres) | 验证用两盘一杯条目，两件盘子共享同一份 DishConfig；点数 100 和首次额外点数 25 只用于检查配置隔离，不代表正式订单平衡。 |
| [Tools/verify_runtime_state.gd](../../Tools/verify_runtime_state.gd) | 构造多份运行状态，修改及删除其中一份的进度、泡沫、位置、占用、工具和集合内容，检查其他实例、新状态与源配置。成功输出 RUNTIME_STATE_OK、退出 0，失败报告原因并退出 1。 |
| [Tools/verify_cleanliness.gd](../../Tools/verify_cleanliness.gd) | 用内存配置检查加权清洁度、零污渍、越界与只读行为、泡沫独立、整数显示及实际 95% 门槛；不依赖模型加载。成功输出 CLEANLINESS_OK、退出 0，失败报告原因并退出 1。 |
| [Tools/verify_game_input.gd](../../Tools/verify_game_input.gd) | 独立 SubViewport 注入键鼠事件，检查 18 个映射、普通工具及 1／2 手位上下文、G、沉浸中键与右键隔离、重复输入、移动与鼠标信号、HUD 布局及 GUI 消费；成功输出 GAME_INPUT_OK、退出 0，失败报告原因并退出 1。真实窗口捕获与失焦另作图形检查。 |
| [Tools/verify_player_movement.gd](../../Tools/verify_player_movement.gd) | 加载真实可玩场景，注入移动意图并运行物理帧，检查出生、相机、方向、斜向速度、30/120 Hz 物理频率、模式限制、碰撞和任务区通路；约 20 秒，成功输出 PLAYER_MOVEMENT_OK 并退出 0，失败退出 1。 |
| [Tools/verify_mouse_look.gd](../../Tools/verify_mouse_look.gd) | 加载真实可玩场景，注入鼠标及移动事件，检查水平转身、俯仰、模式锁定、恢复、边走边转、右键放大及中断复原；再单独载入旧展示器回归右键拖动和机位。成功输出 MOUSE_LOOK_OK 并退出 0，失败退出 1。 |
| [Tools/verify_dish_targeting.gd](../../Tools/verify_dish_targeting.gd) | 加载真实可玩场景，检查三件身份与姿态、盘杯表面法线及变换、孔洞和内腔、距离、放大不延长距离、真实遮挡、查询层、HUD 中断恢复及展示器隔离；只改内存，成功输出 DISH_TARGETING_OK 并退出 0，失败退出 1。 |
| [Tools/verify_kitchen_slots.gd](../../Tools/verify_kitchen_slots.gd) | 检查 11 项正式配置、完整姿态、独立占用及同时摆放的网格边线／最低点承托，确认无固定水槽标记，保留施液瞄准意图与展示器隔离；只改内存，输出 KITCHEN_SLOTS_OK、退出 0，失败退出 1。 |

上述 11 个数据类与现有十六份验证脚本各有同名 .gd.uid，随源码提交；预览、放置、普通工具、双持／搬运及 F 切换专项见前节。Examples 验证用 .tres 不被主场景加载，正式 kitchen-layout.tres 已由 KitchenSlots 加载；先导入新增类型，再按 [progress.md](progress.md) 重跑验证。

## 总场景组装和截图工具

| 文件 | 输入、输出与职责 |
| --- | --- |
| [Tools/build_kitchen_scene.py](../../Tools/build_kitchen_scene.py) | 通过 Blender 读取灰盒和已有独立 .blend，保留房间结构、追加正式道具并按槽位摆餐具；输出 Assets/Scenes/kitchen-room-shell.glb、Assets/Scenes/kitchen-demo.blend 和四张 Blender 场景预览。它不生成 Godot 主场景。 |
| [Tools/build_kitchen_demo.gd](../../Tools/build_kitchen_demo.gd) | 在 Godot 资源导入后加载独立 GLB，按槽位完整变换摆放餐具，创建灯光、相机及查看提示并绑定浏览脚本，覆盖 Scenes/kitchen-demo.tscn。 |
| [Tools/capture_kitchen_demo.gd](../../Tools/capture_kitchen_demo.gd) | 在图形模式实例化现有展示场景，调用两个预设视角，覆盖 Docs/scenes/kitchen-demo/godot-player.png 和 godot-overview.png；不重建场景，不支持无头截图。 |

生成依赖按“独立资产源文件及导出 → Blender 总场景与房间壳 → Godot 导入 → Godot 场景组装 → 运行或截图”理解。只改独立 GLB 后可重新导入该资源；若槽位、节点名或摆放变化，还需同步组装逻辑。不要假定修改 Blender 总场景会自动改变 Godot 中的独立实例。

现有三个总场景工具不覆盖 kitchen-game.tscn、game-hud.tscn、player.tscn、kitchen-walk-collision.tscn、kitchen-slots.tscn、盘杯封装、正式布局配置、项目配置或新增运行脚本。若生成器改变尺寸、节点或路径，须同时核对步行代理、出生点、注册路径、水槽真实形状与自由支撑及两个入口。

## 独立资产生成器

以下 Python 文件通过 Blender 运行，生成相应源模型、GLB 与资产预览；不可用普通 Python 代替。生成器可能覆盖既有输出，手工修改须先保护并同步到对应生成逻辑。

| 文件 | 职责及主要资产 |
| --- | --- |
| [Tools/build_kitchen_graybox.py](../../Tools/build_kitchen_graybox.py) | 制作原操作区灰盒、房间与定位参考，输出 Assets/Graybox 下的 kitchen-workstation 源文件和 GLB；总场景组装从其 .blend 读取结构。 |
| [Tools/build_standard_plate.py](../../Tools/build_standard_plate.py) | 标准餐盘的几何、材质、定位与预览，输出 Assets/Dishes/plate-standard。 |
| [Tools/build_standard_mug.py](../../Tools/build_standard_mug.py) | 开口马克杯、杯柄、定位与预览，输出 Assets/Dishes/mug-standard。 |
| [Tools/build_standard_sponge.py](../../Tools/build_standard_sponge.py) | 海绵两层结构、材质烘焙、压缩表现资源和预览，输出 Assets/Tools/sponge-standard 及贴图；没有干湿玩法判定。 |
| [Tools/build_sink_countertop.py](../../Tools/build_sink_countertop.py) | 水槽、排水口和开孔台面的几何与安装参考，输出 Assets/Kitchen/sink-countertop。 |
| [Tools/build_faucet.py](../../Tools/build_faucet.py) | 龙头、可移动喷头、把手、出水定位与软管展示形态，输出 Assets/Kitchen/faucet-pullout；不实现供水开关或清洁，运行时视觉跟随由 WorldCleaningTools 接入。 |
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
| [faucet-pullout.blend](../../Assets/Kitchen/faucet-pullout.blend)、[faucet-pullout.glb](../../Assets/Kitchen/faucet-pullout.glb) | 龙头、喷头、把手和软管资源；可玩入口已接入动态视觉跟随，供水与软管避障仍待实现。 |
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
| [implementation-plan.md](implementation-plan.md) | 62 个实施步骤与验证条件，第 1～15 步及追加需求已通过；下一项第 16 步普通旋转／滚轮边界，第 17 步背景模糊待做。 |
| [progress.md](progress.md) | 实际完成记录、测试执行者及来源、当前状态与后续衔接。 |
| [architecture.md](architecture.md) | 当前文件职责、依赖和重建边界；新增或改变职责时更新。 |
| [Docs/README.md](../README.md) | 文档导航，连接 memory-bank、资产说明、场景说明与参考图。 |
| [Docs/kitchen-asset-plan.md](../kitchen-asset-plan.md) | 资产制作范围与交付进度，包括原操作区灰盒说明。 |
| [厨房场景说明](../scenes/kitchen-demo/kitchen-demo.md) | 现有展示场景的打开方式、位置、布局、重建步骤与历史验证。 |
| [可玩入口说明](../scenes/kitchen-game/kitchen-game.md) | F5/F6、当前操作、普通工具、F 沉浸及空间／中断验证、G 物理松手、固定架位、命令、验收来源与画面。 |
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
3. **固定架位与自由物理分别处理。** 架位读取完整 marker，不再加半高；其余位置由 G 释放后的重力与碰撞决定。自由运动不注册水槽槽位，不恢复旧自动返回或预览。
4. **共享配置不承载可变进度。** 同一 DishConfig 可以服务多件盘子；每件区域状态、每次订单字典及 ToolState 均独立创建。第 3 步验证包含数值修改和删除集合元素，避免只检查顶层对象不同而遗漏嵌套数据共享。
5. **可见几何与步行碰撞分别维护。** 第 6 步使用玩家专用代理验证通路，第 8 步另按实际网格生成交互表面并加入距离判断。碰撞尺寸、出生点和固定盘杯姿态对应当前布局，资产或生成布局变化后需分别核对。
6. **资产动画不等于玩法状态。** 泵头动画、喷嘴定位、软管展示形态和海绵形态均可复用，但缺少运行时供水、干湿、施液、清洁及评分判定。历史资产说明中的接液或固定站位方案若与当前设计冲突，玩法以 memory-bank 的现行设计为准，几何约定仍须遵守。
7. **性能目标与当前配置分开记录。** 开发机 1080p 默认画质、稳定 60 FPS 是后续测量目标；现有窗口配置和第 1 步展示验收不能证明该目标或最低配置已经满足。
8. **显示值与规则值分开。** 清洁度直接从区域状态计算，四舍五入只用于显示；实际 95% 门槛独立于泡沫及持有状态。清洁度达标不等于完整入架资格，后续槽位规则还需组合距离、兼容、占用和遮挡等条件。
9. **区域边界在汇总前处理。** 分别限制每个区域的剩余量，避免一处负值抵消另一处污渍；计算时限制范围但不改写进度。污渍初始量是清洁度权重，foam_weight 仅留给泡沫汇总，不能混用。
10. **输入意图与执行结果分开。** GameInput 只决定操作意图，目标需经世界查询筛选，消费者仍须验证并执行。PlayerController 已读取分派后的向量，后续扩展不能用全局按键轮询绕过 UI、近距离或过渡限制。
11. **界面消费与持续输入都要处理。** _unhandled_input 避免按钮点击落到场景，模式切换另清除按住状态并发送停止通知；只隐藏菜单或只释放鼠标不足以结束已启动的工具使用。独立输入验证通过真实 GUI 消费检查这条边界，窗口捕获仍由图形验收确认。
12. **身体阻挡与表面命中分层。** 玩家使用层 2、步行代理使用层 5；第 10 步世界查询掩码 13 检查餐具层 1、环境层 3 及工具层 4，防止整柜代理封住水槽。真实环境和前景餐具仍阻挡目标，不能为方便拾取而只检测餐具层。
13. **临时镜头效果需要中断复原。** 右键放大缓存按下前的 FOV，由输入层统一在松开或模式中断时发送停止意图。镜头控制器恢复原值，不能用固定默认值覆盖当前视野，也不能让重复按下污染缓存；餐具拉近仍是另一套位置操作。
14. **物理与交互都需验证小模型。** Jolt 的薄陶瓷接触容差和 10 倍查询形状分别验证；共享顶点采用 0.1 mm 射线足迹取最近真实面。不能用封闭杯口／杯柄或延长交互距离掩盖几何错误。
15. **识别对象与执行动作分开。** 目标名称不构成释放授权；G 执行时重查架位或真实表面与释放空间，不读旧预览。正式订单仍待接入。
16. **占用只能有一份权威记录。** 当前注册器每场景新建 SlotState，配置只共享布局。接入 OrderState 时必须共用或明确替换这套状态；初始槽位 ID 与当前所在位置、最近一次拿起的来源位置是不同概念。
17. **分别验证注册姿态和真实运动。** 架位专项检查完整姿态与占用，松手／堆放专项检查盘杯下落、碰撞、孔洞、落稳与再次拿取。几个静态样例不能代替物理专项或整场景性能验收。

18. **手位身份与操作角色分开。** 第一件左手、第二件右手，餐具可以在任一侧；F 从一餐具一工具组合识别角色，不交换实例。归回后不搬动另一件，双餐具放置按 1／2 显式选中手位，不使用第一件兼容读取。
19. **世界目标与沉浸表面各有所有者。** DishTargeting 只在世界模式写入目标，沉浸时 DishCarry 写入当前餐具的操作命中。两个组件互相清空上下文会造成持物时选不中或持续使用被递归取消。
20. **闲置移动与清洁资格分开。** 自由工具位置由画面光标决定，主动表面接触由左键和真实命中决定；恢复旋转或离开表面不应让工具自动吸附或回手位。contact_active 不能绕过后续干湿、供水、施液与区域判定。
21. **局部长度缩放不能写成世界轴缩放。** 软管圆柱先对齐管段，再只缩放局部 Y。世界 Y 缩放会将倾斜管段拉成长条；回归检查实际首尾连续及横截面，比只检查管段数量更能捕捉这个错误。
22. **接入可动工具时移走旧遮挡。** 原模型的环境碰撞是就绪快照，拿走可见头部还保留旧形状会产生幽灵遮挡；独立工具需连同真实形状移动，保留固定龙头和归位节点。
23. **按实际能力记录提前接入。** 用户追加需求提前实现了部分沉浸与工具操作，后续步骤仍保留尚缺的边界、模糊、暂停、供水和去污验收。用户通过当前原型不等于整个 MVP 或这些编号步骤全部完成。
24. **按住意图与本帧接触分别维护。** 普通模式扫过空处只停止本帧接触，保留按住以便重新命中；模式、工具、界面和失焦仍结束意图。沉浸维持原有目标清除规则，不能把普通模式的续用行为扩散到所有上下文。
25. **模式专用鼠标动作独立绑定。** game_rotate_close 只负责沉浸中键，game_rotate 保留普通右键职责；无关按钮的释放不能终止中键旋转，恢复菜单也不能恢复旧旋转或左键使用。
26. **判定结果不构成位置预留。** 可放置结果只描述查询时的快照；占用、遮挡或选中手位变化后必须重新调用，确认前不移动节点、不修改占用。未知清洁状态必须明确拒绝入架，不能用显示整数或默认完全清洁绕过真实门槛。
27. **切换的路径与返回结果都要验证。** F 终点有空间不代表途中无障碍；退出求解失败不能复用旧安全姿态。自由工具还可能挡住另一手的返回查询，需在 F 的手位恢复中排除双方，再对真实环境做避障。图形检查和工具移到不同侧后的完整往返用于捕捉这种互挡，普通搬运不因此移除物品间避障。
