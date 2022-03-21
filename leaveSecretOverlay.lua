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
local yesBox = ''
local noBox = ''
local imgBox = ''
local secrets = 0
 
 
local function yesListener()
    local plusCode = removePlus(currentPlusCode)
    local something = saveSecret(plusCode, passwordBox.text, "geocachePic.jpg")
	--composer.hideOverlay("leaveHintOverlay")
    yesButton.isVisible = false;
    noButton.isVisible = false;
    return true
end

local function noListener()
    composer.hideOverlay("leaveHintOverlay")
    return true
end

local function processPhotoEvent(event)
    if (event.completed == true) then
        local paint = {
            type = "image",
            filename = "geocachePic.jpg",
            baseDir = system.TemporaryDirectory
        }
        imgBox.fill = paint
        if (secrets > 0) then
            yesButton.isVisible = true
        end
    else
        yesButton.isVisible = false
        descText2.text = "You need to take a picture to save a cache."
    end
end

function saveSecret(pluscode, password, file)
    local headers = {}
    headers["Content-Type"] = "application/octet-stream"
    local params = {
        headers = headers,
        bodyType = "binary"
    }
    local url = serverURL .. 'SecureData/Area/' .. pluscode .. '/privateGeoCache/' .. password .. defaultQueryString
    local results = network.upload(serverURL .. 'SecureData/Area/' .. pluscode .. '/privateGeoCache/' .. password .. defaultQueryString, 'PUT', saveSecretHandler, params, file, system.TemporaryDirectory)
    netTransfer()
    return results
end

function saveSecretHandler(event)
    --we don't need to do anything real serious, just confirm the upload succeeded and track counts.
    local plusCode = Split(string.gsub(string.gsub(event.url, serverURL .. "SecureData/Area/", ""), "/privateGeoCache", ""), '?')[1]
    print(plusCode:sub(1,8))

    if event.status == 200 then
        spendSecret(plusCode:sub(1,8))
        native.showAlert('', "secret spent for " .. plusCode:sub(1,8))
        netUp()
    else
        native.showAlert('', "upload failed")
        netDown()
    end
    composer.hideOverlay("leaveHintOverlay")
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

    imgBox = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY - 150, 180, 320)

	descText = display.newText(sceneGroup, "Is this the photo you want to cache here?", display.contentCenterX, display.contentCenterY -300, 600, 100, native.systemFont, 30)
    passwordText = display.newText(sceneGroup, "Set the password to open your cache:", display.contentCenterX, display.contentCenterY + 100, 600, 100, native.systemFont, 30)
	passwordBox = native.newTextField(display.contentCenterX, display.contentCenterY + 120, 600, 40)
	descText2 = display.newText(sceneGroup, "Send this cache?", display.contentCenterX + 25, display.contentCenterY + 230, 600, 100, native.systemFont, 30)

	yesButton = display.newImageRect(sceneGroup, "themables/ACYes.png", 100, 100)
    yesButton.x = display.contentCenterX - 200
    yesButton.y = display.contentCenterY + 300
    yesButton:addEventListener("tap", yesListener)
    yesButton.isVisible = false

    noButton = display.newImageRect(sceneGroup, "themables/ACNo.png", 100, 100)
    noButton.x = display.contentCenterX + 200
    noButton.y = display.contentCenterY + 300
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
		secrets = tonumber(hintsLeft[4])

		if secrets <= 0 then
			yesButton.isVisible = false
			descText2.text = "You have already hidden a geocache here."
        else
            media.capturePhoto({ listener = processPhotoEvent, destination  = {baseDir = system.TemporaryDirectory, filename = "geocachePic.jpg"}}) 
		end
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
		passwordBox:removeSelf() --native components dont automatically leave the screen.
 
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