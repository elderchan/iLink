#!/usr/bin/env bash
# iLink ilink-lightme — Claude 平台脚本
# /ilink-lightme <story> 的预检:校验 design.master.md 存在性 + 提取 Status + 计算 Upstream_SHA1 + 报告 domain 覆盖
# 用法: bash .claude/commands/ilink-lightme.sh <story-id>
# 依赖: bash + grep + sed + awk + shasum + find + tr (macOS/Linux/Git Bash 默认全部包含)

set -eo pipefail

# ============================================================
# 1. 参数解析(严格只接受 1 个参数)
# ============================================================
if [[ $# -ne 1 || -z "${1:-}" ]]; then
  echo "❌ 用法：/ilink-lightme <story-id>" >&2
  echo "" >&2
  echo "例如：/ilink-lightme kcia-1520" >&2
  exit 1
fi

story="$1"
base_dir="iLink-doc/${story}"

# ============================================================
# 2. Story 目录与 design.master.md 存在性校验
# ============================================================
if [[ ! -d "$base_dir" ]]; then
  echo "❌ Story 目录不存在: $base_dir" >&2
  echo "   请先执行 /ilink-init $story <usage-value> 创建 Story" >&2
  exit 1
fi

design_doc="${base_dir}/${story}-design.master.md"
if [[ ! -f "$design_doc" ]]; then
  echo "❌ design.master.md 不存在: $design_doc" >&2
  echo "   Lightme 运行在 /ilink-design 与 /ilink-approve 之间。" >&2
  echo "   请先执行 /ilink-design $story" >&2
  exit 1
fi

# ============================================================
# 3. 提取 Status (从 Metadata 印章)
# ============================================================
status=$(grep -E '^Status: ' "$design_doc" 2>/dev/null | tail -1 | sed 's/^Status: //' | tr -d ' \r\n')

if [[ -z "$status" ]]; then
  echo "⚠️ 无法从 design.master.md 提取 Status 字段(Metadata 印章缺失或格式异常)" >&2
  echo "   继续执行,但 Status 检查跳过。" >&2
  status="UNKNOWN"
fi

if [[ "$status" == "PENDING_CODER" ]]; then
  echo "❌ design.master.md 状态为 PENDING_CODER —— 该 design 已经过 /ilink-approve,再跑 lightme 无意义。" >&2
  echo "" >&2
  echo "   典型修复路径:" >&2
  echo "   - 如发现设计缺陷想推翻已 approve 的决策:重跑 /ilink-design 生成新 design(Status 回 STAGING),再 /ilink-lightme" >&2
  echo "   - 如仅想审计已 approve 设计的盲区记录:不要用 lightme,建议 Leader 手动复盘并在 Story 笔记或 commit 信息中留痕" >&2
  exit 1
elif [[ "$status" != "STAGING" && "$status" != "UNKNOWN" ]]; then
  echo "⚠️ design.master.md 状态为 $status (期望 STAGING)" >&2
  echo "   Lightme 在 design STAGING 等待 approve 时最有用。" >&2
  echo "   继续执行。" >&2
fi

# ============================================================
# 4. 计算 SHA1 (给 AI 用作 Metadata 印章的 Upstream_SHA1)
# ============================================================
sha1=$(shasum "$design_doc" | awk '{print $1}')

# ============================================================
# 5. 报告 domain 覆盖率(informational only)
# ============================================================
domain_dir="iLink-doc/domain"
domain_count=0
if [[ -d "$domain_dir" ]]; then
  domain_count=$(find "$domain_dir" -maxdepth 1 -name '*-domain-knowledge.md' 2>/dev/null | wc -l | tr -d ' ')
fi

# ============================================================
# 6. 输出预检报告
# ============================================================
echo ""
echo "=========================================="
echo "/ilink-lightme <$story> 预检完成"
echo "=========================================="
echo ""
echo "  目标 design   : $design_doc"
echo "  Status        : $status"
echo "  Upstream_SHA1 : $sha1"
echo "  Domain 文档数 : $domain_count (in $domain_dir/)"
echo ""
echo "AI 将基于以上信息执行拷问任务:"
echo "    1. 加载 design.master.md / project-context.md / 相关 domain"
echo "    2. 以对抗(协作)人格拷问设计,挑盲区(至少 3 个)"
echo "    3. 经 Human-Gate 确认后就地更新 project-context.md / 已存在的 domain"
echo "    4. 生成 iLink-doc/$story/${story}-lightme.md 审计报告"
echo "    5. Metadata 印章使用 Upstream_SHA1: $sha1"
echo ""
echo "⚠️ 提醒 Leader:本命令 MUST 在【全新的 Claude Code 会话】中运行,"
echo "   不能接在生成 design 的同一会话后(会护短,见 Root Spec §4.8.5)。"
echo ""
