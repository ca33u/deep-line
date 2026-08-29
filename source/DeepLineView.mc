using Toybox.Attention;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;

class DeepLineView extends WatchUi.View {
    // Slightly faster than the first hardware-tuned pass: this trims the
    // expanded timing windows by about 4% without removing a whole grace tick.
    const TIMER_PERIOD_MS = 120;
    const REFERENCE_WIDTH = 280;
    const HERO_TRAVEL_TICKS = 64;

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
    const COLOR_MIP_LIGHT = 0x0055AA;
    const COLOR_MIP_MID = 0x005555;
    const COLOR_MIP_DEEP = 0x000055;
    const COLOR_MIP_ABYSS = 0x000000;
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
    private var _pauseSelection as Lang.Number = 0;
    private var _heroTravelTick as Lang.Number = 8;
    private var _heroCarryEndTick as Lang.Number = -1;
    private var _descentFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _ascentFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _equalizeFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _turnFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _duckFrames as Lang.Array<WatchUi.BitmapResource> = [];
    private var _framesLoaded as Lang.Boolean = false;
    private var _loadedAmoled as Lang.Boolean = false;
    private var _amoled as Lang.Boolean = false;
    private var _displayResolved as Lang.Boolean = false;
    private var _mipOceanBackground as WatchUi.BitmapResource or Null = null;
    private var _mipOceanTerritory as Lang.Number = -1;
    // Only the set matching the current display is resident. Keys map to a
    // single bitmap or, for wildlife, to a two-frame animation strip.
    private var _art as Lang.Dictionary = {};

    function initialize() {
        View.initialize();
        _model = new DiveModel();
        _timer = new Timer.Timer();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _screenWidth = dc.getWidth();
        _screenHeight = dc.getHeight();
        loadArt();
    }

    function onShow() as Void {
        if (_model.getState() != DiveConstants.STATE_PAUSED) {
            startTimer();
        }
    }

    function onHide() as Void {
        stopTimer();
    }

    function startGame() as Void {
        if (_model.getState() == DiveConstants.STATE_LEVEL_SELECT &&
                !_model.isSelectedUnlocked()) {
            return;
        }
        var carriesCampaignHero =
            _model.getState() == DiveConstants.STATE_LEVEL_SELECT;
        _feedbackEvent = DiveConstants.EVENT_NONE;
        _feedbackTicks = 0;
        if (carriesCampaignHero) {
            var heroPhase = _heroTravelTick % HERO_TRAVEL_TICKS;
            _heroCarryEndTick = _heroTravelTick +
                (HERO_TRAVEL_TICKS - heroPhase);
        } else {
            _heroCarryEndTick = -1;
        }
        _model.startGame();
        startTimer();
        WatchUi.requestUpdate();
    }

    function openCampaign() as Void {
        _model.openCampaign();
        _iceTransitionTicks = _model.getTerritory() == 4 ? 8 : 0;
        _heroTravelTick = 8;
        _heroCarryEndTick = -1;
        WatchUi.requestUpdate();
    }

    function returnToMenu() as Void {
        _model.returnToMenu();
        startTimer();
        WatchUi.requestUpdate();
    }

    function leaveDiveToMenu() as Void {
        _feedbackEvent = DiveConstants.EVENT_NONE;
        _feedbackTicks = 0;
        _model.returnToMenu();
        startTimer();
        WatchUi.requestUpdate();
    }

    function changeLevel(delta as Lang.Number) as Void {
        var previousTerritory = _model.getTerritory();
        _model.moveSelection(delta);
        _iceTransitionTicks = _model.getTerritory() == 4 ? 8 : 0;
        if (_model.getTerritory() != previousTerritory) {
            _heroTravelTick = 8;
        }
        _heroCarryEndTick = -1;
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
        var actionY = _screenHeight / 2;
        var hitHalfHeight = scaled(28);
        if (y < actionY - hitHalfHeight || y > actionY + hitHalfHeight) {
            return;
        }
        if (x < _screenWidth * 35 / 100) {
            openCampaign();
        } else if (x > _screenWidth * 65 / 100) {
            startNextOrRetry();
        }
    }

    function handleAction() as Void {
        var event = _model.action();
        handleEvent(event);
        WatchUi.requestUpdate();
    }

    function handleTap(x as Lang.Number, y as Lang.Number) as Void {
        // Gameplay has one universal action. Touch coordinates must never make
        // TAG/TURN easier or harder than START/ENTER on button-only watches.
        handleAction();
    }

    function togglePause() as Void {
        _model.togglePause();
        if (_model.getState() == DiveConstants.STATE_PAUSED) {
            _pauseSelection = 0;
            stopTimer();
        } else if (_model.isDiveActive()) {
            startTimer();
        }
        WatchUi.requestUpdate();
    }

    function movePauseSelection(delta as Lang.Number) as Void {
        _pauseSelection += delta;
        if (_pauseSelection < 0) { _pauseSelection = 1; }
        if (_pauseSelection > 1) { _pauseSelection = 0; }
        WatchUi.requestUpdate();
    }

    function activatePauseSelection() as Void {
        if (_pauseSelection == 0) {
            togglePause();
        } else {
            leaveDiveToMenu();
        }
    }

