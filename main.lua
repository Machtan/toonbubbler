local dalgi = require("dalgi")
local toml = require("toml")
local utf8 = require("utf8")
local comic_renderer = require("comic_renderer")
local annotator = require("annotator")
local page_scroller = require("page_scroller")

local g_images = dalgi.Array:new()
local g_notes = dalgi.Array:new()
local g_comic = ""
local game

local function update_title(content_height)
    local pages = math.ceil(content_height/love.graphics.getHeight())
    local page = math.floor((-game.y) / love.graphics.getHeight()) + 1
    local title = "ToonBubbler - '%s' - Page %d/%d"
    love.window.setTitle(title:format(g_comic, page, pages))
end

function love.load()
    game = dalgi.EntityGroup:new(0, 0)
    game:overwrite_active_love_game()
    love.graphics.setBackgroundColor({255, 255, 255})
    local content_height
    if #arg > 1 then
        local comic = arg[2]
        local anno = annotator.Annotator:new(0, 0)
        if comic:match(".toml$") then
            print("Loading areas from '"..comic.."'")
            local file = io.open(comic, "r")
            local text = file:read("*a")
            local data = toml.loads(text)
            --dalgi.print(data)
            for _, note in ipairs(data.notes) do
                local rect = dalgi.Rect:from_table(note.area)
                anno:add_note(rect, note.text)
            end
            file:close()
            g_comic = data.folder
        else
            g_comic = comic
        end
        
        local renderer = comic_renderer.ComicRenderer:new(0, 0, g_comic)
        content_height = renderer:content_height()
        
        game:add(renderer)
        game:add(anno, 2)
    else
        print("Usage: love toonbubbler <comic dir | note file>")
        love.event.quit()
    end
    
    local scroller = page_scroller.PageScroller:new(
        function ()
            return game.y
        end, 
        function (value)
            game.y = value
            update_title(content_height)
        end, 
        content_height
    )
    game:add(scroller)
    
    local w, h = love.graphics.getDimensions()
    love.window.setMode(w, h, {
        resizable = true,
    })

    update_title(content_height)
    
    game:init()
end

local function save_file()
    local filename = g_comic:match("[^/]+$")
    local outfile = filename..".toml"
    local file = io.open(outfile, "w")
    file:write(toml.dumps({
        folder = g_comic,
        notes = g_notes,
    }))
    file:close()
    print("Saved data to '"..outfile.."'")
end

function love.textinput( text )
    if g_selected then
        g_selected.text = g_selected.text .. text
    end
end

function love.mousepressed( x, y, button, isTouch )
    if button == 1 then
        g_selector:start_drag(-game.x + x, -game.y + y)
    elseif button == 2 then
        local px = x + -game.x
        local py = y + -game.y
        for _, note in g_notes:iter_rev() do
            if note.area:contains(px, py) then
                --print("Selected rect #"..i)
                g_selected = note
                return
            end
        end
        g_selected = nil
    end
end

function love.mousemoved( x, y, dx, dy )
    g_selector:update(-game.x + x, -game.y + y)
end

function love.mousereleased( x, y, button, isTouch )
    g_selector:finish()
end

function love.draw()
    local y_pos = game.y
    for _, image in ipairs(g_images) do
        image:draw(game.x, y_pos)
        y_pos = y_pos + image.h
    end
    for _, note in ipairs(g_notes) do
        local area = note.area
        if note == g_selected then
            love.graphics.setColor({})
            
        else
            love.graphics.setColor({})
            love.graphics.rectangle("fill", area.x + game.x, area.y + game.y, area.width, area.height)
            love.graphics.setColor({})
            love.graphics.rectangle("line", area.x + game.x, area.y + game.y, area.width, area.height)
        end
        
    end
    if g_selector.is_dragging then
        local x, y, w, h = g_selector:get_rect()
        
        love.graphics.setColor(SELECTION_COLOR)
        love.graphics.rectangle("fill", x + game.x, y + game.y, w, h)
        love.graphics.setColor(SELECTION_BORDER_COLOR)
        love.graphics.rectangle("line", x + game.x, y + game.y, w, h)
    end
    love.graphics.setColor({255, 255, 255})
end

--love.event.quit()