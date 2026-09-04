# Skill: 场景开发（scene-dev）

**描述：** 搭建 `.tscn` 场景与节点树、预制体、UI 布局。主菜单/选关/HUD/关卡场景/实体预制时使用。

## 使用场景
- 主菜单 / 关卡选择 / 结算面板（`Scenes/UI/`）
- 关卡场景（`Scenes/Levels/Level.tscn`，按 LevelDefinition 数据驱动）
- 实体预制（`Scenes/Entities/`：Player / Mechanism / Food / Goal）
- 调整 `Main.tscn` 的层级结构

## 指令
1. **命名：** 节点/场景文件用 PascalCase（`Level.tscn`、`EntityRoot`）；美术/数据文件名按 [开发文档.md](../../开发文档.md) §3.3 前缀规范。场景结构遵循开发文档 §4.4。
2. **基类：** 玩法场景根节点挂 `Scripts/Core/GameScene.gd`（或其子类 `LevelScene`）；UI 场景根用 `Control` 系。
3. **节点引用：** 用 `@onready var x: Node2D = $Path`，**禁止**在 `_process` 里 `get_node`。
4. **信号接线：** `_ready()` 顶部集中声明 `EventManager.xxx.connect(...)`；新玩法信号见 [架构说明](../../architecture/架构说明.md) §3。
5. **关卡结构：** 关卡是**单一通用场景**（Level.tscn），布局来自 `LevelDefinition.tres`——禁止为每关复制 `.tscn`。Ground(TileMapLayer)/EntityRoot/GridSystem 按开发文档 §4.4 组织。
6. **不使用物理碰撞：** 本作基于网格数据判定，场景不需要 RigidBody/Area 碰撞层。
7. **冲突处理（强制）：** `.tscn` 冲突**禁手文本合并**，用 Godot 编辑器 GUI 解决。改动同一 `.tscn` 前在 PR 描述声明，串行处理。
8. **UI 层：** HUD/菜单按开发文档 §4.2 放对应场景；暂停覆盖设 `process_mode = PROCESS_MODE_WHEN_PAUSED`。
9. **登记：** 关卡数据在关卡场景 `_setup()` 注册到 ResourceManager；HUD 等场景由 Main 加载。

## 示例
搭建关卡场景 `Scenes/Levels/Level.tscn`：
- 根节点 `Level (Node2D)` 挂 `LevelScene.gd`（继承 GameScene）。
- 子节点：`Ground (TileMapLayer)`、`EntityRoot (Node2D)`（下挂 Goal/Foods/Mechanisms/Player 预制）、`GridSystem (Node)`、`MechanismSystem (Node)`、`HUDLayer (CanvasLayer)`。
- 数据接入：`_setup()` 中 `ResourceManager.get_resource("lvl_%02d" % level_id)` 读取关卡。
