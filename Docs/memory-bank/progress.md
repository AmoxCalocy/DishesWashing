# 开发进度

> 更新日期：2026-11-27（Asia/Shanghai）｜已验收：第 1～17 步及 G 物理松手、无预览等追加需求

## 当前状态

第 1～17 步及 G 物理松手、无预览等追加需求已由用户验证通过。2026-11-27 用户确认第 17 步背景模糊通过，并授权更新文档及上传 GitHub。Compatibility 下 F 平滑进入／退出模糊，原餐具、工具与 UI 清晰，视角不变；保留两态中键、沉浸滚轮与 Q/E、G 物理松手和普通 Q 无返回。下一项为第 18 步暂停与失焦处理，尚未开始；实际清洗仍待后续。

执行依据为 [实施计划](implementation-plan.md)、[游戏设计文档 0.17](game-design-document.md)和[技术栈 0.13](tech-stack.md)。[architecture.md](architecture.md)描述当前职责。历史记录保留各步当时范围：旧固定水槽位、预览和静态叠放由第 14 步 G 物理松手与无预览覆盖；普通右键旋转由第 16 步统一中键覆盖；“背景模糊待实现”由第 17 步覆盖。

## 第 1 步：确认现有基线

### 已完成工作

1. 阅读当时 memory-bank 内的全部三份文档，并核对仓库 AGENTS.md。
2. 阅读项目入口、厨房展示场景、浏览脚本、Blender 总场景组装脚本、Godot 场景组装脚本和截图工具，确认运行入口及生成器覆盖范围。
3. 通过只读版本查询确认实际 Godot、Blender 版本；检查场景外部资源路径与源资产存在情况。
4. 查看 Git 工作区状态，识别已有修改、删除和未跟踪文件；未清理、覆盖、提交或回退用户内容，未重新生成模型或场景。
5. 将第 1 步导入、启动及展示器操作的验证交给用户；收到用户确认后记录本步通过。

### 已确认的基线

| 项目 | 记录 |
| --- | --- |
| Godot | 4.7.2.stable.official.ed1daf0bf，标准版 |
| Blender | 5.3.0，构建标识 02f0899d78e3 |
| 运行语言与渲染 | GDScript、Compatibility |
| 启动链路 | project.godot → Scenes/kitchen-demo.tscn → Scripts/kitchen_viewer.gd |
| 视口与窗口配置 | 视口 1600 × 900，窗口覆盖 1280 × 720；1080p 仍是后续性能测试基准 |
| 当前展示内容 | 厨房环境及 5 个餐盘、2 个马克杯；托盘两盘一杯，架内三盘一杯 |
| 资源存在性 | 场景直接引用的脚本与 10 个 GLB 文件均存在；资产目录共 10 个 .blend、11 个 .glb |
| Blender 导入 | 已关闭 .blend 自动导入，Godot 使用显式导出的 GLB |
| 玩法状态 | WASD、鼠标直接看向、拿取、清洗、评分、订单和存档均待后续实现 |

### 验收结果与来源

测试执行者为用户，用户已确认第 1 步整体验证通过。以下按本步既定验收范围记录；未另外收到逐项日志或截图，不将其表述为 AI 本轮亲自运行的测试。

| 验收范围 | 结果来源 |
| --- | --- |
| 现有 Godot 项目导入、主场景启动 | 用户确认第 1 步通过 |
| 1～4 切换操作区、全貌、待洗区、沥水区视角 | 用户确认第 1 步通过 |
| R 恢复默认视角 | 用户确认第 1 步通过 |
| 右键拖动有限环顾，松开释放鼠标 | 用户确认第 1 步通过 |
| 失焦释放，返回不自动继续拖动 | 用户确认第 1 步通过 |

本步通过不代表 WASD、完整订单、1080p 性能、导出构建或第二台机器已经验证，这些属于后续步骤。

### 原有工作区状态

基线核查时，Docs/README.md 和 Docs/kitchen-asset-plan.md 已有本地修改；旧位置的 Docs/game-design-document.md、Docs/tech-stack.md 处于删除状态，新位置为 Docs/memory-bank。项目入口、Scenes、Scripts、Assets/Scenes、多项工具和导入元数据仍有未跟踪内容。后续开发者应重新查看实时 Git 状态，不能把这些内容当作本步骤新建或可清理文件。

### 验收后的文档更新

- 新建本文件，记录工作内容、实际基线、验收来源及后续边界。
- 新建 architecture.md，解释已有运行文件、生成器、资产、元数据与文档的职责。
- 更新 implementation-plan.md，将第 1 步标为用户验证通过，后续步骤保持未开始。
- 更新 Docs/README.md，将核心文档导航指向 memory-bank，并加入计划、进度和架构入口。

## 已确认的需求与实施边界

基础游戏的 WASD 行走与玩家碰撞已在第 6 步实现；第 7 步已接入鼠标直接看向及空手、持泵瓶时的右键临时观察放大，均已通过用户验收。原展示器的固定机位和右键拖动仍是独立查看操作。

普通模式持工具后中央准星瞄准已放置餐具，按住左键持续操作，海绵自动擦动、喷头对准真实命中；行走和看向可用，松开回原手位。持工具且另一手为空时 E 优先拿取目标餐具，其他持工具情形尝试归回工具。近距离保持进入前的位置、朝向与 FOV，锁定行走和镜头；仅 F 返回，中键拖动或 Q/E 旋转，两工具可在画面内自由移动，主动左键才接触／瞄准，海绵须移动鼠标。背景模糊已于第 17 步验收；供水、润湿、施液、去污与泡沫仍按后续步骤实施。

普通搬运按 1／2 选择左／右手餐具，HUD 标注“当前”，不调换手位。第 11 步共用判定只读，未执行实际放下；仅沥水位要求该件真实清洁状态达到实际 95%，缺失或错配状态不授权，待洗位／临时位允许脏餐具，泡沫不阻止入架。

## 第 2 步：隔离可玩入口（已验收）

新增 Scenes/kitchen-game.tscn，继承原厨房布局，在自身根节点清除浏览脚本并隐藏 ViewerOverlay；project.godot 默认启动该入口。原展示场景、浏览脚本、生成器及资产保持原样，可在编辑器单独打开厨房展示场景并按 F6 使用原有操作。

可玩入口是手工维护文件，现有生成器不覆盖它或 project.godot。对应文件职责、继承依赖及生成输出范围已补充到 architecture.md，用户验证方式见 [入口说明](../scenes/kitchen-game/kitchen-game.md)。AGENTS.md、文档导航和原展示场景说明已同步 F5/F6 的入口区别。

本步仅隔离入口，未新增餐具配置、运行状态、玩家控制或清洁逻辑。用户于 2026-11-23 明确确认验证通过；运行验收由用户执行，不表述为 AI 亲自运行。未另附逐项日志或截图，实际重建是否执行不单独推断。

| 验收范围 | 结果与来源 |
| --- | --- |
| F5 可玩入口与 F6 展示入口分别运行 | 用户确认第 2 步通过 |
| 可玩入口隐藏展示提示，不响应 1～4、R 或右键浏览输入 | 用户确认第 2 步通过 |
| 原展示器视角切换、R 复位、右键拖动和失焦释放 | 用户确认验证通过 |
| 生成器不写入可玩入口或项目配置 | 已静态核对保存路径；实际重建未单独提供执行记录 |
| 文档链接、空白和原展示文件改动边界 | AI 静态检查通过；原展示场景、脚本、生成器和资产未修改 |

## 第 3 步：建立配置与独立运行状态（已验收）

### 已完成工作

- 新增 Scripts/Data 中的 6 种 Resource 配置，分别描述污渍区域、餐具、槽位、厨房布局、订单条目和订单基础奖励。
- 新增 Scripts/State 中的 5 种 RefCounted 状态，分别记录污渍量与泡沫、餐具位置与施液、槽位占用、工具状态及本次订单状态。
- 新建 OrderState 时，为每件餐具、每个污渍区域、每个槽位和工具创建独立对象与集合；复制所需值，不把可变进度写回共享 Resource。
- 新增 Resources/Examples 下的 4 份验证配置。两件盘子引用同一餐具配置，用于证明共享配置不会导致运行状态联动；样例不是已接入游戏的正式订单或完整厨房槽位表。
- 新增 Tools/verify_runtime_state.gd，覆盖状态隔离、初始占用、工具默认值、重新创建状态以及配置未被污染；保留本次导入产生的脚本 UID 元数据。

本步没有修改运行入口、场景、资产或生成器，没有把数据层绑定到场景。F5 画面保持原样；清洁度计算、实际拾取、清洗、奖励发放及重开订单流程仍待对应后续步骤。

### 验收结果与来源

用户于 2026-11-23 明确确认验证通过。验收方式为先导入新增脚本和资源，再运行独立验证脚本；成功标准为输出 RUNTIME_STATE_OK 且退出码为 0。未另附原始控制台日志，以下按用户对本步的整体确认记录，不表述为 AI 亲自运行。

| 验证范围 | 结果与来源 |
| --- | --- |
| 同一配置创建两份订单状态，修改其中一份不影响另一份 | 用户确认第 3 步通过 |
| 同一份餐具配置创建两件盘子，污渍、泡沫与施液独立 | 用户确认第 3 步通过 |
| 修改或删除运行集合内容不污染另一份状态及配置 | 用户确认第 3 步通过 |
| 新建状态恢复初始污渍、位置、占用、无施液、无泡沫、干海绵和关水 | 用户确认第 3 步通过 |
| 初始配置、区域权重、槽位兼容和基础奖励保持不变 | 用户确认第 3 步通过 |
| 文件引用、空白及原入口和文档改动边界 | AI 静态检查通过；用户确认前未更新文档 |

### 重跑方式

