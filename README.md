# Growth

> 2026 GameJam 项目 · 主题 **Grow** · 引擎 Godot 4.7 · 语言 GDScript

GameJam 时限内交付一款以"生长（Grow）"为核心机制的可玩原型。架构优先"快速决策 → 快速落地"，玩法细节待团队冻结。

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
├── Scenes/                  # 场景（Main / Levels / UI / Entities）
├── Scripts/
│   ├── Autoload/            # 全局单例：GameManager / EventManager / ResourceManager / AudioManager
│   ├── Core/                # Main.gd / GameScene.gd 基类
│   ├── Systems/             # 玩法系统（玩法冻结后填充）
│   ├── Entities/            # Player / Enemy / Pickup
│   ├── UI/  Utils/
├── Resources/               # .tres / JSON 数据（Cards/Enemies/Skills/Passives/Characters/Config）
├── Art/  Audio/  Models/  UI/   # 二进制资源（Git LFS）
├── docs/                    # 开发文档 / 架构 / 环境搭建 / 玩法需求 / AI 智能体
└── AGENTS.md                # AI 智能体角色与协作约定
```

## 文档导航

| 文档 | 用途 |
|------|------|
| [docs/开发文档.md](docs/开发文档.md) | 规范权威源（资源 / 命名 / 数据 / 提交） |
| [docs/architecture/架构说明.md](docs/architecture/架构说明.md) | 分层 / Autoload / 事件总线 / 场景编排 |
| [docs/development/环境搭建指南.md](docs/development/环境搭建指南.md) | 15 分钟配好开发环境 |
| [docs/design/功能需求文档.md](docs/design/功能需求文档.md) | Grow 主题玩法需求模板（待冻结） |
| [AGENTS.md](AGENTS.md) | AI 智能体角色与职责 |
| [docs/agents/skills/](docs/agents/skills/) | 智能体技能模块 |
| [docs/agents/rules/](docs/agents/rules/) | 编码规范 / 协作规范 |

## 架构要点
- **Autoload 单例**：`GameManager`（状态/场景）、`EventManager`（信号总线）、`ResourceManager`（资源缓存）、`AudioManager`（音频）。
- **通信解耦**：跨系统走 `EventManager.*`，取资源走 `ResourceManager.*`，播音频走 `AudioManager.*`。
- **玩法扩展点**：新系统 → `Scripts/Systems/`；新实体 → `Scripts/Entities/`；新信号 → `EventManager` 末尾 Hook 区。

## 许可
见 [LICENSE](LICENSE)。
