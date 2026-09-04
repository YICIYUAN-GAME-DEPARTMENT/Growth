# 协作与提交规范

> 配套 [开发文档.md](../../开发文档.md) §7。涵盖分支、提交、PR、Git LFS、`.tscn` 冲突处理。

## 1. 分支策略
- `main`：受保护，只接 PR；始终可运行（F5 无报错）。
- `feat/<topic>`：新功能 / 机制
- `fix/<topic>`：修 bug
- `art/<topic>`：纯资源入库（贴图/音频）
- `lvl/<id>`：关卡场景（`Scenes/Levels/Level_*.tscn`）改动
- `docs/<topic>`：仅文档

> 分支名小写、连字符、简短（`feat/grid-system`）。

## 2. 提交信息
前缀 + 简述（祈使句，单行 ≤ 72）：
```
feat(level): 接入 GridSystem 走格子判定
fix(mech): 修正机关占格冲突重试
feat(level-3): 新增教程关 3 数据
art: 入库主角占位贴图 A-02
asset: 入库机关 5 阶段占位图 (A-03)
docs: 权威文档 v1.0 重写
refactor(audio): AudioManager 用对象池
chore: 升级 .gitignore
```
| 前缀 | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修 bug |
| `art` | 美术资源 |
| `asset` | 任意 LFS 大资源入库 |
| `lvl` | 关卡数据（.tres） |
| `docs` | 仅文档 |
| `refactor` | 重构（不改行为） |
| `chore` | 杂项配置 |

`asset`/`art` 提交**必须**在描述注明 A-xx 资产编号（见 [开发文档.md](../../开发文档.md) §3.9）。

## 3. PR 流程
1. 从 `main` 拉最新：`git pull origin main`。
2. 在特性分支完成改动，**自检**（见 [qa.md](../skills/qa.md)）。
3. PR 标题 = 主题，描述含：改动摘要 / 测试清单 / 影响范围 / 资产编号。
4. 同一 `.tscn` 的并行 PR：在描述互相 `@` 声明，**串行合并**。
5. 合并前 QA 通过；squash 合并保留线性历史。

## 4. 资源入库（Git LFS）
1. 确认 `.gitattributes` 已追踪该扩展名（见 [开发文档.md](../../开发文档.md) §3.8）。
2. 放入对应目录（`Art/` / `Audio/`；关卡是 `Scenes/Levels/Level_*.tscn` 文本，不入 LFS）。
3. `git add <file>`（LFS 自动接管）→ 提交信息 `asset: ... (A-xx)`。
4. 在 [开发文档.md](../../开发文档.md) §3.9 资产清单加行。
5. 推送前本地 `git lfs ls-files` 确认已追踪。

> `.gd/.tscn/.tres/.cfg/.import` **永不入 LFS**。

## 5. `.tscn` 冲突处理（强制）
- `.tscn` 为 Godot 文本格式，**禁止**手动文本合并解决冲突。
- 冲突时：`git checkout --theirs <file>.tscn`（或 ours）→ 用 Godot 编辑器重新搭出合并后结构 → 提交。
- 预防：改动同一场景前在 PR 描述声明，串行处理。

## 6. 不该提交的内容
- `.godot/`（已在 `.gitignore`）
- `export_presets.cfg`
- 个人 `.vscode/*`（保留 `settings.json/extensions.json/launch.json/tasks.json`）
- 临时占位资源未登记编号的

## 7. AI 智能体协作接力
- 脚本侧需要新信号 → 先在 `EventManager` 加好（PR1）→ 玩法接（PR2）。
- 制作关卡/平衡 `.tres` 前先核对 [功能需求文档](../../design/功能需求文档.md) §6–7 与 [开发文档](../../开发文档.md) §5.2，并在 PR 附上数值出处。
- **涉及玩法/数值变更需求，AI 智能体必须先停下来问人类**，人类确认后同步更新权威文档，禁止代码里擅自改规则。
