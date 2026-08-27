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
    const COLOR_ABYSS_HIGH = 0x05212E;
    const COLOR_DEEP = 0x062B3A;
    const COLOR_DEEP_HIGH = 0x083A49;
    const COLOR_MID = 0x0A4A5B;
    const COLOR_MID_HIGH = 0x0B5E6C;
    const COLOR_SHALLOW = 0x0D7180;
    const COLOR_SHALLOW_HIGH = 0x11818A;
    const COLOR_AQUA = 0x159398;
    const COLOR_SURFACE = 0x18A6A6;
    const COLOR_SURFACE_HIGH = 0x1DB8B0;
    const COLOR_MIP_SURFACE = 0x00AAAA;
    const COLOR_MIP_LIGHT = 0x008888;
    const COLOR_MIP_MID = 0x005555;
    const COLOR_MIP_DEEP = 0x003333;
    const COLOR_MIP_ABYSS = 0x001111;
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
    private var _animationTick as Lang.Number = 0;
    private var _descentFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _ascentFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _equalizeFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _turnFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _duckFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _framesLoaded as Lang.Boolean = false;
    private var _loadedAmoled as Lang.Boolean = false;
    private var _buoyMip as WatchUi.BitmapResource;
    private var _buoyAmoled as WatchUi.BitmapResource;
    private var _tagMip as WatchUi.BitmapResource;
    private var _tagAmoled as WatchUi.BitmapResource;
    private var _fishMip as WatchUi.BitmapResource;
    private var _fishAmoled as WatchUi.BitmapResource;
    private var _fish1Mip as WatchUi.BitmapResource;
    private var _fish1Amoled as WatchUi.BitmapResource;
    private var _turtleMip as WatchUi.BitmapResource;
    private var _turtleAmoled as WatchUi.BitmapResource;
    private var _turtle1Mip as WatchUi.BitmapResource;
    private var _turtle1Amoled as WatchUi.BitmapResource;
    private var _orcaMip as WatchUi.BitmapResource;
    private var _orcaAmoled as WatchUi.BitmapResource;
    private var _orca1Mip as WatchUi.BitmapResource;
    private var _orca1Amoled as WatchUi.BitmapResource;

    function initialize() {
        View.initialize();
        _model = new DiveModel();
        _timer = new Timer.Timer();
        _buoyMip = WatchUi.loadResource($.Rez.Drawables.BuoyMip) as WatchUi.BitmapResource;
        _buoyAmoled = WatchUi.loadResource($.Rez.Drawables.BuoyAmoled) as WatchUi.BitmapResource;
        _tagMip = WatchUi.loadResource($.Rez.Drawables.TagMip) as WatchUi.BitmapResource;
        _tagAmoled = WatchUi.loadResource($.Rez.Drawables.TagAmoled) as WatchUi.BitmapResource;
        _fishMip = WatchUi.loadResource($.Rez.Drawables.FishSchoolMip) as WatchUi.BitmapResource;
        _fishAmoled = WatchUi.loadResource($.Rez.Drawables.FishSchoolAmoled) as WatchUi.BitmapResource;
        _fish1Mip = WatchUi.loadResource($.Rez.Drawables.FishSchool1Mip) as WatchUi.BitmapResource;
        _fish1Amoled = WatchUi.loadResource($.Rez.Drawables.FishSchool1Amoled) as WatchUi.BitmapResource;
        _turtleMip = WatchUi.loadResource($.Rez.Drawables.GreenTurtleMip) as WatchUi.BitmapResource;
        _turtleAmoled = WatchUi.loadResource($.Rez.Drawables.GreenTurtleAmoled) as WatchUi.BitmapResource;
        _turtle1Mip = WatchUi.loadResource($.Rez.Drawables.GreenTurtle1Mip) as WatchUi.BitmapResource;
        _turtle1Amoled = WatchUi.loadResource($.Rez.Drawables.GreenTurtle1Amoled) as WatchUi.BitmapResource;
        _orcaMip = WatchUi.loadResource($.Rez.Drawables.OrcaMip) as WatchUi.BitmapResource;
        _orcaAmoled = WatchUi.loadResource($.Rez.Drawables.OrcaAmoled) as WatchUi.BitmapResource;
        _orca1Mip = WatchUi.loadResource($.Rez.Drawables.Orca1Mip) as WatchUi.BitmapResource;
        _orca1Amoled = WatchUi.loadResource($.Rez.Drawables.Orca1Amoled) as WatchUi.BitmapResource;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _screenWidth = dc.getWidth();
        _screenHeight = dc.getHeight();
        loadDiverFrames();
    }

    function onShow() as Void {
        startTimer();
    }

    function onHide() as Void {
        stopTimer();
    }

    function startGame() as Void {
        _feedbackEvent = DiveConstants.EVENT_NONE;
        _feedbackTicks = 0;
        _animationTick = 0;
        _model.startGame();
        startTimer();
        WatchUi.requestUpdate();
    }

    function handleAction() as Void {
        var event = _model.action();
        handleEvent(event);
        WatchUi.requestUpdate();
    }

    function handleTap(x as Lang.Number, y as Lang.Number) as Void {
        if (_model.getState() == DiveConstants.STATE_TURNING) {
            var cue = _model.getCueKind();
            var targetX = turnTargetX(cue);
            var targetY = turnTargetY(cue);
            var hitRadius = scaled(32);
            if (x < targetX - hitRadius || x > targetX + hitRadius ||
                    y < targetY - hitRadius || y > targetY + hitRadius) {
                _feedbackEvent = DiveConstants.EVENT_WAIT;
                _feedbackTicks = 3;
                playVibe([new Attention.VibeProfile(18, 30)]);
                WatchUi.requestUpdate();
                return;
            }
        }
        handleAction();
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
        _animationTick = (_animationTick + 1) % 24;
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
                event == DiveConstants.EVENT_GLIDE_STARTED ||
                event == DiveConstants.EVENT_TURN_READY ||
                event == DiveConstants.EVENT_SURFACE_REACHED ||
                event == DiveConstants.EVENT_DUCKED) {
            return;
        }

        _feedbackEvent = event;
        _feedbackTicks = 10;
        if (event == DiveConstants.EVENT_PERFECT) {
            playVibe([new Attention.VibeProfile(25, 45)]);
        } else if (event == DiveConstants.EVENT_GOOD || event == DiveConstants.EVENT_TURNED ||
                event == DiveConstants.EVENT_TAGGED) {
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

        var pixelsPerTenMeters = height * 82 / 100;
        var surfaceY = height * 22 / 100;
        var state = _model.getState();
        if (state != DiveConstants.STATE_MENU && state != DiveConstants.STATE_RESULT) {
            surfaceY = (height / 2) -
                (_model.getDepthCm() * pixelsPerTenMeters / 1000);
        }

        var stripCount = isAmoled() ? 20 : 10;
        for (var row = 0; row < stripCount; row += 1) {
            var stripTop = row * height / stripCount;
            var stripBottom = (row + 1) * height / stripCount;
            var sampleY = (stripTop + stripBottom) / 2;
            var depthAtStrip = (sampleY - surfaceY) * 1000 / pixelsPerTenMeters;
            var waterColor = isAmoled() ? amoledOceanColor(depthAtStrip) :
                mipOceanColor(depthAtStrip);
            dc.setColor(waterColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, stripTop, width, stripBottom - stripTop + 1);
        }

        var phase = _animationTick % 8;
        var sway = 0;
        if (phase == 2 || phase == 6) { sway = scaled(1); }
        if (phase == 3 || phase == 4 || phase == 5) { sway = scaled(2); }

        // Tiny particles keep the water alive without prominent diagonal rays.
        var drift = (_animationTick % 20) * height / 400;
        var particleTop = height * 14 / 100;
        var particleRange = height * 74 / 100;
        var y1 = height * 38 / 100 - drift;
        var y2 = height * 48 / 100 - drift;
        var y3 = height * 66 / 100 - drift;
        var y4 = height * 75 / 100 - drift;
        var y5 = height * 85 / 100 - drift;
        if (y1 < particleTop) { y1 += particleRange; }
        if (y2 < particleTop) { y2 += particleRange; }
        if (y3 < particleTop) { y3 += particleRange; }
        if (y4 < particleTop) { y4 += particleRange; }
        if (y5 < particleTop) { y5 += particleRange; }
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(width * 18 / 100 + sway, y1, scaled(1));
        dc.fillCircle(width * 78 / 100 - sway, y2, scaled(1));
        dc.fillCircle(width * 28 / 100, y3, scaled(1));
        dc.fillCircle(width * 83 / 100, y4, scaled(1));
        dc.fillCircle(width * 12 / 100, y5, scaled(1));
    }

    private function amoledOceanColor(depthCm as Lang.Number) as Lang.Number {
        if (depthCm <= 0) { return COLOR_SURFACE_HIGH; }
        if (depthCm < 250) {
            return mixColor(COLOR_SURFACE_HIGH, COLOR_AQUA, depthCm * 100 / 250);
        }
        if (depthCm < 550) {
            return mixColor(COLOR_AQUA, COLOR_SHALLOW, (depthCm - 250) * 100 / 300);
        }
        if (depthCm < 950) {
            return mixColor(COLOR_SHALLOW, COLOR_MID, (depthCm - 550) * 100 / 400);
        }
        if (depthCm < 1450) {
            return mixColor(COLOR_MID, COLOR_DEEP_HIGH, (depthCm - 950) * 100 / 500);
        }
        if (depthCm < 2100) {
            return mixColor(COLOR_DEEP_HIGH, COLOR_ABYSS, (depthCm - 1450) * 100 / 650);
        }
        return COLOR_ABYSS;
    }

    private function mipOceanColor(depthCm as Lang.Number) as Lang.Number {
        // The restricted palette keeps the gradient teal on 64-color MIP screens.
        if (depthCm < 200) { return COLOR_MIP_SURFACE; }
        if (depthCm < 500) { return COLOR_MIP_LIGHT; }
        if (depthCm < 900) { return COLOR_MIP_MID; }
        if (depthCm < 1450) { return COLOR_MIP_DEEP; }
        return COLOR_MIP_ABYSS;
    }

    private function mixColor(fromColor as Lang.Number, toColor as Lang.Number,
            amount as Lang.Number) as Lang.Number {
        if (amount < 0) { amount = 0; }
        if (amount > 100) { amount = 100; }
        var fromR = (fromColor >> 16) & 0xFF;
        var fromG = (fromColor >> 8) & 0xFF;
        var fromB = fromColor & 0xFF;
        var toR = (toColor >> 16) & 0xFF;
        var toG = (toColor >> 8) & 0xFF;
        var toB = toColor & 0xFF;
        var red = fromR + ((toR - fromR) * amount / 100);
        var green = fromG + ((toG - fromG) * amount / 100);
        var blue = fromB + ((toB - fromB) * amount / 100);
        return (red << 16) | (green << 8) | blue;
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

        drawDuckFrame(dc, 0, cx - scaled(58), height * 22 / 100 + scaled(7));
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
        if (state == DiveConstants.STATE_DUCK_DIVE) {
            drawDuckSequence(dc, cx, cy);
            drawFeedback(dc, cx, cy);
            return;
        }
        var diverX = state == DiveConstants.STATE_TURNING ?
            cx - scaled(38) : cx - scaled(28);
        var diverY = state == DiveConstants.STATE_SURFACING ?
            cy + scaled(36) : cy;
        drawDiver(dc, diverX, diverY, descending);
        drawCue(dc, cx, cy);
        if (state != DiveConstants.STATE_SURFACING) {
            drawHud(dc);
        }
        drawFeedback(dc, cx, cy);
    }

    private function drawWorld(dc as Graphics.Dc, cx as Lang.Number, cy as Lang.Number) as Void {
        var height = dc.getHeight();
        var depth = _model.getDepthCm();
        var pixelsPerTenMeters = height * 82 / 100;

        drawDepthLife(dc, cx, cy, pixelsPerTenMeters, depth);

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
        var state = _model.getState();
        var showTag = state == DiveConstants.STATE_DESCENDING ||
            _model.getCueKind() == DiveConstants.CUE_TAG;
        if (showTag && targetY > -scaled(40) && targetY < height + scaled(40)) {
            drawTag(dc, cx, targetY);
        }
    }

    private function drawDepthLife(dc as Graphics.Dc, cx as Lang.Number,
            cy as Lang.Number, pixelsPerTenMeters as Lang.Number,
            depth as Lang.Number) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var swimPhase = _animationTick % 24;
        var swim = swimPhase <= 12 ? swimPhase : 24 - swimPhase;
        var drift = (swim - 6) * scaled(1) / 2;

        var fishAlt = ((_animationTick / 4) % 2) == 1;
        var fish = isAmoled() ?
            (fishAlt ? _fish1Amoled : _fishAmoled) :
            (fishAlt ? _fish1Mip : _fishMip);
        var fishY = cy + ((450 - depth) * pixelsPerTenMeters / 1000);
        if (fishY > height * 12 / 100 && fishY < height * 88 / 100) {
            dc.drawBitmap(width * 64 / 100 - (fish.getWidth() / 2) + drift,
                fishY - (fish.getHeight() / 2), fish);
        }

        var turtleAlt = ((_animationTick / 8) % 2) == 1;
        var turtle = isAmoled() ?
            (turtleAlt ? _turtle1Amoled : _turtleAmoled) :
            (turtleAlt ? _turtle1Mip : _turtleMip);
        var turtleY = cy + ((1000 - depth) * pixelsPerTenMeters / 1000);
        if (turtleY > height * 12 / 100 && turtleY < height * 88 / 100) {
            dc.drawBitmap(width * 27 / 100 - (turtle.getWidth() / 2) - drift,
                turtleY - (turtle.getHeight() / 2), turtle);
        }

        if (_model.getState() == DiveConstants.STATE_DESCENDING) {
            var orcaAlt = ((_animationTick / 6) % 2) == 1;
            var orca = isAmoled() ?
                (orcaAlt ? _orca1Amoled : _orcaAmoled) :
                (orcaAlt ? _orca1Mip : _orcaMip);
            var orcaY = cy + ((1650 - depth) * pixelsPerTenMeters / 1000);
            if (orcaY > height * 12 / 100 && orcaY < height * 88 / 100) {
                dc.drawBitmap(width * 55 / 100 - (orca.getWidth() / 2) + (drift / 2),
                    orcaY - (orca.getHeight() / 2), orca);
            }
        }
    }

    private function drawDuckSequence(dc as Graphics.Dc, cx as Lang.Number,
            surfaceY as Lang.Number) as Void {
        var age = _model.getDuckAge();
        if (age < 4) {
            drawDuckFrame(dc, 0, cx - scaled(58), surfaceY + scaled(7));
        } else if (age < 8) {
            drawDuckFrame(dc, 1, cx - scaled(38), surfaceY + scaled(20));
        } else {
            var settle = 20 - ((age - 8) * 5);
            drawDuckFrame(dc, 2, cx - scaled(28), surfaceY + scaled(settle));
        }
    }

    private function drawDuckFrame(dc as Graphics.Dc, index as Lang.Number,
            x as Lang.Number, y as Lang.Number) as Void {
        if (_duckFrames.size() <= index) {
            return;
        }
        var frame = _duckFrames[index];
        dc.drawBitmap(x - (frame.getWidth() / 2),
            y - (frame.getHeight() / 2), frame);
    }

    private function drawSurfaceAndBuoy(dc as Graphics.Dc, cx as Lang.Number,
            y as Lang.Number) as Void {
        var width = dc.getWidth();

        // A bright cap above the wave and three shallow layers below it make the
        // surface a real boundary that scrolls away as the diver goes deeper.
        if (y > 0) {
            dc.setColor(isAmoled() ? COLOR_SURFACE_HIGH : COLOR_MIP_SURFACE,
                Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 0, width, y);
        }
        dc.setColor(isAmoled() ? COLOR_SURFACE : COLOR_MIP_SURFACE,
            Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, y, width, scaled(3));
        dc.setColor(isAmoled() ? COLOR_AQUA : COLOR_MIP_LIGHT,
            Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, y + scaled(3), width, scaled(4));
        dc.setColor(isAmoled() ? COLOR_SHALLOW_HIGH : COLOR_MIP_MID,
            Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, y + scaled(7), width, scaled(5));

        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(1));
        var waveWidth = width * 52 / 100;
        var waveLeft = cx - (waveWidth / 2);
        var segment = waveWidth / 6;
        var wavePhase = (_animationTick / 2) % 2;
        for (var index = 0; index < 6; index += 1) {
            var high = (index + wavePhase) % 2 == 0;
            var waveY = y + (high ? -scaled(1) : scaled(1));
            var nextY = y + (high ? scaled(1) : -scaled(1));
            dc.drawLine(waveLeft + (index * segment), waveY,
                waveLeft + ((index + 1) * segment), nextY);
        }

        var buoy = isAmoled() ? _buoyAmoled : _buoyMip;
        var buoyPhase = (_animationTick / 3) % 4;
        var buoyBob = 0;
        if (buoyPhase == 1) { buoyBob = -scaled(1); }
        if (buoyPhase == 3) { buoyBob = scaled(1); }
        dc.drawBitmap(cx - (buoy.getWidth() / 2),
            y - (buoy.getHeight() * 64 / 100) + buoyBob, buoy);
        dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(1));
        dc.drawLine(cx, y, cx, y + scaled(16));
    }

    private function drawDiver(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number,
            headDown as Lang.Boolean) as Void {
        var frames = headDown ? _descentFrames : _ascentFrames;
        if (_model.getCueKind() == DiveConstants.CUE_EQUALIZE) {
            frames = _equalizeFrames;
        }
        if (_model.getState() == DiveConstants.STATE_TURNING ||
                _model.getCueKind() == DiveConstants.CUE_TAG) {
            frames = _turnFrames;
        }
        if (frames.size() == 0) {
            return;
        }

        var cue = _model.getCueKind();
        var gentleDescent = headDown && cue != DiveConstants.CUE_EQUALIZE &&
            cue != DiveConstants.CUE_TAG &&
            _model.getState() != DiveConstants.STATE_TURNING;
        var frameIndex = (_animationTick / 2) % 4;
        if (gentleDescent) {
            // Half-speed fin movement with the neutral pose held between kicks.
            var descentPhase = (_animationTick / 4) % 6;
            frameIndex = 1;
            if (descentPhase == 1) { frameIndex = 0; }
            if (descentPhase == 4) { frameIndex = 2; }
        } else if (frames.size() == 2) {
            frameIndex = (_animationTick / 3) % 2;
        } else if (frameIndex == 3) {
            frameIndex = 1;
        }

        var bobPhase = (_animationTick / 3) % 4;
        var bob = 0;
        if (!gentleDescent) {
            if (bobPhase == 1) { bob = -scaled(1); }
            if (bobPhase == 3) { bob = scaled(1); }
        }
        var diver = frames[frameIndex];
        dc.drawBitmap(x - (diver.getWidth() / 2),
            y - (diver.getHeight() / 2) + bob, diver);
    }

    private function drawCue(dc as Graphics.Dc, cx as Lang.Number, cy as Lang.Number) as Void {
        var cue = _model.getCueKind();
        if (cue == DiveConstants.CUE_NONE) {
            return;
        }

        if (cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) {
            var cueAge = _model.getCueAge();
            var movingRadius = scaled(126 - (cueAge * 11));
            if (movingRadius < scaled(70)) {
                movingRadius = scaled(70);
            }
            var targetColor = COLOR_DIM;
            if (cueAge >= 2 && cueAge <= 3) {
                targetColor = COLOR_GOOD;
            }
            dc.setColor(targetColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(scaled(1));
            dc.drawCircle(cx, cy, scaled(70));
            dc.drawCircle(cx, cy, scaled(74));
            var ringColor = COLOR_FOAM;
            if (cueAge >= 2 && cueAge <= 3) {
                ringColor = COLOR_GOOD;
            } else if (cueAge >= 4) {
                ringColor = COLOR_LINE;
            }
            dc.setColor(ringColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(scaled(2));
            dc.drawCircle(cx, cy, movingRadius);
        } else if (cue == DiveConstants.CUE_TAG || cue == DiveConstants.CUE_TURN) {
            var targetX = turnTargetX(cue);
            var targetY = turnTargetY(cue);
            var pulse = scaled(22 + ((_animationTick / 2) % 3));
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(scaled(1));
            dc.drawCircle(targetX, targetY, scaled(17));
            dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(scaled(2));
            dc.drawCircle(targetX, targetY, pulse);
            dc.fillCircle(targetX, targetY, scaled(3));
        }

        var label = cueLabel(cue);
        drawActionPill(dc, _screenWidth / 2, _screenHeight * 78 / 100,
            label, COLOR_TEXT);
    }

    private function turnTargetX(cue as Lang.Number) as Lang.Number {
        if (cue == DiveConstants.CUE_TURN) {
            return _screenWidth * 28 / 100;
        }
        return _screenWidth / 2;
    }

    private function turnTargetY(cue as Lang.Number) as Lang.Number {
        if (cue == DiveConstants.CUE_TURN) {
            return _screenHeight * 66 / 100;
        }
        return _screenHeight / 2;
    }

    private function drawHud(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var depthMeters = _model.getDepthCm() / 100.0;

        var hudY = height / 2;
        var depthX = width * 82 / 100;
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(depthX, hudY, Graphics.FONT_MEDIUM,
            depthMeters.format("%.1f") + "m",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var radius = (width < height ? width : height) * 44 / 100;
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(6));
        dc.drawArc(width / 2, height / 2, radius,
            Graphics.ARC_COUNTER_CLOCKWISE, 135, 225);

        var flow = _model.getFlow();
        var flowColor = _model.getFlow() > 35 ? COLOR_GOOD : COLOR_BAD;
        var fillStart = 225 - (90 * flow / 100);
        dc.setColor(flowColor, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(width / 2, height / 2, radius,
            Graphics.ARC_COUNTER_CLOCKWISE, fillStart, 225);

        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width * 17 / 100, hudY, Graphics.FONT_XTINY, "FLOW",
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
        var feedbackY = _screenHeight * 90 / 100;
        drawPillBackground(dc, cx, feedbackY, scaled(70), scaled(23), COLOR_DEEP);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, feedbackY, Graphics.FONT_SMALL, label,
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
        var tagPhase = (_animationTick / 3) % 4;
        var tagSway = 0;
        if (tagPhase == 1) { tagSway = -scaled(1); }
        if (tagPhase == 3) { tagSway = scaled(1); }
        dc.drawBitmap(x - (tag.getWidth() / 2) + tagSway,
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
        if (cue == DiveConstants.CUE_TURN) { return "TURN"; }
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
        if (event == DiveConstants.EVENT_TAGGED) { return "TAGGED"; }
        if (event == DiveConstants.EVENT_TURNED) { return "TURN"; }
        if (event == DiveConstants.EVENT_GLIDE_PENALTY) { return "STAY CALM"; }
        return "";
    }

    private function scaled(value as Lang.Number) as Lang.Number {
        return value * _screenWidth / REFERENCE_WIDTH;
    }

    private function loadDiverFrames() as Void {
        var amoled = isAmoled();
        if (_framesLoaded && _loadedAmoled == amoled) {
            return;
        }

        if (amoled) {
            _descentFrames = [
                WatchUi.loadResource($.Rez.Drawables.DiverDescend0Amoled) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverDescend1Amoled) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverDescend2Amoled) as WatchUi.BitmapResource
            ];
            _ascentFrames = [
                WatchUi.loadResource($.Rez.Drawables.DiverAscend0Amoled) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverAscend1Amoled) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverAscend2Amoled) as WatchUi.BitmapResource
            ];
            _equalizeFrames = [
                WatchUi.loadResource($.Rez.Drawables.DiverEqualize0Amoled) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverEqualize1Amoled) as WatchUi.BitmapResource
            ];
            _turnFrames = [
                WatchUi.loadResource($.Rez.Drawables.DiverTurn0Amoled) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverTurn1Amoled) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverTurn2Amoled) as WatchUi.BitmapResource
            ];
            _duckFrames = [
                WatchUi.loadResource($.Rez.Drawables.DiverDuck0Amoled) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverDuck1Amoled) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverDuck2Amoled) as WatchUi.BitmapResource
            ];
        } else {
            _descentFrames = [
                WatchUi.loadResource($.Rez.Drawables.DiverDescend0Mip) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverDescend1Mip) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverDescend2Mip) as WatchUi.BitmapResource
            ];
            _ascentFrames = [
                WatchUi.loadResource($.Rez.Drawables.DiverAscend0Mip) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverAscend1Mip) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverAscend2Mip) as WatchUi.BitmapResource
            ];
            _equalizeFrames = [
                WatchUi.loadResource($.Rez.Drawables.DiverEqualize0Mip) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverEqualize1Mip) as WatchUi.BitmapResource
            ];
            _turnFrames = [
                WatchUi.loadResource($.Rez.Drawables.DiverTurn0Mip) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverTurn1Mip) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverTurn2Mip) as WatchUi.BitmapResource
            ];
            _duckFrames = [
                WatchUi.loadResource($.Rez.Drawables.DiverDuck0Mip) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverDuck1Mip) as WatchUi.BitmapResource,
                WatchUi.loadResource($.Rez.Drawables.DiverDuck2Mip) as WatchUi.BitmapResource
            ];
        }

        _loadedAmoled = amoled;
        _framesLoaded = true;
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
