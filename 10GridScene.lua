local composer = require( "composer" )
local scene = composer.newScene()

--require("timer")
require("UIParts")
require("database")
 
if (debug) then print("10GridScene loading") end
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

--TODO
--additional colors, to indicate when a cell has a bonus waiting to be collected. (colors here are none/daily/weekly. FirstTime is on the other grid now)
--add a bounce-and-fall popup for when you gain score, add a sound effect to that too.

local cellCollection = {}
--color codes
local unvisitedCell = {.3, .3, .3, 1}
local visitedCell = {.1, .1, .7, 1}
local timerResults ={}

local firstRun = true

local locationText = ""
local countText = ""
local pointText = ""
local timeText = ""
local directionArrow = ""

--This is sufficiently fast with debug=false ot not be real concerned about performance issues.
local function UpdateLocal()
    --at size 23, this takes .04 seconds with debug = false
    --at size 23, this takes .55 seconds with debug = true. Lots of console writes take a while, huh
    if (debug) then print("start UpdateLocal") end
    if (debug) then print(currentPlusCode) end

    if (currentPlusCode ~= previousPlusCode or firstRun) then
        firstRun = false
        previousPlusCode = currentPlusCode
        for square = 1, #cellCollection do --this is supposed to be faster than ipairs
            --if (debug) then print("displaycell " .. cellCollection[square].gridX .. "," .. cellCollection[square].gridY) end
            --check each spot based on current cell, modified by gridX and gridY
            if VisitedCell(shiftCell(currentPlusCode, cellCollection[square].gridX, cellCollection[square].gridY)) then
                cellCollection[square].fill = visitedCell
            else
                cellCollection[square].fill = unvisitedCell
            end
        end
    end

    if (debug) then print("grid done or skipped") end
    if (debug) then print(locationText.text) end
    locationText.text = "Current location:" .. currentPlusCode
    countText.text = "Total Explored Cells: " .. TotalExploredCells()
    pointText.text = "Score: " .. Score()
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading


    if (debug) then print("end updateLocal") end
end

local function SwitchToBigGrid()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("8GridScene", options)
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    if (debug) then print("creating 10GridScene") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    countText = display.newText(sceneGroup, "Total Cells Explored: ?", display.contentCenterX, 240, native.systemFont, 20)
    pointText = display.newText(sceneGroup, "Score: ?", display.contentCenterX, 260, native.systemFont, 20)

    CreateSquareGrid(23, 25, sceneGroup, cellCollection)

    directionArrow = display.newImageRect(sceneGroup, "arrow1.png", 25, 25)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY


    local changeGrid = display.newImageRect(sceneGroup, "BigGridButton.png", 300, 100)
    changeGrid.anchorX = 0
    changeGrid.anchorY = 0
    changeGrid.x = 60
    changeGrid.y = 1000

    changeGrid:addEventListener("tap", SwitchToBigGrid)
    if (debug) then print("created 10GridScene") end

end
 
-- show()
function scene:show( event )
    if (debug) then print("showing 10GridScene") end
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen 
            timerResults = timer.performWithDelay(500, UpdateLocal, -1)  
    end
end
 
-- hide()
function scene:hide( event )
    if (debug) then print("hiding 10GridScene") end
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        timer.cancel(timerResults)
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
 
    end
end
 
-- destroy()
function scene:destroy( event )
    if (debug) then print("destroying 10GridScene") end
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
 
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene