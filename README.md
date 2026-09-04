# Growth

> 2026 GameJam 项目 · 主题 **Grow** · 引擎 Godot 4.7 · 语言 GDScript

**2D 俯视网格解谜游戏**（暂定代号 "绳蛇解谜"）：主角尾部钉死在起点、身长受限；吃食物能增长最大身长，但每走 6 步场上的机关会同步扩张、堵死路径。规划路线，在"够得着终点"和"路被堵死"之间找到解。

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
│   ├── UI/                  # MainMenu（入口）/ LevelSelect
│   ├── Levels/              # LevelTemplate + Level_<nn>.tscn（关卡即场景，直编）
│   └── Entities/            # PlayerSpawn / Obstacle / Food / Goal / Mechanism(+5阶段)
├── Scripts/
│   ├── Autoload/            # GameManager(balance) / EventManager / AudioManager / SaveManager
│   ├── Systems/             # Level.gd / GridSystem（网格+BFS）
│   ├── Entities/            # CellEntity / PlayerSpawn / Obstacle / Food / Goal / Mechanism
│   ├── UI/  Data/  Utils/   # UI 逻辑 / 数据类 / 工具
├── Resources/
│   └── Config/              # Balance.tres（全局数值，可 Inspector 直接调）
├── Art/  Audio/             # 美术 / 音频（Git LFS）
├── docs/                    # 开发文档 / 功能需求 / 架构 / 环境 / 技能 / 规则
└── AGENTS.md                # AI 智能体角色与协作约定
```

## 文档导航

| 文档 | 定位 |
|------|------|
| [docs/开发文档.md](docs/开发文档.md) | **工程规范·权威**（架构 / 目录 / 命名 / 数据 / LFS / 协作） |
| [docs/design/功能需求文档.md](docs/design/功能需求文档.md) | **产品需求·权威**（玩法规则 / 界面 / 关卡 / 数值 / 验收） |
| [docs/design/玩法说明.md](docs/design/玩法说明.md) | 设计推导与决策记录（追溯用） |
| [docs/architecture/架构说明.md](docs/architecture/架构说明.md) | 分层 / Autoload / 事件总线 / 场景编排细节 |
| [docs/development/环境搭建指南.md](docs/development/环境搭建指南.md) | 15 分钟配好开发环境 |
| [docs/development/关卡制作指南.md](docs/development/关卡制作指南.md) | **设计者：新建/摆放关卡** |
| [AGENTS.md](AGENTS.md) | AI 智能体角色与职责 |
| [docs/agents/skills/](docs/agents/skills/) | 智能体技能模块 |
| [docs/agents/rules/](docs/agents/rules/) | 编码规范 / 协作规范 |

## 架构要点
- **Autoload 单例**：`GameManager`（状态/场景/持有 Balance）、`EventManager`（信号总线）、`ResourceManager`（资源缓存）、`AudioManager`（音频）、`SaveManager`（步数存档）。
- **通信解耦**：跨系统走 `EventManager.*`，播音频走 `AudioManager.*`。
- **关卡=场景直编**：每关一个 `Scenes/Levels/Level_<nn>.tscn`，在编辑器里直接摆放 PlayerSpawn/Obstacle/Food/Goal/Mechanism 节点（拖动吸附格子）。
- **数值集中**：初始 L / ΔL / 生长步数都在 `Resources/Config/Balance.tres`（@export，Inspector 直接调）；脚本禁硬编码。
- **网格判定**：走格子/BFS 全部基于数据（GridSystem），不使用物理碰撞。

## 许可
见 [LICENSE](LICENSE)。
