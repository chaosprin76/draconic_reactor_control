local component = require("component");
local draconic_reactor = component.draconic_reactor;
local output = component.proxy(component.get("9af65af1"));
local input = component.proxy(component.get("8e24f155"));
local config = require("config");

local reactor = {}
-------------------------------------------------------------------------------

function percentage(max, val)
    if max == 0 then
        return 0
    else
        return math.ceil(val / max * 10000) * 0.01
    end
end

-------------------------------------------------------------------------------
-- Reading reactor information
reactor.info = draconic_reactor.getReactorInfo;

reactor.satPercentage = function()
    return percentage(reactor.info().maxEnergySaturation, reactor.info().energySaturation;
end

reactor.fieldPercentage = function()
    return percentage(reactor.info().maxFieldStrength, reactor.info().fieldStrength);
end

reactor.fuelConversionLevel = function()
    return percentage(reactor.info().maxFuelConversion, reactor.info().fuelConversion)
end

reactor.shouldCharge = function()
    local status = reactor.info().status;
    return 
        (status == "cold" or status == "stopping") and 
        reactor.info().temperature < 2000
end

reactor.shouldActivate = function()
    return
        (reactor.info().status == "warming_up" and reactor.info().temperature >= 2000)
end

reactor.happyDrain = function()
    return reactor.info().fieldDrainRate / 0.5
end

reactor.initialized = false;

do
    local status = reactor.info().status
    if status == "charged" or status == "running" then
        reactor.initialized = true;
    end
end
-- Interaction with the reactor
reactor.stop = function()
    reactor.initialized = false;
    draconic_reactor.stopReactor();
end

-- Adding flux-gates
reactor.input_gate = input;
reactor.output_gate = output;

reactor.getInputFlow = reactor.input_gate.getFlow;
reactor.setInputFlow = reactor.input_gate.setSignalLowFlow;

reactor.getOutputFlow = reactor.output_gate.getFlow;
reactor.setOutputFlow = reactor.output_gate.setSignalLowFlow;

reactor.autoInputControl = true;
reactor.autoOutputControl = false;

reactor.raiseOutputByTier = function(tier)
    for i, temp in pairs(tier.maxTemps) do 
        if reactor.info().temperature <= temp then 
            reactor.setOutputFlow(reactor.getOutputFlow() + tier.steps[i]);
        end
    end
end

reactor.raiseOutput = function()
    if reactor.info().generationRate >= reactor.getOutputFlow() and
    reactor.fieldPercentage() >= 50 and
    reactor.fieldPercentage() <= 60 then
        for i, tier in pairs(config.generationTiers) do 
            if reactor.satPercentage() >= tier.minSaturation and
            reactor.fuelConversionLevel() >= tier.minFuelConversion and
            reactor.getOutputFlow() <= tier.targetOut then
                reactor.raiseOutputByTier(tier);
            end
        end
    end
end


reactor.run = function()
    if reactor.shouldCharge() then
        reactor.setInputFlow(900000);
        draconic_reactor.chargeReactor();
        reactor.initialized = true;
        return reactor.status();
    elseif reactor.shouldActivate() then
        reactor.setInputFlow(200000);
        reactor.setOutputFlow(200000);
        draconic_reactor.activateReactor();
    elseif reactor.status() == "running" then
        if reactor.info().temperature >= 7700 or 
        reactor.fieldPercentage() <= 15 or 
        reactor.fuelConversionLevel() >= 88 then
            reactor.stop();
        end

        if reactor.autoInputControl then 
            reactor.setInputFlow(reactor.happyDrain()) 
        end

        if reactor.autoOutputControl then
            reactor.raiseOutput();
        end

    end
end

return reactor;