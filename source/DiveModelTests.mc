using Toybox.Lang;
using Toybox.Test;

(:test)
function testStartAndPausePreserveDepth(logger as Test.Logger) as Lang.Boolean {
    var model = new DiveModel();
    model.startGame();
    for (var tick = 0; tick < 12; tick += 1) {
        model.advance();
    }
    var depth = model.getDepthCm();
    model.togglePause();
    for (var pausedTick = 0; pausedTick < 20; pausedTick += 1) {
        model.advance();
    }
    if (model.getDepthCm() != depth) {
        logger.error("paused dive changed depth");
        return false;
    }
    model.togglePause();
    model.advance();
    return model.getDepthCm() > depth;
}

(:test)
function testStartUsesDuckDive(logger as Test.Logger) as Lang.Boolean {
    var model = new DiveModel();
    model.startGame();
    if (model.getState() != DiveConstants.STATE_DUCK_DIVE || model.getDepthCm() != 0) {
        logger.error("game did not begin at the surface");
        return false;
    }
    for (var tick = 0; tick < 11; tick += 1) {
        model.advance();
    }
    if (model.getState() != DiveConstants.STATE_DUCK_DIVE || model.getDepthCm() != 0) {
        logger.error("duck dive moved depth before animation completed");
        return false;
    }
    return model.advance() == DiveConstants.EVENT_DUCKED &&
        model.getState() == DiveConstants.STATE_DESCENDING;
}

(:test)
function testPerfectEqualization(logger as Test.Logger) as Lang.Boolean {
    var model = new DiveModel();
    model.startGame();
    while (model.getCueKind() != DiveConstants.CUE_EQUALIZE) {
        model.advance();
    }
    model.advance();
    model.advance();
    var event = model.action();
    if (event != DiveConstants.EVENT_PERFECT || model.getPerfectCount() != 1) {
        logger.error("equalization did not resolve as perfect");
        return false;
    }
    return model.getCueKind() == DiveConstants.CUE_NONE;
}

(:test)
function testMissedEqualizationCostsFlow(logger as Test.Logger) as Lang.Boolean {
    var model = new DiveModel();
    model.startGame();
    while (model.getCueKind() != DiveConstants.CUE_EQUALIZE) {
        model.advance();
    }
    var event = DiveConstants.EVENT_NONE;
    for (var tick = 0; tick < 6; tick += 1) {
        event = model.advance();
    }
    if (event != DiveConstants.EVENT_MISS) {
        logger.error("expired equalization did not miss");
        return false;
    }
    return model.getFlow() == 88 && model.getMissCount() == 1;
}

(:test)
function testFullDiveReachesSurface(logger as Test.Logger) as Lang.Boolean {
    var model = new DiveModel();
    model.startGame();

    for (var tick = 0; tick < 1000; tick += 1) {
        var cue = model.getCueKind();
        if ((cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) &&
                model.getCueAge() == 2) {
            model.action();
        } else if (model.getState() == DiveConstants.STATE_TURNING) {
            if (cue == DiveConstants.CUE_TAG) {
                model.action();
            } else if (cue == DiveConstants.CUE_TURN && model.getCueAge() == 2) {
                model.action();
            }
        }

        var event = model.advance();
        if (event == DiveConstants.EVENT_SURFACED) {
            return model.getState() == DiveConstants.STATE_RESULT &&
                model.getDepthCm() == 0 && model.didReachTarget();
        }
    }

    logger.error("full dive did not reach the surface");
    return false;
}

(:test)
function testTurnRequiresTagAndTurn(logger as Test.Logger) as Lang.Boolean {
    var model = new DiveModel();
    model.startGame();
    while (model.getState() != DiveConstants.STATE_TURNING) {
        model.advance();
    }

    if (model.getCueKind() != DiveConstants.CUE_TAG) {
        logger.error("turn did not begin with tag target");
        return false;
    }
    if (model.action() != DiveConstants.EVENT_TAGGED ||
            model.getState() != DiveConstants.STATE_TURNING ||
            model.getCueKind() != DiveConstants.CUE_TURN) {
        logger.error("first turn action did not advance to second target");
        return false;
    }
    model.advance();
    model.advance();
    return model.action() == DiveConstants.EVENT_TURNED &&
        model.getState() == DiveConstants.STATE_ASCENDING;
}

(:test)
function testGlidePunishesExtraKick(logger as Test.Logger) as Lang.Boolean {
    var model = new DiveModel();
    model.startGame();

    for (var tick = 0; tick < 1000; tick += 1) {
        var cue = model.getCueKind();
        if ((cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) &&
                model.getCueAge() == 2) {
            model.action();
        }
        if (model.getState() == DiveConstants.STATE_TURNING) {
            model.action();
        }
        if (model.getCueKind() == DiveConstants.CUE_GLIDE) {
            var flow = model.getFlow();
            var event = model.action();
            return event == DiveConstants.EVENT_GLIDE_PENALTY && model.getFlow() == flow - 4;
        }
        model.advance();
    }

    logger.error("dive never entered glide");
    return false;
}

(:test)
function testFinishedRunTracksBestScore(logger as Test.Logger) as Lang.Boolean {
    var model = new DiveModel();
    var previousBest = model.getBestScore();
    model.startGame();

    for (var tick = 0; tick < 1000; tick += 1) {
        var cue = model.getCueKind();
        if ((cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) &&
                model.getCueAge() == 2) {
            model.action();
        }
        if (model.getState() == DiveConstants.STATE_TURNING) {
            model.action();
        }
        if (model.advance() == DiveConstants.EVENT_SURFACED) {
            return model.getScore() > 0 && model.getBestScore() >= model.getScore() &&
                model.getBestScore() >= previousBest;
        }
    }

    logger.error("could not finish scoring run");
    return false;
}
