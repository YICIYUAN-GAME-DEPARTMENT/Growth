extends Node2D
## ============================================================================
## GameScene  —  玩法场景基类
## ----------------------------------------------------------------------------
## 所有关卡 / 战斗 / 菜单场景的脚本继承此类，重写以下虚函数即可获得统一
## 生命周期，避免每个场景各写一套样板：
##   _setup()           — 初始化状态、生成实体、连接信号
##   _on_scene_entered()— 场景激活后调用
##   _on_scene_exiting()— 离开前清理（释放实体、断开信号）
## 退出统一走 exit_to()，保证清理顺序。
## ============================================================================

func _ready() -> void:
	_setup()
	_on_scene_entered()


func _setup() -> void:
	pass


func _on_scene_entered() -> void:
	pass


func _on_scene_exiting() -> void:
	pass


func exit_to(target_scene: String) -> void:
	_on_scene_exiting()
	GameManager.change_scene(target_scene)
