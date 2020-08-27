local composer = require("composer")
local scene = composer.newScene()

require("UIParts")
require("database")
require("localNetwork")

if (debug) then print("10GridScene loading") end
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

-- TODO
-- additional colors, to indicate when a cell has a bonus waiting to be collected. (colors here are none/daily/weekly. FirstTime is on the other grid now)
-- add a bounce-and-fall popup for when you gain score, add a sound effect to that too?

local cellCollection = {}
-- color codes
local unvisitedCell = {.3, .3, .3, 1}
local visitedCell = {.1, .4, .4, 1}
local waterCell = {0, 0, .7, 1}
local parkCell = {0, .7, 0, 1}
-- TODO other colors for other cell types.

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
    if (os.time() %2 == 0 ) then
        currentPlusCode = shiftCellV3(currentPlusCode, 1, 9) --move north
    else
        currentPlusCode = shiftCellV3(currentPlusCode, 1, 10) --move west
    end
end

local function UpdateLocal()
    if (debugLocal) then print("start UpdateLocal") end
    if (debugLocal) then print(currentPlusCode) end

    -- native.showAlert("", "Updating local")
    if (currentPlusCode == "") then
        if timerResults == nil then
            timerResults = timer.performWithDelay(500, UpdateLocal, -1)
        end
        if (debugLocal) then print("skipping, no location.") end
        return
    end

    if (debug) then debugText.text = dump(lastLocationEvent) end

    if (currentPlusCode ~= previousPlusCode or firstRun) then
        firstRun = false
        previousPlusCode = currentPlusCode
        for square = 1, #cellCollection do -- this is slightly faster than ipairs
            -- check each spot based on current cell, modified by gridX and gridY
            local thisSquaresPluscode = currentPlusCode
            thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, cellCollection[square].gridX, 10)
            thisSquaresPluscode = shiftCellV3(thisSquaresPluscode, cellCollection[square].gridY, 9)
            cellCollection[square].pluscode = thisSquaresPluscode

            --apply type now if we found it.
            --print("loading terrain info for " .. thisSquaresPluscode:sub(1,8) .. thisSquaresPluscode:sub(10,11))
            local terrainInfo = LoadTerrainData(thisSquaresPluscode:sub(1,8) .. thisSquaresPluscode:sub(10,11)) --is a whole row from the DB.
            --print("terrain info pulled: " .. #terrainInfo)
            --if (#terrainInfo > 0) then print(dump(terrainInfo)) end

            if (#terrainInfo == 0) then
                --we don't have this cell, load it.
                GetCellData(thisSquaresPluscode) --will show up next pass
            else if (terrainInfo[4] ~= "") then --4 is areaType
                --apply info
                --print("cell with data found!")
                cellCollection[square].name = terrainInfo[3] 
                cellCollection[square].type = terrainInfo[4]
            else
                --apply generic colors.
            end
        end

            --cellCollection[square].type = ""
            -- check if we have this square's data, if we do, show it. if not, get it.
            -- TODO: apply this logic to 8cell page too?
            -- or make another server endpoint to see if anything fully covers an 8code by checking .Contains on the corners?

            -- if locationList[thisSquaresPluscode] ~= nil then
            --     local values = locationList[thisSquaresPluscode] -- will be a table with "name|type", which might both be empty.
            --     --if (string.len(values) == 10) then
            --     if (values[2] == "") then
            --         -- this is not a special area of interest.
            --     else
            --         print("cell with data found!")
            --         cellCollection[square].name = values[1] --locationList[thisSquaresPluscode][1] or .name?
            --         cellCollection[square].type = values[2] --locationList[thisSquaresPluscode][2] or .type?
            --     end
            -- else
            --     print("no data for cell")
            --     GetCellData(thisSquaresPluscode) -- this will update on screen next refresh (plus code change)
            -- end

            if (currentPlusCode == thisSquaresPluscode) then
                -- draw this place's name on screen.
                --print("drawing this name on screen")
                locationName.text = cellCollection[square].name
            end

            --cellCollection is a table of imageRects with a couple extra properties assigned.
            -- now handle assigning colors
            --print("pre-colors")
            --print(#locationList[thisSquaresPluscode])
            if (cellCollection[square].type == "") then
                --print("applying default colors")
                if VisitedCell(thisSquaresPluscode) then
                    cellCollection[square].fill = visitedCell
                else
                    cellCollection[square].fill = unvisitedCell
                end
            else
                --print("applying terrain colors")
                if (cellCollection[square].type == "water") then
                    cellCollection[square].fill = waterCell
                else
                    if (cellCollection[square].type == "park") then
                        cellCollection[square].fill = parkCell
                    end
                end
            end
        end 
    end

    -- native.showAlert("", "past cell checks")

    if (debugGPS) then print("grid done or skipped") end
    if (debugGPS) then print(locationText.text) end
    locationText.text = "Current location:" .. currentPlusCode
    countText.text = "Total Explored Cells: " .. TotalExploredCells()
    pointText.text = "Score: " .. Score()
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading
    locationName.text = ""
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
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)

    if (debug) then print("creating 10GridScene") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    locationText = display.newText(sceneGroup,
                                   "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    countText = display.newText(sceneGroup, "Total Cells Explored: ?", display.contentCenterX, 240, native.systemFont, 20)
    pointText = display.newText(sceneGroup, "Score: ?", display.contentCenterX, 260, native.systemFont, 20)
    scoreLog = display.newText(sceneGroup, "", display.contentCenterX, 1250, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 280, native.systemFont, 20)

    CreateSquareGrid(23, 25, sceneGroup, cellCollection)

    directionArrow = display.newImageRect(sceneGroup, "arrow1.png", 25, 25)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY

    local changeGrid = display.newImageRect(sceneGroup, "BigGridButton.png", 300, 100)
    changeGrid.anchorX = 0
    changeGrid.anchorY = 0
    changeGrid.x = 60
    changeGrid.y = 1000

    local changeTrophy = display.newImageRect(sceneGroup, "TrophyRoom.png", 300, 100)
    changeTrophy.anchorX = 0
    changeTrophy.anchorY = 0
    changeTrophy.x = 390
    changeTrophy.y = 1000

    changeGrid:addEventListener("tap", SwitchToBigGrid)
    changeTrophy:addEventListener("tap", SwitchToTrophy)

    local header = display.newImageRect(sceneGroup, "SmallGridButton.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 100

    local store = display.newImageRect(sceneGroup, "StoreIcon.png", 100, 100)
    store.anchorX = 0
    -- store.anchorY = 0
    store.x = 50
    store.y = 100
    store:addEventListener("tap", GoToStoreScene)

    local leaderboard = display.newImageRect(sceneGroup, "LeaderboardIcon.png", 100, 100)
    leaderboard.anchorX = 0
    -- leaderboard.anchorY = 0
    leaderboard.x = 580
    leaderboard.y = 100
    leaderboard:addEventListener("tap", GoToLeaderboardScene)

    if (debug) then
        print("Creating debugText")
        debugText = display.newText(sceneGroup, "location data", display.contentCenterX, 1180, 600, 0, native.systemFont, 22)
        print("Created debugText")

        header:addEventListener("tap", SwitchToDebugScene)
    end

    if (debug) then print("created 10GridScene") end

end

-- show()
function scene:show(event)
    if (debug) then print("showing 10GridScene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        firstRun = true

    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen 
        -- native.showAlert("", "creating update timer")
        timer.performWithDelay(50, UpdateLocal, 1)

        if (debugGPS) then
            timer.performWithDelay(3000, testDrift, -1)
        end
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
