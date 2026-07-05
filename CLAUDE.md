# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指引。

## 项目概述

Garmin 表盘项目，使用 **Connect IQ SDK** + **Monkey C** 语言开发，当前适配设备为 **fr955**。

## 进度记录（2026-07-02）

**已完成：**
- 安装 Connect IQ SDK Manager（brew cask）+ SDK 9.1.0 + fr955 设备包
- 安装 OpenJDK（brew formula，`monkeyc` 依赖 Java）
- 生成开发者签名密钥（`~/Library/Application Support/Garmin/ConnectIQ/Keys/developer_key.der`）
- 创建最小表盘项目，包含 `manifest.xml`、`monkey.jungle`、`App.mc`、`WatchFaceView.mc`
- 编译成功 + **模拟器运行验证通过**：`onUpdate()` 正常回调，屏幕 260x260（fr955）
- 白屏问题结论：模拟器刚启动、尚未用 `monkeydo` 加载程序时窗口为空属正常现象；先 `connectiq` 等模拟器就绪，再 `monkeydo` 即可
- 新增 `./run.sh`：一键构建 + 启动模拟器 + 加载表盘

## TODO

- [x] 表盘功能扩展：时分秒、心率、电量、步数、周几、日期（2026-07-02 完成 v1）
- [x] 设计迭代：v2 AXIS → v3 STRIDE → v4 TEMPO →（用户提供目标参考图）→ v6（2026-07-04 现行版）
- [x] 自定义位图字体管线：`tools/gen_bmfont.py`（TTF→BMFont .fnt+.png + 图标字形绘制）
- [ ] v6 微调（等用户反馈）；可选：真机测试、AM/PM 指示

## 当前版本 v6（按用户目标参考图实现）

- 布局：顶行心率组+电池图标 / 双色大字时间（时白、分绿 #55FF00，无冒号，Barlow SemiCondensed Bold 92px）/
  秒（专用 20px 字体）贴分右缘底对齐 / 日期行（日数绿）/ 底部三格 天气|步数|卡路里（细线分隔）
- 图标：Material Symbols Rounded 可变字体（Apache 2.0）渲染字形，FILL=1 实心、按轴序 set_variation_by_axes([1,0,24,400])；
  映射 H=favorite F=footprint S=sunny C=local_fire_department
- 秒越界教训：92px 数字 + 20px 秒的时间行总宽 ≈232 起步；布局改动后务必核对
  「时+分+秒右缘 ≤ 247」及各行元素在对应 y 高度的圆边界内（half = √(130²-dy²)）
- 电池：纯图标无数字，填充比例 + 绿/黄/红三档（>50/20-50/≤20）
- 天气图标随 `Weather.CONDITION_*` 切换（7 档：晴/少云/阴/雨/雪/雷/雾，见 weatherIcon()），颜色分档
- 第三格 = 压力值（SensorHistory.getStressHistory，橙色 speed 仪表图标；manifest 需 SensorHistory 权限）；
  图标字体中备有 B=bolt（身体电量）、C=flame（卡路里）字形可随时切换
  **CIQ 无"昨晚睡眠时长"API**（已验证 SDK 9.1：SensorHistory 无 sleep 历史，UserProfile.sleepTime 只是设定的就寝时间）
- 大字体 cell 内字形偏下 ~5px（yoffset 导致），秒对齐等布局微调时先查 .fnt 的 yoffset/height

## 设计资产与工作流

