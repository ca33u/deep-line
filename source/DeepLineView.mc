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
    private var _iceTransitionTicks as Lang.Number = 0;
    private var _descentFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _ascentFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _equalizeFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _turnFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _duckFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _framesLoaded as Lang.Boolean = false;
    private var _loadedAmoled as Lang.Boolean = false;
    private var _buoyMip as WatchUi.BitmapResource;
    private var _buoyAmoled as WatchUi.BitmapResource;
    private var _titleMip as WatchUi.BitmapResource;
    private var _titleAmoled as WatchUi.BitmapResource;
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
    private var _seaLionMip as WatchUi.BitmapResource;
    private var _seaLionAmoled as WatchUi.BitmapResource;
    private var _seaLion1Mip as WatchUi.BitmapResource;
    private var _seaLion1Amoled as WatchUi.BitmapResource;
    private var _thresherMip as WatchUi.BitmapResource;
    private var _thresherAmoled as WatchUi.BitmapResource;
    private var _thresher1Mip as WatchUi.BitmapResource;
    private var _thresher1Amoled as WatchUi.BitmapResource;
    private var _mantaMip as WatchUi.BitmapResource;
    private var _mantaAmoled as WatchUi.BitmapResource;
    private var _manta1Mip as WatchUi.BitmapResource;
    private var _manta1Amoled as WatchUi.BitmapResource;
    private var _hammerheadMip as WatchUi.BitmapResource;
    private var _hammerheadAmoled as WatchUi.BitmapResource;
    private var _hammerhead1Mip as WatchUi.BitmapResource;
    private var _hammerhead1Amoled as WatchUi.BitmapResource;
    private var _penguinMip as WatchUi.BitmapResource;
    private var _penguinAmoled as WatchUi.BitmapResource;
    private var _penguin1Mip as WatchUi.BitmapResource;
    private var _penguin1Amoled as WatchUi.BitmapResource;
    private var _leopardSealFloeMip as WatchUi.BitmapResource;
    private var _leopardSealFloeAmoled as WatchUi.BitmapResource;

    function initialize() {
        View.initialize();
        _model = new DiveModel();
        _timer = new Timer.Timer();
        _buoyMip = WatchUi.loadResource($.Rez.Drawables.BuoyMip) as WatchUi.BitmapResource;
        _buoyAmoled = WatchUi.loadResource($.Rez.Drawables.BuoyAmoled) as WatchUi.BitmapResource;
        _titleMip = WatchUi.loadResource($.Rez.Drawables.DeepLineTitleMip) as WatchUi.BitmapResource;
        _titleAmoled = WatchUi.loadResource($.Rez.Drawables.DeepLineTitleAmoled) as WatchUi.BitmapResource;
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
        _seaLionMip = WatchUi.loadResource($.Rez.Drawables.SeaLionMip) as WatchUi.BitmapResource;
        _seaLionAmoled = WatchUi.loadResource($.Rez.Drawables.SeaLionAmoled) as WatchUi.BitmapResource;
        _seaLion1Mip = WatchUi.loadResource($.Rez.Drawables.SeaLion1Mip) as WatchUi.BitmapResource;
        _seaLion1Amoled = WatchUi.loadResource($.Rez.Drawables.SeaLion1Amoled) as WatchUi.BitmapResource;
        _thresherMip = WatchUi.loadResource($.Rez.Drawables.ThresherSharkMip) as WatchUi.BitmapResource;
        _thresherAmoled = WatchUi.loadResource($.Rez.Drawables.ThresherSharkAmoled) as WatchUi.BitmapResource;
        _thresher1Mip = WatchUi.loadResource($.Rez.Drawables.ThresherShark1Mip) as WatchUi.BitmapResource;
        _thresher1Amoled = WatchUi.loadResource($.Rez.Drawables.ThresherShark1Amoled) as WatchUi.BitmapResource;
        _mantaMip = WatchUi.loadResource($.Rez.Drawables.MantaRayMip) as WatchUi.BitmapResource;
        _mantaAmoled = WatchUi.loadResource($.Rez.Drawables.MantaRayAmoled) as WatchUi.BitmapResource;
        _manta1Mip = WatchUi.loadResource($.Rez.Drawables.MantaRay1Mip) as WatchUi.BitmapResource;
        _manta1Amoled = WatchUi.loadResource($.Rez.Drawables.MantaRay1Amoled) as WatchUi.BitmapResource;
        _hammerheadMip = WatchUi.loadResource($.Rez.Drawables.HammerheadSharkMip) as WatchUi.BitmapResource;
        _hammerheadAmoled = WatchUi.loadResource($.Rez.Drawables.HammerheadSharkAmoled) as WatchUi.BitmapResource;
        _hammerhead1Mip = WatchUi.loadResource($.Rez.Drawables.HammerheadShark1Mip) as WatchUi.BitmapResource;
        _hammerhead1Amoled = WatchUi.loadResource($.Rez.Drawables.HammerheadShark1Amoled) as WatchUi.BitmapResource;
        _penguinMip = WatchUi.loadResource($.Rez.Drawables.SwimmingPenguinMip) as WatchUi.BitmapResource;
        _penguinAmoled = WatchUi.loadResource($.Rez.Drawables.SwimmingPenguinAmoled) as WatchUi.BitmapResource;
        _penguin1Mip = WatchUi.loadResource($.Rez.Drawables.SwimmingPenguin1Mip) as WatchUi.BitmapResource;
        _penguin1Amoled = WatchUi.loadResource($.Rez.Drawables.SwimmingPenguin1Amoled) as WatchUi.BitmapResource;
        _leopardSealFloeMip = WatchUi.loadResource($.Rez.Drawables.LeopardSealFloeMip) as WatchUi.BitmapResource;
        _leopardSealFloeAmoled = WatchUi.loadResource($.Rez.Drawables.LeopardSealFloeAmoled) as WatchUi.BitmapResource;
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
        if (_model.getState() == DiveConstants.STATE_LEVEL_SELECT &&
                !_model.isSelectedUnlocked()) {
            return;
        }
        _feedbackEvent = DiveConstants.EVENT_NONE;
        _feedbackTicks = 0;
        _animationTick = 0;
        _model.startGame();
        startTimer();
        WatchUi.requestUpdate();
    }

    function openCampaign() as Void {
        _model.openCampaign();
        _iceTransitionTicks = _model.getTerritory() == 4 ? 8 : 0;
        WatchUi.requestUpdate();
    }

    function returnToMenu() as Void {
        _model.returnToMenu();
        WatchUi.requestUpdate();
    }

    function changeLevel(delta as Lang.Number) as Void {
        _model.moveSelection(delta);
        _iceTransitionTicks = _model.getTerritory() == 4 ? 8 : 0;
        WatchUi.requestUpdate();
    }

    function startNextOrRetry() as Void {
        _feedbackEvent = DiveConstants.EVENT_NONE;
        _feedbackTicks = 0;
        _animationTick = 0;
        _model.startNextOrRetry();
        startTimer();
        WatchUi.requestUpdate();
    }

    function handleLevelTap(x as Lang.Number, y as Lang.Number) as Void {
        if (y >= _screenHeight * 72 / 100) {
            startGame();
        } else if (x < _screenWidth * 45 / 100) {
            changeLevel(-1);
        } else if (x > _screenWidth * 55 / 100) {
            changeLevel(1);
        }
    }

    function handleResultTap(x as Lang.Number, y as Lang.Number) as Void {
        if (x < _screenWidth / 2) {
            openCampaign();
        } else {
            startNextOrRetry();
        }
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
        if (_iceTransitionTicks > 0) {
            _iceTransitionTicks -= 1;
        }
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
        } else if (state == DiveConstants.STATE_LEVEL_SELECT) {
            drawLevelSelect(dc);
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
        var abyss = isAmoled() ? biomeAbyss() : biomeMipAbyss();
        dc.setColor(abyss, abyss);
        dc.clear();

        var pixelsPerTenMeters = height * 82 / 100;
        var surfaceY = height * 22 / 100;
        var state = _model.getState();
        if (state != DiveConstants.STATE_MENU &&
                state != DiveConstants.STATE_LEVEL_SELECT &&
                state != DiveConstants.STATE_RESULT) {
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
        var surfaceHigh = biomeSurfaceHigh();
        var aqua = biomeAqua();
        var shallow = biomeShallow();
        var mid = biomeMid();
        var deep = biomeDeep();
        var abyss = biomeAbyss();
        if (depthCm <= 0) { return surfaceHigh; }
        if (depthCm < 250) {
            return mixColor(surfaceHigh, aqua, depthCm * 100 / 250);
        }
        if (depthCm < 550) {
            return mixColor(aqua, shallow, (depthCm - 250) * 100 / 300);
        }
        if (depthCm < 950) {
            return mixColor(shallow, mid, (depthCm - 550) * 100 / 400);
        }
        if (depthCm < 1450) {
            return mixColor(mid, deep, (depthCm - 950) * 100 / 500);
        }
        if (depthCm < 2100) {
            return mixColor(deep, abyss, (depthCm - 1450) * 100 / 650);
        }
        return abyss;
    }

    private function mipOceanColor(depthCm as Lang.Number) as Lang.Number {
        // The restricted palette keeps the gradient teal on 64-color MIP screens.
        if (depthCm < 200) { return biomeMipSurface(); }
        if (depthCm < 500) { return biomeMipLight(); }
        if (depthCm < 900) { return biomeMipMid(); }
        if (depthCm < 1450) { return biomeMipDeep(); }
        return biomeMipAbyss();
    }

    private function biomeSurfaceHigh() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x23BFA7; }
        if (territory == 2) { return 0x249AC0; }
        if (territory == 3) { return 0x29B8D0; }
        if (territory == 4) { return 0xB7E6ED; }
        return COLOR_SURFACE_HIGH;
    }

    private function biomeSurface() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x18A68E; }
        if (territory == 2) { return 0x1686AF; }
        if (territory == 3) { return 0x1DA6C5; }
        if (territory == 4) { return 0x83CBD8; }
        return COLOR_SURFACE;
    }

    private function biomeAqua() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x118C79; }
        if (territory == 2) { return 0x0B6D94; }
        if (territory == 3) { return 0x1287AA; }
        if (territory == 4) { return 0x4A9CAF; }
        return COLOR_AQUA;
    }

    private function biomeShallow() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x0A6C62; }
        if (territory == 2) { return 0x08537A; }
        if (territory == 3) { return 0x0A698C; }
        if (territory == 4) { return 0x347A91; }
        return COLOR_SHALLOW;
    }

    private function biomeMid() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x07504E; }
        if (territory == 2) { return 0x063B61; }
        if (territory == 3) { return 0x074D70; }
        if (territory == 4) { return 0x23576E; }
        return COLOR_MID;
    }

    private function biomeDeep() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x06393F; }
        if (territory == 2) { return 0x052A49; }
        if (territory == 3) { return 0x063650; }
        if (territory == 4) { return 0x173A50; }
        return COLOR_DEEP_HIGH;
    }

    private function biomeAbyss() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x031B25; }
        if (territory == 2) { return 0x031525; }
        if (territory == 3) { return 0x031725; }
        if (territory == 4) { return 0x081827; }
        return COLOR_ABYSS;
    }

    private function biomeMipSurface() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x00AA55; }
        if (territory == 2) { return 0x00AAAA; }
        if (territory == 3) { return 0x00AAAA; }
        if (territory == 4) { return 0xAAAAAA; }
        return COLOR_MIP_SURFACE;
    }

    private function biomeMipLight() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x008855; }
        if (territory == 2) { return 0x0088AA; }
        if (territory == 3) { return 0x0088AA; }
        if (territory == 4) { return 0x5588AA; }
        return COLOR_MIP_LIGHT;
    }

    private function biomeMipMid() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x005544; }
        if (territory == 2) { return 0x005588; }
        if (territory == 3) { return 0x005588; }
        if (territory == 4) { return 0x335577; }
        return COLOR_MIP_MID;
    }

    private function biomeMipDeep() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x003333; }
        if (territory == 2) { return 0x003355; }
        if (territory == 3) { return 0x003355; }
        if (territory == 4) { return 0x223344; }
        return COLOR_MIP_DEEP;
    }

    private function biomeMipAbyss() as Lang.Number {
        return _model.getTerritory() == 4 ? 0x112233 : COLOR_MIP_ABYSS;
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

        dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(1));
        dc.drawLine(cx, height * 23 / 100, cx, height * 77 / 100);
        drawSurfaceAndBuoy(dc, cx, height * 22 / 100);
        var title = isAmoled() ? _titleAmoled : _titleMip;
        dc.drawBitmap(cx - (title.getWidth() / 2),
            height * 40 / 100 - (title.getHeight() / 2), title);
        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 52 / 100, Graphics.FONT_XTINY,
            "One breath. One line.",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawDuckFrame(dc, 0, cx - scaled(58), height * 22 / 100 + scaled(7));
        drawMenuActionPill(dc, cx, height * 86 / 100);
    }

    private function drawLevelSelect(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var level = _model.getSelectedLevel();
        var territory = _model.getTerritory();
        var depthMeters = _model.getTargetDepthCm() / 100;

        drawSurfaceAndBuoy(dc, cx, height * 15 / 100);
        drawTerritoryPreview(dc, territory, width * 61 / 100, height * 45 / 100);

        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 24 / 100, Graphics.FONT_SMALL,
            Campaign.territoryName(territory),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 32 / 100, Graphics.FONT_XTINY,
            Campaign.territorySubtitle(territory),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 46 / 100, Graphics.FONT_LARGE,
            depthMeters.format("%d") + "m",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 57 / 100, Graphics.FONT_XTINY,
            Campaign.landmark(level),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawMedals(dc, cx, height * 65 / 100, _model.getSelectedMedal());

        dc.setPenWidth(scaled(2));
        dc.setColor(level > 0 ? COLOR_TEXT : COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(width * 20 / 100, height * 43 / 100,
            width * 15 / 100, height * 46 / 100);
        dc.drawLine(width * 15 / 100, height * 46 / 100,
            width * 20 / 100, height * 49 / 100);
        dc.setColor(level < Campaign.LEVEL_COUNT - 1 ? COLOR_TEXT : COLOR_DIM,
            Graphics.COLOR_TRANSPARENT);
        dc.drawLine(width * 80 / 100, height * 43 / 100,
            width * 85 / 100, height * 46 / 100);
        dc.drawLine(width * 85 / 100, height * 46 / 100,
            width * 80 / 100, height * 49 / 100);

        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 73 / 100, Graphics.FONT_XTINY,
            (level + 1).format("%d") + " / " + Campaign.LEVEL_COUNT.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var actionLabel = _model.isSelectedUnlocked() ? "DIVE" : "LOCKED";
        var actionColor = _model.isSelectedUnlocked() ? COLOR_ACCENT : COLOR_DIM;
        drawPrimaryButton(dc, cx, height * 85 / 100, actionLabel, actionColor);
    }

    private function drawTerritoryPreview(dc as Graphics.Dc,
            territory as Lang.Number, x as Lang.Number, y as Lang.Number) as Void {
        var alternate = ((_animationTick / 6) % 2) == 1;
        var animal = isAmoled() ?
            (alternate ? _seaLion1Amoled : _seaLionAmoled) :
            (alternate ? _seaLion1Mip : _seaLionMip);
        if (territory == 1) {
            animal = isAmoled() ?
                (alternate ? _thresher1Amoled : _thresherAmoled) :
                (alternate ? _thresher1Mip : _thresherMip);
        } else if (territory == 2) {
            animal = isAmoled() ?
                (alternate ? _manta1Amoled : _mantaAmoled) :
                (alternate ? _manta1Mip : _mantaMip);
        } else if (territory == 3) {
            animal = isAmoled() ?
                (alternate ? _hammerhead1Amoled : _hammerheadAmoled) :
                (alternate ? _hammerhead1Mip : _hammerheadMip);
        } else if (territory == 4) {
            animal = isAmoled() ?
                (alternate ? _penguin1Amoled : _penguinAmoled) :
                (alternate ? _penguin1Mip : _penguinMip);
        }
        var bob = ((_animationTick / 6) % 3) - 1;
        dc.drawBitmap(x - (animal.getWidth() / 2),
            y - (animal.getHeight() / 2) + scaled(bob), animal);
    }

    private function drawMedals(dc as Graphics.Dc, cx as Lang.Number,
            y as Lang.Number, earned as Lang.Number) as Void {
        for (var index = 0; index < 3; index += 1) {
            dc.setColor(index < earned ? COLOR_GOOD : COLOR_DIM,
                Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(scaled(2));
            dc.drawCircle(cx + scaled((index - 1) * 18), y, scaled(5));
            if (index < earned) {
                dc.fillCircle(cx + scaled((index - 1) * 18), y, scaled(2));
            }
        }
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
            cy + scaled(52) : cy;
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

        dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(2));
        dc.drawLine(cx, 0, cx, height);

        var targetMeters = _model.getTargetDepthCm() / 100;
        var markerStep = 5;
        if (targetMeters > 40) { markerStep = 10; }
        if (targetMeters > 60) { markerStep = 20; }
        if (targetMeters > 120) { markerStep = 25; }
        for (var meters = 0; meters <= targetMeters; meters += markerStep) {
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
        // Each encounter crosses the background once during descent. Keeping them
        // off ascent prevents the same animal from visibly swimming backwards.
        if (_model.getState() != DiveConstants.STATE_DESCENDING) {
            return;
        }

        var target = _model.getTargetDepthCm();
        var span = target * 18 / 100;
        if (span < 250) { span = 250; }
        if (span > 650) { span = 650; }
        var territory = _model.getTerritory();

        var fishAlt = ((_animationTick / 4) % 2) == 1;
        var fish = isAmoled() ?
            (fishAlt ? _fish1Amoled : _fishAmoled) :
            (fishAlt ? _fish1Mip : _fishMip);

        var turtleAlt = ((_animationTick / 8) % 2) == 1;
        var turtle = isAmoled() ?
            (turtleAlt ? _turtle1Amoled : _turtleAmoled) :
            (turtleAlt ? _turtle1Mip : _turtleMip);

        var orcaAlt = ((_animationTick / 6) % 2) == 1;
        var orca = isAmoled() ?
            (orcaAlt ? _orca1Amoled : _orcaAmoled) :
            (orcaAlt ? _orca1Mip : _orcaMip);

        var seaLionAlt = ((_animationTick / 5) % 2) == 1;
        var seaLion = isAmoled() ?
            (seaLionAlt ? _seaLion1Amoled : _seaLionAmoled) :
            (seaLionAlt ? _seaLion1Mip : _seaLionMip);

        var thresherAlt = ((_animationTick / 7) % 2) == 1;
        var thresher = isAmoled() ?
            (thresherAlt ? _thresher1Amoled : _thresherAmoled) :
            (thresherAlt ? _thresher1Mip : _thresherMip);

        var mantaAlt = ((_animationTick / 8) % 2) == 1;
        var manta = isAmoled() ?
            (mantaAlt ? _manta1Amoled : _mantaAmoled) :
            (mantaAlt ? _manta1Mip : _mantaMip);

        var hammerheadAlt = ((_animationTick / 6) % 2) == 1;
        var hammerhead = isAmoled() ?
            (hammerheadAlt ? _hammerhead1Amoled : _hammerheadAmoled) :
            (hammerheadAlt ? _hammerhead1Mip : _hammerheadMip);

        var penguinAlt = ((_animationTick / 4) % 2) == 1;
        var penguin = isAmoled() ?
            (penguinAlt ? _penguin1Amoled : _penguinAmoled) :
            (penguinAlt ? _penguin1Mip : _penguinMip);

        if (territory == 0) {
            drawEncounter(dc, fish, cy, pixelsPerTenMeters, depth,
                target * 24 / 100, span, true, 4);
            drawEncounter(dc, turtle, cy, pixelsPerTenMeters, depth,
                target * 52 / 100, span, false, 8);
            drawEncounter(dc, seaLion, cy, pixelsPerTenMeters, depth,
                target * 80 / 100, span, true, 5);
        } else if (territory == 1) {
            drawEncounter(dc, fish, cy, pixelsPerTenMeters, depth,
                target * 24 / 100, span, true, 4);
            drawEncounter(dc, turtle, cy, pixelsPerTenMeters, depth,
                target * 52 / 100, span, false, 8);
            drawEncounter(dc, thresher, cy, pixelsPerTenMeters, depth,
                target * 80 / 100, span, false, 6);
        } else if (territory == 2) {
            drawEncounter(dc, fish, cy, pixelsPerTenMeters, depth,
                target * 24 / 100, span, true, 4);
            drawEncounter(dc, manta, cy, pixelsPerTenMeters, depth,
                target * 58 / 100, span, true, 7);
            drawEncounter(dc, turtle, cy, pixelsPerTenMeters, depth,
                target * 82 / 100, span, false, 8);
        } else if (territory == 3) {
            drawEncounter(dc, fish, cy, pixelsPerTenMeters, depth,
                target * 24 / 100, span, true, 4);
            drawEncounter(dc, hammerhead, cy, pixelsPerTenMeters, depth,
                target * 56 / 100, span, false, 6);
            drawEncounter(dc, manta, cy, pixelsPerTenMeters, depth,
                target * 82 / 100, span, true, 7);
        } else {
            drawEncounter(dc, penguin, cy, pixelsPerTenMeters, depth,
                target * 25 / 100, span, true, 5);
            drawEncounter(dc, orca, cy, pixelsPerTenMeters, depth,
                target * 58 / 100, span, true, 6);
            drawEncounter(dc, penguin, cy, pixelsPerTenMeters, depth,
                target * 82 / 100, span, true, 5);
        }
    }

    private function drawEncounter(dc as Graphics.Dc, animal as WatchUi.BitmapResource,
            cy as Lang.Number, pixelsPerTenMeters as Lang.Number,
            depth as Lang.Number, worldDepth as Lang.Number, span as Lang.Number,
            leftToRight as Lang.Boolean, bobPeriod as Lang.Number) as Void {
        var startDepth = worldDepth - span;
        var endDepth = worldDepth + span;
        if (startDepth < 0) { startDepth = 0; }
        if (endDepth > _model.getTargetDepthCm()) {
            endDepth = _model.getTargetDepthCm();
        }
        if (depth < startDepth || depth > endDepth || endDepth <= startDepth) {
            return;
        }

        var width = dc.getWidth();
        var height = dc.getHeight();
        var animalY = cy + ((worldDepth - depth) * pixelsPerTenMeters / 1000);
        if (animalY < height * 10 / 100 || animalY > height * 90 / 100) {
            return;
        }

        var progress = depth - startDepth;
        var travel = width + (animal.getWidth() * 2);
        var animalX = -animal.getWidth() +
            (progress * travel / (endDepth - startDepth));
        if (!leftToRight) {
            animalX = width - (progress * travel / (endDepth - startDepth));
        }
        var bob = ((_animationTick / bobPeriod) % 3) - 1;
        dc.drawBitmap(animalX,
            animalY - (animal.getHeight() / 2) + scaled(bob), animal);
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
            dc.setColor(isAmoled() ? biomeSurfaceHigh() : biomeMipSurface(),
                Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 0, width, y);
        }
        dc.setColor(isAmoled() ? biomeSurface() : biomeMipSurface(),
            Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, y, width, scaled(3));
        dc.setColor(isAmoled() ? biomeAqua() : biomeMipLight(),
            Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, y + scaled(3), width, scaled(4));
        dc.setColor(isAmoled() ? biomeShallow() : biomeMipMid(),
            Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, y + scaled(7), width, scaled(5));

        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(1));
        var waveSegments = 10;
        var wavePhase = (_animationTick / 2) % 2;
        for (var index = 0; index < waveSegments; index += 1) {
            var high = (index + wavePhase) % 2 == 0;
            var waveY = y + (high ? -scaled(1) : scaled(1));
            var nextY = y + (high ? scaled(1) : -scaled(1));
            dc.drawLine(index * width / waveSegments, waveY,
                (index + 1) * width / waveSegments, nextY);
        }

        var buoy = isAmoled() ? _buoyAmoled : _buoyMip;
        var buoyPhase = (_animationTick / 3) % 4;
        var buoyBob = 0;
        if (buoyPhase == 1) { buoyBob = -scaled(1); }
        if (buoyPhase == 3) { buoyBob = scaled(1); }
        dc.drawBitmap(cx - (buoy.getWidth() / 2),
            y - (buoy.getHeight() * 74 / 100) + buoyBob, buoy);

        if (_model.getTerritory() == 4 &&
                _model.getState() != DiveConstants.STATE_MENU) {
            drawAntarcticIce(dc, y);
        }
    }

    private function drawAntarcticIce(dc as Graphics.Dc, y as Lang.Number) as Void {
        var width = dc.getWidth();
        var slide = scaled(_iceTransitionTicks * 6);
        var left = -slide;
        var right = width + slide;
        var showSeal = _model.getState() == DiveConstants.STATE_LEVEL_SELECT &&
            _model.getSelectedLevel() == 13;

        // Pack-ice floes enter from opposite edges whenever an Antarctic level
        // is selected. The center stays open for the buoy and dive line.
        dc.setColor(isAmoled() ? 0x77BED1 : 0x5588AA,
            Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [left - scaled(16), y],
            [left + scaled(100), y + scaled(1)],
            [left + scaled(88), y + scaled(14)],
            [left + scaled(8), y + scaled(12)]
        ]);
        dc.fillPolygon([
            [right + scaled(16), y],
            [right - scaled(96), y + scaled(1)],
            [right - scaled(84), y + scaled(13)],
            [right - scaled(7), y + scaled(11)]
        ]);

        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [left - scaled(16), y - scaled(4)],
            [left + scaled(18), y - scaled(10)],
            [left + scaled(53), y - scaled(8)],
            [left + scaled(100), y - scaled(3)],
            [left + scaled(86), y + scaled(5)],
            [left + scaled(10), y + scaled(6)]
        ]);
        dc.fillPolygon([
            [right + scaled(16), y - scaled(4)],
            [right - scaled(16), y - scaled(9)],
            [right - scaled(50), y - scaled(14)],
            [right - scaled(96), y - scaled(3)],
            [right - scaled(82), y + scaled(5)],
            [right - scaled(8), y + scaled(6)]
        ]);

        dc.setColor(isAmoled() ? 0xD1F1F4 : 0xAAAAAA,
            Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [left + scaled(22), y - scaled(7)],
            [left + scaled(45), y - scaled(12)],
            [left + scaled(70), y - scaled(7)],
            [left + scaled(36), y - scaled(4)]
        ]);
        dc.fillPolygon([
            [right - scaled(20), y - scaled(7)],
            [right - scaled(44), y - scaled(12)],
            [right - scaled(69), y - scaled(7)],
            [right - scaled(35), y - scaled(4)]
        ]);

        if (showSeal) {
            var seal = isAmoled() ? _leopardSealFloeAmoled : _leopardSealFloeMip;
            var sealX = left + scaled(90) - (seal.getWidth() / 2);
            var sealY = y - (seal.getHeight() * 75 / 100);
            dc.drawBitmap(sealX, sealY, seal);
        }

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
        var frameIndex = 0;
        if (_model.getState() == DiveConstants.STATE_TURNING) {
            if (cue == DiveConstants.CUE_TAG) {
                frameIndex = 0;
            } else if (_model.getCueAge() <= 2) {
                frameIndex = 1;
            } else {
                frameIndex = 2;
            }
        } else if (gentleDescent) {
            // Half-speed fin movement with the neutral pose held between kicks.
            var descentPhase = (_animationTick / 4) % 6;
            frameIndex = 1;
            if (descentPhase == 1) { frameIndex = 0; }
            if (descentPhase == 4) { frameIndex = 2; }
        } else if (frames.size() == 2) {
            frameIndex = (_animationTick / 3) % 2;
        } else {
            frameIndex = (_animationTick / 2) % 4;
            if (frameIndex == 3) {
                frameIndex = 1;
            }
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
        if (_feedbackEvent == DiveConstants.EVENT_NONE) {
            if (cue == DiveConstants.CUE_GLIDE) {
                drawTwoLineStatus(dc, "GLIDE", "STAY CALM", COLOR_TEXT);
            } else {
                drawStatusText(dc, label, COLOR_TEXT);
            }
        }
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
        drawStatusText(dc, label, color);
    }

    private function drawStatusText(dc as Graphics.Dc, label as Lang.String,
            color as Lang.Number) as Void {
        var statusY = _screenHeight * 87 / 100;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_screenWidth / 2, statusY, Graphics.FONT_XTINY, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawTwoLineStatus(dc as Graphics.Dc, first as Lang.String,
            second as Lang.String, color as Lang.Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_screenWidth / 2, _screenHeight * 84 / 100,
            Graphics.FONT_XTINY, first,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(_screenWidth / 2, _screenHeight * 90 / 100,
            Graphics.FONT_XTINY, second,
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
        var level = _model.getSelectedLevel();
        drawSurfaceAndBuoy(dc, cx, height * 18 / 100);
        var resultLabel = _model.didReachTarget() ? "SURFACED · OK" : "EARLY TURN · SAFE";
        var resultColor = _model.didReachTarget() ? COLOR_GOOD : COLOR_LINE;
        dc.setColor(resultColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 28 / 100, Graphics.FONT_SMALL, resultLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 36 / 100, Graphics.FONT_XTINY,
            Campaign.territoryName(_model.getTerritory()),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 46 / 100, Graphics.FONT_MEDIUM,
            (_model.getMaxDepthCm() / 100.0).format("%.1f") + "m",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        drawMedals(dc, cx, height * 56 / 100, _model.getRunMedal());
        dc.drawText(cx, height * 64 / 100, Graphics.FONT_SMALL,
            "SCORE " + _model.getScore().format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 72 / 100, Graphics.FONT_XTINY,
            "PERFECT " + _model.getPerfectCount().format("%d") +
            "  MISS " + _model.getMissCount().format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, height * 78 / 100, Graphics.FONT_XTINY,
            "BEST " + _model.getSelectedBestScore().format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        drawActionPill(dc, width * 30 / 100, height * 89 / 100, "MAP", COLOR_TEXT);
        var primary = level < _model.getUnlockedLevel() ? "NEXT" : "RETRY";
        drawActionPill(dc, width * 70 / 100, height * 89 / 100, primary, COLOR_ACCENT);
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

    private function drawMenuActionPill(dc as Graphics.Dc, cx as Lang.Number,
            cy as Lang.Number) as Void {
        drawPrimaryButton(dc, cx, cy, "START", COLOR_ACCENT);
    }

    private function drawPrimaryButton(dc as Graphics.Dc, cx as Lang.Number,
            cy as Lang.Number, label as Lang.String, color as Lang.Number) as Void {
        var width = _screenWidth * 48 / 100;
        var height = scaled(30);
        drawPillBackground(dc, cx, cy, width, height, COLOR_ABYSS);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_SMALL, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function cueLabel(cue as Lang.Number) as Lang.String {
        if (cue == DiveConstants.CUE_EQUALIZE) { return "EQUALIZE"; }
        if (cue == DiveConstants.CUE_TAG) { return "TAKE THE TAG"; }
        if (cue == DiveConstants.CUE_TURN) { return "TURN"; }
        if (cue == DiveConstants.CUE_STROKE) { return "KICK"; }
        if (cue == DiveConstants.CUE_GLIDE) { return "GLIDE"; }
        return "";
    }

    private function feedbackLabel(event as Lang.Number) as Lang.String {
        if (event == DiveConstants.EVENT_PERFECT) { return "PERFECT"; }
        if (event == DiveConstants.EVENT_GOOD) { return "GOOD"; }
        if (event == DiveConstants.EVENT_MISS) { return "MISSED"; }
        if (event == DiveConstants.EVENT_WAIT) { return "EARLY"; }
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
