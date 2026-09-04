# Skill: 场景开发（scene-dev）

**描述：** 搭建 `.tscn` 场景与节点树、预制体、UI 布局。新关卡 / 菜单 / HUD / 实体预制时使用。

## 使用场景
- 新增玩法场景（`Scenes/Levels/`）
- 新增菜单 / HUD / 暂停覆盖（`Scenes/UI/`）
- 新增实体预制（`Scenes/Entities/`，Player/Enemy/Pickup）
- 调整 `Main.tscn` 的层级结构

## 指令
1. **命名：** 节点用 PascalCase（`WorldRoot`、`HealthBar`），文件按 [开发文档.md](../../开发文档.md) §3.3（`LVL_*` / `SCN_*` / `CHR_*` 等）。
2. **基类：** 玩法场景根节点挂 `Scripts/Core/GameScene.gd` 或其子类；UI 场景用 `Control` 系。
3. **节点引用：** 用 `@onready var x: Node2D = $Path`，**禁止**在 `_process` 里 `get_node`。
4. **信号接线：** `_ready()` 顶部集中声明 `EventManager.xxx.connect(...)`，便于审查。
5. **物理层：** 按 [开发文档.md](../../开发文档.md) §7 命名层设置 `collision_mask`/`collision_layer`，禁裸数字。
6. **冲突处理（强制）：** `.tscn` 冲突**禁手文本合并**，用 Godot 编辑器 GUI 解决（[开发文档.md](../../开发文档.md) §3 资源制作规范、godot-resource 技能同此要求）。改动同一 `.tscn` 前在 PR 描述声明，串行处理。
7. **UI 层：** HUD/菜单挂 `Main.UIRoot`（CanvasLayer），暂停覆盖设 `process_mode = PROCESS_MODE_WHEN_PAUSED`。
8. **登记：** 新场景在 `MainMenu._ready()` 或 `BootStrap` 调 `ResourceManager.register_scene(id, path)`。

## 示例
创建测试关卡：`Scenes/Levels/LVL_Forest_01.tscn`，根节点 `Level01(Node2D)` 挂 `Scripts/Core/GameScene.gd`；在 `BootStrap` 登记：
```gdscript
ResourceManager.register_scene("lvl_forest_01", "res://Scenes/Levels/LVL_Forest_01.tscn")
```
