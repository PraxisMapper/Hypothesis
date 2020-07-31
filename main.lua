-----------------------------------------------------------------------------------------
-- main.lua
-----------------------------------------------------------------------------------------
--this function sets up a few global variables and baseline config.
--remember, lua requires code to be in order to reference (cant call a function that's lower in the file than the current one)


--TODO:
--refactor and clean up code. move stuff and split into multiple files
----consider re-scoping variables, since calling a variable local in a file means other files can't see it. Not declaring it local makes it global, which is apparently slower.
--add game logic for game.
--name and baseline assets.
--make a screen that draws the whole explored map you have, scaled to screen? requires drawing directly to a bitmap
--look into using timer.performwithdelay() as a method for updating objects repeatedly instead of only on events.
--calculate distance between location events, track distance travelled in db

system.setIdleTimer(false) --disables screen auto-off.

require("store")
require("helpers")
require("gameLogic")

require("database")
debug = true --set false for release builds. Set true for lots of console info being dumped. Must be global to apply to all files.
--uncomment when testing to clear local data.
--ResetDatabase()
startDatabase()

--uncomment to add test cell in lower right corner of 11x11 grid
 --function fillinTestCells()
     --AddPlusCode("849VCRXR+4M") --5, -5 means lower right cell
--     --AddPlusCode("849VCRXR+9C") --home base cell, center
 --end
 --fillinTestCells()

require("plusCodes")
currentPlusCode = "" -- where the user is sitting now
lastPlusCode = "" --the previously received value for the location event, may be the same as currentPlusCode
previousPlusCode = ""  --the previous DIFFERENT pluscode value we visited.
currentHeading = 0

local composer = require("composer")
composer.gotoScene("10GridScene")


local function gpsListener(event)
    if (debug) then
        print("got GPS event")
        if (event.errorCode ~= nil) then
            print("GPS Error " .. event.errorCode)
            return
        end

        print("Coords " .. event.latitude .. " " ..event.longitude)
    end

    currentheading = event.direction

    local pluscode = tryMyEncode(event.latitude, event.longitude, 10); --only goes to 10 right now. TODO expand if I want to for fun.
    if (debug)then print ("Plus Code: " .. pluscode) end
    currentPlusCode = pluscode   
    if (lastPlusCode == currentPlusCode) then
        --dont update stuff, we're still standing in the same spot.
        return
    end

    --now update stuff that only needs processed on entering a new cell
    lastPlusCode = currentPlusCode

    --do DB processing on plus codes.
    --this should be a gameLogic function
    grantPoints(currentPlusCode)
end

--will need to remove this manually on exit
Runtime:addEventListener("location", gpsListener) 

