# 开源表盘参考（GitHub）

调研日期：2026-07-03。浅克隆检查过源码的仓库标 ✓。

## 仓库清单

| 仓库 | 星数 | 看点 |
|---|---|---|
| [warmsound/crystal-face](https://github.com/warmsound/crystal-face) ✓ | 463★ | 百万下载 Crystal 的完整源码，**最值得学** |
| [blotspot/garmin-watchface-protomolecule](https://github.com/blotspot/garmin-watchface-protomolecule) ✓ | 88★ | 环形/轨道数据字段（RingDataField、OrbitDataField） |
| [RyanDam/Infocal](https://github.com/RyanDam/Infocal) | 68★ | 数据密集型布局 |
| [Laverlin/Yet-Another-WatchFace](https://github.com/Laverlin/Yet-Another-WatchFace) | 67★ | 天气/日出日落集成 |
| [ludw/Segment34](https://github.com/ludw/Segment34) ✓ | 59★ | 34 段 LED 数码管风格（自制段码字体） |
| [ahuggel/SwissRailwayClock](https://github.com/ahuggel/SwissRailwayClock) | 30★ | 瑞士铁路钟模拟指针实现 |
| [douglasr/connectiq-logo-analog](https://github.com/douglasr/connectiq-logo-analog) | 28★ | 模拟表盘入门模板 |

## Crystal 的核心技术（对本项目最有价值）

### 1. 自定义位图字体（BMFont 格式：.fnt + .png）

商店高分表盘好看的最大秘密。系统 FONT_NUMBER_* 字形呆板，Crystal 全部用自制字体：

- `titillium-web-bold-68-tall.fnt`（时·粗）+ `titillium-web-light-68-tall.fnt`（分·细）——**同族双字重**构成 thick-thin 时间，这是 Crystal 的视觉签名
- 在 `resources/fonts/fonts.xml` 声明：`<font id="HoursFont" filename="xxx.fnt" antialias="true" filter="0123456789"/>`
  - `filter` 只打包用到的字符，**大幅省内存**（fr955 内存极有限）
- 代码中 `Ui.loadResource(Rez.Fonts.HoursFont)` 加载，正常 `dc.drawText` 使用
- 按分辨率放不同尺寸字体（`resources-round-260x260/` 等设备限定资源目录）
- 制作工具：BMFont（Win）/ [fontbm](https://github.com/vladimirgamalyan/fontbm)（跨平台 CLI），任意 TTF 转 .fnt+.png

### 2. 图标也是字体

`crystal-icons.fnt`：每个图标是一个字形，映射到字符（如 "A"=闹钟）。画图标 = `dc.drawText(x, y, gIconsFont, "A", ...)`。
优点：矢量工具设计、导出位图后边缘平滑、可用 setColor 随意着色、一次 drawText 完成。
Segment34 则用独立 PNG drawable 存每个天气图标（`Rez.Drawables.w_rain` 等），适合多色图标。

### 3. GoalMeter 分段进度仪表（缓冲位图）

两侧弧形分段仪表的实现：把"全满"和"全空"两种状态各画进一张 BufferedBitmap，
每帧只按填充比例 clip 两张缓冲图上屏（最多 2 次 draw）。分段外观 + MIP 上的高性能。

### 4. 架构组织

每个视觉元素一个 Drawable 类（ThickThinTime / DateLine / GoalMeter / MoveBar / DataFields / Indicators），
布局参数放 layout.xml 按分辨率适配，代码只读布局值。多设备支持的标准做法。

## 对 STRIDE（v3）的改进启示

1. **数字塔换自定义字体**：用 fontbm 从开源字体（如 Titillium Web、Oswald、Barlow Condensed）生成
   ~100px 高的窄数字字体，粗（时）细（分）双字重，观感将远超 THAI_HOT
2. **心形/足迹/电池图标改用图标字体或 PNG**，替代原语拼装，边缘更精致
3. 步数进度弧可升级为 Crystal 式分段仪表（更有"表"的感觉）
4. 如果做多设备适配，参照 resources-round-{W}x{H} 目录结构
