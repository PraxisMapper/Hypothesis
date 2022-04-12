local composer = require( "composer" )
local scene = composer.newScene()

require("database")
local widget = require("widget")

 -- a scrolling list of creatures, displayed as an overlay.
 -- Creatures with a catch count of 0 are blanked / ??? out
 -- creatures with a catch count of >0 show their image, name, and total caught of them.
 -- possibly a list of where they can be found.
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local mainView = {}

 function hideThis()
    composer.hideOverlay()
 end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    print("opening list")
    local bgFill = {.6, .6, .6, 1}
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 700, 1150)
    bg.fill = bgFill
    
    local header = display.newImageRect(sceneGroup, "themables/creatureList.png",300, 100)
    header.x = display.contentCenterX
    header.y = 150
    header:addEventListener("tap", hideThis)
    header:toFront()
    print("header up")

    local imgCredits = display.newText(sceneGroup, "Images CC BY-NC Pheonixsong at https://phoenixdex.alteredorigin.net", 625, 1200, 1200, 0, native.systemFont, 22)
    imgCredits.anchorX = .5
    imgCredits.anchorY = .5
    imgCredits:setFillColor({0, 0, 0})

    mainView = widget.newScrollView({ x= display.contentCenterX, y = display.contentCenterY + 20, width = 600, height = 900, horizontalScrollDisabled = true, backgroundColor = {.6, .6, .6}})
    mainView.backgroundColor = {1, 1, 0}
    print("scroll view exists")

    local dbEntries = Query("SELECT name, count FROM creaturesCaught ORDER BY name")
    print("got entries")
    print(#dbEntries)

    local nextX = 100
    local nextY = 0

    for i, v in ipairs(dbEntries) do
        print("in loop")
        if v[2] == 0 then
            --draw empty entry.
            questionMarkLine = display.newText(sceneGroup, "???", nextX + 100, nextY + 60, 200, 0, native.systemFont, 22)
            mainView:insert(questionMarkLine)
        else
            --draw the actual entry
            local image = display.newImageRect(sceneGroup, "themables/CreatureImages/" .. v[1] .. ".png", 200, 200)
            image.x = nextX + 25
            image.y = nextY + 25
            image.anchorX = 0.5
            image.anchorY = 0
            local nameLine = display.newText(sceneGroup, v[1], nextX + 50, nextY + 20 , 200, 0, native.systemFont, 22)
            local countInfo = display.newText(sceneGroup, "Total Collected:" .. v[2], nextX + 25, nextY + 220, 200, 0, native.systemFont, 22)
            mainView:insert(image)
            mainView:insert(nameLine)
            mainView:insert(countInfo)
        end

        --update positioning info.
        if i % 2 == 0 then
            nextY = nextY + 250
            nextX = 100
        else
            nextX = 400
        end

    end
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
        mainView:removeSelf()
 
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