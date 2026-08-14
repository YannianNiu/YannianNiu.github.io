# yannianniu.github.io

个人主页。单页结构，所有内容在 `index.html` 一个文件里（HTML + 内嵌 CSS），
没有构建步骤，推上去就是线上看到的样子。

线上地址：<https://yannianniu.github.io>

## 目录

```
index.html    整个网站：内容、样式、脚本都在这里
images/       图片（profile.JPG 是首页头像）
files/        PDF：简历放 cv.pdf，论文也放这里
.nojekyll     告诉 GitHub Pages 别拿 Jekyll 处理，直接按原样发布
.tools/       推送前的检查脚本
```

## 怎么改

1. 用编辑器打开 `index.html`，找到对应板块的注释块（`<!-- ===== News ===== -->` 这种），
   照着已有的条目复制一份改。每个板块开头的注释里写了加条目的规矩。
2. **本地预览**：双击 `index.html`，浏览器里直接看效果。改完存盘刷新即可，不需要起服务。
3. 满意了再推送（见下）。

搜 `【` 能找到所有还没填的占位符。

## 推送

```bash
.tools/publish.sh "这次改了什么"
```

脚本会先跑检查（标签有没有闭合、导航锚点对不对得上、引用的图片和 PDF 在不在），
通过了才提交推送，然后盯着线上直到新版本真的上线。

只想检查不推送：

```bash
ruby .tools/check.rb
```

浏览器里看不到更新的话，硬刷新一下（Cmd+Shift+R）—— GitHub Pages 的 CDN 缓存 10 分钟。

---

改版前用的是 [academicpages](https://github.com/academicpages/academicpages.github.io)（Jekyll 主题），
改成单页时历史一并重置了。老版本的完整历史打包在
`~/Desktop/YannianNiu.github.io-完整历史备份-20260813.bundle`（不在仓库里），
要翻回去的话 `git clone 那个文件`。
