# 厨房可玩入口

> 第 1～16 步及 G 物理松手、无预览、普通中键等追加需求｜2026-11-27｜用户已确认验证通过

打开 [project.godot](../../../project.godot)，导入后按 F5 运行 [kitchen-game.tscn](../../../Scenes/kitchen-game.tscn)。独立展示器仍可打开 [kitchen-demo.tscn](../../../Scenes/kitchen-demo.tscn) 按 F6，使用 1～4、R、右键拖动和失焦释放。

## 当前操作

| 输入／场景 | 当前行为 |
| --- | --- |
| WASD、鼠标 | 普通状态按镜头水平朝向行走与直接看向，胶囊阻挡柜体、地面和边界；沉浸／过渡停止行走和环顾 |
| 准星、左键／E（未持工具） | 2 米内第一处真实表面识别餐具／工具并拿取，包含地面餐具；先拿左手、第二件右手 |
| 1／2 | 普通持餐具时选择左／右餐具，HUD 标注“当前”；单件自动选中，第二件拿起保留选择；不换手、不切换或生成工具 |
| 中键拖动（普通持餐具） | 只旋转 1／2 当前餐具，相机和另一手角度不变；受真实空间和近裁剪限制，换手选择后需重新按中键 |
| G（普通持餐具） | 松开当前餐具：台面、托盘、地面和水槽统一由重力落下，可倾倒、滑落、自然叠放并再次拿取；只清空该手 |
| G（固定沥水架位） | 最新目标通过兼容／尺寸／占用／距离／可见性／空间／实际 95% 后吸附完整姿态；未知清洁度继续持有并提示 |
| 左键按住（普通持工具） | 操作准星所指已放餐具；海绵贴面持续擦动并压缩，喷头对准命中点，可边走边看。松开回手位，失效命中停止接触；尚无出水或去污 |
| E（普通持工具） | 有空手且对准餐具时拿取；其他持工具情形尝试原位归回，须距原位 1.5 米内且无遮挡，另一手不换边 |
| F | 一件餐具加工具进入／退出沉浸，约 0.2 秒只移动同一餐具；不移动玩家、转相机或改 FOV。重查终点与平移路径，返回空间不足时保留沉浸并提示，只有 F 返回搬运 |
| 鼠标、左键（沉浸） | 海绵／喷头自由跟随，离面或旋转后不吸附／收回；主动左键命中当前餐具才接触／瞄准，海绵还须移动鼠标 |
| 中键拖动、Q/E（沉浸） | 旋转餐具，按住 Q 左／E 右，松开停止，同时按住抵消；旋转时停止工具使用 |
| Q（普通状态） | 已取消返回／放下动作；不自动回来源或寻找水槽 |
| G（沉浸／过渡／菜单） | 不释放餐具 |
| 右键 | 普通空手、只持工具或测试构造的独占持瓶状态临时收窄 FOV，松开或中断复原；持餐具不旋转／放大，右键释放不结束中键旋转 |
| 滚轮（仅沉浸） | 上滚拉近、下滚推远，每格 0.02 m；盘 0.40～0.56 m、杯 0.36～0.52 m，默认 0.45 m；空间／路径受阻保持当前距离，F 往返保留所选值 |
| Esc、失焦 | 菜单释放鼠标并清除旧输入；继续后不恢复旧操作。目前不冻结场景树或自由刚体，完整暂停在第 18 步 |

画面没有放置幽灵或绿／红落位标签，左键不再放下或叠放。G 被挡住时继续持有并显示文字原因；同一物理帧重复请求不会放掉另一手。G 之前会结束旧左键工具使用。

托盘初始两盘一杯，水槽和架位为空。正式注册仍为 3 个托盘初始点和 8 个架位；托盘点不作为手动固定目标，水槽不恢复盘位／杯位。其余位置由松手后的物理模拟决定，来源只作记录，已移除静态支撑依赖及“先拿上层”的锁定规则。

第 15 步已覆盖不同站位、朝向及两种手位顺序的 F 往返。工具移到餐具两侧后退出，双方恢复安全搬运手位；F 返回求解排除另一手持物，真实环境仍参与避障，靠近架体时可缩短搬运距离。过渡中重复 F／G／E 不执行额外动作，沉浸中 Q/E 只旋转。进入／退出途中 Esc 或失焦后，当前切换可继续到目的模式，菜单光标不被拉回餐具中心；恢复不自动继续旧行走、使用或旋转，完整冻结仍在第 18 步。

