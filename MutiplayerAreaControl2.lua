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

local gridzoom = 2 -- 1, 2, 3. 

local cellCollection = {} -- main background map tiles
local overlayCollection = {} -- AreaControl map tiles, translucent

local touchDetector = {} -- Determines what cell10 was tapped on the screen.

local timerResults = nil
local firstRun = true
local mapTileUpdater = nil

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
    gridzoom = gridzoom + 1
    if (gridzoom > 3) then gridzoom = 1 end
    local sceneGroup = scene.view

    timer.pause(timerResults)

    for i = 1, #cellCollection do cellCollection[i]:removeSelf() end
    for i = 1, #overlayCollection do overlayCollection[i]:removeSelf() end

    cellCollection = {}
    overlayCollection = {}
    makeGrid()

    for square = 1, #overlayCollection do
        overlayCollection[square]:toBack()
        cellCollection[square]:toBack() --same count
    end    
    touchDetector:toBack()

    directionArrow:toFront()
    forceRedraw = true
    timer.resume(timerResults)
    return true
end

function makeGrid()
    local sceneGroup = scene.view   
    if (gridzoom == 1) then
        CreateRectangleGrid(3, 640, 800, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(3, 640, 800, sceneGroup, overlayCollection) -- rectangular Cell11 grid with overlay
    elseif (gridzoom == 2) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(3, 320, 400, sceneGroup, overlayCollection) -- rectangular Cell11 grid with overlay
    elseif (gridzoom == 3) then
        CreateRectangleGrid(5, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(5, 160, 200, sceneGroup, overlayCollection) -- rectangular Cell11 grid with overlay
    end

    for square = 1, #overlayCollection do
        overlayCollection[square]:toBack()
        cellCollection[square]:toBack() --same count
    end    
    touchDetector:toBack()
end

--"tap" event
local function DetectLocationClick(event)
    print("Detecting location")
    -- we have a click somewhere in our rectangle. 
    -- zoomed out grid is 5x5 lowres tiles, 800 x 1000 total, each pixel is 1 Cell 11
    -- zoomed in grid is 3x3 highres tiles, 960 x 1200 total, each 2x2 pixels is 1 Cell 11

    -- figure out how many pixels from the center of the item each tap is
    -- divide those distances by 16 and 20 (or 8 and 10) to get cell10s away from center of image.
    local screenX = event.x
    local screenY = event.y
    local centerX = display.contentCenterX
    local centerY = display.contentCenterY

    --remember that the CENTER of the center square is the center pixel on screen, not the SW corner
    --so i have to shift info by half a square somewhere.

    local pixelshiftX = screenX - centerX
    local pixelshiftY = centerY - screenY --flips the sign to get things to line up correctly.
    local plusCodeShiftX = 0
    local plusCodeShiftY = 0

    if (gridzoom == 1) then
        pixelshiftX = pixelshiftX + 16
        pixelshiftY =  pixelshiftY + 20
        plusCodeShiftX = pixelshiftX / 32
        plusCodeShiftY = pixelshiftY / 40
    elseif (gridzoom == 2) then
        pixelshiftX = pixelshiftX + 8
        pixelshiftY =  pixelshiftY + 10
        plusCodeShiftX = pixelshiftX / 16
        plusCodeShiftY = pixelshiftY / 20
    elseif (gridzoom == 3) then
        pixelshiftX = pixelshiftX + 4
        pixelshiftY =  pixelshiftY + 5
        plusCodeShiftX = pixelshiftX / 8
        plusCodeShiftY = pixelshiftY / 10
    end

    local newCell = currentPlusCode:sub(0,8) .. "+FF" --might be GG, depends on direction of shift
    newCell = shiftCell(newCell, plusCodeShiftY, 9) --Y axis
    newCell = shiftCell(newCell, plusCodeShiftX, 10) --X axis
    print("Detected cell: " .. newCell)
    tapData.text = "Cell Tapped: " .. newCell

    local pluscodenoplus = removePlus(newCell)
    local terrainInfo = LoadTerrainData(pluscodenoplus)

    -- 3 is name, 4 is area type, 6 is mapDataID (privacyID)
    if (terrainInfo[3] == "") then
        tappedAreaName = terrainInfo[4]
    else
        tappedAreaName = terrainInfo[3]
    end
    
    tappedCell = newCell
    tappedAreaScore = 0 --i don't save this locally, this requires a network call to get and update
    tappedAreaMapDataId = terrainInfo[6]
    composer.showOverlay("overlayMPAreaClaim", {isModal = true})
    
end

local function GoToSceneSelect()
    print("back to scene select")
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
    return true
end

local function tintArrow(teamID)
    if (teamID == 1) then
        directionArrow:setFillColor(1, 0, 0, .5)
    elseif (teamID == 2) then
        directionArrow:setFillColor(0, 1, 0, .5)
    elseif (teamID == 3) then
        directionArrow:setFillColor(0, 0, 1, .5) 
    end
end

local function UpdateLocalOptimized()
    -- This needs to be 2 loops, because the cell tables are different sizes.
    -- First loop for map tiles
    -- Then loop for touch event rectangles.
    if timerResults == nil then
        timerResults = timer.performWithDelay(450, UpdateLocalOptimized, -1)
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

    --This function takes ~16ms to run, we call the loop every 150, we probably don't need to pause/resume the timer
    --if (timerResults ~= nil) then timer.pause(timerResults) end
    local innerForceRedraw = forceRedraw or firstRun or (currentPlusCode:sub(1,8) ~= previousPlusCode:sub(1,8))
    firstRun = false
    forceRedraw = false
    previousPlusCode = currentPlusCode
    
    if (arrowPainted == false) then
        if (factionID == 0) then
            GetTeamAssignment()
        else            
            tintArrow(factionID)
            arrowPainted = true
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
        --GetMapData8(plusCodeNoPlus)
        --checkTileGeneration(plusCodeNoPlus, "mapTiles")
        --all of this commented block should be replaced with the simpler call above
        --local imageRequested = requestedMapTileCells[plusCodeNoPlus] -- read from DataTracker because we want to know if we can paint the cell or not.
        
        --if (imageRequested == nil) then 
            --imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.CachesDirectory)
        --end
 
        --if (imageExists == false or imageExists == nil) then 
            --GetMapTile8(plusCodeNoPlus)
        --else
        local imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.CachesDirectory)
        if imageExists == true then
            cellCollection[square].fill = {0.1, 0.1} -- required to make Solar2d actually update the texture.
            local paint = {
                type = "image",
                filename = plusCodeNoPlus .. "-11.png",
                baseDir = system.CachesDirectory
            }
            cellCollection[square].fill = paint
        else
            cellCollection[square].fill = {0.1, 0.1} -- required to make Solar2d actually update the texture.
        end

        --checkTileGeneration(plusCodeNoPlus, "teamColor")
        --imageRequested = requestedMPMapTileCells[plusCodeNoPlus] -- read from DataTracker because we want to know if we can paint the cell or not.
        
        --if (imageRequested == nil) then 
            --imageExists = doesFileExist(plusCodeNoPlus .. "-AC-11.png", system.TemporaryDirectory)
        --end
        --if (imageExists == false or imageExists == nil) then 
            --GetTeamControlMapTile8(plusCodeNoPlus)

        imageExists = doesFileExist(plusCodeNoPlus .. "-AC-11.png", system.TemporaryDirectory)
        if imageExists then
            overlayCollection[square].fill = {0, 0} -- required to make Solar2d actually update the texture.
            local paint = {
                type = "image",
                filename = plusCodeNoPlus .. "-AC-11.png",
                baseDir = system.TemporaryDirectory
            }
            overlayCollection[square].fill = paint
        else
            overlayCollection[square].fill = {0, 0} -- required to make Solar2d actually update the texture.
        end
    end --for
    end --if

    --update team scores
    scoreCheckCounter = scoreCheckCounter - 1
    if (scoreCheckCounter <= 0) then
        GetMyScore()
        network.request(serverURL .. "Data/Global/scoreTeam1" .. defaultQueryString, "GET", team1ScoreListener)
        network.request(serverURL .. "Data/Global/scoreTeam2" .. defaultQueryString, "GET", team2ScoreListener)
        network.request(serverURL .. "Data/Global/scoreTeam3" .. defaultQueryString, "GET", team3ScoreListener)
        scoreCheckCounter = 24
    end

   -- if (timerResults ~= nil) then timer.resume(timerResults) end
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
    if (gridzoom == 1) then
        directionArrow.x = display.contentCenterX + (shift * 32)  + 16
        directionArrow.y = display.contentCenterY - (shift2 * 40) + 20
    elseif (gridzoom == 2) then
        directionArrow.x = display.contentCenterX + (shift * 16)  + 8
        directionArrow.y = display.contentCenterY - (shift2 * 20) + 10
    elseif (gridzoom == 3) then
        directionArrow.x = display.contentCenterX + (shift * 8) + 4
        directionArrow.y = display.contentCenterY - (shift2 * 10) + 5
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

