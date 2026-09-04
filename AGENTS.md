# AGENTS.md

> 本文件定义 Growth 项目中 AI 智能体与人类成员的角色、职责边界与协作约定。
> 所有 AI 智能体在本仓库工作时，**必须先读本文件**，并遵循 [docs/agents/rules/](docs/agents/rules/)、[docs/开发文档.md](docs/开发文档.md) 与 [docs/design/功能需求文档.md](docs/design/功能需求文档.md)。

---

## 0. 全局原则

1. **双权威源：**
   - 工程 / 架构 / 数据 / 命名 → [docs/开发文档.md](docs/开发文档.md)（工程规范·权威）。
   - 玩法 / 功能 / 数值 / 验收 → [docs/design/功能需求文档.md](docs/design/功能需求文档.md)（产品需求·权威）。
   - 改规范 = 改对应权威文档 + 走 PR；引用其章节的技能需同步。
2. **玩法定稿：** Grow 玩法/规则已冻结（见功能需求文档）。**涉及玩法/数值调整必须先与人类对齐**，并更新功能需求文档与 `Balance.tres`/关卡数据，禁止在代码里"顺手"改规则。
3. **不破坏扩展点：** Autoload 公共接口（见 [docs/architecture/架构说明.md](docs/architecture/架构说明.md) §2）勿擅改；新增内容走 [开发文档](docs/开发文档.md) §2.3 扩展点。
4. **GameJam 时限优先：** 选最简可用方案，避免过度工程；占位资源允许，正式替换在 §3.9 登记。
5. **GDScript 单语言：** 不引入 C# / 插件，除非人类明确要求。
6. **本文档用途：** Growth 项目为 2D 网格解谜（无卡牌/敌人/技能类玩法），角色职责描述与仓库内容一致。

---

## 1. 智能体角色

### 1.1 项目架构师（Project Architect）
- **职责：** 高层规划、任务拆分与分发、架构一致性审查、风险评估。
- **何时用：** 新功能起步、跨模块改动、不确定"该怎么做"时。
- **技能：** [skills/architect.md](docs/agents/skills/architect.md)
- **权限：** 可修改 `docs/` 与 autoload 接口（需 PR）；不直接写玩法逻辑。

### 1.2 场景开发（Scene Developer）
- **职责：** `.tscn` 场景与节点树搭建、预制体、UI 布局。
- **何时用：** 主菜单/选关/HUD/关卡场景（Level.tscn）/实体预制。
- **技能：** [skills/scene-dev.md](docs/agents/skills/scene-dev.md)
- **规则要点：** `.tscn` 冲突**禁手合并**，用 Godot GUI；节点 PascalCase；场景按 [开发文档](docs/开发文档.md) §4 组织。

### 1.3 脚本开发（Script Developer）
- **职责：** GDScript 逻辑：网格/机关/主角/UI、信号接线、Autoload 行为。
- **何时用：** 实现 [功能需求文档](docs/design/功能需求文档.md) 中某功能（FR/C-xx）、修 bug。
- **技能：** [skills/script-dev.md](docs/agents/skills/script-dev.md)
- **规则要点：** 遵循 [coding-rules.md](docs/agents/rules/coding-rules.md)；跨系统走 `EventManager`；数值来自 `Balance.tres`/关卡数据，禁硬编码。

### 1.4 资源管理（Resource Manager）
- **职责：** 美术/音频导入设置、关卡/平衡数据 `Resource`(.tres)、Git LFS 入库、资产登记。
- **何时用：** 导入贴图/音频、制作 `LevelDefinition`/`Balance` 等 `.tres`。
- **技能：** [skills/resource-mgmt.md](docs/agents/skills/resource-mgmt.md)（亦遵循全局 `godot-resource` 技能）
- **规则要点：** 大资源走 LFS（[开发文档](docs/开发文档.md) §3.8）；数据 Schema 见 §5.2；新资源登记 §3.9。

### 1.5 测试与质量（QA）
- **职责：** 按 [功能需求文档](docs/design/功能需求文档.md) §8 验收标准回归、性能检查、规范符合性审查、导出验证。
- **何时用：** PR 前、里程碑前、疑难 bug。
- **技能：** [skills/qa.md](docs/agents/skills/qa.md)
- **规则要点：** 对照验收标准 C-xx；`push_warning/push_error` 不得被静默吞掉。

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

1. [docs/开发文档.md](docs/开发文档.md) — 工程规范·权威
2. [docs/design/功能需求文档.md](docs/design/功能需求文档.md) — 玩法/功能/数值/验收·权威
3. [docs/architecture/架构说明.md](docs/architecture/架构说明.md) — 架构实现细节
4. [docs/agents/rules/coding-rules.md](docs/agents/rules/coding-rules.md) — 编码规范
5. [docs/agents/rules/collaboration-rules.md](docs/agents/rules/collaboration-rules.md) — 提交/协作/LFS
6. 对应自己的 [skills/](docs/agents/skills/) 技能文件

---

## 4. 变更记录
| 日期 | 摘要 | 作者 |
|------|------|------|
| 2026-09-04 | 初版，定义 5 类智能体角色与协作流程 | 架构组 |
| 2026-09-04 | 玩法冻结：确立双权威源（开发文档 + 功能需求文档）；删除卡牌/敌人等无关描述；角色职责对齐网格解谜 | 架构组 |
