local composer = require( "composer" )
local scene = composer.newScene()

require("localNetwork")
require("helpers")

--TODO:
--display options for various leaderboards
----make temp icons for these leaderboards, make imageRects and eventHandlers for them.
--set local nickname (or assign it randomly)
--display current rank in each category along with leaders.
--Icons for leaderboards? (use images as tabs?)
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
local function SwitchToSmallGrid()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("10GridScene", options)
end

local function SwitchToBigGrid()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("8GridScene", options)
end
 
local scoresText = {}
local lastScoreboardID = 0

local function networkHandler(event)
    --this function updates the screen regardless of the leaderboard call
    if (debug) then print("handler called") end
    --local splitString = event.response:Split(" ")
    local splitString = Split(event.response, "|")
    if (debug) then print(dump(splitString)) end
    local displayText = ""
    for i =1, #splitString do
        if (i < #splitString) then
            displayText = displayText .. i .. ": " .. splitString[i] .. "\n"
        else
            displayText = displayText .. "Your Rank: " .. splitString[i]
        end
    end

    if(lastScoreboardID == 1) then
        displayText = "Most Routine Cells: \n\n" .. displayText
    end

    scoresText.text = displayText
end

local function GetLeaderboardText(id)
    if (debug) then print("getting LBtext") end
    if (id == 1) then
        local url = serverURL .. '10CellLeaderboard/' .. system.getInfo("deviceID")
        if(debugNetwork) then print(url) end
        lastScoreboardID = 1
        network.request(url, "GET", networkHandler)
    end
end
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
    if (debug) then print("Creating LeaderboardScene") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    local header = display.newImageRect(sceneGroup, "LeaderboardHeader.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 100 

    local changeGrid = display.newImageRect(sceneGroup, "BigGridButton.png", 300, 100)
    changeGrid.anchorX = 0
    changeGrid.anchorY = 0
    changeGrid.x = 60
    changeGrid.y = 1000

    local changegrid2 = display.newImageRect(sceneGroup, "SmallGridButton.png", 300, 100)
    changegrid2.anchorX = 0
    changegrid2.anchorY = 0
    changegrid2.x = 390
    changegrid2.y = 1000

    changeGrid:addEventListener("tap", SwitchToBigGrid)
    changegrid2:addEventListener("tap", SwitchToSmallGrid)

    if (debug) then print("buttons done") end
    local textOptions = {}
    textOptions.parent =  sceneGroup
    textOptions.text = "Loading..."
    textOptions.x = display.contentCenterX
    textOptions.y = 160
    textOptions.width = 550
    textOptions.height = 0
    textOptions.font = native.systemFont
    textOptions.fontSize = 28

    scoresText = display.newText(textOptions)
    scoresText.anchorY = 0
    if (debug) then print("text made") end
    GetLeaderboardText(1)
    if (debug) then print("created LeaderboardScene") end
end
 
 
-- show()
function scene:show( event )
    if (debug) then print("showing LeaderboardScene") end
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
 
    end
end
 
 
-- hide()
function scene:hide( event )
    if (debug) then print("hiding leaderboardScene") end
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
 
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
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