第 16 步已统一普通和沉浸的中键拖动；沉浸另保留 Q/E。旋转可翻看盘背、杯内，靠近真实环境时停在安全角度；普通 G 和选择另一手会结束旧中键输入。滚轮只在沉浸调整餐具距离，普通、过渡和菜单不调距；旋转／调距不移动相机或改变 FOV，调整后需重新按左键使用工具。同次持有的 F 往返保留角度、所选距离及原手位。

## 当前边界与后续

正式 DishState／OrderState 尚未接入，DishCarry.dish_states 生产为空；架位按 G 时显示“无法确认餐具清洁度”，不会默认洗净。已知清洁状态只由验证夹具注入，实际 0.95 门槛保留，泡沫不拒绝。

当前餐具已使用 Jolt 重力、多凸体碰撞与旋转；物理杯口和杯柄保持开放。释放点在第一处真实表面前留出体积和约 6 cm 下落余量，未命中时位于镜头前 0.8 m；最终角度与位置不由静态落位求解器指定。边缘可能滑落或倾倒，这是松手后的物理行为。

第 16 步及普通中键修正已验收，下一项为第 17 步背景模糊，尚未开始；第 18 步完整暂停。供水、湿润、施液、去污、泡沫与订单仍未接入；喷头原位限制为 1.5 米，软管仍是简化曲线，没有完整长度约束或避障。

## 实现与文件边界

| 文件 | 当前作用 |
| --- | --- |
| [kitchen-game.tscn](../../../Scenes/kitchen-game.tscn)、[game-hud.tscn](../../../Scenes/game-hud.tscn) | 手工玩法入口、准星、手位与菜单；已移除 PlacementPreview 节点和 PlacementHint 标签，生成器不得覆盖 |
| [player.tscn](../../../Scenes/player.tscn) | 玩家胶囊、相机、左右搬运与清洗锚点 |
| [game_input.gd](../../../Scripts/Input/game_input.gd) | 18 个映射；两态中键旋转、沉浸滚轮、旧输入中断、G 一次松手、普通 Q 无返回、左键／E／F 上下文 |
| [dish_carry.gd](../../../Scripts/Dishes/dish_carry.gd) | 原实例双手、G 释放／架位、来源／占用／匹配状态、安全搬运与接触、F 路径及返回、旋转弧线／近裁剪、滚轮范围／平移路径 |
| [dish_body.gd](../../../Scripts/Dishes/dish_body.gd)、[mug.tscn](../../../Scenes/Dishes/mug.tscn) | 原身份与精确查询、独立 motion_body；导出盘默认近距范围，杯封装覆盖为自己的最小／最大距离 |
| [hand_item.gd](../../../Scripts/Dishes/hand_item.gd) | 每手来源、角度、close_distance、包围盒、安全姿态、真实薄三角空间检查；旧支撑采样已删除 |
| [dish_targeting.gd](../../../Scripts/Interaction/dish_targeting.gd)、[mesh_surface_collision.gd](../../../Scripts/Interaction/mesh_surface_collision.gd) | 2 米最近真实表面、0.1 mm 射线足迹、10 倍局部三角面与倒数缩放；持物排除、菜单清除与沉浸上下文隔离 |
| [kitchen_slot_registry.gd](../../../Scripts/Slots/kitchen_slot_registry.gd)、[placement_rules.gd](../../../Scripts/Slots/placement_rules.gd) | 11 项注册、独立占用、仅架位固定目标与共用资格；不再解算水槽自由最终姿态 |
| [cleaning_tool.gd](../../../Scripts/Tools/cleaning_tool.gd)、[world_cleaning_tools.gd](../../../Scripts/Tools/world_cleaning_tools.gd) | 原海绵／喷头包装与移除旧原位碰撞、归位检查、视觉软管 |
| [project.godot](../../../project.godot) | Godot 4.7.2 Compatibility、G 物理键及内置 Jolt；薄陶瓷接触容差 0.5 mm、预测接触 2 mm、4 次位置迭代 |

交互查询掩码仍为 13：餐具 1、环境 4、工具 8。独立运动体用层 6（32），WORLD 掩码 46，包含环境、工具、玩家及其他物理餐具，排除查询身体 1 和玩家柜体代理 16，避免把水槽封成实心。持有时运动体冻结且层／掩码为 0；架位冻结并保留物理层 32。

源 GLB、Blender、资产生成器和 F6 展示场景未修改。生成器仍只覆盖其展示／资产输出，不能覆盖手工玩法场景。完整职责见 [architecture.md](../../memory-bank/architecture.md)。

## 验证与来源

