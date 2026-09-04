# Skill: 资源管理（resource-mgmt）

**描述：** 处理美术/音频导入设置、自定义 `Resource`/JSON 配置、Git LFS 入库、资产登记。导入资源 / 制作 `.tres` 配置时使用。本技能与全局 `godot-resource` 技能配合，后者按本仓库 [开发文档.md](../../开发文档.md) 第 3 章执行。

## 使用场景
- 导入贴图 / 模型 / 音频 / 字体
- 制作 `CardDefinition`/`EnemyDefinition` 等自定义 `Resource`（`.tres`）或 JSON
- 大资源入库（Git LFS）
- 整理 `Resources/`、`Art/`、`Audio/` 目录

## 指令
1. **目录职责：** 按 [开发文档.md](../../开发文档.md) §3.4 放置，禁止散落根目录。
2. **命名：** [开发文档.md](../../开发文档.md) §3.3 统一前缀（`CHR/ENM/SKL/PSV/CRD/LVL/SCN/SFX/MUS/ART`）+ 类型 + 名称 + 版本。
3. **导入设置：** 按 §3.2（贴图）/ §3.5（音频）；未定规格先默认并标【待定】。
4. **配置数据：** 按 §5.2 字段规范制作；玩法冻结前为模板，冻结后定稿。`XxxIdentityID` 用整数。
5. **Git LFS：** 大资源（png/jpg/glb/wav/ogg/ttf 等）走 LFS（§3.8，`.gitattributes` 已按扩展名追踪）。提交信息用 `asset` 前缀并注明 A-xx 编号。
6. **资产登记：** 新资源登记到 [开发文档.md](../../开发文档.md) §3.9 资产清单，避免重复制作；制作前先查此表。
7. **占位资源：** 未定稿美术用纯色/线框，命名加 `_TMP`，正式替换后删除占位并更新编号。

## 示例
制作测试敌人（假设采用敌人定义）：
1. 新建 `Resources/Enemies/ENM_Slime_Green_01.tres`，根类 `EnemyDefinition`
2. 填字段：`EnemyIdentityID=40001`、`BaseMaxHP=20`、`BaseSpeed=1`、`IntentCycle=[...]`
3. 在 `BootStrap` 登记：`ResourceManager.register_resource("slime_green", "res://Resources/Enemies/ENM_Slime_Green_01.tres")`
4. §3.9 资产清单加行：`A-03 | Slime Green | res://Resources/Enemies/ENM_Slime_Green_01.tres | data | ✅`
