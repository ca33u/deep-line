using Toybox.Attention;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;

class DeepLineView extends WatchUi.View {
    const TIMER_PERIOD_MS = 125;
    const REFERENCE_WIDTH = 280;

    const COLOR_ABYSS = 0x041823;
    const COLOR_DEEP = 0x062B3A;
    const COLOR_MID = 0x0A4A5B;
    const COLOR_SHALLOW = 0x0D7180;
    const COLOR_SURFACE = 0x18A6A6;
    const COLOR_FOAM = 0xE7F2E9;
    const COLOR_LINE = 0xF0D69C;
    const COLOR_ACCENT = 0xFF6B3D;
    const COLOR_GOOD = 0x8FE388;
    const COLOR_BAD = 0xFF6464;
    const COLOR_TEXT = 0xF6F0DC;
    const COLOR_DIM = 0x6CA0A4;

    private var _model as DiveModel;
    private var _timer as Timer.Timer;
    private var _timerRunning as Lang.Boolean = false;
    private var _screenWidth as Lang.Number = 280;
    private var _screenHeight as Lang.Number = 280;
    private var _feedbackEvent as Lang.Number = DiveConstants.EVENT_NONE;
    private var _feedbackTicks as Lang.Number = 0;
    private var _diversMip as Lang.Array<WatchUi.BitmapResource>;
    private var _diversAmoled as Lang.Array<WatchUi.BitmapResource>;
    private var _buoyMip as WatchUi.BitmapResource;
    private var _buoyAmoled as WatchUi.BitmapResource;
    private var _tagMip as WatchUi.BitmapResource;
    private var _tagAmoled as WatchUi.BitmapResource;

    function initialize() {
        View.initialize();
        _model = new DiveModel();
        _timer = new Timer.Timer();
        _diversMip = [
            WatchUi.loadResource($.Rez.Drawables.DiverDescendMip) as WatchUi.BitmapResource,
            WatchUi.loadResource($.Rez.Drawables.DiverAscendMip) as WatchUi.BitmapResource,
            WatchUi.loadResource($.Rez.Drawables.DiverEqualizeMip) as WatchUi.BitmapResource,
            WatchUi.loadResource($.Rez.Drawables.DiverTurnMip) as WatchUi.BitmapResource
        ];
        _diversAmoled = [
            WatchUi.loadResource($.Rez.Drawables.DiverDescendAmoled) as WatchUi.BitmapResource,
            WatchUi.loadResource($.Rez.Drawables.DiverAscendAmoled) as WatchUi.BitmapResource,
            WatchUi.loadResource($.Rez.Drawables.DiverEqualizeAmoled) as WatchUi.BitmapResource,
            WatchUi.loadResource($.Rez.Drawables.DiverTurnAmoled) as WatchUi.BitmapResource
        ];
        _buoyMip = WatchUi.loadResource($.Rez.Drawables.BuoyMip) as WatchUi.BitmapResource;
        _buoyAmoled = WatchUi.loadResource($.Rez.Drawables.BuoyAmoled) as WatchUi.BitmapResource;
        _tagMip = WatchUi.loadResource($.Rez.Drawables.TagMip) as WatchUi.BitmapResource;
        _tagAmoled = WatchUi.loadResource($.Rez.Drawables.TagAmoled) as WatchUi.BitmapResource;
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
        dc.setColor(COLOR_ABYSS, COLOR_ABYSS);
        dc.clear();

        dc.setColor(COLOR_DEEP, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height * 78 / 100);
        dc.setColor(COLOR_MID, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height * 55 / 100);
        dc.setColor(COLOR_SHALLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height * 32 / 100);
        dc.setColor(COLOR_SURFACE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height * 13 / 100);

        // Broad rays and drifting particles give depth without expensive textures.
        dc.setColor(COLOR_SHALLOW, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(1));
        dc.drawLine(width * 18 / 100, 0, width * 34 / 100, height * 48 / 100);
        dc.drawLine(width * 80 / 100, 0, width * 64 / 100, height * 42 / 100);
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(width * 18 / 100, height * 38 / 100, scaled(1));
        dc.fillCircle(width * 78 / 100, height * 47 / 100, scaled(1));
        dc.fillCircle(width * 28 / 100, height * 67 / 100, scaled(1));
        dc.fillCircle(width * 83 / 100, height * 73 / 100, scaled(1));
        dc.fillCircle(width * 12 / 100, height * 84 / 100, scaled(1));

        dc.setColor(COLOR_SURFACE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, height * 32 / 100, width, height * 32 / 100);
        dc.setColor(COLOR_MID, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, height * 55 / 100, width, height * 55 / 100);
    }

