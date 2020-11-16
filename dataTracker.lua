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
    --print("DataTracker learn 8 called")
    local status = requestedDataCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
    --print(status)
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = Downloaded8Cell(Cell8)
        if (dataPresent == true) then --use local data.
            requestedDataCells[Cell8] = 1
            return
        end
        requestedDataCells[Cell8] = 0
        print("getting 8 cell terrain data:" .. Cell8)
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

    --print("DataTracker maptile 10 called")
    local status = requestedMapTileCells[Cell10] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
    --print(status)
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell10 .. "-11.png", system.DocumentsDirectory)
        if (dataPresent == true) then --use local data.
            requestedMapTileCells[Cell10] = 1
            return
        end
        requestedMapTileCells[Cell10] = 0
        --print("getting 10 cell map tile")
        TrackerGet10CellImage11(Cell10)
     end

     if (status == -1) then --retry a failed download.
        requestedDataCells[Cell10] = 0
        TrackerGet10CellImage11(Cell10)
     end

end


function Get8CellTerrainData(code8)
    --print("tracker starting cell8 data " .. code8)
    --local cellAlreadyRequested = string.find(requestedCells, code8 .. ",")
    --print(cellAlreadyRequested)
    --if (cellAlreadyRequested ~= nil) then 
      --  print("or not") 
        --return 
    --end
    --print("found requested cell")
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
            --print(insertString)
            local results = db:exec(insertString)
            --print(results)
        end
    end
    local e2 = db:exec("END TRANSACTION")
    --if(debugNetwork) then print("table done") end
    --save these results to the DB.
    --print("saving info to db")
    local updateCmd = "INSERT INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode8 .. "', " .. os.time() .. ")"
    Exec(updateCmd)
    print("data inserted")
    requestedDataCells[plusCode8] = 1
end

function TrackerGet10CellImage11(plusCode)
    --print("trying 10cell11 download")
    --print("DL image for " .. plusCode)
    --plusCode10 = plusCode10:sub(0, 8) .. plusCode10:sub(10, 11) -- remove the actual plus sign
    --if networkReqPending == true then return end
    networkReqPending = true
    netTransfer()
    --ShowLoadingPopup()
    --print("past loading popup")
    --if (debugNetwork) then print ("getting cell image data via " .. serverURL .. "MapData/8cellbitmap11/" .. plusCode8) end
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.DocumentsDirectory}
    --print("params set")
    network.request(serverURL .. "MapData/10cellBitmap11/" .. plusCode, "GET", Trackerimage1011Listener, params)
end

function Trackerimage1011Listener(event)
    --if (debug) then print("10cell11 listener fired:" .. event.status) end
    --HideLoadingPopup()
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "MapData/10cellBitmap11/", "")
        --print("image pluscode: " .. filename)
        requestedMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "MapData/10cellBitmap11/", "")
        --print("image pluscode: " .. filename)
        requestedMapTileCells[filename] = -1
    end
end