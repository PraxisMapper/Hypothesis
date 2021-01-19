--Turf War Mode
--Simplified area control mode: walk into a Cell10, claim it for your team.
--(Teams get assigned by the server randomly per instance. TODO for servr to make and client ot get a team on a new instance.)
--auto-resets on a scheduled basis, can have multiple scoreboards/instances going.
--should use Cell8 for background tiles performance, but an overlay that changes colors for cell10s.
local composer = require("composer")
local scene = composer.newScene()

require("UIParts")
require("database")
require("dataTracker") -- replaced localNetwork for this scene

-- cleanup TODOs
-- move scene switch functions to some single file instead of copying them in each scene.
-- use removeplus function where necessary

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
-- color codes

local unvisitedCell = {0, 0} -- completely transparent
local visitedCell = {.529, .807, .921, .4} -- sky blue, 50% transparent
local selectedCell = {.8, .2, .2, .4} -- red, 50% transparent

--TODO: populate this from server info.
local TeamColors = {}
TeamColors[1] = {1, 0, 0, .6}
TeamColors[2] = {0, 1, 0, .6}
TeamColors[3] = {.1, .605, .822, .6} --sky blue for team 3.

local timerResults = nil
local timerResultsMap = nil
local timerResultsScoreboard = nil
local TurfWarMapUpdateCountdown = 8 --wait this many loops over the main update before doing a network call. 
local firstRun = true

local locationText = ""
--local explorePointText = ""
local scoreText = ""
local timeText = ""
local directionArrow = ""
local scoreLog = ""
local debugText = {}
local locationName = ""

local instanceID = 1
local factionID = 0 --invalid, will avoid accidental claims until you get your team.

local function GetScoreboard()
    --local instanceID = "1"
    local url = serverURL .. "TurfWar/Scoreboard/" .. instanceID
    network.request(url, "GET", GetScoreboardListener)
    print("scoreboard request sent to " .. url)
end

function GetScoreboardListener(event) --these listeners can't be local.
    print("scoreboard listener fired")
    if event.status == 200 then
        print("got Scoreboard")
        print(event.response)
        local results = Split(event.response, "|")
        local setText = ""
        --line 1 is instanceName#time.
        --every other line is teamName=Score, need to iterate those.
        setText = Split(results[1], "#")[1] .. "\n"
        for i = 2, #results do
            setText = setText .. results[i] .. "\n"
        end
        scoreText.text = setText
        print(setText)
    end
    print("scoreboard text done")
end

local function GetTeamAssignment()
    --local instanceID = "1"
    local url = serverURL .. "TurfWar/AssignTeam/" .. instanceID .. "/" .. system.getInfo("deviceID")
    network.request(url, "GET", GetTeamAssignmentListener)
    print("Team request sent to " .. url)
end

function GetTeamAssignmentListener(event)
    print("Team listener fired")
    print(event.status)
    if event.status == 200 then
        print("got Team")
        print(event.response)
        factionID = tonumber(event.response)
        if (factionID == 1) then
            directionArrow:setFillColor(1, 0, 0, .5)
        elseif (factionID == 2) then
            directionArrow:setFillColor(0, 1, 0, .5)
        elseif (factionID == 3) then
            directionArrow:setFillColor(0, 0, 1, .5) 
        end
    end
    print("Team Assignment done")
end

local function testDrift()
    if (os.time() % 2 == 0) then
        currentPlusCode = shiftCellV3(currentPlusCode, 1, 9) -- move north
    else
        currentPlusCode = shiftCellV3(currentPlusCode, 1, 10) -- move west
    end
end

-- local function SwitchToBigGrid()
--     local options = {effect = "flip", time = 125}
--     composer.gotoScene("8GridScene", options)
-- end

-- local function SwitchToTrophy()
--     local options = {effect = "flip", time = 125}
--     composer.gotoScene("trophyScene", options)
-- end

