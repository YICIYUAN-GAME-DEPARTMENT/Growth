class_name Palette
## ============================================================================
## Palette — 占位用统一配色（后续美术替换时改这里或换成贴图）
## ============================================================================

const BG_CELL := Color("242427")       # 空格底色
const BG_GRID := Color("34363d")        # 格线色（draw 辅助线用）
const SPAWN := Color("8ef0c8")          # 出生点
const OBSTACLE := Color("6a6f7a")       # 障碍
const FOOD := Color("f5a84a")           # 食物
const GOAL := Color("4ad2ff")           # 终点
const PLAYER_HEAD := Color("ffe08a")    # 玩家头
const PLAYER_BODY := Color("c8a24a")    # 玩家身体

# 机关各阶段配色（从浅到深，便于区分生长）
const MECH := [
	Color("7fbf7f"),
	Color("66a366"),
	Color("4d874d"),
	Color("3a6b3a"),
	Color("2a522a"),
]

const MECH_CORE := Color("1d3a1d")      # 机关中心格
