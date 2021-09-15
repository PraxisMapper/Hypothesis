--a single shared file for specifically handling downloading map tiles and cell data
--This is an attempt to make updating a bigger grid faster by minimizing duplicate work/network calls/etc.

require("helpers") --colorConvert
local composer = require( "composer" ) --for storing variables


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

defaultQueryString = "?PraxisAuthKey=testingKey" --lazy easier way to authenticate
headers = {}
headers["PraxisAuthKey"] = "testingKey" --the proper way to authenticate

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
        print ("getting cell data via " .. serverURL .. "Data/GetPlusCodeTerrainData/" .. code8) 
    end
    network.request(serverURL .. "Data/GetPlusCodeTerrainData/" .. code8 .. defaultQueryString , "GET", TrackplusCode8Listener)
    netTransfer()
end

function TrackplusCode8Listener(event)
    --if (debug) then print("plus code 8 event started") end
    if event.status == 200 then 
        netUp() 
    else 
        netDown(event) 
    end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.

    --This one splits each Cell10 via newline.
    local resultsTable = Split(event.response, "\r\n") --windows newlines
    --Format:
    --cell10|name|typeID|mapDataID
    --EX: 82HHWG48=Local Park|4|guid

    db:exec("BEGIN TRANSACTION") --transactions for multiple inserts are a huge performance boost.
    for i = 1, #resultsTable do
        if (resultsTable[i] ~= nil and resultsTable[i] ~= "") then 
            local data = Split(resultsTable[i], "|") --4 data parts in order
            data[2] = string.gsub(data[2], "'", "''")--escape data[2] to allow ' in name of places.
            insertString = "INSERT INTO terrainData (plusCode, name, areatype, MapDataId) VALUES ('" .. data[1] .. "', '" .. data[2] .. "', '" .. data[3] .. "', '" .. data[4] .. "');" 
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

function TrackerGetCell8Image11(plusCode)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "MapTile/DrawPlusCode/" .. plusCode .. defaultQueryString, "GET", Trackerimage811Listener, params)
end

function Trackerimage811Listener(event)
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "MapTile/DrawPlusCode/", "")
        requestedMapTileCells[filename] = 1
    else 
        netDown(event) 
        local filename = string.gsub(event.url, serverURL .. "MapTile/DrawPlusCode/", "")
        requestedMapTileCells[filename] = -1
    end
end

function GetTeamControlMapTile8(Cell8)
    --print("getting AC tile " .. Cell8)
    if (requestedMPMapTileCells[cell8] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMPMapTileCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell8 .. "-AC-11.png", system.TemporaryDirectory)
        if (dataPresent == true) then --use local data.
            requestedMPMapTileCells[Cell8] = 1
            return
        end
        requestedMPMapTileCells[Cell8] = 0
        TrackerGetMPCell8Image11(Cell8)
     end

     if (status == -1) then --retry a failed download.
        requestedMPMapTileCells[Cell8] = 0
        TrackerGetMPCell8Image11(Cell8)
     end
end


function TrackerGetMPCell8Image11(plusCode)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-AC-11.png", baseDirectory = system.TemporaryDirectory}
    network.request(serverURL .. "MapTile/DrawPlusCodeCustomElements/" .. plusCode .. "/teamColor/teamColor" .. defaultQueryString, "GET", TrackerMPimage811Listener, params)
end

function TrackerMPimage811Listener(event)
    local plusCode = string.gsub(string.gsub(event.url, serverURL .. "MapTile/DrawPlusCodeCustomElements/", ""), "/teamColor/teamColor", "")
    --if (debug) then print("got data for " ..  plusCode) end
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        requestedMPMapTileCells[plusCode] = 1
    else 
        netDown(event) 
        print(plusCode .. " errored on MAC tile: " .. event.status)
        requestedMPMapTileCells[plusCode] = -1
    end
end

