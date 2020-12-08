-- multiplayer Area Control mode scene.
-- Version 2 TODO: have 1-9 images for background (use Cell8s for that), don't draw anything on the touch layer of rectangles.
-- maybe have your current Cell8 in the middle, shift around your cursor a few pixels to indicate position inside it, instead of dynamic scrolling all over?
-- probably have neighboring Cell8s around it.
-- A cell8 png is 80x100. 4x bigger than then current Cell10 stuff is.
-- so i want my grid to be 9x9?
-- each Cell8 is 20x20 Cell10s.
-- current Cell10 mode is 35x35.
-- So thats 2.75 Cell8s. Make it 3.
-- Speed issues on this app are due to the number of cells I have to check on screen and/or the number of .fill operations occurring (varies by scene)
-- so I can confirm that Solar2D will just not do well for a zoomed out set of Cell10 data the way I want this app to behave.
local composer = require("composer")
local scene = composer.newScene()

require("UIParts")
require("database")
require("dataTracker") -- replaced localNetwork for this scene

-- cleanup dones:
-- all variables declared are used.
-- using current names on the web server.

-- cleanup TODOs
-- move scene switch functions to some single file instead of copying them in each scene.
-- use removeplus function where necessary

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local bigGrid = true

local cellCollection = {} -- show cell area data/image tiles
local CellTapSensors = {} -- this is for tapping an area to claim, but needs renamed.
local ctsGroup = display.newGroup()
ctsGroup.x = -8
ctsGroup.y = 10
-- color codes

local unvisitedCell = {0, 0} -- completely transparent
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

local function testDrift()
    if (os.time() % 2 == 0) then
        currentPlusCode = shiftCellV3(currentPlusCode, 1, 9) -- move north
    else
        currentPlusCode = shiftCellV3(currentPlusCode, 1, 10) -- move west
    end
end

local function SwitchToBigGrid()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("8GridScene", options)
end

local function SwitchToTrophy()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("trophyScene", options)
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
        CreateRectangleGrid(61, 16, 20, ctsGroup, CellTapSensors, "mac") -- rectangular Cell11 grid  with event for area control
        ctsGroup.x = -8
        ctsGroup.y = 10
    else
        CreateRectangleGrid(3, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 8, 10, ctsGroup, CellTapSensors, "mac") -- rectangular Cell11 grid  with event for area control
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

    directionArrow:toFront()
    forceRedraw = true
    timer.resume(timerResults)
end

local function GoToLeaderboardScene()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("LeaderboardScene", options)
end

local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end

