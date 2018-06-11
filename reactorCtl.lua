package.loaded.config = nil;
package.loaded.gui = nil;
package.loaded.reactor = nil;
package.loaded.colorTable = nil;

local component = require("component");
local term = require("term");
local os = require("os");
local reactor = require("reactor");
local event = require("event");
local keyboard = require("keyboard");
local gpu = component.gpu;
local colors = require("colorTable");
local config = require("config")
local gui = require("gui")

local run = true;
-------------------------------------------------------------------------------
function getKey()
    return (select(4, event.pull("key_down")))
end

-------------------------------------------------------------------------------

-- # Keyboard control

local function flowRaiser(set, get, val, delay)
    set(get() + val);
    os.sleep(delay);
end

local function raiseInputFlow(val, delay)
    flowRaiser(reactor.setInputFlow, reactor.getInputFlow, val, delay);
end

local function raiseOutputFlow(val, delay)
    flowRaiser(reactor.setOutputFlow, reactor.getOutputFlow, val, delay);
end

local function onRaise(raiser, negate, opts)
    local high, low, norm, delay = 
        opts.high or config.highRaiseValue, 
        opts.low or config.lowRaiseValue, 
        opts.norm or config.normalRaiseValue,
        opts.delay or config.updateRate;
    if negate then
        high, low, norm = -high, -low, -norm
    end

    if keyboard.isControlDown() then
        raiser(high, delay);
    elseif keyboard.isShiftDown() then
        raiser(low, delay);
    else
        raiser(norm, delay);
    end
end

local function getKeyPress(event, address, arg1, arg2, arg3)
    if type(address) == "string" and component.isPrimary(address) then
        if arg2 == keyboard.keys.q then
            run = false;
        elseif arg2 == keyboard.keys.up then
            onRaise(raiseInputFlow, false, {})
        elseif arg2 == keyboard.keys.down then
            onRaise(raiseInputFlow, true, {})
        elseif arg2 == keyboard.keys.right then
            onRaise(raiseOutputFlow, false, {})
        elseif arg2 == keyboard.keys.left then
            onRaise(raiseOutputFlow, true, {})
        elseif arg2 == keyboard.keys.s then
            reactor.run()
        elseif arg2 == keyboard.keys.i then
            reactor.autoInputControl = not reactor.autoInputControl;
            os.sleep(config.updateRate);
        elseif arg2 == keyboard.keys.o then
            reactor.autoOutputControl = not reactor.autoOutputControl;
            os.sleep(config.updateRate)
        end
    end
end

-------------------------------------------------------------------------------

local function drawGui()
    local width, height = gpu.getResolution();
    local border = 2;
    local pad = 1;
    
    local fluxGateBox = gui.drawBox(colors.darkgray, {
        x = 1, 
        y = 1, 
        width = width / 2, 
        height = height / 2, 
        pad = pad,
        border = border
    });

    fluxGateBox.write(colors.white, 1, 1, "Flux-gates");
    fluxGateBox.write(colors.white, 1, 3, "Gate-input:");
    fluxGateBox.write(colors.green, 16, 3, "%s Rf/t", reactor.getInputFlow());
    fluxGateBox.write(colors.white, 1, 4, "Automatic input control enabled: %s",
        reactor.autoInputControl and "Yes" or "No")
    fluxGateBox.write(colors.white, 1, 5, "Gate-output:");
    fluxGateBox.write(colors.green, 16, 5, "%s Rf/t", reactor.getOutputFlow());
    fluxGateBox.write(colors.white, 1, 6, "Automatic output control enabled: %s",
        reactor.autoOutputControl and "Yes" or "No")

    local reactorInfoBox = gui.drawBox(colors.darkgray, {
        x = fluxGateBox.width + 1,
        y = 1,
        width = width / 2,
        height = height / 2,
        pad = pad,
        border = border
    });

    
    reactorInfoBox.write(colors.white, 1, 1, "Reactor-stats");
    reactorInfoBox.write(colors.white, 1, 3, "Temperature:");
    reactorInfoBox.write(colors.red, 20, 3,  "%s °C", reactor.temperature());
    
    reactorInfoBox.write(colors.white, 1, 4, "Containmentfield:");
    reactorInfoBox.write(colors.red, 20, 4, "%s", reactor.fieldStrength());
    reactorInfoBox.progressBar(1, 5, {
        percentage = reactor.fieldPercentage(),
        width = 20,
        fg = colors.yellow,
        bg = colors.cyan,
        textColor = colors.black
    })
    
    reactorInfoBox.write(colors.white, 1, 6, "Energy-saturation:");
    reactorInfoBox.write(colors.red, 20, 6, "%s", reactor.saturation());
    reactorInfoBox.progressBar(1, 7, {
        percentage = reactor.satPercentage(),
        width = 20,
        fg = colors.yellow,
        bg = colors.cyan,
        textColor = colors.black
    })

    reactorInfoBox.write(colors.white, 1, 8, "Fuel-conversion:");
    reactorInfoBox.write(colors.white, 20, 8, "%snb/t", reactor.info().fuelConversionRate);
    reactorInfoBox.progressBar(1, 9, {
        percentage = reactor.fuelConversionLevel(),
        width = 20,
        fg = colors.yellow,
        bg = colors.cyan,
        textColor = colors.black
    })

    reactorInfoBox.write(colors.white, 1, 11, "Generating: ");
    reactorInfoBox.write(colors.red, 20, 11, "%s Rf/t", reactor.info().generationRate);
    reactorInfoBox.write(colors.white, 1, 12, "Status:");
    reactorInfoBox.write(colors.red, 20, 12, "%s", reactor.info().status)
    gui.resetColors();
end

-------------------------------------------------------------------------------

term.clear();
term.setCursorBlink(false);

while run do
    drawGui();
    if reactor.initialized then
        reactor.run();
    end
    getKeyPress(event.pull(1));
end

term.clear()
term.setCursorBlink(false)