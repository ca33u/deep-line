using Toybox.Lang;

module Campaign {
    const LEVEL_COUNT = 15;
    const TERRITORY_COUNT = 5;
    const LEVELS_PER_TERRITORY = 3;

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
        if (level == 12) { return 13600; }
        if (level == 13) { return 14500; }
        return 15000;
    }

    function territory(level as Lang.Number) as Lang.Number {
        return level / LEVELS_PER_TERRITORY;
    }

    function territoryName(territoryIndex as Lang.Number) as Lang.String {
        if (territoryIndex == 0) { return "MEXICO"; }
        if (territoryIndex == 1) { return "PHILIPPINES"; }
        if (territoryIndex == 2) { return "RED SEA"; }
        if (territoryIndex == 3) { return "BAHAMAS"; }
        return "ANTARCTICA";
    }

    function territorySubtitle(territoryIndex as Lang.Number) as Lang.String {
        if (territoryIndex == 0) { return "SEA OF CORTEZ"; }
        if (territoryIndex == 1) { return "BOHOL SEA"; }
        if (territoryIndex == 2) { return "DAHAB"; }
        if (territoryIndex == 3) { return "DEAN'S BLUE HOLE"; }
        return "SOUTHERN OCEAN";
    }

    function rankName(level as Lang.Number) as Lang.String {
        if (level <= 2) { return "BEGINNER"; }
        if (level <= 5) { return "WAVE RIDER"; }
        if (level <= 8) { return "DEEP DIVER"; }
        if (level <= 11) { return "ELITE"; }
        if (level <= 13) { return "RECORD CHASER"; }
        return "BEYOND THE RECORD";
    }

    function landmark(level as Lang.Number) as Lang.String {
        if (level == 2) { return "WAVE 1 RANGE"; }
        if (level == 4) { return "WAVE 2 RANGE"; }
        if (level == 6) { return "WAVE 3 RANGE"; }
        if (level == 7) { return "WAVE 4 RANGE"; }
        if (level == 12) { return "136m CWT LANDMARK"; }
        if (level == 14) { return "BEYOND THE RECORD"; }
        return rankName(level);
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
        if (level >= 12) { return 3; }
        if (level >= 6) { return 4; }
        return 5;
    }

    function missCost(level as Lang.Number) as Lang.Number {
        return 10 + (territory(level) * 2);
    }
}
