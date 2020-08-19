-----------------------------------------------------------------------------------------
-- main.lua
-----------------------------------------------------------------------------------------
--this function sets up a few global variables and baseline config.
--remember, lua requires code to be in order to reference (cant call a function that's lower in the file than the current one)

--TODO:
--refactor and clean up code. move stuff and split into multiple files
----consider re-scoping variables, since calling a variable local in a file means other files can't see it. Not declaring it local makes it global, which is apparently slower.
----figure out how to make the scene change functions reusable. It doesn't look like dropping them into UIParts worked the first time?
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
--ponder using compass heading for arrow instead of GPS heading. --might not be useful? might be reading it wrong?
--Maybe track minimum/maximum altitude, and run the scoreboard off the difference between them?
system.setIdleTimer(false) --disables screen auto-off.

require("store")
require("helpers")
require("gameLogic")
require("database") 

debug = true --set false for release builds. Set true for lots of console info being dumped. Must be global to apply to all files.
debugShift = false --display math for shifting PlusCodes
debugGPS = false --display data for the GPS event and timer loop
debugDB = true
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
lastTime = 0
lastScoreLog = ""
lastHeadingTime = 0

lastLocationEvent = {}
  
print("starting network")
require("localNetwork")
networkResults = "blank"
UploadData()    


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

    lastLocationEvent = event

    -- if (event.distance ~= nil) then 
    if (event.direction ~= 0) then
         currentHeading = event.direction
     end

    local pluscode = tryMyEncode(event.latitude, event.longitude, 10); --only goes to 10 right now.
    if (debugGPS) then print ("Plus Code: " .. pluscode) end
    currentPlusCode = pluscode   

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
    -- local speed = event.speed
    -- if (lastTime == 0) then
    --     if(debugGPS) then print("Didn't move, no distance to add.") end
    --     lastTime = event.time --will never be less than 1 second, since this is seconds since epoch.
    --     return
    -- end

    --local duration = event.time - lastTime
    --local metersTravelled = speed * duration
    --if(debugGPS) then print("manual distance done") end
    --AddDistance(metersTravelled)
    AddDistance(event.distance)
    if(debugGPS) then print("added event.distance") end
    --lastDistance = event.distance .. "~" .. metersTravelled
    AddSeconds(event.time - lastLocationEvent.time)
    --lastTime = event.time
    AddSpeed(speed)
    --lastSpeed = event.speed
    SetMaxAltitude(event.altitude)
    --lastAltitude = event.altitude
    lastTime = event.time --will never be less than 1 second, since this is seconds since epoch?
    if(debugGPS) then print("Finished location event") end
end

-- function compassListener(event)
--     print("Compass fired!")
--     currentHeading = event.magnetic
--     currentHeadingTime = dump(event)
-- end

--will need to remove this manually on exit?
Runtime:addEventListener("location", gpsListener) 
--Runtime:addEventListener("heading", compassListener)
timer.performWithDelay(60000 * 5, ResetDailyWeekly, -1)  --TODO test this

