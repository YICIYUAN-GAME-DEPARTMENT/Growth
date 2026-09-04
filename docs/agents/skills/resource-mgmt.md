# Skill: 资源管理（resource-mgmt）

**描述：** 处理美术/音频导入设置、关卡/平衡数据 `Resource`（`.tres`）、Git LFS 入库、资产登记。导入资源 / 制作 `.tres` 配置时使用。本技能与全局 `godot-resource` 技能配合；本仓库以 [开发文档（权威）](../../开发文档.md) §3 / §5 与 [功能需求文档（权威）](../../design/功能需求文档.md) §6–7 为准。

## 使用场景
- 导入贴图 / 音频（占位或正式）
- 制作 `LevelDefinition` / `Balance` 等 `.tres`
- 大资源入库（Git LFS）
- 整理 `Art/`、`Audio/`、`Resources/` 目录
- 为关卡设计验收/数值确认

## 指令
1. **权威先行：** 制作前先读 [功能需求文档](../../design/功能需求文档.md)（关卡清单/数值/验收）与 [开发文档](../../开发文档.md) §5.2（字段 Schema）。
2. **目录职责：** 按 [开发文档](../../开发文档.md) §3.4 放置：`Resources/Levels/`（关卡 `.tres`）、`Resources/Config/`（Balance）、`Art/*`（美术）、`Audio/*`（音频），禁止散落根目录。
3. **命名：** [开发文档](../../开发文档.md) §3.3 统一前缀（`LVL`/`CHR`/`TILE`/`UI`/`SFX`/`MUS`）+ 名称 + 序号；脚本 `.gd`/场景 `.tscn` 用 PascalCase。
4. **配置数据：** 按 §5.2 `LevelDefinition` 字段制作（`level_id`/`start_cell`/`goal_cell`/`obstacles`/`foods`/`mechanisms` 等）；数值必须与功能需求文档 §7 一致。**本项目不用 JSON**。
5. **机关形状：** 机关 5 阶段形状由 `Mechanism.shape(lv)` 实现（非数据文件），数值权威=功能需求文档 §4.3；不要在 `.tres` 里另存一套。
6. **Git LFS：** 大资源（png/wav/ogg 等）走 LFS（§3.8，`.gitattributes` 已按扩展名追踪）。提交用 `asset` 前缀并注明 A-xx；关卡 `.tres` 是文本，**不入 LFS**。
7. **资产登记：** 美术/音频新资源登记到 [开发文档](../../开发文档.md) §3.9 资产清单，避免重复；关卡/平衡数据不占 A-xx，但需在 PR 描述注明。
8. **占位资源：** 未定稿美术用纯色/线框，命名加 `_TMP`，正式替换后删除占位并更新登记。

## 示例
制作教程关 1（LevelDefinition）：
1. 读功能需求文档 §6.1 关 1 需求（教程：无机关，1 食物，E 在初始 L 可达范围）。
2. 新建 `Resources/Levels/LVL_01_Tutorial.tres`，根类 `LevelDefinition`，填：
   `level_id=1`、`grid_size=Vector2i(32,32)`、`start_cell=...`、`goal_cell=...`、`initial_max_len=3`、`obstacles=[...]`、`foods=[...]`、`mechanisms=[]`、`is_tutorial=true`。
3. 在 ResourceManager 注册：`register_resource("lvl_01", "res://Resources/Levels/LVL_01_Tutorial.tres")`（实际由关卡场景 `_setup()` 统一注册）。
4. 用 §8 C-L01 验收用例自检；PR 分支 `lvl/01`，描述附数值出处。
