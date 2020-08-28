--TODO
--ponder converting between S2, PlusCodes, and GPS coords. if not, remove from table.
--cache data in a table, so i can just ping memory instead of disk for all (23 * 23) cells twice a second. Possibly. Indexing seems fast enough.
--encrypt database to stop people from just opening the file and editing as they want.
--NOTE: rows returns rows with numbered results, nrows returns values with named results.

--NOTE: on android, clearing app data doesnt' delete the database, just contents of it, apparently.
require("helpers")

local sqlite3 = require("sqlite3") 
db = "" --tODO: make this local again?
local dbVersionID = 6

function startDatabase()
    -- Open "data.db". If the file doesn't exist, it will be created
    local path = system.pathForFile("data.db", system.DocumentsDirectory)
    db = sqlite3.open(path)

    -- Handle the "applicationExit" event to close the database
    local function onSystemEvent(event)
        if (event.type == "applicationExit" and db:isopen()) then db:close() end
    end

    Runtime:addEventListener("system", onSystemEvent)
end


    --CREATE TABLE IF NOT EXISTS terrainData (id INTEGER PRIMARY KEY, pluscode UNIQUE, name, areatype, lastUpdated);
    --CREATE INDEX IF NOT EXISTS terrainIndex on terrainData(pluscode)
    -- Set up the table if it doesn't exist 
    --plusCodesVisited will be permanent first-time visits plus most recent data.
    --I shouldn't use Inserts in this block, since they'll still be run each startup. PUt those in createBaselineContent
    --TODO: might need to mark some of these as REAL typed. Or make the first insert 0.0 to set that up?
    -- local tablesetup =
    --     [[CREATE TABLE IF NOT EXISTS plusCodesVisited(id INTEGER PRIMARY KEY, pluscode, lat, long, firstVisitedOn, lastVisitedOn, totalVisits, eightCode);
    --     CREATE TABLE IF NOT EXISTS acheivements(id INTEGER PRIMARY KEY, name, acheived, acheivedOn);
    --     CREATE TABLE IF NOT EXISTS playerData(id INTEGER PRIMARY KEY, distanceWalked REAL, totalPoints, totalCellVisits, totalSecondsPlayed, maximumSpeed, totalSpeed, maxAltitude, minAltitude);
    --     CREATE TABLE IF NOT EXISTS systemData(id INTEGER PRIMARY KEY, dbVersionID, isGoodPerson, coffeesBought, deviceID);
    --     CREATE TABLE IF NOT EXISTS weeklyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
    --     CREATE TABLE IF NOT EXISTS dailyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
    --     CREATE TABLE IF NOT EXISTS trophysBought(id INTEGER PRIMARY KEY, itemCode, boughtOn);
    --     CREATE INDEX IF NOT EXISTS indexPCodes on plusCodesVisited(pluscode);
    --     CREATE INDEX IF NOT EXISTS indexEightCodes on plusCodesVisited(eightCode);
    --     ]]
    --     --CREATE TABLE IF NOT EXISTS ConversionLinks(id INTEGER PRIMARY KEY, pluscode, s2Cell, lat, long); --not sure yet if this is a thing i want to bother with.

    -- if (debug) then 
    --     print("SQLite version " .. sqlite3.version())
    -- end
    -- Exec(tablesetup)

    -- --create content on first run, upgrade if necessary on later runs.
    -- local currentDataExists = Query("SELECT COUNT(*) from systemData")[1][1] --this has different depths on firstRun that later runs
    -- --native.showAlert("", dump(currentDataExists))
    -- if (currentDataExists == 0) then
    --     --Database is empty.
    --     createBaselineContent()
    -- else
    --     --database exists.
    --     local previousDBVersion = Query("SELECT dbVersionID from systemData")[1][1] --this errors out on first run, hence the split.
    --     upgradeDatabaseVersion(previousDBVersion)
    --     ResetDailyWeekly()
    -- end

    -- Setup the event listener to catch "applicationExit"
    
--end

