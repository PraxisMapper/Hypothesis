--TODO
--track more data for leaderboards?
--ponder converting between S2, PlusCodes, and GPS coords. if not, remove from table.
--cache data in a table, so i can just ping memory instead of disk for all (23 * 23) cells twice a second. Possibly. Indexing seems fast enough.
--encrypt database to stop people from just opening the file and editing as they want.
--possible optimization: store 8cell and 10cell both in the table, to avoid using substr() in queries, if that becomes too slow
require("helpers")

local sqlite3 = require("sqlite3") 
local db
local dbVersionID = 4

function startDatabase()
    -- Open "data.db". If the file doesn't exist, it will be created
    local path = system.pathForFile("data.db", system.DocumentsDirectory)
    db = sqlite3.open(path)

    -- Handle the "applicationExit" event to close the database
    local function onSystemEvent(event)
        if (event.type == "applicationExit" and db:isopen()) then db:close() end
    end

    -- Set up the table if it doesn't exist 
    --plusCodesVisited will be permanent first-time visits plus most recent data.
    --I shouldn't use Inserts in this block, since they'll still be run each startup. PUt those in createBaselineContent
    local tablesetup =
        [[CREATE TABLE IF NOT EXISTS plusCodesVisited(id INTEGER PRIMARY KEY, pluscode, lat, long, firstVisitedOn, lastVisitedOn, totalVisits, eightCode);
        CREATE TABLE IF NOT EXISTS acheivements(id INTEGER PRIMARY KEY, name, acheived, acheivedOn);
        CREATE TABLE IF NOT EXISTS playerData(id INTEGER PRIMARY KEY, distanceWalked, totalPoints, totalCellVisits, totalSecondsPlayed, maximumSpeed, totalSpeed, maxAltitude);
        CREATE TABLE IF NOT EXISTS systemData(id INTEGER PRIMARY KEY, dbVersionID, isGoodPerson, coffeesBought, deviceID);
        CREATE TABLE IF NOT EXISTS weeklyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS dailyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS trophysBought(id INTEGER PRIMARY KEY, itemCode, boughtOn);
        CREATE INDEX IF NOT EXISTS indexPCodes on plusCodesVisited(pluscode);
        CREATE INDEX IF NOT EXISTS indexEightCodes on plusCodesVisited(eightCode);
        ]]
        --CREATE TABLE IF NOT EXISTS ConversionLinks(id INTEGER PRIMARY KEY, pluscode, s2Cell, lat, long); --not sure yet if this is a thing i want to bother with.

    if (debug) then 
        print("SQLite version " .. sqlite3.version())
    end
    Exec(tablesetup)
    local previousDBVersion = Query("SELECT dbVersionID from systemData")[1][1]
    if (debugDB) then print(previousDBVersion) end
    createBaselineContent()
    upgradeDatabaseVersion(previousDBVersion)
    ResetDailyWeekly()

    -- Setup the event listener to catch "applicationExit"
    Runtime:addEventListener("system", onSystemEvent)
end