在仓库根目录使用 PowerShell，先导入新增类型，再执行验证脚本：

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path . --quit
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script Tools/verify_runtime_state.gd
$LASTEXITCODE
```

输出 RUNTIME_STATE_OK、最后退出码为 0 才视为通过。此脚本只构造和修改内存状态，不启动游戏操作，不写入配置或存档。

## 第 4 步：实现清洁度规则（已验收）

### 已完成工作

- 在 [dish_state.gd](../../Scripts/State/dish_state.gd) 新增清洁度读取：按初始污渍量加权，返回 0～1 的实际值，无初始污渍时返回 1。
- 每个区域的剩余量在计算中限制于 0 与自身初始量之间，避免擦洗过量与其他区域的污渍相互抵消；读取不修改原始状态。
- 将四舍五入的整数百分比与实际 95% 门槛分开。94.9% 显示为 95%，但不达标；95% 和 95.1% 达标，不用近似相等放宽门槛。
- 泡沫量、泡沫权重、施液资格和持有位置不参与清洁度；保留泡沫独立影响后续评分与点数的规则。
- 新增 [verify_cleanliness.gd](../../Tools/verify_cleanliness.gd) 及其 [.gd.uid](../../Tools/verify_cleanliness.gd.uid)，用内存配置覆盖加权、零污渍、上下限和门槛边界；原独立状态脚本用于回归验证。

本步只增加数据层计算和独立验证，未绑定运行场景或增加 HUD、放置交互及实际清洗。清洁度达标接口只回答清洁门槛，完整槽位判定仍须在对应步骤实现。用户确认前未更新文档；第 4 步验收时，第 5 步尚未开始。

### 验收结果与来源

用户于 2026-11-23 明确确认验证通过。验收方式为项目导入、新增清洁度验证及原独立状态验证；通过标准为三个退出码均为 0，两个脚本分别输出 CLEANLINESS_OK、RUNTIME_STATE_OK，且无脚本错误。未另附原始控制台日志，以下按用户对本步的整体确认记录，不表述为 AI 亲自运行。

| 验证范围 | 结果与来源 |
| --- | --- |
| 不等初始污渍量及局部清洁后的加权结果 | 用户确认第 4 步通过 |
| 无区域、全零初始量、零初始与非零区域混合及极小正初始量 | 用户确认第 4 步通过 |
| 负剩余量、超过初始量、混合越界与 0～100% 范围，读取不改状态 | 用户确认第 4 步通过 |
| 94.9%、95%、95.1%，及紧邻门槛两侧，整数显示不提前达标 | 用户确认第 4 步通过 |
| 改变泡沫及持有状态不影响清洁度，当前污渍变化立即更新达标结果 | 用户确认第 4 步通过 |
| 原配置与运行状态隔离回归 | 用户确认第 4 步通过 |
| 改动范围、缩进与空白 | AI 静态检查通过；未修改场景、配置资源或生成器 |

### 重跑方式

在仓库根目录使用 PowerShell，依次运行并检查每项退出码：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_cleanliness.gd
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_runtime_state.gd
$LASTEXITCODE
```

三个退出码均为 0，且分别输出 CLEANLINESS_OK、RUNTIME_STATE_OK 才视为通过。验证脚本只构造和修改内存状态，不运行玩家操作或写入存档。

## 第 5 步：配置游戏输入（已验收）

### 已完成工作

- 在 [project.godot](../../project.godot) 配置 16 个 game_ 前缀输入动作，覆盖 WASD、左右鼠标键、F、E、1～3、Q、Tab、Esc 和滚轮；鼠标移动由事件分派。
- 新增 [game_input.gd](../../Scripts/Input/game_input.gd)，仅处理未被界面消费的事件。左键按持有模式、目标和工具选择分派；E、Q、数字键及滚轮各自按上下文发出意图，不直接操作场景或共享配置。
- 输入层保存经分派的按住状态，返回归一化移动向量，并分别发出观察、餐具旋转和近距离工具光标信号；过滤按键回响及重复按下，正确结束持续使用。
- 新增 [game-hud.tscn](../../Scenes/game-hud.tscn) 与 [game_hud.gd](../../Scripts/UI/game_hud.gd)，提供中央准星、Esc 菜单及“继续游戏”按钮。菜单与失焦释放鼠标并清除旧输入，恢复后不自动续用；准星不拦截鼠标事件。
- 在 [kitchen-game.tscn](../../Scenes/kitchen-game.tscn) 加入 GameInput、GameHUD，继续清除继承的浏览脚本并隐藏 ViewerOverlay；展示场景及生成器未改动。
- 新增 [verify_game_input.gd](../../Tools/verify_game_input.gd)，通过独立 SubViewport 注入键鼠事件，检查映射、分派、准星布局及真实 GUI 事件消费；保留本次导入生成的三个脚本 UID。

第 5 步验收时已接通输入意图与基础界面，尚未实现 CharacterBody3D 行走、相机转动、世界目标射线或真实拾取和清洗。实际场景默认空手、无目标，其他上下文由独立脚本构造验证；ToolState 只被输入层引用工具枚举，订单状态与清洁度未绑定场景。Esc 界面只阻止游戏输入，完整游戏暂停及运行状态冻结仍属第 18 步。用户确认前未更新文档或上传；当时第 6 步未开始。

### 验收结果与来源

用户于 2026-11-23 明确确认验证通过。本步验收包含项目导入、输入验证脚本，以及 F5 准星、鼠标捕获、Esc 菜单、失焦释放和 F6 展示器回归。未另附控制台原始日志或截图，以下按用户对本步的整体确认记录，不表述为 AI 亲自运行。

| 验证范围 | 结果与来源 |
| --- | --- |
| 16 个键鼠映射、WASD 方向、归一化向量及松键清零 | 用户确认第 5 步通过 |
| 左键在拿取、润湿、放置、近距离使用、泵压及无效目标间单一分派 | 用户确认第 5 步通过 |
| E 回响不重复触发、持餐具不拿瓶、持瓶不切工具，Q 按模式分派 | 用户确认第 5 步通过 |
| 鼠标观察、旋转及工具光标分别分派，近距离滚轮连续脉冲有效 | 用户确认第 5 步通过 |
| 界面与过渡阻止输入，持续使用被中断，恢复不带入旧按住状态 | 用户确认第 5 步通过 |
| GUI 消费的按钮点击不传入场景，未被消费的点击仍可分派 | 用户确认第 5 步通过 |
| F5 准星居中，Esc 隐藏准星并释放鼠标，继续按钮恢复捕获，失焦可安全返回 | 用户确认第 5 步通过 |
| 游戏不响应旧展示机位操作，F6 原展示器操作正常 | 用户确认第 5 步通过 |
| 输入映射数量、场景引用、缩进和空白、文档更新时机 | AI 静态检查通过；用户确认后才更新文档 |

### 重跑方式

在仓库根目录使用 PowerShell，先导入再执行验证，并检查每项退出码：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_game_input.gd
$LASTEXITCODE
```

两个退出码均为 0、验证脚本输出 GAME_INPUT_OK 且无脚本错误才视为脚本通过。图形检查按 [可玩入口说明](../scenes/kitchen-game/kitchen-game.md) 执行；无头脚本不证明真实窗口的鼠标捕获与失焦表现。

## 第 6 步：实现 WASD 行走与玩家碰撞（已验收）

### 已完成工作

- 新增 [player_controller.gd](../../Scripts/Player/player_controller.gd)，使用 CharacterBody3D，在物理回调中读取 GameInput 的移动向量，按相机水平朝向行走，限制斜向速度并处理重力与滑动碰撞。
- 新增 [player.tscn](../../Scenes/player.tscn)，配置半径 0.22 m、高 1.75 m 的胶囊及眼高 1.62 m 的玩家相机，初始速度 1.6 m/s、重力 9.8 m/s²；未连接鼠标转向。
- 新增 [kitchen-walk-collision.tscn](../../Scenes/kitchen-walk-collision.tscn)，为地面、柜体与台面整体、后墙和三个地面边界提供玩家阻挡。地面位置与 5×5 m 尺寸已静态核对实际房间 GLB 数据。
- 在 [kitchen-game.tscn](../../Scenes/kitchen-game.tscn) 实例化玩家与步行碰撞，出生位置为世界坐标（0，0.03，1.18）；停用继承的旧相机，由玩家相机随行走移动。
- 玩家使用物理层 2、碰撞掩码 16，步行阻挡使用物理层 5（位值 16）；这些代理用于限制玩家行走，后续交互射线应排除此层，避免把整柜代理误作水槽表面。
- 新增 [verify_player_movement.gd](../../Tools/verify_player_movement.gd) 及两个新脚本的 UID；验证使用真实可玩场景和物理移动，测试结束恢复原物理频率。

本步未修改原展示场景、浏览脚本、资产或生成器。实施前 project.godot 已存在编辑器展开保存的输入事件字段；实施阶段原样保留，验收后随当前项目配置提交，未新增键位或改渲染设置。第 6 步验收时，鼠标转动、世界目标检测与真实拾取和清洗尚未接入；持餐具、持瓶和近距离等模式由脚本构造上下文验证。用户确认前未更新文档或上传；当时第 7 步未开始。

### 验收结果与来源

用户于 2026-11-24 明确确认验证通过。验收方式为导入项目、执行行走验证脚本及 F5 行走、碰撞和中断检查；脚本标准为两个退出码均为 0、输出 PLAYER_MOVEMENT_OK 且无脚本错误。未另附原始控制台日志或截图，以下按用户对本步的整体确认记录，不表述为 AI 亲自运行。

| 验证范围 | 结果与来源 |
| --- | --- |
| 安全出生、落地、胶囊不重叠、玩家相机激活及眼高 | 用户确认第 6 步通过 |
| WASD 方向、直行与斜行速度，相机水平朝向及上下俯仰不改变行走高度 | 用户确认第 6 步通过 |
| 30 Hz 与 120 Hz 物理频率下同一秒的行走距离 | 用户确认第 6 步通过；不是图形帧率或性能报告 |
| 持餐具及持瓶允许行走，近距离、过渡和菜单阻止行走 | 用户确认第 6 步通过；尚未实现的模式由脚本设置 |
| Esc 与失焦停止移动，继续游戏不恢复旧按住状态 | 用户确认第 6 步通过 |
| 柜体、台面、后墙、侧边界与前边界阻挡，落地后不穿地 | 用户确认第 6 步通过 |
| 沿台面前方走近托盘、水槽、沥水架及订单板 | 用户确认第 6 步通过 |
| 场景引用、资源数量、缩进、空白及既有项目配置保留 | AI 静态检查通过；仅在用户确认后更新文档 |

### 重跑方式

在仓库根目录使用 PowerShell，先导入再执行验证，脚本约运行 20 秒：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_player_movement.gd
$LASTEXITCODE
```

两个退出码均为 0、输出 PLAYER_MOVEMENT_OK 且无脚本错误才视为脚本通过。F5 检查 WASD、任务区通路、柜体和边界阻挡，以及 Esc、Alt+Tab 后停止移动；继续游戏后需重新按下移动键。鼠标转向尚未接入，不作为本步通过条件。

## 第 7 步：鼠标直接看向与临时观察放大（已验收）

### 已完成工作

- 在 [player_controller.gd](../../Scripts/Player/player_controller.gd) 连接 GameInput 的观察信号：玩家根节点承担水平转向，相机承担俯仰；水平角循环归一化而不限制转身圈数，俯仰限制为 ±80°，默认灵敏度为每像素 0.0025 弧度。
- 镜头直接处理每次鼠标位移，不累计跨模式增量；恢复捕获时丢弃首个位移，避免光标重定位造成突跳。菜单、失焦、近距离及过渡期间禁用观察，目标或工具更新不反复丢弃有效输入。
- 按用户追加要求，在 [game_input.gd](../../Scripts/Input/game_input.gd) 将空手和单独持泵瓶的右键分派为 zoom_view 按下/停止意图；持餐具的右键继续分派旋转，不同时放大镜头。
- 玩家控制器收到放大意图后缓存原 FOV，默认由 53.7° 收窄到 35°；松开、菜单、失焦或持有模式切换时恢复原值。放大不移动玩家或相机，期间仍可转动镜头。
- 新增 [verify_mouse_look.gd](../../Tools/verify_mouse_look.gd) 及其 [UID](../../Tools/verify_mouse_look.gd.uid)，覆盖转身、俯仰、边走边转、模式锁定、恢复捕获、右键放大与旧展示器回归；原输入脚本用于分派及 GUI 消费回归。

