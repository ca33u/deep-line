using Toybox.Lang;
using Toybox.WatchUi;

class DeepLineDelegate extends WatchUi.InputDelegate {
    private var _view as DeepLineView;

    function initialize(view as DeepLineView) {
        InputDelegate.initialize();
        _view = view;
    }

    function onKey(event as WatchUi.KeyEvent) as Lang.Boolean {
        var key = event.getKey();
        var state = _view.getGameState();

        if (key == WatchUi.KEY_ENTER) {
            if (state == DiveConstants.STATE_MENU || state == DiveConstants.STATE_RESULT) {
                _view.startGame();
            } else if (state == DiveConstants.STATE_PAUSED) {
                _view.togglePause();
            } else {
                _view.handleAction();
            }
            return true;
        }

        if (key == WatchUi.KEY_MENU) {
            if (_view.isDiveActive() || state == DiveConstants.STATE_PAUSED) {
                _view.togglePause();
                return true;
            }
            return false;
        }

        if (key == WatchUi.KEY_ESC) {
            if (_view.isDiveActive()) {
                _view.togglePause();
            } else {
                _view.exitApp();
            }
            return true;
        }

        return false;
    }

    function onTap(event as WatchUi.ClickEvent) as Lang.Boolean {
        var state = _view.getGameState();
        if (state == DiveConstants.STATE_MENU || state == DiveConstants.STATE_RESULT) {
            _view.startGame();
        } else if (state == DiveConstants.STATE_PAUSED) {
            _view.togglePause();
        } else {
            var coordinates = event.getCoordinates();
            _view.handleTap(coordinates[0], coordinates[1]);
        }
        return true;
    }
}
