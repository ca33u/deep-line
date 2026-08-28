using Toybox.Application;
using Toybox.Lang;

module DiveConstants {
    const STATE_MENU = 0;
    const STATE_DESCENDING = 1;
    const STATE_TURNING = 2;
    const STATE_ASCENDING = 3;
    const STATE_PAUSED = 4;
    const STATE_RESULT = 5;
    const STATE_SURFACING = 6;
    const STATE_DUCK_DIVE = 7;
    const STATE_LEVEL_SELECT = 8;

    const CUE_NONE = 0;
    const CUE_EQUALIZE = 1;
    const CUE_TAG = 2;
    const CUE_STROKE = 3;
    const CUE_GLIDE = 4;

    const EVENT_NONE = 0;
    const EVENT_CUE = 1;
    const EVENT_PERFECT = 2;
    const EVENT_GOOD = 3;
    const EVENT_MISS = 4;
    const EVENT_WAIT = 5;
    const EVENT_TURN_READY = 6;
    const EVENT_GLIDE_STARTED = 8;
    const EVENT_GLIDE_PENALTY = 9;
    const EVENT_SURFACED = 10;
    const EVENT_SURFACE_REACHED = 12;
    const EVENT_DUCKED = 13;
    const EVENT_TAG_MISS = 14;

    const MAX_FLOW = 100;
}

class DiveModel {
    private var _state as Lang.Number = DiveConstants.STATE_MENU;
    private var _stateBeforePause as Lang.Number = DiveConstants.STATE_MENU;
    private var _depthCm as Lang.Number = 0;
    private var _maxDepthCm as Lang.Number = 0;
    private var _flow as Lang.Number = DiveConstants.MAX_FLOW;
    private var _score as Lang.Number = 0;
    private var _bestScore as Lang.Number = 0;
    private var _persistedBestScore as Lang.Number = 0;
    private var _perfectCount as Lang.Number = 0;
    private var _goodCount as Lang.Number = 0;
    private var _missCount as Lang.Number = 0;
    private var _combo as Lang.Number = 0;
    private var _cueKind as Lang.Number = DiveConstants.CUE_NONE;
    private var _cueAge as Lang.Number = 0;
    private var _nextDescentCue as Lang.Number = 0;
    private var _nextAscentCue as Lang.Number = 0;
    private var _strokeBoostTicks as Lang.Number = 0;
    private var _surfaceAge as Lang.Number = 0;
    private var _duckAge as Lang.Number = 0;
    private var _targetReached as Lang.Boolean = false;
    private var _tagTaken as Lang.Boolean = false;
    private var _turnCompleted as Lang.Boolean = false;
    private var _ascentFailed as Lang.Boolean = false;
    private var _selectedLevel as Lang.Number = 0;
    private var _persistedSelectedLevel as Lang.Number = -1;
    private var _unlockedLevel as Lang.Number = 0;
    private var _targetDepthCm as Lang.Number = 1000;
    private var _runMedal as Lang.Number = 0;
    private var _bestScores as Lang.Array<Lang.Number> = [];
    private var _medals as Lang.Array<Lang.Number> = [];
    private var _equalizeDepths as Lang.Array<Lang.Number> = [];
    private var _strokeDepths as Lang.Array<Lang.Number> = [];

    function initialize() {
        // v1 progression used a different scoring model and unlocked levels after
        // an incomplete bottom turn. Keep those keys untouched for recovery, but
        // never let them bypass the corrected campaign rules.
        var saved = Application.Storage.getValue("bestScoreV2");
        if (saved instanceof Lang.Number) {
            _bestScore = saved < 0 ? 0 : saved;
        }
        _persistedBestScore = _bestScore;
        loadCampaign();
        configureLevel();
    }

    function openCampaign() as Void {
        if (_state == DiveConstants.STATE_MENU || _state == DiveConstants.STATE_RESULT) {
            _state = DiveConstants.STATE_LEVEL_SELECT;
        }
    }

    function returnToMenu() as Void {
        if (_state == DiveConstants.STATE_LEVEL_SELECT ||
                _state == DiveConstants.STATE_PAUSED) {
            _state = DiveConstants.STATE_MENU;
        }
    }

    function moveSelection(delta as Lang.Number) as Void {
        if (_state != DiveConstants.STATE_LEVEL_SELECT) {
            return;
        }
        var next = _selectedLevel + delta;
        if (next < 0) { next = 0; }
        if (next >= Campaign.LEVEL_COUNT) { next = Campaign.LEVEL_COUNT - 1; }
        _selectedLevel = next;
        configureLevel();
    }

