# Skill: 测试与质量（qa）

**描述：** 回归测试、性能检查、规范符合性审查、导出验证。PR 前 / 里程碑前 / 疑难 bug 时使用。

## 使用场景
- PR 提交前自检
- 里程碑（M1/M2/M3）前回归
- 出现疑难 bug 需运行时证据
- 导出前验证

## 指令
1. **规范符合性：** 对照 [coding-rules.md](../rules/coding-rules.md) 与 [开发文档.md](../../开发文档.md) 检查：
   - 是否有裸 `load()` / 裸 `get_node("/root/...")` / 裸键码
   - 是否在 `_process` 里 `get_node`
   - 信号是否走 `EventManager`、资源是否走 `ResourceManager`、音频是否走 `AudioManager`
2. **运行验证：**
   - 项目能 F5 启动到 `Main.tscn` 无报错
   - Autoload 四件套均加载成功
   - 改动的场景能正常打开（无 `.tscn` 解析错误）
3. **数值回归：** 对照 [开发文档.md](../../开发文档.md) §5.6 测试基准（玩法冻结后填入）。
4. **错误流：** `push_warning/push_error` 不得被业务代码静默吞掉；Output 面板的 warning/error 数应为 0。
5. **性能：** 关注 `_process` 中的高频操作；大资源用 `ResourceManager.prewarm()` 异步预热。
6. **LFS 完整性：** `git lfs ls-files` 列出的大资源与 `.gitattributes` 一致；`git status` 不应包含 `.godot/` 残留。
7. **导出（仅 M3）：** 按目标平台导出，验证资源路径无 `res://` 失效。

## 输出格式
- 检查清单结果（通过 / 警告 / 失败）
- 失败项：定位文件:行号 + 复现步骤 + 建议
- 性能热点（若测）
