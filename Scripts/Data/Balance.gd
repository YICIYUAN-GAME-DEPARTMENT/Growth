class_name Balance
extends Resource
## ============================================================================
## Balance  —  全局玩法数值（数据驱动，可在 Inspector 随时调整）
## ----------------------------------------------------------------------------
## 存放：Resources/Config/Balance.tres
## 权威数值出处：[docs/design/功能需求文档.md] §7；改数值请同步该文档并走 PR。
## 引用方式：GameManager.balance.xxx（加载后只读，不缓存副本）。
## ============================================================================

@export_group("主角")
## 初始最大身长 L（HUD 显示 L）
@export var initial_max_len: int = 3
## 吃到 1 个食物增长的最大身长 ΔL
@export var food_len_gain: int = 2

@export_group("机关")
## 机关最高阶段（lv 0..max，中心恒占）
@export var mechanism_max_level: int = 4
## 每累计多少有效步，所有机关同步生长 1 阶段
@export var growth_step_interval: int = 6
## 机关生长动画时长（秒），期间锁输入
@export var grow_anim_sec: float = 0.3

