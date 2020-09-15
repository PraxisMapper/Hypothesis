local composer = require( "composer" )
 
local scene = composer.newScene()

require("database")
require("localNetwork")
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
 local statusText = "" --displayText object for info

 local function startGame()
    composer.gotoScene("10GridScene")
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
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        --Do some database stuff, display progress on screen
        print("loading scene on screen")

        statusText.text = "Database Check"
        startDatabase()
        statusText.text = "Database Opened"
        print("database started")

        local tablesetup =
        [[CREATE TABLE IF NOT EXISTS plusCodesVisited(id INTEGER PRIMARY KEY, pluscode, lat, long, firstVisitedOn, lastVisitedOn, totalVisits, eightCode);
        CREATE TABLE IF NOT EXISTS acheivements(id INTEGER PRIMARY KEY, name, acheived, acheivedOn);
        CREATE TABLE IF NOT EXISTS playerData(id INTEGER PRIMARY KEY, distanceWalked REAL, totalPoints, totalCellVisits, totalSecondsPlayed, maximumSpeed, totalSpeed, maxAltitude, minAltitude);
        CREATE TABLE IF NOT EXISTS systemData(id INTEGER PRIMARY KEY, dbVersionID, isGoodPerson, coffeesBought, deviceID);
        CREATE TABLE IF NOT EXISTS weeklyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS dailyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS trophysBought(id INTEGER PRIMARY KEY, itemCode, boughtOn);
        CREATE INDEX IF NOT EXISTS indexPCodes on plusCodesVisited(pluscode);
        CREATE INDEX IF NOT EXISTS indexEightCodes on plusCodesVisited(eightCode);
        INSERT OR IGNORE INTO systemData(id, dbVersionID, isGoodPerson, coffeesBought, deviceID) values (1, ]] .. 5 .. ", 0, 0, '" .. system.getInfo("deviceID") .. [[') ;
        INSERT OR IGNORE INTO playerData(id, distanceWalked, totalPoints, totalCellVisits, totalSecondsPlayed, maximumSpeed, totalSpeed, maxAltitude, minAltitude) values (1, 0.0, 0, 0, 0, 0.0, 0.0, 0, 20000);
        INSERT OR IGNORE INTO trophysBought(id, itemCode, boughtOn) VALUES (1, 0, 0);
        CREATE TABLE IF NOT EXISTS terrainData (id INTEGER PRIMARY KEY, pluscode UNIQUE, name, areatype, lastUpdated);
        CREATE INDEX IF NOT EXISTS terrainIndex on terrainData(pluscode);
        CREATE TABLE IF NOT EXISTS dataDownloaded(id INTEGER PRIMARY KEY, pluscode8, downloadedOn);
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
        upgradeDatabaseVersion(7) --TODO: make this read form systemData table.
        ResetDailyWeekly()

        statusText.text = "Database work done!"
        statusText.text = "Uploading current scores..."

        if (pcall(UploadData)) then
            --no errors
            statusText.text = "Scores Sent"
        else
            statusText.text = "Scores Not Sent"
        end

        

        print("loading scene done")
        statusText.text = "Opening Game..."
        timer.performWithDelay(50, startGame, 1)   
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
        Runtime:addEventListener("location", gpsListener) 
        print("loadingScene hidden, GPS on.")
 
    end
end
 
 
-- destroy()
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