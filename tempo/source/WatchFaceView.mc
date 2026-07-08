using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.Weather;
using Toybox.Application;

// «TEMPO» v6：参考用户提供的目标设计
// 双色大字时间（时白分绿，无冒号）+ 顶行心率/电池 + 日期行（日数绿）+ 底部三格（天气/步数/卡路里）
class WatchFaceView extends WatchUi.WatchFace {
    // 调色板（RGB222）
    const COLOR_BLUE = 0x00AAFF;    // 雨天图标、身体电量闪电
    const COLOR_RED = 0xFF0000;     // 心形、电池低电量
    const COLOR_YELLOW = 0xFFFF00;  // 电池中档
    const COLOR_AMBER = 0xFFAA00;   // 太阳图标
    const COLOR_ORANGE = 0xFF5500;  // 火焰图标
    const COLOR_DIM = 0xAAAAAA;     // 秒、电池描边、无值占位
    const COLOR_GREEN = 0x55FF00;   // 电池高电量（语义绿，独立于主题色）

    // 主题色可选调色板（全部 RGB222 合法），索引对应 settings.xml 的 listEntry value
    hidden var _palette = [
        0x55FF00,  // 0 绿（默认）
        0x00FFFF,  // 1 青
        0x00AAFF,  // 2 蓝
        0xFFAA00,  // 3 琥珀
        0xFF5500,  // 4 橙
        0xFF55AA,  // 5 粉
        0xFF5555,  // 6 红
        0xFFFFFF   // 7 白
    ];
    hidden var _accent = 0x55FF00;  // 当前主题色：分钟、日期日数（onLayout/onSettingsChanged 读属性）

    hidden var _weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    hidden var _months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                          "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

    hidden var _fontTime = null;
    hidden var _fontData = null;
    hidden var _fontDate = null;
    hidden var _fontSec = null;
    hidden var _fontIcons = null;

    // 时间行布局（等宽数字，onLayout 一次算好）
    hidden var _digitW2 = 0;   // 「88」宽
    hidden var _hourX = 0;     // 时右缘（RIGHT 锚点）
    hidden var _minX = 0;      // 分左缘（LEFT 锚点）
    hidden var _secX = 0;
    hidden var _secY = 0;
    hidden var _secClipY = 0;
    hidden var _secClipW = 0;
    hidden var _secClipH = 0;

    // 分辨率无关：所有坐标以 260×260 为基准，按 _s 缩放（fr955=1.0，fr965/970≈1.75）
    hidden var _s = 1.0;   // 缩放系数 = 屏宽 / 260
    hidden var _cx = 130;  // 屏幕中心 x

    const TIME_Y = 104;
    const TIME_GAP = 6;

    function initialize() {
        WatchFace.initialize();
    }

    // 260 基准坐标 → 实际像素
    hidden function px(v) {
        return (v * _s + 0.5).toNumber();
    }

    // 线宽缩放，最小 1px
    hidden function pw(v) {
        var w = (v * _s + 0.5).toNumber();
        return w < 1 ? 1 : w;
    }

    function onLayout(dc) {
        _fontTime = WatchUi.loadResource(Rez.Fonts.TimeFont);
        _fontData = WatchUi.loadResource(Rez.Fonts.DataFont);
        _fontDate = WatchUi.loadResource(Rez.Fonts.DateFont);
        _fontSec = WatchUi.loadResource(Rez.Fonts.SecondsFont);
        _fontIcons = WatchUi.loadResource(Rez.Fonts.IconsFont);

        _s = dc.getWidth() / 260.0;
        _cx = dc.getWidth() / 2;
        loadAccent();

        _digitW2 = dc.getTextWidthInPixels("88", _fontTime);
        _secClipW = dc.getTextWidthInPixels("88", _fontSec) + px(2);

        // 时+分+秒作为整体水平居中；字体宽度已随屏放大，坐标偏移用 px() 缩放
        var total = _digitW2 * 2 + px(TIME_GAP) + px(4) + _secClipW;
        var left = _cx - total / 2;
        // 时数字左边距太小时（Chakra 偏宽），用秒右侧的圆界余量把整块右移，避免时贴左缘
        var minLeft = px(18);
        if (left < minLeft) {
            var slack = (_cx + px(125)) - (left + total);
            var need = minLeft - left;
            left += (need < slack ? need : slack);
        }
        if (left < px(8)) {
            left = px(8);
        }
        _hourX = left + _digitW2;
        _minX = _hourX + px(TIME_GAP);
        _secX = _minX + _digitW2 + px(4);

        // 秒底缘与时间数字底缘对齐（几何关系随比例缩放）
        _secY = px(TIME_Y + 25);
        _secClipH = px(28);
        _secClipY = _secY - px(14);
    }

