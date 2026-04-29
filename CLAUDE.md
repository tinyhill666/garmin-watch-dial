# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指引。

## 项目概述

Garmin 表盘项目，使用 **Connect IQ SDK** + **Monkey C** 语言开发，当前适配设备为 **fr955**。

## 进度记录（2026-04-30）

**已完成：**
- 安装 Connect IQ SDK Manager（brew cask）+ SDK 9.1.0 + fr955 设备包
- 安装 OpenJDK（brew formula，`monkeyc` 依赖 Java）
- 生成开发者签名密钥（`~/Library/Application Support/Garmin/ConnectIQ/Keys/developer_key.der`）
- 创建最小表盘项目，包含 `manifest.xml`、`monkey.jungle`、`App.mc`、`WatchFaceView.mc`
- **编译成功**（`monkeyc -o bin/fr955.prg ...` → `BUILD SUCCESSFUL`）

**待解决：**
- 模拟器运行后窗口显示空白，需要排查（可能是设备选择问题或窗口未正确加载）

## TODO

- [ ] 排查模拟器白屏问题，确认表盘能在模拟器中正常显示
- [ ] 表盘功能扩展：电量、步数、心率等数据展示
- [ ] 布局与样式优化（字体、颜色、对齐等）

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