    function startNextOrRetry() as Void {
        if (_state == DiveConstants.STATE_RESULT && _selectedLevel < _unlockedLevel) {
            _selectedLevel += 1;
            configureLevel();
        }
        startGame();
    }

    function startGame() as Void {
        if (_state == DiveConstants.STATE_LEVEL_SELECT &&
                _selectedLevel > _unlockedLevel) {
            return;
        }
        _state = DiveConstants.STATE_DUCK_DIVE;
        _stateBeforePause = DiveConstants.STATE_DUCK_DIVE;
        _depthCm = 0;
        _maxDepthCm = 0;
        _flow = DiveConstants.MAX_FLOW;
        _score = 0;
        _perfectCount = 0;
        _goodCount = 0;
        _missCount = 0;
        _combo = 0;
        _cueKind = DiveConstants.CUE_NONE;
        _cueAge = 0;
        _nextDescentCue = 0;
        _nextAscentCue = 0;
        _strokeBoostTicks = 0;
        _surfaceAge = 0;
        _duckAge = 0;
        _targetReached = false;
        _tagTaken = false;
        _turnCompleted = false;
        _ascentFailed = false;
        _runMedal = 0;
        configureLevel();
        saveProgress();
    }

    function togglePause() as Void {
        if (_state == DiveConstants.STATE_PAUSED) {
            _state = _stateBeforePause;
            return;
        }
        if (isDiveActive()) {
            _stateBeforePause = _state;
            _state = DiveConstants.STATE_PAUSED;
        }
    }

    function advance() as Lang.Number {
        if (_state == DiveConstants.STATE_DESCENDING) {
            return advanceDescent();
        }
        if (_state == DiveConstants.STATE_TURNING) {
            return advanceTurn();
        }
        if (_state == DiveConstants.STATE_ASCENDING) {
            return advanceAscent();
        }
        if (_state == DiveConstants.STATE_SURFACING) {
            return advanceSurfacing();
        }
        if (_state == DiveConstants.STATE_DUCK_DIVE) {
            return advanceDuckDive();
        }
        return DiveConstants.EVENT_NONE;
    }

    function action() as Lang.Number {
        if (_state == DiveConstants.STATE_DUCK_DIVE) {
            return DiveConstants.EVENT_NONE;
        }
        if (_state == DiveConstants.STATE_DESCENDING) {
            if (_cueKind == DiveConstants.CUE_EQUALIZE) {
                return resolveCue(100, 60, 2);
            }
            applyMiss(3);
            if (_flow <= 0) {
                beginAscent(false);
            }
            return DiveConstants.EVENT_WAIT;
        }

        if (_state == DiveConstants.STATE_TURNING) {
            if (_cueKind == DiveConstants.CUE_TAG) {
                var result = resolveCue(150, 80, 3);
                _tagTaken = true;
                _turnCompleted = true;
                return result;
            }
            return DiveConstants.EVENT_WAIT;
        }

        if (_state == DiveConstants.STATE_ASCENDING) {
            if (_cueKind == DiveConstants.CUE_STROKE) {
                var result = resolveCue(90, 50, 2);
                _strokeBoostTicks = (result == DiveConstants.EVENT_PERFECT) ? 5 : 3;
                return result;
            }
            if (_cueKind == DiveConstants.CUE_GLIDE) {
                applyMiss(4);
                return DiveConstants.EVENT_GLIDE_PENALTY;
            }
            applyMiss(2);
            return DiveConstants.EVENT_WAIT;
        }

        return DiveConstants.EVENT_NONE;
    }

    private function advanceDescent() as Lang.Number {
        _depthCm += Campaign.descentSpeedCm(_selectedLevel);
        if (_depthCm > _maxDepthCm) {
            _maxDepthCm = _depthCm;
        }

        if (_cueKind == DiveConstants.CUE_EQUALIZE) {
            _cueAge += 1;
            if (_cueAge > Campaign.cueDeadline(_selectedLevel)) {
                _cueKind = DiveConstants.CUE_NONE;
                applyMiss(Campaign.missCost(_selectedLevel));
                if (_flow <= 0) {
                    beginAscent(false);
                }
                return DiveConstants.EVENT_MISS;
            }
        }

        if (_cueKind == DiveConstants.CUE_NONE && _nextDescentCue < _equalizeDepths.size() &&
                _depthCm >= _equalizeDepths[_nextDescentCue]) {
            _nextDescentCue += 1;
            _cueKind = DiveConstants.CUE_EQUALIZE;
            _cueAge = 0;
            return DiveConstants.EVENT_CUE;
        }

        if (_depthCm >= _targetDepthCm) {
            _depthCm = _targetDepthCm;
            _maxDepthCm = _targetDepthCm;
            _cueKind = DiveConstants.CUE_TAG;
            _cueAge = 0;
            _state = DiveConstants.STATE_TURNING;
            return DiveConstants.EVENT_TURN_READY;
        }

        return DiveConstants.EVENT_NONE;
    }

