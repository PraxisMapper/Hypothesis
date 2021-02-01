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
    results = {}
    local tempResults = db:rows(sql)    

    for row in db:rows(sql) do
        table.insert(results, row) 
    end
    if (debugDB) then dump(results) end
    return results --results is a table of tables EX {[1] : {[1] : 1}} for count(*) when there are results.
end

function Exec(sql)
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

function Downloaded6Cell(pluscode)
    if (debug) then print("Checking if downloaded current 6 cell " .. pluscode) end
    local query = "SELECT COUNT(*) as c FROM dataDownloaded WHERE pluscode8 = '" .. pluscode .. "'"
    for i,row in ipairs(Query(query)) do
        if (row[1] >= 1) then --any number of entries over 1 means this block was visited.
            return true
        else
            return false
        end
    end
end

function Downloaded8Cell(pluscode)
    local query = "SELECT COUNT(*) as c FROM dataDownloaded WHERE pluscode8 = '" .. pluscode .. "'"
    for i,row in ipairs(Query(query)) do
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
    if (mapdataid == null) then return false end
    local query = "SELECT COUNT(*) as c FROM areasOwned WHERE MapDataId = "  .. mapdataid
    for i,row in ipairs(Query(query)) do
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
    local query = "SELECT factionID FROM playerData"
    for i,row in ipairs(Query(query)) do
        if (#row == 1) then
            return row[1]
        else
            return 0
        end
    end
    return 0
end

function GetServerAddress()
    local query = "SELECT serverAddress FROM systemData"
    for i,row in ipairs(Query(query)) do
        if (#row == 1) then
            return row[1]
        else
            return ""
        end
    end
    return ""
end


function SetServerAddress(url)
    local cmd = "UPDATE systemData SET serverAddress = '" .. url .. "'"
    db:exec(cmd)
end

function SetFactionId(teamId)
    local cmd = "UPDATE playerData SET factionID = " .. teamId .. ""
    db:exec(cmd)
end