local PageScroller = {}

function PageScroller:new(fn_get_y, fn_set_y, content_height)
    self.__index = self
    return setmetatable({
        fn_get_y = fn_get_y,
        fn_set_y = fn_set_y,
        content_height = content_height,
    }, self)
end

local MOUSE_SCROLL_SPEED = 10
local KEY_SCROLL_SPEED = 10

function PageScroller:y()
    return self.fn_get_y()
end

function PageScroller:y_min()
    return (-self.content_height) + love.graphics.getHeight()
end

function PageScroller:set_y(value)
    --print("Scrolling to '"..tostring(value).."'")
    local restricted = math.min(math.max(value, self:y_min()), 0)
    self.fn_set_y(restricted)
end

function PageScroller:wheelmoved(dx, dy)
    self:set_y(self:y() + dy * MOUSE_SCROLL_SPEED)
end

function PageScroller:page_up()
    self:set_y(self:y() + love.graphics.getHeight())
end

function PageScroller:page_down()
    self:set_y(self:y() - love.graphics.getHeight())
end

function PageScroller:keypressed(key, scancode, is_repeat)
    local cmd_down = love.keyboard.isDown("lgui", "rgui")
    if key == "space" then
        self:set_y(self:y() - love.graphics.getHeight())
    end
    if cmd_down then
        if key == "up" then
            self:set_y(0)
        elseif key == "down" then
            self:set_y(self:y_min())
        elseif key == "right" then
            for i=1, 10, 1 do
                self:page_down()
            end
        elseif key == "left" then
            for i=1, 10, 1 do
                self:page_up()
            end
        end
    else
        if key == "right" then
            self:page_down()
        elseif key == "left" then
            self:page_up()
        end
    end
end

function PageScroller:update()
    if love.keyboard.isDown("up") then
        self:set_y(self:y() + KEY_SCROLL_SPEED)
    elseif love.keyboard.isDown("down") then
        self:set_y(self:y() - KEY_SCROLL_SPEED)
    end
end

return {
    PageScroller = PageScroller,
}