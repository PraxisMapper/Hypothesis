--a single shared file for specifically handling downloading map tiles and cell data
--This is an attempt to make updating a bigger grid faster, such as the 35x35 area control map.
--by minimizing duplicate work/network calls/etc.

require("localNetwork") --for serverURL.

--this process:
--these tables have a string key for each relevant cell
--key present: this cell has been requested this session
--key absent: this cell has not been requested this session
--0 value: request sent
--1 value: data present (either request completed earlier or data was already present)
-- -1 value: last request failed.
requestedDataCells = {} --these should be Cell8
requestedMapTileCells = {} --these should be Cell10
requestedMPMapTileCells = {} --these should be Cell10, separate because they can change quickly.
requestedTurfWarCells = {} --Should be a table by instance types, since multiple Turf Wars can run at once.
TurfWarInstanceIDs ={} --list of int ids.

requestedTurfWarCells[1] = {}

function GetMapData8(Cell8) -- the terrain type call.
    local status = requestedDataCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = Downloaded8Cell(Cell8)
        if (dataPresent == true) then --use local data.
            requestedDataCells[Cell8] = 1
            return
        end
        requestedDataCells[Cell8] = 0
        Get8CellTerrainData(Cell8)
     end

     if (status == -1) then --retry a failed download.
        requestedDataCells[Cell8] = 0
        Get8CellTerrainData(Cell8)
     end
end

function GetMapTile10(Cell10)
    if (requestedMapTileCells[cell10] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMapTileCells[Cell10] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell10 .. "-11.png", system.DocumentsDirectory)
        if (dataPresent == true) then --use local data.
            requestedMapTileCells[Cell10] = 1
            return
        end
        requestedMapTileCells[Cell10] = 0
        TrackerGet10CellImage11(Cell10)
     end

     if (status == -1) then --retry a failed download.
        requestedMapTileCells[Cell10] = 0
        TrackerGet10CellImage11(Cell10)
     end
end

function GetMapTile8(Cell8)
    print("Getting map tile for " .. Cell8) 
    if (requestedMapTileCells[cell8] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMapTileCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell8 .. "-11.png", system.DocumentsDirectory)
        if (dataPresent == true) then --use local data.
            requestedMapTileCells[Cell8] = 1
            return
        end
        requestedMapTileCells[Cell8] = 0
        TrackerGet8CellImage11(Cell8)
     end

     if (status == -1) then --retry a failed download.
        requestedDataCells[Cell8] = 0
        TrackerGet8CellImage11(Cell8)
     end
end

function Get8CellTerrainData(code8)
    networkReqPending = true
    if debugNetwork then print("network: getting 8 cell data " .. code8) end
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/LearnCell8/" .. code8) end
    network.request(serverURL .. "MapData/LearnCell8/" .. code8 , "GET", TrackplusCode8Listener)
end

function TrackplusCode8Listener(event)
    if (debug) then print("plus code 8 event started") end
    if event.status == 200 then 
        netUp() 
    else 
        netDown() 
    end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.
    networkReqPending = false 

    --This one splits each 10cell via newline.
    local resultsTable = Split(event.response, "\r\n") --windows newlines
    print("received: " .. resultsTable[1] .. " " .. #resultsTable)
    --Format:
    --line1: the cell8 requested
    --remaining lines: the last 2 digits in the cell10=name|typeID|mapDataID
    --EX: 48=Local Park|4|1234

    db:exec("BEGIN TRANSACTION") --transactions for multiple inserts are a huge performance boost.
    local plusCode8 = resultsTable[1] 
    for i = 2, #resultsTable do
        if (resultsTable[i] ~= nil and resultsTable[i] ~= "") then 
            local data = Split(resultsTable[i], "|") --4 data parts in order
            data[2] = string.gsub(data[2], "'", "''")--escape data[2] to allow ' in name of places.
            insertString = "INSERT INTO terrainData (plusCode, name, areatype, MapDataId) VALUES ('" .. resultsTable[1] .. data[1] .. "', '" .. data[2] .. "', '" .. data[3] .. "', '" .. data[4] .. "');" 
            local results = db:exec(insertString)
        end
    end
    local e2 = db:exec("END TRANSACTION")
    --save these results to the DB.
    local updateCmd = "INSERT INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode8 .. "', " .. os.time() .. ")"
    Exec(updateCmd)
    print("data inserted")
    requestedDataCells[plusCode8] = 1
    forceRedraw = true
end

function TrackerGet10CellImage11(plusCode)
    networkReqPending = true
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.DocumentsDirectory}
    network.request(serverURL .. "MapData/DrawCell10Highres/" .. plusCode, "GET", Trackerimage1011Listener, params)
end

function Trackerimage1011Listener(event)
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "MapData/DrawCell10Highres/", "")
        requestedMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "MapData/DrawCell10Highres/", "")
        requestedMapTileCells[filename] = -1
    end
end

