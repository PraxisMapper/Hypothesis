--This is the scene that appears after the splash screen, and sets up everything the game needs to run correcly

--a lot of functions are localized to this scene, rather than being shared.
local composer = require( "composer" )
local scene = composer.newScene()

require("database")
require("dataTracker")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
 local statusText = "" --displayText object for info
 imagecount = 0; --pending responses on map tiles.

 local lat = 0
 local lon = 0

 local function startGame()
    statusText.text = "Opening Game..."
    composer.gotoScene("SceneSelect")
    --    composer.gotoScene("uploadTest")
 end

 function GetCurrentTiles()
    statusText.text = "Grabbing nearby map tiles and terrain info..."
    for x = -2, 2 do
        for y = -2, 2 do
            local thisPlusCode = shiftCell(currentPlusCode, x, 8)
            thisPlusCode = shiftCell(thisPlusCode, y, 7)
            thisPlusCode = thisPlusCode:sub(1,8)
            if doesFileExist(thisPlusCode .. "-11.png", system.CachesDirectory) == false then
                TrackerGetCell8Image11(thisPlusCode)
            end
            if not DownloadedCell8(thisPlusCode) then
                GetCell8TerrainData(thisPlusCode)
            end
        end
    end

    timer.performWithDelay(50, checkWait, 1)
 end

 function checkWait()
    statusText.text = "Downloading tiles and terrain info: " .. #networkQueue
    if (#networkQueue > 0) then
        timer.performWithDelay(50, checkWait, 1)
    else
        startGame()
    end
 end

 function loadingGpsListener(event)
    local eventL = event

    if (debugGPS) then
        print("got GPS event")
        if (eventL.errorCode ~= nil) then
            print("GPS Error " .. eventL.errorCode)
            return
        end

        print("Coords " .. eventL.latitude .. " " ..eventL.longitude)
    end

    lat = eventL.latitude
    lon = eventL.longitude
    local pluscode = encodeLatLon(eventL.latitude, eventL.longitude, 10); --only goes to 10 right now.
    if (debugGPS) then print ("Plus Code: " .. pluscode) end
    currentPlusCode = pluscode

    --Debug/testing override location
    
       --More complicated, problematic entries: (Pending possible fix for loading data missing from a file)
       --currentPlusCode ="8FW4V75V+8R" --Eiffel Tower. ~60,000 entries.
       --currentPlusCode = "376QRVF4+MP" --Antartic SPOI
       --currentPlusCode = "85872779+F4" --Hoover Dam Lookout
       --currentPlusCode = "85PFF56C+5P" --Old Faithful 
       -- currentPlusCode = "87G8Q2GH+7H" --Central park.
end

--These 2 are mostly duplicates of the ones in dataTracker, but I want to stop the loading process until I get the server bounds.
function GetServerBoundsStartup()
    local url = serverURL .. "Data/ServerBounds" .. defaultQueryString
    network.request(url, "GET", GetServerBoundsListenerStartup) 
    netTransfer()
end

function GetServerBoundsListenerStartup(event)
    if (event.status == 200) then
        local boundValues = Split(event.response, "|") --in clockwise order, S/W/N/E
        serverBounds["south"] = tonumber(boundValues[1])
        serverBounds["west"] = tonumber(boundValues[2])
        serverBounds["north"] = tonumber(boundValues[3])
        serverBounds["east"] = tonumber(boundValues[4])
        netUp()
        
        GetCurrentTiles()
    else
        statusText.text = "Failed to get server bounds, retrying....."
        GetServerBoundsStartup()
    end
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    print("creating loading scene")
    -- Code here runs when the scene is first created but has not yet appeared on screen
    --Draw a background image, fullscreen 720x1280
    --will draw text over that.

    local loadingBg = display.newImageRect(sceneGroup, "themables/LoadingScreen.png", 720, 1280)
    loadingBg.anchorX = 0
    loadingBg.anchorY = 0

    statusText = display.newText(sceneGroup, "Loading....", display.contentCenterX, 260, native.systemFont, 30)
    statusText:setFillColor(.2, .2, .2)
    print("loading scene created")
end
 
 
-- show()
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        Runtime:addEventListener("location", loadingGpsListener)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        --Do some database stuff, display progress on screen
        print("loading scene on screen")

        statusText.text = "Database Check"
        startDatabase()
        statusText.text = "Database Opened"
        print("database started")

        local currentDbVersion = 1;

        local tablesetup =
        [[CREATE TABLE IF NOT EXISTS plusCodesVisited(id INTEGER PRIMARY KEY, pluscode, lat, long, firstVisitedOn, nextScoreTime, totalVisits, eightCode);
        CREATE TABLE IF NOT EXISTS playerData(id INTEGER PRIMARY KEY, factionID, totalPoints);
        CREATE TABLE IF NOT EXISTS systemData(id INTEGER PRIMARY KEY, dbVersionID, serverAddress);
        CREATE TABLE IF NOT EXISTS weeklyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS dailyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS terrainData (id INTEGER PRIMARY KEY, pluscode UNIQUE, name, areatype, lastUpdated, MapDataId);
        CREATE TABLE IF NOT EXISTS bounds(id INTEGER PRIMARY KEY, south, west, north, east);
        CREATE TABLE IF NOT EXISTS dataDownloaded(id INTEGER PRIMARY KEY, pluscode8, downloadedOn);
        CREATE TABLE IF NOT EXISTS areasOwned(id INTEGER PRIMARY KEY, mapDataId, name, points);
        CREATE TABLE IF NOT EXISTS idleStats(id INTEGER PRIMARY KEY, lastAddTime, allPerSec, parkPerSec, naturePerSec, trailPerSec, touristPerSec, graveyardPerSec, allTotal, parkTotal, natureTotal, trailTotal, touristTotal, graveyardTotal, wins);
        CREATE TABLE IF NOT EXISTS tileGenerationData (id INTEGER PRIMARY KEY, plusCode, styleSet, generationId);
        CREATE TABLE IF NOT EXISTS geocacheHints(id INTERGER PRIMARY KEY, plusCode8, hintsLeft, secretsLeft);
        CREATE TABLE IF NOT EXISTS creaturesCaught(id INTERGER PRIMARY KEY, name, count);
        CREATE INDEX IF NOT EXISTS indexPCodes on plusCodesVisited(pluscode);
        CREATE INDEX IF NOT EXISTS indexEightCodes on plusCodesVisited(eightCode);
        CREATE INDEX IF NOT EXISTS indexOwnedMapIds on areasOwned(mapDataId);
        CREATE INDEX IF NOT EXISTS terrainIndex on terrainData(pluscode);
        CREATE INDEX IF NOT EXISTS generationIndex on tileGenerationData(pluscode);
        CREATE INDEX IF NOT EXISTS hintIndex on geocacheHints(plusCode8);
        CREATE INDEX IF NOT EXISTS creatureNameIndex on creaturesCaught(name);
        INSERT OR IGNORE INTO systemData(id, dbVersionID, serverAddress) values (1, ]] .. currentDbVersion .. [[, 'https://oh.praxismapper.org:5001/');
        INSERT OR IGNORE INTO playerData(id, factionID, totalPoints) values (1, 0, 0);
        INSERT OR IGNORE INTO idleStats(id, lastAddTime, allPerSec, parkPerSec, naturePerSec, trailPerSec, graveyardPerSec, touristPerSec, allTotal, parkTotal, natureTotal, trailTotal, graveyardTotal, touristTotal, wins) values (1, ]] .. os.time() .. [[, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        ]]
        
        statusText.text = "Database Opened "  .. sqlite3.version() --3.19 on android and simulator.
        if (debug) then 
            print("SQLite version " .. sqlite3.version())
        end
        local setupResults = Exec(tablesetup)
        if (debug) then print("setup done " .. setupResults) end
        statusText.text = "setup done " .. setupResults
        if (setupResults > 0) then
            print(db:errmsg())
            statusText = db:errmsg()
        end
        
        statusText.text = "Database Exists : " .. setupResults
        if (setupResults ~= 0) then return end
        statusText.text = "Database Exists!"

        --upgrading database now, clearing data on android apparently doesn't reset table structure.
        upgradeDatabaseVersion(currentDbVersion) 
        statusText.text = "Database work done!"

        serverURL = GetServerAddress()
        print(serverURL)

        --Debug setup
        --if (debug) then
            -- serverURL = "http://localhost/praxismapper/"
            --serverURL = "http://localhost:5000/"
            --serverURL = "http://192.168.50.247/praxismapper/"
              --serverURL = "https://oh.praxismapper.org:5001/"
            --serverURL = "https://us.praxismapper.org/praxismapper/"
        --end

        statusText.text = "Getting server boundaries..."
        GetServerBoundsStartup() --Startup process continues in the event handler for this.
    end
end
 
-- hide()
function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        print("loadingScene hiding")
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        Runtime:removeEventListener("location", loadingGpsListener) --the local one
        Runtime:addEventListener("location", gpsListener) --the one in main.lua
        print("loadingScene hidden, GPS on.")
    end
end
  
function scene:destroy( event )
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
end
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene