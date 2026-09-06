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

- **禁 `set_cells_terrain_connect` 批量重涂**：会外扩（地板 40→70 格案例）。重铺一律**确定性直写**：按格集几何算掩码，`layer.set_cell(c, 0, coords)`，绝不外扩。可参考 `Level._paint_auto`（corners+sides 瓦片集走 `_paint_blob_auto`：按 8 邻接规范掩码查瓦，角位需两侧都涂；**地板/墙/机关三套 blob47 都走这条**，仅旧 `TerrainFloor.tres` 走 4 角掩码 `Vector2i(mask,0)`）（v1.16 已清理引用旧关的一次性工具 MigrateTerrain / RebuildLevelTiles，重铺参考 `Level._paint_auto` 直写逻辑）。
- 地形瓦片集（三套 blob47 的瓦片=ascending canonical blob 列序）：地板 `TerrainGrassBlob47.tres`（正式 `Art/Tiles/TILE_Grass_Blob47_01.png`，1504×32 单行 47 瓦）、**墙 `TerrainWall.tres`（正式 `Art/Tiles/TILE_Wall_Blob47__01.png`，1504×32 单行 47 瓦）**、**机关 `TerrainMech.tres`（正式 `Art/Tiles/TILE_Flower_Blob47_Animated_01.png`，1504×96，47 列 × 3 帧行 0=冒出/1=生长中/2=完成）**，三套 peering 逐列一致；墙/机关 .tres 由 `tools/GenBlob47MechWall.tscn` 就地重写。旧 `TerrainFloor.tres`（16 列 4 角，角序 bit0=左上…bit3=右下）仅给未迁移旧关。**瓦片必须建在脚本写格的那个行**——建在非 0 行而场景按 `(mask,0)` 写格会**静默不显示**（机关停留格写 row2）。
- **工具重存 .tres 会丢 uid 头**（ResourceSaver.save 在该会话未注册 path→uid 时直接省略）：重生成 Terrain*.tres 后必须把原 `uid="uid://…"` 补回 gd_resource 首行，否则场景按 uid 引用 TileSet 会全部失联。
- 机关生长体铺瓦集合=全部 `claimed` 格**含核心格**（掩码才把核心当邻居，角点不缺瓦）；核心由 Core Sprite 画，Mechanism 根节点 `z_index=1` 浮瓦片层之上（MechanismCells 层在场景树里位于 EntityRoot 之后）。
- 头/尾是独立 Sprite（非瓦片），贴图**可大于单格**，按"接口点"锚定：默认接口点=纹理中心=格中心（Sprite 居中定位）；内容不在画布中心的正式美术用 `Sprite2D.offset` 把接口点移到格中心（旋转绕该点）。教训：192×32 图集画布、内容只画最左 32px → 整体左移 80px"不显示"。**正式头（Algee-all）锚点=贴图垂直 3/4（下半部分中点）**：Level 运行期 `_set_head_anchor` 按帧高自动 `offset.y = -帧高/4`。

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
- 替换占位 / 更新正式美术：地板/墙/机关已全是正式 47-blob（三套 peering 列序一致，替换美术须保持 ascending canonical 列序）；玩家身体=`Art/Tiles/path.png`（10 列：col0..5 连接件 + col6..9 端点半截瓦）；头=`Art/Sprites/Algee-all.png`（**96×256 精灵表**，4 行方向 × 3 列帧，Head Sprite 用 hframes=3/vframes=4 选片、不旋转，每步播 0→1 两帧停回帧 2），替换后须复查 Sprite2D.offset 接口点是否仍对齐帧中心。
