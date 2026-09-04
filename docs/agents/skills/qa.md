# Skill: 测试与质量（qa）

**描述：** 按权威验收标准回归、性能检查、规范符合性审查、导出验证。PR 前 / 里程碑前 / 疑难 bug 时使用。

## 使用场景
- PR 提交前自检
- 里程碑（M1/M2/M3）前回归
- 出现疑难 bug 需运行时证据
- 导出前验证

## 指令
1. **规范符合性：** 对照 [coding-rules.md](../rules/coding-rules.md) 与 [开发文档.md](../../开发文档.md) 检查：
   - 是否有裸 `load()` / 裸 `get_node("/root/...")` / 裸键码
   - 是否在 `_process` 里 `get_node`、是否轮询替代事件驱动
   - 信号是否走 `EventManager`、资源是否走 `ResourceManager`、音频是否走 `AudioManager`
   - 是否在脚本里硬编码了玩法数值（应来自 Balance/关卡 `.tres`）
2. **运行验证：**
   - 项目能 F5 启动到 `Main.tscn` 无报错
   - Autoload 五件套（含 SaveManager）加载成功
   - 改动的场景能正常打开（无 `.tscn` 解析错误）
3. **功能回归：** 逐条对照 [功能需求文档.md](../../design/功能需求文档.md) §8 验收标准（C-01..C-14 + C-Lnn）跑关卡；数值对照 §7。
4. **死局/BFS 专项：** 构造死局场景（无通路）确认自动判负；构造占格冲突场景确认"跳过但 lv+1、后续再占"（C-08）；确认动画锁输入（C-09）。
5. **错误流：** `push_warning/push_error` 不得被业务代码静默吞掉；Output 面板 warning/error 数应为 0。
6. **性能：** 32×32 下 BFS 单次 < 1ms；机关动画不卡帧；大资源用 `ResourceManager.prewarm()` 异步预热。
7. **LFS 完整性：** `git lfs ls-files` 列出的大资源与 `.gitattributes` 一致；`git status` 不应包含 `.godot/` 残留。
8. **存档：** 首次无存档默认解锁第 1 关；通关后解锁推进、重开项目仍在。
9. **导出（仅 M3）：** 按目标平台导出，验证资源路径无 `res://` 失效。

## 输出格式
- 检查清单结果（通过 / 警告 / 失败，含对应 C-xx / Lnn 编号）
- 失败项：定位文件:行号 + 复现步骤 + 建议
- 性能热点（若测）
