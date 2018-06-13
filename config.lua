local colors = require("colorTable");

return {
    updateRate = 0.15;
    normalRaiseValue = 1000;
    lowRaiseValue = 100;
    highRaiseValue = 10000;
    
    defaultBackground = colors.black;
    defaultForeground = colors.white;

    maxTemp = 7800;
    minField = 20;

    generationTiers= {
        tier_0 = {
            targetOut = 25000000;
            minFuelConversion = 70;
            maxTemps = {6000, 6600, 7200};
            steps = {50000, 30000, 10000};
            minSaturation = 65;
        },
        tier_1 = {
            targetOut = 20000000;
            minFuelConversion = 40;
            maxTemps = {4800, 5200, 5800};
            steps = {80000, 60000, 40000};
            minSaturation = 60;
        },
        tier_2 = {
            targetOut = 15000000;
            minFuelConversion = 15;
            maxTemps = {3800, 4200, 4800};
            steps = {125000, 100000, 75000};
            minSaturation = 50;
        },
        tier_3 = {
            targetOut = 10000000;
            minFuelConversion = 5;
            maxTemps = {5000};
            steps = {500000};
            minSaturation = 40;
        },
        tier_4 = {
            targetOut = 5000000;
            minFuelConversion = 0;
            maxTemps = {5000};
            steps = {300000};
            minSaturation = 40;
        }
        
    }
}