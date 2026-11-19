#!/usr/bin/env bash
# install.sh — ai-coding-kit 安装器（macOS / Linux，与 install.ps1 同语义）
# 语义：把 kit 单一源（skills/ + rules/）转换为目标 IDE 布局；只转格式不改语义。
# 同名文件跳过不覆盖并报告；CLAUDE.md 以标记块幂等替换；模板仅在 --with-templates 且目标缺失时生成。
# 用法示例：
#   bash ai-coding-kit/adapters/install.sh --ide qoder
#   bash ai-coding-kit/adapters/install.sh --ide claude-code --stack python --with-templates
#   bash ai-coding-kit/adapters/install.sh --ide cursor --dry-run --target /path/to/project

set -euo pipefail

IDE=""
STACK="java,vue"
WITH_TEMPLATES=0
DRY_RUN=0
TARGET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --ide) IDE="${2:-}"; shift 2 ;;
    --stack) STACK="${2:-}"; shift 2 ;;
    --with-templates) WITH_TEMPLATES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

case "$IDE" in
  qoder|cursor|claude-code) ;;
  *) echo "必须指定 --ide qoder|cursor|claude-code" >&2; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KIT_ROOT="$(dirname "$SCRIPT_DIR")"
if [ -z "$TARGET" ]; then TARGET="$(dirname "$KIT_ROOT")"; fi
TARGET="$(cd "$TARGET" && pwd)"

IFS=',' read -r -a SELECTED_STACKS <<< "$STACK"
for s in "${SELECTED_STACKS[@]}"; do
  case "$s" in
    java|vue|python) ;;
    *) echo "非法栈名 '$s'：--stack 仅支持 java,vue,python 的逗号列表" >&2; exit 1 ;;
  esac
done

COPIED=""
SKIPPED=""
PLANNED=""

install_content() {
  # $1=目标路径 $2=内容
  local dest="$1" content="$2"
  if [ -e "$dest" ]; then
    SKIPPED="${SKIPPED}${dest}"$'\n'
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    PLANNED="${PLANNED}${dest}"$'\n'
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  printf '%s' "$content" > "$dest"
  COPIED="${COPIED}${dest}"$'\n'
}

strip_frontmatter() {
  awk 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm {print}' "$1"
}