本步未改场景、项目输入映射、资产、生成器或旧展示脚本，原行走物理回调保持原样。真实拾取、持瓶和餐具旋转尚未实现，相关模式通过脚本构造上下文验证；F 拉近餐具和近距离滚轮距离仍按后续步骤实施，不能用本步 FOV 放大替代。用户确认前未更新文档或上传，当时第 8 步未开始。

### 验收结果与来源

用户于 2026-11-24 明确确认第 7 步及追加右键放大验证通过。最终版本验收来源为用户确认，未另附原始日志或截图；以下不据此推断 AI 已运行包含右键放大的最终版 Godot 测试。

| 验证范围 | 结果与来源 |
| --- | --- |
| 无需右键即可观察，水平可连续转身、俯仰不翻转、不产生侧倾 | 用户确认第 7 步通过 |
| 鼠标转向与 WASD 同时生效，前进方向跟随观察朝向 | 用户确认第 7 步通过 |
| 近距离、过渡及餐具右键旋转不改变镜头朝向 | 用户确认第 7 步通过；未实现的持物模式由脚本设置 |
| 菜单、失焦停止移动与观察，恢复捕获不突跳、不续用旧移动键 | 用户确认第 7 步通过 |
| 空手及持瓶右键按住放大、松开复原，重复按下不污染原 FOV | 用户确认追加功能通过 |
| 放大期间可观察；目标更新保留放大，菜单、失焦与持有模式切换取消放大 | 用户确认追加功能通过 |
| 餐具旋转不放大镜头，旧展示器仍需右键拖动且保留机位与 R 复位 | 用户确认第 7 步及追加功能通过 |
| 输入分派与 GUI 消费回归、文件边界及静态空白检查 | 用户确认输入回归通过；AI 静态核对改动范围 |

### 重跑方式

在仓库根目录使用 PowerShell。首次导入新脚本后，依次执行鼠标观察与输入分派验证，每项退出码应为 0：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_mouse_look.gd
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_game_input.gd
$LASTEXITCODE
```

两个验证脚本应分别输出 MOUSE_LOOK_OK、GAME_INPUT_OK，且无脚本错误。F5 检查直接看向、边走边转、右键按住/松开、Esc 与 Alt+Tab 后恢复；F6 展示器继续使用原操作。窗口捕获和主观手感以交互验收为准。

### 验收后的文档同步

设计文档更新为 0.8、技术栈更新为 0.4，补充右键按上下文放大或旋转，以及 FOV 放大与 F 拉近餐具的区别；实施计划保持 62 步，将第 7 步及追加功能标为通过。架构、入口说明、文档导航与 AGENTS.md 同步实际职责和运行命令。

## 第 8 步：封装盘杯及碰撞（已验收）

### 已完成工作

- 新增 [plate.tscn](../../Scenes/Dishes/plate.tscn)、[mug.tscn](../../Scenes/Dishes/mug.tscn) 与 [dish_body.gd](../../Scripts/Dishes/dish_body.gd)。复用正式 GLB，每个实例分别保存身份、类型和显示名称，并生成仅供查询的真实三角面碰撞。
- 在 [kitchen-game.tscn](../../Scenes/kitchen-game.tscn) 中隐藏托盘原有三个展示实例，以同一完整姿态放置 PlayableDishes 下的两盘一杯；身份为 tray_plate_01、tray_plate_02、tray_mug_01。架内四件仍是展示装饰，只作为遮挡，不作为可交互餐具。
- 新增 [mesh_surface_collision.gd](../../Scripts/Interaction/mesh_surface_collision.gd)，按可见 MeshInstance3D 的真实面和完整变换创建 ConcavePolygonShape3D，不使用封闭凸包。三角面局部坐标放大 100 倍，碰撞形状施加 0.01 的等比缩放，修复实际遇到的细面短射线漏检，保持世界尺寸为米。
- 新增 [kitchen_surface_collision.gd](../../Scripts/Interaction/kitchen_surface_collision.gd)，只在可玩入口为环境、工具和架内展示餐具生成表面遮挡；保留杯内、杯柄孔、架槽、托盘与水槽内腔。
- 新增 [dish_targeting.gd](../../Scripts/Interaction/dish_targeting.gd)，每个物理帧从玩家相机中央查询，默认距离 1.5 米。只考虑第一处真实表面，距离外或遮挡后的餐具不能成为目标；将有效餐具类别通过 set_context 交给 GameInput，不执行拾取。
- 扩展 [game-hud.tscn](../../Scenes/game-hud.tscn) 与 [game_hud.gd](../../Scripts/UI/game_hud.gd)，准星下显示“餐盘 1”“餐盘 2”或“马克杯”；失去目标、菜单和失焦时清除，恢复后重新查询。
- 新增 [verify_dish_targeting.gd](../../Tools/verify_dish_targeting.gd)，使用真实场景和物理查询检查身份、姿态、表面、开口、距离、遮挡及展示器隔离；保留四个新增运行脚本及此验证脚本各自的 .gd.uid。

交互餐具位于物理层 1（位值 1），环境表面位于层 3（位值 4），查询掩码为 5；玩家层 2 与步行代理层 5 不参与查询，原行走碰撞不变。本步没有修改项目配置、模型、生成器、原展示场景、输入分派或玩家控制脚本。订单状态与清洁度仍未绑定场景，槽位注册和实际拿起分别留给第 9、10 步；用户确认前未更新文档、上传或开始下一步。

### 验收结果与来源

用户于 2026-11-24 明确确认第 8 步验证通过。用户未另附逐项日志或截图，图形操作与本步整体验收以其明确确认为准。实施期间 AI 已实际运行项目导入、专项脚本及三项回归，最终均退出 0；表中区分执行来源，不用无头结果替代真实窗口操作。

| 验证范围 | 结果与来源 |
| --- | --- |
| 新增脚本与场景导入 | AI 实际运行，最终退出 0、无导入或脚本错误 |
| 三件独立身份、类型、完整摆放姿态及无重复碰撞 | AI 专项检查通过；用户确认第 8 步通过 |
| 盘正反面、杯内底和内壁、外底、杯柄、变换后的真实表面及法线 | AI 专项检查通过，输出 DISH_TARGETING_OK、退出 0 |
| 杯柄孔、空架槽、托盘内底及水槽内腔保持开放 | AI 专项检查通过 |
| 柜体与墙体遮挡、前景餐具阻挡、环境和装饰不误选 | AI 专项检查通过；用户确认第 8 步通过 |
| 距离内可选、超距失效，FOV 放大不延长距离，玩家和步行层排除 | AI 专项检查通过 |
| 准星名称、菜单和失焦清除、恢复查询及 F6 展示器隔离 | AI 专项检查通过；图形验收由用户确认 |
| 原输入、鼠标观察与右键放大、行走碰撞回归 | AI 实际运行，分别输出 GAME_INPUT_OK、MOUSE_LOOK_OK、PLAYER_MOVEMENT_OK，退出码均为 0 |
| 空白、脚本 UID、改动范围及文档时机 | AI 静态检查通过；用户确认后才更新文档 |

首次沙箱内导入和运行受 Godot 用户缓存、日志目录及系统证书读取权限影响；在沙箱外重试后最终检查通过。排查细面漏检的临时脚本已删除，不作为交付文件。

### 重跑方式

在仓库根目录使用 PowerShell，先导入再执行专项检查，每项退出码应为 0：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_dish_targeting.gd
$LASTEXITCODE
```

专项成功输出 DISH_TARGETING_OK。回归可依次运行 Tools/verify_game_input.gd、Tools/verify_mouse_look.gd、Tools/verify_player_movement.gd，命令格式同上。验证脚本只修改实例化场景的内存状态，不保存资源、场景或用户进度。

F5 走近左侧托盘，分别瞄准两盘一杯，确认名称正确，移开或超距后消失；检查 Esc、Alt+Tab 及恢复后的名称与操作。F6 原展示器保持所有展示餐具和原操作。实际拿起仍未实现，不作为第 8 步的通过条件。

### 验收后的文档同步

更新本文件、architecture.md、实施计划、入口说明、文档导航与 AGENTS.md，补充当前职责、碰撞分层、精度处理和验证命令。设计文档 0.8、技术栈 0.4 的目标规则未变，实施计划仍为 62 步。

## 第 9 步：注册槽位（已验收）

### 已完成工作

- 新增 [kitchen-layout.tres](../../Resources/Kitchen/kitchen-layout.tres)，列出托盘 2 盘 1 杯、沥水架 6 盘 2 杯、水槽临时 1 盘 1 杯，共 13 个槽位的身份、名称、类别、兼容类型和定位来源。这是运行场景使用的完整布局，不替换 Resources/Examples 的数据层验证样例。
- 新增 [kitchen_slot.gd](../../Scripts/Slots/kitchen_slot.gd)，关联配置、实际定位节点及每场景独立的 SlotState；直接返回定位节点完整姿态，并提供类型兼容和空位读取。这些读取不构成完整放置授权。
- 新增 [kitchen_slot_registry.gd](../../Scripts/Slots/kitchen_slot_registry.gd)，校验槽位和初始餐具身份，注册槽位、记录初始占用，按模型节点完整姿态摆放托盘三件，不额外叠加半高。
- 新增手工维护的 [kitchen-slots.tscn](../../Scenes/kitchen-slots.tscn)。临时盘位和杯位沿用水槽返回参考点，按正式盘杯全部网格与实际盆底测量，校准为约 0.5 mm 的最小承托间隙；增加圆环与名称，区分餐具根姿态和用于识别的 SelectionSurface 表面点。
- 扩展 [slot_config.gd](../../Scripts/Data/slot_config.gd) 的显示名称与 [dish_body.gd](../../Scripts/Dishes/dish_body.gd) 的 initial_slot_id；在 [kitchen-game.tscn](../../Scenes/kitchen-game.tscn) 接入注册器，改从托盘节点取得初始姿态，并隐藏架内四件展示餐具，使八个任务架位实际空置。F6 原展示器未改动。
- 扩展 [dish_targeting.gd](../../Scripts/Interaction/dish_targeting.gd) 与 [game_hud.gd](../../Scripts/UI/game_hud.gd)。餐具优先识别；射线首先命中真实盆底且临时位为空时，才显示临时位名称。沿用 1.5 米范围和现有遮挡，超距、占用、菜单或失焦清除目标。
- 新增 [verify_kitchen_slots.gd](../../Tools/verify_kitchen_slots.gd)，同时在 13 个完整姿态放入正式盘杯，检查模型边线与环境及其他餐具的相交、最低处承托、独立占用、临时位及施液瞄准。保留两个新运行脚本和验证脚本的 .gd.uid；测量临时脚本及其 UID 已删除。

本步未修改项目配置、资产、生成器、原展示场景、输入分派或玩家控制。OrderState 与 DishState 仍未接入场景，当前使用注册器内的独立 SlotState 记录占用。实际拿起、完整放置判定、落位预览与吸附、拿瓶及泵压执行仍属后续步骤；施液验证只证明放在临时位的盘杯可见、可命中并正确分派已有输入意图。用户确认前未更新文档或上传，也未开始第 10 步。

### 验收结果与来源

