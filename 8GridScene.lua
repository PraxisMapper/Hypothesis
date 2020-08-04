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
--additional colors, to indicate when a cell has a bonus waiting to be collected. (colors here are visited/notYetVisited. recurring bonuses are on the other grid)
--add a bounce-and-fall popup for when you gain score, add a sound effect to that too.

local cellCollection = {}
--color codes
local visitedCell = {.8, .3, .3, 1}
local unvisitedCell = {.1, .7, .7, 1}
local timerResults8 = nil

local firstRun8 = true

local locationText = ""
local countText = ""
local pointText = ""
local timeText = ""
local directionArrow = ""

--This is sufficiently fast with debug=false ot not be real concerned about performance issues.
local function UpdateLocal8()
    --at size 23, this takes .04 seconds with debug = false
    --at size 23, this takes .55 seconds with debug = true. Lots of console writes take a while, huh
    if (debug) then print("start UpdateLocal8") end
    local currentPlusCode8 = currentPlusCode:sub(1,8)
    local previousPlusCode8 =  previousPlusCode:sub(1,8)
    if (debug) then print(currentPlusCode8) end

    if (currentPlusCode8 ~= previousPlusCode8 or firstRun8) then
        firstRun8 = false
        previousPlusCode8 = currentPlusCode8
        if (debug) then print("in 8 grid loop " ..previousPlusCode8 .. " " .. currentPlusCode8) end
        for square = 1, #cellCollection do --this is supposed to be faster than ipairs
            --if (debug) then print("displaycell " .. cellCollection[square].gridX .. "," .. cellCollection[square].gridY) end
            --check each spot based on current cell, modified by gridX and gridY
            if Visited8Cell(Shift8Block(currentPlusCode8, cellCollection[square].gridX, cellCollection[square].gridY)) then
                cellCollection[square].fill = visitedCell
            else
                cellCollection[square].fill = unvisitedCell
            end
        end
    end

    if (debug) then print("8grid done or skipped") end
    if (debug) then print(locationText.text) end
    locationText.text = "Current 8 location:" .. currentPlusCode8
    countText.text = "Total Explored 8 Cells: " .. TotalExplored8Cells()
    pointText.text = "Score: " .. Score()
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading

    if (timerResults8 == nil) then
        timerResults8 = timer.performWithDelay(500, UpdateLocal8, -1) 
    end

    if (debug) then print("end updateLocal8") end
end

local function SwitchToSmallGrid()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("10GridScene", options)
end

local function SwitchToTrophy()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("trophyScene", options)
end

local function GoToStoreScene()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("storeScene", options)
end

local function GoToLeaderboardScene()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("LeaderboardScene", options)
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    if (debug) then print("creating 8GridScene") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    countText = display.newText(sceneGroup, "Total Cells Explored: ?", display.contentCenterX, 240, native.systemFont, 20)
    pointText = display.newText(sceneGroup, "Score: ?", display.contentCenterX, 260, native.systemFont, 20)

    CreateSquareGrid(9, 65, sceneGroup, cellCollection)

    directionArrow = display.newImageRect(sceneGroup, "arrow1.png", 65, 65)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY

    local changeGrid = display.newImageRect(sceneGroup, "SmallGridButton.png", 300, 100)
    changeGrid.anchorX = 0
    changeGrid.anchorY = 0
    changeGrid.x = 60
    changeGrid.y = 1000

    local changeTrophy = display.newImageRect(sceneGroup, "TrophyRoom.png", 300, 100)
    changeTrophy.anchorX = 0
    changeTrophy.anchorY = 0
    changeTrophy.x = 390
    changeTrophy.y = 1000

    changeGrid:addEventListener("tap", SwitchToSmallGrid)
    changeTrophy:addEventListener("tap", SwitchToTrophy)
    
    local header = display.newImageRect(sceneGroup, "BigGridButton.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 100

    local store = display.newImageRect(sceneGroup, "StoreIcon.png", 100, 100)
    store.anchorX = 0
    --store.anchorY = 0
    store.x = 50
    store.y = 100
    store:addEventListener("tap", GoToStoreScene)

    local leaderboard = display.newImageRect(sceneGroup, "LeaderboardIcon.png", 100, 100)
    leaderboard.anchorX = 0
    --leaderboard.anchorY = 0
    leaderboard.x = 580
    leaderboard.y = 100
    leaderboard:addEventListener("tap", GoToLeaderboardScene)


    if (debug) then print("created 8GridScene") end

end
 
 
-- show()
function scene:show( event )
    if (debug) then print("showing 8GridScene") end
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        firstRun8 = true
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen 
        UpdateLocal8()
    end
end
 
 
-- hide()
function scene:hide( event )
    if (debug) then print("hiding 8GridScene") end
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        timer.cancel(timerResults8)
        timerResults8 = nil
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
 
    end
end
 
 
-- destroy()
function scene:destroy( event )
    if (debug) then print("destroying 8GridScene") end
 
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