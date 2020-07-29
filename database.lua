--TODO
--ponder keeping DB open as optimization? Need to see if this is actually slow as is.
--add game tables
--track more data
--ponder converting between S2, PlusCodes, and GPS coords. if not, remove from table.
--enable smooth updates as i change the DB.
--think about order of createBaselineContent and upgradeDatabaseVersion. create should probably be after.


local sqlite3 = require("sqlite3")
local db
local dbVersionID = 1

function startDatabase()
    -- Open "data.db". If the file doesn't exist, it will be created
    local path = system.pathForFile("data.db", system.DocumentsDirectory)
    db = sqlite3.open(path)

    -- Handle the "applicationExit" event to close the database
    local function onSystemEvent(event)
        if (event.type == "applicationExit" and db:isopen()) then db:close() end
        --I close it up in each function.
    end

    -- Set up the table if it doesn't exist 
    --might need a daily table, to track cells visited today
    --same for weekly results.
    --plusCodesVisited will be permanent first-time visits
    --I shouldn't use Inserts in this block, since they'll still be run each startup.
    local tablesetup =
        [[CREATE TABLE IF NOT EXISTS plusCodesVisited(id INTEGER PRIMARY KEY, pluscode, lat, long, firstVisitedOn, totalVisits);
        CREATE TABLE IF NOT EXISTS acheivements(id INTEGER PRIMARY KEY, name, acheived, acheivedOn);
        CREATE TABLE IF NOT EXISTS playerData(id INTEGER PRIMARY KEY, distanceWalked, totalPoints, totalCellVisits);
        CREATE TABLE IF NOT EXISTS systemData(id INTEGER PRIMARY KEY, dbVersionID);
        CREATE TABLE IF NOT EXISTS weeklyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        CREATE TABLE IF NOT EXISTS dailyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
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

    -- Setup the event listener to catch "applicationExit"
    Runtime:addEventListener("system", onSystemEvent)

    --db:close();
end

function upgradeDatabaseVersion()
    --query DB for current version
    if (dbVersionID <= 1) then
        --do any scripting to match upgrade to version 1
        --which should be none, since that's the baseline for this feature.
    end
    if (dbVersionID <= 2) then
        --do any scripting to match upgrade to version 2
        --
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
    db:close()
    startDatabase()
end

function Query(sql)
    if (debug) then print("sql command:" .. sql) end
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
    if (debug) then print("sql command:" .. sql) end
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
            cmd = "INSERT INTO systemData(dbVersionID) values (" .. dbVersionID .. ")";
            Exec(cmd)
            cmd = "INSERT INTO playerData(distanceWalked, totalPoints, totalCellVisits) values (0, 0, 0)";
            Exec(cmd)
        end
    end

     --create acheivement data.
     local acheivementRows = { "INSERT INTO acheivements VALUES ()", "", ""}
     --foreach these strings.

    --db:close()
end

function DBReset()
    --checks for daily and weekly reset times.
    --if oldest date in daily/weekly table is over 24/(24 * 7) hours old, delete everything in the table.
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

--should probably be a gamelogic method
function TotalExploredCells()
    if (debug) then print("opening total explored cells ") end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited"
    --if Query(query)[1] == 1 then
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end

function Score()
    if (debug) then print("opening score ") end
    local query = "SELECT totalPoints as p from playerData"
    --if Query(query)[1] == 1 then
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end