    private function drawMenu(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;

        drawSurfaceAndBuoy(dc, cx, height * 22 / 100);
        dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(1));
        dc.drawLine(cx, height * 23 / 100, cx, height * 77 / 100);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 36 / 100, Graphics.FONT_MEDIUM, "DEEP LINE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 47 / 100, Graphics.FONT_XTINY, "ONE BREATH · ONE LINE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawDiver(dc, cx, height * 66 / 100, true);
        drawActionPill(dc, cx, height * 88 / 100, "TAP / START", COLOR_ACCENT);
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
        var diverX = state == DiveConstants.STATE_TURNING ? cx - scaled(19) : cx;
        drawDiver(dc, diverX, cy, descending);
        drawCue(dc, cx, cy);
        drawHud(dc);
        drawFeedback(dc, cx, cy);
    }

    private function drawWorld(dc as Graphics.Dc, cx as Lang.Number, cy as Lang.Number) as Void {
        var height = dc.getHeight();
        var depth = _model.getDepthCm();
        var pixelsPerTenMeters = height * 82 / 100;

        dc.setColor(COLOR_ABYSS, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(4));
        dc.drawLine(cx + scaled(1), 0, cx + scaled(1), height);
        dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(2));
        dc.drawLine(cx, 0, cx, height);

        for (var meters = 0; meters <= 25; meters += 5) {
            var markerDepth = meters * 100;
            var y = cy + ((markerDepth - depth) * pixelsPerTenMeters / 1000);
            if (y < height * 18 / 100 || y > height * 80 / 100) {
                continue;
            }
            dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(scaled(1));
            dc.drawLine(cx - scaled(11), y, cx + scaled(11), y);
            dc.fillCircle(cx, y, scaled(2));
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
        if (targetY > -scaled(40) && targetY < height + scaled(40)) {
            drawTag(dc, cx, targetY);
        }
    }

    private function drawSurfaceAndBuoy(dc as Graphics.Dc, cx as Lang.Number,
            y as Lang.Number) as Void {
        var width = dc.getWidth();
        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(1));
        var waveWidth = width * 52 / 100;
        var waveLeft = cx - (waveWidth / 2);
        var segment = waveWidth / 6;
        for (var index = 0; index < 6; index += 1) {
            var waveY = y + ((index % 2 == 0) ? -scaled(1) : scaled(1));
            var nextY = y + ((index % 2 == 0) ? scaled(1) : -scaled(1));
            dc.drawLine(waveLeft + (index * segment), waveY,
                waveLeft + ((index + 1) * segment), nextY);
        }

        var buoy = isAmoled() ? _buoyAmoled : _buoyMip;
        dc.drawBitmap(cx - (buoy.getWidth() / 2),
            y - (buoy.getHeight() * 64 / 100), buoy);
        dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(1));
        dc.drawLine(cx, y, cx, y + scaled(16));
    }

    private function drawDiver(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number,
            headDown as Lang.Boolean) as Void {
        var pose = headDown ? 0 : 1;
        if (_model.getCueKind() == DiveConstants.CUE_EQUALIZE) {
            pose = 2;
        }
        if (_model.getState() == DiveConstants.STATE_TURNING ||
                _model.getCueKind() == DiveConstants.CUE_TAG) {
            pose = 3;
        }
        var divers = isAmoled() ? _diversAmoled : _diversMip;
        var diver = divers[pose];
        dc.drawBitmap(x - (diver.getWidth() / 2), y - (diver.getHeight() / 2), diver);
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
            dc.setPenWidth(scaled(1));
            dc.drawCircle(cx, cy, scaled(22));
            dc.drawCircle(cx, cy, scaled(27));
            dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(scaled(2));
            dc.drawCircle(cx, cy, movingRadius);
        }

        var label = cueLabel(cue);
        drawActionPill(dc, cx, cy + scaled(50), label, COLOR_TEXT);
    }

    private function drawHud(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var depthMeters = _model.getDepthCm() / 100.0;

        var badgeWidth = scaled(62);
        var badgeHeight = scaled(22);
        var badgeY = height * 7 / 100;
        drawPillBackground(dc, width / 2, badgeY, badgeWidth, badgeHeight, COLOR_DEEP);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, badgeY, Graphics.FONT_SMALL,
            depthMeters.format("%.1f") + "m",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var barWidth = width * 48 / 100;
        var barX = (width - barWidth) / 2;
        var barY = height * 91 / 100;
        var barHeight = scaled(7);
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, barWidth, barHeight);
        dc.fillCircle(barX, barY + (barHeight / 2), barHeight / 2);
        dc.fillCircle(barX + barWidth, barY + (barHeight / 2), barHeight / 2);
        var fillWidth = barWidth * _model.getFlow() / 100;
        var flowColor = _model.getFlow() > 35 ? COLOR_GOOD : COLOR_BAD;
        if (fillWidth > barHeight) {
            dc.setColor(flowColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX, barY, fillWidth, barHeight);
            dc.fillCircle(barX, barY + (barHeight / 2), barHeight / 2);
            dc.fillCircle(barX + fillWidth, barY + (barHeight / 2), barHeight / 2);
        }
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
        drawPillBackground(dc, cx, cy - scaled(51), scaled(70), scaled(23), COLOR_DEEP);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - scaled(51), Graphics.FONT_SMALL, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawPause(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        dc.setColor(COLOR_ABYSS, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(width * 14 / 100, height * 33 / 100,
            width * 72 / 100, height * 34 / 100);
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(2));
        dc.drawRectangle(width * 14 / 100, height * 33 / 100,
            width * 72 / 100, height * 34 / 100);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 44 / 100, Graphics.FONT_MEDIUM, "PAUSED",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        drawActionPill(dc, width / 2, height * 58 / 100,
            "TAP / START TO RESUME", COLOR_ACCENT);
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
        drawActionPill(dc, cx, height * 88 / 100, "RETRY", COLOR_ACCENT);
    }

    private function drawTag(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number) as Void {
        var tag = isAmoled() ? _tagAmoled : _tagMip;
        dc.drawBitmap(x - (tag.getWidth() / 2),
            y - (tag.getHeight() * 72 / 100), tag);
    }

    private function drawPillBackground(dc as Graphics.Dc, cx as Lang.Number,
            cy as Lang.Number, width as Lang.Number, height as Lang.Number,
            color as Lang.Number) as Void {
        var radius = height / 2;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - (width / 2) + radius, cy - radius,
            width - (radius * 2), height);
        dc.fillCircle(cx - (width / 2) + radius, cy, radius);
        dc.fillCircle(cx + (width / 2) - radius, cy, radius);
    }

    private function drawActionPill(dc as Graphics.Dc, cx as Lang.Number,
            cy as Lang.Number, label as Lang.String, color as Lang.Number) as Void {
        var width = dc.getTextWidthInPixels(label, Graphics.FONT_XTINY) + scaled(22);
        var maxWidth = _screenWidth * 76 / 100;
        if (width > maxWidth) {
            width = maxWidth;
        }
        drawPillBackground(dc, cx, cy, width, scaled(22), COLOR_ABYSS);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_XTINY, label,
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

    private function isAmoled() as Lang.Boolean {
        return _screenWidth >= 360;
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
