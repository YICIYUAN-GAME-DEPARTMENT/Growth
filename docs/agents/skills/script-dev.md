# Skill: 脚本开发（script-dev）

**描述：** 编写 GDScript 逻辑：网格系统、机关/主角/食物/终点实体、UI、信号接线、autoload 行为。实现功能/修 bug/写系统时使用。

## 使用场景
- 实现 [功能需求文档.md](../../design/功能需求文档.md) 中某功能（§4 规则 → §8 验收 C-xx）
- 修 GDScript bug
- 调整 autoload 行为（需架构师确认接口稳定）
- 新增 `Scripts/Systems/`、`Scripts/Entities/`、`Scripts/UI/`、`Scripts/Data/` 下类

## 指令
1. **遵循编码规范：** [coding-rules.md](../rules/coding-rules.md)（命名 / 类型标注 / 信号 / 事件驱动等）。
2. **权威先行：** 移动/身长/截断/机关生长/BFS 规则以 [功能需求文档](../../design/功能需求文档.md) §4 为准，数值取自 `Balance.tres` / 关卡 `.tres`；**禁止在脚本中硬编码规则数值**。
3. **分层归属：**
   - 全局生命周期 → `Scripts/Autoload/`（GameManager/EventManager/ResourceManager/AudioManager/SaveManager；公共接口勿擅改）
   - 玩法系统 → `Scripts/Systems/`（GridSystem/MechanismSystem），由关卡场景持有，**不进 Autoload**
   - 实体 → `Scripts/Entities/`（Player/Mechanism/Food/Goal）
   - 数据类 → `Scripts/Data/`（LevelDefinition/Balance）
4. **通信纪律：**
   - 跨系统 → `EventManager.xxx.emit/connect`（信号见 [架构说明](../../architecture/架构说明.md) §3），**禁止** `get_node("/root/OtherSystem")`
   - 取资源 → `ResourceManager.get_scene/get_resource(id)`，**禁止**裸 `load()`
   - 播音频 → `AudioManager.play_sfx/play_music`，**禁止**自建 `AudioStreamPlayer`
   - 场景切换 → `GameManager.change_scene()` / `GameScene.exit_to()`
5. **输入：** 用 `Input.is_action_pressed("xxx")`，禁裸查键码；`restart`(R) 等新动作先在 `project.godot` `[input]` 登记。
6. **错误处理：** 边界用 `push_warning/push_error`，不得静默吞掉；内部信任代码不冗余校验。
7. **改动已冻结玩法？** 先停：任何规则/数值调整需人类确认并更新功能需求文档 / Balance，不允许"顺手改规则"。
8. **新增信号：** 追加到 `EventManager` 文件尾 `## Gameplay` 区块，不删改既有信号签名。

## 示例
机关生长触发（MechanismSystem，由关卡持有）：
```gdscript
class_name MechanismSystem
extends Node

# 数值来自 Balance.tres，勿硬编码
func try_grow(step_count: int) -> bool:
    if step_count > 0 and step_count % _balance().growth_step_interval == 0:
        grow_all()
        return true
    return false

func grow_all() -> void:
    for mech in get_children():
        if mech.lv < _balance().mech_level_max:
            mech.grow()  # 更新占格 + 播放动画
    EventManager.mechanism_grew.emit(...)
```
