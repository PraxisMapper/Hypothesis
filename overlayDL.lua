--This is the modal pop-up that tells a user the game is downloading data.
--loadingScene is the part after the splash screen that sets up everything to run.


--TODO:
--get a big spinner icon.
--put big text that says Loading...
--be modal overlay, so the game is still visible behind it but you can't interact with it.
--call this with showOverlay() insead of gotoScene()

local composer = require( "composer" )
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
 
 
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    local spinner = display.newImageRect(sceneGroup, "themables/spinner.png", 300, 300)
    spinner.x = 360
    spinner.y = 650
    spinner.anchorX = 0.5
    spinner.anchorY = 0.5

    statusText = display.newText(sceneGroup, "Loading....", display.contentCenterX, display.contentCenterY - 200, native.systemFont, 30)
    --statusText:setFillColor(.2, .2, .2)
 
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