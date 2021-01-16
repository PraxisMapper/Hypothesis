--This is the scene that appears after the splash screen, and sets up everything the game needs to run correcly
--overlayDL is the pop-up for downloading new data.

--a lot of functions are localized to this scene, rather than being shared.
local composer = require( "composer" )
local scene = composer.newScene()

require("database")
require("localNetwork")

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
 end

 function Get8CellDataLoading(pluscode8)
    if networkReqPending == true then return end
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/LearnCell8/" .. pluscode8) end
    --network.request(serverURL .. "MapData/LearnCell8/" .. pluscode8, "GET", plusCode8ListenerLoading)
    LoadMapData()
end

function plusCode8ListenerLoading(event)
    if (debugNetwork) then print("plus code 8 event response status: " .. event.status) end --these are fairly large, 10k entries isnt weird.
    if (event.status ~= 200) then 
        LoadMapData()
        return --dont' save invalid results on an error.
    end 

    --tell the user we're working
    --had to move this earlier for it to appear.
    --ShowLoadingPopup()

    --This one splits each 10cell via newline.
    local resultsTable = Split(event.response, "\r\n") --windows newlines
    print(#resultsTable)
    --Format:
    --line1: the 6cell requested
    --remaining lines: the last 4 digits for a 10cell=name|type|mapDataID
    --EX: 2248=Local Park|park|12345
  
    local insertString = ""
    local insertCount = 0

    db:exec("BEGIN TRANSACTION") --transactions for multiple inserts are a huge performance boost.
    local plusCode6 = resultsTable[1] 
    for i = 2, #resultsTable do
        if (resultsTable[i] ~= nil and resultsTable[i] ~= "") then 
            local data = Split(resultsTable[i], "|") --3 data parts in order
            data[2] = string.gsub(data[2], "'", "''")--escape data[2] to allow ' in name of places.
            insertString = "INSERT INTO terrainData (plusCode, name, areatype) VALUES ('" .. resultsTable[1] .. data[1] .. "', '" .. data[2] .. "', '" .. data[3] .. "');" --insertString .. 
            db:exec(insertString)
        end
    end
    local e2 = db:exec("END TRANSACTION")
    if(debugNetwork) then print("table done") end

    --save these results to the DB.
    --TODO: fix columsn to indicate these are 6 cells that have been downloaded, not 8 cells.
    local updateCmd = "INSERT INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode6 .. "', " .. os.time() .. ")"
    Exec(updateCmd)
    LoadMapData()
end

function LoadMapData()
    statusText.text = "Downloading map data"
    print("getting map info")
        if (imagecount == 0) then
            timer.performWithDelay(50, startGame, 1)   
        end
end

function Get10CellImage11Loading(plusCode)
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.DocumentsDirectory}
    network.request(serverURL .. "MapData/DrawCell10Highres/" .. plusCode, "GET", imageListenerLoading, params)
    imagecount = imagecount + 1
end

function imageListenerLoading(event)
    imagecount = imagecount - 1;
    if (imagecount == 0) then
        startGame()
    end
end