用户于 2026-11-24 明确确认第 9 步验证通过，未另附逐项原始日志或截图；真实窗口操作与整体验收按用户明确确认记录。实施期间 AI 已实际运行项目导入、槽位专项及五项回归，最终均退出 0。新增视觉标记的图形验收来源为用户确认，不表述为 AI 已生成或查看新截图。

| 验证范围 | 结果与来源 |
| --- | --- |
| 新增布局、场景、类型及验证脚本导入 | AI 实际运行通过，无导入或脚本错误 |
| 13 位数量、类型、初始占用、完整姿态，竖盘与倒扣杯朝向 | AI 专项检查通过，输出 KITCHEN_SLOTS_OK、退出 0 |
| 所有位置同时放入正式盘杯后的边线相交与约 0.5 mm 最低处承托 | AI 专项检查通过；此项不是动态插入或重力稳定性测试 |
| 共享布局但不同场景的占用独立，单槽修改不影响其他槽 | AI 专项检查通过 |
| 可玩入口隐藏原展示餐具、架位空置，F6 保留原展示布置 | AI 专项检查通过；用户确认第 9 步通过 |
| 临时位可选、名称正确，超距、占用、遮挡与菜单恢复处理 | AI 专项检查通过；真实窗口由用户确认 |
| 临时位放置盘杯后的餐具优先识别及 pump_soap 输入意图 | AI 专项检查通过；盘杯摆放与持瓶模式由测试构造，未实现泵压执行 |
| 盘杯识别、独立状态、输入、鼠标及行走回归 | AI 实际运行，分别输出 DISH_TARGETING_OK、RUNTIME_STATE_OK、GAME_INPUT_OK、MOUSE_LOOK_OK、PLAYER_MOVEMENT_OK，退出码均为 0 |
| 空白、UID 与改动边界 | AI 静态检查通过；30 个脚本 UID 唯一，文档在用户确认后更新 |

### 重跑方式

在仓库根目录使用 PowerShell，先导入再执行槽位专项，两个退出码均应为 0：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_kitchen_slots.gd
$LASTEXITCODE
```

专项成功输出 KITCHEN_SLOTS_OK，且无脚本错误。回归脚本使用相同命令格式，文件与成功标识见上表。测试只修改实例化场景的内存状态，不保存模型、场景、配置或用户进度。

F5 走近水槽，检查“临时盘位”“临时杯位”圆环与名称，瞄准可识别，移开、走远或打开菜单后清除准星名称；托盘三件仍可识别，右侧沥水架为空。F6 原展示器保留原餐具和控制方式。实际拿起、放置和泵压不作为本步的通过条件。

### 验收后的文档同步

更新本文件、architecture.md、实施计划、入口说明、文档导航及 AGENTS.md，解释新增文件、完整布局与验证样例的区别、占用所有权及后续衔接。设计文档 0.8、技术栈 0.4 的目标规则不变，实施计划仍为 62 步。

## 第 10 步：普通拿起与追加双持、沉浸操作（已验收）

### 已完成工作

- 新增 [dish_carry.gd](../../Scripts/Dishes/dish_carry.gd) 与 [hand_item.gd](../../Scripts/Dishes/hand_item.gd)，使用两个稳定手位移动原物体实例。第一件在左下，第二件在右下；剩余物品不因另一件归回而换边。支持两餐具或餐具加一个清洗工具，不支持两工具或泵瓶混持。
- 餐具拿起即时重查距离和遮挡，通过注册器新增 find_occupied_slot 读取当前占用来源，空身份／重复占用不授权；安全姿态合格才解除该来源占用。逐手保存本次来源，不将 initial_slot_id 当作当前槽位。
- 按每件真实网格包围盒建立独立搬运查询形状，检查近裁剪和运动路径，保留表面余量及最近安全世界姿态。空间不足拒绝拿取或保持安全姿态，不创建副本或误放餐具。
- 新增 [cleaning_tool.gd](../../Scripts/Tools/cleaning_tool.gd) 与 [world_cleaning_tools.gd](../../Scripts/Tools/world_cleaning_tools.gd)，封装世界中原海绵及实际喷头，移除它们原来的环境遮挡并让真实碰撞随模型移动。工具在任一空手可左键或 E 拿取；普通搬运 E 在原位 1.5 米范围且无遮挡时归回，保留另一手。
- 在玩家相机下增加左右搬运和居中清洗锚点，F 约 0.2 秒移动同一件餐具；仅餐具加工具可进入，进入前检查空间，喷头检查距水槽原位。保持玩家位置、观察方向与 FOV，过渡不接受重复切换，沉浸停止行走与环顾。
- 按用户修订，仅 F 返回搬运。沉浸时右键拖动或按住 Q/E 左右旋转，松开停止、同时按住抵消。旋转中断使用，恢复或失焦后不带入旧左键或旋转输入。搬运 E 归回工具，1 和 Q 不再归回工具。
- 海绵和喷头在相机前自由跟随光标，按真实网格限制画面边缘及近裁剪。未主动使用、移出餐具或旋转后都不自动吸附或收回；左键主动命中当前餐具才贴合／瞄准，海绵移动时压缩，喷头从持有侧稍偏移并将实际喷嘴对准命中点；F 返回才恢复手位。
- 修正喷头沿用餐盘拿取方向的问题；软管以 16 个圆柱段连接实际端点，使用端点切向曲线且只缩放管段局部 Y，修复世界轴缩放造成的异常黑色长条。归回喷头恢复原软管。当前仍是视觉跟随，尚无餐具避障或长度约束。
- 扩展目标查询以支持搬运中再拿一件及工具层，排除所有已持 RID；沉浸目标改由持物控制器负责，世界查询不再覆盖它。HUD 增加左右手状态、上下文操作和拒绝提示。
- 新增 [verify_dish_carry.gd](../../Tools/verify_dish_carry.gd) 与 [verify_dual_wield.gd](../../Tools/verify_dual_wield.gd)，更新输入验证的双持、E 与 Q/E 预期。保留六个新脚本的 UID，当前 36 个 GDScript 稳定标识唯一。

本轮未修改 GLB、Blender 源模型、资产生成器或原展示场景。OrderState、DishState、干湿和供水条件仍未绑定实际玩法；contact_active 只是操作接触状态，不会减污渍或出水。第 11 步完整放置、第 16 步普通搬运旋转与滚轮范围、第 17 步背景模糊、第 18 步完整暂停及后续供水、去污仍待对应验收。

### 验收结果与来源

用户于 2026-11-24 明确确认当前全部改动验证通过并授权更新文档、上传 GitHub；用户未另附逐项原始日志。实施期间 AI 实际运行以下检查；中间失败已修复，表中记录最终通过的范围，不将整单清洗或完整 MVP 记为已验收。

| 验证范围 | 最终结果与来源 |
| --- | --- |
| Godot 新脚本导入与默认入口启动 | AI 实际运行，退出 0、无脚本错误 |
| 三件盘杯逐件拿起、当前来源与占用、原实例、重复无效输入、近裁剪、左下构图和 36 个障碍姿态 | AI 实际运行，输出 DISH_CARRY_OK、退出 0 |
| 两餐具、盘杯加两工具、两种拿取顺序、满手与双工具拒绝、手位保持 | AI 实际运行，输出 DUAL_WIELD_OK、退出 0 |
| F 过渡、位置／朝向／FOV、右键与 Q/E 方向及停止、超过侧面旋转后工具仍自由、失焦恢复 | AI 双持专项最终通过；用户确认整体验收 |
| 两工具自由跟随、松开左键恢复自由、四角完整可见、主动接触／实际喷嘴方向、F 回手位、E 归回 | AI 双持专项最终通过；左右手与盘杯场景均覆盖 |
| 实际软管各段首尾连续、横截面无异常拉伸 | AI 双持专项通过；不代表软管避障或完整物理模拟 |
| 输入分派、重复键、GUI 消费和持续输入中断 | AI 实际运行 GAME_INPUT_OK、退出 0，已更新最终 Q/E 与 E 规则 |
| 世界盘杯识别、槽位、镜头、玩家行走回归 | AI 实施期间分别运行 DISH_TARGETING_OK、KITCHEN_SLOTS_OK、MOUSE_LOOK_OK、PLAYER_MOVEMENT_OK，最终退出 0 |
| 实际画面 | AI 用 Godot 图形模式渲染并查看双持、海绵／喷头自由位置、超过侧面旋转、边缘和 F 恢复手位；用户确认玩法验收 |
| 文档更新时机、空白与 UID | 用户确认前未改文档或上传；确认后同步当前规则、架构和边界，静态检查结果随交付记录 |

验收期间曾修正持物目标被旧规则清空、输入构造模式下 HUD 读取空工具以及软管世界轴缩放的问题。验证脚本也修正了相机重置、类型数组和旋转角测量方式；不将测试脚本构造错误归因于用户环境或保留为未解决的运行错误。

### 重跑方式

在仓库根目录依次执行，退出码均应为 0，两个专项分别输出 DISH_CARRY_OK、DUAL_WIELD_OK，且无脚本错误：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_dish_carry.gd
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_dual_wield.gd
$LASTEXITCODE
& $godotExe --headless --path . --script Tools/verify_game_input.gd
$LASTEXITCODE
```

专项只修改实例化场景的内存，不写入模型、配置或存档。真实窗口操作和当前预览见 [可玩入口说明](../scenes/kitchen-game/kitchen-game.md)；无头测试不证明完整暂停、供水、去污或性能目标。

### 验收后的文档同步

更新本文件、architecture.md、实施计划、设计文档 0.9、技术栈 0.5、入口说明、文档导航、工具资产接入备注及 AGENTS.md；归档当前玩法预览。保留既有 62 步编号，将提前接入的能力与后续缺口分开记录，不将第 15、16、19 步整体标为完成。

## 第 10 步追加：普通模式工具操作与沉浸中键旋转（2026-11-26，已验收）

### 已完成工作

- 参考《犯罪现场清洁工》的持工具瞄准、按住左键使用方式，保留实体工具、稳定双手及 F 沉浸。普通模式持工具后左键持续操作已放置餐具，不误拾取、不改变目标槽位占用；E 在持工具且空余一手时优先拿取目标餐具，其他持工具情形尝试归回。
- DishCarry 每物理帧调用 DishTargeting.query_surface 即时读取准星第一处真实表面，排除两手已持 RID；只命中餐具才接触。海绵沿法线贴面持续擦动、压缩，喷头实际喷嘴瞄准命中点，contact_dish 保存本帧操作对象。普通操作和沉浸复用表面姿态计算。
- 普通操作保持 WASD 和直接看向；目标在餐具、空处和环境之间变化时保留已按住的 use_tool 意图，实际无效立即停止接触，重新命中再继续。松开回原手位，菜单、失焦、模式及工具变化清除旧使用，恢复后重新按下；E 拿取前先结束接触，避免工具挡住餐具。
- 工具增加接触位置、近裁剪、形状和接近路径检查。托盘内目标允许先检查越过边缘再下降的路径；保留 1.5 米世界交互范围，喷头另检查距原位 1.5 米工作范围。此项不是完整手臂动画、软管长度或碰撞模拟。
- 沉浸拖动旋转从右键改为中键；project.godot 新增 game_rotate_close，现有 game_rotate 保留普通模式用途，共 17 个输入动作。沉浸右键不旋转、不放大，也不取消工具使用；中键及 Q/E 仍中断使用，释放或菜单恢复不续用旧输入。HUD 同步中键及普通 E 的提示。
- 新增 [verify_world_tool_use.gd](../../Tools/verify_world_tool_use.gd) 和 UID，复用双持检查的真实场景辅助方法；更新输入和双持专项。当前 37 个脚本 UID 唯一，十份独立验证脚本。未修改模型、生成器或原展示场景。

