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

- 布局：顶行心率组+电池图标 / 双色大字时间（时白、分绿 #55FF00，无冒号，Chakra Petch Bold 76px）/
  秒（专用 28px 字体）贴分右缘底对齐 / 日期行（日数绿）/ 底部三格 天气|步数|压力
- 字体：Chakra Petch（几何切角，直线为主，SIL OFL）—— 比圆体（Barlow/Titillium）在 MIP 屏锯齿少很多；
  Chakra 偏宽，时间字号取 76（不是 92）才能保证「时+分+秒」整体不越圆界（曾经的教训见下）
- 图标：Material Symbols Rounded 可变字体（Apache 2.0）渲染字形，FILL=1 实心、按轴序 set_variation_by_axes([1,0,24,400])；
  映射 H=favorite F=footprint S=sunny C=local_fire_department
- 秒越界教训：92px 数字 + 20px 秒的时间行总宽 ≈232 起步；布局改动后务必核对
  「时+分+秒右缘 ≤ 247」及各行元素在对应 y 高度的圆边界内（half = √(130²-dy²)）
- 电池：纯图标无数字，填充比例 + 绿/黄/红三档（>50/20-50/≤20）
- 主题色可换：`resources/settings/{settings,properties}.xml` 定义 ThemeColor 属性（8 色调色板见 `_palette`），
  用户在 Garmin Connect 手机 App 里选色；分钟数字 + 日期日数跟随主题，电池/心率/天气/压力保持各自语义色
  - **换色靠 onUpdate 每帧重读属性**（不只依赖 onSettingsChanged 回调，后者在模拟器可能不触发）
  - 模拟器测设置的坑：① 改 properties.xml 默认值**不生效**，因为持久化文件覆盖默认值；
    ② 持久化文件 `…/T/com.garmin.connectiq/GARMIN/APPS/SETTINGS/FR955.SET`，**最后一个字节 = ThemeColor 值**；
    改设置要么用模拟器的 App Settings 编辑器，要么删掉 .SET 让它回退默认，要么直接改最后一字节
- 天气图标随 `Weather.CONDITION_*` 切换（7 档：晴/少云/阴/雨/雪/雷/雾，见 weatherIcon()），颜色分档
- 压力图标随值分四档（0-25/26-50/51-75/76-100 → 平静/微笑/平/皱眉脸，蓝/绿/琥珀/红，见 stressIcon/stressColor）
- 第三格 = 压力值（SensorHistory.getStressHistory，橙色 speed 仪表图标；manifest 需 SensorHistory 权限）；
  图标字体中备有 B=bolt（身体电量）、C=flame（卡路里）字形可随时切换
  **CIQ 无"昨晚睡眠时长"API**（已验证 SDK 9.1：SensorHistory 无 sleep 历史，UserProfile.sleepTime 只是设定的就寝时间）
- 大字体 cell 内字形偏下 ~5px（yoffset 导致），秒对齐等布局微调时先查 .fnt 的 yoffset/height

## 设计资产与工作流

- `design/CAPABILITIES.md`：设备能力简报（给设计用）；`design/design-v4.md`：当前实现的规格
- `design/refs/`：高分表盘参考图（Crystal 实机截图等）；`design/OSS-REFERENCES.md`：开源表盘调研笔记
## 多分辨率适配（fr955 260 / fr965·fr970 454）

- **坐标分辨率无关**：WatchFaceView 所有坐标以 260 为基准，onLayout 里算 `_s = 宽/260`、`_cx = 宽/2`，
  用 `px(v)`/`pw(v)` 缩放；加新元素时坐标一律写 260 基准值再包 `px()`
- **字体按分辨率分目录**：`resources-round-260x260/fonts/` 与 `resources-round-454x454/fonts/` 各一套（角色命名
  time/data/sec/icons，fonts.xml 内容相同），CIQ 按设备自动选用；**base `resources/` 下不能有 fonts**（否则 454 设备冲突）
- `tools/gen_bmfont.py` 的 `gen_set(out_dir, s)` 按系数生成整套；`__main__` 对 260(1.0) 和 454(1.746) 各调一次
- manifest 的 products 列了 fr955/fr965/fr970；加设备时若分辨率已有对应字体目录则无需再生成
- 切设备测试：monkeydo 不会切换运行中的模拟器设备，需 `pkill simulator` 后 `connectiq` 重启再 `monkeydo <prg> <device>`

## 字体与设计资产

- 字体：`design/fonts-src/`（TTF 源，**已 gitignore，不入库**）→ `python3 tools/gen_bmfont.py` → `resources-round-*/fonts/`（生成产物，入库）
  - 生成器注意：数字做了强制等宽；图集内绘制位置用原始 bbox、等宽只调 char 记录的 xoffset（否则字形串位）
  - `design/fonts-src/` 缺失时重新下载 `gen_bmfont.py` 当前用到的三个（Material Symbols 约 14MB，故不入库）：
    ```bash
    mkdir -p design/fonts-src && cd design/fonts-src
    curl -sL -o ChakraPetch-Bold.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/chakrapetch/ChakraPetch-Bold.ttf"
    curl -sL -o ChakraPetch-SemiBold.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/chakrapetch/ChakraPetch-SemiBold.ttf"
    curl -sL -o MaterialSymbolsRounded.ttf "https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
    ```
    全部 SIL OFL / Apache 2.0 开源。（早期用过 Barlow/Titillium/Rajdhani/DSEG，因锯齿或过宽被 Chakra 取代）
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