    private function advanceTurn() as Lang.Number {
        _cueAge += 1;
        if (_turnCompleted) {
            // Keep the state briefly so the complete pivot animation is visible
            // after the single successful TAG & TURN action.
            if (_cueAge >= 5) {
                beginAscent(true);
            }
            return DiveConstants.EVENT_NONE;
        }
        if (_cueAge > Campaign.cueDeadline(_selectedLevel)) {
            applyMiss(10);
            beginAscent(false);
            return DiveConstants.EVENT_TAG_MISS;
        }
        return DiveConstants.EVENT_NONE;
    }

    private function advanceAscent() as Lang.Number {
        var speed = Campaign.ascentSpeedCm(_selectedLevel);
        if (_depthCm <= 300) {
            speed = 6;
        }
        if (_depthCm <= 100) {
            speed = 3;
        }
        if (_strokeBoostTicks > 0) {
            speed += 4;
            _strokeBoostTicks -= 1;
        }
        _depthCm -= speed;

        if (_depthCm <= 0) {
            _depthCm = 0;
            _state = DiveConstants.STATE_SURFACING;
            _cueKind = DiveConstants.CUE_NONE;
            _surfaceAge = 0;
            return DiveConstants.EVENT_SURFACE_REACHED;
        }

        if (_cueKind == DiveConstants.CUE_STROKE) {
            _cueAge += 1;
            if (_cueAge > Campaign.cueDeadline(_selectedLevel)) {
                _cueKind = DiveConstants.CUE_NONE;
                applyMiss(Campaign.missCost(_selectedLevel) - 2);
                return DiveConstants.EVENT_MISS;
            }
        }

        if (_depthCm <= 300) {
            if (_cueKind != DiveConstants.CUE_GLIDE) {
                _cueKind = DiveConstants.CUE_GLIDE;
                _cueAge = 0;
                return DiveConstants.EVENT_GLIDE_STARTED;
            }
            return DiveConstants.EVENT_NONE;
        }

        if (_cueKind == DiveConstants.CUE_NONE && _nextAscentCue < _strokeDepths.size() &&
                _depthCm <= _strokeDepths[_nextAscentCue]) {
            _nextAscentCue += 1;
            _cueKind = DiveConstants.CUE_STROKE;
            _cueAge = 0;
            return DiveConstants.EVENT_CUE;
        }

        return DiveConstants.EVENT_NONE;
    }

    private function advanceSurfacing() as Lang.Number {
        _surfaceAge += 1;
        if (_surfaceAge >= 10) {
            finishRun();
            return DiveConstants.EVENT_SURFACED;
        }
        return DiveConstants.EVENT_NONE;
    }

    private function advanceDuckDive() as Lang.Number {
        _duckAge += 1;
        if (_duckAge >= 12) {
            _state = DiveConstants.STATE_DESCENDING;
            _stateBeforePause = DiveConstants.STATE_DESCENDING;
            return DiveConstants.EVENT_DUCKED;
        }
        return DiveConstants.EVENT_NONE;
    }

    private function resolveCue(perfectPoints as Lang.Number, goodPoints as Lang.Number,
            flowGain as Lang.Number) as Lang.Number {
        var age = _cueAge;
        _cueKind = DiveConstants.CUE_NONE;
        _cueAge = 0;
        if (age >= Campaign.perfectStart(_selectedLevel) &&
                age <= Campaign.perfectEnd(_selectedLevel)) {
            awardPerfect(perfectPoints, flowGain);
            return DiveConstants.EVENT_PERFECT;
        }
        awardGood(goodPoints);
        return DiveConstants.EVENT_GOOD;
    }

    private function awardPerfect(points as Lang.Number, flowGain as Lang.Number) as Void {
        _perfectCount += 1;
        _combo += 1;
        _score += points + (_combo * 5);
        _flow += flowGain;
        if (_flow > DiveConstants.MAX_FLOW) {
            _flow = DiveConstants.MAX_FLOW;
        }
    }

    private function awardGood(points as Lang.Number) as Void {
        _goodCount += 1;
        _combo += 1;
        _score += points;
    }

