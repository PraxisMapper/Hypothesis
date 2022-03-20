local composer = require( "composer" )
require("database")
require("dataTracker")
 local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
local descText = '' 
local hintBox = ''
local descText2 = '' 
local yesBox = ''
local noBox = ''
 
 
local function yesListener()
    local plusCode = removePlus(currentPlusCode)
    saveHint(plusCode, hintBox.text)
	composer.hideOverlay("leaveHintOverlay")
    return true
end

local function noListener()
    composer.hideOverlay("leaveHintOverlay")
    return true
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

	descText = display.newText(sceneGroup, "What do you want your hint to say?", display.contentCenterX, display.contentCenterY -200, 600, 100, native.systemFont, 30)
	hintBox = native.newTextField(display.contentCenterX, display.contentCenterY - 100, 600, 40)

	descText2 = display.newText(sceneGroup, "Send this hint?", display.contentCenterX, display.contentCenterY, 600, 100, native.systemFont, 30)

	yesButton = display.newImageRect(sceneGroup, "themables/ACYes.png", 100, 100)
    yesButton.x = display.contentCenterX - 200
    yesButton.y = display.contentCenterY + 100
    yesButton:addEventListener("tap", yesListener)

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
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen

		--print(currentPlusCode:sub(1,8))

		local hintsLeft = getHintInfo(currentPlusCode:sub(1,8))
		local hints = tonumber(hintsLeft[3])

		if hints <= 0 then
			yesButton.isVisible = false
			descText2.text = "You have already given all your hints for this area."
		end
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
		hintBox:removeSelf() --native components dont automatically leave the screen.
 
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