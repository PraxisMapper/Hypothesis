local composer = require( "composer" )
local scene = composer.newScene()

require("UIParts")
require("database")
require("dataTracker") --replaced localNetwork for this scene
 
if (debug) then print("8GridScene11image loading") end
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local cellCollection = {}

--color codes. cell8s dont use type-specific ones.
local visitedCell = {.8, .3, .3, 1}
local unvisitedCell = {.1, .7, .7, 1}
local timerResults8 = nil

local firstRun8 = true

local locationText = ""
local countText = ""
local pointText = ""
local timeText = ""
local directionArrow = ""

local function UpdateLocal8()
    if (debugGPS) then print("start UpdateLocal8") end
    local currentPlusCode8 = currentPlusCode:sub(1,8)
    local previousPlusCode8 =  previousPlusCode:sub(1,8)
    if (debugGPS) then print(currentPlusCode8) end

    if (currentPlusCode8 ~= previousPlusCode8 or firstRun8 or forceRedraw) then
        firstRun8 = false
        previousPlusCode8 = currentPlusCode8
        if (debugGPS) then print("in 8 grid loop " ..previousPlusCode8 .. " " .. currentPlusCode8) end
        for square = 1, #cellCollection do --this is slightly faster than ipairs
            local thisSquaresPluscode = currentPlusCode8
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridX, 8)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridY, 7)
            cellCollection[square].pluscode = thisSquaresPluscode

            if (forceRedraw == false and cellDataCache[thisSquaresPluscode] ~= nil) then
                --we can skip some of the processing we did earlier.
                cellCollection[square].fill = cellDataCache[thisSquaresPluscode].tileFill
            else
                cellDataCache[thisSquaresPluscode] = {}
                local imageExists = requestedMapTileCells[thisSquaresPluscode] --read from DataTracker because we want to know if we can paint the cell or not.
                if (imageExists == nil) then
                    imageExists = doesFileExist(thisSquaresPluscode .. "-11.png", system.CachesDirectory)
                end
                if (not imageExists) then
                    GetMapTile8(thisSquaresPluscode)
                else
                    local paint = {type  = "image", filename = thisSquaresPluscode .. "-11.png", baseDir = system.CachesDirectory}
                    cellCollection[square].fill = paint
                    cellDataCache[thisSquaresPluscode].tileFill = {type  = "image", filename = thisSquaresPluscode .. "-11.png", baseDir = system.CachesDirectory}
                end

            end
        end
    end

    forceRedraw = false
    if (debugGPS) then print("8grid done or skipped") end
    if (debugGPS) then print(locationText.text) end
    locationText.text = "Current 8 location:" .. currentPlusCode8
    countText.text = "Total Explored Cell8s: " .. TotalExploredCell8s()
    pointText.text = "Score: " .. Score()
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading

    if (timerResults8 == nil) then
        timerResults8 = timer.performWithDelay(500, UpdateLocal8, -1) 
    end

    if (debugGPS) then print("end updateLocal8") end
end

local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    if (debug) then print("creating 8GridScene") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    countText = display.newText(sceneGroup, "Total Cells Explored: ?", display.contentCenterX, 240, native.systemFont, 20)
    pointText = display.newText(sceneGroup, "Score: ?", display.contentCenterX, 260, native.systemFont, 20)

    --NOTE: 11-cell resolution images for cell8s are 80x100, so use the rectangle function
    --I've since doubled their resolution, so they can get set up to 160x200.
    --CreateRectangleGrid(7, 80, 100, sceneGroup, cellCollection, "painttown") --7 is the max that fits on screen at this image size
    CreateRectangleGrid(4, 160, 200, sceneGroup, cellCollection, "painttown") --7 is the max that fits on screen at this image size

    directionArrow = display.newImageRect(sceneGroup, "themables/circle1.png", 65, 65)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY
    
    local header = display.newImageRect(sceneGroup, "themables/8cell11image.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 100
    header:addEventListener("tap", GoToSceneSelect)

    if (debug) then print("created 8GridScene11Image") end
end
 
 
-- show()
function scene:show( event )
    if (debug) then print("showing 8GridScene") end
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        firstRun8 = true
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen 
        timer.performWithDelay(50, UpdateLocal8, 1)  
    end
end
 
 
-- hide()
function scene:hide( event )
    if (debug) then print("hiding 8GridScene") end
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        timer.cancel(timerResults8)
        timerResults8 = nil
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
 
    end
end
 
 
-- destroy()
function scene:destroy( event )
    if (debug) then print("destroying 8GridScene") end
 
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