function upgradeDatabaseVersion(oldDBversion)
    --if oldDbVersion is nil, that should mean we're making the DB for the first time and can skip this step
    if (oldDBversion == nil or oldDBversion == dbVersionID) then return end

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
    if (oldDBversion < 5) then
        --do any scripting to match upgrade to version 5
        --Add the eightcode column and index to boost performance on the cityBlock screen.
        local v5Command = 
       [[ALTER TABLE plusCodesVisited ADD COLUMN eightCode;
       UPDATE plusCodesVisited SET eightCode = SUBSTR(plusCode, 0, 8);
       CREATE INDEX IF NOT EXISTS indexEightCodes on plusCodesVisited(eightCode);
         ]]
         Exec(v5Command)
   end
   if (oldDBversion < 6) then
    --do any scripting to match upgrade to version 6
        --Add the eightcode column and index to boost performance on the cityBlock screen.
        local v6Command = 
       [[ALTER TABLE playerData ADD COLUMN minAltitude;
       UPDATE playerData SET minAltitude = 20000;
         ]]
         Exec(v6Command)
   end
   if (oldDBversion < 8) then
    --do any scripting to match upgrade to version 8, i think i missed a number somewhere.
        --Add the eightcode column and index to boost performance on the cityBlock screen.
        local v8Command = 
       [[CREATE TABLE IF NOT EXISTS terrainData (id INTEGER PRIMARY KEY, pluscode UNIQUE, name, areatype, lastUpdated);
         CREATE INDEX IF NOT EXISTS terrainIndex on terrainData(pluscode)
         ]]
         Exec(v8Command)
   end
   

   Exec("UPDATE systemData SET dbVersionID = " .. dbVersionID)
end

function ResetDatabase()
    db:close()
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

    --I have an issue with Query, where i seem to get 2 or 3 different result types.
    --This needs to get boiled down to one, or some documented behavior.
    --native.showAlert("", "sql passed:" .. sql)
    results = {}
    local tempResults = db:rows(sql)    

    for row in db:rows(sql) do
        table.insert(results, row) --todo potential optimization? especially if I just iPairs this table.
    end
    if (debugDB) then dump(results) end
    return results --results is a table of tables EX {[1] : {[1] : 1}} for count(*) when there are results.
end

function Exec(sql)
    if (debugDB) then print("exec sql command:" .. sql) end
    results = {}
    local resultCode = db:exec(sql);
    
    --return resultCode

     if (resultCode == 0) then
         return 0
     end

    --now its all error tracking.
     local errormsg = db:errmsg()
     print(errormsg)
     native.showAlert("dbExec error", errormsg)
     return resultCode
    -- if (debugDB) then print("sql exec error: " .. errormsg) end
end
--createbaselinecontent merged into the tablesetup commands
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
    --native.showAlert("", "getting Score")
    local qResults = Query(query)
    --native.showAlert("", #qResults)
    if (#qResults > 0) then
        for i,row in ipairs(qResults) do
            --native.showAlert("", dump(row))
            return row[1]
        end
    else
        return "?"
    end
end


--some/all of these are no longer used, merged into a single query in main right now.

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
    --native.showAlert("", "adding Speed of " .. speed)
    if (speed == nil) then return end
    if (debugDB) then print("adding speed:" .. speed) end
    local cmd = "UPDATE playerData SET totalSpeed = totalSpeed + " .. speed
    Exec(cmd)
    local currentMaxSpeed = Query("SELECT maximumSpeed from playerData")[1][1]
    if (debugDB) then print(currentMaxSpeed) end
    if (currentMaxSpeed < speed) then
        cmd = "UPDATE playerData SET maximumSpeed = " .. speed
        Exec(cmd)
    end
    --native.showAlert("", "speed added")
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

function LoadTerrainData(pluscode)
    --print(pluscode)
    if (debugDB) then print("loading terrain data ") end
    local query = "SELECT * from terrainData WHERE plusCode = '" .. pluscode .. "'"
    local results = Query(query) --or just return this?
    --print("query done for " .. pluscode)
    
    for i,row in ipairs(results) do
        if (debugDB) then print(dump(row)) end
        return row
    end 
    return {} --empty table means no data found.
end

function SaveTerrainData(pluscode, name, type)
    --native.showAlert("test", pluscode)
    if (debugDB) then print("saving terrain data " .. pluscode .. " " .. name .. " " .. type) end
    local query = "INSERT OR REPLACE INTO terrainData (plusCode, name, areatype, lastUpdated) VALUES('" .. pluscode .. "', '" .. name .. "', '" .. type .. "', " .. os.time() .. ")"
    --Doing this locally here for a good reason. Can't upsert in this version of SQLite, so I have to check manually for dupes.
    local dupe = db:exec(query)
    print("save success:" .. dupe)
    if (dupe > 0) then
        UpdateTerrainData(pluscode, name, type)
    end
end

-- function UpdateTerrainData(pluscode, name, type)
--     --native.showAlert("test", pluscode)
--     if (debugDB) then print("updating terrain data " .. pluscode .. " " .. name .. " " .. type) end
--     local query = "UPDATE terrainData  SET plusCode = '" .. pluscode .. "', name = '" .. name .. "', areatype = '" .. type .. "', lastUpdated = " .. os.time()
--     Exec(query)
-- end


--testing a performance thing
function AddRandomCells()
    for i = 1, 800, 1 do
        local cmd= "INSERT INTO plusCodesVisited (pluscode) VALUES (" .. math.random() .. ")" --just have something to look for
        Exec(cmd)
    end
end