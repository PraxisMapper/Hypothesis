-- single player Area Control mode scene.
-- Now uses my newer style of code, runs a good deal faster.
local composer = require("composer")
local scene = composer.newScene()

require("UIParts")
require("database")
require("dataTracker")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local bigGrid = true

local cellCollection = {} -- show cell area data/image tiles
local visitedCellDisplay = {} -- where we tint cells to show control.
local ctsGroup = display.newGroup()
ctsGroup.x = -8
ctsGroup.y = 10

local unvisitedCell = {0, 0.01} -- completely transparent
local visitedCell = {.529, .807, .921, .4} -- sky blue, 50% transparent
local selectedCell = {.8, .2, .2, .4} -- red, 50% transparent

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
local header= ""
local zoom = ""

local function testDrift()
    if (os.time() % 2 == 0) then
        currentPlusCode = shiftCell(currentPlusCode, 1, 9) -- move north
    else
        currentPlusCode = shiftCell(currentPlusCode, 1, 10) -- move west
    end
end

local function ToggleZoom()
    bigGrid = not bigGrid
    local sceneGroup = scene.view

    for i = 1, #cellCollection do
        cellCollection[i]:removeSelf()
    end

    for i = 1, #visitedCellDisplay do
        visitedCellDisplay[i]:removeSelf()
    end
    cellCollection = {}
    visitedCellDisplay = {}

    if (bigGrid) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 16, 20, ctsGroup, visitedCellDisplay, "ac") -- rectangular Cell11 grid  with event for area control
        ctsGroup.x = -8
        ctsGroup.y = 10
    else
        CreateRectangleGrid(3, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 8, 10, ctsGroup, visitedCellDisplay, "ac") -- rectangular Cell11 grid  with event for area control
        ctsGroup.x = -4
        ctsGroup.y = 5
    end
    
    ctsGroup:toFront()
    header:toFront()
    locationText:toFront()
    explorePointText:toFront()
    scoreText:toFront()
    timeText:toFront()
    directionArrow:toFront()
    scoreLog:toFront()
    zoom:toFront()

    forceRedraw = true
    return true
end

local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
    return true
end

