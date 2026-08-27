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
    const CUE_TURN = 5;

    const EVENT_NONE = 0;
    const EVENT_CUE = 1;
    const EVENT_PERFECT = 2;
    const EVENT_GOOD = 3;
    const EVENT_MISS = 4;
    const EVENT_WAIT = 5;
    const EVENT_TURN_READY = 6;
    const EVENT_TURNED = 7;
    const EVENT_GLIDE_STARTED = 8;
    const EVENT_GLIDE_PENALTY = 9;
    const EVENT_SURFACED = 10;
    const EVENT_TAGGED = 11;
    const EVENT_SURFACE_REACHED = 12;
    const EVENT_DUCKED = 13;

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
    private var _selectedLevel as Lang.Number = 0;
    private var _unlockedLevel as Lang.Number = 0;
    private var _targetDepthCm as Lang.Number = 1000;
    private var _runMedal as Lang.Number = 0;
    private var _bestScores as Lang.Array<Lang.Number> = [];
    private var _medals as Lang.Array<Lang.Number> = [];
    private var _equalizeDepths as Lang.Array<Lang.Number> = [];
    private var _strokeDepths as Lang.Array<Lang.Number> = [];

    function initialize() {
        var saved = Application.Storage.getValue("bestScore");
        if (saved instanceof Lang.Number) {
            _bestScore = saved;
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
        if (_state == DiveConstants.STATE_LEVEL_SELECT) {
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
        Application.Storage.setValue("selectedLevel", _selectedLevel);
    }

    function startNextOrRetry() as Void {
        if (_state == DiveConstants.STATE_RESULT && _selectedLevel < _unlockedLevel) {
            _selectedLevel += 1;
            configureLevel();
            Application.Storage.setValue("selectedLevel", _selectedLevel);
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
        _runMedal = 0;
        configureLevel();
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
            return DiveConstants.EVENT_WAIT;
        }

        if (_state == DiveConstants.STATE_TURNING) {
            if (_cueKind == DiveConstants.CUE_TAG) {
                _cueKind = DiveConstants.CUE_TURN;
                _cueAge = 0;
                return DiveConstants.EVENT_TAGGED;
            }
            if (_cueKind != DiveConstants.CUE_TURN) {
                return DiveConstants.EVENT_WAIT;
            }
            if (_cueAge >= 2 && _cueAge <= 7) {
                awardPerfect(150, 3);
            } else {
                awardGood(80);
            }
            beginAscent(true);
            return DiveConstants.EVENT_TURNED;
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
            _targetReached = true;
            _state = DiveConstants.STATE_TURNING;
            return DiveConstants.EVENT_TURN_READY;
        }

        return DiveConstants.EVENT_NONE;
    }

    private function advanceTurn() as Lang.Number {
        _cueAge += 1;
        if (_cueAge > 12) {
            applyMiss(10);
            beginAscent(true);
            return DiveConstants.EVENT_TURNED;
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
        if (age >= 2 && age <= 3) {
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
    }

    private function beginAscent(reachedTarget as Lang.Boolean) as Void {
        _targetReached = reachedTarget;
        _state = DiveConstants.STATE_ASCENDING;
        _cueKind = DiveConstants.CUE_NONE;
        _cueAge = 0;
        _nextAscentCue = 0;
        _strokeBoostTicks = 0;
    }

    private function finishRun() as Void {
        _state = DiveConstants.STATE_RESULT;
        _cueKind = DiveConstants.CUE_NONE;
        _score += (_maxDepthCm / 2) + (_flow * 5) + (_selectedLevel * 100);
        if (_score > _bestScore) {
            _bestScore = _score;
        }
        _runMedal = calculateMedal();
        if (_score > _bestScores[_selectedLevel]) {
            _bestScores[_selectedLevel] = _score;
            Application.Storage.setValue(levelKey("levelBest", _selectedLevel), _score);
        }
        if (_runMedal > _medals[_selectedLevel]) {
            _medals[_selectedLevel] = _runMedal;
            Application.Storage.setValue(levelKey("levelMedal", _selectedLevel), _runMedal);
        }
        if (_targetReached && _selectedLevel == _unlockedLevel &&
                _unlockedLevel < Campaign.LEVEL_COUNT - 1) {
            _unlockedLevel += 1;
            Application.Storage.setValue("unlockedLevel", _unlockedLevel);
        }
        saveBestScore();
    }

    private function calculateMedal() as Lang.Number {
        if (!_targetReached) { return 0; }
        var medal = 1;
        if (_flow >= 50 && _missCount <= 3) { medal = 2; }
        if (_flow >= 75 && _missCount <= 1 && _perfectCount >= 3) { medal = 3; }
        return medal;
    }

    private function loadCampaign() as Void {
        for (var index = 0; index < Campaign.LEVEL_COUNT; index += 1) {
            var savedLevelBest = Application.Storage.getValue(levelKey("levelBest", index));
            var savedMedal = Application.Storage.getValue(levelKey("levelMedal", index));
            _bestScores.add(savedLevelBest instanceof Lang.Number ? savedLevelBest : 0);
            _medals.add(savedMedal instanceof Lang.Number ? savedMedal : 0);
        }

        var savedUnlocked = Application.Storage.getValue("unlockedLevel");
        if (savedUnlocked instanceof Lang.Number) {
            _unlockedLevel = savedUnlocked;
        } else if (_bestScore > 0) {
            // Existing 20m players keep access to the complete first territory.
            _unlockedLevel = 2;
        }
        if (_unlockedLevel >= Campaign.LEVEL_COUNT) {
            _unlockedLevel = Campaign.LEVEL_COUNT - 1;
        }

        var savedSelected = Application.Storage.getValue("selectedLevel");
        if (savedSelected instanceof Lang.Number) {
            _selectedLevel = savedSelected;
        } else {
            _selectedLevel = _unlockedLevel;
        }
        if (_selectedLevel > _unlockedLevel) { _selectedLevel = _unlockedLevel; }
        if (_selectedLevel < 0) { _selectedLevel = 0; }
    }

    private function configureLevel() as Void {
        _targetDepthCm = Campaign.depthCm(_selectedLevel);
        _equalizeDepths = [];
        _strokeDepths = [];

        var equalizeCount = Campaign.equalizeCount(_selectedLevel);
        for (var equalizeIndex = 1; equalizeIndex <= equalizeCount;
                equalizeIndex += 1) {
            _equalizeDepths.add(_targetDepthCm * equalizeIndex / (equalizeCount + 1));
        }

        var strokeCount = Campaign.strokeCount(_selectedLevel);
        for (var strokeIndex = 1; strokeIndex <= strokeCount; strokeIndex += 1) {
            _strokeDepths.add(_targetDepthCm -
                (_targetDepthCm * strokeIndex / (strokeCount + 1)));
        }
    }

    private function levelKey(prefix as Lang.String, level as Lang.Number) as Lang.String {
        return prefix + level.format("%d");
    }

    function saveBestScore() as Void {
        if (_bestScore != _persistedBestScore) {
            Application.Storage.setValue("bestScore", _bestScore);
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
    function getSelectedLevel() as Lang.Number { return _selectedLevel; }
    function getUnlockedLevel() as Lang.Number { return _unlockedLevel; }
    function getTerritory() as Lang.Number { return Campaign.territory(_selectedLevel); }
    function getRunMedal() as Lang.Number { return _runMedal; }
    function getSelectedMedal() as Lang.Number { return _medals[_selectedLevel]; }
    function getSelectedBestScore() as Lang.Number { return _bestScores[_selectedLevel]; }
    function isSelectedUnlocked() as Lang.Boolean { return _selectedLevel <= _unlockedLevel; }
}