用户于 2026-11-27 确认第 16 步最终普通中键版本通过。AI 在本步运行 DISH_MANIPULATION_OK 与 7 项相关回归、导入和默认启动，并查看 6 张实际画面；中键修正后重跑专项、输入、镜头及图形，普通选中右手／F 返回两张已更新。各步实际执行范围和来源见 [progress.md](../../memory-bank/progress.md)。当前 17 份验证脚本、46 个唯一 GDScript UID、18 个输入映射。无头验证不代替真实窗口操作或性能测量。

在仓库根目录运行，均应退出 0 且无脚本错误：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script Tools/verify_dish_manipulation.gd
& $godotExe --headless --path . --script Tools/verify_close_transition.gd
& $godotExe --headless --path . --script Tools/verify_dual_wield.gd
& $godotExe --headless --path . --script Tools/verify_world_tool_use.gd
& $godotExe --headless --path . --script Tools/verify_dish_drop.gd
& $godotExe --headless --path . --script Tools/verify_dish_placement.gd
& $godotExe --headless --path . --script Tools/verify_basin_stacking.gd
& $godotExe --headless --path . --script Tools/verify_placement_preview.gd
& $godotExe --headless --path . --script Tools/verify_game_input.gd
& $godotExe --headless --path . --quit-after 60
```

对应成功标识为 DISH_MANIPULATION_OK、CLOSE_TRANSITION_OK、DUAL_WIELD_OK、WORLD_TOOL_USE_OK、DISH_DROP_OK、DISH_PLACEMENT_OK、BASIN_STACKING_OK、PLACEMENT_PREVIEW_OK、GAME_INPUT_OK。旋转／调距专项覆盖 8 组盘杯／工具／手位、上下限、真实表面及近裁剪、障碍、中断和 30／120 Hz Q/E；F 专项覆盖 40 组站位朝向往返。已知清洁状态仅夹具注入，生产仍为空。保留旧预览专项文件名，现检查“预览已移除”。其余脚本按同格式执行，本步实际执行范围见进度记录。

F5 手动检查：拿取盘／杯与海绵／喷头，从不同站位和朝向 F 往返；将工具移动到两侧后返回，检查相机、角度、原手位和正常搬运距离。切换途中连按 F／G，或 Esc／Alt+Tab 后明确继续，不误放、不自动续用旧输入；近距离 Q/E 仅旋转，F 才退出。无头模式不证明真实窗口捕获和 Alt+Tab 行为。

第 16 步另检查普通 1／2 当前手中键拖动，另一手与镜头不跟转；中键按住期间释放右键仍能旋转。F 后用滚轮反复到盘／杯各自上下限，翻面、倾斜并重新按左键接触，确认盘背和杯内可达、不穿近裁剪；F 往返保留角度和所选距离，Esc／失焦后不续用旧中键。

## 当前实际画面

2026-11-27 第 16 步及普通中键修正后的画面，均由 Godot Compatibility 图形模式捕获并查看；最近／最远指餐具根节点到相机的深度，餐具、工具与背景保持当前场景表现。

| 普通右手中键旋转 | F 返回搬运 |
| --- | --- |
| ![1／2选中右手杯子，中键只旋转当前餐具](step16-selected-right.png) | ![返回原手位，普通提示已统一为中键](step16-return-carry.png) |

| 餐盘最近 0.40 m：背面 | 餐盘最远 0.56 m：背面 |
| --- | --- |
| ![最近距离仍可完整查看餐盘背面](step16-plate-near-back.png) | ![最远距离保留同一背面角度和相机](step16-plate-far-back.png) |

| 杯子最近 0.36 m：杯内 | 杯子最远 0.52 m：倾斜 |
| --- | --- |
| ![最近距离杯口与杯内保持可见，喷头自由移动](step16-mug-near-inside.png) | ![最远距离可倾斜杯子，工具保持光标自由位置](step16-mug-far-tilted.png) |

2026-11-27 第 15 步 F 场景覆盖及修复后的画面，均由 Godot Compatibility 图形模式捕获并查看；镜头保持当前站位和朝向，背景模糊、供水与实际去污尚未实现。

| 左侧站位搬运 | 同站位切换中 |
| --- | --- |
| ![餐盘左手、海绵右手，保持当前观察方向](step15-carry-left.png) | ![同一餐盘在约0.2秒内移动到清洗锚点](step15-transition.png) |

| 沉浸餐盘 | F 返回原手位 |
| --- | --- |
| ![餐盘拉近，原相机与厨房背景不变](step15-close-plate.png) | ![餐盘与海绵恢复正常搬运距离和原手位](step15-return-left.png) |

![右侧朝向的沉浸杯子与左手喷头，自由工具不依赖杯子表面](step15-close-mug.png)

2026-11-26 第 14 步最终 G 物理松手画面，均由 Godot 图形模式捕获并查看；没有落位幽灵、绿／红标签、供水或去污。

| 松手前 | 松手后下落中 |
| --- | --- |
| ![手位餐盘与G松手提示，无放置幽灵](step14-free-carry.png) | ![餐盘在水槽内自然下落](step14-free-falling.png) |

| 盆内落稳 | 两盘一杯自然堆放 |
| --- | --- |
| ![原餐盘靠重力在盆内落稳](step14-free-basin.png) | ![两盘一杯由真实陶瓷碰撞自然叠放](step14-free-stack.png) |

![地面餐具可由2米目标查询识别并再次拿取](step14-free-floor.png)

## 历史画面

以下第 11～13 步画面保留当时操作、预览及静态叠放阶段的验收记录；现行操作以本页上方 G 物理松手为准。

2026-11-26 第 13 步及交叠追加需求最终画面：两盘一杯保留各自身份与实际厚度，槽内自由落点无固定标记。以下由 Godot 图形模式捕获并查看，未展示供水或去污。

| 叠放预览 | 确认后的实际原模型 |
| --- | --- |
| ![餐盘上方绿色叠放预览](step13-stack-preview.png) | ![两盘与杯子在水槽内交叠放置](step13-stack-placed.png) |

| 下层拿取受阻 | 从上层拿取 |
| --- | --- |
| ![下层仍支撑上层时提示先拿走上方餐具](step13-stack-lower-pickup.png) | ![取回上方马克杯并保留其来源](step13-stack-top-pickup.png) |

下列为第 13 步核心确认实现阶段画面，早于叠放追加版的 HUD 提示；现行输入以本页操作表为准。架位画面由专项注入匹配实例的已知 95% 清洁状态，正式玩法仍缺少清洁状态，不会默认授权入架。

| 水槽实际放置 | 普通工具接触已放餐具 |
| --- | --- |
| ![餐盘已实际放到水槽自由位置](step13-free-placed.png) | ![普通海绵接触水槽内已放餐盘](step13-cleaning-placed.png) |

| 再次拿取原模型 | 已知清洁状态的架位确认夹具 |
| --- | --- |
| ![重新拿起水槽原餐盘](step13-repicked.png) | ![专项注入已知95%状态后完成架位放置](step13-rack-placed.png) |

以下为历史阶段画面。2026-11-26 第 12 步：水槽自由落点、盘杯共用区域和无效位置原因。旧盘位／杯位标记已移除；下图幽灵仅作预览，实际放置尚未实现。

| 餐盘自由预览 | 马克杯自由预览 |
| --- | --- |
| ![水槽自由选择餐盘落点](step12-free-plate.png) | ![同一区域预览马克杯及杯柄](step12-free-mug.png) |

| 槽壁空间不足 | 固定架位、未知清洁度 |
| --- | --- |
| ![靠近槽壁时红色提示空间不足](step12-free-blocked.png) | ![杯架保留倒扣姿态且未知清洁度拒绝入架](step12-free-rack.png) |

2026-11-26 第 11 步手位选择预览：左手餐盘、右手马克杯，按 2 后右手名称显示“当前”。该画面只证明手位选择与 HUD，实际放下仍未实现。

![第 11 步按 2 选中右手马克杯](step11-hand-selection.png)

2026-11-26 普通模式操作预览，使用 Godot 图形模式渲染并查看。海绵贴面擦动、喷头对准目标，尚无供水或去污；软管仍可能穿过餐具。沉浸现用中键旋转，下面保留的 2026-11-24 沉浸截图属于历史画面，其旧右键提示以当前操作表为准。

| 普通海绵操作 | 普通喷头瞄准 |
| --- | --- |
| ![普通模式海绵贴合已放置餐盘](world-tool-sponge.png) | ![普通模式喷头对准已放置餐盘](world-tool-sprayer.png) |

以下为 2026-11-24 用实际 Godot 图形模式渲染并查看的操作原型。没有背景模糊、水流或污渍，软管避障仍未完成；这些截图不证明整单清洗已可玩。

| 双手搬运 | 海绵自由移动 | 喷头自由移动 |
| --- | --- | --- |
| ![餐具左手、喷头右手](dual-carry.png) | ![海绵移到餐盘外仍可见](immersive-sponge.png) | ![喷头移到餐盘外且软管继续跟随](immersive-sprayer.png) |
