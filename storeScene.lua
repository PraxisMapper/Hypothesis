local composer = require( "composer" )
 
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
--TODO:
--Create 2 items.
--Buy items separately per platform
 --track count of coffees bought?
 --don't attempt to let user buy GoodPerson if they already own it
--icon/button to enter this scene.



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
    if (debug) then print("creating store scene") end
    local sceneGroup = self.view

    local header = display.newImageRect(sceneGroup, "StoreHeader.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 100 

    -- Code here runs when the scene is first created but has not yet appeared on screen
    local GoodPersonDesc = "Supporting developers that don't use ads, lootboxes, or invasive data tracking is good. Be a good person. You'll get reminded every time you open the game that you're a good person."
    local CoffeeDesc = "Buy the developer a coffee because you want to actively support this game and future development of the idea. Possibly future games built around the core idea, with more stuff to do."

    --make items.
    local coffeeIcon = display.newImageRect(sceneGroup, "coffeeIcon.png", 100, 100)
    coffeeIcon.anchorX = 0
    coffeeIcon.anchorY = 0
    coffeeIcon.x = 50
    coffeeIcon.y = 400

    local goodPersonIcon = display.newImageRect(sceneGroup, "goodPerson.png", 100, 100)
    goodPersonIcon.anchorX = 0
    goodPersonIcon.anchorY = 0
    goodPersonIcon.x = 50
    goodPersonIcon.y = 700


    local textOptions = {}
    textOptions.parent =  sceneGroup
    textOptions.text = CoffeeDesc
    textOptions.x = 50
    textOptions.y = 50
    textOptions.width = 500
    textOptions.height = 0
    textOptions.font = native.systemFont
    textOptions.fontSize = 26
    
    local coffeeText = display.newText(textOptions)
    coffeeText.anchorX = 0
    coffeeText.anchorY = 0
    coffeeText.x = 175
    coffeeText.y = 400

    textOptions.text = GoodPersonDesc
    textOptions.y = 500

    local goodPersonText = display.newText(textOptions)
    goodPersonText.anchorX = 0
    goodPersonText.anchorY = 0
    goodPersonText.x = 175
    goodPersonText.y = 700

    local changeGrid = display.newImageRect(sceneGroup, "BigGridButton.png", 300, 100)
    changeGrid.anchorX = 0
    changeGrid.anchorY = 0
    changeGrid.x = 60
    changeGrid.y = 1000

    local changegrid2 = display.newImageRect(sceneGroup, "SmallGridButton.png", 300, 100)
    changegrid2.anchorX = 0
    changegrid2.anchorY = 0
    changegrid2.x = 390
    changegrid2.y = 1000

    changeGrid:addEventListener("tap", SwitchToBigGrid)
    changegrid2:addEventListener("tap", SwitchToSmallGrid)

    local color = 
    {
        highlight = { r=1, g=.7, b=.7 },
        shadow = { r=0.3, g=0.3, b=0.3 }
    }

    textOptions.text = "$0.99"
    textOptions.fontSize = 64  

    local coffeePrice = display.newEmbossedText(textOptions)
    coffeePrice.anchorX = 0
    coffeePrice.anchorY = 0
    coffeePrice.x = 175
    coffeePrice.y = 600
    coffeePrice:setFillColor(.6)
    coffeePrice:setEmbossColor(color)

    textOptions.text = "$2.99"
    local goodPrice = display.newEmbossedText(textOptions)
    goodPrice.anchorX = 0
    goodPrice.anchorY = 0
    goodPrice.x = 175
    goodPrice.y = 300
    goodPrice:setFillColor(.6)
    goodPrice:setEmbossColor(color)
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