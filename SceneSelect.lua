local composer = require( "composer" ) 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local function SwitchToSettingsScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SettingsScene", options)
end

local function SwitchToMultiplayerAreaControlScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("MutiplayerAreaControl2", options)
end

local function SwitchToPaintTownScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("PaintTownScene", options)
end

local function SwitchToIdleScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("IdleScene", options)
end

local function SwitchToGeocacheScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("geocacheScene", options)
end

local function SwitchToCreatureScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("CreatureCollectorScene", options)
end
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event ) 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    if (debug) then print("showing SceneSelect") end

    local headerText = display.newText(sceneGroup, "Hypothesis - Mode Select", display.contentCenterX, 30, native.systemFont, 50)
    local helperText = display.newText(sceneGroup, "Tap the header in any mode to return to this screen", display.contentCenterX, 900, native.systemFont, 30)

    local changeMPAreaControl = display.newImageRect(sceneGroup, "themables/MultiplayerAreaControl.png", 300, 100) --area tag
    changeMPAreaControl.anchorX = 0
    changeMPAreaControl.anchorY = 0
    changeMPAreaControl.x = 390
    changeMPAreaControl.y = 100
    changeMPAreaControl:addEventListener("tap", SwitchToMultiplayerAreaControlScene)

    local changeIdle = display.newImageRect(sceneGroup, "themables/idleGame.png", 300, 100) --idle game
    changeIdle.anchorX = 0
    changeIdle.anchorY = 0
    changeIdle.x = 60
    changeIdle.y = 250
    changeIdle:addEventListener("tap", SwitchToIdleScene)

    local changePaintTown = display.newImageRect(sceneGroup, "themables/PaintTown.png", 300, 100) --paint the town
    changePaintTown.anchorX = 0
    changePaintTown.anchorY = 0
    changePaintTown.x = 60
    changePaintTown.y = 100
    changePaintTown:addEventListener("tap", SwitchToPaintTownScene)

    local changeGeocache = display.newImageRect(sceneGroup, "themables/virtualGeocache.png", 300, 100) --area tag
    changeGeocache.anchorX = 0
    changeGeocache.anchorY = 0
    changeGeocache.x = 390
    changeGeocache.y = 250
    changeGeocache:addEventListener("tap", SwitchToGeocacheScene)

    local changeCreature = display.newImageRect(sceneGroup, "themables/creatureCollector.png", 300, 100) --paint the town
    changeCreature.anchorX = 0
    changeCreature.anchorY = 0
    changeCreature.x = 60
    changeCreature.y = 400
    changeCreature:addEventListener("tap", SwitchToCreatureScene)

    local changeSettings = display.newImageRect(sceneGroup, "themables/Settings.png", 300, 100) -- settings
    changeSettings.anchorX = 0
    changeSettings.anchorY = 0
    changeSettings.x = 390
    changeSettings.y = 700
    changeSettings:addEventListener("tap", SwitchToSettingsScene) 
end
 
-- show()
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    if (debug) then print("showing SceneSelect") end
 
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

    if (debug) then print("hiding SceneSelect") end
 
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
    if (debug) then print("destroying SceneSelect") end
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