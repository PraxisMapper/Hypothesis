--a single shared file for specifically handling downloading map tiles and cell data
--This is an attempt to make updating a bigger grid faster, such as the 35x35 area control map.
--by minimizing duplicate work/network calls/etc.

require("localNetwork") --for serverURL.
require("helpers") --colorConvert

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
requestedPaintTownCells = {} --Should be a table by instance types, since multiple PaintTheTowns could run at once.
PaintTownInstanceIDs ={} --list of int ids.

requestedPaintTownCells[1] = {}
requestedPaintTownCells[2] = {}

function GetMapData8(Cell8) -- the terrain type call.
    local status = requestedDataCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = DownloadedCell8(Cell8)
        if (dataPresent == true) then --use local data.
            requestedDataCells[Cell8] = 1
            return
        end
        requestedDataCells[Cell8] = 0
        GetCell8TerrainData(Cell8)
     end

     if (status == -1) then --retry a failed download.
        requestedDataCells[Cell8] = 0
        GetCell8TerrainData(Cell8)
     end
end

function GetMapTile10(Cell10)
    if (requestedMapTileCells[cell10] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMapTileCells[Cell10] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell10 .. "-11.png", system.CachesDirectory)
        if (dataPresent == true) then --use local data.
            requestedMapTileCells[Cell10] = 1
            return
        end
        requestedMapTileCells[Cell10] = 0
        TrackerGetCell10Image11(Cell10)
     end

     if (status == -1) then --retry a failed download.
        requestedMapTileCells[Cell10] = 0
        TrackerGetCell10Image11(Cell10)
     end
end

function GetMapTile8(Cell8)
    if (requestedMapTileCells[cell8] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMapTileCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell8 .. "-11.png", system.CachesDirectory)
        if (dataPresent == true) then --use local data.
            requestedMapTileCells[Cell8] = 1
            return
        end
        requestedMapTileCells[Cell8] = 0
        TrackerGetCell8Image11(Cell8)
     end

     if (status == -1) then --retry a failed download.
        requestedMapTileCells[Cell8] = 0
        TrackerGetCell8Image11(Cell8)
     end
end

function GetCell8TerrainData(code8)
    if debugNetwork then 
        print("network: getting 8 cell data " .. code8) 
        print ("getting cell data via " .. serverURL .. "MapData/LearnCell8/" .. code8) 
    end
    network.request(serverURL .. "MapData/LearnCell8/" .. code8 , "GET", TrackplusCode8Listener)
    netTransfer()
end

function TrackplusCode8Listener(event)
    if (debug) then print("plus code 8 event started") end
    if event.status == 200 then 
        netUp() 
    else 
        netDown() 
    end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.

    --This one splits each Cell10 via newline.
    local resultsTable = Split(event.response, "\r\n") --windows newlines
    --Format:
    --line1: the Cell8 requested
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
    requestedDataCells[plusCode8] = 1
    forceRedraw = true
end

function TrackerGetCell10Image11(plusCode)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.CachesDirectory}
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

function TrackerGetCell8Image11(plusCode)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "MapData/DrawCell8Highres/" .. plusCode, "GET", Trackerimage811Listener, params)
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

function GetTeamControlMapTile8(Cell8)
    if (requestedMPMapTileCells[cell8] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMPMapTileCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell8 .. "-AC-11.png", system.CachesDirectory)
        if (dataPresent == true) then --use local data.
            requestedMPMapTileCells[Cell8] = 1
            return
        end
        requestedMPMapTileCells[Cell8] = 0
        TrackerGetMPCell8Image11(Cell8)
     end

     if (status == -1) then --retry a failed download.
        requestedDataCells[Cell8] = 0
        TrackerGetMPCell8Image11(Cell8)
     end
end

function TrackerMPimage1011Listener(event)
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "AreaControl/DrawFactionModeCell10HighRes/", "")
        requestedMPMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "AreaControl/DrawFactionModeCell10HighRes/", "")
        requestedMPMapTileCells[filename] = -1
    end
end

function TrackerGetMPCell8Image11(plusCode)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-AC-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "AreaControl/DrawFactionModeCell8HighRes/" .. plusCode, "GET", TrackerMPimage811Listener, params)
end

function TrackerMPimage811Listener(event)
    if (debug) then print("got data for " ..  string.gsub(event.url, serverURL .. "AreaControl/DrawFactionModeCell8HighRes/", "")) end
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "AreaControl/DrawFactionModeCell8HighRes/", "")
        requestedMPMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "AreaControl/DrawFactionModeCell8HighRes/", "")
        requestedMPMapTileCells[filename] = -1
    end
end

--Since Paint The Town is meant to be a much faster game mode, we won't save its state in the database, just memory.
function GetPaintTownMapData8(Cell8) -- the painttown map update call.
    --this doesn't get saved to the device at all. Keep it in memory, update it every few seconds.
    netTransfer()
    network.request(serverURL .. "PaintTown/LearnCell8/"  .. Cell8, "GET", PaintTownMapListener) 
end

function PaintTownMapListener(event)
    if (debug) then print("paint the town map event started") end
    if event.status == 200 then 
        netUp() 
    else 
        print("paint the town map listener failed")
        netDown() 
    end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.
    local instanceID = Split(string.gsub(event.url, serverURL .. "PaintTown/LearnCell8/", ""), "/")[1]
    --This one splits each Cell10 via pipe, each sub-vaule by =
    local resultsTable = Split(event.response, "|")
    --Format:
    --Cell10=#color|Cell10=#color

    for cell = 1, #resultsTable do
        local splitData = Split(resultsTable[cell], "=")
        local key = splitData[1]
        if (splitData[2] ~= nil) then
            requestedPaintTownCells[key] = convertColor(splitData[2])
        end
    end
    forceRedraw = true
    if(debug) then print("paint town map event ended") end
end

function ClaimPaintTownCell(Cell10)
    netTransfer()
    network.request(serverURL .. "PaintTown/ClaimCell10/" .. Cell10, "GET", PaintTownClaimListener) 
end

function PaintTownClaimListener(event) --doesnt record any data.
    if event.status == 200 then 
        netUp() 
    else 
        print("paint the town claim failed")
        netDown() 
    end
end