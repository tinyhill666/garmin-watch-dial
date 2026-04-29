using Toybox.Application;
using Toybox.WatchUi;

class App extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new WatchFaceView()];
    }
}
