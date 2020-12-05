--TODO
--cache data in a table, so i can just ping memory instead of disk for all (23 * 23) cells twice a second. Possibly. Indexing seems fast enough.
--encrypt database to stop people from just opening the file and editing as they want.
--NOTE: rows returns rows with numbered results, nrows returns values with named results.

--NOTE: on android, clearing app data doesnt' delete the database, just contents of it, apparently.
require("helpers")

local sqlite3 = require("sqlite3") 
db = "" 
local dbVersionID = 10

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
        --Add a table to track data we've downloaded.
        local v8Command = 
       [[CREATE TABLE IF NOT EXISTS terrainData (id INTEGER PRIMARY KEY, pluscode UNIQUE, name, areatype, lastUpdated);
         CREATE INDEX IF NOT EXISTS terrainIndex on terrainData(pluscode);
         CREATE TABLE IF NOT EXISTS dataDownloaded(id INTEGER PRIMARY KEY, pluscode8, downloadedOn);
         ]]
         Exec(v8Command)
   end
   if (oldDBversion < 9) then
    --do any scripting to match upgrade to version 9, i think i missed a number somewhere.
        --new table
        local v9Command = 
       [[CREATE TABLE IF NOT EXISTS areasOwned(id INTEGER PRIMARY KEY, mapDataId, name, points);
       ALTER TABLE terrainData ADD COLUMN MapDataId;
         ]]
         Exec(v9Command)
   end   
   if (oldDBversion < 10) then
    --do any scripting to match upgrade to version 10, i think i missed a number somewhere.
        --add column to table.
        local v9Command = 
       [[
       ALTER TABLE systemData ADD COLUMN factionID;
       UPDATE systemData SET factionID = 1;
         ]]
         Exec(v9Command)
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
    db:exec("drop table areasOwned")
    db:close()
    startDatabase()
end

function Query(sql)
    --if (debugDB) then print("sql command:" .. sql) end

    --I have an issue with Query, where i seem to get 2 or 3 different result types.
    --This needs to get boiled down to one, or some documented behavior.
    results = {}
    local tempResults = db:rows(sql)    

    for row in db:rows(sql) do
        table.insert(results, row) --todo potential optimization? especially if I just iPairs this table.
    end
    if (debugDB) then dump(results) end
    return results --results is a table of tables EX {[1] : {[1] : 1}} for count(*) when there are results.
end

function Exec(sql)
    --if (debugDB) then print("exec sql command:" .. sql) end
    results = {}
    local resultCode = db:exec(sql);

     if (resultCode == 0) then
         return 0
     end

    --now its all error tracking.
     local errormsg = db:errmsg()
     print(errormsg)
     native.showAlert("dbExec error", errormsg .. "|" .. sql)
     return resultCode
end

