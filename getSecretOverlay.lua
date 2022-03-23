local composer = require( "composer" )
require("database")
require("dataTracker")
 local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
local descText = '' 
local passwordBox = ''
local descText2 = '' 
local rotateButton = ''
local exitButton = '' 
 
local function yesListener()
    local plusCode = removePlus(currentPlusCode)
    guessSecret(plusCode, passwordBox.text)
    return true
end

local function noListener()
    composer.hideOverlay("getSecretOverlay")
    return true
end

function guessSecret(plusCode, password)
    local params = {
        response = {
            filename = "lastGeocache.jpg",
            baseDirectory = system.CachesDirectory
        }
    }
    
    network.request(serverURL .. 'SecureData/Area/' .. plusCode .. '/privateGeoCache/' .. password .. defaultQueryString, 'GET', guessSecretHandler, params)
    netTransfer()    
    return true
end

function rotateListener()
    imgBox:rotate(90)
    if (imgBox.width == 720) then
        imgBox.width = 1280
        imgBox.height = 720
    else
        imgBox.width = 720
        imgBox.height = 1280
    end
end

function guessSecretHandler(event)
    if (event.status == 200) then
        netUp()
        yesButton.isVisible = false
        noButton.isVisible = false
        yesButton:toBack()
        noButton:toBack()
        imgBox:toFront()
        rotateButton:toFront()
        exitButton:toFront()
        rotateButton.isVisible = true
        exitButton.isVisible = true
        local paint = {
            type = "image",
            filename = "lastGeocache.jpg",
            baseDir = system.CachesDirectory
        }
        imgBox.fill = paint
        imgBox.isVisible = true


        --hide old UI, add new buttons to rotate and exit.
        passwordBox:removeSelf() --native components dont automatically leave the screen.
        passwordBox = nil
        passwordText.isVisible = false
    else
        netDown()
        native.showAlert('Incorrect', "Couldn't open the cache in this space, if one exists, with this password.")
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

	local bgFill = {.6, .6, .6, 1}
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 700, 750)
    bg.fill = bgFill

    imgBox = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 720, 1280)
    imgBox.isVisible = false;

	--descText = display.newText(sceneGroup, "Is this the photo you want to cache here?", display.contentCenterX, display.contentCenterY -300, 600, 100, native.systemFont, 30)
    passwordText = display.newText(sceneGroup, "Enter the password to open this cache:", display.contentCenterX, display.contentCenterY + 100, 600, 100, native.systemFont, 30)
	passwordBox = native.newTextField(display.contentCenterX, display.contentCenterY + 120, 600, 40)

	yesButton = display.newImageRect(sceneGroup, "themables/ACYes.png", 100, 100)
    yesButton.x = display.contentCenterX - 200
    yesButton.y = display.contentCenterY + 300
    yesButton:addEventListener("tap", yesListener)

    noButton = display.newImageRect(sceneGroup, "themables/ACNo.png", 100, 100)
    noButton.x = display.contentCenterX + 200
    noButton.y = display.contentCenterY + 300
    noButton:addEventListener("tap", noListener)

    yesButton = display.newImageRect(sceneGroup, "themables/ACYes.png", 100, 100)
    yesButton.x = display.contentCenterX - 200
    yesButton.y = display.contentCenterY + 300
    yesButton:addEventListener("tap", yesListener)

    noButton = display.newImageRect(sceneGroup, "themables/ACNo.png", 100, 100)
    noButton.x = display.contentCenterX + 200
    noButton.y = display.contentCenterY + 300
    noButton:addEventListener("tap", noListener)

    rotateButton = display.newImageRect(sceneGroup, "themables/rotate.png", 300, 100)
    rotateButton.x = display.contentCenterX - 200
    rotateButton.y = display.contentCenterY + 500
    rotateButton:addEventListener("tap", rotateListener)
    rotateButton.isVisible = false

    exitButton = display.newImageRect(sceneGroup, "themables/exit.png", 300, 100)
    exitButton.x = display.contentCenterX + 200
    exitButton.y = display.contentCenterY + 500
    exitButton:addEventListener("tap", noListener)
    exitButton.isVisible = false
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
        if passwordBox ~= nil then
		    passwordBox:removeSelf() --native components dont automatically leave the screen.
        end

 
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