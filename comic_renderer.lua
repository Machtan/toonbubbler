
local BigImage = {}
local PART_SIZE = 1024
function BigImage:new(filepath, part_size)
    local PART_SIZE = part_size or PART_SIZE
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

local ComicRenderer = {}

function ComicRenderer:new(x, y, directory)
    local images = {}
    local pfile = io.popen('ls "'..directory..'"')
    local i = 1
    for filename in pfile:lines() do
        --print("- '"..filename.."'")
        local filepath = directory.."/"..filename
        --print("path: '"..filepath.."'")
        local image = BigImage:new(filepath)
        images[i] = image
        i = i + 1
    end
    pfile:close()
    self.__index = self
    return setmetatable({
        x = x,
        y = y,
        images = images,
    }, self)
end

function ComicRenderer:content_height()
    local height = 0
    for _, image in ipairs(self.images) do
        height = height + image.h
    end
    return height
end

function ComicRenderer:draw(ox, oy)
    local ox, oy = ox or 0, oy or 0
    local x = self.x + ox
    local rel_y = self.y + oy
    for _, image in ipairs(self.images) do
        image:draw(x, rel_y)
        rel_y = rel_y + image.h
    end
end

return {
    ComicRenderer = ComicRenderer,
}