function ResetDailyWeekly()
    --checks for daily and weekly reset times.
    --if oldest date in daily/weekly table is over 22/(24 * 6.9) hours old, delete everything in the table.
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
        --print(dump(row))
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
    local qResults = Query(query)
    if (#qResults > 0) then
        for i,row in ipairs(qResults) do
            return row[1]
        end
    else
        return "?"
    end
end


--some/all of these are no longer used, merged into a single query in main right now.
-- function AddDistance(meters)
--     if (meters == nil) then return end
--     if (debugDB) then print("adding distance ") end
--     local cmd = "UPDATE playerData SET distanceWalked = distanceWalked + " .. meters 
--     Exec(cmd)
-- end

-- function AddSeconds(time)
--     if (debugDB) then print("adding time :" .. time) end
--     local cmd = "UPDATE playerData SET totalSecondsPlayed = totalSecondsPlayed + " .. time
--     Exec(cmd)
-- end

-- function AddSpeed(speed)    
--     if (speed == nil) then return end
--     if (debugDB) then print("adding speed:" .. speed) end
--     local cmd = "UPDATE playerData SET totalSpeed = totalSpeed + " .. speed
--     Exec(cmd)
--     local currentMaxSpeed = Query("SELECT maximumSpeed from playerData")[1][1]
--     if (debugDB) then print(currentMaxSpeed) end
--     if (currentMaxSpeed < speed) then
--         cmd = "UPDATE playerData SET maximumSpeed = " .. speed
--         Exec(cmd)
--     end
-- end

-- function SetMaxAltitude(alt)
--     if (debugDB) then print("checking altitude ") end
--     local currentMaxAlt = Query("SELECT maxAltitude from playerData")[1][1]
--     if (currentMaxAlt < alt) then
--         local cmd = "UPDATE playerData SET maxAltitude = " .. alt
--         Exec(cmd)
--     end
-- end

function GetClientData()
    --stuff to send up to leaderboards API
    if (debugDB) then print("loading client data ") end
    local query = "SELECT * from playerData P LEFT JOIN systemData S" --this gets everything, but has 2 columns named ID that should both be 1.
    local results = Query(query) --or just return this?
    for i,row in ipairs(results) do
        if (debugDB) then print(dump(row)) end
        return row --this is only the first value?
    end 
end

function LoadTerrainData(pluscode) --plus code does not contain a + here
    --print(pluscode)
    if (debugDB) then print("loading terrain data ") end
    local query = "SELECT * from terrainData WHERE plusCode = '" .. pluscode .. "'"
    local results = Query(query) 
    
    for i,row in ipairs(results) do
        if (debugDB) then print(dump(row)) end
        return row
    end 
    return {} --empty table means no data found.
end

function SaveTerrainData(pluscode, name, type)
    if (debugDB) then print("saving terrain data " .. pluscode .. " " .. name .. " " .. type) end
    local query = "INSERT OR REPLACE INTO terrainData (plusCode, name, areatype, lastUpdated) VALUES('" .. pluscode .. "', '" .. name .. "', '" .. type .. "', " .. os.time() .. ")"
    --Doing this locally here for a good reason. Can't upsert in this version of SQLite, so I have to check manually for dupes.
    local dupe = db:exec(query)    
end

--unused
-- function SaveDownloadedData(pluscode8)
--      --native.showAlert("test", pluscode)
--      if (debugDB) then print("saving downloaded data  reminder " .. pluscode8) end
--      local query = "DELETE FROM dataDownloaded WHERE plusCode8 = '" .. pluscode8 .. "'; INSERT OR REPLACE INTO dataDownloaded (plusCode8, downloadedOn) VALUES('" .. pluscode8 .. "', " .. os.time() .. ")"
--      local dupe = Exec(query)
-- end

function Downloaded6Cell(pluscode)
    if (debug) then print("Checking if downloaded current 6 cell " .. pluscode) end
    local query = "SELECT COUNT(*) as c FROM dataDownloaded WHERE pluscode8 = '" .. pluscode .. "'"
    --print (query)
    for i,row in ipairs(Query(query)) do
        --print(dump(row))
        if (row[1] >= 1) then --any number of entries over 1 means this block was visited.
            return true
        else
            return false
        end
    end
end

function Downloaded8Cell(pluscode)
    --if (debug) then print("Checking if downloaded current 8 cell " .. pluscode) end
    local query = "SELECT COUNT(*) as c FROM dataDownloaded WHERE pluscode8 = '" .. pluscode .. "'"
    --print (query)
    for i,row in ipairs(Query(query)) do
        --print(dump(row))
        if (row[1] >= 1) then --any number of entries over 1 means this block was visited.
            return true
        else
            return false
        end
    end
    return false
end

function ClaimAreaLocally(mapdataid, name, score)
    if (debug) then print("claiming area " .. mapdataid) end
    local cmd = "INSERT INTO areasOwned (mapDataId, name, points) VALUES (" .. mapdataid .. ", '" .. name .. "'," .. score ..")"
    db:exec(cmd)
end

function CheckAreaOwned(mapdataid)
    --if (debug) then print(mapdataid) end
    if (mapdataid == null) then return false end
    local query = "SELECT COUNT(*) as c FROM areasOwned WHERE MapDataId = "  .. mapdataid
    for i,row in ipairs(Query(query)) do
        --print(dump(row))
        if (row[1] >= 1) then --any number of entries over 1 means this entry is owned
            return true
        else
            return false
        end
    end
    return false
end

function AreaControlScore()
    local query = "SELECT SUM(points) FROM areasOwned"
    for i,row in ipairs(Query(query)) do
        if (#row == 1) then
            return row[1]
        else
            return 0
        end
    end
    return 0
end

function SpendPoints(points)
    local cmd = "UPDATE playerData SET totalPoints = totalPoints - " .. points
    db:exec(cmd)
end

function GetTeamID()
    local query = "SELECT factionID FROM systemData"
    for i,row in ipairs(Query(query)) do
        if (#row == 1) then
            return row[1]
        else
            return 0
        end
    end
    return 0
end
