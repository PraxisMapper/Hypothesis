local composer = require( "composer" )
require('database')
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
--id, lastAddTime, allPerSec, parkPerSec, naturePerSec, trailPerSec, touristPerSec, graveyardPerSec,  allTotal, parkTotal, natureTotal, trailTotal, touristTotal, graveyardTotal, wins
currentValues = {}

--placeholders for UI elements
local emptyLabel = ''
local parkLabel = ''
local natureReserveLabel = ''
local trailLabel = ''
local tourismLabel = ''
local graveyardLabel = ''

local buyParkLabel = ''
local buyNatureReserverLabel = ''
local buyTrailLabel = ''
local buyTourismLabel = ''
local buyGraveyardLabel = ''
local buyWinLabel = ''

local function GetAllValues()
    local sql = 'SELECT * FROM IdleStats'
    currentValues = Query(sql)[1] 
end
 
local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end

local function GetUpgradeCost(currentCount)
    return math.modf(currentCount ^ 2.1 + 1)
end

local function updateTotals()
    GetAllValues()
    --add per second values for each second that's passed since the last check
    local timeCheck = os.time()
    local timeShift = (timeCheck - currentValues[2]) / 1000
    sql = "UPDATE IdleStats SET allTotal = allTotal + " .. (currentValues[3] * timeShift) .. ", "
    sql = sql  .. "parkTotal = parkTotal + " .. (currentValues[4] * timeShift) .. ", "
    sql = sql  .. "natureTotal = natureTotal + " .. (currentValues[5] * timeShift) .. ", "
    sql = sql  .. "trailTotal = trailTotal + " .. (currentValues[6] * timeShift) .. ", "
    sql = sql  .. "touristTotal = touristTotal + " .. (currentValues[7] * timeShift) .. ", "
    sql = sql  .. "graveyardTotal = graveyardTotal + " .. (currentValues[8] * timeShift) .. ", "
    sql = sql  .. "lastAddTime = " .. timeCheck
    Exec(sql)

    GetAllValues()

    emptyLabel.text = "All Points: " .. math.modf(currentValues[9])
    parkLabel.text = "Park Points: " .. math.modf(currentValues[10])
    natureReserveLabel.text = "Nature Reserve Points: " .. math.modf(currentValues[11])
    trailLabel.text ="Trail Points: " .. math.modf(currentValues[12])
    tourismLabel.text = "Tourism Points: " .. math.modf(currentValues[13])
    graveyardLabel.text ="Graveyard Points: " .. math.modf(currentValues[14])

    buyParkLabel.text = "Buy 1 Park per second for " .. GetUpgradeCost(currentValues[4]) .. ' All points'
    buyNatureReserverLabel.text = "Buy 1 Nature Reserve per second for " .. GetUpgradeCost(currentValues[5]) .. ' Park points'
    buyTrailLabel.text ="Buy 1 Trail per second for " .. GetUpgradeCost(currentValues[6]) .. ' Nature Reserve points'
    buyTourismLabel.text = "Buy 1 Tourism per second for " .. GetUpgradeCost(currentValues[7]) .. ' Trail points'
    buyGraveyardLabel.text ="Buy 1 Graveyard per second for " .. GetUpgradeCost(currentValues[8]) .. ' Tourism points'

    buyWinLabel.text = "Confirm your victory with " .. (1000000 * (10 ^ currentValues[15])) ..  " of each terrain type"
end

local function WinIdle()
    --Should do some fancy effects to indicate victory has been acheived
    --sound, particles, screen filters?
    --first, check if the player actually won
    --currentvalues needs all 6 totals over 1 million.
    --its 86k per day if you have 1 per second of each type.
    --so its 12 days to win if you get 1 of each space for the first time

    local totalRequired = 1000000 * (10 ^ currentValues[15])
    if (currentValues[9] > totalRequired and currentValues[10] > totalRequired and currentValues[11] > totalRequired and currentValues[12] > totalRequired and currentValues[13] > totalRequired and currentValues[14] > totalRequired) then
        --VICTORY.
        --TODO: flashy effects

        local sql = "UPDATE IdleStats SET wins = wins + 1, allPerSec = 0, parkPerSec = 0, naturePerSec = 0, trailPerSec = 0, touristPerSec = 0, graveyardPerSec = 0,  allTotal = 0, parkTotal = 0, natureTotal = 0, trailTotal = 0, touristTotal = 0, graveyardTotal = 0"
        Exec(sql)
        GetAllValues()
    else
        native.showAlert("Not Yet...", "You do not yet have enough points in all terrain types to ascend.")
    end
end

local function buyPark()
    local cost = GetUpgradeCost(currentValues[4])
    if (currentValues[9] > cost) then
        local sql = "UPDATE IdleStats SET parkPerSec = parkPerSec + 1, allTotal = " .. (currentValues[9] - cost)
        Exec(sql)
        GetAllValues()
    end
end

local function buyNatureReserve()
    local cost = GetUpgradeCost(currentValues[5])
    if (currentValues[10] > cost) then
        local sql = "UPDATE IdleStats SET naturePerSec = naturePerSec + 1, parkTotal = " .. (currentValues[10] - cost)
        Exec(sql)
        GetAllValues()
    end