local function UpdateLocalOptimized()
    -- This now needs to be 2 loops, because the cell tables are different sizes.
    -- First loop for map tiles
    -- Then loop for touch event rectangles.
    if (debugLocal) then print("start UpdateLocalOptimized") end
    if (currentPlusCode == "") then
        if timerResults == nil then
            timerResults = timer.performWithDelay(150, UpdateLocalOptimized, -1)
        end
        if (debugLocal) then print("skipping, no location.") end
        return
    end

    if (debug) then debugText.text = dump(lastLocationEvent) end

    if (timerResults ~= nil) then timer.pause(timerResults) end
    local innerForceRedraw = forceRedraw or firstRun or (currentPlusCode ~= previousPlusCode)
    firstRun = false
    forceRedraw = false
    previousPlusCode = currentPlusCode

    -- Step 1: set background MAC map tiles for the Cell8. Should be much simpler than old loop.
    for square = 1, #cellCollection do
        -- check each spot based on current cell, modified by gridX and gridY
        local thisSquaresPluscode = currentPlusCode
        thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, cellCollection[square].gridX, 8)
        thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, cellCollection[square].gridY, 7)
        cellCollection[square].pluscode = thisSquaresPluscode
        local plusCodeNoPlus = removePlus(thisSquaresPluscode):sub(1, 8)

        if (innerForceRedraw == false) then -- and cellDataCache[plusCodeNoPlus] ~= nil) then -- and cellDataCache[plusCodeNoPlus].lastRefresh < os.time() - 60000
 
        else
             GetMapData8(plusCodeNoPlus)
            local imageRequested = requestedMapTileCells[plusCodeNoPlus] -- read from DataTracker because we want to know if we can paint the cell or not.
            local imageExists = doesFileExist(plusCodeNoPlus .. "-AC-11.png",
                                              system.DocumentsDirectory)
            if (imageRequested == nil) then -- or imageExists == 0 --if I check for 0, this is always nil? if I check for nil, this is true when images are present?
                imageExists = doesFileExist(plusCodeNoPlus .. "-AC-11.png",
                                            system.DocumentsDirectory)
            end
 
            if (imageExists == false or imageExists == nil) then -- not sure why this is true when file is found and 0 when its not? -- or imageExists == 0
                 GetTeamControlMapTile8(plusCodeNoPlus)
            else
                cellCollection[square].fill = {0, 0} -- required to make Solar2d actually update the texture.
                local paint = {
                    type = "image",
                    filename = plusCodeNoPlus .. "-AC-11.png",
                    baseDir = system.DocumentsDirectory
                }
                cellCollection[square].fill = paint
            end
        end
    end

    print("done with map cells")
    -- Step 2: set up event listener grid. These need Cell10s
    local baselinePlusCode = currentPlusCode:sub(1,8) .. "+FF"
    for square = 1, #CellTapSensors do
        --if (innerForceRedraw == true and cellDataCache[plusCodeNoPlus] ~= nil) then -- and cellDataCache[plusCodeNoPlus].lastRefresh < os.time() - 60000
        if (innerForceRedraw) then
            local thisSquaresPluscode = baselinePlusCode
            local shiftChar7 = math.floor(CellTapSensors[square].gridY / 20)
            local shiftChar8 = math.floor(CellTapSensors[square].gridX / 20)
            local shiftChar9 = math.floor(CellTapSensors[square].gridY % 20)
            local shiftChar10 = math.floor(CellTapSensors[square].gridX % 20)
            --print("Shifting values for " .. CellTapSensors[square].gridX .. " " ..CellTapSensors[square].gridY  .. ": " .. shiftChar7 .. " " .. shiftChar8 .. " " .. shiftChar9 .. " " .. shiftChar10)
            thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, shiftChar7, 7)
            thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, shiftChar8, 8)
            thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, shiftChar9, 9)
            thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, shiftChar10, 10)
            
            CellTapSensors[square].pluscode = thisSquaresPluscode
            local plusCodeNoPlus = removePlus(thisSquaresPluscode)
            local terrainInfo = LoadTerrainData(plusCodeNoPlus) -- terrainInfo is a whole row from the DB.
            
            if (#terrainInfo > 4 and terrainInfo[4] ~= "") then -- 4 is areaType. not every area is named, so use type.
                -- apply info
                CellTapSensors[square].name = terrainInfo[3]
                CellTapSensors[square].type = terrainInfo[4]
                CellTapSensors[square].MapDataId = terrainInfo[6]
            else
                CellTapSensors[square].name = ""
                CellTapSensors[square].type = ""
            end

            if (CellTapSensors[square].type ~= "") then
                CellTapSensors[square].fill = visitedCell
            end

            if (currentPlusCode == thisSquaresPluscode) then
                if (debugLocal) then print("setting name") end
                -- draw this place's name on screen, or an empty string if its not a place.
                locationName.text = CellTapSensors[square].name
                if (locationName.text == "" and CellTapSensors[square].type ~= 0) then
                    locationName.text = typeNames[CellTapSensors[square].type]
                end
            end

            cellDataCache[plusCodeNoPlus] = {}
            -- cellDataCache[plusCodeNoPlus].tileFill = {type  = "image", filename = plusCodeNoPlus .. "-AC-11.png", baseDir = system.DocumentsDirectory}
            cellDataCache[plusCodeNoPlus].name = CellTapSensors[square].name
            cellDataCache[plusCodeNoPlus].type = CellTapSensors[square].type
            cellDataCache[plusCodeNoPlus].MapDataId = CellTapSensors[square].MapDataId
            cellDataCache[plusCodeNoPlus].lastRefresh = os.time()

        end
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

    if (timerResults ~= nil) then timer.resume(timerResults) end
    if (debugLocal) then print("grid done or skipped") end
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

    if (debug) then print("creating MPAreaControlScene2") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    explorePointText = display.newText(sceneGroup, "Explore Points: ?", display.contentCenterX, 240, native.systemFont, 20)
    scoreText = display.newText(sceneGroup, "Control Score: ?", display.contentCenterX, 260, native.systemFont, 20)
    scoreLog = display.newText(sceneGroup, "", display.contentCenterX, 1250, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 280, native.systemFont, 20)

    --Note: i might want to put the CellTapSensors into their own group, and shift it around a couple pixels manually to make it line up better with the actual map tiles.
    if (bigGrid) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 16, 20, ctsGroup, CellTapSensors, "mac") -- rectangular Cell11 grid  with event for area control
    else
        -- original values, but too small to interact with.
        CreateRectangleGrid(3, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 5, 4, ctsGroup, CellTapSensors, "mac") -- rectangular Cell11 grid  with event for area control
    end
    print(ctsGroup.numChildren)
    

    directionArrow = display.newImageRect(sceneGroup, "themables/arrow1.png", 25, 25)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY

    local changeGrid = display.newImageRect(sceneGroup, "themables/BigGridButton.png", 300,100)
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

    local header = display.newImageRect(sceneGroup, "themables/MultiplayerAreaControl.png",300, 100)
    header.x = display.contentCenterX
    header.y = 100
    header:addEventListener("tap", GoToSceneSelect)

    local zoom = display.newImageRect(sceneGroup, "themables/ToggleZoom.png", 100, 100)
    zoom.anchorX = 0
    zoom.x = 50
    zoom.y = 100
    zoom:addEventListener("tap", ToggleZoom)

    local leaderboard = display.newImageRect(sceneGroup, "themables/LeaderboardIcon.png", 100, 100)
    leaderboard.anchorX = 0
    leaderboard.x = 580
    leaderboard.y = 100
    leaderboard:addEventListener("tap", GoToLeaderboardScene)

    if (debug) then
        debugText = display.newText(sceneGroup, "location data", display.contentCenterX, 1180, 600, 0, native.systemFont, 22)
    end

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
