# Skill: 脚本开发（script-dev）

**描述：** 编写 GDScript 逻辑：系统、实体、状态机、信号接线、autoload 行为。实现机制 / 修 bug / 写系统时使用。

## 使用场景
- 实现 [功能需求文档.md](../../design/功能需求文档.md) 中某条机制（M-xx）
- 修 GDScript bug
- 新增 autoload 行为（需架构师确认接口稳定）
- 新增 `Scripts/Systems/` 或 `Scripts/Entities/` 下的类

## 指令
1. **遵循编码规范：** [docs/agents/rules/coding-rules.md](../rules/coding-rules.md)（命名 / 类型标注 / 信号 / `_process` 节流等）。
2. **分层归属：**
   - 全局生命周期 → `Scripts/Autoload/`（仅架构师确认后加，公共接口勿擅改）
   - 玩法系统 → `Scripts/Systems/`，由场景持有，**不进 Autoload**
   - 实体 → `Scripts/Entities/`，挂 `WorldRoot`
3. **通信纪律：**
   - 跨系统 → `EventManager.xxx.emit/connect`，**禁止** `get_node("/root/OtherSystem")` 硬引用
   - 取资源 → `ResourceManager.get_scene/get_resource(id)`，**禁止**裸 `load()` 散落
   - 播音频 → `AudioManager.play_sfx/play_music`，**禁止**业务代码自建 `AudioStreamPlayer`
   - 场景切换 → `GameManager.change_scene()` / `GameScene.exit_to()`
4. **输入：** 用 `Input.is_action_pressed("xxx")`，禁裸查键码；新动作先在 `project.godot` 的 `[input]` 登记。
5. **错误处理：** 边界用 `push_warning/push_error`，不得静默吞掉；内部信任代码不冗余校验。
6. **玩法未冻结时：** 机制实现前确认 [功能需求文档.md](../../design/功能需求文档.md) §11 对应问题已决策；若未决策，停下来问，不要猜测。
7. **新增信号：** 追加到 `EventManager` 末尾"Grow 主题 Hook"区，不删改既有信号签名。

## 示例
实现一个成长系统骨架（放 `Scripts/Systems/GrowthSystem.gd`，由场景持有）：
```gdscript
class_name GrowthSystem
extends Node

var stage: int = 0

func advance() -> void:
    stage += 1
    EventManager.entity_evolved.emit(get_parent(), "stage_%d" % stage)
```