- `design/CAPABILITIES.md`：设备能力简报（给设计用）；`design/design-v4.md`：当前实现的规格
- `design/refs/`：高分表盘参考图（Crystal 实机截图等）；`design/OSS-REFERENCES.md`：开源表盘调研笔记
- 字体：`design/fonts-src/`（TTF 源，**已 gitignore，不入库**）→ `python3 tools/gen_bmfont.py` → `resources/fonts/`（生成产物，入库）
  - 生成器注意：数字做了强制等宽；图集内绘制位置用原始 bbox、等宽只调 char 记录的 xoffset（否则字形串位）
  - `design/fonts-src/` 缺失时重新下载（Material Symbols 那个可变字体约 14MB，故不入库）：
    ```bash
    mkdir -p design/fonts-src && cd design/fonts-src
    curl -sL -o BarlowCondensed-Bold.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/barlowcondensed/BarlowCondensed-Bold.ttf"
    curl -sL -o BarlowCondensed-Light.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/barlowcondensed/BarlowCondensed-Light.ttf"
    curl -sL -o BarlowCondensed-SemiBold.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/barlowcondensed/BarlowCondensed-SemiBold.ttf"
    curl -sL -o BarlowSemiCondensed-Bold.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/barlowsemicondensed/BarlowSemiCondensed-Bold.ttf"
    curl -sL -o TitilliumWeb-Bold.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/titilliumweb/TitilliumWeb-Bold.ttf"
    curl -sL -o TitilliumWeb-Light.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/titilliumweb/TitilliumWeb-Light.ttf"
    curl -sL -o TitilliumWeb-SemiBold.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/titilliumweb/TitilliumWeb-SemiBold.ttf"
    curl -sL -o MaterialSymbolsRounded.ttf "https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
    ```
    全部 SIL OFL / Apache 2.0 开源
- **模拟器截图自检**：需在非沙盒下执行；窗口可能不在当前 Space，用
  `swift -e 'CGWindowListCopyWindowInfo...'` 找 "CIQ Simulator" 窗口 ID，再 `screencapture -x -l<ID>`（按窗口截图跨 Space 有效）

## 环境准备

SDK 已通过 `brew install --cask connectiq-sdk-manager` 安装，路径：
```
~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b
```
开发者密钥：`~/Library/Application Support/Garmin/ConnectIQ/Keys/developer_key.der`

## 常用命令

```bash
export SDK_HOME="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b"
export JAVA_HOME="/opt/homebrew/opt/openjdk"
export PATH="$JAVA_HOME/bin:$SDK_HOME/bin:$PATH"

# 构建
monkeyc -o bin/fr955.prg -d fr955 -f monkey.jungle -y "$HOME/Library/Application Support/Garmin/ConnectIQ/Keys/developer_key.der"

# 启动模拟器 + 运行
connectiq
monkeydo bin/fr955.prg fr955
```

## manifest.xml 要求

- `id` 必须是 **32 位十六进制字符串**（用 `uuidgen | tr -d '-'` 生成）
- `name` 必须是字符串资源引用（如 `@Strings.AppName`），不能是字面量
- 不支持 `minHeight` 属性（SDK 9.1.0 验证报错）
- 当前 app id：`75aa1bcea6f64afd96d1b4bed850f4fb`

## Monkey C 核心要点

- 入口：继承 `AppBase`（通常在 `source/App.mc`），在 `getInitialView()` 中返回表盘 View
- 表盘：继承 `WatchFace`（继承自 `Ui.View`），在 `onUpdate(dc)` 中绘制
- `dc`（设备上下文）是绘图 API：`dc.setColor()`、`dc.drawText()`、`dc.fillRectangle()` 等
- 内存极有限，**禁止在 `onUpdate()` 中分配对象**，所有变量在类成员中预分配复用
- `onUpdate()` 默认每分钟调用一次；实现 `onPartialUpdate()` 可支持每秒刷新
- API 5.2 不支持类型注解（`as String`、`as Dc` 等），变量声明不写类型

## 开发约定

- 用户可配置的设置项用 `Application.Properties`（定义在 `properties.xml`）
- 刷新显示用 `Ui.requestUpdate()`，不要用忙等待循环
- 日志用 `Toybox.System.println()`
- 位图资源放在 `resources/drawables/`，通过 `Rez.Drawables` 引用
- 字体资源须在资源 XML 中声明，通过 `Rez.Fonts` 引用
