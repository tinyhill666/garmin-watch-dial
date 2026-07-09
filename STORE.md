# 发布到 Connect IQ 商店

两个 app（TEMPO / PULSE）各自独立提交。流程与素材清单如下。

## 一次性准备

1. 用 Garmin 账号登录 [developer.garmin.com](https://developer.garmin.com)，同意 Connect IQ 开发者协议。
2. 开发者后台在 [apps.garmin.com](https://apps.garmin.com)（登录后进 Dashboard）。
3. 保管好 `~/Library/Application Support/Garmin/ConnectIQ/Keys/developer_key.der`
   —— 发布及**以后所有更新**都必须用同一把密钥 + 同一 app id，丢了无法更新已发布 app。

## 打包 .iq

```bash
./package.sh          # 两个 app 都打
./package.sh pulse    # 只打一个
```

产物在 `pulse/bin/pulse.iq`、`tempo/bin/tempo.iq`（含 manifest 里所有设备，release 签名）。
底层命令：`monkeyc -e -r -w -o <app>.iq -f <app>/monkey.jungle -y <key>`（`-e` 打包 / `-r` release）。

## 提交步骤

Dashboard → Upload an App → 传对应 `.iq` → 填元数据（见下）→ 提交审核。
Garmin 人工审核通常几天，需过 [App Review Guidelines](https://developer.garmin.com/connect-iq/app-review-guidelines/)。

## 待办 / 注意

- [ ] **启动图标偏小**：现为 40×40，fr965/970 需 65×65（否则被放大变糊）。换一张 ≥65×65 的
      `resources/launcher_icon.png`（两个 app 各一份），或按分辨率放 `resources-round-454x454/drawables/`。
- 类型选 **Watch Face**。
- 权限：manifest 声明了 `SensorHistory`（压力值用）——商店会列出，用途见下。
- 编译期的 "Cannot determine container access" 是数组访问的类型检查警告，无害。

## 元数据草稿

### PULSE（棱角版，Chakra Petch）
- **名称**：PULSE
- **一句话**：Angular data watch face — time, HR, battery, steps, weather & stress at a glance.
- **描述**：A clean, data-rich watch face with a bold two-tone time, icon-based heart rate / battery /
  weather / stress that change with their values, a step-goal progress arc, and 8 selectable theme colors
  (set in Garmin Connect). Geometric Chakra Petch type for crisp readability on MIP displays.
  棱角几何字体、双色大字时间、随数值变化的图标、步数目标进度弧、8 种可换主题色。
- **截图**：`docs/preview-pulse.png`（+ 建议再出 fr955 / fr970 各一张，含非零步数以显示进度弧）

### TEMPO（圆体版，Barlow + Titillium）
- **名称**：TEMPO
- **一句话**：Rounded data watch face — same layout, softer type.
- **描述**：同 PULSE 的功能，改用圆润的 Barlow SemiCondensed + Titillium Web 字体，气质更柔和。
- **截图**：`docs/preview-tempo.png`

### 共用
- **权限说明**：Uses activity/stress history (SensorHistory) to show your current stress level.
- **语言**：English（可加 简体中文）
- **定价**：Free

## 更新已发布 app

改代码 → `./package.sh <app>` → 在该 app 的商店条目下 Upload 新版本（同密钥、同 app id）。
