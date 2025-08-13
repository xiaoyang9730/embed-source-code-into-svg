# Embed source code into SVG

对 typst 或 mermaid 的源码进行 base64 编码, 并将其嵌入到生成的 SVG 文件.

## Prerequisite

需要安装 typst 和 mmdc (mermaid 的 cli 工具).

##  Usage

使用 `embed.ps1` 生成嵌入代码的同名 SVG 文件.

```powershell
embed.ps1 math.typ
```

使用 `extract.ps1` 从嵌入代码的 SVG 文件中提取代码.

```powershell
extract.ps1 math.svg > extracted_source_code.typ
```

如果 SVG 文件中包含 base64 编码的图片, 可通过 `-imageDir` 参数指定一个文件夹用于保存提取出的图片. 不使用该参数时, 不会对图片进行提取.

```powershell
extract.ps1 math.svg -imageDir .\extracted_images > extracted_source_code.typ
```
