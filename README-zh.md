# MdtoPdf - Markdown 转 PDF 工具

一个可移植、可配置的 Markdown 转 PDF 工具，基于 pandoc + XeLaTeX，针对中英文混排内容优化，支持表格自动适配、页眉页脚和专业排版。

## 功能特性

- 中英文双语支持（Noto CJK 字体）
- 多套模板：`default`（简洁）、`report`（专业报告）、`minimal`（极简）
- 表格列宽自动均分（Lua 过滤器）
- 可选预处理：ASCII 图表清理、宽表格字号自动缩小
- 超链接可点击、章节标题彩色高亮
- 页眉显示章节名、页脚显示页码

## 快速开始

```bash
# 基础转换
./md2pdf.sh 我的文档.md

# 报告风格 + 自动目录
./md2pdf.sh 我的文档.md --template report

# 预处理ASCII图表 + 报告风格 + 指定输出文件
./md2pdf.sh 我的文档.md 输出.pdf --preprocess --template report
```

## 安装依赖

### Ubuntu / Debian

```bash
sudo apt install pandoc texlive-xetex fonts-noto-cjk poppler-utils
```

### macOS (Homebrew)

```bash
brew install pandoc
brew install --cask mactex
# 另需下载 Noto CJK 字体: https://github.com/notofonts/noto-cjk
```

### 设置执行权限

```bash
chmod +x md2pdf.sh
```

## 使用方法

```
./md2pdf.sh <输入.md> [输出.pdf] [选项]

选项:
  --toc                  生成目录
  --lang <zh|en>         文档语言（默认: zh）
  --template <名称>      模板: default, minimal, report（默认: default）
  --font-size <大小>     字号: 10pt, 11pt, 12pt（默认: 11pt）
  --paper <规格>         纸张: a4paper, letterpaper（默认: a4paper）
  --margin <大小>        页边距（默认: 2cm）
  --line-stretch <倍数>  行距倍数（默认: 1.3）
  --preprocess           转换前清理ASCII图表
  -h, --help             显示帮助
```

## 目录结构

```
MdtoPdf/
├── md2pdf.sh            # 主转换脚本
├── preprocess.py        # Markdown 预处理器
├── templates/
│   ├── default.yaml     # 简洁风格
│   ├── report.yaml      # 专业报告（带目录+蓝色标题+页眉页脚）
│   └── minimal.yaml     # 极简风格
├── filters/
│   └── table_wrap.lua   # 表格列宽自动均分过滤器
├── README.md            # 英文文档
└── README-zh.md         # 中文文档
```

## 模板说明

### `default` - 简洁风格

适合日常文档。无目录，底部页码，彩色超链接。

### `report` - 专业报告

适合正式报告和调研文档：
- 自动生成目录（三级深度）
- 蓝色章节标题
- 页眉显示当前章节名
- 页脚居中页码，带分隔线

### `minimal` - 极简风格

最少 LaTeX 包，无页眉页脚，适合简短文档或草稿。

## 自定义扩展

### 新增模板

1. 复制 `templates/` 下已有的 `.yaml` 文件
2. 修改字体、颜色、间距、LaTeX 包等
3. 通过 `--template 你的模板名` 使用

### 模板中可调整的关键参数

| 参数 | 说明 | 示例值 |
|------|------|--------|
| `CJKmainfont` | 中文正文字体 | `"Noto Serif CJK SC"` |
| `mainfont` | 西文正文字体 | `"Noto Serif CJK SC"` |
| `monofont` | 代码字体 | `"DejaVu Sans Mono"` |
| `geometry` | 页面布局 | `"a4paper, margin=2cm"` |
| `fontsize` | 基础字号 | `"11pt"` |
| `linestretch` | 行距 | `1.3` |
| `toc` | 是否生成目录 | `true` / `false` |

### 预处理器功能

`preprocess.py` 处理 LaTeX 渲染效果差的 Markdown 内容：

| 功能 | 处理前 | 处理后 |
|------|--------|--------|
| ASCII 方框图 | `┌──┐│内容│└──┘` | 结构化列表项 |
| 单行流程图 | `A → B → C`（代码块内） | LaTeX 数学箭头 |
| 宽表格（>5列） | 正常字号，溢出页面 | 自动缩小字号 |
| 手写目录 | `- [标题](#anchor)` | 删除（pandoc 自动生成） |

## 常见问题

**Q: 中文显示为方框或乱码？**
A: 确认已安装 Noto CJK 字体：`fc-list | grep "Noto.*CJK.*SC"`

**Q: 表格超出页面宽度？**
A: 使用 `--preprocess` 选项自动缩小宽表格字号，或在模板中调整 `geometry` 增大页面/减小边距。

**Q: pandoc 版本不兼容？**
A: 工具兼容 pandoc 2.9+ 和 3.x。Lua 过滤器已做版本适配。

## 更新日志

### v1.0.1 (2026-04-09)

**Bug 修复：**

- **PDF 大纲跳转错位** — `report.yaml` 中以 `sectsty` 替换 `titlesec`。`titlesec` 重写了 section 内部机制，导致 `hyperref` 锚点在章节标题出现于新页开头时落到上一页底部，点击大纲栏标题会跳转到错误页面。`sectsty` 仅修改字体和颜色，不改动 section 结构，锚点位置因此正确。
- **目录对齐** — 引入 `tocloft` 包，为一至三级目录条目添加点引线（dot leaders），页码对齐右边距。
- **目录页码不准** — 重写 `md2pdf.sh` 的 `run_pandoc()` 函数：先由 pandoc 生成 `.tex` 文件，再连续执行 `xelatex` 三遍。单次编译目录页码无法收敛；三遍编译可确保页码稳定。
- **表格单元格溢出** — 添加 `xurl`（URL 自动换行）、`ragged2e`、`microtype` 包；`table_wrap.lua` 将列宽预算从 100% 改为 94%，防止单元格内容超出页边距。
- **代码块超出页面** — 添加 `fvextra` 包并配置 `\fvset{breaklines=true, breakanywhere=true}`，所有代码块长行自动换行；`preprocess.py` 对超长行代码块额外注入 `\small` / `\scriptsize` 字号缩小指令。
- **宽表格字号缩减** — `preprocess.py` 自动在列数超过 5 的表格前插入 `\small`。
- **正文横线** — `table_wrap.lua` 过滤掉 `HorizontalRule` 元素，Markdown 中的 `---` 分隔符不再在 PDF 正文中渲染为可见横线。
- **段落溢出容错** — 添加 `\setlength{\emergencystretch}{3em}` 和 `\setlength{\hfuzz}{3pt}`，减少正文段落中长技术字符串引起的 overfull box 编译错误。

### v1.0.0 (2026-04-08)
- 初始版本
- 三套模板：default、report、minimal
- Lua 过滤器自动均分表格列宽
- Python 预处理器清理 ASCII 图表
- 中英文双语支持
