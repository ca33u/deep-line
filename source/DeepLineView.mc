using Toybox.Attention;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;

class DeepLineView extends WatchUi.View {
    const TIMER_PERIOD_MS = 125;
    const REFERENCE_WIDTH = 280;

    const COLOR_DEEP = 0x062B3A;
    const COLOR_MID = 0x0B5262;
    const COLOR_SHALLOW = 0x147A83;
    const COLOR_SURFACE = 0x56C7C3;
    const COLOR_FOAM = 0xD8F3EC;
    const COLOR_LINE = 0xE8D9A9;
    const COLOR_DIVER = 0x111B24;
    const COLOR_SKIN = 0xF3C785;
    const COLOR_ACCENT = 0xFFB347;
    const COLOR_GOOD = 0x7EE081;
    const COLOR_BAD = 0xF25F5C;
    const COLOR_TEXT = 0xF2F4EA;
    const COLOR_DIM = 0x7BA5A8;

    private var _model as DiveModel;
    private var _timer as Timer.Timer;
    private var _timerRunning as Lang.Boolean = false;
    private var _screenWidth as Lang.Number = 280;
    private var _screenHeight as Lang.Number = 280;
    private var _feedbackEvent as Lang.Number = DiveConstants.EVENT_NONE;
    private var _feedbackTicks as Lang.Number = 0;

    function initialize() {
        View.initialize();
        _model = new DiveModel();
        _timer = new Timer.Timer();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _screenWidth = dc.getWidth();
        _screenHeight = dc.getHeight();
    }

    function onShow() as Void {
        if (_model.isDiveActive()) {
            startTimer();
        }
    }

    function onHide() as Void {
        stopTimer();
    }

    function startGame() as Void {
        _feedbackEvent = DiveConstants.EVENT_NONE;
        _feedbackTicks = 0;
        _model.startGame();
        startTimer();
        WatchUi.requestUpdate();
    }

    function handleAction() as Void {
        var event = _model.action();
        handleEvent(event);
        WatchUi.requestUpdate();
    }

    function togglePause() as Void {
        _model.togglePause();
        if (_model.getState() == DiveConstants.STATE_PAUSED) {
            stopTimer();
        } else if (_model.isDiveActive()) {
            startTimer();
        }
        WatchUi.requestUpdate();
    }

