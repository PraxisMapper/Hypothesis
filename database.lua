--NOTE: on android, clearing app data doesnt' delete the database, just contents of it, apparently.
require("helpers")

local sqlite3 = require("sqlite3") 
db = "" 
local dbVersionID = 1

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

--THis loads a single terrain data entry from the DB.
function LoadTerrainData(pluscode) --plus code does not contain a + here
    if (debugDB) then print("loading terrain data for " .. pluscode) end
    local query = "SELECT * from terrainData WHERE plusCode = '" .. pluscode .. "'"
    local results = Query(query) 
    
    for i,row in ipairs(results) do
        if (debugDB) then print(dump(row)) end
        return row
    end 
    return {} --empty table means no data found.
end

--This loads all terrain for a cell8
function LoadTerrainDataCell8(pluscode) --plus code does not contain a + here
    if (debugDB) then print("loading terrain data for " .. pluscode) end
    local query = "SELECT * from terrainData WHERE plusCode LIKE '" .. pluscode .. "%'"
    local results = Query(query) 
    
    return results
end

function DownloadedCell8(pluscode)
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

function SpendPoints(points)
    local cmd = "UPDATE playerData SET totalPoints = totalPoints - " .. points
    db:exec(cmd)
end

function GetServerAddress()
    local query = "SELECT serverAddress FROM systemData"
    for i,row in ipairs(Query(query)) do
        if (#row == 1) then
            return row[1]
        else
            return "noServerFound"
        end
    end
    return ""
end

function SetServerAddress(url)
    local cmd = "UPDATE systemData SET serverAddress = '" .. url .. "'"
    db:exec(cmd)
end

function getHintInfo(plusCode)
    local cmd = 'SELECT * FROM geocacheHints WHERE plusCode8 = "' .. plusCode .. '"'
    local results = Query(cmd)
    for i,row in ipairs(Query(cmd)) do
        return row
    end
            --insert the data now.
            local exec = "INSERT INTO geocacheHints(plusCode8, hintsLeft, secretsLeft) VALUES('" .. plusCode .. "', 3, 1)"
            db:exec(exec)
            local t = {}
            t[2] = plusCode
            t[3] = 3
            t[4] = 1
            return t
end

function spendHint(plusCode)
    local cmd = 'UPDATE geocacheHints SET hintsLeft = (hintsLeft - 1) WHERE plusCode8 = "' .. plusCode .. '"'
    db:exec(cmd)
end

function spendSecret(plusCode)
    local cmd = 'UPDATE geocacheHints SET secretsLeft = (secretsLeft - 1) WHERE plusCode8 = "' .. plusCode .. '"'
    db:exec(cmd)
end