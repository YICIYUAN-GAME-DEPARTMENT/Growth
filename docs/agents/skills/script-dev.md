# Skill: 脚本开发（script-dev）

**描述：** 编写 GDScript 逻辑：网格系统、机关/主角/食物/终点实体、UI、信号接线、autoload 行为。实现功能/修 bug/写系统时使用。

## 使用场景
- 实现 [功能需求文档.md](../../design/功能需求文档.md) 中某功能（§4 规则 → §8 验收 C-xx）
- 修 GDScript bug
- 调整 autoload 行为（需架构师确认接口稳定）
- 新增 `Scripts/Systems/`、`Scripts/Entities/`、`Scripts/UI/`、`Scripts/Data/` 下类

## 指令
1. **遵循编码规范：** [coding-rules.md](../rules/coding-rules.md)（命名 / 类型标注 / 信号 / 事件驱动等）。
2. **权威先行：** 移动/身长/截断/机关生长/BFS 规则以 [功能需求文档](../../design/功能需求文档.md) §4 为准，数值取自 `Balance.tres`；**禁止在脚本中硬编码规则数值或关卡布局**。
3. **分层归属：**
   - 全局生命周期 → `Scripts/Autoload/`（GameManager/EventManager/SaveManager；公共接口勿擅改）
   - 玩法系统 → `Scripts/Systems/`（Level.gd、GridSystem），由关卡场景使用，**不进 Autoload**
   - 实体 → `Scripts/Entities/`（CellEntity 基类 + PlayerSpawn/Mechanism/Food/Goal；障碍非实体，不在此列）
   - 数据类 → `Scripts/Data/`（Balance / MechanicShapes / GridMetrics）
4. **通信纪律：**
   - 跨系统 → `EventManager.xxx.emit/connect`（信号见 [架构说明](../../architecture/架构说明.md) §3），**禁止** `get_node("/root/OtherSystem")`
   - 取资源/场景 → 显式 `load()`（需要处缓存引用；路径写常量/调用处），**禁止**热路径反复 `load()`
   - 场景切换 → `GameManager.change_scene()`（关卡入口 `GameManager.start_level`）
5. **输入：** 用 `Input.is_action_pressed("xxx")`，禁裸查键码；`restart`(R) 等新动作先在 `project.godot` `[input]` 登记。
6. **错误处理：** 边界用 `push_warning/push_error`，不得静默吞掉；内部信任代码不冗余校验。
7. **改动已冻结玩法？** 先停：任何规则/数值调整需人类确认并更新功能需求文档 / Balance，不允许"顺手改规则"。
8. **新增信号：** 追加到 `EventManager` 文件尾 `## Gameplay` 区块，不删改既有信号签名。

## 示例
机关生长（在 Level.gd 内，机关占格逻辑见 Mechanism.gd）：
```gdscript
# 数值来自 GameManager.balance（Balance.tres），勿硬编码
func _grow_all_mechanisms() -> void:
    var blocked := _blocked_cells()   # 玩家身体 + S + E（保护格）
    for m in _mechanisms:
        if m.level < MechanicShapes.max_level():
            m.set_level(m.level + 1)
            m.claim_missing(blocked)  # 玩家身体阻挡的格本次跳过，lv 照升
    _rebuild_mech_grid()              # 更新 GridSystem 占格，即时生效
    EventManager.mechanism_grew.emit(_current_mech_level())
```