    private function applyMiss(flowCost as Lang.Number) as Void {
        _missCount += 1;
        _combo = 0;
        _flow -= flowCost;
        if (_flow < 0) {
            _flow = 0;
        }
        if (_flow == 0 && _state == DiveConstants.STATE_ASCENDING) {
            _ascentFailed = true;
        }
    }

    private function beginAscent(reachedTarget as Lang.Boolean) as Void {
        _targetReached = reachedTarget;
        _state = DiveConstants.STATE_ASCENDING;
        _cueKind = DiveConstants.CUE_NONE;
        _cueAge = 0;
        _strokeBoostTicks = 0;

        // Skip the kick cues the diver is already above. An early turn used to
        // fire every deeper cue back to back the moment the ascent began, which
        // punished a dive that had just been penalised.
        _nextAscentCue = 0;
        while (_nextAscentCue < _strokeDepths.size() &&
                _depthCm <= _strokeDepths[_nextAscentCue]) {
            _nextAscentCue += 1;
        }
    }

    private function finishRun() as Void {
        _state = DiveConstants.STATE_RESULT;
        _cueKind = DiveConstants.CUE_NONE;
        // Depth alone used to dwarf every timing point. Scaling the depth bonus
        // by accuracy keeps a clean dive worth replaying for.
        var cues = _perfectCount + _goodCount + _missCount;
        var accuracy = cues > 0 ? (_perfectCount * 100 / cues) : 0;
        var depthBonus = (_maxDepthCm / 2) * (50 + accuracy) / 150;
        _score += depthBonus + (_flow * 5) + (_selectedLevel * 100);
        _runMedal = calculateMedal();
        if (isRunSuccessful()) {
            if (_score > _bestScore) {
                _bestScore = _score;
            }
            if (_score > _bestScores[_selectedLevel]) {
                _bestScores[_selectedLevel] = _score;
                Application.Storage.setValue(levelKey("levelBestV2", _selectedLevel), _score);
            }
            if (_runMedal > _medals[_selectedLevel]) {
                _medals[_selectedLevel] = _runMedal;
                Application.Storage.setValue(levelKey("levelMedalV2", _selectedLevel), _runMedal);
            }
        }
        // One-star completion proves the route but not its timing. Campaign
        // progression starts at two stars so the rhythm cannot be bypassed by
        // answering every cue immediately.
        if (_runMedal >= 2 && _selectedLevel == _unlockedLevel &&
                _unlockedLevel < Campaign.LEVEL_COUNT - 1) {
            _unlockedLevel += 1;
            Application.Storage.setValue("unlockedLevelV2", _unlockedLevel);
        }
        saveBestScore();
    }

    private function calculateMedal() as Lang.Number {
        if (!isRunSuccessful()) { return 0; }
        var cues = _perfectCount + _goodCount + _missCount;
        var perfectPercent = cues > 0 ? (_perfectCount * 100 / cues) : 0;
        var medal = 1;
        if (_flow >= 50 && _missCount <= 2 && perfectPercent >= 40) { medal = 2; }
        if (_flow >= 75 && _missCount <= 1 && perfectPercent >= 75) { medal = 3; }
        return medal;
    }

    function isRunSuccessful() as Lang.Boolean {
        return _targetReached && _tagTaken && _turnCompleted &&
            !_ascentFailed && _flow > 0;
    }

    private function loadCampaign() as Void {
        for (var index = 0; index < Campaign.LEVEL_COUNT; index += 1) {
            var savedLevelBest = Application.Storage.getValue(levelKey("levelBestV2", index));
            var savedMedal = Application.Storage.getValue(levelKey("levelMedalV2", index));
            var levelBest = savedLevelBest instanceof Lang.Number ? savedLevelBest : 0;
            var medal = savedMedal instanceof Lang.Number ? savedMedal : 0;
            if (levelBest < 0) { levelBest = 0; }
            if (medal < 0) { medal = 0; }
            if (medal > 3) { medal = 3; }
            _bestScores.add(levelBest);
            _medals.add(medal);
        }

        var savedUnlocked = Application.Storage.getValue("unlockedLevelV2");
        if (savedUnlocked instanceof Lang.Number) {
            _unlockedLevel = savedUnlocked;
        }
        if (_unlockedLevel < 0) { _unlockedLevel = 0; }
        if (_unlockedLevel >= Campaign.LEVEL_COUNT) {
            _unlockedLevel = Campaign.LEVEL_COUNT - 1;
        }

        var savedSelected = Application.Storage.getValue("selectedLevelV2");
        if (savedSelected instanceof Lang.Number) {
            _selectedLevel = savedSelected;
        } else {
            _selectedLevel = _unlockedLevel;
        }
        if (_selectedLevel > _unlockedLevel) { _selectedLevel = _unlockedLevel; }
        if (_selectedLevel < 0) { _selectedLevel = 0; }
        _persistedSelectedLevel = _selectedLevel;
    }