    function exitApp() as Void {
        _model.saveBestScore();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function persistBestScore() as Void {
        _model.saveBestScore();
    }

    function getGameState() as Lang.Number { return _model.getState(); }
    function isDiveActive() as Lang.Boolean { return _model.isDiveActive(); }

    private function startTimer() as Void {
        if (_timerRunning) {
            return;
        }
        _timer.start(method(:onTimer), TIMER_PERIOD_MS, true);
        _timerRunning = true;
    }

    private function stopTimer() as Void {
        if (!_timerRunning) {
            return;
        }
        _timer.stop();
        _timerRunning = false;
    }

    function onTimer() as Void {
        if (_feedbackTicks > 0) {
            _feedbackTicks -= 1;
            if (_feedbackTicks == 0) {
                _feedbackEvent = DiveConstants.EVENT_NONE;
            }
        }

        var event = _model.advance();
        handleEvent(event);
        if (event == DiveConstants.EVENT_SURFACED) {
            stopTimer();
        }
        WatchUi.requestUpdate();
    }

    private function handleEvent(event as Lang.Number) as Void {
        if (event == DiveConstants.EVENT_NONE || event == DiveConstants.EVENT_CUE ||
                event == DiveConstants.EVENT_GLIDE_STARTED) {
            return;
        }

        _feedbackEvent = event;
        _feedbackTicks = 6;
        if (event == DiveConstants.EVENT_PERFECT) {
            playVibe([new Attention.VibeProfile(25, 45)]);
        } else if (event == DiveConstants.EVENT_GOOD || event == DiveConstants.EVENT_TURNED) {
            playVibe([new Attention.VibeProfile(18, 35)]);
        } else if (event == DiveConstants.EVENT_MISS || event == DiveConstants.EVENT_WAIT ||
                event == DiveConstants.EVENT_GLIDE_PENALTY) {
            playVibe([new Attention.VibeProfile(55, 90)]);
        } else if (event == DiveConstants.EVENT_SURFACED) {
            playVibe([
                new Attention.VibeProfile(35, 70),
                new Attention.VibeProfile(0, 45),
                new Attention.VibeProfile(35, 110)
            ]);
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        _screenWidth = dc.getWidth();
        _screenHeight = dc.getHeight();
        drawOcean(dc);

        var state = _model.getState();
        if (state == DiveConstants.STATE_MENU) {
            drawMenu(dc);
        } else if (state == DiveConstants.STATE_RESULT) {
            drawResult(dc);
        } else {
            drawDive(dc);
            if (state == DiveConstants.STATE_PAUSED) {
                drawPause(dc);
            }
        }
    }

    private function drawOcean(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        dc.setColor(COLOR_DEEP, COLOR_DEEP);
        dc.clear();
        dc.setColor(COLOR_MID, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height * 58 / 100);
        dc.setColor(COLOR_SHALLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height * 34 / 100);
        dc.setColor(COLOR_SURFACE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height * 16 / 100);
    }

    private function drawMenu(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;

        drawSurfaceAndBuoy(dc, cx, height * 22 / 100);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 38 / 100, Graphics.FONT_MEDIUM, "DEEP LINE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 50 / 100, Graphics.FONT_XTINY, "ONE BREATH · ONE LINE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawDiver(dc, cx, height * 67 / 100, true);
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 87 / 100, Graphics.FONT_SMALL, "TAP / START",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawDive(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var cy = height / 2;
        var state = _model.getState();
        var descending = state == DiveConstants.STATE_DESCENDING ||
            (state == DiveConstants.STATE_PAUSED && _model.getCueKind() == DiveConstants.CUE_EQUALIZE);

        drawWorld(dc, cx, cy);
        drawDiver(dc, cx, cy, descending);
        drawCue(dc, cx, cy);
        drawHud(dc);
        drawFeedback(dc, cx, cy);
    }

    private function drawWorld(dc as Graphics.Dc, cx as Lang.Number, cy as Lang.Number) as Void {
        var height = dc.getHeight();
        var depth = _model.getDepthCm();
        var pixelsPerTenMeters = height * 82 / 100;

        dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(2));
        dc.drawLine(cx, 0, cx, height);

        for (var meters = 0; meters <= 25; meters += 5) {
            var markerDepth = meters * 100;
            var y = cy + ((markerDepth - depth) * pixelsPerTenMeters / 1000);
            if (y < height * 18 / 100 || y > height * 80 / 100) {
                continue;
            }
            dc.setPenWidth(scaled(1));
            dc.drawLine(cx - scaled(12), y, cx + scaled(12), y);
            if (y < cy - scaled(54) || y > cy + scaled(54)) {
                dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx + scaled(18), y, Graphics.FONT_XTINY,
                    meters.format("%d") + "m",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        }

        var surfaceY = cy - (depth * pixelsPerTenMeters / 1000);
        if (surfaceY > -scaled(30) && surfaceY < height + scaled(30)) {
            drawSurfaceAndBuoy(dc, cx, surfaceY);
        }

        var targetY = cy + ((_model.getTargetDepthCm() - depth) * pixelsPerTenMeters / 1000);
        if (targetY > -scaled(20) && targetY < height + scaled(20)) {
            dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(cx - scaled(18), targetY - scaled(3), scaled(36), scaled(6));
        }
    }

    private function drawSurfaceAndBuoy(dc as Graphics.Dc, cx as Lang.Number,
            y as Lang.Number) as Void {
        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(2));
        dc.drawLine(cx - scaled(62), y, cx + scaled(62), y);
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, y - scaled(7), scaled(7));
        dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, y, cx, y + scaled(16));
    }