### 验收结果与来源

用户于 2026-11-26 明确确认验证通过并要求更新文档、上传 GitHub，未另附逐项原始日志。AI 在实现阶段实际执行下列检查；不将工具接触反馈写成出水或实际去污。

| 验证范围 | 结果与来源 |
| --- | --- |
| Godot 项目导入 | AI 实际运行，退出 0，无脚本错误 |
| 两工具、左右手、已放置盘杯、原占用、持续瞄准、WASD／观察、遮挡、超距、菜单及失焦、E 拿取和 F 共存 | AI 运行 WORLD_TOOL_USE_OK，最终退出 0 |
| 中键映射、沉浸右键无效且不取消使用、中键中断左键、独立释放、菜单与旧输入清除、GUI 消费 | AI 运行 GAME_INPUT_OK，最终退出 0 |
| 两种拿取顺序、稳定手位、F、实际中键旋转、Q/E、自由工具与软管回归 | AI 运行 DUAL_WIELD_OK，最终退出 0 |
| 鼠标观察、右键 FOV 放大及原展示器 | AI 运行 MOUSE_LOOK_OK，最终退出 0 |
| 搬运和玩家行走 | 普通操作实现阶段运行 DISH_CARRY_OK、PLAYER_MOVEMENT_OK，退出 0；中键修改后重跑上述四项相关专项通过 |
| 普通工具实际画面 | AI 用 Godot 图形模式渲染并查看海绵贴盘、喷头瞄准及软管；已归档两张预览。中键交互及本轮整体验收由用户确认 |

### 重跑方式

在仓库根目录先导入，再依次检查退出码均为 0：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script Tools/verify_world_tool_use.gd
& $godotExe --headless --path . --script Tools/verify_game_input.gd
& $godotExe --headless --path . --script Tools/verify_dual_wield.gd
& $godotExe --headless --path . --script Tools/verify_mouse_look.gd
```

对应成功标识为 WORLD_TOOL_USE_OK、GAME_INPUT_OK、DUAL_WIELD_OK、MOUSE_LOOK_OK。脚本只修改实例化场景内存，不写入配置或玩家存档。F5 先拿工具，对准托盘盘杯按住左键；持工具对准餐具按 E 拿取，再按 F 检查沉浸中键拖动和 Q/E，F 返回。完整放置、供水、湿润、施液、去污、泡沫、背景模糊和完整暂停仍未实现。

### 验收后的文档同步

同步进度、架构、实施计划、设计文档 0.10、技术栈 0.6、可玩入口说明、文档导航、工具资产补充及 AGENTS.md，归档普通模式操作预览。保持 62 步编号，第 11 步及其双餐具放置选择仍未开始。

## 第 11 步：统一放置判定与显式手位选择（已验收）

### 已完成工作

- 用户明确选择“按 1／2 选择左手／右手餐具”。普通持餐具时复用原键位发送 select_left_dish／select_right_dish，不新增映射或切换实体工具；单件自动选中，第二件拿起保留原选择，空手／工具不可选，HUD 标注“当前”。selected_dish、get_selected_dish_item 与 selected_dish_hand 明确操作对象及各手本次来源，不依赖 held_dish 兼容 getter。
- 新增 [placement_rules.gd](../../Scripts/Slots/placement_rules.gd)、[placement_result.gd](../../Scripts/Slots/placement_result.gd) 和 UID；DishCarry.check_placement 检查普通搬运／界面上下文，再把当前选中物品交给同一判定入口。结果提供原因码、中文原因、完整目标姿态、餐具／槽位身份和手位，不移动节点、不预留或更改占用、不修改运行状态。
- 判定覆盖槽位对象在注册器中的身份、兼容类型、目标空位、来源占用已释放、尺寸、1.5 米距离、视锥及第一处真实遮挡。真实 DishState 只用于沥水位的实际 95% 门槛；缺失／错配状态不授权入架，泡沫不作为拒绝条件，待洗位和临时位允许脏餐具。正式订单与清洁状态仍未绑定玩法，验证使用已知状态。
- SlotConfig 增加 maximum_dish_size，正式 13 个槽位按餐具局部轴配置含杯柄的尺寸上限：盘（0.251，0.025，0.251）、杯（0.132，0.106，0.091）米。HandItem 按需缓存真实网格三角面；空间先用包围盒筛选，再用表面微薄凸棱柱检查，保留杯柄孔并覆盖三角面内部的小障碍，不复用搬运 4 mm 余量。
- 新增 [verify_placement_rules.gd](../../Tools/verify_placement_rules.gd) 和 UID，并更新输入验证的 1／2 预期。当前共 40 个唯一脚本 UID、十一份验证脚本，输入映射仍为 17 个。未修改 GLB、Blender、生成器或场景文件；第 12～14 步未提前实施。

### 验收结果与来源

用户于 2026-11-26 明确确认验证通过并要求更新文档与上传 GitHub，未另附逐项原始日志。AI 在实施阶段实际运行下列检查；图形验收和整体验收来源为用户确认，不将只读判定写成已经能够放下餐具。

| 验证范围 | 结果与来源 |
| --- | --- |
| Godot 新类型、配置和脚本导入 | AI 实际运行，退出 0，无脚本错误 |
| 13 个正式完整姿态、实际 94.9%／95%／95.1% 及紧邻门槛、整数显示与泡沫独立 | AI 运行 PLACEMENT_RULES_OK，最终退出 0 |
| 未知／错配状态、未注册槽位、占用与来源、类型、实际放大模型、距离与遮挡 | AI 专项通过，拒绝码及中文原因一致 |
| 真实空间、三角面内部 0.2 mm 小障碍、杯柄孔内障碍不误拒绝、占用变化后重查 | AI 专项通过；不是动态插入或完整刚体模拟验证 |
| 判定不改节点、父节点、占用及运行状态，1／2 选择、空手拒绝、选右杯而非兼容 getter、UI 阻断 | AI 专项通过；Q 和左键未提前执行放置 |
| 输入、双持、普通工具、槽位、运行状态、清洁度回归 | AI 分别运行 GAME_INPUT_OK、DUAL_WIELD_OK、WORLD_TOOL_USE_OK、KITCHEN_SLOTS_OK、RUNTIME_STATE_OK、CLEANLINESS_OK，退出码均为 0 |
| 实际画面 | AI 用 Godot 图形模式渲染并查看右手杯子“当前”标记与 1／2 提示，已归档截图；用户确认整体验收 |

### 重跑方式

仓库根目录先导入，再运行专项；成功输出 PLACEMENT_RULES_OK，退出码为 0 且无脚本错误：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script Tools/verify_placement_rules.gd
```

六项回归按同一格式运行上表对应的 Tools/verify_*.gd。所有检查仅修改实例化场景内存，不写配置或玩家存档。F5 拿起两件餐具，按 1／2 检查“当前”标记；只有一件时自动选中，选择空手时提示且不丢失原选择。

### 验收后的文档同步

更新本文件、架构、实施计划、设计文档 0.11、技术栈 0.7、入口说明、文档导航和 AGENTS.md，归档手位选择预览。保持 62 步编号，第 11 步标为通过，第 12 步未开始。

## 第 12 步：水槽自由落点与沥水架固定预览（已验收）

### 已完成工作

