-----------------------------------------------------------------------------------------
-- main.lua
-----------------------------------------------------------------------------------------
--this function sets up a few global variables and baseline config.
--remember, lua requires code to be in order to reference (cant call a function that's lower in the file than the current one)
--Remember: in LUA, if you use strings to index a table, you can't use #table to get a count accurately, but the string reference will work.

system.setIdleTimer(false) --disables screen auto-off.

require("store")
require("helpers")
require("gameLogic")
require("database")

print("starting network")
serverURL = "" --moving this here so it can be changed while running? TODO confirm
require("localNetwork")
networkResults = "down" --indicates if i am getting network data or not.

forceRedraw = false --used to tell the screen to redraw even if we havent moved.

debug = false --set false for release builds. Set true for lots of console info being dumped. Must be global to apply to all files.
debugShift = false --display math for shifting PlusCodes
debugGPS = true --display data for the GPS event and timer loop and auto-move
debugDB = false
debugLocal = false
debugNetwork = false
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

tappedAreaName = ""
tappedAreaScore = 0
tappedAreaMapDataId = 0

tappedCell = "            "
redrawOverlay = false
factionID = 0 --this is apparently real critical, even if its 0

typeNames = {}
typeNames["1"] = "Water"
typeNames["2"] = "Wetlands"
typeNames["3"] = "Park"
typeNames["4"] = "Beach"
typeNames["5"] = "University"
typeNames["6"] = "Nature Reserve"
typeNames["7"] = "Cemetery"
--typeNames["8"] = "Retail" --old mall entry, should never appear
typeNames["9"] = "Retail"
typeNames["10"] = "Tourism"
typeNames["11"] = "Historical"
typeNames["12"] = "Trail"
--typeNames["13"] = "" --admin entry, should never appear
typeNames["14"] = "Building"
typeNames["15"] = "Road"
typeNames["16"] = "Parking"
typeNames["100"] = "Server-Generated"

requestedCells = ""

cellDataCache = {}

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

tapData = display.newText("Cell Tapped:", 20, 1250, native.systemFont, 20)
tapData.anchorX = 0

--OSM License Compliance. Do not remove this line.
--It might be moved, but it must be visible when maptiles are.
--TODO: link to OSM license info when tapped?
local osmLicenseText = display.newText("Map Data © OpenStreetMap contributors", 530, 1250, native.systemFont, 20)

print("shifting to loading scene")
local composer = require("composer")
composer.isDebug = debug
composer.gotoScene("loadingScene")

function gpsListener(event)

    print("main gps fired")
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
    local plusCode8 = currentPlusCode:sub(0,8)

    --checking here. Checking for this after GrantPoints updates the visited list before this, would never load data.
    print("checking for terrain data")
    local hasData = Downloaded8Cell(plusCode8)
    print(hasData)
    if (hasData == false) then
        Get8CellData(plusCode8) -- we do need terrain info here.
    end

    local plusCode8 = currentPlusCode:sub(0,8)
    imageExists = doesFileExist(plusCode8 .. "-11.png", system.CachesDirectory)
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

function backListener(event)
    print("key listener got")
    if (event.keyName == "back" and event.phase == "up") then
        local currentScene = composer.getSceneName("current")
        if (currentScene == "SceneSelect") then
            return false
        end
        print("back to scene select")
        local options = {effect = "flip", time = 125}
        composer.gotoScene("SceneSelect", options)
        return true
    end
    print("didn't handle this one")
end

timer.performWithDelay(60000 * 5, ResetDailyWeekly, -1)
Runtime:addEventListener("location", gpsListener)
Runtime:addEventListener("key", backListener)

function netUp()
    networkResults = "up"
    networkUp.isVisible = true
    networkDown.isVisible = false
    networkTx.isVisible = false
end

function netDown()
    networkResults = "down"
    networkDown.isVisible = true
    networkUp.isVisible = false
    networkTx.isVisible = false
end

function netTransfer()
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