local function UpdateLocalOptimized()
    if (debugLocal) then print("start UpdateLocalOptimized") end

    if (currentPlusCode == "") then
        if timerResults == nil then
            timerResults = timer.performWithDelay(150, UpdateLocalOptimized, -1)
        end
        if (debugLocal) then print("skipping, no location.") end
        return
    end

    if (debug) then debugText.text = dump(lastLocationEvent) end

    if (redrawOverlay) then
        if (debugLocal) then print("redrawing overlay: " .. tappedCell) end
        -- only do the overlay layer, because we tapped a cell.
        for square = 1, #cellCollection do
            local pc = removePlus(cellCollection[square].pluscode)
            if (cellCollection[square].pluscode == tappedCell) then
                visitedCellDisplay[square].fill = selectedCell
            else
                visitedCellDisplay[square].fill = cellDataCache[pc].visitedFill
            end
        end
        redrawOverlay = false
        if (debugLocal) then print("completed redrawing overlay: ") end
    end

    local innerForceRedraw = forceRedraw or firstRun or (currentPlusCode:sub(1, 8) ~= previousPlusCode:sub(1, 8))
    firstRun = false
    forceRedraw = false
    -- Step 1: set background map tiles for the Cell8. Should be much simpler than old loop.
    if (innerForceRedraw) then -- none of this needs to get processed if we haven't moved and there's no new maptiles to refresh.
        for square = 1, #cellCollection do
            -- check each spot based on current cell, modified by gridX and gridY
            local thisSquaresPluscode = currentPlusCode
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridX, 8)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridY, 7)
            cellCollection[square].pluscode = thisSquaresPluscode
            local plusCodeNoPlus = removePlus(thisSquaresPluscode):sub(1, 8)

            GetMapData8(plusCodeNoPlus)
            local imageRequested = requestedMapTileCells[plusCodeNoPlus] -- read from DataTracker because we want to know if we can paint the cell or not.
            local imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.CachesDirectory)
            if (imageRequested == nil) then
                imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.CachesDirectory)
            end

            if (imageExists == false or imageExists == nil) then
                GetMapTile8(plusCodeNoPlus)
            else
                cellCollection[square].fill = {0, 0} -- required to make Solar2d actually update the texture.
                local paint = {
                    type = "image",
                    filename = plusCodeNoPlus .. "-11.png",
                    baseDir = system.CachesDirectory
                }
                cellCollection[square].fill = paint
            end
        end
    end

    -- Step 2: set up event listener grid. These need Cell10s
    local baselinePlusCode = currentPlusCode:sub(1, 8) .. "+FF"
    if (innerForceRedraw) then -- Also no need to do all of this unless we shifted our Cell8 location or claimed an area.
        for square = 1, #visitedCellDisplay do
            local thisSquaresPluscode = baselinePlusCode
            local shiftChar7 = math.floor(visitedCellDisplay[square].gridY / 20)
            local shiftChar8 = math.floor(visitedCellDisplay[square].gridX / 20)
            local shiftChar9 = math.floor(visitedCellDisplay[square].gridY % 20)
            local shiftChar10 = math.floor(visitedCellDisplay[square].gridX % 20)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar7, 7)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar8, 8)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar9, 9)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar10, 10)
            plusCodeNoPlus = removePlus(thisSquaresPluscode)

            if (cellDataCache[plusCodeNoPlus] ~= nil and innerForceRedraw == false) then
                -- use cached data.
                cellDataCache[plusCodeNoPlus].name = visitedCellDisplay[square].name
                cellDataCache[plusCodeNoPlus].type = visitedCellDisplay[square].type
                cellDataCache[plusCodeNoPlus].pluscode = thisSquaresPluscode
                cellDataCache[plusCodeNoPlus].MapDataId = visitedCellDisplay[square].MapDataId
                cellDataCache[plusCodeNoPlus].lastRefresh = os.time()
            else
                visitedCellDisplay[square].pluscode = thisSquaresPluscode
                local plusCodeNoPlus = removePlus(thisSquaresPluscode)
                local terrainInfo = LoadTerrainData(plusCodeNoPlus) -- terrainInfo is a whole row from the DB.

                if (#terrainInfo > 4 and terrainInfo[4] ~= "") then -- 4 is areaType. not every area is named, so use type.
                    -- apply info
                    visitedCellDisplay[square].name = terrainInfo[3]
                    visitedCellDisplay[square].type = terrainInfo[4]
                    visitedCellDisplay[square].MapDataId = terrainInfo[6]
                else
                    visitedCellDisplay[square].name = ""
                    visitedCellDisplay[square].type = ""
                end

                -- Area control specific properties
                if (#terrainInfo >= 6) then
                    visitedCellDisplay[square].MapDataId = terrainInfo[6]
                    if (CheckAreaOwned(terrainInfo[6]) == true) then
                        visitedCellDisplay[square].fill = visitedCell
                    else
                        visitedCellDisplay[square].fill = unvisitedCell
                    end
                else
                    visitedCellDisplay[square].fill = unvisitedCell
                end

                if (currentPlusCode == thisSquaresPluscode) then
                    if (debugLocal) then
                        print("setting name")
                    end
                    -- draw this place's name on screen, or an empty string if its not a place.
                    locationName.text = visitedCellDisplay[square].name
                    if (locationName.text == "" and visitedCellDisplay[square].type ~= 0) then
                        locationName.text = typeNames[visitedCellDisplay[square].type]
                    end
                end

                cellDataCache[plusCodeNoPlus] = {}
                cellDataCache[plusCodeNoPlus].name = visitedCellDisplay[square].name
                cellDataCache[plusCodeNoPlus].type = visitedCellDisplay[square].type
                cellDataCache[plusCodeNoPlus].MapDataId = visitedCellDisplay[square].MapDataId
                cellDataCache[plusCodeNoPlus].pluscode = thisSquaresPluscode
                cellDataCache[plusCodeNoPlus].lastRefresh = os.time()
            end
        end
    end
    -- these checks happens either way.
    if (currentPlusCode == thisSquaresPluscode) then
        if (debugLocal) then print("setting name") end
        -- draw this place's name on screen, or an empty string if its not a place.
        locationName.text = cellCollection[square].name
        if (locationName.text == "" and cellCollection[square].type ~= 0) then
            locationName.text = typeNames[cellCollection[square].type]
        end
    end

    local shift = CODE_ALPHABET_:find(currentPlusCode:sub(11, 11)) - 11
    local shift2 = CODE_ALPHABET_:find(currentPlusCode:sub(10, 10)) - 10
    if (bigGrid) then
        directionArrow.x = display.contentCenterX + (shift * 16)
        directionArrow.y = display.contentCenterY - (shift2 * 20)
    else
        directionArrow.x = display.contentCenterX + (shift * 8)
        directionArrow.y = display.contentCenterY - (shift2 * 10)
    end

    if (debugLocal) then print("grid done or skipped") end
    locationText.text = "Current location:" .. currentPlusCode
    explorePointText.text = "Explore Points: " .. Score()
    scoreText.text = "Control Score: " .. AreaControlScore()
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading
    scoreLog.text = lastScoreLog

    previousPlusCode = currentPlusCode

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
    sceneGroup:insert(ctsGroup)
    -- Code here runs when the scene is first created but has not yet appeared on screen

    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    explorePointText = display.newText(sceneGroup, "Explore Points: ?", display.contentCenterX, 240, native.systemFont, 20)
    scoreText = display.newText(sceneGroup, "Control Score: ?", display.contentCenterX, 260, native.systemFont, 20)
    scoreLog = display.newText(sceneGroup, "", display.contentCenterX, 1250, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 280, native.systemFont, 20)

    if (bigGrid) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 16, 20, ctsGroup, visitedCellDisplay, "ac") -- rectangular Cell11 grid  with event for area control
    else
        CreateRectangleGrid(3, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 5, 4, ctsGroup, visitedCellDisplay, "ac") -- rectangular Cell11 grid  with event for area control
    end

    directionArrow = display.newImageRect(sceneGroup, "themables/arrow1.png", 25, 25)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY

    header = display.newImageRect(sceneGroup, "themables/AreaControl.png",300, 100)
    header.x = display.contentCenterX
    header.y = 100
    header:addEventListener("tap", GoToSceneSelect)

    zoom = display.newImageRect(sceneGroup, "themables/ToggleZoom.png", 100, 100)
    zoom.anchorX = 0
    zoom.x = 50
    zoom.y = 100
    zoom:addEventListener("tap", ToggleZoom)

    if (debug) then
        debugText = display.newText(sceneGroup, "location data",display.contentCenterX, 1180, 600, 0, native.systemFont, 22)
    end

    ctsGroup:toFront()
    header:toFront()
    locationText:toFront()
    explorePointText:toFront()
    scoreText:toFront()
    timeText:toFront()
    directionArrow:toFront()
    scoreLog:toFront()
    zoom:toFront()

    if (debug) then print("created AreaControl scene") end
end

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
        if (debugGPS) then timer.performWithDelay(3000, testDrift, -1) end
    end
end

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