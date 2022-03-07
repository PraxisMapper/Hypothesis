local composer = require( "composer" )
local scene = composer.newScene()
-- local media = require("media")

require("dataTracker") 


 
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
 --if privateGeoCache exists, let the user enter a password and attempt to retreive it as an image file.
 --if we successsfully get the image file, display it

 --test purposes, we need 2 image boxes. 1 for the uploaded image, 1 for the received image.

 local textData = ''
 local picUp = ''
 local picDown = ''
 
-- function processPhotoEvent(results)
--     textData.text = dump(results)
--     if results.completed == false then
--         return
--     end
--     -- upload given file.
--     local params = {
--         body = {
--             filename = '86HWGGHQ-AC-11.png' -- "securePic.jpg",  --confirm this is static and wont be changed by the app
--             baseDirectory = system.TemporaryDirectory
--         }
--     }
--     network.request(serverURL .. 'SecureData/SetSecurePlusCodeData/' .. '86GG224466FF/' .. 'privateGeoCache/' .. 'password', 'GET', DefaultNetCallHandler, params)
-- end
    
function uploadPhoto()
    local headers = {}
    headers["Content-Type"] = "application/octet-stream" --"text/text"
    --headers["Content-Type"] = "text/text"

    local params = {
        --body = {
            --filename = '86HWGGHQ-11.png', -- "securePic.jpg",  --confirm this is static and wont be changed by the app
            --baseDirectory = system.CachesDirectory
        --},
        headers = headers,
        bodyType = "text"
    }
    --network.request(serverURL .. 'SecureData/SetSecurePlusCodeData/' .. '86GG224466FF/' .. 'privateGeoCache/' .. 'password', 'GET', DefaultNetCallHandler, params)
    network.upload(serverURL .. 'SecureData/Area/86GG224466FF/' .. 'privateGeoCache/' .. 'password', 'PUT', uploadHandler, params,'86HWGGGP-11.png', system.CachesDirectory)
end

function uploadHandler(event)
    -- upload is done, get results.
    print(event.status)
    print('now getting uploaded photo')
    getPhoto()
end

function getPhoto()
    -- todo: see if i can save text data directly as a png and open it up, or if i'm missing something from that plan.
    -- is only a question because the secureData endpoints return strings, not byte arrays.
    local params = {
        response = {
            filename = "testDL.png",
            baseDirectory = system.CachesDirectory
        }
    }
    network.request(serverURL .. 'SecureData/Area/' .. '86GG224466FF/' .. 'privateGeoCache/' .. 'password', 'GET', dlHandler, params)
end

function dlHandler(event)
    print("dl completed " .. event.status)
    print(event.response)
    local paint = {
        type = "image",
        filename = "testDL.png",
        baseDir = system.CachesDirectory
    }
    picDown.fill = paint
    
end


-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    --textData = display.newText(sceneGroup, "text", display.contentCenterX, 200, 600, 900, native.systemFont, 20)
    print("create")
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        print("will")
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        uploadPhoto() --media.capturePhoto(processPhotoEvent, {baseDir = system.TemporaryDirectory, filename = "securePic.jpg"}) 
        print("did")
        picUp = display.newRect(sceneGroup, 80, 400, 80, 100) 
        local paint = {
            type = "image",
            filename = "86HWGGGM-11.png",
            baseDir = system.CachesDirectory
        }
        picUp.fill = paint

        picDown = display.newRect(sceneGroup, 400, 400, 80, 100)

        --print("checking tile gen id")
        checkTileGeneration('86HWGGHQ', 'mapTiles')

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
        --media.
        
 
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