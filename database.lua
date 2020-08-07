--TODO
--add game tables
--track more data
--ponder converting between S2, PlusCodes, and GPS coords. if not, remove from table.
--enable smooth updates as i change the DB.
--cache data in a table, so i can just ping memory instead of disk for all (23 * 23) cells twice a second. Possibly.
--encrypt database to stop people from just opening the file and editing as they want.
--possible optimization: store 8cell and 10cell both in the table, to avoid using substr() in queries
--possible optimization: add indexes to DB. I need to see where it slows down first.
require("helpers")

local sqlite3 = require("sqlite3")
local db
local dbVersionID = 3

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
        [[CREATE TABLE IF NOT EXISTS plusCodesVisited(id INTEGER PRIMARY KEY, pluscode, lat, long, firstVisitedOn, lastVisitedOn, totalVisits);
        CREATE TABLE IF NOT EXISTS acheivements(id INTEGER PRIMARY KEY, name, acheived, acheivedOn);
        CREATE TABLE IF NOT EXISTS playerData(id INTEGER PRIMARY KEY, distanceWalked, totalPoints, totalCellVisits, totalSecondsPlayed);
        CREATE TABLE IF NOT EXISTS systemData(id INTEGER PRIMARY KEY, dbVersionID, isGoodPerson, coffeesBought, deviceID);
        CREATE TABLE IF NOT EXISTS weeklyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS dailyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS trophysBought(id INTEGER PRIMARY KEY, itemCode, boughtOn);
        ]]
        --CREATE TABLE IF NOT EXISTS ConversionLinks(id INTEGER PRIMARY KEY, pluscode, s2Cell, lat, long); --not sure yet if this is a thing i want to bother with.
        --INSERT INTO systemData(dbVersionID) values (]] .. dbVersionID .. [[);

    if (debug) then 
        --print(tablesetup) 
        print("SQLite version " .. sqlite3.version())
    end
    Exec(tablesetup)
    upgradeDatabaseVersion()
    createBaselineContent()
    ResetDailyWeekly()

    -- Setup the event listener to catch "applicationExit"
    Runtime:addEventListener("system", onSystemEvent)

    --db:close();
end

function upgradeDatabaseVersion()
    --query DB for current version
    if (dbVersionID < 1) then
        --do any scripting to match upgrade to version 1
        --which should be none, since that's the baseline for this feature.
    end
    if (dbVersionID < 2) then
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
    if (dbVersionID < 3) then
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
    if (dbVersionID < 4) then
         --do any scripting to match upgrade to version 4
         --might need to move ADD lastVisitedOn here
    end
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
    --if (debug) then print("sql command:" .. sql) end
    results = {}
    --local path = system.pathForFile("data.db", system.DocumentsDirectory)
    --local db = sqlite3.open(path)
    for row in db:rows(sql) do
        table.insert(results, row) --todo potential optimization? especially if I just iPairs this table.
    end
    --db:close()
    if (debug) then dump(results) end
    return results 
end

function Exec(sql)
    if (debug) then print("exec sql command:" .. sql) end
    results = {}
    --local path = system.pathForFile("data.db", system.DocumentsDirectory)
    --local db = sqlite3.open(path) 
    local resultCode = db:exec(sql);
    
    if (resultCode == 0) then
        --db:close()
        return
    end

    --now its all error tracking.
    local errormsg = db:errmsg()
    if (debug) then print("sql exec error: " .. errormsg) end
    --db:close()
end

function createBaselineContent()
     -- Open "data.db". If the file doesn't exist, it will be created (should have been done above.)
     --local path = system.pathForFile("data.db", system.DocumentsDirectory)
     --local db = sqlite3.open(path)

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
            cmd = "INSERT INTO systemData(dbVersionID, isGoodPerson, coffeesBought, deviceID) values (" .. dbVersionID .. ", 0, 0, " .. system.getInfo("deviceID") .. ")";
            Exec(cmd)
            cmd = "INSERT INTO playerData(distanceWalked, totalPoints, totalCellVisits, totalSecondsPlayed) values (0, 0, 0, 0)";
            Exec(cmd)
        end
    end

     --create acheivement data.
     local acheivementRows = { "INSERT INTO acheivements VALUES ()", "", ""}
     --foreach these strings.

    --db:close()
end

function ResetDailyWeekly()
    --checks for daily and weekly reset times.
    --if oldest date in daily/weekly table is over 24/(24 * 7) hours old, delete everything in the table. (actually , do 22 hour reset)
    local timeDiffDaily = os.time() - (60 * 60 * 22) --22 hours, converted to seconds.
    local cmd = "DELETE FROM dailyVisited WHERE VisitedOn < " .. timeDiffDaily
    Exec(cmd)
    local timeDiffWeekly = os.time() - math.floor(60 * 60 * 24 * 6.9) -- 6.9 days, converted to seconds
    cmd = "DELETE FROM weeklyVisited WHERE VisitedOn < " .. timeDiffWeekly
    Exec(cmd)
end

function VisitedCell(pluscode)
    if (debug) then print("Checking if visited current cell " .. pluscode) end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE pluscode = '" .. pluscode .. "'"
    --if Query(query)[1] == 1 then
    for i,row in ipairs(Query(query)) do
        if (row[1] == 1) then
            return true
        else
            return false
        end
    end
end

function Visited8Cell(pluscode)
    if (debug) then print("Checking if visited current 8 cell " .. pluscode) end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE substr(pluscode, 1, 8) = '" .. pluscode .. "'"
    --if Query(query)[1] == 1 then
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
    --if (debug) then print("opening total explored cells ") end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited"
    --if Query(query)[1] == 1 then
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end

function TotalExplored8Cells()
    --if (debug) then print("opening total explored 8 cells ") end
    local query = "SELECT COUNT(DISTINCT substr(pluscode, 1, 8)) as c FROM plusCodesVisited"
    --if Query(query)[1] == 1 then
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end

function Score()
    --if (debug) then print("opening score ") end
    local query = "SELECT totalPoints as p from playerData"
    --if Query(query)[1] == 1 then
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end

function AddDistance(meters)
    if (debug) then print("adding distance ") end
    local cmd = "UPDATE playerData SET distanceWalked = distanceWalked + " .. meters 
    Exec(cmd)
end

function AddSeconds(time)
    if (debug) then print("adding time ") end
    local cmd = "UPDATE playerData SET totalSecondsPlayed = totalSecondsPlayed + " .. time
    Exec(cmd)
end

function GetClientData()
    --stuff to send up to leaderboards API
    if (debug) then print("loading client data ") end
    local query = "SELECT * from playerData P LEFT JOIN systemData S" --this gets everything, just has 2 columns named ID that should both be 1.
    local results = Query(query) --or just return this?
    for i,row in ipairs(results) do
        --1 row, several columns. Map it to a table and send that over? 
        --return row[1] --this is only the first value.
    end 
end


--testing a performance thing
function AddRandomCells()
    for i = 1, 800, 1 do
        local cmd= "INSERT INTO plusCodesVisited (pluscode) VALUES (" .. math.random() .. ")" --just have something to look for
        Exec(cmd)
    end
end