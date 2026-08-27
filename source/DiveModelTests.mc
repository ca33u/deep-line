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
    return model.getFlow() == DiveConstants.MAX_FLOW -
        Campaign.missCost(model.getSelectedLevel()) && model.getMissCount() == 1;
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

(:test)
function testCampaignUsesRealDepthLandmarks(logger as Test.Logger) as Lang.Boolean {
    if (Campaign.LEVEL_COUNT != 15 || Campaign.depthCm(0) != 1000 ||
            Campaign.depthCm(2) != 2000 || Campaign.depthCm(12) != 13600 ||
            Campaign.depthCm(14) != 15000) {
        logger.error("campaign depth ladder changed unexpectedly");
        return false;
    }
    return Campaign.territory(0) == 0 && Campaign.territory(14) == 4;
}

(:test)
function testCampaignSelectionClampsAndConfiguresDive(logger as Test.Logger) as Lang.Boolean {
    var model = new DiveModel();
    model.openCampaign();
    model.moveSelection(-Campaign.LEVEL_COUNT);
    if (model.getState() != DiveConstants.STATE_LEVEL_SELECT ||
            model.getSelectedLevel() != 0 || model.getTargetDepthCm() != 1000) {
        logger.error("campaign selection did not clamp to first dive");
        return false;
    }
    model.startGame();
    return model.getState() == DiveConstants.STATE_DUCK_DIVE &&
        model.getTargetDepthCm() == 1000;
}

(:test)
function testCampaignScalesDeepDivePressure(logger as Test.Logger) as Lang.Boolean {
    return Campaign.descentSpeedCm(14) > Campaign.descentSpeedCm(0) &&
        Campaign.ascentSpeedCm(14) > Campaign.ascentSpeedCm(0) &&
        Campaign.equalizeCount(14) > Campaign.equalizeCount(0) &&
        Campaign.strokeCount(14) > Campaign.strokeCount(0) &&
        Campaign.cueDeadline(14) < Campaign.cueDeadline(0) &&
        Campaign.missCost(14) > Campaign.missCost(0);
}

(:test)
function testSuccessfulCampaignDiveAwardsAndUnlocks(logger as Test.Logger) as Lang.Boolean {
    var model = new DiveModel();
    var selected = model.getSelectedLevel();
    var unlocked = model.getUnlockedLevel();
    model.startGame();

    for (var tick = 0; tick < 1200; tick += 1) {
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

        if (model.advance() == DiveConstants.EVENT_SURFACED) {
            if (model.getRunMedal() < 1 ||
                    model.getSelectedBestScore() < model.getScore()) {
                logger.error("successful campaign dive did not save its award");
                return false;
            }
            if (selected == unlocked && unlocked < Campaign.LEVEL_COUNT - 1) {
                return model.getUnlockedLevel() == unlocked + 1;
            }
            return model.getUnlockedLevel() == unlocked;
        }
    }

    logger.error("successful campaign dive did not finish");
    return false;
}
