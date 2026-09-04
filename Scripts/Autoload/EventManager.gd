extends Node
## ============================================================================
## EventManager  —  全局信号总线 (Autoload)
## ----------------------------------------------------------------------------
## 用途：解耦各系统通信。任何脚本发信号走 EventManager.* 而非直接引用对方。
## 规范：见 docs/architecture/架构说明.md §3（信号权威清单）。
## 本文件只声明信号，不含逻辑。新增信号：追加到区块并保持签名，同步架构说明 §3。
## 注：当前实现中 UI 刷新/胜负结算直接调用（Level→HUD/SaveManager），信号为
## 跨系统解耦与扩展预留（audio 等模块接入时订阅）。禁止删仍在 emit 的信号。
## ============================================================================

# ── Gameplay（权威，见架构说明 §3）────────────────────────────
signal level_loaded(level_id: int)
signal player_moved(head: Vector2i)          # 每次有效移动/截断
signal max_length_changed(new_max: int)       # L 变化
signal move_count_changed(count: int)         # 步数变化
signal food_eaten(pos: Vector2i)
signal mechanism_grew(new_level: int)         # 全体机关 +1 后的阶段
signal input_locked(locked: bool)             # 机关生长动画期间
signal level_cleared(level_id: int, steps: int)
signal level_failed(level_id: int)
