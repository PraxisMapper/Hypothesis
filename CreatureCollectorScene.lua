 
-- the minimum stuff to get a scene with maptiles going. Copy and build upon it for new modes with maptiles.
local composer = require("composer")
local scene = composer.newScene()

local json = require("json")
require("UIParts")
require("database")
require("dataTracker") 
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
 
local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end
 
local deviceId = system.getInfo("deviceID")

defaultConfig ={
    monsterPerCell8 = 12,
    monsterCountToRespawn = 3,
    monsterDurationMin = 30,
    monsterDurationMax = 60,
    monsters = {
        -- These are CC-NC-BY, need to credit Pheonixsong at https://phoenixdex.alteredorigin.net
        { name ="Acafia", type1 ="Grass", type2 = "", imageName ="themables/CreatureImages/acafia.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Acceleret", type1 ="Normal", type2 = "Flying", imageName ="themables/CreatureImages/acceleret.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Aeolagio", type1 ="Water", type2 = "Poison", imageName ="themables/CreatureImages/aeolagio.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Bandibat", type1 ="Electric", type2 = "Dark", imageName ="themables/CreatureImages/bandibat.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Belamrine", type1 ="Bug", type2 = "Water", imageName ="themables/CreatureImages/belmarine.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Bojina", type1 ="Ghost", type2 = "", imageName ="themables/CreatureImages/bojina.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Caslot", type1 ="Dark", type2 = "Fairy", imageName ="themables/CreatureImages/caslot.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Cindigre", type1 ="Fire", type2 = "", imageName ="themables/CreatureImages/cindigre.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Curlsa", type1 ="Fairy", type2 = "", imageName ="themables/CreatureImages/curlsa.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Decicorn", type1 ="Poison", type2 = "", imageName ="themables/CreatureImages/decicorn.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Dauvespa", type1 ="Bug", type2 = "Ground", imageName ="themables/CreatureImages/dauvespa.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Drakella", type1 ="Water", type2 = "Grass", imageName ="themables/CreatureImages/drakella.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Eidograph", type1 ="Ghost", type2 = "Psychic", imageName ="themables/CreatureImages/eidograph.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Encanoto", type1 ="Psychic", type2 = "", imageName ="themables/CreatureImages/encanoto.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Faintrick", type1 ="Normal", type2 = "", imageName ="themables/CreatureImages/faintrick.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Galavena", type1 ="Rock", type2 = "Psychic", imageName ="themables/CreatureImages/galavena.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Vanitarch", type1 ="Bug", type2 = "Fairy", imageName ="themables/CreatureImages/vanitarch.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Grotuille", type1 ="Water", type2 = "Rock", imageName ="themables/CreatureImages/grotuille.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Gumbwaal", type1 ="Normal", type2 = "", imageName ="themables/CreatureImages/gumbwaal.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Mandragoon", type1 ="Grass", type2 = "Dragon", imageName ="themables/CreatureImages/mandragoon.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Ibazel", type1 ="Dark", type2 = "", imageName ="themables/CreatureImages/ibazel.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Makappa", type1 ="Ice", type2 = "Fire", imageName ="themables/CreatureImages/makappa.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Pyrobin", type1 ="Fire", type2 = "Fairy", imageName ="themables/CreatureImages/pyrobin.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Rocklantis", type1 ="Water", type2 = "Fighting", imageName ="themables/CreatureImages/rocklantis.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Strixlan", type1 ="Dark", type2 = "Flying", imageName ="themables/CreatureImages/strixlan.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Tinimer", type1 ="Bug", type2 = "", imageName ="themables/CreatureImages/tinimer.png", terrainSpawns ={}, areaSpawns = {}, },
        { name ="Vaquerado", type1 ="Bug", type2 = "Ground", imageName ="themables/CreatureImages/vaquerado.png", terrainSpawns ={}, areaSpawns = {}, },
    }
}

-- This chain of functions should create the Creaturecollector data on the server if its missing.
function ccSetupCheck()
    print("ccsetupcheck")
    network.request(serverURL .. "Data/Global/ccSetup" .. defaultQueryString, "GET", cc1Listener)
