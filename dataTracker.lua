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
        requestedDataCells[Cell10] = 0
        TrackerGet10CellImage11(Cell10)
     end
end

function GetMapTile8(Cell8)
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
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/Cell8Info/" .. code8) end
    network.request(serverURL .. "MapData/Cell8Info/" .. code8 , "GET", TrackplusCode8Listener)
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
end

function TrackerGet10CellImage11(plusCode)
    networkReqPending = true
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.DocumentsDirectory}
    network.request(serverURL .. "MapData/10cellBitmap11/" .. plusCode, "GET", Trackerimage1011Listener, params)
end

function Trackerimage1011Listener(event)
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "MapData/10cellBitmap11/", "")
        requestedMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "MapData/10cellBitmap11/", "")
        requestedMapTileCells[filename] = -1
    end
end

function TrackerGet8CellImage11(plusCode)
    networkReqPending = true
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.DocumentsDirectory}
    network.request(serverURL .. "MapData/8cellBitmap11/" .. plusCode, "GET", Trackerimage1011Listener, params)
end

function Trackerimage811Listener(event)
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "MapData/8cellBitmap11/", "")
        requestedMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "MapData/8cellBitmap11/", "")
        requestedMapTileCells[filename] = -1
    end
end