#!/bin/bash
#
# 校验 → 提交 → 推送 → 盯着线上直到构建完成。
#
#   .tools/publish.sh "更新简介"
#
# 推之前先双击 index.html 在浏览器里看一眼，样式对了再跑这个。
#
# 这个脚本解决的是「静默失败」：GitHub Pages 那边出问题时不会有任何页面
# 提示，你只会看到旧内容。它通过轮询 last-modified 响应头来判断新版本
# 是否真的上线了。

set -e
cd "$(dirname "$0")/.."

MSG="${1:-update site}"
SITE="https://yannianniu.github.io"

# ---------- 1. 体检 ----------
echo "=== 检查文件 ==="
ruby .tools/check.rb || exit 1

# ---------- 2. 有东西可推吗 ----------
# 两种情况都算「有东西」：文件改了还没提交，或者提交了但上次推送失败。
DIRTY=$(git status --porcelain)
AHEAD=$(git log @{u}.. --oneline 2>/dev/null | wc -l | tr -d ' ')

if [ -z "$DIRTY" ] && [ "$AHEAD" = "0" ]; then
  echo "没有改动，不需要推送。"
  exit 0
fi

if [ -n "$DIRTY" ]; then
  echo "=== 本次改动 ==="
  git status --short
  echo
else
  echo "工作区干净，还有 $AHEAD 个提交没推上去，直接推。"
  echo
fi

# ---------- 3. 记下推送前的部署时间戳 ----------
BEFORE=$(curl -sI "$SITE" | tr -d '\r' | awk 'tolower($1)=="last-modified:"{$1=""; print substr($0,2)}')
echo "线上当前版本: ${BEFORE:-未知}"

# ---------- 4. 提交并推送 ----------
if [ -n "$DIRTY" ]; then
  git add -A
  git commit -q -m "$MSG"
fi
echo "=== 推送中 ==="
git push -q
echo "已推送: $(git log -1 --format='%h %s')"

# ---------- 5. 等构建 ----------
echo
echo "=== 等待 GitHub Pages 构建（最多 5 分钟）==="
for i in $(seq 1 30); do
  sleep 10
  # 加时间戳绕开 CDN 的 600 秒缓存
  NOW=$(curl -sI "$SITE/?v=$(date +%s)" | tr -d '\r' | awk 'tolower($1)=="last-modified:"{$1=""; print substr($0,2)}')
  if [ -n "$NOW" ] && [ "$NOW" != "$BEFORE" ]; then
    echo
    echo "构建成功，新版本已上线。"
    echo "  部署时间: $NOW"
    echo "  地址:     $SITE"
    echo
    echo "浏览器里记得硬刷新（Cmd+Shift+R）—— CDN 缓存 10 分钟。"
    exit 0
  fi
  printf '.'
done

echo
echo "超时：5 分钟内线上没有更新。"
echo
echo "多半是构建失败了。去这里看具体报错："
echo "  https://github.com/YannianNiu/YannianNiu.github.io/actions"
echo
echo "GitHub 也会往你的注册邮箱发一封构建失败的邮件，里面有出错的文件和行号。"
exit 1
