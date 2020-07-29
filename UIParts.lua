--TODO
--additional colors, to indicate when a cell has a bonus waiting to be collected.
--add a bounce-and-fall popup for when you gain score, add a sound effect to that too.

local cellCollection = {}
local gridGroup = display.newGroup()

--color codes
local unvisitedCell = {.3, .3, .3, 1}
local visitedCell = {.1, .1, .7, 1}

locationText = display.newText("Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
timeText = display.newText("Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
countText = display.newText("Total Cells Explored: ?", display.contentCenterX, 240, native.systemFont, 20)
pointText = display.newText("Score: ?", display.contentCenterX, 260, native.systemFont, 20)

directionArrow = display.newImageRect("arrow1.png", 25, 25)
directionArrow.x = display.contentCenterX
directionArrow.y = display.contentCenterY

function CreateSquareGrid(gridSize)
    --instead of hard-coding the grid, how do i dynamically make it?
    --size is square, X by Y size. Must be odd so that i can have a center square. Even values get treated as one larger to be made odd.
    local padding = 1 --space between cells.
    local cellSize = 25 -- square size in pixels
    local range = math.floor(gridSize / 2) -- 7 becomes 3, which is right. 6 also becomes 3.

    for x = -range, range, 1 do
        for y = -range, range, 1 do
            --create cell, tag it with x and y values.
            local newSquare = display.newRect(gridGroup, display.contentCenterX + (cellSize * x) + x , display.contentCenterY + (cellSize * y) + y , cellSize, cellSize) --x y w h
            newSquare.gridX = x
            newSquare.gridY = -y --invert this so cells get identified top-to-bottom, rather than bottom-to-top
            cellCollection[#cellCollection + 1] = newSquare
        end
    end
end

--This is sufficiently fast with debug=false ot not be real concerned about performance issues.
function UpdateCustomGrid()
    --at size 23, this takes .04 seconds with debug = false
    --at size 23, this takes .55 seconds with debug = true. Lots of console writes take a while, huh
    --print("start UpdateGrid")
    for square = 1, #cellCollection do --this is supposed to be faster than ipairs
        if (debug) then print("displaycell " .. cellCollection[square].gridX .. "," .. cellCollection[square].gridY) end
        --check each spot based on current cell, modified by gridX and gridY
        if VisitedCell(shiftCell(currentPlusCode, cellCollection[square].gridX, cellCollection[square].gridY)) then
            cellCollection[square].fill = visitedCell
        else
            cellCollection[square].fill = unvisitedCell
        end
    end
    --print("end updateGrid")
end