end

local uploadPicsLeft = 0
function cc1Listener(event)
    --Response meanings:
    --blank: server hasn't been setup. Claim the right to bootstrap up CC mode
    --a player ID: this player has claimed to be running setup, check their ID to see if its still reserved or if that attempt expired.
    --true: Server has been configured and is ready to play.
    print("cc1Listener")
    if (event.response == "true") then
        print("response true, bailing on setup.")
        --skip to normal logic? might need a flag to confirm ive done the setup check or bootstrap
        return
    elseif event.response == deviceId then
        --oh, we're the ones setting it up, continue on.
    else
        --this should be someone else'se deviceId, we have to wait for them.
        --exiting for now, TODO indicate to the player whats going on.
        print("other player mid-setup, bailing.")
        return
    end
    print("staring cc load")
    --Global entries can't expire, so i may have issues if these get set to pending and never changed or updating is cancelled.
    --Plan 2: put deviceID in ccSetup, and attach expiration to an entry on that player? If they're not configuring things, you are allowed to instead.
    network.request(serverURL .. "Data/Global/ccSetup/" .. deviceId .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Player/" .. deviceId .. "/ccSetup/pending/120" .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Global/ccConfigId/1" .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Global/ccPics/" .. deviceId .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Player/" .. deviceId .. "/ccPics/pending/60" .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Global/ccPicsId/1" .. defaultQueryString, "PUT", DefaultNetCallHandler)  

    print("post-claiming config")

    local headers = {}
    headers["Content-Type"] = "application/octet-stream"
    --queue all these calls up.
    for i,v in ipairs(defaultConfig.monsters) do
        --todo: add line here to copy file to temporary files.
        print("copying file")
        local filenameparts = Split(v.imageName, "/")
        print(dump(filenameparts))
        copyFile(v.imageName, system.ResourceDirectory, filenameparts[3], system.TemporaryDirectory, true )
        print("file copied")
        local params = {
            headers = headers,
            bodyType = "binary",
            body = {
                filename = filenameparts[3], --NOTE: Android won't read .png files from the ResourceDirectory, those need moved or renamed.
                baseDirectory = system.TemporaryDirectory
            }
        }
        --might have an issue here if I have slashes in the imageName value. Might need to escape that here. &#47 == / or %2f
        --print(v.imageName)
        --print(string.gsub(v.imageName, "\/", "-"))
        local url = serverURL .. "StyleData/Bitmap/" .. string.gsub(v.imageName, "\/", "-") .. defaultQueryString
        print(url)
        table.insert(networkQueue, { url = serverURL .. "StyleData/Bitmap/" .. filenameparts[3] .. defaultQueryString, verb = "PUT", handlerFunc = picUploadHandler, params = params})
        uploadPicsLeft = uploadPicsLeft + 1
        print("upload queued")
    end

    --wait for queue to empty, then continue.

end

function picUploadHandler(event)
    print("picUploadhandler")
    if (event.status ~= 200) then
        --requeue this call? Might need to be done on a specific status call.
        print("pic upload failed.")

        print(event.response)
    else
        print("pic uploaded")
        uploadPicsLeft = uploadPicsLeft - 1
        networkQueueBusy = false
        --todo: delete temporary file bitmap matching this call.
        if (uploadPicsLeft == 0) then
            --go on to the next step
            --NOTE: this might fail on the server since a null value would read the body, which is also null, and may not like that. Might need actual delete calls.
            network.request(serverURL .. "Data/Global/ccPics" .. defaultQueryString, "DELETE", DefaultNetCallHandler)
            network.request(serverURL .. "Data/Global/ccSpawnRuleUpload/" .. deviceId .. defaultQueryString, "PUT", DefaultNetCallHandler)
            network.request(serverURL .. "Data/Global/ccSpawnRuleId/1" .. defaultQueryString, "PUT", DefaultNetCallHandler)
            sendSpawnRules()
        end
    end
end

function sendSpawnRules()
    print("sendSpawnRules")
    --turn defaultConfig into a string, upload it
    local convertedDefaultConfig = json.encode(defaultConfig)
    --set this convertedDefaultConfig to the request's body.
    local params = {}
    params.body = convertedDefaultConfig
    table.insert(networkQueue, { url = serverURL .. "Data/Global/ccConfig" .. defaultQueryString, verb = "PUT", handlerFunc = spawnRuleUploadHandler, params = params})
end

function spawnRuleUploadHandler(event)
    print("spawnRulesHandler")
    networkQueueBusy = false
    print(event.status)
    print(event.response)
    if (event.status == 200) then
        --i think this means CreatureCollector mode is configured up.
        network.request(serverURL .. "Data/Global/ccSpawnRuleUpload" .. deviceId .. defaultQueryString, "DELETE", DefaultNetCallHandler)
        network.request(serverURL .. "Data/Global/ccSetup/true" .. defaultQueryString, "PUT", DefaultNetCallHandler)
        network.request(serverURL .. "Data/Player/" .. deviceId .. "/ccSetup/done/1" .. defaultQueryString, "PUT", DefaultNetCallHandler)
        network.request(serverURL .. "Data/Player/" .. deviceId .. "/ccPics/done/1" .. defaultQueryString, "PUT", DefaultNetCallHandler)
        print("all good")
    end
end



local gridzoom = 2 -- 1, 2, 3. 

local cellCollection = {} -- main background map tiles
local overlayCollection = {} -- any overlay tiles needed.

local touchDetector = {} -- Determines what cell10 was tapped on the screen.

local timerResults = nil
local firstRun = true
local mapTileUpdater = nil

local locationText = ""
local timeText = ""
local directionArrow = ""
local debugText = {}
local locationName = ""

local function testDrift()
    if (os.time() % 2 == 0) then
        currentPlusCode = shiftCell(currentPlusCode, 1, 9) -- move north
    else
        currentPlusCode = shiftCell(currentPlusCode, 1, 10) -- move west
    end
end

local function ToggleZoom()
    print("zoom tapped")
    gridzoom = gridzoom + 1
    if (gridzoom > 3) then gridzoom = 1 end
    timer.pause(timerResults)

    for i = 1, #cellCollection do cellCollection[i]:removeSelf() end
    for i = 1, #overlayCollection do overlayCollection[i]:removeSelf() end

    cellCollection = {}
    overlayCollection = {}
    makeGrid()

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
    -- gridzoom3 is 5x5 lowres tiles, 800 x 1000 total, each pixel is 1 Cell 11
    -- gridzoom2 is 3x3 highres tiles, 960 x 1200 total, each 2x2 pixels is 1 Cell 11
    -- gridzoom1 is 3x3 doubled highres tiles, 1960 x 2400 total, each 4x4 pixels is 1 cell 11.

    -- figure out how many pixels from the center of the item each tap is
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
    print("Detected cell tap: " .. newCell)
    tapData.text = "Cell Tapped: " .. newCell

    local pluscodenoplus = removePlus(newCell)
    local terrainInfo = LoadTerrainData(pluscodenoplus)

    -- 3 is name, 4 is area type, 6 is mapDataID (privacyID)
    if (terrainInfo[3] == "") then
        tappedAreaName = terrainInfo[4]
    else
        tappedAreaName = terrainInfo[3]
    end
    
    --tappedCell = newCell
    --tappedAreaScore = 0 --i don't save this locally, this requires a network call to get and update
    --tappedAreaMapDataId = terrainInfo[6]
    --composer.showOverlay("overlayMPAreaClaim", {isModal = true})
    
end

local function GoToSceneSelect()
    print("back to scene select")
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
    return true
end

local function UpdateLocalOptimized()
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

    if (timerResults ~= nil) then timer.pause(timerResults) end
    local innerForceRedraw = forceRedraw or firstRun or (currentPlusCode:sub(1,8) ~= previousPlusCode:sub(1,8))
    firstRun = false
    forceRedraw = false
    previousPlusCode = currentPlusCode

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
        local imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.CachesDirectory)
        if imageExists == true then
            cellCollection[square].fill = {0.1, 0.1} -- required to make Solar2d actually update the texture.
            local paint = {
                type = "image",
                filename = plusCodeNoPlus .. "-11.png",
                baseDir = system.CachesDirectory
            }
            cellCollection[square].fill = paint
        end

            --Update this loop to pull the overlay tiles if needed
            -- imageRequested = requestedMPMapTileCells[plusCodeNoPlus] -- read from DataTracker because we want to know if we can paint the cell or not.
            -- imageExists = doesFileExist(plusCodeNoPlus .. "-AC-11.png", system.TemporaryDirectory)
            -- if (imageRequested == nil) then 
            --     imageExists = doesFileExist(plusCodeNoPlus .. "-AC-11.png", system.TemporaryDirectory)
            -- end
 
            -- if (imageExists == false or imageExists == nil) then 
            --      GetTeamControlMapTile8(plusCodeNoPlus)
            -- else
            --     overlayCollection[square].fill = {0, 0} -- required to make Solar2d actually update the texture.
            --     local paint = {
            --         type = "image",
            --         filename = plusCodeNoPlus .. "-AC-11.png",
            --         baseDir = system.TemporaryDirectory
            --     }
            --     overlayCollection[square].fill = paint
            -- end
        end
    end

    if (timerResults ~= nil) then timer.resume(timerResults) end
    if (debugLocal) then print("grid done or skipped") end
    locationText.text = "Current location:" .. currentPlusCode
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

    locationText:toFront()
    timeText:toFront()
    directionArrow:toFront()
    locationName:toFront()

    if (debugLocal) then print("end updateLocalOptimized") end