function Get8CellImage11Loading(plusCode8)
    local params = {}
    params.response  = {filename = plusCode8 .. "-11.png", baseDirectory = system.DocumentsDirectory}
    network.request(serverURL .. "MapData/DrawCell8Highres/" .. plusCode8, "GET", imageListenerLoading, params)
    imagecount = imagecount + 1
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
    local pluscode = tryMyEncode(eventL.latitude, eventL.longitude, 10); --only goes to 10 right now.
    if (debugGPS) then print ("Plus Code: " .. pluscode) end
    currentPlusCode = pluscode

    --Debug/testing override location
    --currentPlusCode = "9C6RVJ85+J8" --random UK location, should have water to the north, and a park north of that.
    
       --More complicated, problematic entries: (Pending possible fix for loading data missing from a file)
       --currentPlusCode ="8FW4V75V+8R" --Eiffel Tower. ~60,000 entries.
       --currentPlusCode = "376QRVF4+MP" --Antartic SPOI
       --currentPlusCode = "85872779+F4" --Hoover Dam Lookout
       --currentPlusCode = "85PFF56C+5P" --Old Faithful 



    --local plusCode6 = currentPlusCode:sub(0,6)
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

        local currentDbVersion = 10;

        local tablesetup =
        [[CREATE TABLE IF NOT EXISTS plusCodesVisited(id INTEGER PRIMARY KEY, pluscode, lat, long, firstVisitedOn, lastVisitedOn, totalVisits, eightCode);
        CREATE TABLE IF NOT EXISTS acheivements(id INTEGER PRIMARY KEY, name, acheived, acheivedOn);
        CREATE TABLE IF NOT EXISTS playerData(id INTEGER PRIMARY KEY, distanceWalked REAL, totalPoints, totalCellVisits, totalSecondsPlayed, maximumSpeed, totalSpeed, maxAltitude, minAltitude);
        CREATE TABLE IF NOT EXISTS systemData(id INTEGER PRIMARY KEY, dbVersionID, isGoodPerson, coffeesBought, deviceID, factionID, serverAddress);
        CREATE TABLE IF NOT EXISTS weeklyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS dailyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS trophysBought(id INTEGER PRIMARY KEY, itemCode, boughtOn);
        CREATE TABLE IF NOT EXISTS terrainData (id INTEGER PRIMARY KEY, pluscode UNIQUE, name, areatype, lastUpdated, MapDataId);
        CREATE INDEX IF NOT EXISTS terrainIndex on terrainData(pluscode);
        CREATE TABLE IF NOT EXISTS dataDownloaded(id INTEGER PRIMARY KEY, pluscode8, downloadedOn);
        CREATE TABLE IF NOT EXISTS areasOwned(id INTEGER PRIMARY KEY, mapDataId, name, points);
        CREATE INDEX IF NOT EXISTS indexPCodes on plusCodesVisited(pluscode);
        CREATE INDEX IF NOT EXISTS indexEightCodes on plusCodesVisited(eightCode);
        CREATE INDEX IF NOT EXISTS indexOwnedMapIds on areasOwned(mapDataId);
        INSERT OR IGNORE INTO systemData(id, dbVersionID, isGoodPerson, coffeesBought, deviceID, factionID) values (1, ]] .. currentDbVersion .. ", 0, 0, '" .. system.getInfo("deviceID") .. [[', 1) ;
        INSERT OR IGNORE INTO playerData(id, distanceWalked, totalPoints, totalCellVisits, totalSecondsPlayed, maximumSpeed, totalSpeed, maxAltitude, minAltitude) values (1, 0.0, 0, 0, 0, 0.0, 0.0, 0, 20000);
        INSERT OR IGNORE INTO trophysBought(id, itemCode, boughtOn) VALUES (1, 0, 0);
        ]]
        
        print("tablesetup exists")
        statusText.text = "Database Opened2" .. sqlite3.version() --3.19 on android and simulator.
        if (debug) then 
            print("SQLite version " .. sqlite3.version())
        end
        local setupResults = Exec(tablesetup)
        print("setup done" .. setupResults)
        statusText.text = "setup done" .. setupResults
        if (setupResults > 0) then
            print(db:errmsg())
            statusText = db:errmsg()
        end
        
        statusText.text = "Database Exists : " .. setupResults
        if (setupResults ~= 0) then return end
        statusText.text = "Database Exists!"

        --upgrading database now, clearing data on android apparently doesn't reset table structure.
        upgradeDatabaseVersion(currentDbVersion) --TODO: make this read from systemData table?
        ResetDailyWeekly()

        statusText.text = "Database work done!"
        statusText.text = "Uploading current scores..."

        if (pcall(UploadData)) then
            --no errors
            statusText.text = "Scores Sent"
        else
            statusText.text = "Scores Not Sent"
        end

        statusText.text = "Checking area data"
        LoadMapData()
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
        Runtime:removeEventListener("location", loadingGpsListener)
        Runtime:addEventListener("location", gpsListener)
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