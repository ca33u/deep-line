using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;

class DeepLineApp extends Application.AppBase {
    private var _view as DeepLineView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
    }

    function onStop(state as Lang.Dictionary?) as Void {
        var view = _view;
        if (view != null) {
            view.persistBestScore();
        }
    }

    function getInitialView() {
        var view = new DeepLineView();
        _view = view;
        return [view, new DeepLineDelegate(view)];
    }
}

function getApp() as DeepLineApp {
    return Application.getApp() as DeepLineApp;
}
