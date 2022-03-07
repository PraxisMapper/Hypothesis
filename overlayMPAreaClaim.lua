--the popup to claim an area in the app for Multiplayer mode.
--Spend points == size or length of the whole area/path.
local composer = require( "composer" )
local scene = composer.newScene()
require("database")
require("dataTracker") --for requestedMapTileCells

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local bg = ""
local textDisplay = ""
local ownerDisplay = ""
local yesButton = ""
local noButton = ""
local hasPoints = false
local isDifferentTeam = false

local oldTeam = 0;

local function yesListener()
    --check walking score, if high enough, spend points and color this area in.
    if (debug) then print("yes tapped") end
    local points = Score()
    if (tonumber(points) >= tappedAreaScore) then
        if (debug) then print("claiming") end
        ClaimMPArea()
        forceRedraw = true
        yesButton.isVisible = false
        noButton.isVisible = false
    end
    return true
end

local function noListener()
    composer.hideOverlay("overlayMPAreaClaim")
    return true
end

function GetAreaOwner(mapDataId)
    network.request(serverURL .. "Data/Place/" .. tappedAreaMapDataId .. "/teamColor" .. defaultQueryString, "GET", AreaOwnerListener)
end

function AreaOwnerListener(event)
    if (debug) then print("Area Owner listener fired:" .. event.status) end
    if event.status == 200 then 
        netUp() 
    else 
        netDown(event)  
        textDisplay.text = "Error getting info"
    end
    
    if event.response ~= "" then
        oldTeam = tonumber(event.response)
        ownerDisplay.text = ownerDisplay.text .. " " .. factions[oldTeam].name
    else
        oldTeam = 0;
        ownerDisplay.text = ownerDisplay.text .. " Nobody"
    end

    if (composer.getVariable("faction") ~= tonumber(event.response)) then
        isDifferentTeam = true
    end

    yesButton.isVisible = (hasPoints and isDifferentTeam)
end

function GetAreaScore(mapDataId)
    network.request(serverURL .. "Data/Score/" .. tappedAreaMapDataId .. defaultQueryString, "GET", AreaScoreListener)
end

function AreaScoreListener(event)
    if (debug) then print("Area Score listener fired:" .. event.status) end
    if event.status == 200 then 
        netUp() 
    else 
        netDown(event)  
        textDisplay.text = "Error getting info"
        return
    end

    if (event.response == "") then
        event.response = "1"
    end
     tappedAreaScore = tonumber(event.response)
     textDisplay.text = textDisplay.text .. event.response .. " points?"

     if (tappedAreaScore <= tonumber(Score())) then
        hasPoints = true
     end

     yesButton.isVisible = (hasPoints and isDifferentTeam)
end

function ClaimMPArea()
    --TODO: ponder making a generic 'retryListener' that makes another attempt to call a URL if it fails, and use it for all of these.
    local teamID = composer.getVariable("faction") --GetTeamID()
    netTransfer()
    network.request(serverURL .. "Data/Player/Increment/" .. system.getInfo("deviceID") .. "/score/" .. tappedAreaScore .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Place/" .. tappedAreaMapDataId .. "/teamColor/" .. teamID .. defaultQueryString, "PUT", DefaultNetCallHandler)
    if oldTeam ~= 0 then network.request(serverURL .. "Data/Global/Increment/scoreTeam" .. oldTeam .. "/-" .. tappedAreaScore .. defaultQueryString, "PUT", DefaultNetCallHandler) end
    network.request(serverURL .. "Data/Global/Increment/scoreTeam" ..  teamID .. "/" .. tappedAreaScore .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "MapTile/Expire/" .. tappedAreaMapDataId .. "/teamColor" .. defaultQueryString, "PUT", DefaultNetCallHandler)
    SpendPoints(tappedAreaScore)
    composer.hideOverlay("overlayMPAreaClaim")
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    if (debug) then print("Creating MAC overlay") end

    local bgFill = {.6, .6, .6, 1}
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 700, 500)
    bg.fill = bgFill
    textDisplay = display.newText(sceneGroup, "Claim X with Y points?", display.contentCenterX, display.contentCenterY - 150, 600, 100, native.systemFont, 30)
    ownerDisplay = display.newText(sceneGroup, "Owned by: ", display.contentCenterX, display.contentCenterY, 600, 100, native.systemFont, 30)

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
    if (debug) then print("Showing MAC Overlay") end
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        textDisplay.text = "Claim " .. tappedAreaName .. " with "
        GetAreaOwner(tappedAreaMapDataId)
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