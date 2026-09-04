# Skill: 场景开发（scene-dev）

**描述：** 搭建 `.tscn` 场景、节点树与 UI 布局；核心工作 = **关卡场景直编**。设计关卡/菜单/HUD/实体时使用。

## 使用场景
- 新建/编辑关卡场景（`Scenes/Levels/Level_<nn>.tscn`）
- 主菜单 / 选关（`Scenes/UI/`）
- 调整实体预制（`Scenes/Entities/`）
- 编辑器内摆放实体并吸附格子

## 指令
1. **关卡 = 场景（不是 .tres）**：复制 `LevelTemplate.tscn`，改名 `Level_<nn>_<名>.tscn`，根节点保留 `Level.gd`。关卡结构见 [开发文档.md](../../开发文档.md) §4.4。
2. **摆放实体：** 把 PlayerSpawn/Obstacle/Food/Goal/Mechanism 作为子节点拖入场景，放到格子位置（`cell` 自动吸附）。节点名 PascalCase。
3. **导出字段：** 在关卡根节点 Inspector 设 `level_id`（int，选关排序/记录用）、`level_name`、`map_size`（保底，默认 32×32）。
4. **机关：** 放置 `Mechanism.tscn` 即机关核心；内部 5 个 Stage 子场景会在编辑器里预览，运行时按 lv 自绘占格。机关逻辑形状不要手工改 Stage 节点。
5. **信号接线：** 关卡逻辑由 `Level.gd` 统一处理；HUD 由 Level 在运行时构建。需要全局通信用 `EventManager`（[架构说明](../../architecture/架构说明.md) §3）。
6. **冲突处理（强制）：** `.tscn` 冲突**禁手文本合并**，用 Godot 编辑器 GUI 解决；改动同一关卡 `.tscn` 前在 PR 描述声明，串行处理。
7. **UI 场景：** 根用 `Control` 系；选关/菜单全屏切换经 `GameManager.change_scene()`。
