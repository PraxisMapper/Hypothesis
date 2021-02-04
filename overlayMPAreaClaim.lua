--the popup to claim an area in the app for Multiplayer mode.
--Spend points == size or length of the whole area/path.
local composer = require( "composer" )
require("database")
require("localNetwork")
require("dataTracker") --for requestedMapTileCells
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local bg = ""
local textDisplay = ""
local ownerDisplay = ""
local yesButton = ""
local noButton = ""

local function yesListener()
    --check walking score, if high enough, spend points and color this area in.
    if (debug) then print("yes tapped") end
    local points = Score()
    if (tonumber(points) >= tonumber(tappedAreaScore)) then
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
    network.request(serverURL .. "Gameplay/AreaOwners/" .. mapDataId, "GET", AreaOwnerListener)
end

function AreaOwnerListener(event)
    if (debug) then print("Area Owner listener fired:" .. event.status) end
    if event.status == 200 then 
        netUp() 
    else 
        netDown()  
        textDisplay.text = "Error getting info"
    end

    local results = Split(event.response, "|")
    tappedAreaScore = tonumber(results[3])
    textDisplay.text = textDisplay.text .. tappedAreaScore .. " points?"
    ownerDisplay.text = ownerDisplay.text .. " " .. results[2]

    if (tappedAreaScore <= tonumber(Score())) then
        yesButton.isVisible = true
    else
    end
end

function ClaimMPArea()
    local teamID = GetTeamID()
    print(serverURL .. "Gameplay/ClaimArea/" .. tappedAreaMapDataId .. "/" .. teamID)
    network.request(serverURL .. "Gameplay/ClaimArea/" .. tappedAreaMapDataId .. "/" .. teamID, "GET", ClaimMPAreaListener)
end

function ClaimMPAreaListener(event)
    if (event.status == 200) then
        SpendPoints(tappedAreaScore)
    end
    --this call chains to another one, to find which map tiles to update.
    timer.performWithDelay(2000, FindChangedMapTiles, 1)
    composer.hideOverlay("overlayMPAreaClaim")
end

function FindChangedMapTiles()
    network.request(serverURL .. "Gameplay/FindChangedMaptiles/" .. tappedAreaMapDataId, "GET", FindMPAreaListener)
end

function FindMPAreaListener(event)
    if (event.status == 200) then
        ClearMapTiles(event.response)
    end
end

function ClearMapTiles(cellList)
    if (debug) then print("clearing map tiles" ) end
    local cellsToClear = Split(cellList, "|")
    for i = 1, #cellsToClear do
        cellDataCache[cellsToClear[i]] = nil
        os.remove(system.pathForFile(cellsToClear[i] .. "-AC-11.png", system.CachesDirectory))
        requestedMapTileCells[cellsToClear[i]] = -1
    end
    forceRedraw = true

    if (debug) then print("tiles cleared") end
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