function upgradeDatabaseVersion(oldDBversion)
    if (oldDBversion == dbVersionID) then return end

    if (oldDBversion < 1) then
        --do any scripting to match upgrade to version 1
        --which should be none, since that's the baseline for this feature.
    end
    if (oldDBversion < 2) then
        -- add isGoodPerson, coffeesBought to systemData
        --also add trophysbought table.
        local v2Command = 
        [[ALTER TABLE systemData ADD COLUMN isGoodPerson;
          ALTER TABLE systemData ADD COLUMN coffeesBought; 
          UPDATE systemData SET isGoodPerson = 0, coffeesBought = 0;
          CREATE TABLE IF NOT EXISTS trophysBought(id INTEGER PRIMARY KEY, itemCode, boughtOn)
          ]]
          Exec(v2Command)
    end
    if (oldDBversion < 3) then
        --do any scripting to match upgrade to version 3
        --might need to add separate scores? Or just a cumulative running total instead?
        --add totalSecondsPlayed to DB. Add deviceID to systemData
        local v3Command = 
        [[ALTER TABLE playerData ADD COLUMN totalSecondsPlayed;
          UPDATE playerData SET totalSecondsPlayed = 0;
          ALTER TABLE systemData ADD COLUMN deviceID;
          UPDATE systemData SET deviceID = ]] .. system.getInfo("deviceID")  .. [[;
          ALTER TABLE plusCodesVisited ADD COLUMN lastVisitedOn; 
          UPDATE plusCodesVisited SET lastVisitedOn = ]] .. os.time() .. [[
          ]]
          Exec(v3Command)
    end
    if (oldDBversion < 4) then
         --do any scripting to match upgrade to version 4
         --might need to move ADD lastVisitedOn here
         --index will be created without this step, no other table edits yet.
         local v4Command = 
        [[ALTER TABLE playerData ADD COLUMN maximumSpeed;
        ALTER TABLE playerData ADD COLUMN totalSpeed;
        ALTER TABLE playerData ADD COLUMN maxAltitude;
          ]]
          Exec(v4Command)
    end
    if (oldDBversion < 4) then
        --do any scripting to match upgrade to version 5
        --Add the eightcode column and index to boost performance on the cityBlock screen.
        local v5Command = 
       [[ALTER TABLE plusCodesVisited ADD COLUMN eightCode;
       CREATE INDEX IF NOT EXISTS indexEightCodes on plusCodesVisited(eightCode);
         ]]
         Exec(v5Command)
   end

   Exec("UPDATE systemData SET dbVersionID = " .. dbVersionID)
end

function ResetDatabase()
    --db:close()
    path = system.pathForFile("data.db", system.DocumentsDirectory)
    db = sqlite3.open(path)
    db:exec("drop table test")
    db:exec("drop table plusCodesVisited")
    db:exec("drop table acheivements")
    db:exec("drop table playerData")
    db:exec("drop table systemData")
    db:exec("drop table weeklyVisited")
    db:exec("drop table dailyVisited")
    db:exec("drop table trophysBought")
    db:close()
    startDatabase()
end

function Query(sql)
    --if (debugDB) then print("sql command:" .. sql) end
    results = {}
    for row in db:rows(sql) do
        table.insert(results, row) --todo potential optimization? especially if I just iPairs this table.
    end
    if (debugDB) then dump(results) end
    return results 
end

function Exec(sql)
    if (debugDB) then print("exec sql command:" .. sql) end
    results = {}
    local resultCode = db:exec(sql);
    
    if (resultCode == 0) then
        return
    end

    --now its all error tracking.
    local errormsg = db:errmsg()
    if (debugDB) then print("sql exec error: " .. errormsg) end
end

function createBaselineContent()
     --insert system data row
     local query = "SELECT COUNT(*) FROM playerData"
     local dataPresent = Query(query)
     for i,row in ipairs(Query(query)) do
        if (row[1] == 1) then
            --data exists, bail out.
            return
        else
            --Database is empty, time to create the baseline data.
            local cmd = ""
            cmd = "INSERT INTO systemData(dbVersionID, isGoodPerson, coffeesBought, deviceID) values (" .. dbVersionID .. ", 0, 0, '" .. system.getInfo("deviceID") .. "')";
            Exec(cmd)
            cmd = "INSERT INTO playerData(distanceWalked, totalPoints, totalCellVisits, totalSecondsPlayed, maximumSpeed, totalSpeed, maxAltitude) values (0, 0, 0, 0, 0, 0, 0)";
            Exec(cmd)
            cmd = "INSERT INTO trophysBought(itemCode, boughtOn) VALUES (0, 0)";
            Exec(cmd)
        end
    end

     --create acheivement data. TODO
     local acheivementRows = { "INSERT INTO acheivements VALUES ()", "", ""}
     --foreach these strings.
