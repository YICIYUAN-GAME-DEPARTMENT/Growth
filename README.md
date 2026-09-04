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

用 Godot 4.7 stable 打开 `project.godot`，按 **F5** 运行（入口 `Scenes/Main.tscn`）。详细环境配置见 [docs/development/环境搭建指南.md](docs/development/环境搭建指南.md)。

## 项目结构

```
Growth/
├── project.godot            # 引擎配置（GDScript / Forward+ / Jolt / d3d12）
├── Scenes/
│   ├── Main.tscn            # 根场景（WorldRoot + UIRoot）
│   ├── Levels/              # 关卡通用场景 Level.tscn
│   ├── UI/                  # MainMenu / LevelSelect / HUD / 结算
│   └── Entities/            # Player / Mechanism / Food / Goal 预制
├── Scripts/
│   ├── Autoload/            # GameManager / EventManager / ResourceManager / AudioManager / SaveManager
│   ├── Core/                # Main.gd / GameScene.gd / LevelScene.gd
│   ├── Systems/             # GridSystem（网格+BFS）/ MechanismSystem
│   ├── Entities/            # Player / Mechanism / Food / Goal
│   ├── UI/  Data/  Utils/   # UI 逻辑 / 数据类 / 工具
├── Resources/
│   ├── Levels/              # LVL_*.tres（LevelDefinition 关卡数据）
│   └── Config/              # Balance.tres（全局数值）
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
| [AGENTS.md](AGENTS.md) | AI 智能体角色与职责 |
| [docs/agents/skills/](docs/agents/skills/) | 智能体技能模块 |
| [docs/agents/rules/](docs/agents/rules/) | 编码规范 / 协作规范 |

## 架构要点
- **Autoload 单例**：`GameManager`（状态/场景）、`EventManager`（信号总线）、`ResourceManager`（资源缓存）、`AudioManager`（音频）、`SaveManager`（解锁/步数存档）。
- **通信解耦**：跨系统走 `EventManager.*`，取资源走 `ResourceManager.*`，播音频走 `AudioManager.*`。
- **数据驱动关卡**：单一 `Level.tscn` + `Resources/Levels/LVL_*.tres`；规则数值来自 `Balance.tres`，脚本禁硬编码。
- **网格判定**：走格子/BFS 全部基于数据，不使用物理碰撞。

## 许可
见 [LICENSE](LICENSE)。