- 用户在预览初版后明确修正：“水槽里的位置不用固定，玩家可以随意放置餐具，只有沥水架有固定位置”。已移除正式布局中的 Sink_Plate_01／Sink_Mug_01 及 SelectionSurface、圆环和名称标记；注册器保留 3 个托盘初始点及 8 个架位，只有架位参与固定目标查询，托盘点仅初始化及记录来源。
- 新增 [第 12 步历史预览脚本](https://github.com/AmoxCalocy/DishesWashing/blob/8c39b9e8b342afd419515f9ba89d4dab2365fd51/Scripts/Slots/placement_preview.gd) 及 UID，并在手工玩法入口接入。普通搬运以 1／2 选中餐具为对象，复制可见正式网格，杯柄也显示；独立半透明绿／红材质和 HUD PlacementHint 使用同一结果与拒绝原因。幽灵节点不含脚本、身份或碰撞，不影响拾取、射线或占用。
- DishTargeting 增加 PLACEMENT_SURFACE 上下文和水槽表面通知，保留首个真实命中、所有持物 RID 排除、1.5 米与遮挡条件。固定查询仅选择架位并保留竖盘、倒杯完整姿态；水槽通过真实盆体／排水口形状识别，排除台面和边沿，不按盘杯分区。菜单、失焦、沉浸和过渡清除预览，恢复后重查。
- DishCarry.check_surface_placement → PlacementRules.evaluate_surface 提供共用只读自由判定：XZ 连续跟随命中点，八个真实底圈支撑点向下查询并检查接触范围包围中心，浅坡对齐法线，保留约 0.5 mm 支撑间隙。过陡、支撑不足、与槽壁或其他餐具穿插时拒绝。HandItem 缓存三角面查询形状和支撑点，仍每次重查真实世界；不缓存有效性或预留位置。原注册位置判定保持类型、尺寸、占用及架位实际 95% 门槛。
- 新增 [verify_placement_preview.gd](../../Tools/verify_placement_preview.gd) 及 UID；更新输入、槽位、统一规则和搬运专项以匹配 11 项正式注册配置。当前共 42 个唯一 GDScript UID、12 份验证脚本，输入映射仍为 17 个。未修改 GLB、Blender、资产生成器或原展示场景。

### 验收结果与来源

用户于 2026-11-26 确认修正后的版本验证通过，并要求更新文档与上传 GitHub，未另附逐项原始日志。以下 AI 检查均在实现阶段实际执行；不将预览写作已可放下餐具或完成清洗。

| 验证范围 | 结果与来源 |
| --- | --- |
| 盘子 18 个、杯子 12 个不同水槽落点及额外小幅连续移动，同一点支持两种餐具 | AI 运行 PLACEMENT_PREVIEW_OK，最终退出 0 |
| 独立真实网格边线射线、约 0.5 mm 支撑间隙、槽壁、过陡支撑、非准星路径小障碍与相邻真实餐具 | 同一专项通过，分别正确显示有效、空间不足或支撑不足 |
| 8 个架位完整姿态、倒杯、类型、未知清洁状态、94.9%／95%、有泡沫、占用变更 | 同一专项通过；生产缺失状态仍红色，不默认清洁 |
| 左右手选择、原网格和独立材质、无碰撞／拾取／占用、左键／Q 不提前执行动作 | 同一专项通过 |
| 前景餐具／柜板、超距、移开、菜单／失焦、旧命中重查、持物及工具排除、F 往返与展示器隔离 | 同一专项通过 |
| 共用规则、注册／承托、输入、搬运、真实瞄准、双持、普通工具回归 | AI 分别运行 PLACEMENT_RULES_OK、KITCHEN_SLOTS_OK、GAME_INPUT_OK、DISH_CARRY_OK、DISH_TARGETING_OK、DUAL_WIELD_OK、WORLD_TOOL_USE_OK，均退出 0 |
| 编辑器导入与默认玩法启动 | AI 实际运行 --headless --editor --quit 及 --quit-after 60，退出 0，无脚本错误 |
| 实际画面与整体验收 | AI 用 Godot 图形模式渲染并查看自由盘位移动、杯柄、无效红色及固定架位，归档 4 张截图；最终整体验收来自用户确认 |
| 文件完整性 | git diff --check 通过，42 个脚本 UID 无重复；临时探针、截图脚本和日志不入库 |

### 重跑方式

仓库根目录先导入，再运行专项；成功输出 PLACEMENT_PREVIEW_OK，退出码为 0 且无脚本错误：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script Tools/verify_placement_preview.gd
& $godotExe --headless --path . --script Tools/verify_placement_rules.gd
& $godotExe --headless --path . --script Tools/verify_kitchen_slots.gd
```

其他回归按同一格式运行上表相应 Tools/verify_*.gd；检查只改实例内存，不写场景、配置或玩家存档。F5 拿起餐具，瞄准水槽内部移动准星，检查连续绿／红预览；按 1／2 改选盘杯，瞄准沥水架检查固定完整姿态。尚未绑定清洁状态时架位红色提示为预期，左键和 Q 尚不放下。

### 验收后的文档同步

更新本文件、架构、实施计划、设计文档 0.12、技术栈 0.8、可玩入口说明、文档导航及 AGENTS.md，归档自由预览画面。保持 62 步编号，第 12 步标为通过，第 13 步未开始；旧历史记录保留当时配置并注明现行规则已修正。

## 第 13 步：确认放置、自由来源与水槽重叠堆放（已验收）

### 已完成工作

- 接入 place_dish：点击时读取最新准星、当前 1／2 手位及同一共用规则，拒绝不改持有、位置、占用或匹配状态。成功后把原 DishBody／碰撞直接吸附到完整姿态，归入 PlayableDishes，更新唯一位置／架位占用及该手持有；不复制餐具，不播放与碰撞脱节的飞行动画。增加同物理帧重复提交保护，避免碰撞尚未同步时误放另一手。
- DishBody 增加 REGISTERED／BASIN／HELD 位置类别，BASIN 用原节点 global_transform 记录自由位置，保留局部放置包围盒和实际支撑餐具 ID。HandItem 保存本次 origin_kind、完整 origin_pose 及可选 origin_slot_id；自由餐具再次拿取不要求 SlotState，不读取 initial_slot_id 冒充当前来源。另一手保留实例、位置和手位。
- 预览与确认改为共同读取 DishCarry.dish_states；生产映射仍为空，只有测试注入已知状态。合法确认及再次拿取会同步匹配状态的 is_held／current_slot_id，不更改清洁度、泡沫或施液。架位实际 95% 门槛保留，未知状态继续拒绝，不默认干净。
- 用户追加“餐具在水槽中可以重叠放置”。现已允许盘叠盘、杯放盘上等交叠，用真实槽底与下方陶瓷轮廓计算高度；只有 PlayableDishes 中的 BASIN 餐具成为支撑，托盘／架位餐具仍是遮挡。缓存 12×12 XZ 分区中的最低真实顶点供高度采样，薄三角面查询修正边缘接触，必要时细化高度；最终仍检查环境、工具及餐具的实际几何，不缓存有效性。
- STACKABLE_DISH 明确交互优先级：搬运餐具且未持工具时，瞄准水槽餐具左键叠放、E 拿取；空手仍左键拿取。持工具时，瞄准已放餐具仍左键持续操作，瞄准槽底／架位才放下所持餐具。依赖支撑的下层餐具须先拿走上层，提示“请先拿走上面的餐具”；上层移走清除依赖，再可拿下层。采用静态落位，不模拟滚落、倾倒或刚体平衡。
- 修正普通工具接近槽内餐具的路径：可在安全搬运朝向抬高，检查转向球形余量，越过槽沿后下降；海绵和喷头、两种手位与 F 往返均通过。新增 [verify_dish_placement.gd](../../Tools/verify_dish_placement.gd)、[verify_basin_stacking.gd](../../Tools/verify_basin_stacking.gd) 及 UID，调整输入及既有预览／规则专项；现有 14 份验证脚本、44 个唯一脚本 UID，仍为 17 个输入映射。本步未改 GLB、Blender、生成器或原展示场景。

### 验收结果与来源

用户于 2026-11-26 明确确认第 13 步及水槽重叠堆放最终版本通过，要求更新文档与上传 GitHub，未另附逐项原始日志。下表是 AI 在实施阶段实际执行的检查；不把静态叠放写成刚体物理、实际清洗或完整暂停。

| 验证范围 | 结果与来源 |
| --- | --- |
| 当前目标／手位、实际 95%／泡沫／未知状态、绿色预览后占用／空间／遮挡变化 | DISH_PLACEMENT_OK，最终退出 0 |
| 8 个架位实际确认及再次拿取、倒杯完整姿态、原身份／碰撞／来源、另一手保持、重复请求和 UI／过渡 | 同一专项通过；生产仍不注入虚假清洁状态 |
| 水槽自由位置、连续放下／再次拿取、来源类型和姿态、两工具及两种拿取顺序、普通接触与 F 往返 | 同一专项通过 |
| 两盘一杯交叠、独立网格边线与支撑间隙、上到下拿取、支撑移走后确认重查、工具优先级 | BASIN_STACKING_OK，最终退出 0 |
| 预览、共用规则、输入、普通工具、双持、瞄准及固定槽位 | 最终版本分别运行 PLACEMENT_PREVIEW_OK、PLACEMENT_RULES_OK、GAME_INPUT_OK、WORLD_TOOL_USE_OK、DUAL_WIELD_OK、DISH_TARGETING_OK、KITCHEN_SLOTS_OK，均退出 0 |
| 原单件搬运 | 第 13 步核心实现阶段运行 DISH_CARRY_OK，三餐具案例退出 0；后续叠放版的拿取由上述新两项集成专项覆盖 |
| 导入与默认入口 | 最终 --headless --editor --quit 及 --quit-after 60 均退出 0，无脚本错误 |
| 实际画面 | AI 用 Godot 图形模式渲染并查看自由盘杯、工具接触、再次拿取、已知状态架位，以及叠放预览／落位／下层提示／上层拿取，归档 8 张图；用户确认最终整体验收 |
| 文件完整性 | git diff --check 通过，44 个脚本 UID 无重复；临时捕获／剖析脚本及日志不入库 |

专项记录了单次叠放查询耗时，几何缓存与采样降低了预览计算开销；这不是整场景帧率或 1080p／60 FPS 验收。

### 重跑方式

在仓库根目录先导入，再运行专项；应输出 DISH_PLACEMENT_OK／BASIN_STACKING_OK，退出 0 且无脚本错误：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script Tools/verify_dish_placement.gd
& $godotExe --headless --path . --script Tools/verify_basin_stacking.gd
```

相关回归按同一格式运行上表的 Tools/verify_*.gd，只修改实例内存，不写配置、场景或玩家存档。F5：拿起餐具瞄准绿色水槽落点左键放下；再拿另一件，对准已放餐具左键叠放、E 拿取。上层先取走后可取下层；持工具仍左键操作餐具，E 拿到空手后可按 F 检查沉浸。Q 尚未归回，未知清洁状态的架位仍显示拒绝。

### 验收后的文档同步

更新进度、架构、实施计划、设计文档 0.13、技术栈 0.9、可玩入口、文档导航、相关资产接入补充及 AGENTS.md，归档 8 张实际画面。第 13 步和水槽交叠追加需求标为通过，保持 62 步编号，第 14 步未开始。

## 第 14 步：G 物理松手与移除预览（已验收）

### 已完成工作

- 用户明确取消普通 Q 自动返回，选择“按 G 松手，餐具靠重力自然落下”。普通左键恢复为拿取／工具使用；G 使用当前 1／2 手位，松开选中餐具并保留另一手。沉浸中的 Q/E、中键旋转与 F 保留，G 在沉浸／过渡／界面不执行；按住或重复输入不连发。
- 台面、托盘、地面、水槽共用物理释放，不再自动返回来源或寻找水槽落点。当前真实命中前留出餐具体积和约 6 cm 下落余量；未命中时在镜头前 0.8 m 释放。检查释放空间后交给重力、旋转和碰撞决定最终姿态，边缘可滑落或倾倒，不把最终位置伪装成静态吸附。
- DishBody 保留原查询身体、身份及 RID，增加独立多凸体 RigidBody3D，使用 REGISTERED／HELD／WORLD。松手让运动体独立于跟随节点，原身体同步完整姿态；拿取冻结并收回运动体。共享网格缓存只读凸体，不存可变进度。物理杯口／杯柄孔均验证开放。
- 接入内置 Jolt 并配置 0.5 mm 接触穿透容差、2 mm 预测接触和 4 次位置迭代。运动层 32、WORLD 掩码 46，不包含封住水槽的玩家柜体代理 16；交互掩码仍为 13。真实表面内部改为 10 倍局部坐标，准星增加四条 0.1 mm 平行偏移射线并取最近命中，处理共享顶点漏检。世界范围改为 2 米以便拿取地面餐具，工具原位限制仍为 1.5 米。
- 移除 PlacementPreview 节点、脚本／UID、PlacementHint 标签、预览信号、PLACEMENT_SURFACE／STACKABLE_DISH 路由、check_surface_placement／evaluate_surface、静态叠放高度求解、底圈／叠放采样和 support_dish_ids。自由支撑交给物理模拟，不再施加“先拿上层”的静态依赖锁。
- 只有 8 个沥水架位保留固定完整姿态：按 G 重查共用资格，未知或未到实际 95% 不入架；成功才冻结原餐具并同步唯一占用及匹配状态。DishCarry.dish_states 生产仍为空，专项注入已知状态验证架位，不把自由物理放下当作已完成清洗。
- 新增 [verify_dish_drop.gd](../../Tools/verify_dish_drop.gd) 与 UID；重写放置、堆放与原预览专项以验证当前行为。现有 15 份验证脚本、44 个唯一 UID、18 个输入映射。未修改 GLB、Blender、资产生成器或展示场景。

### 验收结果与来源

用户于 2026-11-26 确认最终 G 物理松手及无预览版本通过，并要求更新文档与上传 GitHub；未另附逐项原始日志。以下是 AI 在实施阶段实际运行的检查，均以最终通过结果记录，不把用户确认写成 AI 真实试玩。

| 验证范围 | 实际结果 |
| --- | --- |
| G 盘杯下落、盆体／托盘／台面边缘／地面、原实例再次拿取、状态、物理开口、双手、重复请求、阻止上下文、两工具／两种拿取顺序及 F | DISH_DROP_OK，退出 0 |
| 8 架位 G 提交、完整姿态／占用／再拿取、左键不放置、未知／未达实际 95% 拒绝 | DISH_PLACEMENT_OK，退出 0 |
| 两盘一杯真实重力和陶瓷碰撞、盆内交叠、无槽位／静态依赖与再次拿取 | BASIN_STACKING_OK，退出 0 |
| 预览与绿／红标签已移除，瞄准不提交或预留、展示器独立 | PLACEMENT_PREVIEW_OK，退出 0；保留历史脚本名 |
| 共用架位规则、目标表面、正式注册、双持、普通工具、原搬运 | PLACEMENT_RULES_OK、DISH_TARGETING_OK、KITCHEN_SLOTS_OK、DUAL_WIELD_OK、WORLD_TOOL_USE_OK、DISH_CARRY_OK，均退出 0 |
| Jolt 下玩家碰撞／WASD 与镜头、输入和 GUI 消费 | PLAYER_MOVEMENT_OK、MOUSE_LOOK_OK、GAME_INPUT_OK，均退出 0 |
| 独立状态与实际清洁门槛 | RUNTIME_STATE_OK、CLEANLINESS_OK，均退出 0 |
| 最终导入、默认玩法入口 | --headless --editor --quit 与 --quit-after 60 均退出 0，无脚本错误 |
| 实际画面 | AI 使用 Godot 图形模式渲染并查看松手前、下落中、盆内落稳、自然堆放和地面餐具 5 张图；用户确认整体手感 |
| 文件完整性 | git diff --check 通过，44 个脚本 UID 无重复；临时捕获／探针和缓存不入库 |

物理测试覆盖当前三件盘杯的典型交互，不代表整单清洗、完整暂停、分类收纳或开发机 1080p／60 FPS 目标已验收。

### 重跑方式

在仓库根目录先导入，再运行专项；全部应退出 0 且无脚本错误：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script Tools/verify_dish_drop.gd
& $godotExe --headless --path . --script Tools/verify_dish_placement.gd
& $godotExe --headless --path . --script Tools/verify_basin_stacking.gd
& $godotExe --headless --path . --script Tools/verify_placement_preview.gd
```

其余脚本使用相同格式重跑。F5：左键／E 拿餐具，按 1／2 选择后 G 松手；查看水槽下落与叠放、地面捡起。持工具仍按住左键操作，E 拿到餐具后 F 沉浸，中键／Q/E 旋转。普通 Q 不再返回，画面没有放置预览。

### 文档与画面归档

2026-11-27 完成验收后的文档同步与提交准备。同步设计文档 0.14、技术栈 0.10、实施计划、架构、可玩入口、导航、相关资产接入说明和 AGENTS.md。归档 [松手前](../scenes/kitchen-game/step14-free-carry.png)、[下落中](../scenes/kitchen-game/step14-free-falling.png)、[盆内落稳](../scenes/kitchen-game/step14-free-basin.png)、[自然堆放](../scenes/kitchen-game/step14-free-stack.png)及[地面餐具](../scenes/kitchen-game/step14-free-floor.png)。第 14 步标记已验收，保持 62 步编号，下一项为第 15 步。

## 第 15 步：F 沉浸切换的场景覆盖（已验收）

### 已完成工作

- 新增 [verify_close_transition.gd](../../Tools/verify_close_transition.gd) 及 UID，复用双持专项的真实场景和输入辅助方法。餐盘／马克杯、海绵／喷头、两种拿取顺序与五组站位／朝向组成 40 组 F 往返，覆盖玩家与相机位置／方向／FOV、约 0.2 秒过渡、身份／查询 RID、稳定手位、来源、占用与冻结运动体。
- 在 [dish_carry.gd](../../Scripts/Dishes/dish_carry.gd) 为 F 的进入与退出增加保持餐具角度的包围盒路径扫掠，排除两手已持 RID。进入保留原终点空间检查；途中存在障碍时拒绝切换，保留原物品和当前模式并提示空间不足。
- 退出先确认搬运安全姿态求解成功，再检查返回路径；失败留在沉浸，不再使用旧 safe_pose。工具自由移动到餐具两侧后返回时，F 专用搬运求解排除另一手持物，修复两件物品相互阻挡、餐具异常贴近镜头的问题；真实环境仍参与避障，近架体时可保留正常缩短的搬运距离。
- 进入过渡在菜单打开后完成时不再把菜单光标移回餐具中心。Esc／失焦阻止输入并保留切换目的模式，恢复不重放旧 WASD、左键使用或旋转；当前过渡和自由刚体仍继续运行，完整冻结保持第 18 步范围。
- 验证过渡中重复 F、G、E 无额外动作，沉浸中 WASD 不移动、Q/E 只旋转，F 返回后新 WASD 与直接鼠标观察可用。专项注入已知 DishState，确认各区域污渍、泡沫及施液资格保持不变；生产 dish_states 仍为空，不把测试数据接入玩法。
- 保留 G 物理松手、无预览、普通 Q 无返回及沉浸中键／Q/E 规则。本步只修改持物脚本并新增专项及 UID；未修改场景、输入映射、project.godot、GLB、Blender 源文件、生成器或展示器。当前 16 份验证脚本、45 个唯一 GDScript UID、18 个输入映射。

### 验收结果与来源

用户于 2026-11-27 明确确认第 15 步验证通过，并要求更新文档、上传 GitHub，未另附逐项原始日志。下表为 AI 在实施阶段实际执行的检查；用户手感验收与自动／图形检查分别记录。

| 验证范围 | 最终结果与来源 |
| --- | --- |
| 40 组盘杯／工具／手位／站位朝向 F 往返，原实例、来源、占用、视角和状态保留 | CLOSE_TRANSITION_OK，退出 0，无脚本错误 |
| 真实墙体、终点和途中障碍、搬运返回空间不足、移开障碍后重试、喷头原位超距 | 同一专项通过；拒绝保留物品与模式，提示原因 |
| 切换约 0.2 秒、重复 F／G／E、沉浸行走锁定、Q/E 不退出、返回后的新输入 | 同一专项通过 |
| Esc／失焦发生在进入与退出途中，恢复不续用旧操作 | 同一专项通过；图形模式另验证鼠标可见／捕获和菜单光标不被重置 |
| 双持、普通工具、G 松手 | DUAL_WIELD_OK、WORLD_TOOL_USE_OK、DISH_DROP_OK 均退出 0；双手返回修复后重跑通过 |
| 输入、鼠标观察与展示器、行走、原搬运 | GAME_INPUT_OK、MOUSE_LOOK_OK、PLAYER_MOVEMENT_OK、DISH_CARRY_OK 均退出 0 |
| 导入与默认入口启动 | --headless --editor --quit、--quit-after 60 均退出 0，无脚本错误 |
| 图形模式 | Compatibility 下实际运行、捕获并查看 5 张画面；图形中断／鼠标检查零失败，用户确认本步整体验收 |
| 文件完整性 | git diff --check 通过，45 个脚本 UID 唯一；临时验证／捕获脚本、缓存和日志不入库 |

实施阶段先复现并修复终点检查遗漏路径、返回忽略求解失败的问题；图形检查又发现并修复自由工具导致的双手返回互挡。专项区分近架体的正常避障与异常贴近镜头，不以强制穿过环境恢复完整锚点。本步没有重跑其余八份规则／数据／放置专项，其最近执行来源保留在此前记录；不宣称本步运行了全部 16 份脚本。

### 重跑方式

在仓库根目录先导入，再运行专项；应输出 CLOSE_TRANSITION_OK、退出 0 且无脚本错误：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script Tools/verify_close_transition.gd
& $godotExe --headless --path . --script Tools/verify_dual_wield.gd
& $godotExe --headless --path . --script Tools/verify_world_tool_use.gd
& $godotExe --headless --path . --script Tools/verify_dish_drop.gd
```

其他相关回归按相同格式执行上表脚本。专项只改实例内存，不写场景、配置或玩家存档。无头模式不验证真实窗口的鼠标捕获；F5 拿取盘／杯与海绵／喷头，从不同位置、朝向反复 F，移动工具到两侧后退出，检查手位、角度、正常搬运距离与视角；切换途中 Esc／Alt+Tab 后明确恢复，旧输入不得继续。背景模糊和完整暂停不作为本步已实现功能。

### 验收后的文档与画面归档

同步进度、架构、实施计划、设计文档 0.15、技术栈 0.11、可玩入口、文档导航与 AGENTS.md。归档 [搬运](../scenes/kitchen-game/step15-carry-left.png)、[切换中](../scenes/kitchen-game/step15-transition.png)、[沉浸餐盘](../scenes/kitchen-game/step15-close-plate.png)、[恢复手位](../scenes/kitchen-game/step15-return-left.png)与[沉浸马克杯](../scenes/kitchen-game/step15-close-mug.png) 5 张实际画面。第 15 步标记已验收，保留 62 步编号，第 16 步未开始。

## 第 16 步：旋转与滚轮范围、普通中键修正（已验收）

### 已完成工作

- 普通与沉浸统一用中键拖动旋转餐具；普通只操作 1／2 当前选中的原实例，另一手保持角度，旋转不转动相机或修改 FOV。沉浸保留中键及 Q/E 的方向、停止与工具自由状态，Q/E 同时按住抵消。普通 Q 不恢复返回，E 保留拿取／归回优先级。
- 复用既有 game_rotate_close 中键映射，扩展到普通持餐具状态；game_rotate 右键只在普通空手、只持工具或测试持瓶上下文放大观察，持餐具时不旋转或放大，沉浸右键行为不变。右键释放不结束中键旋转；选择另一手、G 松手、菜单、失焦或模式切换结束旧旋转，恢复需新按下。
- 在 [dish_body.gd](../../Scripts/Dishes/dish_body.gd) 增加 close_min_distance／close_max_distance：餐盘默认 0.40～0.56 m，[mug.tscn](../../Scenes/Dishes/mug.tscn) 覆盖为 0.36～0.52 m。[HandItem](../../Scripts/Dishes/hand_item.gd) 独立记录 close_distance，默认 0.45 m，仅沉浸滚轮每格 0.02 m，上滚拉近、下滚推远；普通、过渡及界面不调距，同次持有的 F 往返保留所选距离与角度。
- 在 [dish_carry.gd](../../Scripts/Dishes/dish_carry.gd) 将旋转按最多 3° 的小步检查，结合包围盒、半径对应的弧线余量与 near + 0.015 m 边界，受阻停止并给出反馈；保留完整翻面能力，不以固定角度限制挡住盘背或杯内。滚轮按类型上下限、真实空间及平移路径检查，失败保留当前距离；旋转／滚轮均停止旧工具使用，调整后需重新按左键。
- 沉浸射线补充与世界查询相同的四条 0.1 mm 偏移射线，取最近真实命中，减少 Jolt 三角接缝处因旋转或调距导致的漏检。HUD 同步普通中键、当前餐具及沉浸滚轮提示。
- 新增 [verify_dish_manipulation.gd](../../Tools/verify_dish_manipulation.gd) 与 UID；更新输入、镜头专项的普通中键预期。保留原盘杯身份、占用、来源与匹配状态，生产仍不注入清洁状态。未修改 GLB、Blender、资产生成器、F6 展示器、项目映射或其他手工入口；当前 17 份验证脚本、46 个唯一 UID、18 个输入映射。

### 验收结果与来源

用户于 2026-11-27 要求普通模式同样采用中键，修正后明确确认验证通过，并要求更新文档与上传 GitHub；未另附逐项原始日志。下表区分 AI 实际执行与用户确认，不将本步写为完整清洗、背景模糊或性能验收。

| 验证范围 | 实际结果与来源 |
| --- | --- |
| 普通双餐具的 1／2 选择、中键只旋转当前实例、另一手与镜头保持、普通滚轮／Q 无调整 | DISH_MANIPULATION_OK，最终退出 0；中键修正后重跑通过 |
| 盘杯 × 海绵／喷头 × 两种手位顺序共 8 组合，距离上下限、翻面、杯内／背面真实命中、倾斜面工具接触、实际顶点近裁剪与旋转基底 | 同一专项通过，工具及餐具在检查姿态下均保持近裁剪余量 |
| 旋转弧线／滚轮路径遇障碍、撤去障碍后恢复、调整中断工具使用、F 保留角度／距离／身份／状态 | 同一专项通过 |
| Q/E 在 30／120 Hz 下按物理时间旋转、相反按键抵消 | 同一专项通过；不是图形性能测试 |
| 普通中键分派、右键释放隔离、菜单／失焦旧输入清理、相机与原展示器 | GAME_INPUT_OK、MOUSE_LOOK_OK 均退出 0；中键修正后重跑通过 |
| 双持、F 场景覆盖、普通工具、原搬运、G 松手 | 实施阶段运行 DUAL_WIELD_OK、CLOSE_TRANSITION_OK、WORLD_TOOL_USE_OK、DISH_CARRY_OK、DISH_DROP_OK，均退出 0；普通中键修正后重点重跑上述新专项、输入与镜头 |
| 导入与默认入口启动 | --headless --editor --quit、--quit-after 60 均退出 0，无脚本错误 |
| 实际画面 | Compatibility 图形模式运行并查看 6 张画面；中键修正后重新捕获普通选中右手与 F 返回两张，图形中键／右键隔离检查零失败；用户确认最终整体验收 |
| 文件完整性 | git diff --check 通过，46 个脚本 UID 唯一；临时捕获脚本、日志及缓存不入库 |

本步运行新专项及 7 项相关回归；普通中键修正后复测新专项、输入、镜头和图形操作。其余九份专项（含数据、规则、放置及行走）的最近执行来源保留在前述记录，不宣称本步重跑全部 17 份脚本。

### 重跑方式

仓库根目录先导入，再执行专项；应输出 DISH_MANIPULATION_OK，退出 0 且无脚本错误：

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script Tools/verify_dish_manipulation.gd
& $godotExe --headless --path . --script Tools/verify_game_input.gd
& $godotExe --headless --path . --script Tools/verify_mouse_look.gd
```

其他回归按相同格式运行上表脚本。F5：拿起两件餐具，按 1／2 选择后中键拖动，确认只转当前餐具且相机不动；拿取盘／杯和工具，F 后翻看盘背／杯内，滚轮反复到上下限、按住 Q/E 或中键旋转，再 F 往返，确认角度、距离与手位保留。Esc／Alt+Tab 恢复后不续用旧操作。无头检查不代替真实窗口捕获或手感验收。

### 验收后的文档与画面归档

同步进度、架构、实施计划、设计文档 0.16、技术栈 0.12、可玩入口、导航和 AGENTS.md。归档 [普通右手中键旋转](../scenes/kitchen-game/step16-selected-right.png)、[餐盘最近距离背面](../scenes/kitchen-game/step16-plate-near-back.png)、[餐盘最远距离背面](../scenes/kitchen-game/step16-plate-far-back.png)、[杯内最近距离](../scenes/kitchen-game/step16-mug-near-inside.png)、[杯子最远距离倾斜](../scenes/kitchen-game/step16-mug-far-tilted.png)和[F 返回搬运](../scenes/kitchen-game/step16-return-carry.png) 6 张实际画面。第 16 步及普通中键修正标为已验收，保留 62 步编号，第 17 步未开始。

## 第 17 步：近距离背景模糊（已验收）

### 已完成工作

- 新增 [immersion_focus.gd](../../Scripts/Rendering/immersion_focus.gd)、[背景着色器](../../Shaders/immersion_background_blur.gdshader)及各自 UID，仅在手工玩法入口接入。保留 Compatibility，以屏幕纹理 mip LOD 3.2 混合厨房背景；F 进入／退出时约 0.2 秒淡入／淡出，不移动玩家、改变观察方向或 FOV。
- 清晰 SubViewport 共享原 World3D，以同步投影的相机绘制原餐具、工具及喷头软管，不复制身份或碰撞。临时将原持物置于渲染层 20 并从背景相机排除；原灯光加入层 19，保证清晰前景的亮度与单次渲染基线一致。透明前景按预乘 alpha 合成，保留杯柄孔洞及透明边缘；HUD 在更高层，效果不消费鼠标。
- 每次绘制前同步变换、FOV、裁剪、MSAA 和实际渲染像素。图形检查发现 Window 纹理报告尺寸与实际捕获像素不同，现根据可见区域和拉伸变换确定尺寸，窗口变化后仍与原视角一致。进入受阻不启用；菜单／失焦保持目的模式效果，退出及清理恢复原网格／灯光层和相机掩码，并停止额外视口渲染。
- 新增 [verify_immersion_focus.gd](../../Tools/verify_immersion_focus.gd) 与 UID。当前 18 份验证脚本、48 个唯一 GDScript UID，另有 1 个着色器 UID，输入仍为 18 个映射。未修改 GLB、Blender、资产生成器、F6 展示器或物理／交互规则；实际污渍与泡沫仍待后续，新建视觉网格须纳入清晰前景。

### 验收结果与来源

用户于 2026-11-27 明确确认“验证通过”，并要求更新文档和上传 GitHub；未另附逐项原始日志。AI 在实施阶段实际运行下列检查，最终均退出 0，图形最终运行无脚本或资源释放错误；不将用户确认冒充 AI 手动执行的真实 Alt+Tab 操作。

| 验证范围 | 实际结果与来源 |
| --- | --- |
| F 淡入／淡出、四组工具／手位、原身份／RID／状态／视角、渲染层／掩码恢复、失败进入不启用 | IMMERSION_FOCUS_OK，无头及图形模式均通过 |
| 真实餐具射线与工具接触、菜单／失焦通知、继续按钮实际鼠标事件、进入／退出中断、F6 隔离 | 同一专项通过；恢复不续用旧工具输入 |
| 餐盘＋海绵、杯子＋喷头，各左中右站位、最近／最远距离，共 12 组真实图形对照 | 背景像素变化超过阈值，清晰前景与零模糊及原单次渲染基线相符；杯内、工具和 HUD 可见 |
| 杯柄孔洞与 40% alpha 透明测试片、窗口 1024×768／1920×1080 | 两组图形对照通过；前者内容区为 1024×576，保持原画面比例，前景尺寸与实际捕获一致 |
| 输入、镜头、原搬运、双持、普通工具、F 站位往返、旋转／调距 | GAME_INPUT_OK、MOUSE_LOOK_OK、DISH_CARRY_OK、DUAL_WIELD_OK、WORLD_TOOL_USE_OK、CLOSE_TRANSITION_OK、DISH_MANIPULATION_OK，7 项回归均退出 0 |
| 导入与默认入口 | --headless --editor --quit、--quit-after 60 均退出 0 |
| 视觉与用户验收 | AI 查看实际图形画面并归档 7 张代表图；用户确认本步通过 |
| 提交前文档与文件检查 | git diff --check、七份 Markdown 的本地链接、性能原始均值对照均通过；48 个 GDScript UID 和 1 个着色器 UID 无重复 |

本步执行新专项及上述 7 项回归，未重跑全部 18 份脚本。数据、放置、G 物理松手、堆放与行走等其他专项的最近来源保留在历史步骤中。

### 初步渲染开销

开发机：i5-12400F、约 32 GiB 内存、RTX 2080 Ti，Windows 11 专业版 10.0.22631；Godot 4.7.2／OpenGL 3.3 Compatibility，驱动报告 591.86。1920×1080、沿用项目 MSAA，暂时关闭垂直同步，预热后每态采样 30 帧。对比保持同一沉浸姿态的原单次渲染与启用模糊合成；不是普通远距离搬运与沉浸的不同视角比较。

| RenderingServer 平均耗时 | 原单次渲染 | 模糊＋清晰前景 | 增量 |
| --- | --- | --- | --- |
| CPU 渲染（含 frame setup） | 0.652 ms | 0.997 ms | 0.346 ms |
| GPU 渲染 | 0.587 ms | 0.984 ms | 0.397 ms |

CPU 包含帧准备与活跃视口渲染，GPU 汇总活跃视口；原始均值、环境及采样方法已归档到 [step17-render-timing.json](../scenes/kitchen-game/step17-render-timing.json)。此处只记录当前场景的渲染工作，未证明完整 MVP 稳定 60 FPS、最低配置、导出包或第二台机器性能。

### 重跑方式

仓库根目录运行；两种模式均应输出 IMMERSION_FOCUS_OK 并退出 0。无头模式会明确输出 FOCUS_GRAPHICS_SKIPPED，不将其当作视觉或性能验证。

```powershell
$godotExe = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script Tools/verify_immersion_focus.gd
& $godotExe --path . --script Tools/verify_immersion_focus.gd -- --capture
```

图形模式会保存对照 PNG 和本机耗时 JSON 到忽略的 Temp 目录；性能采样结束恢复原垂直同步设置。7 项回归按同格式运行上表脚本。F5 可拿取盘／杯与海绵／喷头，检查不同站位、滚轮距离、旋转、F 往返及 Esc／失焦恢复时背景与前景的表现。

### 验收后的文档与画面归档

同步五份 memory-bank、可玩入口、导航和 AGENTS.md，设计文档更新为 0.17、技术栈为 0.13。归档 [零模糊对照](../scenes/kitchen-game/step17-focus-reference.png)、[中心餐盘](../scenes/kitchen-game/step17-focus-plate.png)、[左侧最远](../scenes/kitchen-game/step17-focus-left.png)、[中心杯内](../scenes/kitchen-game/step17-focus-mug.png)、[右侧最远](../scenes/kitchen-game/step17-focus-right.png)、[透明检查片与杯柄](../scenes/kitchen-game/step17-focus-alpha.png)及[退出搬运](../scenes/kitchen-game/step17-return-carry.png) 7 张图形画面；蓝色透明片仅属于验证夹具。保留 62 步编号，第 17 步标为已验收，第 18 步未开始。

## 后续衔接

下一项为第 18 步暂停与失焦处理：Esc 及失焦须冻结过渡、自由运动刚体和工具等运行状态，恢复时清除旧移动、左键和旋转输入。当前仍只阻止输入，不能把已通过的菜单交互检查当成完整暂停。

保留已验收的 F 模糊与清晰前景、两态中键、沉浸 Q/E、类型滚轮范围、G 物理松手和无预览。正式订单接入仍须协调唯一占用并清理独立 motion_body；供水、湿润、施液、去污、评分、保存及完整性能目标继续按后续步骤验证。
