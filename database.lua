local sqlite3 = require("sqlite3")

function startDatabase()
    -- Open "data.db". If the file doesn't exist, it will be created
    local path = system.pathForFile("data.db", system.DocumentsDirectory)
    local db = sqlite3.open(path)

    -- Handle the "applicationExit" event to close the database
    local function onSystemEvent(event)
        --if (event.type == "applicationExit") then db:close() end
        --I close it up in each function.
    end

    -- Set up the table if it doesn't exist

    --might need a daily table, to track cells visited today
    --same for weekly results.
    --plusCodesVisited will be permanent first-time visits
    local tablesetup =
        [[CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, content, content2);
        CREATE TABLE IF NOT EXISTS plusCodesVisited(id INTEGER PRIMARY KEY, pluscode, lat, long, firstVisitedOn, totalVisits);
        CREATE TABLE IF NOT EXISTS acheivements(id INTEGER PRIMARY KEY, name, acheived, acheivedOn);
        CREATE TABLE IF NOT EXISTS playerData(id INTEGER PRIMARY KEY, distanceWalked);
        ]]
    if (debug) then 
        print(tablesetup) 
        print("SQLite version " .. sqlite3.version())
    end
    Exec(tablesetup)

    -- Setup the event listener to catch "applicationExit"
    --Runtime:addEventListener("system", onSystemEvent)

    db:close();
end

function ResetDatabase()
    local path = system.pathForFile("data.db", system.DocumentsDirectory)
    local db = sqlite3.open(path)
    db:exec("drop table test")
    db:exec("drop table plusCodesVisited")
    db:exec("drop table acheivements")
    db:exec("drop table playerData")
    db:close()
    startDatabase()
end

function Query(sql)
    if (debug) then print("sql command:" .. sql) end
    results = {}
    local path = system.pathForFile("data.db", system.DocumentsDirectory)
    local db = sqlite3.open(path)
    for row in db:rows(sql) do
        table.insert(results, row)
    end
    db:close()
    if (debug) then dump(results) end
    return results
end

function Exec(sql)
    if (debug) then print("sql command:" .. sql) end
    results = {}
    local path = system.pathForFile("data.db", system.DocumentsDirectory)
    local db = sqlite3.open(path) 
    local resultCode = db:exec(sql);
    
    if (resultCode == 0) then
        db:close()
        return
    end

    --now its all error tracking.
    local errormsg = db:errmsg()
    if (debug) then print("sql exec error: " .. errormsg) end
    db:close()
end

function createBaselineContent()
     -- Open "data.db". If the file doesn't exist, it will be created (should have been done above.)
     local path = system.pathForFile("data.db", system.DocumentsDirectory)
     local db = sqlite3.open(path)

     --pre-fill plus codes? nah.

     --create acheivement data.
     local acheivementRows = { "INSERT INTO acheivements VALUES ()", "", ""}
     --foreach these strings.

     --examples.
     -- Add rows with an auto index in 'id'. You don't need to specify a set of values because we're populating all of them.
    local testvalue = {}
    testvalue[1] = "Hello"
    testvalue[2] = "World"
    testvalue[3] = "Lua"
    local tablefill = [[INSERT INTO test VALUES (NULL, ']] .. testvalue[1] ..
                          [[',']] .. testvalue[2] .. [['); ]]
    local tablefill2 = [[INSERT INTO test VALUES (NULL, ']] .. testvalue[2] ..
                           [[',']] .. testvalue[1] .. [['); ]]
    local tablefill3 = [[INSERT INTO test VALUES (NULL, ']] .. testvalue[1] ..
                           [[',']] .. testvalue[3] .. [['); ]]
    db:exec(tablefill)
    db:exec(tablefill2)
    db:exec(tablefill3)

    db:close()
end

function AddPlusCode(code) --string, pluscode
    if (debug) then print("begin adding plus code") end
    --check 1: is this a brand new cell?
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
        if (debug) then print("row data:" .. dump(row)) end
        if (row[1] == 0) then
            if (debug) then print("inserting new row") end
            local insert = "INSERT INTO plusCodesVisited (pluscode, lat, long, firstVisitedOn, totalVisits) VALUES ('" .. code .. "', 0,0, " .. os.time() .. ", 1)" --TODO acutal lat and long value, or drop those from the table?
            Exec(insert)
        else
            if (debug) then print("updating existing data") end
            local update = "UPDATE plusCodesVisited SET totalVisits = totalVisits + 1 WHERE plusCode = '" .. code  .. "'"
            Exec(update)
        end
    end 

    --check 2: this our first visit this week?

    --check 3? this our first visit today?


    
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

function TotalExploredCells()
    if (debug) then print("opening total explored cells ") end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited"
    --if Query(query)[1] == 1 then
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end