    private function configureLevel() as Void {
        _targetDepthCm = Campaign.depthCm(_selectedLevel);
        _equalizeDepths = [];
        _strokeDepths = [];

        // Equalization is front-loaded: cues crowd the first metres and thin out
        // toward the bottom, so a descent has a shape instead of a metronome.
        var equalizeCount = Campaign.equalizeCount(_selectedLevel);
        var equalizeSpan = (equalizeCount + 1) * (equalizeCount + 1) * 2;
        for (var equalizeIndex = 1; equalizeIndex <= equalizeCount;
                equalizeIndex += 1) {
            var shaped = equalizeIndex * (equalizeIndex + equalizeCount + 1);
            _equalizeDepths.add(_targetDepthCm * shaped / equalizeSpan);
        }

        // Kick cues stay above the calm glide so every promised cue can fire.
        var strokeCount = Campaign.strokeCount(_selectedLevel);
        var strokeSpan = _targetDepthCm - Campaign.STROKE_FLOOR_CM;
        if (strokeSpan > 0) {
            for (var strokeIndex = 1; strokeIndex <= strokeCount; strokeIndex += 1) {
                _strokeDepths.add(_targetDepthCm -
                    (strokeSpan * strokeIndex / (strokeCount + 1)));
            }
        }
    }

    private function levelKey(prefix as Lang.String, level as Lang.Number) as Lang.String {
        return prefix + level.format("%d");
    }

    // Progress reaches flash when a run starts or the app leaves, never on every
    // press of the level browser.
    function saveProgress() as Void {
        saveBestScore();
        if (_selectedLevel != _persistedSelectedLevel) {
            Application.Storage.setValue("selectedLevelV2", _selectedLevel);
            _persistedSelectedLevel = _selectedLevel;
        }
    }

    function saveBestScore() as Void {
        if (_bestScore != _persistedBestScore) {
            Application.Storage.setValue("bestScoreV2", _bestScore);
            _persistedBestScore = _bestScore;
        }
    }

    function isDiveActive() as Lang.Boolean {
        return _state == DiveConstants.STATE_DESCENDING ||
            _state == DiveConstants.STATE_TURNING ||
            _state == DiveConstants.STATE_ASCENDING ||
            _state == DiveConstants.STATE_SURFACING ||
            _state == DiveConstants.STATE_DUCK_DIVE;
    }

    function getState() as Lang.Number { return _state; }
    function getDepthCm() as Lang.Number { return _depthCm; }
    function getMaxDepthCm() as Lang.Number { return _maxDepthCm; }
    function getFlow() as Lang.Number { return _flow; }
    function getScore() as Lang.Number { return _score; }
    function getBestScore() as Lang.Number { return _bestScore; }
    function getPerfectCount() as Lang.Number { return _perfectCount; }
    function getGoodCount() as Lang.Number { return _goodCount; }
    function getMissCount() as Lang.Number { return _missCount; }
    function getCueKind() as Lang.Number { return _cueKind; }
    function getCueAge() as Lang.Number { return _cueAge; }
    function getDuckAge() as Lang.Number { return _duckAge; }
    function getTargetDepthCm() as Lang.Number { return _targetDepthCm; }
    function didReachTarget() as Lang.Boolean { return _targetReached; }
    function didTakeTag() as Lang.Boolean { return _tagTaken; }
    function didCompleteTurn() as Lang.Boolean { return _turnCompleted; }
    function didFailAscent() as Lang.Boolean { return _ascentFailed; }
    function getSelectedLevel() as Lang.Number { return _selectedLevel; }
    function getUnlockedLevel() as Lang.Number { return _unlockedLevel; }
    function getTerritory() as Lang.Number { return Campaign.territory(_selectedLevel); }
    function getRunMedal() as Lang.Number { return _runMedal; }
    function getSelectedMedal() as Lang.Number { return _medals[_selectedLevel]; }
    function getSelectedBestScore() as Lang.Number { return _bestScores[_selectedLevel]; }
    function isSelectedUnlocked() as Lang.Boolean { return _selectedLevel <= _unlockedLevel; }
}
