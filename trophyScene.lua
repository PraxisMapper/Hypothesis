local composer = require( "composer" )
 
local scene = composer.newScene()

--TODO
--create baseline background image for trophy room.
--draw pictures for all the things user can by
--actually display things user has bought.


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
 
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    local changeGrid = display.newImageRect(sceneGroup, "SmallGridButton.png", 300, 100)
    changeGrid.anchorX = 0
    changeGrid.anchorY = 0
    changeGrid.x = 60
    changeGrid.y = 1000

    changeGrid:addEventListener("tap", SwitchToSmallGrid)

    local changeGrid2 = display.newImageRect(sceneGroup, "BigGridButton.png", 300, 100)
    changeGrid2.anchorX = 0
    changeGrid2.anchorY = 0
    changeGrid2.x = 390
    changeGrid2.y = 1000

    changeGrid2:addEventListener("tap", SwitchToBigGrid)

    local unlockTrophy = display.newImageRect(sceneGroup, "UnlockTrophy.png", 300, 100)
    unlockTrophy.anchorX = 0
    unlockTrophy.anchorY = 0
    unlockTrophy.x = 210
    unlockTrophy.y = 1110

    changeGrid:addEventListener("tap", SwitchToSmallGrid)

    if (debug) then print("created TrophyScene") end
 
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