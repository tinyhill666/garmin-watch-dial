using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

class WatchFaceView extends WatchUi.WatchFace {
    hidden var _timeStr = "00:00";
    hidden var _dateStr = "";

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        // 加载资源
    }

    function onUpdate(dc) {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);

        _timeStr = Lang.format("$1$:$2$", [
            info.hour.format("%02d"),
            info.min.format("%02d")
        ]);

        _dateStr = Lang.format("$1$/$2$", [
            info.month.format("%02d"),
            info.day.format("%02d")
        ]);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        dc.drawText(cx, cy - 30, Graphics.FONT_NUMBER_HOT, _timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + 30, Graphics.FONT_SMALL, _dateStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
