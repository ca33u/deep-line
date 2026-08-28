using Toybox.Application;
using Toybox.Lang;
using Toybox.Test;

function freshModel() as DiveModel {
    Application.Storage.clearValues();
    return new DiveModel();
}

(:test)
function testStartAndPausePreserveDepth(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
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
function testPausedDiveCanReturnToMenu(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
    model.startGame();
    model.togglePause();
    model.returnToMenu();
    if (model.getState() != DiveConstants.STATE_MENU) {
        logger.error("paused dive did not return to menu");
        return false;
    }
    model.openCampaign();
    return model.getState() == DiveConstants.STATE_LEVEL_SELECT;
}

(:test)
function testStartUsesDuckDive(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
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
    var model = freshModel();
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
    var model = freshModel();
    model.startGame();
    while (model.getCueKind() != DiveConstants.CUE_EQUALIZE) {
        model.advance();
    }
    var event = DiveConstants.EVENT_NONE;
    var expiredAt = Campaign.cueDeadline(model.getSelectedLevel()) + 1;
    for (var tick = 0; tick < expiredAt; tick += 1) {
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
    var model = freshModel();
    model.startGame();

    for (var tick = 0; tick < 1000; tick += 1) {
        var cue = model.getCueKind();
        if ((cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) &&
                model.getCueAge() == 2) {
            model.action();
        } else if (cue == DiveConstants.CUE_TAG && model.getCueAge() == 2) {
            model.action();
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
function testTagAndTurnUseOneTimingCue(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
    model.startGame();
    // The descent has to be played: an ignored one now turns back safely and
    // never reaches the plate.
    for (var tick = 0; tick < 2000 &&
            model.getState() != DiveConstants.STATE_TURNING; tick += 1) {
        if (model.getCueKind() == DiveConstants.CUE_EQUALIZE &&
                model.getCueAge() == Campaign.perfectStart(model.getSelectedLevel())) {
            model.action();
        }
        model.advance();
    }

    if (model.getState() != DiveConstants.STATE_TURNING) {
        logger.error("played descent did not reach the turn");
        return false;
    }
    if (model.getCueKind() != DiveConstants.CUE_TAG) {
        logger.error("bottom did not begin with tag and turn cue");
        return false;
    }
    model.advance();
    model.advance();
    if (model.action() != DiveConstants.EVENT_PERFECT ||
            !model.didTakeTag() || !model.didCompleteTurn() ||
            model.getState() != DiveConstants.STATE_TURNING ||
            model.getCueKind() != DiveConstants.CUE_NONE) {
        logger.error("single timing action did not complete tag and turn");
        return false;
    }
    for (var animationTick = 0; animationTick < 5; animationTick += 1) {
        model.advance();
    }
    return model.getState() == DiveConstants.STATE_ASCENDING &&
        model.didReachTarget();
}

(:test)
function testGlidePunishesExtraKick(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
    model.startGame();

    for (var tick = 0; tick < 1000; tick += 1) {
        var cue = model.getCueKind();
        if ((cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) &&
                model.getCueAge() == 2) {
            model.action();
        }
        if (cue == DiveConstants.CUE_TAG && model.getCueAge() == 2) {
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
    var model = freshModel();
    var previousBest = model.getBestScore();
    model.startGame();

    for (var tick = 0; tick < 1000; tick += 1) {
        var cue = model.getCueKind();
        if ((cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) &&
                model.getCueAge() == 2) {
            model.action();
        }
        if (cue == DiveConstants.CUE_TAG && model.getCueAge() == 2) {
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
            Campaign.depthCm(2) != 2000 || Campaign.depthCm(12) != 12600 ||
            Campaign.depthCm(14) != 15000) {
        logger.error("campaign depth ladder changed unexpectedly");
        return false;
    }
    if (Campaign.territory(0) != 0 || Campaign.territory(14) != 4 ||
            !Campaign.territoryName(4).equals("GREENLAND SEA")) {
        logger.error("campaign territory identity changed unexpectedly");
        return false;
    }
    return true;
}

(:test)
function testCampaignSelectionClampsAndConfiguresDive(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
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
function testIgnoredDiveNeverReachesTheBottom(logger as Test.Logger) as Lang.Boolean {
    // A dive that is never played must turn back safely on every level instead
    // of coasting to the plate and unlocking the next depth.
    for (var level = 0; level < Campaign.LEVEL_COUNT; level += 1) {
        var budget = Campaign.equalizeCount(level) * Campaign.missCost(level);
        if (budget <= DiveConstants.MAX_FLOW) {
            logger.error("level " + level.format("%d") +
                " survives ignoring every cue");
            return false;
        }
        var tolerated = Campaign.missTolerance(level) * Campaign.missCost(level);
        if (tolerated >= DiveConstants.MAX_FLOW) {
            logger.error("level " + level.format("%d") +
                " cannot absorb its own tolerated misses");
            return false;
        }
    }
    return true;
}

(:test)
function testUnplayedDiveTurnsEarlyAndUnlocksNothing(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
    var unlocked = model.getUnlockedLevel();
    model.startGame();

    for (var tick = 0; tick < 2000; tick += 1) {
        if (model.advance() == DiveConstants.EVENT_SURFACED) {
            if (model.didReachTarget()) {
                logger.error("an unplayed dive still counted as reaching target");
                return false;
            }
            return model.getUnlockedLevel() == unlocked && model.getRunMedal() == 0;
        }
    }

    logger.error("unplayed dive never resolved");
    return false;
}

(:test)
function testExpiredTagDoesNotCountTheDive(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
    model.startGame();

    // Play the descent cleanly, then let the tag expire at the bottom.
    for (var tick = 0; tick < 2000; tick += 1) {
        var cue = model.getCueKind();
        if (cue == DiveConstants.CUE_EQUALIZE &&
                model.getCueAge() == Campaign.perfectStart(model.getSelectedLevel())) {
            model.action();
        }
        if (model.advance() == DiveConstants.EVENT_TAG_MISS) {
            return !model.didTakeTag() && !model.didReachTarget() &&
                model.getState() == DiveConstants.STATE_ASCENDING;
        }
    }

    logger.error("dive never reached the turn");
    return false;
}

(:test)
function testEarlyTurnDoesNotBurstPassedKickCues(logger as Test.Logger) as Lang.Boolean {
    // A dive that turns back early is already above some kick cues. Those must
    // be dropped, not fired back to back the moment the ascent starts.
    var model = freshModel();
    model.startGame();
    var turnDepth = -1;

    for (var tick = 0; tick < 2000; tick += 1) {
        var wasDescending = model.getState() == DiveConstants.STATE_DESCENDING;
        var event = model.advance();
        if (wasDescending && model.getState() == DiveConstants.STATE_ASCENDING &&
                turnDepth < 0) {
            turnDepth = model.getDepthCm();
        }
        if (turnDepth >= 0 && event == DiveConstants.EVENT_CUE &&
                model.getCueKind() == DiveConstants.CUE_STROKE &&
                model.getDepthCm() > turnDepth) {
            logger.error("a kick cue fired below the early turn");
            return false;
        }
        if (event == DiveConstants.EVENT_SURFACED) {
            return turnDepth >= 0;
        }
    }

    logger.error("early turn dive did not resolve");
    return false;
}

(:test)
function testEveryKickCueStaysAboveTheGlide(logger as Test.Logger) as Lang.Boolean {
    // Cues scheduled inside the final glide could never fire, so a level would
    // silently promise more kicks than it delivered.
    for (var level = 0; level < Campaign.LEVEL_COUNT; level += 1) {
        var target = Campaign.depthCm(level);
        var count = Campaign.strokeCount(level);
        var span = target - Campaign.STROKE_FLOOR_CM;
        for (var index = 1; index <= count; index += 1) {
            var depth = target - (span * index / (count + 1));
            if (depth <= Campaign.GLIDE_DEPTH_CM) {
                logger.error("level " + level.format("%d") + " hides a kick cue");
                return false;
            }
        }
    }
    return true;
}

(:test)
function testEqualizationIsFrontLoaded(logger as Test.Logger) as Lang.Boolean {
    // The descent should crowd its cues near the surface and open up with depth,
    // instead of running as an even metronome.
    var model = freshModel();
    model.startGame();

    var previousDepth = 0;
    var firstGap = 0;
    var lastGap = 0;
    var seen = 0;

    for (var tick = 0; tick < 2000; tick += 1) {
        var cue = model.getCueKind();
        if (cue == DiveConstants.CUE_EQUALIZE &&
                model.getCueAge() == Campaign.perfectStart(model.getSelectedLevel())) {
            var gap = model.getDepthCm() - previousDepth;
            previousDepth = model.getDepthCm();
            seen += 1;
            if (seen == 1) { firstGap = gap; }
            lastGap = gap;
            model.action();
        }
        // The run opens in the duck dive, so only leaving the descent ends it.
        if (model.getState() != DiveConstants.STATE_DUCK_DIVE &&
                model.getState() != DiveConstants.STATE_DESCENDING) {
            break;
        }
        model.advance();
    }

    if (seen < 3) {
        logger.error("descent did not produce enough equalization cues");
        return false;
    }
    return lastGap > firstGap;
}

(:test)
function testAccuracyOutweighsDepthInScore(logger as Test.Logger) as Lang.Boolean {
    // Two dives to the same depth with the same FLOW must not score the same:
    // a clean run has to be worth replaying for.
    var scores = [0, 0];

    for (var run = 0; run < 2; run += 1) {
        var model = freshModel();
        model.startGame();
        // Run 0 hits the perfect window, run 1 answers every cue immediately:
        // both reach the bottom with full FLOW and no misses.
        var window = run == 0 ? Campaign.perfectStart(model.getSelectedLevel()) : 0;

        for (var tick = 0; tick < 2000; tick += 1) {
            var cue = model.getCueKind();
            if ((cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) &&
                    model.getCueAge() == window) {
                model.action();
            } else if (cue == DiveConstants.CUE_TAG &&
                    model.getCueAge() == window) {
                model.action();
            }

            if (model.advance() == DiveConstants.EVENT_SURFACED) {
                scores[run] = model.getScore();
                break;
            }
        }
    }

    if (scores[0] <= 0 || scores[1] <= 0) {
        logger.error("scoring run did not finish");
        return false;
    }
    if (scores[0] <= scores[1]) {
        logger.error("perfect timing did not beat loose timing");
        return false;
    }
    return true;
}

(:test)
function testCampaignScalesDeepDivePressure(logger as Test.Logger) as Lang.Boolean {
    return Campaign.descentSpeedCm(14) > Campaign.descentSpeedCm(0) &&
        Campaign.ascentSpeedCm(14) > Campaign.ascentSpeedCm(0) &&
        Campaign.equalizeCount(14) > Campaign.equalizeCount(0) &&
        Campaign.strokeCount(14) > Campaign.strokeCount(0) &&
        Campaign.cueDeadline(14) < Campaign.cueDeadline(0) &&
        Campaign.perfectEnd(14) < Campaign.perfectEnd(0) &&
        Campaign.missTolerance(14) < Campaign.equalizeCount(14) / 2;
}

(:test)
function testSuccessfulCampaignDiveAwardsAndUnlocks(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
    var selected = model.getSelectedLevel();
    var unlocked = model.getUnlockedLevel();
    model.startGame();

    for (var tick = 0; tick < 1200; tick += 1) {
        var cue = model.getCueKind();
        if ((cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) &&
                model.getCueAge() == 2) {
            model.action();
        } else if (cue == DiveConstants.CUE_TAG && model.getCueAge() == 2) {
            model.action();
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

(:test)
function testExpiredTagAndTurnCueDoesNotCountDive(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
    model.startGame();

    for (var tick = 0; tick < 2000; tick += 1) {
        var cue = model.getCueKind();
        if (cue == DiveConstants.CUE_EQUALIZE && model.getCueAge() == 2) {
            model.action();
        }

        if (model.advance() == DiveConstants.EVENT_TAG_MISS) {
            return !model.didTakeTag() && !model.didCompleteTurn() &&
                !model.didReachTarget() && !model.isRunSuccessful() &&
                model.getState() == DiveConstants.STATE_ASCENDING;
        }
    }

    logger.error("expired tag and turn cue still counted the bottom turn");
    return false;
}

(:test)
function testZeroFlowAscentCannotCompleteOrSetBest(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
    var unlocked = model.getUnlockedLevel();
    model.startGame();

    for (var tick = 0; tick < 2000; tick += 1) {
        var cue = model.getCueKind();
        if (cue == DiveConstants.CUE_EQUALIZE && model.getCueAge() == 2) {
            model.action();
        } else if (cue == DiveConstants.CUE_TAG && model.getCueAge() == 2) {
            model.action();
        }

        if (model.getState() == DiveConstants.STATE_ASCENDING &&
                model.getFlow() > 0) {
            // Deliberately waste the remaining breath between cues. The diver may
            // still animate safely to the surface, but the run is already failed.
            model.action();
        }

        if (model.advance() == DiveConstants.EVENT_SURFACED) {
            return model.getFlow() == 0 && model.didFailAscent() &&
                !model.isRunSuccessful() && model.getRunMedal() == 0 &&
                model.getUnlockedLevel() == unlocked &&
                model.getSelectedBestScore() == 0 && model.getBestScore() == 0;
        }
    }

    logger.error("zero-FLOW ascent did not resolve as a failed run");
    return false;
}

(:test)
function testImmediateGoodRunNeedsTimingToUnlock(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
    var unlocked = model.getUnlockedLevel();
    model.startGame();

    for (var tick = 0; tick < 2000; tick += 1) {
        var cue = model.getCueKind();
        if ((cue == DiveConstants.CUE_EQUALIZE || cue == DiveConstants.CUE_STROKE) &&
                model.getCueAge() == 0) {
            model.action();
        } else if (cue == DiveConstants.CUE_TAG && model.getCueAge() == 0) {
            model.action();
        }

        if (model.advance() == DiveConstants.EVENT_SURFACED) {
            return model.isRunSuccessful() && model.getRunMedal() == 1 &&
                model.getUnlockedLevel() == unlocked;
        }
    }

    logger.error("all-GOOD run did not finish as a one-star retry");
    return false;
}

(:test)
function testTwoStarRunUnlocksNextDepth(logger as Test.Logger) as Lang.Boolean {
    var model = freshModel();
    model.startGame();

    for (var tick = 0; tick < 2000; tick += 1) {
        var cue = model.getCueKind();
        // The four 10 m equalizations are PERFECT; tag/turn and kicks are GOOD.
        // Four of eight scored actions = 50%, safely above the two-star gate.
        if (cue == DiveConstants.CUE_EQUALIZE && model.getCueAge() == 2) {
            model.action();
        } else if (cue == DiveConstants.CUE_STROKE && model.getCueAge() == 0) {
            model.action();
        } else if (model.getState() == DiveConstants.STATE_TURNING &&
                cue == DiveConstants.CUE_TAG) {
            model.action();
        }

        if (model.advance() == DiveConstants.EVENT_SURFACED) {
            return model.isRunSuccessful() && model.getRunMedal() == 2 &&
                model.getUnlockedLevel() == 1;
        }
    }

    logger.error("two-star run did not unlock the next depth");
    return false;
}

(:test)
function testLegacyProgressCannotBypassCorrectedRules(logger as Test.Logger) as Lang.Boolean {
    Application.Storage.clearValues();
    Application.Storage.setValue("bestScore", 99999);
    Application.Storage.setValue("unlockedLevel", Campaign.LEVEL_COUNT - 1);
    Application.Storage.setValue("selectedLevel", Campaign.LEVEL_COUNT - 1);
    Application.Storage.setValue("levelMedal0", 3);

    var model = new DiveModel();
    if (model.getBestScore() != 0 || model.getUnlockedLevel() != 0 ||
            model.getSelectedLevel() != 0 || model.getSelectedMedal() != 0) {
        logger.error("legacy progression leaked into corrected campaign");
        return false;
    }

    // Migration is non-destructive: the obsolete keys remain recoverable.
    var legacyUnlocked = Application.Storage.getValue("unlockedLevel");
    return legacyUnlocked instanceof Lang.Number &&
        (legacyUnlocked as Lang.Number) == Campaign.LEVEL_COUNT - 1;
}

(:test)
function testCorruptCurrentProgressIsClamped(logger as Test.Logger) as Lang.Boolean {
    Application.Storage.clearValues();
    Application.Storage.setValue("bestScoreV2", -42);
    Application.Storage.setValue("unlockedLevelV2", -7);
    Application.Storage.setValue("selectedLevelV2", 999);
    Application.Storage.setValue("levelBestV20", -100);
    Application.Storage.setValue("levelMedalV20", 99);

    var model = new DiveModel();
    return model.getBestScore() == 0 && model.getUnlockedLevel() == 0 &&
        model.getSelectedLevel() == 0 && model.getSelectedBestScore() == 0 &&
        model.getSelectedMedal() == 3;
}