local function ToggleZoom()
    bigGrid = not bigGrid
    local sceneGroup = scene.view

    timer.pause(timerResults)
    timer.pause(timerResultsMap)

    for i = 1, #cellCollection do cellCollection[i]:removeSelf() end
    for i = 1, #CellTapSensors do CellTapSensors[i]:removeSelf() end

    cellCollection = {}
    CellTapSensors = {}

    if (bigGrid) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(61, 16, 20, ctsGroup, CellTapSensors, "turfwar") -- rectangular Cell11 grid with a color fill
        ctsGroup.x = -8
        ctsGroup.y = 10
    else
        CreateRectangleGrid(3, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 8, 10, ctsGroup, CellTapSensors, "turfwar") -- rectangular Cell11 grid  with a color fill
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
    timer.resume(timerResultsMap)
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
    local innerForceRedraw = forceRedraw or firstRun or (currentPlusCode:sub(1,8) ~= previousPlusCode:sub(1,8))
    firstRun = false
    forceRedraw = false
    if currentPlusCode ~= previousPlusCode then
        ClaimTurfWarCell(removePlus(currentPlusCode), factionID)
    end
    previousPlusCode = currentPlusCode

    TurfWarMapUpdateCountdown = TurfWarMapUpdateCountdown -1
    -- Step 1: set background MAC map tiles for the Cell8. Should be much simpler than old loop.
    if (innerForceRedraw == false) then -- none of this needs to get processed if we haven't moved and there's no new maptiles to refresh.
    for square = 1, #cellCollection do
        -- check each spot based on current cell, modified by gridX and gridY
        local thisSquaresPluscode = currentPlusCode
        thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, cellCollection[square].gridX, 8)
        thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, cellCollection[square].gridY, 7)
        cellCollection[square].pluscode = thisSquaresPluscode
        local plusCodeNoPlus = removePlus(thisSquaresPluscode):sub(1, 8)

        if (TurfWarMapUpdateCountdown == 0) then
            GetTurfWarMapData8(plusCodeNoPlus, 1) --probably doesnt need called every single frame. TODO add a counter to call this every 4 times or something.
        end
            GetMapData8(plusCodeNoPlus)
            local imageRequested = requestedMapTileCells[plusCodeNoPlus] -- read from DataTracker because we want to know if we can paint the cell or not.
            local imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.DocumentsDirectory)
            if (imageRequested == nil) then -- or imageExists == 0 --if I check for 0, this is always nil? if I check for nil, this is true when images are present?
                imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.DocumentsDirectory)
            end
            if (imageExists == false or imageExists == nil) then -- not sure why this is true when file is found and 0 when its not? -- or imageExists == 0
                 GetMapTile8(plusCodeNoPlus)
            else
                cellCollection[square].fill = {0, 0} -- required to make Solar2d actually update the texture.
                local paint = {
                    type = "image",
                    filename = plusCodeNoPlus .. "-11.png",
                    baseDir = system.DocumentsDirectory
                }
                cellCollection[square].fill = paint
            end
        end
    end

    print("done with map cells")
    -- Step 2: set up event listener grid. These need Cell10s
    local baselinePlusCode = currentPlusCode:sub(1,8) .. "+FF"
    if (innerForceRedraw) then --Also no need to do all of this unless we shifted our Cell8 location.
    for square = 1, #CellTapSensors do
        --if (innerForceRedraw == true and cellDataCache[plusCodeNoPlus] ~= nil) then -- and cellDataCache[plusCodeNoPlus].lastRefresh < os.time() - 60000
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
            local idCheck = removePlus(thisSquaresPluscode)
            --print(thisSquaresPluscode)
            --print(idCheck)
            --print(requestedTurfWarCells[1][idCheck])

            CellTapSensors[square].fill = unvisitedCell
            if (requestedTurfWarCells[idCheck] ~= nil) then
                local teamID = requestedTurfWarCells[idCheck]
                CellTapSensors[square].fill = TeamColors[tonumber(teamID)]
                --print("painted " .. idCheck .. " with team color " .. teamID)
            end
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

    if TurfWarMapUpdateCountdown == 0 then
        TurfWarMapUpdateCountdown = 8
    end

    if (timerResults ~= nil) then timer.resume(timerResults) end
    if (debugLocal) then print("grid done or skipped") end
    locationText.text = "Current location:" .. currentPlusCode
    --explorePointText.text = "Explore Points: " .. Score()
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading
    --print(currentPlusCode)
    --Remember, currentPlusCode has the +, so i want chars 10 and 11, not 9 and 10.
    --Shift is how many blocks to move. Multiply it by how big each block is. These offsets place the arrow in the correct Cell10.
    local shift = CODE_ALPHABET_:find(currentPlusCode:sub(11, 11)) - 11
    local shift2 = CODE_ALPHABET_:find(currentPlusCode:sub(10, 10)) - 10
    print (shift .. " " ..  shift2)
    if (bigGrid) then
        directionArrow.x = display.contentCenterX + (shift * 16)
        directionArrow.y = display.contentCenterY - (shift2 * 20)
    else
        directionArrow.x = display.contentCenterX + (shift * 4)
        directionArrow.y = display.contentCenterY - (shift2 * 5)
    end
    scoreLog.text = lastScoreLog

    locationText:toFront()
    --explorePointText:toFront()
    scoreText:toFront()
    timeText:toFront()
    directionArrow:toFront()
    scoreLog:toFront()

    if timerResults == nil then
        if (debugLocal) then print("setting timer") end
        timerResults = timer.performWithDelay(150, UpdateLocalOptimized, -1)
    end

    if timerResultsMap == nil then
        timerResultsMap = timer.performWithDelay(1500, UpdateTurfWarMap, -1)
    end

    if (debugLocal) then print("end updateLocalOptimized") end
