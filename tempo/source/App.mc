using Toybox.Application;
using Toybox.WatchUi;

class App extends Application.AppBase {
    hidden var _view = null;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        _view = new WatchFaceView();
        return [_view];
    }

    // 用户在 Garmin Connect 手机 App 改设置后回调，转发给表盘 View 重载主题色
    function onSettingsChanged() {
        if (_view != null) {
            _view.onSettingsChanged();
        }
    }
}
