-- multiplayer Area Control mode scene.
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

local cellCollection = {} -- main background map tiles
local overlayCollection = {} -- AreaControl map tiles, translucent
local CellTapSensors = {} -- this is for tapping an area to claim, but needs renamed. TODO: find a way to replace this with a single sensor?
local ctsGroup = display.newGroup()
ctsGroup.x = -8
ctsGroup.y = 10

local timerResults = nil
local firstRun = true

local locationText = ""
local explorePointText = ""
local scoreText = ""
local teamScoreText = ""
local timeText = ""
local directionArrow = ""
local scoreLog = ""
local debugText = {}
local locationName = ""
local arrowPainted = false

local scoreCheckCounter = 0
local team1Score = "0"
local team2Score = "0"
local team3Score = "0"

function team1ScoreListener(event)
    if (event.status == 200) then       
        team1Score = event.response
    end
end

function team2ScoreListener(event)
    if (event.status == 200) then
        team2Score = event.response
    end
end

function team3ScoreListener(event)
    if (event.status == 200) then
        team3Score = event.response
    end
end

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
    for i = 1, #overlayCollection do overlayCollection[i]:removeSelf() end
    for i = 1, #CellTapSensors do CellTapSensors[i]:removeSelf() end

    cellCollection = {}
    overlayCollection = {}
    CellTapSensors = {}

    if (bigGrid) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(3, 320, 400, sceneGroup, overlayCollection) -- rectangular Cell11 grid with area control overlay
        CreateRectangleGrid(61, 16, 20, ctsGroup, CellTapSensors, "mac") -- rectangular Cell11 grid  with event for area control
        ctsGroup.x = -8
        ctsGroup.y = 10
    else
        CreateRectangleGrid(5, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(5, 160, 200, sceneGroup, overlayCollection) -- rectangular Cell11 grid with area control overlay
        CreateRectangleGrid(80, 8, 10, ctsGroup, CellTapSensors, "mac") -- rectangular Cell11 grid  with event for area control
        ctsGroup.x = -4
        ctsGroup.y = 5
    end
    --Move these to the back first, so that the map tiles will be behind them.
    for square = 1, #CellTapSensors do
        -- check each spot based on current cell, modified by gridX and gridY
        CellTapSensors[square]:toBack()
    end

    for square = 1, #overlayCollection do
        -- check each spot based on current cell, modified by gridX and gridY
        overlayCollection[square]:toBack()
    end

    for square = 1, #cellCollection do
        -- check each spot based on current cell, modified by gridX and gridY
        cellCollection[square]:toBack()
    end

    directionArrow:toFront()
    forceRedraw = true
    timer.resume(timerResults)
    return true
end

local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end

local function tintArrow(teamID)
    if (teamID == 1) then
        directionArrow:setFillColor(1, 0, 0, .5)
    elseif (teamID == 2) then
        directionArrow:setFillColor(0, 1, 0, .5)
    elseif (teamID == 3) then
        directionArrow:setFillColor(0, 0, 1, .5) 
    end
    arrowPainted = true
end

local function UpdateLocalOptimized()
    -- This needs to be 2 loops, because the cell tables are different sizes.
    -- First loop for map tiles
    -- Then loop for touch event rectangles.
    if timerResults == nil then
        timerResults = timer.performWithDelay(150, UpdateLocalOptimized, -1)
    end

    if not playerInBounds then
        return
    end

    if (debugLocal) then print("start UpdateLocalOptimized") end
    if (currentPlusCode == "") then
        if (debugLocal) then print("skipping, no location.") end
        return
    end

    if (debug) then debugText.text = dump(lastLocationEvent) end

    if (timerResults ~= nil) then timer.pause(timerResults) end
    local innerForceRedraw = forceRedraw or firstRun or (currentPlusCode:sub(1,8) ~= previousPlusCode:sub(1,8))
    firstRun = false
    forceRedraw = false
    previousPlusCode = currentPlusCode
    
    if (arrowPainted == false) then
        local teamID = factionID 
        if (teamID == 0) then
            GetTeamAssignment()
        else            
            tintArrow(teamID)
        end
    end

    -- Step 1: set background MAC map tiles for the Cell8.
    if (innerForceRedraw == false) then -- none of this needs to get processed if we haven't moved and there's no new maptiles to refresh.
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

            imageRequested = requestedMPMapTileCells[plusCodeNoPlus] -- read from DataTracker because we want to know if we can paint the cell or not.
            imageExists = doesFileExist(plusCodeNoPlus .. "-AC-11.png", system.TemporaryDirectory)
            if (imageRequested == nil) then 
                imageExists = doesFileExist(plusCodeNoPlus .. "-AC-11.png", system.TemporaryDirectory)
            end
 
            if (imageExists == false or imageExists == nil) then 
                 GetTeamControlMapTile8(plusCodeNoPlus)
            else
                overlayCollection[square].fill = {0, 0} -- required to make Solar2d actually update the texture.
                local paint = {
                    type = "image",
                    filename = plusCodeNoPlus .. "-AC-11.png",
                    baseDir = system.TemporaryDirectory
                }
                overlayCollection[square].fill = paint
            end
        end
    end

    -- Step 2: set up event listener grid. These need Cell10s
    local baselinePlusCode = currentPlusCode:sub(1,8) .. "+FF"
    if (innerForceRedraw) then --Also no need to do all of this unless we shifted our Cell8 location.
    for square = 1, #CellTapSensors do
            local thisSquaresPluscode = baselinePlusCode
            local shiftChar7 = math.floor(CellTapSensors[square].gridY / 20)
            local shiftChar8 = math.floor(CellTapSensors[square].gridX / 20)
            local shiftChar9 = math.floor(CellTapSensors[square].gridY % 20)
            local shiftChar10 = math.floor(CellTapSensors[square].gridX % 20)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar7, 7)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar8, 8)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar9, 9)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar10, 10)

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

            if (currentPlusCode == thisSquaresPluscode) then
                if (debugLocal) then print("setting name") end
                -- draw this place's name on screen, or an empty string if its not a place.
                locationName.text = CellTapSensors[square].name
                if (locationName.text == "") then
                    locationName.text = CellTapSensors[square].type
                end
            end
        end
    end  

    --update team scores
    scoreCheckCounter = scoreCheckCounter - 1
    if (scoreCheckCounter <= 0) then
        GetMyScore()
        network.request(serverURL .. "Data/GetGlobalData/scoreTeam1" .. defaultQueryString, "GET", team1ScoreListener)
        network.request(serverURL .. "Data/GetGlobalData/scoreTeam2" .. defaultQueryString, "GET", team2ScoreListener)
        network.request(serverURL .. "Data/GetGlobalData/scoreTeam3" .. defaultQueryString, "GET", team3ScoreListener)
        scoreCheckCounter = 24
    end

    if (timerResults ~= nil) then timer.resume(timerResults) end
    if (debugLocal) then print("grid done or skipped") end
    locationText.text = "Current location:" .. currentPlusCode
    explorePointText.text = "Explore Points: " .. Score()
    scoreText.text = "Control Score: " .. composer.getVariable("myScore")
    teamScoreText.text = "Red Team: " .. team1Score   .. "\nGreen Team: " .. team2Score .. "\nBlue Team: " .. team3Score
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading

    --Remember, currentPlusCode has the +, so i want chars 10 and 11, not 9 and 10.
    --Shift is how many blocks to move. Multiply it by how big each block is. These offsets place the arrow in the correct Cell10.
    local shift = CODE_ALPHABET_:find(currentPlusCode:sub(11, 11)) - 11
    local shift2 = CODE_ALPHABET_:find(currentPlusCode:sub(10, 10)) - 10
    if (bigGrid) then
        directionArrow.x = display.contentCenterX + (shift * 16)
        directionArrow.y = display.contentCenterY - (shift2 * 20)
    else
        directionArrow.x = display.contentCenterX + (shift * 8)
        directionArrow.y = display.contentCenterY - (shift2 * 10)
    end
    scoreLog.text = lastScoreLog

    locationText:toFront()
    explorePointText:toFront()
    scoreText:toFront()
    teamScoreText:toFront()
    timeText:toFront()
    directionArrow:toFront()
    scoreLog:toFront()
    locationName:toFront()

    if (debugLocal) then print("end updateLocalOptimized") end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)
    composer.setVariable("myScore", "0")

    if (debug) then print("creating MPAreaControlScene2") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    sceneGroup:insert(ctsGroup)

    contrastSquare = display.newRect(sceneGroup, display.contentCenterX, 270, 400, 200)
    contrastSquare:setFillColor(.8, .8, .8, .7)

    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    explorePointText = display.newText(sceneGroup, "Explore Points: ?", display.contentCenterX, 240, native.systemFont, 20)
    scoreText = display.newText(sceneGroup, "Control Score: ?", display.contentCenterX, 260, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 280, native.systemFont, 20)
    teamScoreText = display.newText(sceneGroup, "Team Scores", display.contentCenterX, 300, native.systemFont, 20)
    teamScoreText.anchorY = 0
    scoreLog = display.newText(sceneGroup, "", display.contentCenterX, 1220, native.systemFont, 20)    

    locationText:setFillColor(0, 0, 0);
    timeText:setFillColor(0, 0, 0);
    explorePointText:setFillColor(0, 0, 0);
    scoreText:setFillColor(0, 0, 0);
    teamScoreText:setFillColor(0, 0, 0);
    scoreLog:setFillColor(0, 0, 0);
    locationName:setFillColor(0, 0, 0);

    if (bigGrid) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(3, 320, 400, sceneGroup, overlayCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 16, 20, ctsGroup, CellTapSensors, "mac") -- rectangular Cell11 grid  with event for area control
    else
        CreateRectangleGrid(5, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(5, 160, 200, sceneGroup, overlayCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(80, 8, 10, ctsGroup, CellTapSensors, "mac") -- rectangular Cell11 grid  with event for area control
    end  

    directionArrow = display.newImageRect(sceneGroup, "themables/arrow1.png", 16, 20)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY
    directionArrow.anchorX = 0
    directionArrow.anchorY = 0
    directionArrow:toFront()

    local header = display.newImageRect(sceneGroup, "themables/MultiplayerAreaControl.png",300, 100)
    header.x = display.contentCenterX
    header.y = 100
    header:addEventListener("tap", GoToSceneSelect)
    header:toFront()

    local zoom = display.newImageRect(sceneGroup, "themables/ToggleZoom.png", 100, 100)
    zoom.anchorX = 0
    zoom.x = 50
    zoom.y = 100
    zoom:addEventListener("tap", ToggleZoom)
    

    if (debug) then
        debugText = display.newText(sceneGroup, "location data", display.contentCenterX, 1180, 600, 0, native.systemFont, 22)
        debugText:toFront()
    end
    ctsGroup:toFront()
    zoom:toFront()
    contrastSquare:toFront()
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
