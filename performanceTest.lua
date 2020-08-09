--performance testing scene.
local composer = require( "composer" )
 
local scene = composer.newScene()
 
require("UIParts")
require("database")
require("plusCodes")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
 local slowestFunc = "" --name of slow func
 local slowestTime = 0 --duration of slowest run

 local perfText = "" --displaytext object on screen.
 
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
 
    if (debug) then print("Creating perfTest") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen


end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        if (debug) then print("showing perftest") end
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
            --perfText = display.newText(sceneGroup, "slowest function:", display.contentCenterX, 200, native.systemFont, 20)
    local startTime = 0
    local endtime = 0
    local lastRunTime = 0
    local slowestRunTime = 0

    local textOptions = {}
    textOptions.parent =  sceneGroup
    textOptions.text = "function Log: "
    textOptions.x = display.contentCenterX
    textOptions.y = display.contentCenterY
    textOptions.width = 700
    textOptions.height = 0
    textOptions.font = native.systemFont
    textOptions.fontSize = 24

    perfText = display.newText(textOptions)
    perfText:addEventListener("tap", SwitchToBigGrid)


    local totalLog = ""
    --if (debug) then print("") end
    if (debug) then print("Making grid") end

    --check creating the display grid
    startTime = os.clock()
    local cellCollection = {}
    CreateSquareGrid(23, 25, sceneGroup, cellCollection)
    endtime = os.clock()
    lastRunTime = endtime - startTime
    if (lastRunTime > slowestTime) then
        slowestTime = lastRunTime
        slowestFunc = "createGrid-23"
    end

    totalLog = totalLog .. "createGrid-23" .. lastRunTime .. "|\n"
    print("func1 " .. lastRunTime)

    --check the updateLocal loops
    if (currentPlusCode == "") then currentPlusCode = "849VCRXR+9C" end
    startTime = os.clock()
    for square = 1, #cellCollection do --this is supposed to be faster than ipairs
        if VisitedCell(shiftCell(currentPlusCode, cellCollection[square].gridX, cellCollection[square].gridY)) then
            cellCollection[square].fill = visitedCell
        else
            cellCollection[square].fill = unvisitedCell
        end
    end
    endtime = os.clock()
    lastRunTime = endtime - startTime
    if (lastRunTime > slowestTime) then
        slowestTime = lastRunTime
        slowestFunc = "updateLocal-#cellCollection"
    end

    totalLog = totalLog .. "updateLocal-#cellCollection" .. lastRunTime .. "|\n"
    print("func2 " .. lastRunTime)

    startTime = os.clock()
    for a, i in ipairs(cellCollection) do 
        if VisitedCell(shiftCell(currentPlusCode, i.gridX, i.gridY)) then
            i.fill = visitedCell
        else
            i.fill = unvisitedCell
        end
    end
    endtime = os.clock()
    lastRunTime = endtime - startTime
    if (lastRunTime > slowestTime) then
        slowestTime = lastRunTime
        slowestFunc = "updateLocal-ipairs"
    end
    totalLog = totalLog .. "updateLocal-ipairs" .. lastRunTime .. "|\n"
    print("func3 " .. lastRunTime)

    perfText.text = perfText.text .. totalLog
 
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