function TrackerGet8CellImage11(plusCode)
    networkReqPending = true
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.DocumentsDirectory}
    network.request(serverURL .. "MapData/DrawCell8Highres/" .. plusCode, "GET", Trackerimage1011Listener, params)
end

function Trackerimage811Listener(event)
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "MapData/DrawCell8Highres/", "")
        requestedMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "MapData/DrawCell8Highres/", "")
        requestedMapTileCells[filename] = -1
    end
end

--TODO: make new handler methods, update URLs for these, create new Lua tables for these map tiles with a faster refresh.
function GetTeamControlMapTile10(Cell10)
    if (requestedMPMapTileCells[cell10] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMPMapTileCells[Cell10] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell10 .. "-AC-11.png", system.DocumentsDirectory)
        if (dataPresent == true) then --use local data.
            requestedMPMapTileCells[Cell10] = 1
            return
        end
        requestedMPMapTileCells[Cell10] = 0
        TrackerGetMP10CellImage11(Cell10)
     end

     if (status == -1) then --retry a failed download.
        requestedDataCells[Cell10] = 0
        TrackerGetMP10CellImage11(Cell10)
     end
end

function GetTeamControlMapTile8(Cell8)
    print("requesting cell " .. Cell8)
    if (requestedMPMapTileCells[cell8] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMPMapTileCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell8 .. "-AC-11.png", system.DocumentsDirectory)
        if (dataPresent == true) then --use local data.
            requestedMPMapTileCells[Cell8] = 1
            return
        end
        requestedMPMapTileCells[Cell8] = 0
        TrackerGetMP8CellImage11(Cell8)
     end

     if (status == -1) then --retry a failed download.
        requestedDataCells[Cell8] = 0
        TrackerGetMP8CellImage11(Cell8)
     end
end

function TrackerGetMP10CellImage11(plusCode)
    networkReqPending = true
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-AC-11.png", baseDirectory = system.DocumentsDirectory}
    network.request(serverURL .. "Gameplay/DrawFactionModeCell10HighRes/" .. plusCode, "GET", TrackerMPimage1011Listener, params)
end

function TrackerMPimage1011Listener(event)
    print("got data for " ..  string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell10HighRes/", ""))
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell10HighRes/", "")
        requestedMPMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell10HighRes/", "")
        requestedMPMapTileCells[filename] = -1
    end
end

function TrackerGetMP8CellImage11(plusCode)
    networkReqPending = true
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-AC-11.png", baseDirectory = system.DocumentsDirectory}
    network.request(serverURL .. "Gameplay/DrawFactionModeCell8HighRes/" .. plusCode, "GET", TrackerMPimage811Listener, params)
end

function TrackerMPimage811Listener(event)
    print("got data for " ..  string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell8HighRes/", ""))
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell8HighRes/", "")
        requestedMPMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell8HighRes/", "")
        requestedMPMapTileCells[filename] = -1
    end
end

function GetTurfWarInstanceIDs()
end


--Since Turf War is meant to be a much faster game mode, we won't save its state in the database, just memory.
function GetTurfWarMapData8(Cell8, instanceID) -- the turf war map update call.
    --this doesn't get saved to the device at all. Keep it in memory, update it every few seconds.
    print("calling Turf War map info for " .. Cell8)
    networkReqPending = true
    netTransfer()
    network.request(serverURL .. "TurfWar/LearnCell8/" .. instanceID .. "/" .. Cell8, "GET", TurfWarMapListener) 
end

function TurfWarMapListener(event)
    if (debug) then print("turf war map event started") end
    -- print(event.status)
    --print(event.url)
    --print(event.response)
    if event.status == 200 then 
        netUp() 
    else 
        netDown() 
    end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.
    networkReqPending = false 
    --TODO, i need to pull the instance ID out of the URL
    local instanceID = Split(string.gsub(event.url, serverURL .. "TurfWar/LearnCell8/", ""), "/")[1]
    --print(instanceID)
    --This one splits each 10cell via pipe, each sub-vaule by =
    local resultsTable = Split(event.response, "|")
    print("received count: " .. #resultsTable)
    --Format:
    --cell10=TeamID

    for cell = 1, #resultsTable do
        local splitData = Split(resultsTable[cell], "=")
        --print(dump(splitData))
        local key = splitData[1]
        requestedTurfWarCells[key] = splitData[2]
        --print(dump(requestedTurfWarCells))
        --print(dump(requestedTurfWarCells[key]))
        --print("value assigned")
    end

    print("turf war table updated")
    --print(dump(requestedTurfWarCells[tonumber(instanceID)]))
    forceRedraw = true
end

function ClaimTurfWarCell(Cell10, factionId)
    print("claiming cell for faction")
    networkReqPending = true
    netTransfer()
    network.request(serverURL .. "TurfWar/ClaimCell10/" .. factionId .. "/" .. Cell10, "GET", TurfWarClaimListener) 
end

function TurfWarClaimListener(event) --doesnt record any data.
    if event.status == 200 then 
        netUp() 
    else 
        netDown() 
    end
    networkReqPending = false 
end