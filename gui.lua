local component = require("component");
local gpu = component.gpu;
local colors = require("colorTable");
local config = require("config")
local term = require("term")

local function printOnPos(col, row, val, ...)
    term.setCursor(col, row);
    print(val:format(...));
end

local function resetForeground()
    gpu.setForeground(config.defaultForeground);
end

local function resetBackground()
    gpu.setBackground(config.defaultBackground);
end

local function resetColors()
    resetForeground();
    resetBackground();
end

local function colorizedPrintOnPos(color, col, row, val, ...)
    gpu.setForeground(color);
    printOnPos(col, row, val, ...);
    resetForeground();
end

local function printInBox(box, color, col, row, val, ...)
    local x = box.x + box.pad + box.border + col;
    local y = box.y + box.pad + box.border + row;
    colorizedPrintOnPos(color, x, y, val, ...);
    return box;
end


local function progressBarInBox(box, col, row, bar)
    local step = 100 / bar.width;
    local steps = math.floor(bar.percentage / step);
    local progressBox = string.rep(" ", steps);
    local fullBox = string.rep(" ", 20)
    
    gpu.setBackground(bar.bg);
    printInBox(box, bar.bg, col, row, fullBox);
    gpu.setBackground(bar.fg);
    printInBox(box, bar.fg, col, row, progressBox);
    printInBox(box, bar.textColor, col, row, "%s%%", bar.percentage);
    gpu.setBackground(box.bg);
    return box;
end


local function drawBox(color, box)
    local x = box.x + box.pad + box.border;
    local y = box.y + box.pad + box.border;
    local width = box.width - box.border;
    local height = box.height - box.border;

    gpu.setBackground(color);
    gpu.setForeground(color);
    gpu.fill(x, y, width, height, " ");
    resetForeground();
    
    box.write = function(color, col, row, val, ...)
        printInBox(box, color, col, row, val, ...);
    end

    box.progressBar = function(color, col, row, bar)
        progressBarInBox(box, color, col, row, bar);
    end

    box.bg = color;
    return box
end

return {
    drawBox = drawBox;
    resetColors = resetColors;
}