    function onUpdate(dc) {
        var clock = System.getClockTime();
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var actInfo = ActivityMonitor.getInfo();

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        // 每次整屏重绘重读主题色：不依赖 onSettingsChanged 是否触发，
        // 用户改色后最迟下一次刷新（或抬腕唤醒）即生效
        loadAccent();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // ── 顶行：心率组（左）+ 电池图标（右）
        var hr = getHeartRate();
        var hrStr = (hr == null) ? "--" : hr.format("%d");
        // 左右两组关于中轴对称锚定（组中心 98 / 172），垂直共线
        var hrW = dc.getTextWidthInPixels(hrStr, _fontData);
        var hx = px(98) - (px(22) + px(4) + hrW) / 2;
        dc.setColor(COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hx, px(31), _fontIcons, "H", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(hr == null ? COLOR_DIM : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hx + px(26), px(41), _fontData, hrStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        drawBattery(dc, px(156), px(34));

        // ── 时间：时（白，右对齐至中缝）+ 分（绿，左对齐自中缝），无冒号
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_hourX, px(TIME_Y), _fontTime, hour.format("%02d"),
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_minX, px(TIME_Y), _fontTime, clock.min.format("%02d"),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        drawSeconds(dc, clock.sec);

        // ── 日期行：FRI 3 JUL，日数用点缀绿
        var s1 = _weekdays[info.day_of_week - 1] + " ";
        var s2 = info.day.format("%d");
        var s3 = " " + _months[info.month - 1];
        var w1 = dc.getTextWidthInPixels(s1, _fontDate);
        var w2 = dc.getTextWidthInPixels(s2, _fontDate);
        var w3 = dc.getTextWidthInPixels(s3, _fontDate);
        var dx = _cx - (w1 + w2 + w3) / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dx, px(160), _fontDate, s1,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dx + w1, px(160), _fontDate, s2,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dx + w1 + w2, px(160), _fontDate, s3,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── 底部三格：天气 | 步数 | 压力（无分隔线）
        // 整体上移避开圆屏下弧；两侧格中心内收至 68/192（往圆屏更宽处）避免下角被切；
        // 步数格（居中，可达 5 位）单独下移 6px 与两侧错落
        // 格1：天气（图标随天气状况切换 + 温度）
        var tempStr = "--°";
        var wIcon = "O";
        var cond = Weather.getCurrentConditions();
        if (cond != null) {
            if (cond.temperature != null) {
                tempStr = cond.temperature.format("%d") + "°";
            }
            wIcon = weatherIcon(cond.condition);
        }
        dc.setColor(weatherColor(wIcon), Graphics.COLOR_TRANSPARENT);
        dc.drawText(px(68), px(178), _fontIcons, wIcon, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(px(68), px(212), _fontData, tempStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 格2：步数（足迹 + 完整数值；居中格单独下移 6px 与两侧错落）
        var steps = (actInfo != null && actInfo.steps != null) ? actInfo.steps : 0;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, px(184), _fontIcons, "F", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_cx, px(218), _fontData, steps.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 格3：压力值（图标随四档切换：静息/低/中/高）
        var stress = getStress();
        if (stress == null) {
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(px(192), px(178), _fontIcons, "3", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(px(192), px(212), _fontData, "--",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(stressColor(stress), Graphics.COLOR_TRANSPARENT);
            dc.drawText(px(192), px(178), _fontIcons, stressIcon(stress), Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(px(192), px(212), _fontData, stress.format("%d"),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // 从 Application.Properties 读主题色索引，映射到调色板
    hidden function loadAccent() {
        var idx = Application.Properties.getValue("ThemeColor");
        if (idx == null || !(idx instanceof Lang.Number) || idx < 0 || idx >= _palette.size()) {
            idx = 0;
        }
        _accent = _palette[idx];
    }

    // 用户改设置后回调：立即重载主题色并刷新（onUpdate 也会兜底重读）
    function onSettingsChanged() {
        loadAccent();
        WatchUi.requestUpdate();
    }

    // 每秒回调（低功耗模式），只重绘秒区域
    function onPartialUpdate(dc) {
        drawSeconds(dc, System.getClockTime().sec);
    }

    hidden function drawSeconds(dc, sec) {
        dc.setClip(_secX, _secClipY, _secClipW, _secClipH);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_secX, _secY, _fontSec, sec.format("%02d"),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.clearClip();
    }

    // 电池纯图标：外框 30x15 + 触点，填充按比例、绿/黄/红三档（x,y 已缩放，内部尺寸再缩放）
    hidden function drawBattery(dc, x, y) {
        var batt = System.getSystemStats().battery.toNumber();
        dc.setPenWidth(pw(2));
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, y, px(30), px(15), px(4));
        dc.setPenWidth(1);
        dc.fillRectangle(x + px(30), y + px(4), px(3), px(7));
        var fillW = (px(24) * batt + 50) / 100;
        if (batt > 0 && fillW < 1) {
            fillW = 1;
        }
        if (fillW > 0) {
            var battColor = COLOR_GREEN;  // 电池语义绿，固定不随主题色变
            if (batt <= 20) {
                battColor = COLOR_RED;
            } else if (batt <= 50) {
                battColor = COLOR_YELLOW;
            }
            dc.setColor(battColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x + px(3), y + px(3), fillW, px(9));
        }
    }

    // 天气状况 → 图标字符：S晴 P少云 O阴 R雨 W雪 T雷 G雾
    hidden function weatherIcon(c) {
        if (c == null) {
            return "O";
        }
        if (c == Weather.CONDITION_CLEAR || c == Weather.CONDITION_FAIR
            || c == Weather.CONDITION_MOSTLY_CLEAR || c == Weather.CONDITION_WINDY) {
            return "S";
        }
        if (c == Weather.CONDITION_PARTLY_CLOUDY || c == Weather.CONDITION_PARTLY_CLEAR
            || c == Weather.CONDITION_THIN_CLOUDS) {
            return "P";
        }
        if (c == Weather.CONDITION_THUNDERSTORMS || c == Weather.CONDITION_SCATTERED_THUNDERSTORMS
            || c == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS || c == Weather.CONDITION_TROPICAL_STORM
            || c == Weather.CONDITION_HURRICANE || c == Weather.CONDITION_TORNADO
            || c == Weather.CONDITION_SQUALL) {
            return "T";
        }
        if (c == Weather.CONDITION_SNOW || c == Weather.CONDITION_LIGHT_SNOW
            || c == Weather.CONDITION_HEAVY_SNOW || c == Weather.CONDITION_CHANCE_OF_SNOW
            || c == Weather.CONDITION_FLURRIES || c == Weather.CONDITION_WINTRY_MIX
            || c == Weather.CONDITION_RAIN_SNOW || c == Weather.CONDITION_LIGHT_RAIN_SNOW
            || c == Weather.CONDITION_HEAVY_RAIN_SNOW || c == Weather.CONDITION_CHANCE_OF_RAIN_SNOW
            || c == Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW || c == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW
            || c == Weather.CONDITION_ICE || c == Weather.CONDITION_ICE_SNOW
            || c == Weather.CONDITION_SLEET || c == Weather.CONDITION_HAIL
            || c == Weather.CONDITION_FREEZING_RAIN) {
            return "W";
        }
        if (c == Weather.CONDITION_RAIN || c == Weather.CONDITION_LIGHT_RAIN
            || c == Weather.CONDITION_HEAVY_RAIN || c == Weather.CONDITION_DRIZZLE
            || c == Weather.CONDITION_SHOWERS || c == Weather.CONDITION_LIGHT_SHOWERS
            || c == Weather.CONDITION_HEAVY_SHOWERS || c == Weather.CONDITION_SCATTERED_SHOWERS
            || c == Weather.CONDITION_CHANCE_OF_SHOWERS || c == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN
            || c == Weather.CONDITION_UNKNOWN_PRECIPITATION) {
            return "R";
        }
        if (c == Weather.CONDITION_FOG || c == Weather.CONDITION_MIST
            || c == Weather.CONDITION_HAZE || c == Weather.CONDITION_HAZY
            || c == Weather.CONDITION_SMOKE || c == Weather.CONDITION_DUST
            || c == Weather.CONDITION_SAND || c == Weather.CONDITION_SANDSTORM
            || c == Weather.CONDITION_VOLCANIC_ASH) {
            return "G";
        }
        return "O";
    }

    hidden function weatherColor(icon) {
        if (icon.equals("S") || icon.equals("P")) {
            return COLOR_AMBER;
        }
        if (icon.equals("R")) {
            return COLOR_BLUE;
        }
        if (icon.equals("T")) {
            return COLOR_YELLOW;
        }
        if (icon.equals("W")) {
            return Graphics.COLOR_WHITE;
        }
        return COLOR_DIM;
    }

    // 压力四档 → 表情图标字符（Garmin 分级：0-25 静息 / 26-50 低 / 51-75 中 / 76-100 高）
    hidden function stressIcon(s) {
        if (s <= 25) { return "1"; }   // 平静脸
        if (s <= 50) { return "2"; }   // 微笑脸
        if (s <= 75) { return "3"; }   // 平脸
        return "4";                    // 压力脸
    }

    // 压力四档 → 颜色（蓝/绿/琥珀/红，语义色，独立于主题）
    hidden function stressColor(s) {
        if (s <= 25) { return COLOR_BLUE; }
        if (s <= 50) { return COLOR_GREEN; }
        if (s <= 75) { return COLOR_AMBER; }
        return 0xFF5555;
    }

    // 压力值：遍历近期历史找最近的有效采样（压力非每分钟都有值，最新样本常为空）
    hidden function getStress() {
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getStressHistory)) {
            var it = Toybox.SensorHistory.getStressHistory({:period => 8});
            if (it != null) {
                var sample = it.next();
                while (sample != null) {
                    if (sample.data != null) {
                        return sample.data.toNumber();
                    }
                    sample = it.next();
                }
            }
        }
        return null;
    }

    hidden function getHeartRate() {
        var hr = null;
        var ai = Activity.getActivityInfo();
        if (ai != null) {
            hr = ai.currentHeartRate;
        }
        if (hr == null) {
            var hist = ActivityMonitor.getHeartRateHistory(1, true);
            if (hist != null) {
                var sample = hist.next();
                if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    hr = sample.heartRate;
                }
            }
        }
        return hr;
    }

    function onExitSleep() {
        WatchUi.requestUpdate();
    }

    function onEnterSleep() {
        WatchUi.requestUpdate();
    }
}
