# Skill: 场景开发（scene-dev）

**描述：** 搭建 `.tscn` 场景、节点树与 UI 布局；核心工作 = **关卡场景直编**。设计关卡/菜单/HUD/实体时使用。

## 使用场景
- 新建/编辑关卡场景（`Scenes/Levels/Level_<nn>.tscn`）
- 主菜单 / 选关（`Scenes/UI/`）
- 调整实体预制（`Scenes/Entities/`）
- 编辑器内摆放实体并吸附格子

## 指令
1. **关卡 = 场景（不是 .tres）**：复制 `LevelTemplate.tscn`，改名 `Level_<nn>_<名>.tscn`，根节点保留 `Level.gd`。关卡结构见 [开发文档.md](../../开发文档.md) §4.4。
2. **涂格：** `Ground` 层涂地板（内容包围盒=地图范围）、`Obstacles` 层涂障碍（涂上=不可走）。实体（PlayerSpawn/Goal/Food/Mechanism）作为子节点拖入 `EntityRoot`，`cell` 自动吸附；节点名 PascalCase。
3. **导出字段：** 在关卡根节点 Inspector 设 `level_id`（int，选关排序/记录用）、`level_name`、`map_size`（**仅空白场景兜底**，默认 32×32）。
4. **机关：** 放置 `Mechanism.tscn` 即机关核心（Core 单贴图）；生长体由 Level 运行时同步到 `MechanismCells` 层，勿手工编辑该层。
5. **信号接线：** 关卡逻辑由 `Level.gd` 统一处理；HUD 为 `LevelHUD.tscn` 实例，已在关卡场景中。需要全局通信用 `EventManager`（[架构说明](../../architecture/架构说明.md) §3）。
6. **冲突处理（强制）：** `.tscn` 冲突**禁手文本合并**，用 Godot 编辑器 GUI 解决；改动同一关卡 `.tscn` 前在 PR 描述声明，串行处理。
7. **UI 场景：** 根用 `Control` 系；菜单/选关/关卡为独立场景，经 `GameManager.change_scene()` 全屏切换。
8. **位置即所见：** World/Cam 是普通场景节点，脚本运行时不移动/缩放；想让地图落在窗口左上就 World=(0,0) + 自己摆 Cam。
