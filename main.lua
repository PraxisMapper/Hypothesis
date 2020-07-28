-----------------------------------------------------------------------------------------
-- main.lua
-----------------------------------------------------------------------------------------
--remember, lua requires code to be in order to reference (cant call a function that's lower in the file than the current one)

--TODO: add an indicator to show facing. This should get updated on location change all the time.
--need a sprite to point a direction, and then rotate it.

--debugging helper functoin
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

-- Your code here
require("database")
local debug = true --set false for release builds.
startDatabase()

--uncomment when testing to clear local data.
--ResetDatabase()

require("plusCodes")
currentPlusCode = ""
lastPlusCode = ""


--TODO:
--draw a grid on screen. Unexplored tiles should be grey, explored tiles will be blue for now.
--rescale display? this game should be vertical.

local locationText = display.newText("Current location:" .. currentPlusCode, display.contentCenterX, 400, native.systemFont, 16)
local timeText = display.newText("Current time:" .. os.date("%X"), display.contentCenterX, 420, native.systemFont, 16)
local countText = display.newText("Total Cells Explored: ?", display.contentCenterX, 440, native.systemFont, 16)



local gridGroup = display.newGroup()
local unvisitedCell = {.3, .3, .3, 1}
local visitedCell = {.1, .1, .7, 1}

local rect11 = display.newRect(gridGroup, display.contentCenterX - 26, display.contentCenterY - 26, 25, 25) --x y w h
local rect12 = display.newRect(gridGroup, display.contentCenterX, display.contentCenterY - 26, 25, 25) --x y w h
local rect13 = display.newRect(gridGroup, display.contentCenterX + 26, display.contentCenterY - 26, 25, 25) --x y w h
local rect21 = display.newRect(gridGroup, display.contentCenterX - 26, display.contentCenterY, 25, 25) --x y w h
local rect22 = display.newRect(gridGroup, display.contentCenterX, display.contentCenterY, 25, 25) --x y w h
local rect23 = display.newRect(gridGroup, display.contentCenterX + 26, display.contentCenterY, 25, 25) --x y w h
local rect31 = display.newRect(gridGroup, display.contentCenterX - 26, display.contentCenterY + 26, 25, 25) --x y w h
local rect32 = display.newRect(gridGroup, display.contentCenterX, display.contentCenterY + 26, 25, 25) --x y w h
local rect33 = display.newRect(gridGroup, display.contentCenterX + 26, display.contentCenterY + 26, 25, 25) --x y w h

local directionArrow = display.newImageRect(gridGroup, "arrow1.png", 25, 25)
directionArrow.x = display.contentCenterX
directionArrow.y = display.contentCenterY


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

drawGrid()


function paintGrid()
    --this is where we set colors, call this function on locationChange
    --PoC: color center rect.
    --expand to 3x3 next. Last digit is X axis, second to last is Y axis

    if (VisitedCell(currentPlusCode)) then
        rect22.fill = visitedCell
    else
        rect22.fill = unvisitedCell
    end

    --center handled, now handle the surrounding cells.
    local celltocheck = shiftCellEast(currentPlusCode)
    if (debug) then print("East cell is " .. celltocheck) end
    if (VisitedCell(celltocheck)) then
        rect23.fill = visitedCell
    else
        rect23.fill = unvisitedCell
    end
    
    celltocheck = shiftCellWest(currentPlusCode)
    if (debug) then print("west cell is " .. celltocheck) end
    if (VisitedCell(celltocheck)) then
        rect21.fill = visitedCell
    else
        rect21.fill = unvisitedCell
    end
    
    celltocheck = shiftCellNorth(currentPlusCode)
    if (debug) then print("north cell is " .. celltocheck) end
    if (VisitedCell(celltocheck)) then
        rect12.fill = visitedCell
    else
        rect12.fill = unvisitedCell
    end

    celltocheck = shiftCellSouth(currentPlusCode)
    if (debug) then print("south cell is " .. celltocheck) end
    if (VisitedCell(celltocheck)) then
        rect32.fill = visitedCell
    else
        rect32.fill = unvisitedCell
    end

    --and now 3x3 corners.
    celltocheck = shiftCellNorth(shiftCellEast(currentPlusCode))
    if (debug) then print("northeast cell is " .. celltocheck) end
    if (VisitedCell(celltocheck)) then
        rect13.fill = visitedCell
    else
        rect13.fill = unvisitedCell
    end

    celltocheck = shiftCellNorth(shiftCellWest(currentPlusCode))
    if (debug) then print("northwest cell is " .. celltocheck) end
    if (VisitedCell(celltocheck)) then
        rect11.fill = visitedCell
    else
        rect11.fill = unvisitedCell
    end

    celltocheck = shiftCellSouth(shiftCellWest(currentPlusCode))
    if (debug) then print("southwest cell is " .. celltocheck) end
    if (VisitedCell(celltocheck)) then
        rect31.fill = visitedCell
    else
        rect31.fill = unvisitedCell
    end

    celltocheck = shiftCellSouth(shiftCellEast(currentPlusCode))
    if (debug) then print("southeast cell is " .. celltocheck) end
    if (VisitedCell(celltocheck)) then
        rect33.fill = visitedCell
    else
        rect33.fill = unvisitedCell
    end

end

function shiftCellEast(pluscode)
    --get last digit, move it 1 notch higher on the list
    local currentDigit = pluscode:sub(11, 11)
    local digitIndex = CODE_ALPHABET_:find(currentDigit)
    digitIndex = digitIndex + 1
    if (digitIndex == 21) then
        --i probably also need to adjust position 8 in the string if this happens. Would be position 7 if north/south.
        digitIndex = 1 
    end
    currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
    local newCode = pluscode:sub(1, 10) .. currentDigit
    return newCode
end

function shiftCellWest(pluscode)
    --get last digit, move it 1 notch higher on the list
    local currentDigit = pluscode:sub(11, 11)
    local digitIndex = CODE_ALPHABET_:find(currentDigit)
    digitIndex = digitIndex - 1
    if (digitIndex <= 0) then
        --i probably also need to adjust position 8 in the string if this happens.
        digitIndex = 20
    end
    currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
    local newCode = pluscode:sub(1, 10) .. currentDigit
    return newCode
end

function shiftCellNorth(pluscode)
    --get last digit, move it 1 notch higher on the list
    local currentDigit = pluscode:sub(10, 10)
    local digitIndex = CODE_ALPHABET_:find(currentDigit)
    digitIndex = digitIndex + 1
    if (digitIndex == 21) then
        --i probably also need to adjust position 7 in the string if this happens.
        digitIndex = 1 
    end
    currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
    local newCode = pluscode:sub(1, 9) .. currentDigit .. pluscode:sub(11,11)
    return newCode
end

function shiftCellSouth(pluscode)
    --get last digit, move it 1 notch higher on the list
    local currentDigit = pluscode:sub(10, 10)
    local digitIndex = CODE_ALPHABET_:find(currentDigit)
    digitIndex = digitIndex - 1
    if (digitIndex < 1) then
        --i probably also need to adjust position 7 in the string if this happens.
        digitIndex = 20 
    end
    currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
    local newCode = pluscode:sub(1, 9) .. currentDigit .. pluscode:sub(11,11)
    return newCode
end

function shiftCell(pluscode, xShift, yShift)
    --take the current cell, move it some number of cells in both directions (positive or negative)
    --will probably only work for values between -19 and 19. Shifting by 20 means you've move up 1 higher level cell entirely.
    local newCode = pluscode
    --do X shift
    if (xShift ~= 0) then
    end
    --do Y shift
    if (yShift ~= 0) then
    end

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

--will need to remove this manually on exit
Runtime:addEventListener("location", gpsListener) 