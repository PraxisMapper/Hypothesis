--TODO here: create buttons to link to all scenes in this test/debug app.
--TODO: scenes to create:
--8-cells with textures for cells instead of solid colors, using 10-cell resolution
--above with 11-cell resolution
--above, but with 6-cell data for both resolutions
--10-cell grid but using textured 8-cell data
--11-cell grid, also using textured 8-cell data

local composer = require( "composer" ) 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
local function SwitchTo8GridScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("8GridScene", options)
end

local function SwitchTo10GridScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("10GridScene", options)
end

local function SwitchTo8GridScene11Image()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("8GridScene11Image", options)
end

local function SwitchTo8GridScene10Image()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("8GridScene10Image", options)
end

local function SwitchToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end

local function SwitchTo10Grid11ImageScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("10GridScene11image", options)
end

local function SwitchToAreaControlScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("10GridScene11AreaControl", options)
end


--this would just be downloading a 1-pixel image. Thats silly. Keep this as the existing scene.
local function SwitchTo10Grid10ImageScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("10GridScene", options)
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    local change8grid = display.newImageRect(sceneGroup, "themables/BigGridButton.png", 300, 100)
    change8grid.anchorX = 0
    change8grid.anchorY = 0
    change8grid.x = 60
    change8grid.y = 100
    change8grid:addEventListener("tap", SwitchTo8GridScene)

    local change8grid11Image = display.newImageRect(sceneGroup, "themables/8cell11image.png", 300, 100)
    change8grid11Image.anchorX = 0
    change8grid11Image.anchorY = 0
    change8grid11Image.x = 60
    change8grid11Image.y = 300
    change8grid11Image:addEventListener("tap", SwitchTo8GridScene11Image)

    local change8grid10Image = display.newImageRect(sceneGroup, "themables/8cell10image.png", 300, 100)
    change8grid10Image.anchorX = 0
    change8grid10Image.anchorY = 0
    change8grid10Image.x = 60
    change8grid10Image.y = 500
    change8grid10Image:addEventListener("tap", SwitchTo8GridScene10Image)


    local changeGrid = display.newImageRect(sceneGroup, "themables/SmallGridButton.png", 300, 100)
    changeGrid.anchorX = 0
    changeGrid.anchorY = 0
    changeGrid.x = 390
    changeGrid.y = 100
    changeGrid:addEventListener("tap", SwitchTo10GridScene)

    local change10Grid11Image = display.newImageRect(sceneGroup, "themables/10cell11image.png", 300, 100)
    change10Grid11Image.anchorX = 0
    change10Grid11Image.anchorY = 0
    change10Grid11Image.x = 390
    change10Grid11Image.y = 300
    change10Grid11Image:addEventListener("tap", SwitchTo10Grid11ImageScene)


    local change10Grid10Image = display.newImageRect(sceneGroup, "themables/10cell10image.png", 300, 100)
    change10Grid10Image.anchorX = 0
    change10Grid10Image.anchorY = 0
    change10Grid10Image.x = 390
    change10Grid10Image.y = 500
    change10Grid10Image:addEventListener("tap", SwitchTo10Grid10ImageScene)

    local changeAreaControl = display.newImageRect(sceneGroup, "themables/AreaControl.png", 300, 100)
    changeAreaControl.anchorX = 0
    changeAreaControl.anchorY = 0
    changeAreaControl.x = 390
    changeAreaControl.y = 700
    changeAreaControl:addEventListener("tap", SwitchToAreaControlScene)

 
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