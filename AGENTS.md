# AGENTS.md

> 本文件定义 Growth 项目中 AI 智能体与人类成员的角色、职责边界与协作约定。
> 所有 AI 智能体在本仓库工作时，**必须先读本文件**，并遵循 [docs/agents/rules/](docs/agents/rules/) 与 [docs/开发文档.md](docs/开发文档.md)。

---

## 0. 全局原则

1. **单一权威源：** 架构与规范以 [docs/开发文档.md](docs/开发文档.md) 为准，技能文档（如 `godot-resource`）引用其章节编号。改规范 = 改主文档 + 走 PR。
2. **玩法未冻结：** Grow 主题具体玩法待定（见 [docs/design/功能需求文档.md](docs/design/功能需求文档.md)）。涉及玩法决策时**必须先与人类对齐**，不得擅自锁定机制。
3. **不破坏扩展点：** Autoload 公共接口（见 [docs/architecture/架构说明.md](docs/architecture/架构说明.md) §2）勿擅改；新增内容走 §2.3 扩展点。
4. **GameJam 时限优先：** 选最简可用方案，避免过度工程；占位资源允许，正式替换在 §3.9 登记。
5. **GDScript 单语言：** 不引入 C# / 插件，除非人类明确要求。

---

## 1. 智能体角色

### 1.1 项目架构师（Project Architect）
- **职责：** 高层规划、任务拆分与分发、架构一致性审查、风险评估。
- **何时用：** 新功能起步、跨模块改动、不确定"该怎么做"时。
- **技能：** [skills/architect.md](docs/agents/skills/architect.md)
- **权限：** 可修改 `docs/` 与 autoload 接口（需 PR）；不直接写玩法逻辑。

### 1.2 场景开发（Scene Developer）
- **职责：** `.tscn` 场景与节点树搭建、预制体、UI 布局。
- **何时用：** 新关卡 / 菜单 / HUD / 实体预制。
- **技能：** [skills/scene-dev.md](docs/agents/skills/scene-dev.md)
- **规则要点：** `.tscn` 冲突**禁手合并**，用 Godot GUI；节点 PascalCase。

### 1.3 脚本开发（Script Developer）
- **职责：** GDScript 逻辑：系统、实体、状态机、信号接线。
- **何时用：** 实现机制、修 bug、写 autoload 行为。
- **技能：** [skills/script-dev.md](docs/agents/skills/script-dev.md)
- **规则要点：** 遵循 [coding-rules.md](docs/agents/rules/coding-rules.md)；跨系统走 `EventManager`。

### 1.4 资源管理（Resource Manager）
- **职责：** 美术/音频导入设置、自定义 `Resource`/JSON 配置、Git LFS 入库、资产登记。
- **何时用：** 导入贴图/模型/音频、制作 `CardDefinition`/`EnemyDefinition` 等 `.tres`。
- **技能：** [skills/resource-mgmt.md](docs/agents/skills/resource-mgmt.md)（亦遵循全局 `godot-resource` 技能）
- **规则要点：** 大资源走 LFS（§3.8）；新资源登记 §3.9 资产清单。

### 1.5 测试与质量（QA）
- **职责：** 回归测试、性能检查、规范符合性审查、导出验证。
- **何时用：** PR 前、里程碑前、出现疑难 bug。
- **技能：** [skills/qa.md](docs/agents/skills/qa.md)
- **规则要点：** 对照 §5.6 测试基准；`push_warning/push_error` 不得被静默吞掉。

---

## 2. 协作流程

```
人类提需求 ─→ 架构师拆任务 ─┬→ 场景开发（.tscn）
                           ├→ 脚本开发（.gd）
                           ├→ 资源管理（.tres/LFS）
                           └→ QA 验证 ─→ PR
```

- **任务拆分粒度：** 一个 PR 一个职责（场景/脚本/资源尽量不混）。
- **冲突预防：** 改动同一 `.tscn` 前在 PR 描述声明，串行处理。
- **接力约定：** 脚本侧需要的新信号，先在 `EventManager` 加好（PR1），玩法再接（PR2）。

---

## 3. 必读文档（优先级）

1. [docs/开发文档.md](docs/开发文档.md) — 规范权威源
2. [docs/architecture/架构说明.md](docs/architecture/架构说明.md) — 架构细节
3. [docs/agents/rules/coding-rules.md](docs/agents/rules/coding-rules.md) — 编码规范
4. [docs/agents/rules/collaboration-rules.md](docs/agents/rules/collaboration-rules.md) — 提交/协作/LFS
5. 对应自己的 [skills/](docs/agents/skills/) 技能文件

---

## 4. 变更记录
| 日期 | 摘要 | 作者 |
|------|------|------|
| 2026-09-04 | 初版，定义 5 类智能体角色与协作流程 | 架构组 |
