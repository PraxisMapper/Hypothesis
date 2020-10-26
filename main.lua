-----------------------------------------------------------------------------------------
-- main.lua
-----------------------------------------------------------------------------------------
--this function sets up a few global variables and baseline config.
--remember, lua requires code to be in order to reference (cant call a function that's lower in the file than the current one)

--TODO:
--implement store stuff
--allow user to set display name/nickname (or use Google Games signin? That might be faster/easier/another keyword)
--move some stuff to database for efficiency purposes?
----EX: put colors in DB query so that i can just look up which color to draw a cell instead of checking after reading cellinfo?
----EX: maybe move score values to DB? could theoretically make a more complicated query that automatically updates scores that way
----terrain types should probably come over as numbers to save a little data usage.
--Do i want to protect the DB at all to stop players from directly editing data?
--make a screen that draws the whole explored map you have, scaled to screen? requires drawing directly to a bitmap
--change colors to be more visible outdoors (I have a lot of dark colors, probably want light colors instead)
system.setIdleTimer(false) --disables screen auto-off.

require("store")
require("helpers")
require("gameLogic")
require("database")

print("starting network")
require("localNetwork")
networkResults = "down" --indicates if i am getting network data or not.

forceRedraw = false --used to tell the screen to redraw even if we havent moved.

debug = true --set false for release builds. Set true for lots of console info being dumped. Must be global to apply to all files.
debugShift = false --display math for shifting PlusCodes
debugGPS = true --display data for the GPS event and timer loop and auto-move
debugDB = false
debugLocal = false
debugNetwork = true
--uncomment when testing to clear local data.
--ResetDatabase()
startDatabase()

require("plusCodes")
currentPlusCode = "" -- where the user is sitting now
lastPlusCode = "" --the previously received value for the location event, may be the same as currentPlusCode
previousPlusCode = ""  --the previous DIFFERENT pluscode value we visited.
currentHeading = 0
lastTime = os.time()
lastScoreLog = ""
lastHeadingTime = 0

lastLocationEvent = ""

--making the network indicator persist through all scenes
networkDown = display.newImageRect("themables/networkDown.png", 25, 25)
networkDown.x = 0
networkDown.y = 0
networkDown.anchorX = 0
networkDown.anchorY = 0

networkUp = display.newImageRect("themables/networkUp.png", 25, 25)
networkUp.x = 0
networkUp.y = 0
networkUp.anchorX = 0
networkUp.anchorY = 0
networkUp.isVisible = false

networkTx = display.newImageRect("themables/networkTransfer.png", 25, 25)
networkTx.x = 0
networkTx.y = 0
networkTx.anchorX = 0
networkTx.anchorY = 0
networkTx.isVisible = false


print("shifting to loading scene")
local composer = require("composer")
composer.gotoScene("loadingScene")

function gpsListener(event)

    local eventL = event --assign it locally just in case somethings messing with the parent event object

    if (debugGPS) then
        print("got GPS event")
        if (eventL.errorCode ~= nil) then
            print("GPS Error " .. eventL.errorCode)
            return
        end

        print("Coords " .. eventL.latitude .. " " ..eventL.longitude)
    end

    if (eventL.direction ~= 0) then
         currentHeading = eventL.direction
     end

    local pluscode = tryMyEncode(eventL.latitude, eventL.longitude, 10); --only goes to 10 right now.
    if (debugGPS) then print ("Plus Code: " .. pluscode) end
    currentPlusCode = pluscode

    --Debug/testing override location
    --currentPlusCode = "9C6RVJ85+J8" --random UK location, should have water to the north, and a park north of that.
    
    currentPlusCode = "86HWHHHH+22"
    
       --More complicated, problematic entries: (Pending possible fix for loading data missing from a file)
       --currentPlusCode ="8FW4V75V+8R" --Eiffel Tower. ~60,000 entries.
       --currentPlusCode = "376QRVF4+MP" --Antartic SPOI
       --currentPlusCode = "85872779+F4" --Hoover Dam Lookout
       --currentPlusCode = "85PFF56C+5P" --Old Faithful

    local plusCode6 = currentPlusCode:sub(0,6)

    --checking here. Checking for this after GrantPoints updates the visited list before this, would never load data.
    print("checking for terrain data")
    local hasData = Downloaded6Cell(plusCode6)
    print(hasData)
    if (hasData == false) then
        --Get6CellData(event.latitude, event.longitude)
        Get6CellData(plusCode6)
    end

    --look for image data. probably a temporary location for this logic.
    --Should definitely check at the loading screen for this.
    local imageExists = doesFileExist(plusCode6 .. "-11.png", system.DocumentsDirectory)
    if (not imageExists) then
        --pull image from server
        Get6CellImage11(plusCode6)
    end

    --These seem more reasonable to use game-wise. much faster and smaller
    local plusCode8 = currentPlusCode:sub(0,8)
    imageExists = doesFileExist(plusCode8 .. "-11.png", system.DocumentsDirectory)
    if (not imageExists) then
        --pull image from server
        Get8CellImage11(plusCode8)
    end

    if (lastPlusCode ~= currentPlusCode) then
        --update score stuff, we moved a cell.  Other stuff needs to process as usual.
        if(debugGPS) then print("calculating score") end
        lastScoreLog = "Earned " .. grantPoints(currentPlusCode) .. " points from cell " .. currentPlusCode
        lastPlusCode = currentPlusCode
    end
    --Update data that should be handled every event.

    --reducing this to one query
    if (lastLocationEvent == "" ) then
        --don't do any calculations yet, this is the first location event.
    else
        local timeDiff = 0
        if (os.time() ~= lastTime) then
            timeDiff = os.time() - lastTime
        end


        local currentQuery = Query("SELECT maxAltitude, maximumSpeed, minAltitude from playerData")[1]
        local cMaxalt = currentQuery[1]
        local cMaxSpeed = currentQuery[2]
        local cMinalt = currentQuery[3]
        if (eventL.altitude > cMaxalt) then
            cMaxalt = eventL.altitude
        end

        if (eventL.altitude < cMinalt) then
            cMinalt = eventL.altitude
        end

        if (eventL.speed > cMaxSpeed) then
            cMaxSpeed = eventL.speed
        end

        local distance = CalcDistance(eventL, lastLocationEvent)

        local cmd = "UPDATE playerData SET totalSecondsPlayed = totalSecondsPlayed + " .. timeDiff .. ", totalSpeed = totalSpeed + " .. eventL.speed
        cmd = cmd ..  ", maxAltitude = " .. cMaxalt .. ", distanceWalked = distanceWalked + " .. distance .. ", maximumSpeed = " .. cMaxSpeed .. ", minAltitude = " .. cMinalt
        Exec(cmd)
    end

    lastTime = os.time() 
    if(debugGPS) then print("Finished location event") end

    lastLocationEvent = eventL
end


timer.performWithDelay(60000 * 5, ResetDailyWeekly, -1)

function netUp()
    print("network is up")
    networkResults = "up"
    networkUp.isVisible = true
    networkDown.isVisible = false
    networkTx.isVisible = false
end

function netDown()
    print("network is down")
    networkResults = "down"
    networkDown.isVisible = true
    networkUp.isVisible = false
    networkTx.isVisible = false
end

function netTransfer()
    print("network data in process")
    networkResults = "transfer"
    networkDown.isVisible = false
    networkUp.isVisible = false
    networkTx.isVisible = true
end

function ShowLoadingPopup()
    composer.showOverlay("overlayDL")
end

function HideLoadingPopup()
    composer.hideOverlay("overlayDL")
end