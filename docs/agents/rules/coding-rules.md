# 编码规范（GDScript）

> 适用对象：所有 `Scripts/**/*.gd`。AI 智能体与人类成员均须遵守。
> 工程结构与命名规则见 [开发文档（权威）](../../开发文档.md)；玩法数值见 [功能需求文档（权威）](../../design/功能需求文档.md)。

## 1. 文件与类
- 脚本文件与 `class_name` 均用 **PascalCase**（`Balance.gd`、`GridSystem.gd`）；Autoload 脚本与其节点名一致（`GameManager.gd`）。
- 文件顶部用 `##` 多行注释说明职责。
- 单一职责：一个脚本只管一件事；超 300 行考虑拆分（System 拆到 `Scripts/Systems/`）。

## 2. 命名
| 类别 | 风格 | 示例 |
|------|------|------|
| 变量 / 函数 / 参数 | snake_case | `world_root`、`try_move()` |
| 类名 / class_name / 文件名 | PascalCase | `GridSystem`、`Balance` |
| 节点名 | PascalCase | `EntityRoot`、`Mechanisms` |
| 常量 | SCREAMING_SNAKE | `DIRS_4` |
| 枚举 | PascalCase 值 / snake_case 名 | `Dir.UP` |
| 输入动作 | snake_case | `move_up`、`restart` |

## 3. 类型标注
- 函数参数与返回值**必须**标类型（`func add(a: int) -> int:`）。
- 成员变量尽量标类型（`var level: int = 0`）；节点引用 `@onready var x: Node2D = $Path`。
- 容器用泛型（`Array[Vector2i]`、`Dictionary` key/value 注明）。

## 4. 信号
- 声明带类型参数：`signal food_eaten(pos: Vector2i)`。
- 跨系统通信用 `EventManager.*`，**禁止** `get_node("/root/OtherSystem")` 硬引用。
- 连接在 `_ready()` 顶部集中声明；`connect` 用可调用形式 `EventManager.x.connect(_on_x)`。
- 发送用 `emit`，**禁止**字符串 `emit_signal("xxx")`。
- 新增玩法信号：追加到 `EventManager` 文件尾 `## Gameplay` 区块，勿删改既有签名（见 [架构说明](../../architecture/架构说明.md) §3）。

## 5. 节点引用
- **必须** `@onready` 缓存；**禁止**在 `_process`/`_physics_process` 里 `get_node`。
- 路径用相对（`$EntityRoot`），避免长绝对路径。

## 6. 输入
- 用 `Input.is_action_pressed("move_up")`，**禁止**裸查键码。
- 新动作先在 `project.godot` `[input]` 登记（如 `restart`=R）再使用。

## 7. 网格玩法判定
- 本作基于数据网格（GridSystem），**不使用物理碰撞**；障碍/机关/可走均由数据判定。
- 关卡的 S/E/食物/机关通过**场景摆放**（Level_*.tscn 实体节点 + `cell` 导出）定义；障碍**不是实体**，由 `Obstacles` TileMapLayer 涂格定义（被涂格=不可走）。**禁止在脚本里硬编码关卡布局**。

## 8. 错误处理
- 边界（外部输入、资源获取失败）用 `push_warning/push_error` + 早返回。
- **禁止**静默吞 warning/error。
- 内部信任代码不冗余判空校验。

## 9. `_process` 纪律
- 回合制游戏尽量少轮询；移动/生长/胜负全部事件驱动。
- 不在 `_process` 做重分配、`load`、`get_node`。

## 10. 资源 / 场景
- 场景与资源经显式 `load()` 获取（可缓存引用复用），**禁止**在热路径反复 `load()`；路径统一写在常量/调用处。
- 切场景走 `GameManager.change_scene()`（选关进关卡用 `GameManager.start_level`），禁止裸 `change_scene`。
- 数值一律来自 `Balance.tres`（全局基准）或关卡根节点导出 `*_override`（0=沿用全局）；**禁止在代码里硬编码玩法数值**（如 6 步、+2、1/5/9/13/21 只可出现在集中常量定义并注释权威出处）。

## 11. 注释
- 只在"为什么"非显而易见处注释，**禁止**复述代码。
- TODO 格式：`# TODO(角色): 描述`，如 `# TODO(qa): 补 C-07 回归用例`。

## 12. 禁止
- ❌ 混入 C# / 第三方插件（除非人类明确同意）
- ❌ `print()` 进生产代码（用 `push_warning/push_error`）
- ❌ 在 Autoload 公共接口上擅自改签名
- ❌ 未经人类确认擅自修改已冻结玩法规则（改需走功能需求文档）
- ❌ 关卡布局 / 机关形状硬编码进脚本
