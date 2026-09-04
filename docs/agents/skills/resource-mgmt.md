# Skill: 资源管理（resource-mgmt）

**描述：** 处理美术/音频导入设置、全局数值 `Balance.tres`、Git LFS 入库、资产登记。导入资源 / 制作数值配置时使用。本技能与全局 `godot-resource` 技能配合；本仓库以 [开发文档（权威）](../../开发文档.md) §3 / §5 与 [功能需求文档（权威）](../../design/功能需求文档.md) §6–7 为准。

## 使用场景
- 导入贴图 / 音频（占位或正式）
- 调整 `Resources/Config/Balance.tres`（初始 L / ΔL / 生长步数等，直接在 Inspector 改）
- 设计关卡场景（摆放实体节点，拖动即吸附格子）
- 大资源入库（Git LFS）
- 整理 `Art/`、`Audio/` 目录

## 指令
1. **权威先行：** 先读 [功能需求文档](../../design/功能需求文档.md)（规则/数值/验收）与 [开发文档](../../开发文档.md) §5.5（Balance 字段）、§4.4（关卡场景结构）。
2. **关卡不做 `.tres`**：关卡 = 场景文件（`Scenes/Levels/Level_<nn>.tscn`），内容是 `Ground`/`Obstacles` 层涂格（障碍=被涂格，**非实体**）加实体节点（PlayerSpawn/Goal/Food/Mechanism），按 [开发文档](../../开发文档.md) §4.4 摆放。全局数值只有 `Balance.tres`。
3. **目录职责：** 按 [开发文档](../../开发文档.md) §3.4 放置（`Resources/Config/`、`Art/*`、`Audio/*`），禁止散落根目录。
4. **命名：** [开发文档](../../开发文档.md) §3.3 统一前缀（`CHR`/`TILE`/`UI`/`SFX`/`MUS`）+ 名称 + 序号。
5. **数值调整：** 打开 `Resources/Config/Balance.tres` 在 Inspector 修改；初始 L / ΔL / 生长步数必须与功能需求文档 §7 一致，改后需走变更流程（同步文档）。
6. **Git LFS：** 大资源（png/wav/ogg 等）走 LFS（§3.8，`.gitattributes` 已按扩展名追踪）。提交用 `asset` 前缀并注明 A-xx；文本类永不入 LFS。
7. **资产登记：** 美术/音频新资源登记到 [开发文档](../../开发文档.md) §3.9 资产清单，避免重复。
8. **占位资源：** 美术未定稿时使用纯色贴图/单贴图占位；贴图就绪后替换。

## 示例
新增正式关卡：
1. 复制 `Scenes/Levels/LevelTemplate.tscn` → `Scenes/Levels/Level_02_X.tscn`。
2. 打开场景：改根节点导出 `level_id`/`level_name`/`map_size`。
3. 在 `Ground`/`Obstacles` 层涂格（地图范围=涂格包围盒），拖入/复制实体节点（PlayerSpawn/Goal/Food/Mechanism）并吸附到格子上。
4. 用功能需求 §6.3 / §8 校验（BFS 可走、食物链可达）。