end

local function buyTrail()
    local cost = GetUpgradeCost(currentValues[6])
    if (currentValues[11] > cost) then
        local sql = "UPDATE IdleStats SET trailPerSec = trailPerSec + 1, natureTotal = " .. (currentValues[11] - cost)
        Exec(sql)
        GetAllValues()
    end
end

local function buyTourism()
    local cost = GetUpgradeCost(currentValues[7])
    if (currentValues[12] > cost) then
        local sql = "UPDATE IdleStats SET touristPerSec = touristPerSec + 1, trailTotal = " .. (currentValues[12] - cost)
        Exec(sql)
        GetAllValues()
    end
end

local function buyGraveyard()
    local cost = GetUpgradeCost(currentValues[8])
    if (currentValues[13] > cost) then
        local sql = "UPDATE IdleStats SET graveyardPerSec = graveyardPerSec + 1, touristTotal = " .. (currentValues[13] - cost)
        Exec(sql)
        GetAllValues()
    end
end
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    header = display.newImageRect(sceneGroup, "themables/idleGame.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 80
    header:addEventListener("tap", GoToSceneSelect)
    header:toFront()

    -- 6 types of space tracked
    -- empty, park, nature reserve, trail, graveyard, tourism
    emptyLabel = display.newText(sceneGroup, "All Points: ", display.contentCenterX, 160, native.systemFont, 20)
    parkLabel = display.newText(sceneGroup, "Park Points: ", display.contentCenterX, 320, native.systemFont, 20)
    natureReserveLabel = display.newText(sceneGroup, "Nature Reserve Points: ", display.contentCenterX, 480, native.systemFont, 20)
    trailLabel = display.newText(sceneGroup, "Trail Points: ", display.contentCenterX, 640, native.systemFont, 20)
    tourismLabel = display.newText(sceneGroup, "Tourism Points: ", display.contentCenterX, 800, native.systemFont, 20)
    graveyardLabel = display.newText(sceneGroup, "Graveyard Points: ", display.contentCenterX, 960, native.systemFont, 20)

    --Need buttons and labels to buy types with other types
    --purchasing order
    --Anywhere will get you to a park
    --parks level up to nature reservers
    --nature reserves are full of trails
    --travelling on trails makes you a tourist
    --all travels have the same final destination
    buyParkLabel = display.newText(sceneGroup, "Buy 1 Park per second for ", display.contentCenterX, 340, native.systemFont, 20)
    buyNatureReserverLabel = display.newText(sceneGroup, "Buy 1 Nature Reserve per second for ", display.contentCenterX, 500, native.systemFont, 20)
    buyTrailLabel = display.newText(sceneGroup, "Buy 1 Trail per second for ", display.contentCenterX, 660, native.systemFont, 20)
    buyTourismLabel = display.newText(sceneGroup, "Buy 1 tourism per second for ", display.contentCenterX, 820, native.systemFont, 20)
    buyGraveyardLabel = display.newText(sceneGroup, "Buy 1 Graveyard per second for ", display.contentCenterX, 980, native.systemFont, 20)

    --buttons for buying
    buyParkImg = display.newImageRect(sceneGroup, "themables/idlePark.png", 300, 100)
    buyParkImg.x = display.contentCenterX
    buyParkImg.y = 240
    buyParkImg:addEventListener("tap", buyPark)

    buyNatResImg = display.newImageRect(sceneGroup, "themables/idleNatRes.png", 300, 100)
    buyNatResImg.x = display.contentCenterX
    buyNatResImg.y = 400
    buyNatResImg:addEventListener("tap", buyNatureReserve)

    buyTrailImg = display.newImageRect(sceneGroup, "themables/idleTrail.png", 300, 100)
    buyTrailImg.x = display.contentCenterX
    buyTrailImg.y = 560
    buyTrailImg:addEventListener("tap", buyTrail)

    buyTourismImg = display.newImageRect(sceneGroup, "themables/idleTourism.png", 300, 100)
    buyTourismImg.x = display.contentCenterX
    buyTourismImg.y = 740
    buyTourismImg:addEventListener("tap", buyGraveyard)

    buyGraveyardImg = display.newImageRect(sceneGroup, "themables/idleGraveyard.png", 300, 100)
    buyGraveyardImg.x = display.contentCenterX
    buyGraveyardImg.y = 880
    buyGraveyardImg:addEventListener("tap", buyGraveyard)

 
    --need a button to 'win' and a label with the values
    buyWinLabel = display.newText(sceneGroup, "Confirm your victory with 1,000,000 of each terrain type", display.contentCenterX, 1080, native.systemFont, 20)

    local buyWinButton = display.newImageRect(sceneGroup, "themables/idleWin.png", 300, 100)
    buyWinButton.x = display.contentCenterX
    buyWinButton.y = 1150
    buyWinButton:addEventListener("tap", WinIdle)

end
  
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        timer.performWithDelay(1000, updateTotals, -1)
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