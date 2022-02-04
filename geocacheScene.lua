local composer = require( "composer" )
local scene = composer.newScene()
local media = require("media")

 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

 -- This scene doesn't need map tiles per se, but it might still draw the map. TBD
 -- if I do want maptiles, use basePlayableScene as the template instead of newSceneTemplate.
 -- this checks for both regular and secure entries for a cell10.
 -- public visible data is text, secured data is a photo taken live, requires a password to view.
 -- so I need to check if there are entries present here, and display the cell10 public entry if it is.
 -- the secure one requires a password so it's silly to bother getting it if it present.

 --use GetallDataInPlusCode to check for publicGeoCache and privateGeoCache
 --if publicGeoCache exists in our current cell, display it.
 --if privateGeoCahce exists, let the user enter a password and attempt to retreive it as an image file.
 --if we successsfully get the image file, display it

 
function processPhotoEvent(results)
    if results.completed == false then
        return
    end
    -- TODO: determine data and type in results, make it a base64 string, and save it.
end
    

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
 
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