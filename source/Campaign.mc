using Toybox.Lang;

module Campaign {
    const LEVEL_COUNT = 15;
    const TERRITORY_COUNT = 5;
    const LEVELS_PER_TERRITORY = 3;

    // The calm final metres of an ascent. Kick cues never land inside it, so a
    // promised cue count is always the count the diver actually sees.
    const GLIDE_DEPTH_CM = 300;
    const STROKE_FLOOR_CM = 400;

    function depthCm(level as Lang.Number) as Lang.Number {
        if (level == 0) { return 1000; }
        if (level == 1) { return 1500; }
        if (level == 2) { return 2000; }
        if (level == 3) { return 2500; }
        if (level == 4) { return 3000; }
        if (level == 5) { return 3500; }
        if (level == 6) { return 4000; }
        if (level == 7) { return 5000; }
        if (level == 8) { return 6000; }
        if (level == 9) { return 7500; }
        if (level == 10) { return 10000; }
        if (level == 11) { return 12000; }
        if (level == 12) { return 12600; }
        if (level == 13) { return 14500; }
        return 15000;
    }

    function territory(level as Lang.Number) as Lang.Number {
        return level / LEVELS_PER_TERRITORY;
    }

    function territoryName(territoryIndex as Lang.Number) as Lang.String {
        if (territoryIndex == 0) { return "SEA OF CORTEZ"; }
        if (territoryIndex == 1) { return "VISAYAN SEA"; }
        if (territoryIndex == 2) { return "RED SEA"; }
        if (territoryIndex == 3) { return "ATLANTIC OCEAN"; }
        return "GREENLAND SEA";
    }

    function descentSpeedCm(level as Lang.Number) as Lang.Number {
        var speed = depthCm(level) / (200 + (territory(level) * 25));
        return speed < 8 ? 8 : speed;
    }

    function ascentSpeedCm(level as Lang.Number) as Lang.Number {
        var speed = depthCm(level) / (160 + (territory(level) * 20));
        return speed < 10 ? 10 : speed;
    }

    function equalizeCount(level as Lang.Number) as Lang.Number {
        return 4 + (level / 2);
    }

    function strokeCount(level as Lang.Number) as Lang.Number {
        return 3 + (level / 3);
    }

    function cueDeadline(level as Lang.Number) as Lang.Number {
        // One extra 120 ms tick compensates for physical button and MIP refresh
        // latency. This expands the total response window by roughly 17–25%
        // without changing travel speed or animation timing.
        if (level >= 12) { return 4; }
        if (level >= 6) { return 5; }
        return 6;
    }

    // The timing ring lands on the target band exactly at the last perfect tick,
    // so the visual promise and the scoring window cannot drift apart.
    function perfectStart(level as Lang.Number) as Lang.Number {
        return 2;
    }

    function perfectEnd(level as Lang.Number) as Lang.Number {
        // The model scores in whole 120 ms ticks. A single late-grace tick is the
        // smallest possible expansion and is preferable to moving the visual
        // target earlier than the player sees it on real hardware.
        return territory(level) >= 3 ? 3 : 4;
    }

    // How many missed cues a dive survives before the safe early turn. Ignoring
    // every cue must never reach the bottom, and the allowance tightens with
    // each territory.
    function missTolerance(level as Lang.Number) as Lang.Number {
        var count = equalizeCount(level);
        var tolerated = count * 2 / 3;
        if (territory(level) >= 2) { tolerated = count / 2; }
        if (territory(level) >= 4) { tolerated = count * 2 / 5; }
        return tolerated < 2 ? 2 : tolerated;
    }

    function missCost(level as Lang.Number) as Lang.Number {
        return (100 / (missTolerance(level) + 1)) + 1;
    }
}
