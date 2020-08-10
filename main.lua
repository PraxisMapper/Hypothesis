-----------------------------------------------------------------------------------------
-- main.lua
-----------------------------------------------------------------------------------------
--this function sets up a few global variables and baseline config.
--remember, lua requires code to be in order to reference (cant call a function that's lower in the file than the current one)

--TODO:
--refactor and clean up code. move stuff and split into multiple files
----consider re-scoping variables, since calling a variable local in a file means other files can't see it. Not declaring it local makes it global, which is apparently slower.
----figure out how to make the scene change functions reusable. It doesn't look like dropping them into UIParts worked the first time?
--add game logic for game.
--name and baseline assets.
--implement store stuff and make scene for it
--allow user to set display name/nickname (or use Google Games signin? That might be faster/easier/another keyword)
--move some stuff to database for efficiency purposes
----EX: put colors in DB query so that i can just look up which color to draw a cell instead of checking after reading cellinfo?
----EX: maybe move score values to DB? could theoretically make a more complicated query that automatically updates scores that way
--Do i want to protect the DB at all to stop players from directly editing data?
--make a screen that draws the whole explored map you have, scaled to screen? requires drawing directly to a bitmap
--calculate distance between location events, track distance travelled in db?
--change colors to be more visible outdoors (I have a lot of dark colors, probably want light colors instead)
--create project with cutting-edge MS tech for server side
---whatever cheapest windows server AWS has, IIS latest, SQL Server (developer) latest, .NET 5 and API stuff
----or some other stuff? DOcker? but I also kinda want to show off specific familiar tools.
--ponder using compass heading for arrow instead of GPS heading.
system.setIdleTimer(false) --disables screen auto-off.

require("store")
require("helpers")
require("gameLogic")
require("database")

debug = true --set false for release builds. Set true for lots of console info being dumped. Must be global to apply to all files.
debugShift = true --display math for shifting PlusCodes
debugGPS = false --display data for the GPS event and timer loop
debugDB = false
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
lastTime = 0
lastScoreLog = ""

--testing boundary fix, part 2
--grantPoints("86HWHG2X+4V") --center cell
--one offs
--grantPoints("86HWHG2X+5V") 
--grantPoints("86HWHG2X+3V")
--grantPoints("86HWHG2X+4X")
--grantPoints("86HWHG2X+4R")
-- in neighboring 8cell on screen.
--grantPoints("86HWHH22+43")
--grantPoints("86HWGGXX+XW")
--grantPoints("86HWHG2X+4V")
--grantPoints("86HWGHX2+W4")
--grantPoints("86HWGH22+23")

--shiftCellV3("86HWHG2X+4X", 1, 10, true) --X looks correct
--shiftCellV3("86HWHG2X+2X", -1, 9, true) --y, going down 1

local composer = require("composer")
composer.gotoScene("10GridScene")

local function gpsListener(event)
    if (debugGPS) then
        print("got GPS event")
        if (event.errorCode ~= nil) then
            print("GPS Error " .. event.errorCode)
            return
        end

        print("Coords " .. event.latitude .. " " ..event.longitude)
    end

    currentHeading = event.direction

    local pluscode = tryMyEncode(event.latitude, event.longitude, 10); --only goes to 10 right now.
    if (debugGPS)then print ("Plus Code: " .. pluscode) end
    currentPlusCode = pluscode   

    --Testing boundary fix here, part 1.
    currentPlusCode = "86HWHG2X+2X" 
    --X coords are 6WGHV, Y coords are 8HH24
    --this should put 4 different 6-grids on screen at once.



    if (lastPlusCode == currentPlusCode) then
        --dont update stuff, we're still standing in the same spot.
        return
    end

    --now update stuff that only needs processed on entering a new cell
    lastPlusCode = currentPlusCode

    --do DB processing on plus codes.
    --this should be a gameLogic function
    if(debugGPS) then print("calculating score") end
    lastScoreLog = "Earned " .. grantPoints(currentPlusCode) .. " points from cell " .. currentPlusCode

    if(debugGPS) then print("calculating distance") end
    --easy-calc distance travelled
    local speed = event.speed
    if (lastTime == 0) then
        if(debugGPS) then print("Didn't move, no distance to add.") end
        lastTime = event.time --will never be less than 1 second, since this is seconds since epoch.
        return
    end
    local duration = event.time - lastTime
    local metersTravelled = speed * duration
    AddDistance(metersTravelled)
    AddSeconds(event.time)
    lastTime = event.time --will never be less than 1 second, since this is seconds since epoch
    if(debugGPS) then print("Finished location event") end

end

--will need to remove this manually on exit
Runtime:addEventListener("location", gpsListener) 