    function handlePauseTap(x as Lang.Number, y as Lang.Number) as Void {
        if (y < _screenHeight * 40 / 100 || y > _screenHeight * 78 / 100) {
            return;
        }
        if (y < _screenHeight * 60 / 100) {
            _pauseSelection = 0;
        } else {
            _pauseSelection = 1;
        }
        activatePauseSelection();
    }

    function exitApp() as Void {
        _model.saveProgress();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function persistBestScore() as Void {
        _model.saveProgress();
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
        _heroTravelTick += 1;
        if (_iceTransitionTicks > 0) {
            _iceTransitionTicks -= 1;
        }
        if (_feedbackTicks > 0) {
            _feedbackTicks -= 1;
            if (_feedbackTicks == 0) {
                _feedbackEvent = DiveConstants.EVENT_NONE;
            }
        }

        // The clock keeps running on the result, map and title screens: the buoy,
        // particles and territory preview are animated there too. It stops only
        // when the view is hidden or the dive is paused.
        handleEvent(_model.advance());
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
        } else if (event == DiveConstants.EVENT_GOOD) {
            playVibe([new Attention.VibeProfile(18, 35)]);
        } else if (event == DiveConstants.EVENT_MISS || event == DiveConstants.EVENT_WAIT ||
                event == DiveConstants.EVENT_GLIDE_PENALTY ||
                event == DiveConstants.EVENT_TAG_MISS) {
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
        // Idempotent: onLayout normally does this first, but drawing must never
        // run against an empty art set.
        loadArt();
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
        var staticScreen = state == DiveConstants.STATE_MENU ||
            state == DiveConstants.STATE_LEVEL_SELECT ||
            state == DiveConstants.STATE_RESULT;
        if (!staticScreen) {
            surfaceY = diveFocusY(height, pixelsPerTenMeters,
                _model.getDepthCm()) -
                (_model.getDepthCm() * pixelsPerTenMeters / 1000);
        }

        if (!isAmoled()) {
            // A five-color depth ladder turned into huge horizontal bands during
            // gameplay. The pre-rendered ordered-dither background uses the same
            // native MIP palette and blends those colors spatially. Keep its
            // Bayer phase fixed in screen coordinates: scrolling the dither by
            // one pixel changes almost every pixel and flashes on real MIP.
            drawMipOcean(dc, width, height);
        } else {
            var stripCount = 20;
            for (var row = 0; row < stripCount; row += 1) {
                var stripTop = row * height / stripCount;
                var stripBottom = (row + 1) * height / stripCount;
                var sampleY = (stripTop + stripBottom) / 2;
                var depthAtStrip = (sampleY - surfaceY) * 1000 / pixelsPerTenMeters;
                var waterColor = amoledOceanColor(depthAtStrip);
                dc.setColor(waterColor, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(0, stripTop, width, stripBottom - stripTop + 1);
            }
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

    private function drawMipOcean(dc as Graphics.Dc, width as Lang.Number,
            height as Lang.Number) as Void {
        var background = mipOceanBackground();
        dc.setColor(biomeMipAbyss(), Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height);
        dc.drawBitmap((width - background.getWidth()) / 2,
            (height - background.getHeight()) / 2, background);
    }

    private function amoledOceanColor(depthCm as Lang.Number) as Lang.Number {
        var surfaceHigh = biomeSurfaceHigh();
        var aqua = biomeAqua();
        var shallow = biomeShallow();
        var mid = biomeMid();
        var deep = biomeDeep();
        var abyss = biomeAbyss();
        if (depthCm <= 0) { return surfaceHigh; }
        if (depthCm < 500) {
            return mixColor(surfaceHigh, aqua, depthCm * 100 / 500);
        }
        if (depthCm < 1500) {
            return mixColor(aqua, shallow, (depthCm - 500) * 100 / 1000);
        }
        if (depthCm < 3500) {
            return mixColor(shallow, mid, (depthCm - 1500) * 100 / 2000);
        }
        if (depthCm < 7500) {
            return mixColor(mid, deep, (depthCm - 3500) * 100 / 4000);
        }
        if (depthCm < 15000) {
            return mixColor(deep, abyss, (depthCm - 7500) * 100 / 7500);
        }
        return abyss;
    }

    private function biomeSurfaceHigh() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x1FAFC4; }
        if (territory == 2) { return 0x249AC0; }
        if (territory == 3) { return 0x29B8D0; }
        if (territory == 4) { return 0xB7E6ED; }
        return COLOR_SURFACE_HIGH;
    }

    private function biomeSurface() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x178FA8; }
        if (territory == 2) { return 0x1686AF; }
        if (territory == 3) { return 0x1DA6C5; }
        if (territory == 4) { return 0x83CBD8; }
        return COLOR_SURFACE;
    }