local function UpdateMapTiles()
    --set this to run once a second or so
    for square = 1, #cellCollection do
        -- check each spot based on current cell, modified by gridX and gridY
        local thisSquaresPluscode = currentPlusCode
        thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridX, 8)
        thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridY, 7)
        cellCollection[square].pluscode = thisSquaresPluscode
        local plusCodeNoPlus = removePlus(thisSquaresPluscode):sub(1, 8)
        GetMapData8(plusCodeNoPlus)
        checkTileGeneration(plusCodeNoPlus, "mapTiles")
        checkTileGeneration(plusCodeNoPlus, "teamColor")
        --print('checked for tile ' .. plusCodeNoPlus)
    end -- for
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)
    composer.setVariable("myScore", "0")

    if (debug) then print("creating MPAreaControlScene2") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    touchDetector = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 720, 1280)
    touchDetector:addEventListener("tap", DetectLocationClick)
    touchDetector.fill = {0, 0.1}
    touchDetector:toBack()

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

    makeGrid()

    directionArrow = display.newImageRect(sceneGroup, "themables/arrow1.png", 16, 20)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY
    directionArrow.anchorX = .5
    directionArrow.anchorY = .5
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
        tintArrow(factionID)
        timer.performWithDelay(50, UpdateLocalOptimized, 1)
        if (debugGPS) then timer.performWithDelay(3000, testDrift, -1) end
        mapTileUpdater = timer.performWithDelay(2000, UpdateMapTiles, -1)
    end
end

function scene:hide(event)
    if (debug) then print("hiding AreaControl scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        timer.cancel(timerResults)
        timerResults = nil
        timer.cancel(mapTileUpdater)
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