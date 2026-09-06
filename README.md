# Growth · 阿吉与花海（algee & blooms）

> 2026  YIGUANG Project GameJam · 主题 **Grow** · 引擎 Godot 4.7 · 语言 GDScript

**《阿吉与花海》（algee & blooms）**是一款 2D 俯视网格解谜游戏。不能接触花朵的阿吉（algee）和保护她的机器人查理（charlie）结伴走进花园，去寻找那些闪闪发亮的**蓝花**。

阿吉与查理之间连接着联系他们生命的"管道"，阿吉走到哪、管道就铺到哪，而查理一直在起点等待。管道越长，能探到的地方越远；但场上错落的**花丛**每走几步就会扩张一圈，悄悄把路堵死。收集路上散落的**花瓣**能让身长上限增加，折返踏回铺过的管道还能就地"截断"重新规划。每一步都在抉择：**走哪条路，才能赶在花丛合拢前摘到蓝花？**

玩法规则见 [功能需求文档（权威）](docs/design/功能需求文档.md)，工程规范见 [开发文档（权威）](docs/开发文档.md)。

## 快速开始

```powershell
git clone https://github.com/YICIYUAN-GAME-DEPARTMENT/Growth.git
cd Growth
git lfs install
git lfs pull
```

用 Godot 4.7 stable 打开 `project.godot`，按 **F5** 运行（入口 `Scenes/UI/MainMenu.tscn`，主菜单→选关→关卡）。详细环境配置见 [docs/development/环境搭建指南.md](docs/development/环境搭建指南.md)。

## 项目结构

```
Growth/
├── project.godot            # 引擎配置（GDScript / Forward+ / 入口 MainMenu）
├── Scenes/
│   ├── UI/                  # MainMenu（入口）/ LevelSelect / LevelHUD
│   ├── Levels/              # LevelTemplate + Level_<nn>.tscn（关卡即场景，直编）
│   └── Entities/            # PlayerSpawn / Food / Goal / Mechanism
├── Scripts/
│   ├── Autoload/            # GameManager(balance) / EventManager / SaveManager
│   ├── Systems/             # Level.gd / GridSystem（网格+BFS）
│   ├── Entities/            # CellEntity 基类 / PlayerSpawn / Food / Goal / Mechanism
│   ├── UI/  Data/           # UI 逻辑 / 数据类（Balance/MechanicShapes/GridMetrics）
├── Resources/
│   ├── Config/              # Balance.tres（全局数值，可 Inspector 直接调）
│   └── Dialogue/            # 剧情剧本 / 角色注册表（JSON）
├── Art/                     # Sprites / Tiles / Portraits / UI / Backdrops（正式美术 + 占位，登记 A-xx，见开发文档 §3.9）
├── Audio/                   # SFX / Music（音频目录占位）
├── tools/                   # 贴图/瓦片集生成工具（headless 运行）
├── docs/                    # 开发文档 / 功能需求 / 架构 / 环境 / 技能 / 规则
└── AGENTS.md                # AI 智能体角色与协作约定
```

## 文档导航

| 文档 | 定位 |
|------|------|
| [docs/开发文档.md](docs/开发文档.md) | **工程规范·权威**（架构 / 目录 / 命名 / 数据 / LFS / 协作） |
| [docs/design/功能需求文档.md](docs/design/功能需求文档.md) | **产品需求·权威**（玩法规则 / 界面 / 关卡 / 数值 / 验收） |
| [docs/design/玩法说明.md](docs/design/玩法说明.md) | 设计推导与决策记录（追溯用，已被权威文档取代） |
| [docs/architecture/架构说明.md](docs/architecture/架构说明.md) | 分层 / Autoload / 事件总线 / 场景编排细节 |
| [docs/development/环境搭建指南.md](docs/development/环境搭建指南.md) | 15 分钟配好开发环境 |
| [docs/development/关卡制作指南.md](docs/development/关卡制作指南.md) | **设计者：新建/摆放关卡** |
| [AGENTS.md](AGENTS.md) | AI 智能体角色与职责 |
| [docs/agents/skills/](docs/agents/skills/) | 智能体技能模块 |
| [docs/agents/rules/](docs/agents/rules/) | 编码规范 / 协作规范 |

## 玩法与架构要点

- **核心循环**：S 出发 → 一格一格走 / 截断重规划 → 吃花瓣（L+2）→ 每满 N 步花丛全体扩张 → 踏入蓝花=胜；无路可走 / 身长够不到（BFS）判负。N 默认 6，单关可 override（`growth_step_interval_override`）。
- **数值集中**：初始 L / ΔL / 机关最高阶段 / 生长周期在 `Resources/Config/Balance.tres`（@export，Inspector 直接调）；单关可用 Level 根节点 `*_override` 覆盖；脚本禁硬编码。
- **Autoload 单例**：`GameManager`（状态/场景/持有 Balance）、`EventManager`（信号总线）、`SaveManager`（每关最佳步数存档）。
- **关卡=场景直编**：每关一个 `Scenes/Levels/Level_<nn>.tscn`，在编辑器里摆 PlayerSpawn/Goal/Food/Mechanism 实体；可走区=Ground 层实际涂格，障碍用 `Obstacles` TileMapLayer 涂格（非实体）。
- **网格判定**：走格子 / 截断 / BFS 死局判定全部基于数据（GridSystem），不使用物理碰撞。
- **头/尾视觉**：身体中段=`PlayerCells` 管道瓦片自动拼直/弯；头=阿吉精灵表（4 方向 × 移动/停留帧）、尾=查理贴图固定在起点 S，二者为独立 Sprite（`PlayerFx`），运行期驱动。
- **剧情演出**：部分关卡带 AVG 对话（进关 / 胜利 / 失败触发点可选挂剧情），数据在 `Resources/Dialogue/`，覆盖层运行时懒实例。

## 许可
见 [LICENSE](LICENSE)。
