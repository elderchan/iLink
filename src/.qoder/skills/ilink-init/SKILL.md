你现在执行 iLink 的 **Story 初始化** 操作。

## 参数

`$ARGUMENTS` 包含两个由空格分隔的参数：`<story-id> <usage-value>`。

- `<story-id>`：本次要初始化的 Story ID
- `<usage-value>`：执行本命令前，用户在 Qoder 中执行 `/usage` 查看到的"已使用 credits"数值

### 必填校验

如果 `$ARGUMENTS` 为空或解析后不包含两个参数（即缺少 `<usage-value>`），**MUST 拒绝执行**，向用户输出：

```
❌ 用法：/ilink-init <story-id> <usage-value>

请先在 Qoder 中执行 /usage 查看"已使用 credits"，然后以如下格式重试：
  /ilink-init <story-id> <已使用 credits 数字>

例如，/usage 显示已使用 1200 credits，则执行：/ilink-init kcia-1520 1200

无法查询时允许传入 0（语义为"故意跳过"，文件正常写入但 delta 标注不可信）。
```

## 执行任务

调用 bash 脚本执行实际初始化（脚本完成所有校验、目录创建、模板生成）：

```bash
bash .qoder/commands/ilink-init $ARGUMENTS
```

**SHALL NOT**：
- 自己创建目录、自己写模板文件——这些全部由 bash 脚本完成

## 输出处理

**首要原则**：bash 脚本的 stdout / stderr **原样转给用户**——脚本已包含完整的进度信息、成功提示、错误指引。SHALL NOT 重复转述或自行解释脚本已经说过的内容。

**仅在脚本退出码 0 时**，**追加** 1 行简短下一步提示（脚本本身不输出这行）：

> 下一步：编辑 requirement.md 填写需求内容，完成后执行 `/ilink-pm <story-id>` 进入需求分析阶段。

**脚本退出码非 0 时**：SHALL NOT 再次调用脚本、SHALL NOT 添加任何补充说明。用户根据 stderr 自行处理。
