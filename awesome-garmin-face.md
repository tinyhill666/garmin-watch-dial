# Awesome Garmin Watch Face

精选的 Garmin Connect IQ 表盘开源仓库与开发资源。星数为收集时（2026-07）的近似值，仅供参考。
标 ✓ 的是本项目开发中实际读过源码、确认有参考价值的。

## 精选表盘

| 仓库 | ★ | 看点 |
|---|---|---|
| [warmsound/crystal-face](https://github.com/warmsound/crystal-face) ✓ | 463 | **最值得学**。商店百万下载的 Crystal 完整源码：thick-thin 双字重时间、图标字体、分段进度仪表（GoalMeter 双缓冲位图）、按分辨率分目录的多设备适配。GPLv3 |
| [blotspot/garmin-watchface-protomolecule](https://github.com/blotspot/garmin-watchface-protomolecule) ✓ | 88 | 环形/轨道数据字段（RingDataField、OrbitDataField）架构清晰，每个视觉元素一个 Drawable 类 |
| [RyanDam/Infocal](https://github.com/RyanDam/Infocal) | 68 | 数据密集型布局，现代运动手表风格，可配置数据字段多 |
| [Laverlin/Yet-Another-WatchFace](https://github.com/Laverlin/Yet-Another-WatchFace) | 67 | 天气、日出日落集成的实现参考 |
| [myneur/late](https://github.com/myneur/late) | 66 | 日历 + 天气，主打"别迟到"的信息设计 |
| [ludw/Segment34](https://github.com/ludw/Segment34) ✓ | 59 | 34 段 LED 数码管复古风，自制段码位图字体，整盘一种强烈风格 |
| [fevieira27/MoveToBeActive](https://github.com/fevieira27/MoveToBeActive) | 43 | 仿 Vivomove 指针 + 数据混合风，健康数据展示全面 |
| [ahuggel/SwissRailwayClock](https://github.com/ahuggel/SwissRailwayClock) | 30 | 经典瑞士铁路钟，模拟指针 + 秒针动画的干净实现 |
| [douglasr/connectiq-logo-analog](https://github.com/douglasr/connectiq-logo-analog) | 28 | 模拟表盘入门模板，适合从零学指针表盘 |
| [sunpazed/garmin-nyan-cat](https://github.com/sunpazed/garmin-nyan-cat) | 23 | 动画彩虹猫，学逐帧动画与低功耗刷新取舍 |
| [ChrisWeldon/GarminMinimalVenuWatchface](https://github.com/ChrisWeldon/GarminMinimalVenuWatchface) | 11 | 2020 Connect IQ 挑战赛作品，极简风 Monkey C 参考 |

## 开发工具与库

| 仓库 | ★ | 用途 |
|---|---|---|
| [markw65/prettier-extension-monkeyc](https://github.com/markw65/prettier-extension-monkeyc) | 19 | VSCode 的 Monkey C 格式化 + 优化扩展，实用 |
| [vtrifonov-esfiddle/ConnectIqDataPickers](https://github.com/vtrifonov-esfiddle/ConnectIqDataPickers) | 11 | 数据选择器 barrel（可复用组件库） |
| [hurenkam/WidgetBarrel](https://github.com/hurenkam/WidgetBarrel) | 10 | 表盘用的绘图原语与 widget 库 |
| [vovan-/MonkeyC](https://github.com/vovan-/MonkeyC) | 9 | IntelliJ IDEA 的 Monkey C 语言插件 |
| [gcaufield/MonkeyContainer](https://github.com/gcaufield/MonkeyContainer) | 4 | 无头 Connect IQ 开发的 Docker 镜像，适合 CI |

## 示例与教程

| 仓库 | ★ | 内容 |
|---|---|---|
| [AndrewKhassapov/connect-iq](https://github.com/AndrewKhassapov/connect-iq) | 72 | "Garmin 表盘 101" 手把手教程 |
| [Peterdedecker/connectiq](https://github.com/Peterdedecker/connectiq) | 45 | Connect IQ 官方风格的示例项目合集 |
| [CodyJung/connectiq-apps](https://github.com/CodyJung/connectiq-apps) | 50 | 个人的表盘/widget/data field 合集 |
| [dennybiasiolli/garmin-connect-iq](https://github.com/dennybiasiolli/garmin-connect-iq) | 23 | 多个 Connect IQ 项目集中仓 |

## Awesome 元列表

- [bombsimon/awesome-garmin](https://github.com/bombsimon/awesome-garmin) — ★317，Garmin 生态最全的 awesome 列表（设备、API、第三方工具）
- [peterfication/awesome-garmin-connect-iq](https://github.com/peterfication/awesome-garmin-connect-iq) — 专注 Connect IQ 开发的精选
- [Fun-with-Garmin-Development/awesome-connect-iq](https://github.com/Fun-with-Garmin-Development/awesome-connect-iq) — Connect IQ 应用精选

## 相关 Connect IQ 应用（非表盘，但适合学 Monkey C）

- [alanfischer/hassiq](https://github.com/alanfischer/hassiq) — ★114，Home Assistant 控制界面
- [klimeryk/garmodoro](https://github.com/klimeryk/garmodoro) — ★106，番茄钟

## 官方资源

- [Connect IQ 开发者文档](https://developer.garmin.com/connect-iq/overview/)
- [Connect IQ 商店](https://apps.garmin.com/)（看别人的成品、找灵感）
- [API 参考](https://developer.garmin.com/connect-iq/api-docs/)

---

> 本项目（TEMPO）的开发调研笔记见 [design/OSS-REFERENCES.md](design/OSS-REFERENCES.md)，
> 其中有 Crystal 自定义字体、分段仪表等技术的拆解。