convert_mdc() {
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" {
      print "---"
      if (trigger=="always_on") { if (desc!="") print "description: " desc; print "alwaysApply: true" }
      else if (trigger=="model_decision") { print "description: " desc; print "alwaysApply: false" }
      else if (trigger=="glob") {
        print "description: " desc
        print "globs:"
        for (i=1; i<=ng; i++) print "  - \"" globs[i] "\""
        print "alwaysApply: false"
      }
      else { print "未知 trigger: " trigger > "/dev/stderr"; exit 1 }
      print "---"
      infm=0; next
    }
    infm {
      if ($0 ~ /^trigger:/) { sub(/^trigger:[ \t]*/, ""); trigger=$0 }
      else if ($0 ~ /^description:/) { sub(/^description:[ \t]*/, ""); desc=$0 }
      else if ($0 ~ /^[ \t]+-[ \t]+/) { s=$0; sub(/^[ \t]+-[ \t]+/, "", s); gsub(/"/, "", s); globs[++ng]=s }
      next
    }
    { print }
  ' "$1"
}

stack_selected() {
  local key="$1" s
  for s in "${SELECTED_STACKS[@]}"; do
    if [ "$s" = "$key" ]; then return 0; fi
  done
  return 1
}

# ---------- skills 安装 ----------
for dir in "$KIT_ROOT"/skills/*/; do
  name="$(basename "$dir")"
  src="${dir}SKILL.md"
  case "$IDE" in
    qoder)
      install_content "$TARGET/.qoder/skills/$name/SKILL.md" "$(cat "$src")"
      ;;
    claude-code)
      install_content "$TARGET/.claude/skills/$name/SKILL.md" "$(cat "$src")"
      ;;
    cursor)
      install_content "$TARGET/.cursor/commands/$name.md" "$(strip_frontmatter "$src")"
      ;;
  esac
done

# ---------- rules 安装 ----------
CLAUDE_IMPORTS=""
KIT_REL="$KIT_ROOT"
case "$KIT_ROOT" in
  "$TARGET"/*) KIT_REL="${KIT_ROOT#"$TARGET"/}" ;;
esac
for file in "$KIT_ROOT"/rules/*.md; do
  fname="$(basename "$file")"
  case "$IDE" in
    qoder)
      install_content "$TARGET/.qoder/rules/$fname" "$(cat "$file")"
      ;;
    cursor)
      mdcname="${fname%.md}.mdc"
      install_content "$TARGET/.cursor/rules/$mdcname" "$(convert_mdc "$file")"
      ;;
    claude-code)
      # 无 glob 机制：安装期按 --stack 挑选；core（无 stack 键）全量，stack 规则仅选中栈
      stackkey="$(awk -F': ' '/^stack:/ {print $2; exit}' "$file" | tr -d '"' | tr -d '[:space:]')"
      if [ -z "$stackkey" ] || stack_selected "$stackkey"; then
        CLAUDE_IMPORTS="${CLAUDE_IMPORTS}@${KIT_REL}/rules/${fname}"$'\n'
      fi
      ;;
  esac
done

# ---------- claude-code：CLAUDE.md 标记块幂等替换 ----------
if [ "$IDE" = "claude-code" ]; then
  BEGIN_MARK='<!-- ai-coding-kit:begin -->'
  END_MARK='<!-- ai-coding-kit:end -->'
  BLOCK="${BEGIN_MARK}"$'\n'"${CLAUDE_IMPORTS%$'\n'}"$'\n'"${END_MARK}"
  CLAUDE_PATH="$TARGET/CLAUDE.md"
  if [ -e "$CLAUDE_PATH" ]; then
    if grep -qF "$BEGIN_MARK" "$CLAUDE_PATH"; then
      UPDATED="$(awk -v block="$BLOCK" '
        BEGIN { inblock=0; replaced=0 }
        index($0, "<!-- ai-coding-kit:begin -->") { if (!replaced) { print block; replaced=1 } inblock=1; next }
        index($0, "<!-- ai-coding-kit:end -->") { inblock=0; next }
        !inblock { print }
      ' "$CLAUDE_PATH")"
    else
      UPDATED="$(cat "$CLAUDE_PATH")"$'\n\n'"$BLOCK"
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
      PLANNED="${PLANNED}${CLAUDE_PATH}"$'\n'
    elif [ "$UPDATED" != "$(cat "$CLAUDE_PATH")" ]; then
      printf '%s\n' "$UPDATED" > "$CLAUDE_PATH"
      COPIED="${COPIED}${CLAUDE_PATH}"$'\n'
    else
      SKIPPED="${SKIPPED}${CLAUDE_PATH}"$'\n'
    fi
  else
    install_content "$CLAUDE_PATH" "$BLOCK"$'\n'
  fi
fi

# ---------- templates（仅 --with-templates 且目标缺失时生成） ----------
if [ "$WITH_TEMPLATES" -eq 1 ]; then
  install_content "$TARGET/AGENTS.md" "$(cat "$KIT_ROOT/templates/AGENTS.md")"
  install_content "$TARGET/docs/INDEX.md" "$(cat "$KIT_ROOT/templates/docs/INDEX.md")"
  install_content "$TARGET/docs/GLOSSARY.md" "$(cat "$KIT_ROOT/templates/docs/GLOSSARY.md")"
  install_content "$TARGET/docs/specs/_domains.md" "$(cat "$KIT_ROOT/templates/docs/specs/_domains.md")"
fi

# ---------- 报告 ----------
count_lines() { if [ -z "$1" ]; then echo 0; else printf '%s' "$1" | grep -c '^'; fi; }
echo "ai-coding-kit install: Ide=$IDE Target=$TARGET Stack=$STACK DryRun=$DRY_RUN WithTemplates=$WITH_TEMPLATES"
echo "copied  ($(count_lines "$COPIED")):"
printf '%s' "$COPIED" | sed 's/^/  /'
echo "skipped ($(count_lines "$SKIPPED"), 同名不覆盖):"
printf '%s' "$SKIPPED" | sed 's/^/  /'
if [ "$DRY_RUN" -eq 1 ]; then
  echo "planned ($(count_lines "$PLANNED"), DryRun 未写入):"
  printf '%s' "$PLANNED" | sed 's/^/  /'
fi
exit 0