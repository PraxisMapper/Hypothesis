--the popup to claim an area in the app.
--Spend points == size of the whole area to color all it's cells sky blue to show ownership.
local composer = require( "composer" )
require("database")
require("localNetwork")
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local bg = ""
local textDisplay = ""
local yesButton = ""
local noButton = ""

local function yesListener()
    --check walking score, if high enough, spend points and color this area in.

    if (debug) then print("yes tapped") end
    local points = Score()
    if (debug) then print(points) end
    if (tonumber(points) >= tonumber(tappedAreaScore)) then
        if (debug) then print("claiming") end
        SpendPoints(tappedAreaScore)
        ClaimAreaLocally(tappedAreaMapDataId, tappedAreaName, tappedAreaScore)
        forceRedraw = true
    end
    composer.hideOverlay("overlayAreaClaim")
end

local function noListener()
    composer.hideOverlay("overlayAreaClaim")
end

function GetAreaScore(mapdataid)
    if (debug) then print("getting score for " .. mapdataid .. "locally") end
    network.request(serverURL .. "MapData/CalculateMapDataScore/" .. mapdataid, "GET", AreaSizeListener)
end

function AreaSizeListener(event)
    if (debug) then print("AreaSize local response: " .. event.response .. " " .. event.status) end
    local scoreResults = Split(event.response, "|")[2]
    tappedAreaScore = tonumber(scoreResults)
    if (tappedAreaScore == 0) then
        tappedAreaScore = 1
    end
    if (debug) then print(scoreResults) print(Score()) end
    textDisplay.text = textDisplay.text .. scoreResults .. " points?"
    if (tappedAreaScore <= tonumber(Score())) then
        yesButton.isVisible = true
    else
        if (debug) then print(tappedAreaScore .. " is bigger than " .. Score())  end
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    local bgFill = {.6, .6, .6, 1}
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 700, 500)
    bg.fill = bgFill
    textDisplay = display.newText(sceneGroup, "Claim X with Y points?", display.contentCenterX, display.contentCenterY - 150, 600, 100, native.systemFont, 30)

    yesButton = display.newImageRect(sceneGroup, "themables/ACYes.png", 100, 100)
    yesButton.x = display.contentCenterX - 200
    yesButton.y = display.contentCenterY + 100
    yesButton:addEventListener("tap", yesListener)
    yesButton.isVisible = false

    noButton = display.newImageRect(sceneGroup, "themables/ACNo.png", 100, 100)
    noButton.x = display.contentCenterX + 200
    noButton.y = display.contentCenterY + 100
    noButton:addEventListener("tap", noListener)
 
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        textDisplay.text = "Claim " .. tappedAreaName .. " with "
        GetAreaScore(tappedAreaMapDataId) 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
 
    end
end
 
 
-- hide()
function scene:hide( event )
 
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