end

function UpdateTurfWarMap()
    local TurfWarInstances = {1}
    --GetTurfWarMapData8(currentPlusCode:sub(1,8), 1)
end


-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)

    if (debug) then print("creating TurfWar scene") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    sceneGroup:insert(ctsGroup)

    --TODO: swap these to TurfWar info (your team, team scoreboards)
    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    --explorePointText = display.newText(sceneGroup, "Explore Points: ?", display.contentCenterX, 240, native.systemFont, 20)
    scoreText = display.newText(sceneGroup, "Leaderboards: ?", display.contentCenterX, 300, native.systemFont, 20)
    scoreLog = display.newText(sceneGroup, "", display.contentCenterX, 1250, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 280, native.systemFont, 20)

    if (bigGrid) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 16, 20, ctsGroup, CellTapSensors, "turfwar") -- rectangular Cell11 grid  with color fill
    else
        -- original values, but too small to interact with.
        CreateRectangleGrid(3, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(60, 5, 4, ctsGroup, CellTapSensors, "turfar") -- rectangular Cell11 grid  with color fill
    end  

    directionArrow = display.newImageRect(sceneGroup, "themables/arrow1.png", 16, 20)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY
    directionArrow.anchorX = 0
    directionArrow.anchorY = 0
    directionArrow:toFront()

    -- local changeGrid = display.newImageRect(sceneGroup, "themables/BigGridButton.png", 300,100)
    -- changeGrid.anchorX = 0
    -- changeGrid.anchorY = 0
    -- changeGrid.x = 60
    -- changeGrid.y = 1000
    -- changeGrid:toFront()

    -- local changeTrophy = display.newImageRect(sceneGroup, "themables/TrophyRoom.png", 300, 100)
    -- changeTrophy.anchorX = 0
    -- changeTrophy.anchorY = 0
    -- changeTrophy.x = 390
    -- changeTrophy.y = 1000
    -- changeTrophy:toFront()

    -- changeGrid:addEventListener("tap", SwitchToBigGrid)
    -- changeTrophy:addEventListener("tap", SwitchToTrophy)

    header = display.newImageRect(sceneGroup, "themables/TurfWar.png",300, 100)
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

    -- local leaderboard = display.newImageRect(sceneGroup, "themables/LeaderboardIcon.png", 100, 100)
    -- leaderboard.anchorX = 0
    -- leaderboard.x = 580
    -- leaderboard.y = 100
    -- leaderboard:addEventListener("tap", GoToLeaderboardScene)
    -- leaderboard:toFront()

    if (debug) then
        debugText = display.newText(sceneGroup, "location data", display.contentCenterX, 1180, 600, 0, native.systemFont, 22)
        debugText:toFront()
    end
    --reorderUI() --not in create

    if (debug) then print("created TurfWar scene") end
end

function reorderUI()
    ctsGroup:toFront()
    header:toFront()
    zoom:toFront()
    --leaderboard:toFront()
    directionArrow:toFront()
end

function scene:show(event)
    if (debug) then print("showing TurfWar scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        firstRun = true
    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen 
        timer.performWithDelay(50, UpdateLocalOptimized, 1)
        --timer.performWithDelay(3000, UpdateTurfWarMap, -1)
        timerResultsScoreboard = timer.performWithDelay(2500, GetScoreboard, -1)
        if (debugGPS) then timer.performWithDelay(3000, testDrift, -1) end
        reorderUI()
        GetTeamAssignment()
    end
    if (debug) then print("showed TurfWar scene") end
end

function scene:hide(event)
    if (debug) then print("hiding TurfWar scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        timer.cancel(timerResults)
        timerResults = nil
        timer.cancel(timerResultsMap)
        timerResultsMap = nil
        timer.cancel(timerResultsScoreboard)
        timerResultsScoreboard = nil
    elseif (phase == "did") then
        -- Code here runs immediately after the scene goes entirely off screen
    end
end

function scene:destroy(event)
    if (debug) then print("destroying TurfWar scene") end

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