end

function ResetDailyWeekly()
    --checks for daily and weekly reset times.
    --if oldest date in daily/weekly table is over 22/(24 * 6.9) hours old, delete everything in the table. (actually, do 22 hour reset)
    local timeDiffDaily = os.time() - (60 * 60 * 22) --22 hours, converted to seconds.
    local cmd = "DELETE FROM dailyVisited WHERE VisitedOn < " .. timeDiffDaily
    Exec(cmd)
    local timeDiffWeekly = os.time() - math.floor(60 * 60 * 24 * 6.9) -- 6.9 days, converted to seconds
    cmd = "DELETE FROM weeklyVisited WHERE VisitedOn < " .. timeDiffWeekly
    Exec(cmd)
end

function VisitedCell(pluscode)
    if (debugDB) then print("Checking if visited current cell " .. pluscode) end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE pluscode = '" .. pluscode .. "'"
    for i,row in ipairs(Query(query)) do
        if (row[1] == 1) then
            return true
        else
            return false
        end
    end
end

function Visited8Cell(pluscode)
    if (debugDB) then print("Checking if visited current 8 cell " .. pluscode) end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE eightCode = '" .. pluscode .. "'"
    for i,row in ipairs(Query(query)) do
        if (row[1] >= 1) then --any number of entries over 1 means this block was visited.
            return true
        else
            return false
        end
    end
end

--should probably be a gamelogic method
function TotalExploredCells()
    if (debugDB) then print("opening total explored cells ") end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited"
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end

function TotalExplored8Cells()
    if (debugDB) then print("opening total explored 8 cells ") end
    local query = "SELECT COUNT(distinct eightCode) as c FROM plusCodesVisited"
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end

function Score()
    local query = "SELECT totalPoints as p from playerData"
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end

function AddDistance(meters)
    if (meters == nil) then return end
    if (debugDB) then print("adding distance ") end
    local cmd = "UPDATE playerData SET distanceWalked = distanceWalked + " .. meters 
    Exec(cmd)
end

function AddSeconds(time)
    if (debugDB) then print("adding time :" .. time) end
    local cmd = "UPDATE playerData SET totalSecondsPlayed = totalSecondsPlayed + " .. time
    Exec(cmd)
end

function AddSpeed(speed)
    if (speed == nil) then return end
    if (debugDB) then print("adding speed:" .. speed) end
    local cmd = "UPDATE playerData SET totalSpeed = totalSpeed + " .. speed
    Exec(cmd)
    local currentMaxSpeed = Query("SELECT maximumSpeed from playerData")[1]
    if (debugDB) then print(currentMaxSpeed) end
    if (currentMaxSpeed < speed) then
        cmd = "UPDATE playerData SET maximumSpeed = " .. speed
        Exec(cmd)
    end
end

function SetMaxAltitude(alt)
    if (debugDB) then print("checking altitude ") end
    local currentMaxAlt = Query("SELECT maxAltitude from playerData")[1][1]
    if (currentMaxAlt < alt) then
        local cmd = "UPDATE playerData SET maxAltitude = " .. alt
        Exec(cmd)
    end
end

function GetClientData()
    --stuff to send up to leaderboards API
    if (debugDB) then print("loading client data ") end
    local query = "SELECT * from playerData P LEFT JOIN systemData S" --this gets everything, just has 2 columns named ID that should both be 1.
    local results = Query(query) --or just return this?
    for i,row in ipairs(results) do
        if (debugDB) then print(dump(row)) end
        
        --1 row, several columns. Map it to a table and send that over? 
        return row --this is only the first value?
    end 
end


--testing a performance thing
function AddRandomCells()
    for i = 1, 800, 1 do
        local cmd= "INSERT INTO plusCodesVisited (pluscode) VALUES (" .. math.random() .. ")" --just have something to look for
        Exec(cmd)
    end
end