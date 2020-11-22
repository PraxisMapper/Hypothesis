-- TODO: this will be the Area Control scene for this debug/demo app.
--Tap a square, show overlayAreaClaim to claim a square
--have a 2nd grid of images overlaying the original grid, tint those squares sky blue and translucent (50%? 30%?) if it's an owned cell.

local composer = require("composer")
local scene = composer.newScene()



require("UIParts")
require("database")
--require("localNetwork") --testing replacing this with DataTracker
require("dataTracker")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local bigGrid = true

local cellCollection = {} --show cell area data/image tiles
local visitedCellDisplay = {} --where we tint cells to show control.
-- color codes

local unvisitedCell = {0, 0} -- completely transparent
local visitedCell = {.529, .807, .921, .4} -- sky blue, 50% transparent
local selectedCell = {.8, .2, .2, .4} -- some kind of red, 50% transparent

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
local explorePointText = ""
local scoreText = ""
local timeText = ""
local directionArrow = ""
local scoreLog = ""
local debugText = {}
local locationName = ""

local allCellsTerrain = ""
local cellTerrainToRequest = {} -- these need to be distinct. I cant just add every cell.
local allCellsMapTiles = ""
local cellTilesToRequest = {}
local mapTilesAlreadyPresent = {}



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
        if (debugLocal) then print("entering main loop") end
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

            --check if we need to download terrain data
            GetMapData8(thisSquaresPluscode:sub(1, 8))
            -- if (Downloaded8Cell(thisSquaresPluscode:sub(1, 8)) == false) then
            --     if (string.find(allCellsTerrain, thisSquaresPluscode:sub(1, 8)) == nil) then
            --         cellTerrainToRequest[#cellTerrainToRequest+ 1] = thisSquaresPluscode:sub(1, 8)
            --         allCellsTerrain = allCellsTerrain .. thisSquaresPluscode:sub(1, 8) .. ","
            --     end
            --end
            --print("updating local")
            -- apply type now if we found it.

            --I wonder if we can speed up performance by throwing TerrainData into a table the way we do for data call and map tiles
            local terrainInfo = LoadTerrainData(plusCodeNoPlus) -- terrainInfo is a whole row from the DB.
            if (terrainInfo[4] ~= "") then -- 4 is areaType. not every area is named, so use type.
                -- apply info
                cellCollection[square].name = terrainInfo[3]
                cellCollection[square].type = terrainInfo[4]
            else
                cellCollection[square].name = ""
                cellCollection[square].type = ""
            end
                        
            --Area control specific properties
            --only try to tint cells if we have a TerrainInfo property
            if (#terrainInfo >= 6) then
                cellCollection[square].MapDataId = terrainInfo[6]
                if (CheckAreaOwned(terrainInfo[6]) == true) then
                    visitedCellDisplay[square].fill = visitedCell
                else    
                    visitedCellDisplay[square].fill = unvisitedCell
                end
            else
                visitedCellDisplay[square].fill = unvisitedCell
            end

            --if not cellCollection[square].isFilled then
                --check if we need to download the map tile
                
                local imageExists = requestedMapTileCells[plusCodeNoPlus] --read from DataTracker because we want to know if we can paint the cell or not.
                --print(imageExists)
                if (imageExists == nil) then
                    imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.DocumentsDirectory)
                end
                if (not imageExists) then
                    GetMapTile10(plusCodeNoPlus)
                    --pull image from server
                    --print("dl image " .. plusCodeNoPlus)
                    --print(requestedCells)
                -- cellTerrainToRequest[#cellTerrainToRequest+ 1] = thisSquaresPluscode:sub(1, 8)
                -- local cellTilesToRequest = {}
                --     local cellAlreadyCalled = string.find(allCellsMapTiles, plusCodeNoPlus .. ",")
                --     if ( cellAlreadyCalled == nil) then
                --         Get10CellImage11(plusCodeNoPlus)
                --         allCellsMapTiles = allCellsMapTiles .. plusCodeNoPlus .. ","
                --     end
                else
                    --mapTilesAlreadyPresent[plusCodeNoPlus] = 1
                    local paint = {type  = "image", filename = plusCodeNoPlus .. "-11.png", baseDir = system.DocumentsDirectory}
                    cellCollection[square].fill = paint
                    --cellCollection[square].isFilled = true
                    --if (debugLocal) then print("painted cell with loaded image") end
                end
            

            if (currentPlusCode == thisSquaresPluscode) then
                if (debugLocal) then print("setting name") end
                -- draw this place's name on screen, or an empty string if its not a place.
                locationName.text = cellCollection[square].name
                if (locationName.text == ""  and cellCollection[square].type ~= 0) then
                    locationName.text = typeNames[cellCollection[square].type]
                end
            end

            if (tappedCell == thisSquaresPluscode) then
                --highlight this square on the grid so i can see what i clicked.
                visitedCellDisplay[square].fill = selectedCell
            end
        end
    end

    if (debugLocal) then print("grid done or skipped") end
    if (debugGPS) then print(locationText.text) end
    locationText.text = "Current location:" .. currentPlusCode
    explorePointText.text = "Explore Points: " .. Score()
    scoreText.text = "Control Score: " .. AreaControlScore()
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading
    scoreLog.text = lastScoreLog

    if timerResults == nil then
        if (debugLocal) then print("setting timer") end
        timerResults = timer.performWithDelay(500, UpdateLocal, -1)
    end

    --print("not borked yet " .. #cellTerrainToRequest)
    -- for i = 1, #cellTerrainToRequest do
    --     if (string.find(allCellsTerrain, cellTerrainToRequest[i]) == nil) then
    --         print("getting data on " .. cellTerrainToRequest[i])
    --         Get8CellData(cellTerrainToRequest[i])
    --         --print("data requested")
    --         forceRedraw = true
    --     end
    -- end

    if (debugLocal) then print("end updateLocal") end
end

local function SwitchToBigGrid()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("8GridScene", options)
end

local function SwitchToTrophy()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("trophyScene", options)
end

-- local function GoToStoreScene()
--     local options = {effect = "flip", time = 125}
--     composer.gotoScene("storeScene", options)
-- end

local function ToggleZoom()
    bigGrid = not bigGrid   
    local sceneGroup = scene.view

    for i = 1, #cellCollection do
        cellCollection[i]:removeSelf()
        visitedCellDisplay[i]:removeSelf()
    end
    cellCollection = {}
    visitedCellDisplay = {}

    if (bigGrid) then
        CreateRectangleGrid(35, 16, 20, sceneGroup, cellCollection, "ac") -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(35, 16, 20, sceneGroup, visitedCellDisplay, "tint") -- rectangular Cell11 grid  with tint for area control
    else
        CreateRectangleGrid(17, 32, 40, sceneGroup, cellCollection, "ac") -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(17, 32, 40, sceneGroup, visitedCellDisplay, "tint") -- rectangular Cell11 grid  with tint for area control
    end
    directionArrow:toFront()
    forceRedraw = true
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

local function UpdateLocalOptimized()
    if (debugLocal) then print("start UpdateLocalOptimized") end
    if (debugLocal) then print(currentPlusCode) end

    if (currentPlusCode == "") then
        if timerResults == nil then
            timerResults = timer.performWithDelay(150, UpdateLocalOptimized, -1)
        end
        if (debugLocal) then print("skipping, no location.") end
        return
    end
  
    if (debug) then debugText.text = dump(lastLocationEvent) end

    if (redrawOverlay) then
        print("redrawing overlay: " .. tappedCell)
        --only do the overlay layer, probably because we tapped a cell. Should be faster than a full redraw
        for square = 1, #cellCollection do -- this is slightly faster than ipairs
            local pc = removePlus(cellCollection[square].pluscode)
            if (cellCollection[square].pluscode == tappedCell) then
                visitedCellDisplay[square].fill = selectedCell
            else
                visitedCellDisplay[square].fill = cellDataCache[pc].visitedFill
            end
        end
        redrawOverlay = false
        print("completed redrawing overlay: ")
    end

    if (currentPlusCode ~= previousPlusCode or firstRun or forceRedraw or debugGPS) then
        if (debugLocal) then print("entering main loop") end
        firstRun = false
        previousPlusCode = currentPlusCode
        for square = 1, #cellCollection do -- this is slightly faster than ipairs
            -- check each spot based on current cell, modified by gridX and gridY
            local thisSquaresPluscode = currentPlusCode
            --print (currentPlusCode)
            thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, cellCollection[square].gridX, 10)
            thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, cellCollection[square].gridY, 9)
            cellCollection[square].pluscode = thisSquaresPluscode
            local plusCodeNoPlus = removePlus(thisSquaresPluscode)

            if (cellDataCache[plusCodeNoPlus] ~= nil and cellDataCache[plusCodeNoPlus].refresh == true) then print("need to refresh a cell!") end
            if (forceRedraw == false and cellDataCache[plusCodeNoPlus] ~= nil and cellDataCache[plusCodeNoPlus].refresh == false) then
                --we can skip some of the processing we did earlier.
                cellCollection[square].fill = cellDataCache[plusCodeNoPlus].tileFill
                visitedCellDisplay[square].fill = cellDataCache[plusCodeNoPlus].visitedFill
                cellCollection[square].name = cellDataCache[plusCodeNoPlus].name
                cellCollection[square].type = cellDataCache[plusCodeNoPlus].type
                cellCollection[square].MapDataId =  cellDataCache[plusCodeNoPlus].MapDataId
                cellDataCache[plusCodeNoPlus].refresh = false
            else
                --fill in all the stuff for this cell
                --check if we need to download terrain data
                cellDataCache[plusCodeNoPlus] = {}
                GetMapData8(thisSquaresPluscode:sub(1, 8))
                local terrainInfo = LoadTerrainData(plusCodeNoPlus) -- terrainInfo is a whole row from the DB.
                if (terrainInfo[4] ~= "") then -- 4 is areaType. not every area is named, so use type.
                    -- apply info
                    cellCollection[square].name = terrainInfo[3]
                    cellCollection[square].type = terrainInfo[4]
                else
                    cellCollection[square].name = ""
                    cellCollection[square].type = ""
                end
                        
                --Area control specific properties
                --only try to tint cells if we have a TerrainInfo property
                if (#terrainInfo >= 6) then
                    cellCollection[square].MapDataId = terrainInfo[6]
                    if (CheckAreaOwned(terrainInfo[6]) == true) then
                        visitedCellDisplay[square].fill = visitedCell
                        cellDataCache[plusCodeNoPlus].visitedFill = visitedCell
                    else    
                        visitedCellDisplay[square].fill = unvisitedCell
                        cellDataCache[plusCodeNoPlus].visitedFill = unvisitedCell
                    end
                else
                    visitedCellDisplay[square].fill = unvisitedCell
                    cellDataCache[plusCodeNoPlus].visitedFill = unvisitedCell
                end
                
                local imageExists = requestedMapTileCells[plusCodeNoPlus] --read from DataTracker because we want to know if we can paint the cell or not.
                --print(imageExists)
                if (imageExists == nil) then
                    imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.DocumentsDirectory)
                end
                if (not imageExists) then
                    GetMapTile10(plusCodeNoPlus)
                else
                    local paint = {type  = "image", filename = plusCodeNoPlus .. "-11.png", baseDir = system.DocumentsDirectory}
                    cellCollection[square].fill = paint
                end

                --save all this data (we already saved the visitedFill earlier)
                cellDataCache[plusCodeNoPlus].tileFill = {type  = "image", filename = plusCodeNoPlus .. "-11.png", baseDir = system.DocumentsDirectory}
                cellDataCache[plusCodeNoPlus].name = cellCollection[square].name
                cellDataCache[plusCodeNoPlus].type = cellCollection[square].type
                cellDataCache[plusCodeNoPlus].MapDataId =  cellCollection[square].MapDataId
                cellDataCache[plusCodeNoPlus].refresh = false
            end

            --these checks happens either way.
            if (currentPlusCode == thisSquaresPluscode) then
                if (debugLocal) then print("setting name") end
                -- draw this place's name on screen, or an empty string if its not a place.
                locationName.text = cellCollection[square].name
                if (locationName.text == ""  and cellCollection[square].type ~= 0) then
                    locationName.text = typeNames[cellCollection[square].type]
                end
            end

            if (tappedCell == thisSquaresPluscode) then
                --highlight this square on the grid so i can see what i clicked.
                visitedCellDisplay[square].fill = selectedCell
            else
                visitedCellDisplay[square].fill = cellDataCache[plusCodeNoPlus].visitedFill
            end
        end
    end

    forceRedraw = false
    if (debugLocal) then print("grid done or skipped") end
    if (debugGPS) then print(locationText.text) end
    locationText.text = "Current location:" .. currentPlusCode
    explorePointText.text = "Explore Points: " .. Score()
    scoreText.text = "Control Score: " .. AreaControlScore()
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading
    scoreLog.text = lastScoreLog

    if timerResults == nil then
        if (debugLocal) then print("setting timer") end
        timerResults = timer.performWithDelay(150, UpdateLocalOptimized, -1)
    end

    if (debugLocal) then print("end updateLocalOptimized") end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)

    if (debug) then print("creating AreaControlScene") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    explorePointText = display.newText(sceneGroup, "Explore Points: ?", display.contentCenterX, 240, native.systemFont, 20)
    scoreText = display.newText(sceneGroup, "Control Score: ?", display.contentCenterX, 260, native.systemFont, 20)
    scoreLog = display.newText(sceneGroup, "", display.contentCenterX, 1250, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 280, native.systemFont, 20)

    --CreateSquareGrid(23, 25, sceneGroup, cellCollection) --original square grid with spacing
    if (bigGrid) then
        CreateRectangleGrid(35, 16, 20, sceneGroup, cellCollection, "ac") -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(35, 16, 20, sceneGroup, visitedCellDisplay, "tint") -- rectangular Cell11 grid  with tint for area control
    else
        CreateRectangleGrid(17, 32, 40, sceneGroup, cellCollection, "ac") -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(17, 32, 40, sceneGroup, visitedCellDisplay, "tint") -- rectangular Cell11 grid  with tint for area control
    end

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

    local header = display.newImageRect(sceneGroup, "themables/AreaControl.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 100
    header:addEventListener("tap", GoToSceneSelect)

    --local store = display.newImageRect(sceneGroup, "themables/StoreIcon.png", 100, 100)
    local store = display.newImageRect(sceneGroup, "themables/ToggleZoom.png", 100, 100)
    store.anchorX = 0
    -- store.anchorY = 0
    store.x = 50
    store.y = 100
    --store:addEventListener("tap", GoToStoreScene)
    store:addEventListener("tap", ToggleZoom)

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

    if (debug) then print("created AreaControl scene") end

end

-- show()
function scene:show(event)
    if (debug) then print("showing AreaControl scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        firstRun = true

    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen 
        timer.performWithDelay(50, UpdateLocalOptimized, 1)

        if (debugGPS) then timer.performWithDelay(8000, testDrift, -1) end
    end
end

-- hide()
function scene:hide(event)
    if (debug) then print("hiding AreaControl scene") end
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
    if (debug) then print("destroying AreaControl scene") end

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
