# ilink-lightme

执行 iLink Lightme（设计拷问员）角色 — `/ilink-design` 与 `/ilink-approve` 之间的可选咨询步骤。

## 用法

```
/ilink-lightme <story>
```

## 前置准备

**重要**：lightme MUST 在**全新的 Qoder 会话**中运行，不能接在 `/ilink-design` 的同一会话后（同模型会护短，见 Root Spec §4.8.5）。

在【全新的 Qoder 会话】中输入 `/ilink-lightme <story>`。AI 会自动调用预检脚本（`.qoder/commands/ilink-lightme`，内部细节）校验 design.master.md 存在并计算 Upstream_SHA1，然后按本章节执行拷问任务。

## 准备

- 读取 `iLink/souls/universal.soul.md` 及其 plug（若存在）
- 读取 `iLink/souls/lightme.soul.md` 及 `iLink/souls/plugs/lightme.project.plug.md`（若存在）

## 前置检查

- 读取 `iLink-doc/<story>/<story>-design.master.md`
- 若不存在，提示用户先执行 `/ilink-design <story>` 并退出
- 检查 design.master.md 的 Status：
  - `STAGING`（典型）→ 继续
  - `PENDING_CODER` → **拒绝执行**：design 已经过 approve，lightme 无意义。提示用户：要么重跑 `/ilink-design` 后再 lightme，要么手动复盘留痕
  - 其它状态 → warning 但继续

### 与 /ilink-refine 的顺序建议

若 design 含 `[待确认]` 项，**建议先 `/ilink-refine` 把 [待确认] 项澄清成 [已确认]，再 `/ilink-lightme` 拷问**。理由：refine 解决"已知不确定性"，lightme 挖"未发现盲区"——先把已知问题压实，避免 lightme 在已经标了 [待确认] 的位置重复挖。

顺序不强制；Leader 也可先跑 lightme 让两边问题一并暴露，再决定如何修订。

## 执行（拷问主流程）

按 lightme.soul.md 第 3 节"工作方式"执行：四原则 + 查代码找文档 + 术语拷问 + 场景压测 + 代码交叉验证。

按 lightme.soul.md 第 5 节执行追问策略：动态主导 + 高频维度评估扫描（不为凑数提问）。

按 lightme.soul.md 第 4 节执行检索局限标注：阳性 / 阴性结论区分。

每识别一个盲区 → 标注三态（RESOLVED / TO-FIX / ACCEPTED-RISK）→ 追加进 `<story>-lightme.md` 的"被照亮的盲区与处置"区块。

## 三类 md 写入边界

按 lightme.soul.md 第 6 节执行：
- 写 `project-context.md` 前 MUST Human-Gate 确认，且 SHALL NOT 触碰 §7.8 隔离块
- 写已存在的 `<模块>-domain-knowledge.md` 前 MUST Human-Gate 确认
- **domain-knowledge.md §10 待确认区块 SHALL NOT 被 lightme 修改**；若有澄清要补入 §10，写进报告"建议补充 domain"区块转交 `/ilink-domain`（详见 Root Spec §4.8.10）
- domain-knowledge.md 不存在时 SHALL NOT 创建，写进报告"建议补充 domain"区块

## 输出

`iLink-doc/<story>/<story>-lightme.md`，按 Root Spec §4.8.12 结构。

## Metadata 印章

```
---
# ILINK-PROTOCOL-METADATA
Protocol_Version: v1.8.0
Role: LIGHTME
AI_Vendor: Qoder
AI_Model: <实际版本>
Current_Timestamp: <shell 获取>
Upstream_SHA1: <shasum design.master.md 取第一列>
Status: ADVISORY
---
```

SHA1 与时间戳 MUST 通过 shell 命令实际获取。预检脚本（`.qoder/commands/ilink-lightme`）已计算 SHA1 并在终端输出，可直接采用。

## 完成后

- 提示用户：lightme.md 已生成，建议在 approve 前 review
- TO-FIX 盲区 → 建议先回 `/ilink-design`（或 `/ilink-refine`）修正
- ACCEPTED-RISK 盲区 → 已留痕，approve 即代表接受
- 不下"通过 / 不通过"结论

## 硬约束（防走过场）

- SHALL NOT 出现 "通过"、"可以进入编码"、"设计无问题"、"建议批准" 等结论性表述
- MUST 至少 3 个具体、有现状依据的盲区（除非 Leader 主动确认全覆盖）
