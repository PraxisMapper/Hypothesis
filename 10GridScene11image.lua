local composer = require("composer")
local scene = composer.newScene()

require("UIParts")
require("database")
require("localNetwork")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

-- TODO
-- add a bounce-and-fall popup for when you gain score, add a sound effect to that too?

local cellCollection = {}
-- color codes
local unvisitedCell = {.3, .3, .3, 1} -- medium grey
local visitedCell = {.1, .4, .4, 1} --lightish green
local parkCell = {0, .7, .0, 1} --bold green
local waterCell = {0, 0, .7, 1} --deep blue
local beachCell = {.845, .712, .153, 1}  -- yellow
local cemeteryCell = {.14, .14, .133, 1}  --really dark grey
local natureReserveCell = {.07, .277, .015, 1}  --darker green than park
local retailCell = {.922, .391, .992, 1}  --pink
local tourismCell = {.1, .605, .822, 1}  --sky blue
local universityCell = {.963, .936, .862, 1}  --off-white, slightly yellow-brown
local wetlandsCell= {.111, .252, .146, 1}  --swampy green
local historicalCell = {.7, .7, 7, 1}  --edit to.... something? Historically interesting area.
local mallCell = {1, .7, .2, 1}  --edit to something?  Big indoor retail area. Might change to just retail.
local trailCell = {.47, .18, .02, 1}  --Brown  A footpath or bridleway or cycleway or a path that isn't a sidewalk, in OSM terms
local adminCell = {0,0,0,0} --None. We shouldn't draw admin cells. But the database has started tracking admin boundaries.

local timerResults = nil
local firstRun = true

local locationText = ""
local countText = ""
local pointText = ""
local timeText = ""
local directionArrow = ""
local scoreLog = ""
local debugText = {}
local locationName = ""

local function testDrift()
    if (os.time() % 2 == 0) then
        currentPlusCode = shiftCellV3(currentPlusCode, 1, 9) -- move north
    else
        currentPlusCode = shiftCellV3(currentPlusCode, 1, 10) -- move west
    end
end