end

local function UpdateMapTiles()
    --set this to run once a second or so.
    for square = 1, #cellCollection do
        -- check each spot based on current cell, modified by gridX and gridY
        local thisSquaresPluscode = currentPlusCode
        thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridX, 8)
        thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridY, 7)
        cellCollection[square].pluscode = thisSquaresPluscode
        local plusCodeNoPlus = removePlus(thisSquaresPluscode):sub(1, 8)
        GetMapData8(plusCodeNoPlus)
        checkTileGeneration(plusCodeNoPlus, "mapTiles")
    end -- for
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)
    composer.setVariable("myScore", "0")

    if (debug) then print("creating MPAreaControlScene2") end
    local sceneGroup = self.view

    touchDetector = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 720, 1280)
    touchDetector:addEventListener("tap", DetectLocationClick)
    touchDetector.fill = {0, 0.1}
    touchDetector:toBack()

    contrastSquare = display.newRect(sceneGroup, display.contentCenterX, 230, 400, 100)
    contrastSquare:setFillColor(.8, .8, .8, .7)

    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 240, native.systemFont, 20)
    
    locationText:setFillColor(0, 0, 0);
    timeText:setFillColor(0, 0, 0);
    locationName:setFillColor(0, 0, 0);

    CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
    CreateRectangleGrid(3, 320, 400, sceneGroup, overlayCollection) -- rectangular Cell11 grid with overlay

    directionArrow = display.newImageRect(sceneGroup, "themables/arrow1.png", 16, 20)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY
    directionArrow.anchorX = .5
    directionArrow.anchorY = .5
    directionArrow:toFront()

    local header = display.newImageRect(sceneGroup, "themables/creatureCollector.png",300, 100)
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
    if (debug) then print("created baseline scene") end

    ccSetupCheck()
end

function scene:show(event)
    if (debug) then print("showing baseline scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        firstRun = true
    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen 
        timer.performWithDelay(50, UpdateLocalOptimized, 1)
        if (debugGPS) then timer.performWithDelay(3000, testDrift, -1) end
        mapTileUpdater = timer.performWithDelay(2000, UpdateMapTiles, -1)
    end
end

function scene:hide(event)
    if (debug) then print("hiding baseline scene") end
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
    if (debug) then print("destroying baseline scene") end

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