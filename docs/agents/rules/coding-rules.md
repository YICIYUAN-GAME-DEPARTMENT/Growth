# 编码规范（GDScript）

> 适用对象：所有 `Scripts/**/*.gd`。AI 智能体与人类成员均须遵守。配套 [开发文档.md](../../开发文档.md) §4。

## 1. 文件与类
- 文件名 snake_case（`game_manager.gd`），节点/PascalCase 类名放 `class_name` 于文件顶部（autoload 除外，autoload 用节点名）。
- 顶部用 `##` 多行注释说明职责（见现有 autoload 文件）。
- 单一职责：一个脚本只管一件事；超 300 行考虑拆分。

## 2. 命名
| 类别 | 风格 | 示例 |
|------|------|------|
| 变量 / 函数 / 信号参数 | snake_case | `world_root`、`change_scene()` |
| 类 / 节点名 | PascalCase | `GrowthSystem`、`WorldRoot` |
| 常量 | SCREAMING_SNAKE | `SFX_POOL_SIZE` |
| 枚举值 | PascalCase（枚举名 snake_case） | `State.MENU` |
| 输入动作 | snake_case | `move_up` |
| 资源 id（ResourceManager key） | snake_case | `slime_green` |

## 3. 类型标注
- 函数参数与返回值**必须**标类型（`func add(a: int) -> int:`）。
- 成员变量尽量标类型（`var stage: int = 0`）；节点引用用 `@onready var x: Node2D = $Path`。
- 容器用 `Array[Type]` 泛型（`var pool: Array[AudioStreamPlayer] = []`）。

## 4. 信号
- 声明带类型参数：`signal score_changed(score: int)`。
- 跨系统通信用 `EventManager.*`，**禁止**直接 `get_node("/root/OtherSystem")`。
- 连接在 `_ready()` 顶部集中声明；`connect` 用可调用形式 `EventManager.x.connect(_on_x)`。
- 发送方用 `emit`，**禁止**用字符串 `emit_signal("xxx")`。

## 5. 节点引用
- **必须** `@onready` 缓存，**禁止**在 `_process`/`_physics_process` 里 `get_node`。
- 路径用相对（`$WorldRoot`），仅在根场景用绝对。

## 6. 输入
- 用 `Input.is_action_pressed("move_up")`，**禁止**裸查 `KEY_W`。
- 新动作先在 `project.godot` 的 `[input]` 段登记再使用。

## 7. 错误处理
- 边界（外部输入、资源获取失败）用 `push_warning/push_error` + 早返回。
- **禁止**静默吞 warning/error。
- 内部信任代码不冗余判空校验。

## 8. `_process` 纪律
- 高频逻辑尽量下沉到 `_physics_process`。
- 不在 `_process` 做重分配、`load`、`get_node`。
- 轮询优先改信号驱动。

## 9. 资源 / 音频 / 场景
- 取资源走 `ResourceManager.get_scene/get_resource(id)`，**禁止**裸 `load()` 散落各处。
- 播音频走 `AudioManager.play_sfx/play_music`，**禁止**业务代码自建 `AudioStreamPlayer`。
- 切场景走 `GameManager.change_scene()` / `GameScene.exit_to()`，**禁止**裸 `change_scene`。

## 10. 注释
- 只在"为什么"非显而易见处注释，**禁止**复述代码。
- TODO 格式：`# TODO(角色): 描述`，如 `# TODO(qa): 补回归用例`。

## 11. 物理层
- `collision_mask`/`collision_layer` 用 [开发文档.md](../../开发文档.md) §7 命名层（`World/Player/Enemy/Projectile/Trigger`），**禁止**裸数字。

## 12. 禁止
- ❌ 混入 C# / 第三方插件（除非人类明确同意）
- ❌ `print()` 进生产代码（用 `push_warning/push_error` 或 `OS.print`）
- ❌ 在 autoload 公共接口上擅自改签名
- ❌ 玩法未冻结时擅自锁定机制
