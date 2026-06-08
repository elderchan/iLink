你现在执行 iLink 的 **流水线状态查看** 操作。

## 参数

`$ARGUMENTS` 可选。如果提供，则为具体的 Story ID；如果不提供，则显示所有 Story 的状态总览。

## 执行任务

调用 bash 脚本查看状态：

```bash
bash .qoder/commands/ilink-status $ARGUMENTS
```

**SHALL NOT**：
- 自己读取文件拼状态信息——这些全部由 bash 脚本完成

## 输出处理

bash 脚本的 stdout / stderr **原样转给用户**。SHALL NOT 重复转述或自行解释脚本已经说过的内容。
