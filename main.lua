local dalgi = require("dalgi")

local MOUSE_SCROLL_SPEED = 10
local KEY_SCROLL_SPEED = 20

local g_x = 0
local g_y = 0
local g_y_min = 0
local g_total_image_height = 0
local g_images = dalgi.Array:new()
local g_areas = dalgi.Array:new()
local g_is_dragging = false
local g_dragged_area
local g_cur_area
local g_comic = ""

local function update_title()
    local pages = math.ceil(-g_y_min/love.graphics.getHeight())
    local page = math.floor(-g_y / love.graphics.getHeight()) + 1
    local title = "ToonBubbler - '%s' - Page %d/%d"
    love.window.setTitle(title:format(g_comic, page, pages))
end

local function set_y(value)
    g_y = math.min(math.max(value, g_y_min), 0)
    update_title()
end

local function page_up()
    set_y(g_y + love.graphics.getHeight())
end

local function page_down()
    set_y(g_y - love.graphics.getHeight())
end

local BigImage = {}
local PART_SIZE = 1024
function BigImage:new(filepath)
    local textures = {}
    local data = love.image.newImageData(filepath)
    local w, h = data:getDimensions()
    --print(string.format("Big image at (%d, %d)", w, h))
    local w_rem = w
    local h_rem = h
    while h_rem > 0 do
        local y = h - h_rem
        local ph = math.min(PART_SIZE, h_rem)
        while w_rem > 0 do
            local x = w - w_rem
            local pw = math.min(PART_SIZE, w_rem)
            --local s = "x y w h: [%d, %d, %d, %d]"
            --print(s:format(x, y, pw, ph))
            local surf = love.image.newImageData(pw, ph)
            surf:paste(data, 0, 0, x, y, pw, ph)
            local texture = love.graphics.newImage(surf)
            table.insert(textures, {texture, x, y})
            w_rem = w_rem - PART_SIZE
        end
        w_rem = w
        h_rem = h_rem - PART_SIZE
    end
    self.__index = self
    return setmetatable({
        source = filepath,
        textures = textures,
        w = w,
        h = h,
    }, self)
end

function BigImage:draw(x, y)
    for _, data in ipairs(self.textures) do
        love.graphics.draw(data[1], x + data[2], y + data[3])
    end
end

function load_comic(directory)
    print("Loading '"..directory.."'...")
    local images = {}
    local pfile = io.popen('ls "'..directory..'"')
    local i = 1
    for filename in pfile:lines() do
        print("- '"..filename.."'")
        local filepath = directory.."/"..filename
        --print("path: '"..filepath.."'")
        local image = BigImage:new(filepath)
        images[i] = image
        i = i + 1
    end
    pfile:close()
    print("Loaded!")
    return images
end

function love.load()
    love.graphics.setBackgroundColor({255, 255, 255})
    g_images:append(load_comic("tog0"))
    local y_min = 0
    for _, image in ipairs(g_images) do
        y_min = y_min - image.h
    end
    g_total_image_height = -y_min
    y_min = y_min + love.graphics.getHeight()
    g_y_min = y_min
    update_title()
end

function love.update()
    if love.keyboard.isDown("up") then
        set_y(g_y + KEY_SCROLL_SPEED)
    elseif love.keyboard.isDown("down") then
        set_y(g_y - KEY_SCROLL_SPEED)
    end
end

function love.keypressed(key, scancode, is_repeat)
    local cmd_down = love.keyboard.isDown("lgui", "rgui")
    if key == "space" then
        set_y(g_y - love.graphics.getHeight())
    end
    if cmd_down then
        if key == "up" then
            set_y(0)
        elseif key == "down" then
            set_y(g_y_min)
        elseif key == "right" then
            for i=1, 10, 1 do
                page_down()
            end
        elseif key == "left" then
            for i=1, 10, 1 do
                page_up()
            end
        end
    else
        if key == "right" then
            page_down()
        elseif key == "left" then
            page_up()
        end
    end
end

function love.wheelmoved(dx, dy)
    set_y(g_y + dy * MOUSE_SCROLL_SPEED)
end

function love.draw()
    local y_pos = g_y
    for _, image in ipairs(g_images) do
        image:draw(g_x, y_pos)
        y_pos = y_pos + image.h
    end
end

--love.event.quit()