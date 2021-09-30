-----------------------------------------------------------------------------------------
-- main.lua
-----------------------------------------------------------------------------------------
--this function sets up a few global variables and baseline config.
--remember, lua requires code to be in order to reference (cant call a function that's lower in the file than the current one)
--Remember: in LUA, if you use strings to index a table, you can't use #table to get a count accurately, but the string reference will work.

system.setIdleTimer(false) --disables screen auto-off.

require("helpers")
require("gameLogic")
require("database")
require("plusCodes")
local lfs = require( "lfs" )
local composer = require("composer")


forceRedraw = false --used to tell the screen to redraw even if we havent moved.

debug = false --set false for release builds. Set true for lots of console info being dumped. Must be global to apply to all files.
composer.isDebug = debug
debugGPS = false --display data for the GPS event and timer loop and auto-move
debugDB = false
debugLocal = false
debugNetwork = false
--uncomment when testing to clear local data.
--ResetDatabase()
startDatabase()

serverURL = ""

currentPlusCode = "" -- where the user is sitting now
lastPlusCode = "" --the previously received value for the location event, may be the same as currentPlusCode
previousPlusCode = ""  --the previous DIFFERENT pluscode value we visited.
currentHeading = 0
lastScoreLog = ""
lastLocationEvent = ""

tappedAreaName = ""
tappedAreaScore = 0
tappedAreaMapDataId = ""

tappedCell = "            "
redrawOverlay = false
factionID = 0 --composer.getVariable(factionID) is used in some spots

requestedCells = ""

--store server bounds in memory on startup.
serverBounds = {}
serverBounds["south"] = -90
serverBounds["west"] = -180
serverBounds["north"] = 90
serverBounds["east"] = 180
playerInBounds = true

function InBounds(lat, lon)
    if (lat >= serverBounds["south"] and lat <= serverBounds["north"]) then
        if (lon >= serverBounds["west"] and lon <= serverBounds["east"]) then
            return true
        end
    end
    return false
end

--Game specific common data for Area Tag.
factions = {}
factions[1] = {}
factions[1].id = 1
factions[1].name = "Red Team"
factions[2] = {}
factions[2].id = 2
factions[2].name = "Green Team"
factions[3] = {}
factions[3].id = 3
factions[3].name = "Blue Team"

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
composer.gotoScene("loadingScene")

function gpsListener(event)
    if (debugGPS) then
        print("main gps fired")
        if (event.errorCode ~= nil) then
            print("GPS Error " .. event.errorCode)
            return
        end

        print("Coords " .. event.latitude .. " " ..event.longitude)
    end

    if not InBounds(event.latitude, event.longitude) then
        --skip the rest of the processing.
        playerInBounds = false
        composer.showOverlay("oobOverlay")
        return
    end
    if (not playerInBounds) then
        composer.hideOverlay()
    end
    playerInBounds = true

    if (event.direction ~= 0) then
         currentHeading = event.direction
     end

    local pluscode = encodeLatLon(event.latitude, event.longitude, 10); --only goes to 10 right now.
    if (debugGPS) then print ("Plus Code: " .. pluscode) end
    currentPlusCode = pluscode
    local plusCode8 = currentPlusCode:sub(0,8)

    if (lastPlusCode ~= currentPlusCode) then
        --update score stuff, we moved a cell.
        if(debugGPS) then print("calculating score") end
        lastScoreLog = "Earned " .. grantPoints(currentPlusCode) .. " points from cell " .. currentPlusCode
        lastPlusCode = currentPlusCode
    end

    if(debugGPS) then print("Finished location event") end
    lastLocationEvent = event
end

function backListener(event)
    if (debug) then print("key listener got")  end
    if (event.keyName == "back" and event.phase == "up") then
        local currentScene = composer.getSceneName("current")
        if (currentScene == "SceneSelect") then
            return false
        end
        if (debug) then print("back to scene select") end
        local options = {effect = "flip", time = 125}
        composer.gotoScene("SceneSelect", options)
        return true
    end
    if (debug) then print("didn't handle this one") end
end

function clearMACcache()
    print("clearing tile cache")
    requestedMPMapTileCells = {}
    local temp_path = system.pathForFile( "", system.TemporaryDirectory )
    for file in lfs.dir( temp_path ) do
        os.remove(system.pathForFile( file, system.TemporaryDirectory ))
    end
end

timer.performWithDelay(20000, clearMACcache, -1)
Runtime:addEventListener("location", gpsListener)
Runtime:addEventListener("key", backListener)

function netUp()
    networkUp.isVisible = true
    networkDown.isVisible = false
    networkTx.isVisible = false
end

function netDown(event)
    networkDown.isVisible = true
    networkUp.isVisible = false
    networkTx.isVisible = false
    if (event ~= nil and debug) then
        native.showAlert("net error",  event.status .. " | " .. string.gsub(event.url, serverURL, "") .. " |"  .. event.response)
    end
end

function netTransfer()
    networkDown.isVisible = false
    networkUp.isVisible = false
    networkTx.isVisible = true
end

function DefaultNetCallHandler(event)
    if (event.status ~= 200) then
        netDown(event)
    else
        netUp()
    end
end