    private function drawDiver(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number,
            headDown as Lang.Boolean) as Void {
        var direction = headDown ? 1 : -1;
        dc.setColor(COLOR_SKIN, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y + (direction * scaled(9)), scaled(4));
        dc.setColor(COLOR_DIVER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(5));
        dc.drawLine(x, y + (direction * scaled(4)), x, y - (direction * scaled(10)));
        dc.setPenWidth(scaled(3));
        dc.drawLine(x, y, x - scaled(8), y - (direction * scaled(5)));
        dc.drawLine(x, y, x + scaled(8), y - (direction * scaled(5)));
        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(2));
        dc.drawLine(x - scaled(2), y - (direction * scaled(10)),
            x - scaled(8), y - (direction * scaled(20)));
        dc.drawLine(x + scaled(2), y - (direction * scaled(10)),
            x + scaled(8), y - (direction * scaled(20)));
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x - scaled(8), y - (direction * scaled(20)),
            x - scaled(13), y - (direction * scaled(24)));
        dc.drawLine(x + scaled(8), y - (direction * scaled(20)),
            x + scaled(13), y - (direction * scaled(24)));
    }

    private function drawCue(dc as Graphics.Dc, cx as Lang.Number, cy as Lang.Number) as Void {
        var cue = _model.getCueKind();
        if (cue == DiveConstants.CUE_NONE) {
            return;
        }

        if (cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) {
            var movingRadius = scaled(45 - (_model.getCueAge() * 6));
            if (movingRadius < scaled(15)) {
                movingRadius = scaled(15);
            }
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(scaled(2));
            dc.drawCircle(cx, cy, scaled(24));
            dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(cx, cy, movingRadius);
        }

        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        var label = cueLabel(cue);
        dc.drawText(cx, cy + scaled(48), Graphics.FONT_XTINY, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawHud(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var depthMeters = _model.getDepthCm() / 100.0;
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 7 / 100, Graphics.FONT_SMALL,
            depthMeters.format("%.1f") + "m",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var barWidth = width * 48 / 100;
        var barX = (width - barWidth) / 2;
        var barY = height * 91 / 100;
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(barX, barY, barWidth, scaled(7));
        var fillWidth = (barWidth - scaled(2)) * _model.getFlow() / 100;
        dc.setColor(_model.getFlow() > 35 ? COLOR_GOOD : COLOR_BAD,
            Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX + scaled(1), barY + scaled(1), fillWidth, scaled(5));
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, barY - scaled(13), Graphics.FONT_XTINY, "FLOW",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawFeedback(dc as Graphics.Dc, cx as Lang.Number,
            cy as Lang.Number) as Void {
        if (_feedbackEvent == DiveConstants.EVENT_NONE) {
            return;
        }
        var label = feedbackLabel(_feedbackEvent);
        var color = COLOR_TEXT;
        if (_feedbackEvent == DiveConstants.EVENT_PERFECT) {
            color = COLOR_GOOD;
        } else if (_feedbackEvent == DiveConstants.EVENT_MISS ||
                _feedbackEvent == DiveConstants.EVENT_WAIT ||
                _feedbackEvent == DiveConstants.EVENT_GLIDE_PENALTY) {
            color = COLOR_BAD;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - scaled(51), Graphics.FONT_SMALL, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawPause(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        dc.setColor(COLOR_DEEP, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(width * 16 / 100, height * 34 / 100,
            width * 68 / 100, height * 32 / 100);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 44 / 100, Graphics.FONT_MEDIUM, "PAUSED",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 57 / 100, Graphics.FONT_XTINY, "TAP / START TO RESUME",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawResult(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        drawSurfaceAndBuoy(dc, cx, height * 18 / 100);
        dc.setColor(COLOR_GOOD, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 30 / 100, Graphics.FONT_SMALL, "SURFACED · OK",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 44 / 100, Graphics.FONT_MEDIUM,
            (_model.getMaxDepthCm() / 100.0).format("%.1f") + "m",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, height * 57 / 100, Graphics.FONT_SMALL,
            "SCORE " + _model.getScore().format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 67 / 100, Graphics.FONT_XTINY,
            "PERFECT " + _model.getPerfectCount().format("%d") +
            "  MISS " + _model.getMissCount().format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, height * 75 / 100, Graphics.FONT_XTINY,
            "BEST " + _model.getBestScore().format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 88 / 100, Graphics.FONT_SMALL, "RETRY",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function cueLabel(cue as Lang.Number) as Lang.String {
        if (cue == DiveConstants.CUE_EQUALIZE) { return "EQUALIZE"; }
        if (cue == DiveConstants.CUE_TAG) { return "TAKE THE TAG"; }
        if (cue == DiveConstants.CUE_STROKE) { return "KICK"; }
        if (cue == DiveConstants.CUE_GLIDE) { return "GLIDE · STAY CALM"; }
        return "";
    }

    private function feedbackLabel(event as Lang.Number) as Lang.String {
        if (event == DiveConstants.EVENT_PERFECT) { return "PERFECT"; }
        if (event == DiveConstants.EVENT_GOOD) { return "GOOD"; }
        if (event == DiveConstants.EVENT_MISS) { return "MISSED"; }
        if (event == DiveConstants.EVENT_WAIT) { return "WAIT"; }
        if (event == DiveConstants.EVENT_TURN_READY) { return "TAG"; }
        if (event == DiveConstants.EVENT_TURNED) { return "TURN"; }
        if (event == DiveConstants.EVENT_GLIDE_PENALTY) { return "STAY CALM"; }
        return "";
    }

    private function scaled(value as Lang.Number) as Lang.Number {
        return value * _screenWidth / REFERENCE_WIDTH;
    }

    private function playVibe(profiles as Lang.Array<Attention.VibeProfile>) as Void {
        if (!(Attention has :vibrate)) {
            return;
        }
        if (System.getDeviceSettings().vibrateOn != true) {
            return;
        }
        Attention.vibrate(profiles);
    }
}
