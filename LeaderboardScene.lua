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

local displayText = ""
 
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


local function ChangeLeaderboardListener(button, event) --note: this one needs hooked up differently
    if (debug) then print("Changing Leaderboards...") end
    scoresText.text = "Loading...."
    if (debug) then print(button.lb) end
    lastScoreboardID = button.lb
    
    GetLeaderboardText(lastScoreboardID)
end

local function networkHandler(event)
    --this function updates the screen regardless of the leaderboard call
    if (debug) then print("handler called") end
    --local splitString = event.response:Split(" ")
    local displayText = ""
    local splitString = Split(event.response, "|")
    if (debug) then print(dump(splitString)) end
    for i =1, #splitString do
        if (i < #splitString) then
            displayText = displayText .. i .. ": " .. splitString[i] .. "\n"
        else
            displayText = displayText .. "Your Rank: " .. splitString[i]
        end
    end

    if(lastScoreboardID == 1) then
        displayText = "Most City Blocks: \n\n" .. displayText
    end
    if(lastScoreboardID == 2) then
        displayText = "Most Routine Cells: \n\n" .. displayText
    end
    if(lastScoreboardID == 3) then
        displayText = "Biggest Altitude Spread: \n\n" .. displayText
    end
    if(lastScoreboardID == 4) then
        displayText = "Most Distance Travelled: \n\n" .. displayText
    end
    if(lastScoreboardID == 5) then
        displayText = "Highest Score: \n\n" .. displayText
    end
    if(lastScoreboardID == 6) then
        displayText = "Highest Average Speed: \n\n" .. displayText
    end
    if(lastScoreboardID == 7) then
        displayText = "Most Time In-Game: \n\n" .. displayText
    end
    if(lastScoreboardID == 9) then
        displayText = "First To All Trophies: \n\n" .. displayText
    end

    scoresText.text = displayText
end

function GetLeaderboardText(id)
    if (debug) then print("getting LBtext") end
    if (debug) then print("server URL is" .. serverURL) end
    local url = ""
    if (id == 1) then
        url = serverURL .. '8CellLeaderboard/' .. system.getInfo("deviceID")
    end
    if (id == 2) then
        url = serverURL .. '10CellLeaderboard/' .. system.getInfo("deviceID")
    end
    if (id == 3) then
        url = serverURL .. 'AltitudeLeaderboard/' .. system.getInfo("deviceID")
    end
    if (id == 4) then
        url = serverURL .. 'DistanceLeaderboard/' .. system.getInfo("deviceID")
    end
    if (id == 5) then
        url = serverURL .. 'ScoreLeaderboard/' .. system.getInfo("deviceID")
    end
    if (id == 6) then
        url = serverURL .. 'AvgSpeedLeaderboard/' .. system.getInfo("deviceID")
    end
    if (id == 7) then
        url = serverURL .. 'TimeLeaderboard/' .. system.getInfo("deviceID")
    end
    if (id == 8) then
        url = serverURL .. 'TrophyLeaderboard/' .. system.getInfo("deviceID")
    end
    if(debugNetwork) then print("URL-  " .. url) end
    network.request(url, "GET", networkHandler)
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


    --now making different leaderboard icons.
    local lb1 = display.newImageRect(sceneGroup, "leaderboardIcons/8cellLB.png", 100, 100) --icons are 50x50, i'll scale them up here for now.
    lb1.lb = 1
    lb1.anchorX = 0
    lb1.anchorY = 0
    lb1.x = 20
    lb1.y = 700
    lb1.tap = ChangeLeaderboardListener --NOTE: these 2 lines are the right way to hook up a shared tap listener
    lb1:addEventListener("tap", lb1)

    local lb2 = display.newImageRect(sceneGroup, "leaderboardIcons/10cellLB.png", 100, 100) --icons are 50x50, i'll scale them up here for now.
    lb2.lb = 2
    lb2.anchorX = 0
    lb2.anchorY = 0
    lb2.x = 140
    lb2.y = 700
    lb2.tap = ChangeLeaderboardListener
    lb2:addEventListener("tap", lb2)

    local lb3 = display.newImageRect(sceneGroup, "leaderboardIcons/AltitudeLB.png", 100, 100) --icons are 50x50, i'll scale them up here for now.
    lb3.lb = 3
    lb3.anchorX = 0
    lb3.anchorY = 0
    lb3.x = 260
    lb3.y = 700
    lb3.tap = ChangeLeaderboardListener
    lb3:addEventListener("tap", lb3)

    local lb4 = display.newImageRect(sceneGroup, "leaderboardIcons/DistanceLB.png", 100, 100) --icons are 50x50, i'll scale them up here for now.
    lb4.lb = 4
    lb4.anchorX = 0
    lb4.anchorY = 0
    lb4.x = 380
    lb4.y = 700
    lb4.tap = ChangeLeaderboardListener
    lb4:addEventListener("tap", lb4)

    local lb5 = display.newImageRect(sceneGroup, "leaderboardIcons/ScoreLB.png", 100, 100) --icons are 50x50, i'll scale them up here for now.
    lb5.lb = 5
    lb5.anchorX = 0
    lb5.anchorY = 0
    lb5.x = 500
    lb5.y = 700
    lb5.tap = ChangeLeaderboardListener
    lb5:addEventListener("tap", lb5)

    local lb6 = display.newImageRect(sceneGroup, "leaderboardIcons/SpeedLB.png", 100, 100) --icons are 50x50, i'll scale them up here for now.
    lb6.lb = 6
    lb6.anchorX = 0
    lb6.anchorY = 0
    lb6.x = 620
    lb6.y = 700
    lb6.tap = ChangeLeaderboardListener
    lb6:addEventListener("tap", lb6)

    local lb7 = display.newImageRect(sceneGroup, "leaderboardIcons/TimeLB.png", 100, 100) --icons are 50x50, i'll scale them up here for now.
    lb7.lb = 7
    lb7.anchorX = 0
    lb7.anchorY = 0
    lb7.x = 20
    lb7.y = 820
    lb7.tap = ChangeLeaderboardListener
    lb7:addEventListener("tap", lb7)

    local lb8 = display.newImageRect(sceneGroup, "leaderboardIcons/TrophyLB.png", 100, 100) --icons are 50x50, i'll scale them up here for now.
    lb8.lb = 8
    lb8.anchorX = 0
    lb8.anchorY = 0
    lb8.x = 140
    lb8.y = 820
    lb8.tap = ChangeLeaderboardListener
    lb8:addEventListener("tap", lb8)


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
        UploadData()
        lastScoreboardID = 1
        GetLeaderboardText(1)
 
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