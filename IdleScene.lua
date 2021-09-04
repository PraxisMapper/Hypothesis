local composer = require( "composer" )
require('database')
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
currentValues = {}

local function GetAllValues()
    local sql = 'SELECT * FROM IdleStats'
    currentValues = Query(sql)
end
 
local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end

local function WinIdle()
    --Should do some fancy effects to indicate victory has been acheived
    --sound, particles, screen filters?
    --first, check if the player actually won
    --currentvalues needs all 6 totals over 1 million.
    --its 86k per day if you have 1 per second of each type.
    --so its 12 days to win if you get 1 of each space.

    --update Bounds table with best win time.
    --TODO: make this match up to Hypothesis
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
    -- empty, park, nature reserve, trail, graveyard, tourist
    emptyLabel = display.newText(sceneGroup, "All Spaces: ", display.contentCenterX, 160, native.systemFont, 20)
    parkLabel = display.newText(sceneGroup, "Park Spaces: ", display.contentCenterX, 160, native.systemFont, 20)
    natureReserveLabel = display.newText(sceneGroup, "Nature Reserve Spaces: ", display.contentCenterX, 160, native.systemFont, 20)
    trailLabel = display.newText(sceneGroup, "Trail Spaces: ", display.contentCenterX, 160, native.systemFont, 20)
    graveyardLabel = display.newText(sceneGroup, "Graveyard Spaces: ", display.contentCenterX, 160, native.systemFont, 20)
    touristLabel = display.newText(sceneGroup, "Tourist Spaces: ", display.contentCenterX, 160, native.systemFont, 20)

    --Need buttons and labels to buy types with other types
    --purchasing order
    --Anywhere will get you to a park
    --parks level up to nature reservers
    --nature reserves are full of trails
    --travelling on trails makes you a tourist
    --all travels have the same final destination
    buyParkLabel = display.newText(sceneGroup, "Buy 1 Park per second for ", display.contentCenterX, 200, native.systemFont, 20)
    buyNatureReserverLabel = display.newText(sceneGroup, "Buy 1 Nature Reserve per second for ", display.contentCenterX, 200, native.systemFont, 20)
    buyTrailLabel = display.newText(sceneGroup, "Buy 1 Trail per second for ", display.contentCenterX, 200, native.systemFont, 20)
    buyTouristLabel = display.newText(sceneGroup, "Buy 1 Tourist per second for ", display.contentCenterX, 200, native.systemFont, 20)
    buyGraveyardLabel = display.newText(sceneGroup, "Buy 1 Graveyard per second for ", display.contentCenterX, 200, native.systemFont, 20)
 
    --need a button to 'win' and a label with the values
    buyWinLabel = display.newText(sceneGroup, "Confirm your victory with 1,000,000 of each point type", display.contentCenterX, 200, native.systemFont, 20)

    local buyWinButton = display.newImageRect(sceneGroup, "themables/idleGame.png", 100, 100)
    changeIdle.anchorX = 0
    changeIdle.anchorY = 0
    changeIdle.x = 60
    changeIdle.y = 300
    changeIdle:addEventListener("tap", SwitchToIdleScene)

end
 
 
-- show()
function scene:show( event )
 
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