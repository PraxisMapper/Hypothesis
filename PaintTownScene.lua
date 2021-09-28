--Paint The Town  Mode
--TODO: rework this to the new non-competitive mode
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
local CellTapSensors = {} -- Not detecting taps in this mode. This is the highlight layer.
local ctsGroup = display.newGroup()
ctsGroup.x = -8
ctsGroup.y = 10

local timerResults = nil
local PaintTownMapUpdateCountdown = 8 --wait this many loops over the main update before doing a network call. 
local firstRun = true

local locationText = ""
local directionArrow = ""
local debugText = {}
local locationName = ""

local zoom = ""
local arrowPainted = false

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
    timer.pause(timerResults)

    for i = 1, #cellCollection do cellCollection[i]:removeSelf() end
    for i = 1, #CellTapSensors do CellTapSensors[i]:removeSelf() end

    cellCollection = {}
    CellTapSensors = {}

    if (bigGrid) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(61, 16, 20, ctsGroup, CellTapSensors, "painttown") -- rectangular Cell11 grid with a color fill
        ctsGroup.x = -8
        ctsGroup.y = 10
    else
        CreateRectangleGrid(5, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(90, 8, 10, ctsGroup, CellTapSensors, "painttown") -- rectangular Cell11 grid  with a color fill
        ctsGroup.x = -4
        ctsGroup.y = 5
    end
    --Move these to the back first, so that the map tiles will be behind them.
    for square = 1, #CellTapSensors do
        -- check each spot based on current cell, modified by gridX and gridY
        CellTapSensors[square]:toBack()
    end

    for square = 1, #cellCollection do
        -- check each spot based on current cell, modified by gridX and gridY
        cellCollection[square]:toBack()
    end

    reorderUI()
    forceRedraw = true
    timer.resume(timerResults)
end

local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
    return true
end

local function UpdateLocalOptimized()
    -- This now needs to be 2 loops, because the cell tables are different sizes.
    -- First loop for map tiles
    -- Then loop for touch event rectangles that get shaded.
    if timerResults == nil then
        timerResults = timer.performWithDelay(150, UpdateLocalOptimized, -1)
    end

    if (debugLocal) then print("start UpdateLocalOptimized") end
    if (currentPlusCode == "") then
        if (debugLocal) then print("skipping, no location.") end
        return
    end

     if (not playerInBounds) then
         return
    end

    if (debug) then debugText.text = dump(lastLocationEvent) end

    local plusCodeNoPlus = removePlus(currentPlusCode)
    if (timerResults ~= nil) then timer.pause(timerResults) end
    local innerForceRedraw = forceRedraw or firstRun or (currentPlusCode:sub(1,8) ~= previousPlusCode:sub(1,8))
    firstRun = false
    forceRedraw = false
    if currentPlusCode ~= previousPlusCode then
        ClaimPaintTownCell(plusCodeNoPlus)
        innerForceRedraw = true
    end
    previousPlusCode = currentPlusCode

    -- draw this place's name on screen, or an empty string if its not a place.
    local terrainInfo = LoadTerrainData(plusCodeNoPlus) -- terrainInfo is a whole row from the DB.
    locationName.text = terrainInfo[3]; --name
    if locationName.text == "" then
        locationName.text = terrainInfo[4] --area type name
    end

    PaintTownMapUpdateCountdown = PaintTownMapUpdateCountdown -1
    -- Step 1: set background MAC map tiles for the Cell8. Should be much simpler than old loop.
    if (innerForceRedraw == false) then -- none of this needs to get processed if we haven't moved and there's no new maptiles to refresh.
        for square = 1, #cellCollection do
            -- check each spot based on current cell, modified by gridX and gridY    
            local thisSquaresPluscode = currentPlusCode
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridX, 8)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridY, 7)
            cellCollection[square].pluscode = thisSquaresPluscode
            local plusCodeNoPlus = removePlus(thisSquaresPluscode):sub(1, 8)
            if (PaintTownMapUpdateCountdown == 0) then
                GetPaintTownMapData8(plusCodeNoPlus)
            end
                GetMapData8(plusCodeNoPlus)
                local imageRequested = requestedMapTileCells[plusCodeNoPlus] -- read from DataTracker because we want to know if we can paint the cell or not.
                local imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.CachesDirectory)
                if (imageRequested == nil) then -- or imageExists == 0 --if I check for 0, this is always nil? if I check for nil, this is true when images are present?
                    imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.CachesDirectory)
                end
                if (imageExists == false or imageExists == nil) then -- not sure why this is true when file is found and 0 when its not? -- or imageExists == 0
                    cellCollection[square].fill = {0, 0} -- required to make Solar2d actually update the texture.
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

    if (debug) then  print("done with map cells") end
    -- Step 2: set up event listener grid. These need Cell10s
    local baselinePlusCode = currentPlusCode:sub(1,8) .. "+FF"
    if (innerForceRedraw) then --Also no need to do all of this unless we shifted our Cell8 location.
        for square = 1, #CellTapSensors do
            CellTapSensors[square].fill = {0, 0}
            local thisSquaresPluscode = baselinePlusCode
            local shiftChar7 = math.floor(CellTapSensors[square].gridY / 20)
            local shiftChar8 = math.floor(CellTapSensors[square].gridX / 20)
            local shiftChar9 = math.floor(CellTapSensors[square].gridY % 20)
            local shiftChar10 = math.floor(CellTapSensors[square].gridX % 20)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar7, 7)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar8, 8)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar9, 9)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar10, 10)
            local idCheck = removePlus(thisSquaresPluscode)

            CellTapSensors[square].pluscode = thisSquaresPluscode
            if (requestedPaintTownCells[idCheck] ~= nil) then
                CellTapSensors[square].fill = requestedPaintTownCells[idCheck]
            end
        end
    end

    if PaintTownMapUpdateCountdown == 0 then
        PaintTownMapUpdateCountdown = 30 -- 60 loops is roughly 10 seconds of time passing. 30 = 5s
    end

    if (timerResults ~= nil) then timer.resume(timerResults) end
    if (debugLocal) then print("grid done or skipped") end
    locationText.text = "Current location:" .. currentPlusCode
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading

    local shift = CODE_ALPHABET_:find(currentPlusCode:sub(11, 11)) - 11
    local shift2 = CODE_ALPHABET_:find(currentPlusCode:sub(10, 10)) - 10
    if (bigGrid) then
        directionArrow.x = display.contentCenterX + (shift * 16)
        directionArrow.y = display.contentCenterY - (shift2 * 20)
    else
        directionArrow.x = display.contentCenterX + (shift * 4)
        directionArrow.y = display.contentCenterY - (shift2 * 5)
    end

    locationText:toFront()
    timeText:toFront()
    directionArrow:toFront()
    locationName:toFront()

    if (debugLocal) then print("end updateLocalOptimized") end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)
    if (debug) then print("creating painttown scene") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    sceneGroup:insert(ctsGroup)

    contrastSquare = display.newRect(sceneGroup, display.contentCenterX, 220, 400, 100)
    contrastSquare:setFillColor(.8, .8, .8, .7)
    
    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 240, native.systemFont, 20)

    locationText:setFillColor(0, 0, 0);
    timeText:setFillColor(0, 0, 0);
    locationName:setFillColor(0, 0, 0);

    if (bigGrid) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 16, 20, ctsGroup, CellTapSensors, "painttown") -- rectangular Cell11 grid  with color fill
    else
        -- original values, but too small to interact with.
        CreateRectangleGrid(3, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 5, 4, ctsGroup, CellTapSensors, "painttown") -- rectangular Cell11 grid  with color fill
    end  

    directionArrow = display.newImageRect(sceneGroup, "themables/arrow1.png", 16, 20)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY
    directionArrow.anchorX = 0
    directionArrow.anchorY = 0
    directionArrow:toFront()

    header = display.newImageRect(sceneGroup, "themables/PaintTown.png",300, 100)
    header.x = display.contentCenterX
    header.y = 100
    header:addEventListener("tap", GoToSceneSelect)
    header:toFront()

    zoom = display.newImageRect(sceneGroup, "themables/ToggleZoom.png", 100, 100)
    zoom.anchorX = 0
    zoom.x = 50
    zoom.y = 100
    zoom:addEventListener("tap", ToggleZoom)
    zoom:toFront()

    if (debug) then
        debugText = display.newText(sceneGroup, "location data", display.contentCenterX, 1180, 600, 0, native.systemFont, 22)
        debugText:setFillColor(0, 0, 0);
        debugText:toFront()
    end

    contrastSquare:toFront()

    if (debug) then print("created PaintTown scene") end
end

function reorderUI()
    ctsGroup:toFront()
    header:toFront()
    zoom:toFront()
    directionArrow:toFront()
end

function scene:show(event)
    if (debug) then print("showing painttown scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        firstRun = true
    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen 
        timer.performWithDelay(50, UpdateLocalOptimized, 1)
        if (debugGPS) then timer.performWithDelay(1000, testDrift, -1) end
        reorderUI()
    end
    if (debug) then print("showed painttown scene") end
end

function scene:hide(event)
    if (debug) then print("hiding painttown scene") end
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
    if (debug) then print("destroying painttown scene") end

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