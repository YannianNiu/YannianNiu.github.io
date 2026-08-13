# encoding: utf-8
#
# 推送前的本地体检。只用 Ruby 标准库，系统自带的 ruby 就能跑。
#
#   ruby .tools/check.rb
#
# 手写 HTML 最容易犯的三类错，这里都查：
#   1. 标签没闭合（复制粘贴一个块的时候漏了 </div>）——页面会整个错位
#   2. 导航栏的 #锚点 和板块的 id 对不上——点了不跳
#   3. 图片 / PDF 路径写错——显示成裂图，或者点 CV 404
# 另外提醒你哪里还留着【】占位符。

FILE = "index.html"

problems = []
def ok(msg)   puts "  \e[32mOK\e[0m   #{msg}" end
def bad(msg)  puts "  \e[31mFAIL\e[0m #{msg}" end
def warn(msg) puts "  \e[33m注意\e[0m #{msg}" end

unless File.exist?(FILE)
  bad("#{FILE} 不存在")
  exit 1
end

html  = File.read(FILE, encoding: "utf-8")
lines = html.lines

# 检查标签配对时要先把注释、CSS、JS 里的内容摘掉，
# 否则 JS 里的 a < b 之类会被当成标签。
clean = html.gsub(/<!--.*?-->/m) { |m| m.gsub(/[^\n]/, " ") }
            .gsub(/<style.*?<\/style>/m) { |m| m.gsub(/[^\n]/, " ") }
            .gsub(/<script.*?<\/script>/m) { |m| m.gsub(/[^\n]/, " ") }

# ---------- 1. 标签是否配对 ----------
puts "\n标签闭合"
CONTAINERS = %w[html head body header nav main section div footer h1 h2 h3 p span a ul li strong em]
VOID = %w[meta link img br hr input]

stack = []
clean.each_line.with_index(1) do |line, n|
  line.scan(/<(\/?)([a-zA-Z0-9]+)([^>]*)>/) do |slash, tag, attrs|
    tag = tag.downcase
    next unless CONTAINERS.include?(tag)
    next if VOID.include?(tag) || attrs.strip.end_with?("/")

    if slash.empty?
      stack.push([tag, n])
    else
      if stack.empty?
        problems << "第 #{n} 行多了一个 </#{tag}>"
        bad("第 #{n} 行：多出来一个 </#{tag}>，没有对应的开标签")
      elsif stack.last[0] != tag
        opened, oline = stack.last
        problems << "第 #{n} 行 </#{tag}> 对不上"
        bad("第 #{n} 行是 </#{tag}>，但当前还没关的是第 #{oline} 行的 <#{opened}>")
        stack.pop
      else
        stack.pop
      end
    end
  end
end

stack.each do |tag, n|
  problems << "第 #{n} 行 <#{tag}> 没闭合"
  bad("第 #{n} 行的 <#{tag}> 一直没关上，少一个 </#{tag}>")
end
ok("所有标签配对正常") if problems.empty?

# ---------- 2. 导航锚点 vs 板块 id ----------
puts "\n导航锚点"
ids     = clean.scan(/\bid="([^"]+)"/).flatten
anchors = clean.scan(/href="#([^"]+)"/).flatten.uniq

dead = anchors.reject { |a| ids.include?(a) }
if dead.empty?
  ok("#{anchors.size} 个锚点都能跳到对应板块")
else
  dead.each do |a|
    problems << "锚点 ##{a}"
    bad("href=\"##{a}\" 找不到对应的 id=\"#{a}\"，点了不会跳")
  end
end

# 板块有 id 但导航栏里没有链接 —— 不算错，只是提醒
sections = clean.scan(/<section[^>]*\bid="([^"]+)"/).flatten
orphan = sections - anchors
warn("板块 #{orphan.join(', ')} 没出现在导航栏里") unless orphan.empty?

# ---------- 3. 本地文件路径 ----------
puts "\n本地文件"
refs = (clean.scan(/(?:src|href)="([^"]+)"/).flatten)
       .reject { |r| r =~ %r{\A(https?:|mailto:|#|//|data:)} }
       .uniq

if refs.empty?
  ok("没有引用本地文件")
else
  refs.each do |r|
    path = r.sub(/[?#].*\z/, "")
    if File.exist?(path)
      ok(path)
    else
      problems << path
      bad("#{path} 不存在（页面上会显示成裂图或者点了 404）")
    end
  end
end

# ---------- 4. 占位符提醒（不算错误） ----------
placeholders = lines.each_with_index.select { |l, _| l.include?("【") }
unless placeholders.empty?
  puts "\n\e[33m还没填的占位符【】—— 共 #{placeholders.size} 处\e[0m"
  placeholders.first(20).each do |l, i|
    puts "  第 #{i + 1} 行: #{l.strip[0, 70]}"
  end
  puts "  ……还有 #{placeholders.size - 20} 处" if placeholders.size > 20
end

puts
if problems.empty?
  puts "\e[32m通过，可以推送。\e[0m\n\n"
  exit 0
else
  puts "\e[31m#{problems.size} 个问题，先修好再推。\e[0m\n\n"
  exit 1
end
