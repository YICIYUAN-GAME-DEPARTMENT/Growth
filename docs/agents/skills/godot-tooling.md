# Godot Headless 工具链（实战沉淀 · 必读防坑）

> 定位：仓库 AI 智能体在运行 Godot headless 生成/迁移/验证、处理瓦片贴图、编辑场景时的**操作性技能**。
> 规范权威见 [docs/开发文档.md](../../开发文档.md)（§3 资源/§4 场景/§4.4 贴边契约）；本文只补"怎么跑、别踩坑"。

## 1. 运行环境（Windows）

- `godot` 不在 PATH。固定路径：
  `C:\Godot Engine\Godot_v4.7.1-stable_mono_win64\Godot_v4.7.1-stable_mono_win64_console.exe`
- 常用命令（在 `d:\Programs\Growth` 下）：
  - 跑工具场景：`godot --headless --path . res://tools/GenSnek.tscn`
  - 资源导入（改动脚本/svg 后必跑，验证解析）：`godot --headless --path . --import`
  - 带参数：`godot --headless --path . res://tools/X.tscn -- --tres-only`
  - 临时验证兜底：`--quit-after 120`
- 控制台里 PowerShell profile 加载报错是**噪声**；关注 Godot 的 `SCRIPT ERROR / Parse Error / ERROR` 即可。

## 2. 资产生成两步法（svg → .tres）

svg 未经 `--import` 前 `load()` 会失败，**.tres 生成必须分两步**：

1. `godot --headless res://tools/GenSnek.tscn`  （写/覆盖 svg）
2. `godot --headless --import`                   （导入 svg，产出 .import）
3. `godot --headless res://tools/GenSnek.tscn -- --tres-only`（再跑一次，读 svg 存 .tres）

## 3. TileMap / Terrain 铁律（每条都出过 bug）

- **禁 `set_cells_terrain_connect` 批量重涂**：会外扩（地板 40→70 格案例）。重铺一律**确定性直写**：按格集对角邻居算掩码，`layer.set_cell(c, 0, Vector2i(mask, 0))`，绝不外扩。可参考 `Level._paint_auto` 与 `tools/MigrateTerrain.gd` / `RebuildLevelTiles.gd`。
- 三套地形 .tres 引用**三张独立纹理**：`terrain_floor.svg`（占位）/ 正式墙 `ImportArt/Terrarin-wall.png`（各 512×32，16 列 4 角掩码，瓦片 `(mask,0)`）、`terrain_mech.svg`（512×96，3 帧行 0=冒出/1=生长中/2=完成，瓦片 `(mask,0..2)`）。**瓦片必须建在脚本写格的那个行**——建在非 0 行而场景按 `(mask,0)` 写格会**静默不显示**（mech 停留格写 row2）。角序 bit0=左上 bit1=右上 bit2=左下 bit3=右下。
- **工具重存 .tres 会丢 uid 头**（ResourceSaver.save 在该会话未注册 path→uid 时直接省略）：重生成 Terrain*.tres 后必须把原 `uid="uid://…"` 补回 gd_resource 首行，否则场景按 uid 引用 TileSet 会全部失联。
- 机关生长体铺瓦集合=全部 `claimed` 格**含核心格**（掩码才把核心当邻居，角点不缺瓦）；核心由 Core Sprite 画，Mechanism 根节点 `z_index=1` 浮瓦片层之上（MechanismCells 层在场景树里位于 EntityRoot 之后）。
- 头/尾是独立 Sprite（非瓦片），贴图**可大于单格**，按"接口点"锚定：默认接口点=纹理中心=格中心（Sprite 居中定位）；内容不在画布中心的正式美术用 `Sprite2D.offset` 把接口点移到格中心（旋转绕该点）。教训：192×32 图集画布、内容只画最左 32px → 整体左移 80px"不显示"。

## 4. 场景脚本注入 / 保存

- `.tscn` 冲突禁手合并（用 Godot GUI）；小属性改动与工具脚本 `pack+save` 允许，且已验证会保留子场景 instance 引用。
- **owner 必须在 `add_child` 之后设置**（`world.add_child(fx); fx.owner = root`），否则报 "Invalid owner"。

## 5. 临时验证脚本（headless 断言，用完即删）

- 建 `tools/VerifyFixes.gd` + `.tscn`：`_ready()` 里实例化目标场景 → `await get_tree().process_frame` → 逐条 `_ok(cond, msg)`（PASS/FAIL）→ `get_tree().quit(1 if fails>0 else 0)`。
- 断言**必须查 `is_visible_in_tree()` 与纹理尺寸**，别只看字段——"纹理内美术偏移"类 bug 只能靠几何断言拦。
- 校验要点示例：头/尾位置=格中心、旋转与贴图尺寸（可>32px，须几何断言）、PlayerCells 瓦片列号（中段 0/1/2/3/4/5 直/弯 + 头格/尾格端点瓦 6=E 7=W 8=S 9=N）、机关 claimed 含核心格、核心格已铺瓦、掩码位含核心。
- 跑完**删除三个文件**（.gd / .gd.uid / .tscn）。

## 6. 编辑器/文件系统陷阱（已多次踩实）

- 同一文件**并行/连续 Edit 可能偶发丢落**（返回成功但磁盘未变）。对策：关键修改后立刻复查；同文件分多批小改；必要时整文件 `Write`；结束前用 `--import` 或全仓库 Grep 复核零残留。
- Read 工具可能返回旧快照，Edit 的 "not found" 报错反而是磁盘真值——以 Edit 结果判断文件实际内容。
- GDScript 带类型参数**不能默认 null**（`mask_set: Dictionary = null` 直接 Parse Error）→ 用无类型参数。
- TileSet 是 RefCounted，**不要 `.free()`**。
- 数组/字典元素类型推断常报错：显式标注 `var c: Vector2i` / `for s: int in [...]`。

## 7. 产出收尾

- 新贴图/图集登记进 [开发文档](../../开发文档.md) §3.9（A-xx）。
- 替换占位（`terrain_floor.svg`/`terrain_mech.svg` / `player_snek.svg`；墙占位 `terrain_wall.svg` 已删、正式图 `ImportArt/Terrarin-wall.png`）保持「行列+角序 / 瓦片列号」等结构契约，否则已画地图/已绑 Sprite 错位。`player_snek.svg` 现为 320×32（col0..5 连接件 + col6..9 端点半截瓦）；头部贴图为**精灵表 132×176**（4 行方向 × 3 列帧，Head Sprite 用 hframes=3/vframes=4 选片、不旋转），替换后须复查 Sprite2D.offset 接口点是否仍对齐帧中心。
