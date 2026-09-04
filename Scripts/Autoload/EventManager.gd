extends Node
## ============================================================================
## EventManager  —  全局信号总线 (Autoload)
## ----------------------------------------------------------------------------
## 用途：解耦各系统通信。任何脚本发信号走 EventManager.* 而非直接引用对方。
## 规范：见 docs/architecture/架构说明.md §事件总线。
## Grow 主题玩法尚未冻结，下方已为常见 Hook 预留信号，团队决策后增删。
## ============================================================================

# ── 生命周期 ────────────────────────────────────────────────────
signal game_started
signal game_paused(paused: bool)
signal game_over(result: Dictionary)         # {"win": bool, "score": int, ...}
signal scene_change_requested(target: String, transition: String)  # transition: "fade"|"cut"

# ── 实体 / 玩家 ─────────────────────────────────────────────────
signal entity_spawned(entity: Node)
signal entity_died(entity: Node)
signal health_changed(current: int, maximum: int)
signal score_changed(score: int)

# ── Grow 主题 Hook（占位，玩法冻结后填充）──────────────────────
# signal growth_phase_advanced(phase: int)
# signal resource_collected(type: String, amount: int)
# signal entity_evolved(entity: Node, new_form: String)
