local component = require("component");
local draconic_reactor = component.draconic_reactor;
local output = component.proxy(component.get("9af65af1"));
local input = component.proxy(component.get("8e24f155"));
local config = require("config");

local baseLib = require("baseLib")
local settings = baseLib.settings
local calc = baseLib.calc

local reactor = {}

-------------------------------------------------------------------------------
-- Reading reactor information
reactor.info = draconic_reactor.getReactorInfo;

reactor.is = function(option)
    return settings.get(option) or false
end

reactor.satPercentage = function()
    return calc.percentage(reactor.info().maxEnergySaturation, reactor.info().energySaturation);
end

reactor.fieldPercentage = function()
    return calc.percentage(reactor.info().maxFieldStrength, reactor.info().fieldStrength);
end

reactor.fuelConversionLevel = function()
    return calc.percentage(reactor.info().maxFuelConversion, reactor.info().fuelConversion)
end

reactor.shouldCharge = function()
    local status = reactor.info().status;
    return 
        (status == "cold" or status == "stopping" or status == 'cooling') and 
        reactor.info().temperature < 2000
end

reactor.shouldActivate = function()
    return
        (reactor.info().status == "warming_up" 
        and reactor.info().temperature >= 2000
        and reactor.is('initialized')
    )
end

reactor.happyDrain = function()
    return reactor.info().fieldDrainRate / 0.5
end


-------------------------------------------------------------------------------
-- ## control for fluxgates

reactor.input_gate = input;
reactor.output_gate = output;

reactor.getInputFlow = reactor.input_gate.getFlow;
reactor.setInputFlow = reactor.input_gate.setSignalLowFlow;

reactor.getOutputFlow = reactor.output_gate.getFlow;
reactor.setOutputFlow = reactor.output_gate.setSignalLowFlow;


-------------------------------------------------------------------------------
-- ## control the reactor


-- Interaction with the reactor
reactor.stop = function()
    if reactor.is('initialized') then
        settings.set({
            initialized = false,
            active = false
        })
    end
    draconic_reactor.stopReactor();
end

reactor.charge = function(sets)
    if reactor.shouldCharge() then
        local sets = sets or {
            inputFlow = 900000
        }
        reactor.setInputFlow(900000)
        settings.set({initialized = true})
        settings.set({charging = true})
        return draconic_reactor.chargeReactor()
    else
        if reactor.is('charging') and not reactor.info().status == 'warming_up' then
            settings.set({charging = false})
        end
        return nil
    end
end

reactor.activate = function(sets)
    if reactor.shouldActivate() then
        local sets = sets or {
            inputFlow = 200000,
            outputFlow = 200000
        }
        settings.set({
            charging = false,
            active = true
        })
        reactor.setInputFlow(sets.inputFlow)
        reactor.setOutputFlow(sets.outputFlow)
        return draconic_reactor.activateReactor()
    else
        return nil
    end
end

reactor.raiseOutputByTier = function(tier)
    for i, temp in pairs(tier.maxTemps) do 
        if reactor.info().temperature <= temp then 
            reactor.setOutputFlow(reactor.getOutputFlow() + tier.steps[i]);
        end
    end
end

reactor.raiseOutput = function()
    if reactor.info().generationRate >= reactor.getOutputFlow() and
    reactor.fieldPercentage() >= 50  then
        for i, tier in pairs(config.generationTiers) do 
            if reactor.satPercentage() >= tier.minSaturation and
            reactor.fuelConversionLevel() >= tier.minFuelConversion and
            reactor.getOutputFlow() <= tier.targetOut then
                reactor.raiseOutputByTier(tier);
            end
        end
    end
end

reactor.running = function(sets)
    local sets = sets or {}
    -- safety first
    if reactor.info().temperature >= (sets.temperature or 7800)
    or reactor.fuelConversionLevel() >= (sets.maxFuelConversion or 90) then
        reactor.stop()
    end

    if sets.autoInputControl and (not reactor.is('charging')) then
        reactor.setInputFlow(reactor.happyDrain())
    end

    if sets.autoOutputControl then
        reactor.raiseOutput();
    end
end

reactor.run = function()
    reactor.charge()
    reactor.activate()
    local autoInput = settings.get('autoInputControl')
    local autoOutput = settings.get('autoOutputControl')
    reactor.running({
        temperature = 7900,
        maxFuelConversion = 90,
        autoInputControl = autoInput,
        autoOutputControl = autoOutput
     })
end

return reactor;