    private function biomeAqua() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x11758E; }
        if (territory == 2) { return 0x0B6D94; }
        if (territory == 3) { return 0x1287AA; }
        if (territory == 4) { return 0x4A9CAF; }
        return COLOR_AQUA;
    }

    private function biomeShallow() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x0A5B72; }
        if (territory == 2) { return 0x08537A; }
        if (territory == 3) { return 0x0A698C; }
        if (territory == 4) { return 0x347A91; }
        return COLOR_SHALLOW;
    }

    private function biomeMid() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x074458; }
        if (territory == 2) { return 0x063B61; }
        if (territory == 3) { return 0x074D70; }
        if (territory == 4) { return 0x23576E; }
        return COLOR_MID;
    }

    private function biomeDeep() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x063044; }
        if (territory == 2) { return 0x052A49; }
        if (territory == 3) { return 0x063650; }
        if (territory == 4) { return 0x173A50; }
        return COLOR_DEEP_HIGH;
    }

    private function biomeAbyss() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x031824; }
        if (territory == 2) { return 0x031525; }
        if (territory == 3) { return 0x031725; }
        if (territory == 4) { return 0x081827; }
        return COLOR_ABYSS;
    }

    private function biomeMipSurface() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x00AAAA; }
        if (territory == 2) { return 0x00AAAA; }
        if (territory == 3) { return 0x00AAAA; }
        if (territory == 4) { return 0xAAAAAA; }
        return COLOR_MIP_SURFACE;
    }

    private function biomeMipLight() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x005555; }
        if (territory == 2) { return 0x0055AA; }
        if (territory == 3) { return 0x0055AA; }
        if (territory == 4) { return 0x55AAAA; }
        return COLOR_MIP_LIGHT;
    }

    private function biomeMipMid() as Lang.Number {
        var territory = _model.getTerritory();
        if (territory == 1) { return 0x005555; }
        if (territory == 2) { return 0x005555; }
        if (territory == 3) { return 0x005555; }
        if (territory == 4) { return 0x5555AA; }
        return COLOR_MIP_MID;
    }

    private function biomeMipDeep() as Lang.Number {
        if (_model.getTerritory() == 4) { return 0x005555; }
        return COLOR_MIP_DEEP;
    }

    private function biomeMipAbyss() as Lang.Number {
        return _model.getTerritory() == 4 ? 0x000055 : COLOR_MIP_ABYSS;
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
        // On the title scene the guide line is a real world object, not a
        // decorative divider: let it continue past the CTA and disappear below
        // the circular viewport instead of stopping in open water.
        dc.drawLine(cx, height * 23 / 100, cx, height);
        drawSurfaceAndBuoy(dc, cx, height * 22 / 100);
        var title = bitmap(:title);
        dc.drawBitmap(cx - (title.getWidth() / 2),
            height / 2 - (title.getHeight() / 2), title);

        drawDuckFrame(dc, 0, cx - scaled(58), height * 22 / 100 + scaled(7));
        drawPlainAction(dc, cx, height * 86 / 100, "START", 0xFFFFFF);
    }

    private function drawLevelSelect(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var level = _model.getSelectedLevel();
        var territory = _model.getTerritory();
        var depthMeters = _model.getTargetDepthCm() / 100;
        var surfaceY = height * 22 / 100;

        drawSurfaceAndBuoy(dc, cx, surfaceY);
        drawDuckFrame(dc, 0, cx - scaled(58), surfaceY + scaled(7));
        drawTerritoryPreview(dc, territory);

        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 32 / 100, Graphics.FONT_SMALL,
            Campaign.territoryName(territory),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height / 2, Graphics.FONT_LARGE,
            depthMeters.format("%d") + "m",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawMedals(dc, cx, height * 62 / 100, _model.getSelectedMedal());

        dc.setPenWidth(scaled(2));
        dc.setColor(level > 0 ? COLOR_TEXT : COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(width * 20 / 100, height * 47 / 100,
            width * 15 / 100, height * 50 / 100);
        dc.drawLine(width * 15 / 100, height * 50 / 100,
            width * 20 / 100, height * 53 / 100);
        dc.setColor(level < Campaign.LEVEL_COUNT - 1 ? COLOR_TEXT : COLOR_DIM,
            Graphics.COLOR_TRANSPARENT);
        dc.drawLine(width * 80 / 100, height * 47 / 100,
            width * 85 / 100, height * 50 / 100);
        dc.drawLine(width * 85 / 100, height * 50 / 100,
            width * 80 / 100, height * 53 / 100);

        var actionLabel = _model.isSelectedUnlocked() ? "DIVE" : "LOCKED";
        var actionColor = _model.isSelectedUnlocked() ? 0xFFFFFF : COLOR_DIM;
        var actionY = height * 86 / 100;
        drawPlainAction(dc, cx, actionY, actionLabel, actionColor);
    }

    private function drawTerritoryPreview(dc as Graphics.Dc,
            territory as Lang.Number) as Void {
        var height = dc.getHeight();
        // The card shows a real scene participant, not a decorative thumbnail.
        // Its travel phase and sprite frame continue when DIVE is pressed.
        drawCampaignHero(dc, territory, height * 71 / 100);
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
        var screenCy = height / 2;
        var pixelsPerTenMeters = height * 82 / 100;
        var focusY = diveFocusY(height, pixelsPerTenMeters,
            _model.getDepthCm());
        var state = _model.getState();
        var descending = state == DiveConstants.STATE_DESCENDING ||
            (state == DiveConstants.STATE_PAUSED && _model.getCueKind() == DiveConstants.CUE_EQUALIZE);

        drawWorld(dc, cx, focusY);
        if (state == DiveConstants.STATE_DUCK_DIVE) {
            drawDuckSequence(dc, cx, height * 22 / 100);
            drawFeedback(dc, cx, screenCy);
            return;
        }
        var diverX = state == DiveConstants.STATE_TURNING ?
            cx - scaled(38) : cx - scaled(28);
        var diverY = focusY;
        var surfacePoseOffset = scaled(30);
        if (state == DiveConstants.STATE_ASCENDING) {
            var surfaceY = focusY -
                (_model.getDepthCm() * pixelsPerTenMeters / 1000);
            var nearSurfaceY = surfaceY + surfacePoseOffset;
            if (diverY < nearSurfaceY) {
                diverY = nearSurfaceY;
            }
        } else if (state == DiveConstants.STATE_SURFACING) {
            diverY = height * 22 / 100 + surfacePoseOffset;
        }
        drawDiver(dc, diverX, diverY, descending);
        // Timing remains a whole-screen instrument instead of following the
        // diver during the first metres of camera settling.
        drawCue(dc, cx, screenCy);
        if (state != DiveConstants.STATE_SURFACING) {
            drawHud(dc);
        }
        drawFeedback(dc, cx, screenCy);
    }

    private function drawWorld(dc as Graphics.Dc, cx as Lang.Number,
            focusY as Lang.Number) as Void {
        var height = dc.getHeight();
        var depth = _model.getDepthCm();
        var state = _model.getState();
        var pixelsPerTenMeters = height * 82 / 100;

        drawDepthLife(dc, cx, focusY, pixelsPerTenMeters, depth);

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
            var y = focusY +
                ((markerDepth - depth) * pixelsPerTenMeters / 1000);
            // World markers scroll through the whole viewport. Keep the center
            // just beyond the edge until the label and tick are fully clipped,
            // so they enter and leave through the bezel instead of popping at an
            // arbitrary inner boundary. HUD/status text is drawn later on top.
            var markerMargin = scaled(12);
            if (y < -markerMargin || y > height + markerMargin) {
                continue;
            }
            dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
            // A two-pixel tick survives MIP refreshes better than a single moving
            // pixel and reads as part of the line instead of background noise.
            dc.setPenWidth(scaled(2));
            dc.drawLine(cx - scaled(11), y, cx + scaled(11), y);
            dc.fillCircle(cx, y, scaled(2));
            // At the bottom the target marker and the right-side HUD show the
            // same number on the same row. Hide only that exact duplicate while
            // TAG & TURN is active; scrolling labels never blink elsewhere.
            var targetDistance = _model.getTargetDepthCm() - depth;
            var hideTargetDuplicate =
                markerDepth == _model.getTargetDepthCm() &&
                (state == DiveConstants.STATE_TURNING ||
                    state == DiveConstants.STATE_ASCENDING) &&
                targetDistance >= 0 && targetDistance <= 100;
            if (!hideTargetDuplicate) {
                dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx + scaled(18), y, Graphics.FONT_XTINY,
                    meters.format("%d") + "m",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        }

        var surfaceY = focusY - (depth * pixelsPerTenMeters / 1000);
        if (surfaceY > -scaled(30) && surfaceY < height + scaled(30)) {
            drawSurfaceAndBuoy(dc, cx, surfaceY);
        }

        var targetY = focusY +
            ((_model.getTargetDepthCm() - depth) * pixelsPerTenMeters / 1000);
        var showTag = state == DiveConstants.STATE_DESCENDING ||
            _model.getCueKind() == DiveConstants.CUE_TAG;
        if (showTag && targetY > -scaled(40) && targetY < height + scaled(40)) {
            drawTag(dc, cx, targetY);
        }
    }

    private function drawDepthLife(dc as Graphics.Dc, cx as Lang.Number,
            focusY as Lang.Number, pixelsPerTenMeters as Lang.Number,
            depth as Lang.Number) as Void {
        var state = _model.getState();
        if (_heroCarryEndTick > _heroTravelTick &&
                (state == DiveConstants.STATE_DUCK_DIVE ||
                state == DiveConstants.STATE_DESCENDING)) {
            var height = dc.getHeight();
            var heroWorldDepth = ((height * 71 / 100) -
                (height * 22 / 100)) * 1000 / pixelsPerTenMeters;
            var heroY = focusY +
                ((heroWorldDepth - depth) * pixelsPerTenMeters / 1000);
            if (heroY > -scaled(30) && heroY < height + scaled(30)) {
                drawCampaignHero(dc, _model.getTerritory(), heroY);
            }
        }

        // Each encounter crosses the background once during descent. Keeping them
        // off ascent prevents the same animal from visibly swimming backwards.
        if (state != DiveConstants.STATE_DESCENDING) {
            return;
        }

        var target = _model.getTargetDepthCm();
        var span = target * 18 / 100;
        if (span < 250) { span = 250; }
        if (span > 650) { span = 650; }
        var territory = _model.getTerritory();

        // Each species keeps its own beat, so the background never pulses in sync.
        var fish = strip(:fish, 4);
        var turtle = strip(:turtle, 8);
        var orca = strip(:orca, 6);
        if (territory == 0) {
            drawEncounter(dc, fish, focusY, pixelsPerTenMeters, depth,
                target * 24 / 100, span, true, 4);
            drawEncounter(dc, turtle, focusY, pixelsPerTenMeters, depth,
                target * 52 / 100, span, false, 8);
        } else if (territory == 1) {
            drawEncounter(dc, fish, focusY, pixelsPerTenMeters, depth,
                target * 24 / 100, span, true, 4);
            // The shallow campaign turtle has already crossed the opening
            // scene. Monad's signature thresher arrives later, closer to the
            // cleaning-station depths that make the Visayan Sea distinctive.
            drawEncounter(dc, strip(:thresher, 7), focusY,
                pixelsPerTenMeters, depth,
                target * 80 / 100, span, false, 7);
        } else if (territory == 2) {
            drawEncounter(dc, fish, focusY, pixelsPerTenMeters, depth,
                target * 24 / 100, span, true, 4);
            drawEncounter(dc, turtle, focusY, pixelsPerTenMeters, depth,
                target * 82 / 100, span, false, 8);
        } else if (territory == 3) {
            drawEncounter(dc, fish, focusY, pixelsPerTenMeters, depth,
                target * 24 / 100, span, true, 4);
            drawEncounter(dc, strip(:manta, 8), focusY,
                pixelsPerTenMeters, depth,
                target * 82 / 100, span, true, 7);
        } else {
            drawEncounter(dc, orca, focusY, pixelsPerTenMeters, depth,
                target * 58 / 100, span, true, 6);
        }
    }

    private function drawCampaignHero(dc as Graphics.Dc,
            territory as Lang.Number, y as Lang.Number) as Void {
        var animal = territoryHero(territory);
        var width = dc.getWidth();
        var phase = _heroTravelTick % HERO_TRAVEL_TICKS;
        var travel = width + animal.getWidth();
        var animalX = -animal.getWidth() +
            (phase * travel / (HERO_TRAVEL_TICKS - 1));
        if (!territoryHeroMovesRight(territory)) {
            animalX = width -
                (phase * travel / (HERO_TRAVEL_TICKS - 1));
        }
        var bob = ((_animationTick / heroBobPeriod(territory)) % 3) - 1;
        dc.drawBitmap(animalX,
            y - (animal.getHeight() / 2) + scaled(bob), animal);
    }

    private function territoryHeroMovesRight(territory as Lang.Number) as Lang.Boolean {
        return territory == 0 || territory == 2 || territory == 4;
    }

    private function heroBobPeriod(territory as Lang.Number) as Lang.Number {
        if (territory == 1) { return 8; }
        if (territory == 2) { return 7; }
        if (territory == 3) { return 6; }
        if (territory == 4) { return 5; }
        return 5;
    }

    private function territoryHero(territory as Lang.Number) as WatchUi.BitmapResource {
        if (territory == 1) { return strip(:turtle, 8); }
        if (territory == 2) { return strip(:manta, 8); }
        if (territory == 3) { return strip(:hammerhead, 6); }
        if (territory == 4) { return strip(:narwhal, 6); }
        return strip(:seaLion, 5);
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

    private function diveFocusY(height as Lang.Number,
            pixelsPerTenMeters as Lang.Number,
            depth as Lang.Number) as Lang.Number {
        var focusY = height * 22 / 100 +
            (depth * pixelsPerTenMeters / 1000);
        if (focusY > height / 2) {
            focusY = height / 2;
        }
        return focusY;
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

        var buoy = bitmap(:buoy);
        var buoyPhase = (_animationTick / 3) % 4;
        var buoyBob = 0;
        if (buoyPhase == 1) { buoyBob = -scaled(1); }
        if (buoyPhase == 3) { buoyBob = scaled(1); }
        dc.drawBitmap(cx - (buoy.getWidth() / 2),
            y - (buoy.getHeight() * 74 / 100) + buoyBob, buoy);

        if (_model.getTerritory() == 4 &&
                _model.getState() != DiveConstants.STATE_MENU) {
            drawArcticIce(dc, y);
        }
    }

    private function drawArcticIce(dc as Graphics.Dc, y as Lang.Number) as Void {
        var width = dc.getWidth();
        // Keep the diver's left-side launch lane completely open. The single
        // Arctic floe enters fully from the right over the selection transition.
        var slide = scaled(_iceTransitionTicks * 14);
        var right = width + slide;
        // Surface wildlife promised on the level card stays on the same floe
        // when the dive begins, then scrolls naturally out with the waterline.
        var showBear = _model.getSelectedLevel() == 14;
        var showSeal = _model.getSelectedLevel() == 13;

        if (showBear) {
            // The asset already includes its own floe; adding code-drawn ice
            // underneath produced the visible "floe on another floe" bug.
            var bear = strip(:polarBear, 10);
            var bearX = right - scaled(82);
            var bearY = y - (bear.getHeight() * 82 / 100);
            dc.drawBitmap(bearX, bearY, bear);
        } else if (showSeal) {
            var seal = strip(:ringedSeal, 8);
            var sealX = right - scaled(70);
            var sealY = y - (seal.getHeight() * 75 / 100);
            dc.drawBitmap(sealX, sealY, seal);
        } else {
            // The first Arctic level has scenery only, so it gets one clean
            // code-drawn floe on the same right-hand trajectory.
            dc.setColor(isAmoled() ? 0x77BED1 : 0x5588AA,
                Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([
                [right + scaled(16), y],
                [right - scaled(96), y + scaled(1)],
                [right - scaled(84), y + scaled(13)],
                [right - scaled(7), y + scaled(11)]
            ]);

            dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
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
                [right - scaled(20), y - scaled(7)],
                [right - scaled(44), y - scaled(12)],
                [right - scaled(69), y - scaled(7)],
                [right - scaled(35), y - scaled(4)]
            ]);
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

        if (cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE ||
                cue == DiveConstants.CUE_TAG) {
            var cueAge = _model.getCueAge();
            var level = _model.getSelectedLevel();
            var perfectStart = Campaign.perfectStart(level);
            var perfectEnd = Campaign.perfectEnd(level);
            var inWindow = cueAge >= perfectStart && cueAge <= perfectEnd;

            // The ring is driven by the scoring window itself: it lands on the
            // target band exactly at the last perfect tick and keeps collapsing
            // afterwards, so "ring on the circle" always means "press now".
            var movingRadius = scaled(126 - ((126 - 72) * cueAge / perfectEnd));
            if (cueAge > perfectEnd) {
                movingRadius = scaled(72 - ((cueAge - perfectEnd) * 10));
                if (movingRadius < scaled(30)) {
                    movingRadius = scaled(30);
                }
            }

            dc.setColor(inWindow ? COLOR_GOOD : COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(scaled(1));
            dc.drawCircle(cx, cy, scaled(70));
            dc.drawCircle(cx, cy, scaled(74));
            var ringColor = COLOR_FOAM;
            if (inWindow) {
                ringColor = COLOR_GOOD;
            } else if (cueAge > perfectEnd) {
                ringColor = COLOR_LINE;
            }
            dc.setColor(ringColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(scaled(2));
            dc.drawCircle(cx, cy, movingRadius);
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

    private function drawHud(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var depthMeters = _model.getDepthCm() / 100.0;

        var hudY = height / 2;
        var depthX = width * 94 / 100;
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(depthX, hudY, Graphics.FONT_SMALL,
            depthMeters.format("%.1f") + "m",
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        var radius = (width < height ? width : height) * 44 / 100;
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scaled(6));
        dc.drawArc(width / 2, height / 2, radius,
            Graphics.ARC_COUNTER_CLOCKWISE, 135, 225);

        var flow = _model.getFlow();
        var flowColor = _model.getFlow() > 35 ? COLOR_GOOD : COLOR_BAD;
        if (flow > 0) {
            var fillStart = 225 - (90 * flow / 100);
            dc.setColor(flowColor, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(width / 2, height / 2, radius,
                Graphics.ARC_COUNTER_CLOCKWISE, fillStart, 225);
        }

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
                _feedbackEvent == DiveConstants.EVENT_GLIDE_PENALTY ||
                _feedbackEvent == DiveConstants.EVENT_TAG_MISS) {
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

        // Pause is a calm full-screen state. A single flat ocean color avoids
        // the dark inner circle that looked like a second display bezel.
        dc.setColor(isAmoled() ? COLOR_DEEP_HIGH : COLOR_MIP_DEEP,
            Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height);

        dc.setColor(COLOR_FOAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 30 / 100, Graphics.FONT_MEDIUM, "PAUSED",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawPauseOption(dc, 0, height * 52 / 100, "RESUME", true);
        drawPauseOption(dc, 1, height * 70 / 100, "MAIN MENU", false);
    }

    private function drawPauseOption(dc as Graphics.Dc, index as Lang.Number,
            y as Lang.Number, label as Lang.String,
            showPlay as Lang.Boolean) as Void {
        var selected = index == _pauseSelection;
        var color = selected ? COLOR_FOAM : COLOR_DIM;
        if (showPlay) {
            drawPlayAction(dc, _screenWidth / 2, y, label, color);
        } else {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_screenWidth / 2, y, Graphics.FONT_SMALL, label,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        if (selected) {
            var halfWidth = dc.getTextWidthInPixels(label, Graphics.FONT_SMALL) / 2;
            if (showPlay) { halfWidth += scaled(8); }
            var gap = scaled(12);
            var lineWidth = scaled(13);
            dc.setPenWidth(scaled(2));
            dc.drawLine(_screenWidth / 2 - halfWidth - gap - lineWidth, y,
                _screenWidth / 2 - halfWidth - gap, y);
            dc.drawLine(_screenWidth / 2 + halfWidth + gap, y,
                _screenWidth / 2 + halfWidth + gap + lineWidth, y);
        }
    }

    private function drawResult(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var level = _model.getSelectedLevel();
        drawSurfaceAndBuoy(dc, cx, height * 18 / 100);
        var resultLabel = "SAFE TURN";
        if (_model.isRunSuccessful()) {
            resultLabel = "SURFACED";
        } else if (_model.getMaxDepthCm() >= _model.getTargetDepthCm()) {
            if (!_model.didTakeTag()) {
                resultLabel = "NO TAG";
            } else if (!_model.didCompleteTurn()) {
                resultLabel = "NO TURN";
            } else {
                resultLabel = "LOW FLOW";
            }
        }

        // Three compact groups with deliberate whitespace between them:
        // outcome, depth + medals, score + best.
        var resultOffsetY = scaled(4);
        var outcomeY = height * 27 / 100 + resultOffsetY;
        var depthY = height * 48 / 100 + resultOffsetY;
        var medalsY = height * 58 / 100 + resultOffsetY;
        var scoreY = height * 71 / 100 + resultOffsetY;
        var bestY = height * 79 / 100 + resultOffsetY;
        var resultColor = _model.isRunSuccessful() ? COLOR_GOOD : COLOR_LINE;
        dc.setColor(resultColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, outcomeY, Graphics.FONT_SMALL, resultLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, depthY, Graphics.FONT_MEDIUM,
            (_model.getMaxDepthCm() / 100.0).format("%.1f") + "m",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        drawMedals(dc, cx, medalsY, _model.getRunMedal());
        // drawMedals leaves the last empty star in COLOR_DIM. Restore the text
        // color explicitly so SCORE cannot inherit an almost invisible teal.
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, scoreY, Graphics.FONT_SMALL,
            "SCORE " + _model.getScore().format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_LINE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, bestY, Graphics.FONT_XTINY,
            "BEST " + _model.getSelectedBestScore().format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var actionY = height / 2 + resultOffsetY;
        var resultLabelOffset = -scaled(2);
        drawResultAction(dc, width * 16 / 100, actionY, "MAP",
            resultLabelOffset);
        var primary = level < _model.getUnlockedLevel() ? "NEXT" : "RETRY";
        drawResultAction(dc, width * 84 / 100, actionY, primary,
            resultLabelOffset);
    }

    private function drawTag(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number) as Void {
        var tag = bitmap(:tag);
        var tagPhase = (_animationTick / 3) % 4;
        var tagSway = 0;
        if (tagPhase == 1) { tagSway = -scaled(1); }
        if (tagPhase == 3) { tagSway = scaled(1); }
        dc.drawBitmap(x - (tag.getWidth() / 2) + tagSway,
            y - (tag.getHeight() * 72 / 100), tag);
    }

    private function drawResultAction(dc as Graphics.Dc, cx as Lang.Number,
            cy as Lang.Number, label as Lang.String,
            textOffsetY as Lang.Number) as Void {
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + textOffsetY, Graphics.FONT_XTINY, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawPlainAction(dc as Graphics.Dc, cx as Lang.Number,
            cy as Lang.Number, label as Lang.String, color as Lang.Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_SMALL, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawPlayAction(dc as Graphics.Dc, cx as Lang.Number,
            cy as Lang.Number, label as Lang.String, color as Lang.Number) as Void {
        var textWidth = dc.getTextWidthInPixels(label, Graphics.FONT_SMALL);
        var gap = scaled(7);
        var iconWidth = scaled(7);
        var groupWidth = textWidth + gap + iconWidth;
        var textCenter = cx - (groupWidth - textWidth) / 2;
        var iconLeft = textCenter + textWidth / 2 + gap;
        var iconHalfHeight = scaled(5);

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textCenter, cy, Graphics.FONT_SMALL, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.fillPolygon([
            [iconLeft, cy - iconHalfHeight],
            [iconLeft + iconWidth, cy],
            [iconLeft, cy + iconHalfHeight]
        ]);
    }

    private function cueLabel(cue as Lang.Number) as Lang.String {
        if (cue == DiveConstants.CUE_EQUALIZE) { return "EQUALIZE"; }
        if (cue == DiveConstants.CUE_TAG) { return "TAG & TURN"; }
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
        if (event == DiveConstants.EVENT_TAG_MISS) { return "NO TAG"; }
        if (event == DiveConstants.EVENT_GLIDE_PENALTY) { return "STAY CALM"; }
        return "";
    }

    private function scaled(value as Lang.Number) as Lang.Number {
        var result = value * _screenWidth / REFERENCE_WIDTH;
        // Integer scaling turns a one-pixel MIP stroke into zero below the
        // 280 px reference width. Garmin rejects setPenWidth(0), so every
        // positive design-space value must retain at least one physical pixel.
        if (value > 0 && result < 1) { return 1; }
        return result;
    }

    // One bitmap for a still asset, a two-frame strip for anything that moves.
    private function bitmap(key as Lang.Symbol) as WatchUi.BitmapResource {
        return _art[key] as WatchUi.BitmapResource;
    }

    private function strip(key as Lang.Symbol, period as Lang.Number) as WatchUi.BitmapResource {
        var frames = _art[key] as Lang.Array<WatchUi.BitmapResource>;
        return frames[(_animationTick / period) % 2];
    }

    private function mipOceanBackground() as WatchUi.BitmapResource {
        var territory = _model.getTerritory();
        if (_mipOceanTerritory != territory) {
            if (territory == 1) {
                _mipOceanBackground = WatchUi.loadResource(
                    $.Rez.Drawables.OceanGradientVisayanSeaMip) as WatchUi.BitmapResource;
            } else if (territory == 2) {
                _mipOceanBackground = WatchUi.loadResource(
                    $.Rez.Drawables.OceanGradientRedSeaMip) as WatchUi.BitmapResource;
            } else if (territory == 3) {
                _mipOceanBackground = WatchUi.loadResource(
                    $.Rez.Drawables.OceanGradientAtlanticMip) as WatchUi.BitmapResource;
            } else if (territory == 4) {
                _mipOceanBackground = WatchUi.loadResource(
                    $.Rez.Drawables.OceanGradientGreenlandSeaMip) as WatchUi.BitmapResource;
            } else {
                _mipOceanBackground = WatchUi.loadResource(
                    $.Rez.Drawables.OceanGradientSeaOfCortezMip) as WatchUi.BitmapResource;
            }
            _mipOceanTerritory = territory;
        }
        return _mipOceanBackground as WatchUi.BitmapResource;
    }

    private function loadArt() as Void {
        var amoled = isAmoled();
        if (_framesLoaded && _loadedAmoled == amoled) {
            return;
        }

        // Only the current display's set is loaded, so the other palette never
        // occupies memory on the watch.
        _art = amoled ? amoledArt() : mipArt();

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
        _mipOceanTerritory = -1;
        _framesLoaded = true;
    }

    private function amoledArt() as Lang.Dictionary {
        return {
            :buoy => WatchUi.loadResource($.Rez.Drawables.BuoyAmoled),
            :title => WatchUi.loadResource($.Rez.Drawables.DeepLineTitleAmoled),
            :tag => WatchUi.loadResource($.Rez.Drawables.TagAmoled),
            :polarBear => [
                WatchUi.loadResource($.Rez.Drawables.PolarBearFloeAmoled),
                WatchUi.loadResource($.Rez.Drawables.PolarBearFloe1Amoled)
            ],
            :ringedSeal => [
                WatchUi.loadResource($.Rez.Drawables.RingedSealFloeAmoled),
                WatchUi.loadResource($.Rez.Drawables.RingedSealFloe1Amoled)
            ],
            :fish => [
                WatchUi.loadResource($.Rez.Drawables.FishSchoolAmoled),
                WatchUi.loadResource($.Rez.Drawables.FishSchool1Amoled)
            ],
            :turtle => [
                WatchUi.loadResource($.Rez.Drawables.GreenTurtleAmoled),
                WatchUi.loadResource($.Rez.Drawables.GreenTurtle1Amoled)
            ],
            :orca => [
                WatchUi.loadResource($.Rez.Drawables.OrcaAmoled),
                WatchUi.loadResource($.Rez.Drawables.Orca1Amoled)
            ],
            :seaLion => [
                WatchUi.loadResource($.Rez.Drawables.SeaLionAmoled),
                WatchUi.loadResource($.Rez.Drawables.SeaLion1Amoled)
            ],
            :thresher => [
                WatchUi.loadResource($.Rez.Drawables.ThresherSharkAmoled),
                WatchUi.loadResource($.Rez.Drawables.ThresherShark1Amoled)
            ],
            :manta => [
                WatchUi.loadResource($.Rez.Drawables.MantaRayAmoled),
                WatchUi.loadResource($.Rez.Drawables.MantaRay1Amoled)
            ],
            :hammerhead => [
                WatchUi.loadResource($.Rez.Drawables.HammerheadSharkAmoled),
                WatchUi.loadResource($.Rez.Drawables.HammerheadShark1Amoled)
            ],
            :narwhal => [
                WatchUi.loadResource($.Rez.Drawables.NarwhalAmoled),
                WatchUi.loadResource($.Rez.Drawables.Narwhal1Amoled)
            ]
        };
    }

    private function mipArt() as Lang.Dictionary {
        return {
            :buoy => WatchUi.loadResource($.Rez.Drawables.BuoyMip),
            :title => WatchUi.loadResource($.Rez.Drawables.DeepLineTitleMip),
            :tag => WatchUi.loadResource($.Rez.Drawables.TagMip),
            :polarBear => [
                WatchUi.loadResource($.Rez.Drawables.PolarBearFloeMip),
                WatchUi.loadResource($.Rez.Drawables.PolarBearFloe1Mip)
            ],
            :ringedSeal => [
                WatchUi.loadResource($.Rez.Drawables.RingedSealFloeMip),
                WatchUi.loadResource($.Rez.Drawables.RingedSealFloe1Mip)
            ],
            :fish => [
                WatchUi.loadResource($.Rez.Drawables.FishSchoolMip),
                WatchUi.loadResource($.Rez.Drawables.FishSchool1Mip)
            ],
            :turtle => [
                WatchUi.loadResource($.Rez.Drawables.GreenTurtleMip),
                WatchUi.loadResource($.Rez.Drawables.GreenTurtle1Mip)
            ],
            :orca => [
                WatchUi.loadResource($.Rez.Drawables.OrcaMip),
                WatchUi.loadResource($.Rez.Drawables.Orca1Mip)
            ],
            :seaLion => [
                WatchUi.loadResource($.Rez.Drawables.SeaLionMip),
                WatchUi.loadResource($.Rez.Drawables.SeaLion1Mip)
            ],
            :thresher => [
                WatchUi.loadResource($.Rez.Drawables.ThresherSharkMip),
                WatchUi.loadResource($.Rez.Drawables.ThresherShark1Mip)
            ],
            :manta => [
                WatchUi.loadResource($.Rez.Drawables.MantaRayMip),
                WatchUi.loadResource($.Rez.Drawables.MantaRay1Mip)
            ],
            :hammerhead => [
                WatchUi.loadResource($.Rez.Drawables.HammerheadSharkMip),
                WatchUi.loadResource($.Rez.Drawables.HammerheadShark1Mip)
            ],
            :narwhal => [
                WatchUi.loadResource($.Rez.Drawables.NarwhalMip),
                WatchUi.loadResource($.Rez.Drawables.Narwhal1Mip)
            ]
        };
    }

    // Screen width used to stand in for display type. That held only by accident
    // for the first two devices: Garmin ships both MIP and AMOLED variants of the
    // same case size, so a wide MIP watch would have picked the AMOLED palette.
    // Burn-in protection is the documented AMOLED signal. Resolved once — this is
    // read dozens of times per frame by the palette helpers.
    private function isAmoled() as Lang.Boolean {
        if (!_displayResolved) {
            var settings = System.getDeviceSettings();
            if (settings has :requiresBurnInProtection) {
                _amoled = settings.requiresBurnInProtection;
            } else {
                // Pre-3.1 devices predate the flag and are all MIP.
                _amoled = false;
            }
            _displayResolved = true;
        }
        return _amoled;
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
