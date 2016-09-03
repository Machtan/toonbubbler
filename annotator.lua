local dalgi = require("dalgi")

local SquareSelector = {}

local SQUARE_FILL_COLOR = {200, 200, 255, 100}
local SQUARE_BORDER_COLOR = {200, 200, 255}
function SquareSelector:new(button, cb_finish, fn_get_offset)
    self.__index = self
    return setmetatable({
        button = button,
        is_dragging = false,
        cb_finish = cb_finish,
        fn_get_offset = fn_get_offset,
    }, self)
end

function SquareSelector:get_offset()
    if self.fn_get_offset ~= nil then
        return self.fn_get_offset()
    else
        return 0, 0
    end
end

function SquareSelector:start(screen_x, screen_y)
    local ox, oy = self:get_offset()
    self.is_dragging = true
    self.start_x = screen_x + ox
    self.start_y = screen_y + oy
    self.end_x = self.start_x
    self.end_y = self.start_y
end

function SquareSelector:mousepressed(x, y, button, is_touch)
    if button == self.button then
        self:start(x, y)
    end
end

function SquareSelector:get_rect()
    local rx = math.min(self.start_x, self.end_x)
    local rw = math.max(self.start_x, self.end_x) - rx
    local ry = math.min(self.start_y, self.end_y)
    local rh = math.max(self.start_y, self.end_y) - ry
    return dalgi.Rect:new(rx, ry, rw, rh)
end

function SquareSelector:mousemoved( x, y, dx, dy )
    if self.is_dragging then
        local ox, oy = self:get_offset()
        self.end_x = x + ox
        self.end_y = y + oy
    end
end

function SquareSelector:draw(ox, oy)
    if self.is_dragging then
        local ox, oy = ox or 0, oy or 0
        local r = self:get_rect()
        love.graphics.setColor(SQUARE_FILL_COLOR)
        love.graphics.rectangle("fill", r.x + ox, r.y + oy, r.width, r.height)
        love.graphics.setColor(SQUARE_BORDER_COLOR)
        love.graphics.rectangle("line", r.x + ox, r.y + oy, r.width, r.height)
        love.graphics.setColor({255, 255, 255})
    end
end

function SquareSelector:mousereleased(x, y, button, is_touch)
    if button == self.button then
        if self.is_dragging then
            self.cb_finish(self:get_rect(), self)
            self.is_dragging = false
        end
    end
end


local Annotation = {}

local NORMAL_FILL_COLOR = {255, 255, 255, 100}
local NORMAL_BORDER_COLOR = {255, 255, 255}
local SELECTED_FILL_COLOR = {200, 200, 255, 100}
local SELECTED_BORDER_COLOR = {200, 200, 255}
function Annotation:new(rect)
    self.__index = self
    return setmetatable({
        rect = rect,
        text = "",
        text_areas = {},
        selected = false,
    }, self)
end

function Annotation:set_text(text)
    self.text = text
    self.text_areas = {}
    -- TODO layout
    local t = love.graphics.newText(love.graphics.getFont(), "")
    t:setf(text, self.rect.width, "left")
    table.insert(self.text_areas, t)
end

function Annotation:draw(ox, oy)
    local ox, oy = ox or 0, oy or 0
    local fill_color = self.selected and SELECTED_FILL_COLOR or NORMAL_FILL_COLOR
    local border_color = self.selected and SELECTED_BORDER_COLOR or NORMAL_BORDER_COLOR
    local r = self.rect
    love.graphics.setColor(fill_color)
    love.graphics.rectangle("fill", r.x + ox, r.y + oy, r.width, r.height)
    love.graphics.setColor(border_color)
    love.graphics.rectangle("line", r.x + ox, r.y + oy, r.width, r.height)
    love.graphics.setColor({255, 255, 255})
    for _, text_obj in ipairs(self.text_areas) do
        love.graphics.draw(text_obj, ox, oy)
    end
end

function Annotation:contains(x, y)
    return self.rect:contains(x, y)
end


local Annotator = {}

function Annotator:new(x, y)
    self.__index = self
    return setmetatable({
        x = x,
        y = y,
        notes = {},
    }, self)
end

function Annotator:init(game)
    print("Annotator initialised!")
    self.game = game
end

function Annotator:add_note(rect, text)
    local note = Annotation:new(rect)
    note:set_text(text)
    table.insert(self.notes, note)
end

function Annotator:mousepressed(x, y, button, is_touch)
    if button ~= 1 then
        return
    end
    local note_clicked = false
    local gx, gy = x + self.game.x, y - self.game.y
    for _, note in ipairs(self.notes) do
        note.selected = false
        if note:contains(gx, gy) then
            if not note_clicked then
                note.selected = true
                note_clicked = true
            end
        end
    end
    if not note_clicked then
        local selector = SquareSelector:new(1,
        function (rect, sel) -- Finish callback
            local note = Annotation:new(rect)
            table.insert(self.notes, note)
            self.game:remove(sel)
        end,
        function () -- Offset getter
            return self.game.x, -self.game.y
        end)
        selector:start(x, y)
        self.game:add(selector, 2)
    end
end

function Annotator:mousereleased(x, y, button, is_touch)
    
end

function Annotator:draw(ox, oy)
    local ox, oy = ox or 0, oy or 0
    local x, y = self.x + ox, self.y + oy
    for _, note in ipairs(self.notes) do
        note:draw(x, y)
    end
end


return {
    Annotator = Annotator,
}