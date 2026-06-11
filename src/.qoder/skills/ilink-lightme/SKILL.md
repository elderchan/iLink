# ilink-lightme

执行 iLink Lightme（设计/需求拷问员）角色 — 可选审视步骤，主流程之外，用于在使用者推进下游之前照亮盲区。

> 详见 Root Spec §4.8、`iLink/souls/lightme.soul.md`。advisory 性质，不改变 Status，不阻塞下游，**SHALL NOT 触碰任何 master doc / project-context / domain-knowledge 文件**。所有发现以 copy-ready 修订建议代码块的形式写入 lightme 报告，使用者自行复制粘贴。

## 用法

```
/ilink-lightme <story>                    # 默认拷问 design
/ilink-lightme -target pm <story>         # 拷问 pm
/ilink-lightme -target design <story>     # 显式拷问 design
```

## 前置准备

**友情提示**：建议在**全新的 Qoder 会话**中运行 lightme（见 Root Spec §4.8.3）。全新会话对抗"AI 自身合理性"和同会话护短通常更有效，但会重新读取 soul、项目文档、目标文档和相关代码，可能消耗更多 token。同一会话也允许执行，只是隔离效果下降。

在 Qoder 会话中输入 `/ilink-lightme [-target pm|design] <story>`。AI 会自动调用预检脚本（`.qoder/commands/ilink-lightme`，内部细节）校验目标文档存在并计算 Upstream_SHA1，然后按本章节执行拷问任务。若明显是在生成目标文档的同一会话中运行，先向使用者友情提示隔离效果下降与 token 权衡，但不阻断。

## 准备

- 读取 `iLink/souls/universal.soul.md` 及其 plug（若存在）
- 读取 `iLink/souls/lightme.soul.md` 及 `iLink/souls/plugs/lightme.project.plug.md`（若存在）

## 前置检查

> lightme 不限目标文档状态——任何阶段（STAGING / PENDING_DESIGNER / PENDING_CODER / 已被下游消费 / 已 COMPLETED）都可触发，因为 lightme 不动 master doc。

### Design 模式（默认）

- 读取 `iLink-doc/<story>/<story>-design.master.md`
- 若不存在，提示用户先执行 `/ilink-design <story>` 并退出

### PM 模式（`-target pm`）

- 读取 `iLink-doc/<story>/<story>-pm.master.md`
- 若不存在，提示用户先执行 `/ilink-pm <story>` 并退出
- 读取 `iLink-doc/<story>/<story>-requirement.md`（需求定义原文）

### 与 /ilink-refine 的顺序建议

若目标文档含 `[待确认]` 项，**建议先 `/ilink-refine` 把 [待确认] 项澄清成 [已确认]，再 `/ilink-lightme` 拷问**。理由：refine 解决"已知不确定性"，lightme 挖"未发现盲区"——先把已知问题压实，避免 lightme 在已经标了 [待确认] 的位置重复挖。

顺序不强制；使用者也可先跑 lightme 让两边问题一并暴露，再决定如何修订。

## 执行（拷问主流程）

### Design 模式

按 lightme.soul.md 第 3 节"工作方式"执行：四原则 + 查代码找文档 + 术语拷问 + 场景压测 + 代码交叉验证。

按 lightme.soul.md 第 5 节执行追问策略：动态主导 + 高频维度评估扫描（不为凑数提问）。

按 lightme.soul.md 第 4 节执行检索局限标注：阳性 / 阴性结论区分。

每识别一个盲区 → 标注三态（RESOLVED / TO-FIX / ACCEPTED-RISK）→ 追加进 `<story>-lightme-design.md` 的"被照亮的盲区与处置"区块。**TO-FIX 项 MUST 附 copy-ready 修订建议代码块**（见下文）。

### PM 模式（`-target pm`）

按 lightme.soul.md 第 3 节四原则执行，但拷问维度切换为需求层面：