local function UpdateLocal()
    if (debugLocal) then print("start UpdateLocal") end
    if (debugLocal) then print(currentPlusCode) end

    if (currentPlusCode == "") then
        if timerResults == nil then
            timerResults = timer.performWithDelay(500, UpdateLocal, -1)
        end
        if (debugLocal) then print("skipping, no location.") end
        return
    end

    if (debug) then debugText.text = dump(lastLocationEvent) end

    if (currentPlusCode ~= previousPlusCode or firstRun or forceRedraw or debugGPS) then
        firstRun = false
        forceRedraw = false
        previousPlusCode = currentPlusCode
        for square = 1, #cellCollection do -- this is slightly faster than ipairs
            -- check each spot based on current cell, modified by gridX and gridY
            local thisSquaresPluscode = currentPlusCode
            --print (currentPlusCode)
            thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, cellCollection[square].gridX, 10)
            thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, cellCollection[square].gridY, 9)
            cellCollection[square].pluscode = thisSquaresPluscode
            local plusCodeNoPlus = thisSquaresPluscode:sub(1, 8) .. thisSquaresPluscode:sub(10, 11)

            --print("updating local")
            -- apply type now if we found it.
            local terrainInfo = LoadTerrainData(plusCodeNoPlus) -- terrainInfo is a whole row from the DB.
            if (terrainInfo[4] ~= "") then -- 4 is areaType. not every area is named, so use type.
                -- apply info
                cellCollection[square].name = terrainInfo[3]
                cellCollection[square].type = terrainInfo[4]
            else
                -- apply generic colors.
                cellCollection[square].name = ""
                cellCollection[square].type = ""
            end

            if not cellCollection[square].isFilled then
                --print("cell " .. square)
                local imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.DocumentsDirectory)
                if (not imageExists) then
                    --pull image from server
                    print("dl image " .. plusCodeNoPlus)
                    Get10CellImage11(plusCodeNoPlus)
                    if VisitedCell(thisSquaresPluscode) then
                        cellCollection[square].fill = visitedCell
                    else
                        cellCollection[square].fill = unvisitedCell
                    end
                else
                    local paint = {type  = "image", filename = plusCodeNoPlus .. "-11.png", baseDir = system.DocumentsDirectory}
                    cellCollection[square].fill = paint
                    cellCollection[square].isFilled = true
                end

            -- if (#terrainInfo == 0) then
            --     -- we don't have this cell, use default colors and values.
            --     cellCollection[square].name = ""
            --     cellCollection[square].type = ""
            --     if VisitedCell(thisSquaresPluscode) then
            --         cellCollection[square].fill = visitedCell
            --     else
            --         cellCollection[square].fill = unvisitedCell
            --     end
            -- else
            --     if (terrainInfo[4] ~= "") then -- 4 is areaType. not every area is named, so use type.
            --         -- apply info
            --         cellCollection[square].name = terrainInfo[3]
            --         cellCollection[square].type = terrainInfo[4]
            --     else
            --         -- apply generic colors.
            --         cellCollection[square].name = ""
            --         cellCollection[square].type = ""
            --     end
            --     --TODO: could probably set cell type to 'visited' when its marked visited
            --     --as a small optimization 

            --     -- cellCollection is a table of imageRects with a couple extra properties assigned.
            --     -- now handle assigning colors
            --     if (cellCollection[square].type == "") then
            --         if VisitedCell(thisSquaresPluscode) then
            --             cellCollection[square].fill = visitedCell
            --         else
            --             cellCollection[square].fill = unvisitedCell
            --         end
            --     else
            --         --these are now numbers instead of strings on the server side.
            --         if (cellCollection[square].type ==  "1") then --"water"
            --             cellCollection[square].fill = waterCell
            --         elseif (cellCollection[square].type == "3" ) then --"park"
            --             cellCollection[square].fill = parkCell
            --         elseif (cellCollection[square].type == "7") then --"cemetery"
            --             cellCollection[square].fill = cemeteryCell
            --         elseif (cellCollection[square].type == "2") then --"wetlands"
            --             cellCollection[square].fill = wetlandsCell
            --         elseif (cellCollection[square].type == "4") then --"beach"
            --             cellCollection[square].fill = beachCell
            --         elseif (cellCollection[square].type == "6") then --"natureReserve"
            --             cellCollection[square].fill = natureReserveCell
            --         elseif (cellCollection[square].type ==  "9") then --"retail"
            --             cellCollection[square].fill = retailCell
            --         elseif (cellCollection[square].type == "10" ) then --"tourism"
            --             cellCollection[square].fill = tourismCell
            --         elseif (cellCollection[square].type == "5") then --"university"
            --             cellCollection[square].fill = universityCell
            --         elseif (cellCollection[square].type == "12") then -- "trail"
            --             cellCollection[square].fill = trailCell
            --         elseif (cellCollection[square].type == "13") then
            --         --elseif (string.sub(cellCollection[square].type, 1, 5) == "admin") then
            --             --cellCollection[square].fill = adminCell --We don't draw these
            --         end
            --     end
            end

            if (currentPlusCode == thisSquaresPluscode) then
                -- draw this place's name on screen, or an empty string if its not a place.
                locationName.text = cellCollection[square].name
            end
        end
    end

    if (debugGPS) then print("grid done or skipped") end
    if (debugGPS) then print(locationText.text) end
    locationText.text = "Current location:" .. currentPlusCode
    countText.text = "Total Explored Cells: " .. TotalExploredCells()
    pointText.text = "Score: " .. Score()
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading
    scoreLog.text = lastScoreLog

    if timerResults == nil then
        timerResults = timer.performWithDelay(500, UpdateLocal, -1)
    end

    if (debugGPS) then print("end updateLocal") end
end

local function SwitchToBigGrid()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("8GridScene", options)
end

local function SwitchToTrophy()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("trophyScene", options)
end

local function GoToStoreScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("storeScene", options)
end

local function GoToLeaderboardScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("LeaderboardScene", options)
end

local function SwitchToDebugScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("performanceTest", options)
end

local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)

    if (debug) then print("creating 10GridScene") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    countText = display.newText(sceneGroup, "Total Cells Explored: ?", display.contentCenterX, 240, native.systemFont, 20)
    pointText = display.newText(sceneGroup, "Score: ?", display.contentCenterX, 260, native.systemFont, 20)
    scoreLog = display.newText(sceneGroup, "", display.contentCenterX, 1250, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 280, native.systemFont, 20)

    --CreateSquareGrid(23, 25, sceneGroup, cellCollection)
    CreateRectangleGrid(29, 20, 16, sceneGroup, cellCollection) -- rectangles are different sized now. Will have to investigate sizing.


    directionArrow = display.newImageRect(sceneGroup, "themables/arrow1.png", 25, 25)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY

    local changeGrid = display.newImageRect(sceneGroup, "themables/BigGridButton.png", 300, 100)
    changeGrid.anchorX = 0
    changeGrid.anchorY = 0
    changeGrid.x = 60
    changeGrid.y = 1000

    local changeTrophy = display.newImageRect(sceneGroup, "themables/TrophyRoom.png", 300, 100)
    changeTrophy.anchorX = 0
    changeTrophy.anchorY = 0
    changeTrophy.x = 390
    changeTrophy.y = 1000

    changeGrid:addEventListener("tap", SwitchToBigGrid)
    changeTrophy:addEventListener("tap", SwitchToTrophy)

    local header = display.newImageRect(sceneGroup, "themables/SmallGridButton.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 100
    header:addEventListener("tap", GoToSceneSelect)

    local store = display.newImageRect(sceneGroup, "themables/StoreIcon.png", 100, 100)
    store.anchorX = 0
    -- store.anchorY = 0
    store.x = 50
    store.y = 100
    store:addEventListener("tap", GoToStoreScene)

    local leaderboard = display.newImageRect(sceneGroup, "themables/LeaderboardIcon.png", 100, 100)
    leaderboard.anchorX = 0
    -- leaderboard.anchorY = 0
    leaderboard.x = 580
    leaderboard.y = 100
    leaderboard:addEventListener("tap", GoToLeaderboardScene)

    if (debug) then
        print("Creating debugText")
        debugText = display.newText(sceneGroup, "location data", display.contentCenterX, 1180, 600, 0, native.systemFont, 22)
        print("Created debugText")
    end

    if (debug) then print("created 10Grid11Scene") end

end

-- show()
function scene:show(event)
    if (debug) then print("showing 10Grid11Scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        firstRun = true

    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen 
        timer.performWithDelay(50, UpdateLocal, 1)

        if (debugGPS) then timer.performWithDelay(500, testDrift, -1) end
    end
end

-- hide()
function scene:hide(event)
    if (debug) then print("hiding 10GridScene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        timer.cancel(timerResults)
        timerResults = nil

    elseif (phase == "did") then
        -- Code here runs immediately after the scene goes entirely off screen

    end
end

-- destroy()
function scene:destroy(event)
    if (debug) then print("destroying 10GridScene") end

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)
-- -----------------------------------------------------------------------------------

return scene