--Since Paint The Town is meant to be a much faster game mode, we won't save its state in the database, just memory.
function GetPaintTownMapData8(Cell8) -- the painttown map update call.
    --this doesn't get saved to the device at all. Keep it in memory, update it every few seconds.
    netTransfer()
    network.request(serverURL .. "Data/GetAllDataInPlusCode/" .. Cell8 .. defaultQueryString, "GET", PaintTownMapListener) 
end

function PaintTownMapListener(event)
    if (debug) then print("paint the town map event started") end
    if event.status == 200 then 
        netUp() 
    else 
        if (debug) then print("paint the town map listener failed") end
        netDown(event) 
    end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.
    --Format:
    --Cell10|dataTag|dataValue\r\n
    local resultsTable = Split(event.response, "\r\n")
    
    for cell = 1, #resultsTable do
        local splitData = Split(resultsTable[cell], "|")
        local key = splitData[1]
        if (splitData[2] == "color") then
            requestedPaintTownCells[key] = convertColor(splitData[3])
        end
    end
    forceRedraw = true
    if(debug) then print("paint town map event ended") end
end

function ClaimPaintTownCell(Cell10)
    netTransfer()
    local randomColorSkiaFormat = "42" --start with a fixed alpha value
    randomColorSkiaFormat = randomColorSkiaFormat ..  string.format("%x", math.random(0, 255)) .. string.format("%x", math.random(0, 255)) .. string.format("%x", math.random(0, 255))
    local url = serverURL .. "Data/SetPlusCodeData/" .. Cell10 .. "/color/" .. randomColorSkiaFormat .. defaultQueryString
    network.request(url, "GET", PaintTownClaimListener) 
end

function PaintTownClaimListener(event) --doesnt record any data.
    if event.status == 200 then 
        netUp() 
    else 
        if (debug) then print("paint the town claim failed") end
        netDown(event) 
    end
end

function GetTeamAssignment()
    local url = serverURL .. "Data/GetPlayerData/"  .. system.getInfo("deviceID") .. "/team" .. defaultQueryString
    if (debug) then print("Team request sent to " .. url) end
    network.request(url, "GET", GetTeamAssignmentListener)
    netTransfer()
end

function GetTeamAssignmentListener(event)
    if (debug) then 
        print("Team listener fired") 
        print(event.status)
    end
    if event.status == 200 then
        factionID = tonumber(event.response)
        if (factionID == 0 or factionID == nil) then
            factionID = math.random(1, 3)
            SetTeamAssignment(factionID)
        end
        composer.setVariable("faction", factionID)
        netUp()
    else
        netDown(event)
    end
    if (debug) then print("Team Assignment done") end
end

function SetTeamAssignment(teamId)
    local url = serverURL .. "Data/SetPlayerData/"  .. system.getInfo("deviceID") .. "/team/" .. teamId .. defaultQueryString
    network.request(url, "GET", nil) --I don't need a result from this.
    if (debug) then print("Team change sent to " .. url) end
    netTransfer()
end

function GetMyScore()
    local url = serverURL .. "Data/GetPlayerData/"  .. system.getInfo("deviceID") .. "/score" .. defaultQueryString
    network.request(url, "GET", GetMyScoreListener) 
    netTransfer()
end

function GetMyScoreListener(event)
    if (event.status == 200) then
        composer.setVariable("myScore", event.response)
        netUp()
    else
        netDown(event)
    end
end

function GetServerBounds()
    local url = serverURL .. "Data/GetServerBounds" .. defaultQueryString
    network.request(url, "GET", GetServerBoundsListener) 
    netTransfer()
end

function GetServerBoundsListener(event)
    if (event.status == 200) then
        local boundValues = Split(event.response, "|") --in clockwise order, S/W/N/E
        serverBounds["south"] = tonumber(boundValues[1])
        serverBounds["west"] = tonumber(boundValues[2])
        serverBounds["north"] = tonumber(boundValues[3])
        serverBounds["east"] = tonumber(boundValues[4])
        netUp()
    else
        netDown(event)
    end
end