- **需求完整性**：是否覆盖了所有应该有的用户场景？有没有"用户没说但应该有的"需求被遗漏？
- **AC 可验证性**：每条验收标准是否能明确判断"做到/没做到"？有没有含糊的"性能好"、"用户体验好"类 AC？
- **范围边界清晰度**：In Scope / Out of Scope 是否精确到不会产生歧义？有没有容易被误解为要做但实际不做的事没列进 Out of Scope？
- **隐含假设显式化**：PM 是否把隐含假设标注为 `[PM推导]` 或 `[待确认]`？有没有未声明的假设被当作事实写进了 B 层？
- **约束与风险覆盖**：B2 硬约束是否完整？B5 假设与风险是否覆盖了可能的失败路径？

每识别一个盲区 → 标注三态 → 追加进 `<story>-lightme-pm.md` 的"被照亮的盲区与处置"区块，TO-FIX 项同样 MUST 附 copy-ready 代码块。

## 写入边界（核心硬约束）

lightme 的**唯一产出**是 lightme 报告。除此之外：

- **SHALL NOT** 写、改、删任何 master doc（pm/design/code/review.master.md）
- **SHALL NOT** 写、改、删 `project-context.md`
- **SHALL NOT** 写、改、删 `iLink-doc/domain/<模块>-domain-knowledge.md`
- **SHALL NOT** 改变任何 Master Doc 的 Status
- **SHALL NOT** 调用 `/ilink-refine` / `/ilink-pm` / `/ilink-design` 等其他命令

不管目标文档当前 Status 是什么，lightme 行为完全一致——只生成报告，TO-FIX 项以可粘贴片段呈现，使用者自行复制到目标文件。

详见 Root Spec §4.8.2。

## TO-FIX 项 copy-ready 修订建议代码块（硬要求）

每个 TO-FIX 项 **MUST** 附一段或多段 ` ```diff` 或 ` ```markdown` 代码块，给出可直接复制粘贴到目标文件的精确文本。**SHALL NOT** 只写"建议增加 XX 章节" / "建议明确 YY 边界"等抽象描述。

代码块 MUST 至少包含：
- **目标位置**：文件名 + 章节锚点（如 `pm.master.md §B5` 或 `design.master.md §6 [DESIGN_DECISIONS]`）
- **修订内容**：原文 → 改后，或直接给出新增片段

详细示例见 Root Spec §4.8.6。

## 输出

- Design 模式：`iLink-doc/<story>/<story>-lightme-design.md`，按 Root Spec §4.8.6 结构
- PM 模式：`iLink-doc/<story>/<story>-lightme-pm.md`，结构相同

## Metadata 印章

```
---
# ILINK-PROTOCOL-METADATA
Protocol_Version: v1.8.0
Role: LIGHTME
AI_Vendor: Qoder
AI_Model: <实际版本>
Current_Timestamp: <shell 获取>
Upstream_SHA1: <shasum 目标文档 取第一列>
Status: ADVISORY
---
```

SHA1 来源：
- Design 模式：`shasum iLink-doc/<story>/<story>-design.master.md`
- PM 模式：`shasum iLink-doc/<story>/<story>-pm.master.md`

SHA1 与时间戳 MUST 通过 shell 命令实际获取。预检脚本（`.qoder/commands/ilink-lightme`）已计算 SHA1 并在终端输出，可直接采用。

## 完成后

- 提示用户：lightme 报告已生成，建议在下一步操作前 review
- TO-FIX 盲区 → 提示使用者将报告中对应的 copy-ready 代码块粘贴到目标文件后再推进下游
- ACCEPTED-RISK 盲区 → 已留痕；Design 模式 `/ilink-approve` 即代表接受，PM 模式进入 `/ilink-design` 即代表接受
- 不下"通过 / 不通过"结论

## 硬约束（防走过场）

- SHALL NOT 出现 "通过"、"可以进入编码"、"设计无问题"、"建议批准" 等结论性表述
- MUST 至少 3 个具体、有现状依据的盲区（除非使用者主动确认全覆盖）
