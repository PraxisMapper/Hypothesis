-----------------------------------------------------------------------------------------
-- main.lua
-----------------------------------------------------------------------------------------
--remember, lua requires code to be in order to reference (cant call a function that's lower in the file than the current one)

--debugging helper function
function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

require("database")
local debug = true --set false for release builds.
startDatabase()

--uncomment when testing to clear local data.
--ResetDatabase()
--uncomment to add test cell in lower right corner of 11x11 grid
--fillinTestCells()

require("plusCodes")
currentPlusCode = ""
lastPlusCode = ""

function fillinTestCells()
    AddPlusCode("849VCRXR+4M") --5, -5 means lower right cell
    --AddPlusCode("849VCRXR+9C") --home base cell, center
end

--TODO:

--display objects
local locationText = display.newText("Current location:" .. currentPlusCode, display.contentCenterX, 400, native.systemFont, 16)
local timeText = display.newText("Current time:" .. os.date("%X"), display.contentCenterX, 420, native.systemFont, 16)
local countText = display.newText("Total Cells Explored: ?", display.contentCenterX, 440, native.systemFont, 16)
local cellCollection = {}
local gridGroup = display.newGroup()
local directionArrow = display.newImageRect("arrow1.png", 25, 25)
directionArrow.x = display.contentCenterX
directionArrow.y = display.contentCenterY

--color codes
local unvisitedCell = {.3, .3, .3, 1}
local visitedCell = {.1, .1, .7, 1}


--this might be replaced by CreateCustomGrid, keeping for text display of grid values if I wanted to go down to level 11.
function drawGrid()
--currentPlusCode is in center of a 5x5 grid?
--Need to work out which cells are around my cell? is there a way to math this, at least for a 10-digit code?
-- oh right, the +3 level is a 5x4 ordered grid. so...
--'23456789CFGHJMPQRVWX'
-- R V W X
-- J M P Q 
-- C F G H 
-- 6 7 8 9 
-- 2 3 4 5 
--whats the fastest way to dig through this? 
--alter the last digit of the current cell to check neighbors, or 2nd to last cell if it overflows
--that only matters if I use 11-digit or more codes. At the 10 digit level its still 20x20. So, same idea, but one is X and one is Y
--oh good. SO if I'm at +P8, I can check P6, P7, P9, and PC in that row,
--and J6, M6, Q6, and R6 in that column, and the combinations of those values on lat/long.
--so J-R, 6-C. 25 total cells to look up when updating the grid. Can do.

--rects per quadrant. Doing 3x3 for proof of concept, so 22 is the middle cell.
--so, the coordinates are XY on the rect's name.


end

--replaced with UpdateCustomGrid?
function paintGrid()
end

function shiftCell(pluscode, xShift, yShift)
    --take the current cell, move it some number of cells in both directions (positive or negative)
    --will probably only work for values between -39 and 39. Shifting by 20 means you've move up 1 higher level cell entirely,
    --and while this checks once for that, it doesn't check twice
    local newCode = pluscode
    local currentDigit = ""
    local digitIndex = 0
    if (debug)then print ("shifting cell " .. pluscode) end
    --do X shift
    if (xShift ~= 0) then
        if (debug)then print ("Shifting X " .. xShift) end
        currentDigit = pluscode:sub(11, 11)
        digitIndex = CODE_ALPHABET_:find(currentDigit)
        digitIndex = digitIndex + xShift
        --i probably also need to adjust position 8 in the string if this happens in either direction
        if (digitIndex <= 0) then
            digitIndex = 20 + digitIndex
        end
        if (digitIndex > 20) then
            digitIndex = digitIndex - 20
        end
        currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
        newCode = newCode:sub(1, 10) .. currentDigit
    end
    if (debug)then print ("newcode is " .. newCode) end

    --do Y shift
    if (yShift ~= 0) then
        if (debug)then print ("shifting Y " .. yShift) end
        --get last digit, move it 1 notch higher on the list
        currentDigit = pluscode:sub(10, 10)
        digitIndex = CODE_ALPHABET_:find(currentDigit)
        digitIndex = digitIndex + yShift
        --i probably also need to adjust position 7 in the string if this happens in either direction
        if (digitIndex <= 0) then
            digitIndex = 20 + digitIndex
        end
        if (digitIndex > 20) then
            digitIndex = digitIndex - 20
        end
        currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
        newCode = newCode:sub(1, 9) .. currentDigit .. newCode:sub(11,11)
    end
    if (debug)then print ("newcode is " .. newCode) end

    return newCode
end


function update()
    --todo: call this once a second to update the screen? or only update on location change
end

local function gpsListener(event)
    if (debug) then
        print("got GPS event")
        if (event.errorCode ~= nil) then
            print("GPS Error " .. event.errorCode)
            return
        end

        print("Coords " .. event.latitude .. " " ..event.longitude)
    end

    local pluscode = tryMyEncode(event.latitude, event.longitude, 10); --only goes to 10 right now. TODO expand if I want to for fun.
    if (debug)then print ("Plus Code: " .. pluscode) end
    currentPlusCode = pluscode

    --update stuff that always needs updated    
    timeText.text = "Current time:" .. os.date("%X")
    --todo update heading
    directionArrow.rotation = event.direction

    UpdateCustomGrid() --this may need moved after changing plus codes

    if (lastPlusCode == currentPlusCode) then
        --dont update stuff, we're still standing in the same spot.
        return
    end

    --now update stuff that only needs processed on entering a new cell
    lastPlusCode = currentPlusCode
   
    --do DB processing on plus codes.
    AddPlusCode(pluscode)

    --do screen updates
    paintGrid()
    
    locationText.text = "Current location:" .. currentPlusCode
    countText.text = "Total Explored Cells: " .. TotalExploredCells()

end

function CreateSquareGrid(gridSize)
    --instead of hard-coding the grid, how do i dynamically make it?
    --size is square, X by Y size. Must be odd so that i can have a center square.
    local padding = 1 --space between cells.
    local cellSize = 25 -- square size in pixels
    local range = math.floor(gridSize / 2) -- 7 becomes 3, which is right.

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

CreateSquareGrid(11)

function UpdateCustomGrid()
    for square = 1, #cellCollection do --this is supposed to be faster than ipairs
        if (debug) then print("displaycell " .. cellCollection[square].gridX .. "," .. cellCollection[square].gridY) end
        --check each spot based on current cell, modified by gridX and gridY
        if VisitedCell(shiftCell(currentPlusCode, cellCollection[square].gridX, cellCollection[square].gridY)) then
            cellCollection[square].fill = visitedCell
        else
            cellCollection[square].fill = unvisitedCell
        end
    end
end

--will need to remove this manually on exit
Runtime:addEventListener("location", gpsListener) 