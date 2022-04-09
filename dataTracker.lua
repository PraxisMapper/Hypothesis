--a single shared file for specifically handling downloading map tiles and cell data
--This is an attempt to make updating a bigger grid faster by minimizing duplicate work/network calls/etc.

require("helpers") --colorConvert
local composer = require( "composer" ) --for storing variables
require("database")

--this process:
--these tables have a string key for each relevant cell
--key present: this cell has been requested this session
--key absent: this cell has not been requested this session
--0 value: request sent
--1 value: data present (either request completed earlier or data was already present)
-- -1 value: last request failed.
requestedDataCells = {} --these should be Cell8
requestedMapTileCells = {} --these should be Cell10
requestedMPMapTileCells = {} 
requestedPaintTownCells = {} --Should be a table by instance types, since multiple PaintTheTowns could run at once.
requestedGeocacheHints = {}



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
    local imageExists = doesFileExist(Cell8 .. "-11.png", system.CachesDirectory)

    if (requestedMapTileCells[Cell8] == 1 and imageExists) then
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
        print ("getting cell data via " .. serverURL .. "Data/Terrain/" .. code8) 
    end
    --network.request(serverURL .. "Data/Terrain/" .. code8 .. defaultQueryString , "GET", TrackplusCode8Listener)
    table.insert(networkQueue, { url = serverURL .. "Data/Terrain/" .. code8 .. defaultQueryString, verb = "GET", handlerFunc = TrackplusCode8Listener})
    netTransfer()
end

function TrackplusCode8Listener(event)
    --if (debug) then print("plus code 8 event started") end
    print("getting terrain data")
    local plusCode8 = Split(string.gsub(string.gsub(event.url, serverURL .. "Data/Terrain/", ""), defaultQueryString, ""), '?')[1]
    networkQueueBusy = false
    if event.status == 200 then 
        netUp() 
    else 
        netDown(event) 
    end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.

    --This one splits each Cell10 via newline.
    local resultsTable = Split(event.response, "\n") --newlines
    --Format:
    --cell10|name|typeID|mapDataID
    --EX: 82HHWG48=Local Park|4|guid
    print("terrain count:")
    print(#resultsTable)

    --print('loading ' .. #resultsTable .. ' to terrain db')

    --TODO: might need to make unique keys for pluscode and pluscode8, or remove the 'or replace' part of the command.
    db:exec("BEGIN TRANSACTION") --transactions for multiple inserts are a huge performance boost.
    for i = 1, #resultsTable do
        if (resultsTable[i] ~= nil and resultsTable[i] ~= "") then 
            local data = Split(resultsTable[i], "|") --4 data parts in order
            data[2] = string.gsub(data[2], "'", "''")--escape data[2] to allow ' in name of places.
            insertString = "INSERT OR REPLACE INTO terrainData (plusCode, name, areatype, MapDataId) VALUES ('" .. data[1] .. "', '" .. data[2] .. "', '" .. data[3] .. "', '" .. data[4] .. "');" 
            local results = db:exec(insertString)
        end
    end
    local e2 = db:exec("END TRANSACTION")
    print("adding successful call to db")
    --save these results to the DB.
    local updateCmd = "INSERT OR REPLACE INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode8 .. "', '" .. tostring(os.time()) .. "')"
    Exec(updateCmd)
    requestedDataCells[plusCode8] = 1
    forceRedraw = true
end

function TrackerGetCell8Image11(plusCode)
    --print('checking for data on ' .. plusCode)
    if requestedMPMapTileCells[plusCode] == 1 then
        --print('data is' .. requestedMPMapTileCells[plusCode])
        return
    end
    --print('tracker called for ' .. plusCode)

    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.CachesDirectory}
    --network.request(serverURL .. "MapTile/Area/" .. plusCode .. defaultQueryString, "GET", Trackerimage811Listener, params)
    table.insert(networkQueue, { url = serverURL .. "MapTile/Area/" .. plusCode .. defaultQueryString, verb = "GET", handlerFunc = TrackplusCode8Listener, params = params})
    --print('called for mapTiles on ' .. plusCode)
end

function Trackerimage811Listener(event)
    networkQueueBusy = false
    --local filename = string.gsub(event.url, serverURL .. "MapTile/Area/", "")
    local filename = Split(string.gsub(event.url, serverURL .. "MapTile/Area/", ""), '?')[1]
    --print('got mapTiles results for ' .. filename)
    --print(dump(event))
    requestedMPMapTileCells[filename] = nil
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        --requestedMapTileCells[filename] = 1
    else 
        netDown(event) 
        print('Failed to get ' .. filename .. ' from download!')
        --requestedMapTileCells[filename] = -1
    end
end

function GetTeamControlMapTile8(Cell8)
    --print(requestedMPMapTileCells[Cell8])
    if requestedMPMapTileCells[Cell8] == nil or requestedMPMapTileCells[Cell8] == 0 then
        requestedMPMapTileCells[Cell8] = 1
        TrackerGetMPCell8Image11(Cell8)
    else
        print('actually not calling getMACtile')
    end
end

function TrackerGetMPCell8Image11(plusCode)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-AC-11.png", baseDirectory = system.TemporaryDirectory}
    --network.request(serverURL .. "MapTile/AreaPlaceData/" .. plusCode .. "/teamColor/teamColor" .. defaultQueryString, "GET", TrackerMPimage811Listener, params)
    table.insert(networkQueue, { url = serverURL .. "MapTile/AreaPlaceData/" .. plusCode .. "/teamColor/teamColor" .. defaultQueryString, verb = "GET", handlerFunc = TrackerMPimage811Listener, params = params})
    --table.insert(networkQueue, { url = url, verb = "GET", handlerFunc = TrackplusCode8Listener})
end

function TrackerMPimage811Listener(event)
    networkQueueBusy = false
    local plusCode = Split(string.gsub(string.gsub(event.url, serverURL .. "MapTile/AreaPlaceData/", ""), "/teamColor/teamColor", ""), '?')[1]
    --print('got AreaTag image for ' .. plusCode)
    requestedMPMapTileCells[plusCode] = 0
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        --requestedMPMapTileCells[plusCode] = 1
        --print('new maptile saved for ' .. plusCode)
    else 
        netDown(event) 
        print(plusCode .. " errored on MAC tile: " .. event.status)
        --requestedMPMapTileCells[plusCode] = -1
    end
    --requestedMPMapTileCells[plusCode] = nil
end

function GetGeocacheHintData8(Cell8) -- 
    --this doesn't get saved to the device at all. Keep it in memory, update it every few seconds.
    netTransfer()
    network.request(serverURL .. "Data/Area/All/" .. currentPlusCode:sub(1,8) .. defaultQueryString, "GET", geocacheHintListener) 
end

function geocacheHintListener(event)
    if (debug) then print("geocache event started") end
    if event.status == 200 then 
        netUp() 
    else 
        if (debug) then print("geocache hint listener failed") end
        netDown(event) 
        return
    end
    --Format:
    --Cell10|dataTag|dataValue\n
    local resultsTable = Split(event.response, "\n")
    --print('loading to hint memory ' .. #resultsTable)
    --print(event.response)

    for cell = 1, #resultsTable do
        local splitData = Split(resultsTable[cell], "|")
        local key = splitData[1]
        if (splitData[2] == "geocacheHint") then
            requestedGeocacheHints[key] = splitData[3]
        end
    end
    forceRedraw = true
    if(debug) then print("geocache hint event ended") end
end

--Since Paint The Town is meant to be a much faster game mode, we won't save its state in the database, just memory.
--Rename this, since CreatureCollector also uses this.
function GetPaintTownMapData8(Cell8) -- the painttown map update call.
    --this doesn't get saved to the device at all. Keep it in memory, update it every few seconds.
    netTransfer()
    network.request(serverURL .. "Data/Area/All/" .. Cell8 .. defaultQueryString, "GET", PaintTownMapListener) 
end

function PaintTownMapListener(event)
    if (debug) then print("paint the town map event started") end
    if event.status == 200 then 
        netUp() 
    else 
        if (debug) then print("paint the town map listener failed") end
        netDown(event) 
        return
    end
    --Format:
    --Cell10|dataTag|dataValue\r\n
    local resultsTable = Split(event.response, "\n") --NOTE: could be \n or \r\n depending on if server is Windows or Unix.
    print('loading  to PTT memory ' .. #resultsTable)
    print(event.response)

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
    print('claiming ' .. Cell10)
    netTransfer()
    local randomColorSkiaFormat = "42" --start with a fixed alpha value
    randomColorSkiaFormat = randomColorSkiaFormat ..  string.format("%x", math.random(0, 255)) .. string.format("%x", math.random(0, 255)) .. string.format("%x", math.random(0, 255))
    local url = serverURL .. "Data/Area/" .. Cell10 .. "/color/" .. randomColorSkiaFormat .. defaultQueryString
    network.request(url, "PUT", PaintTownClaimListener) 
    requestedPaintTownCells[Cell10] = convertColor(randomColorSkiaFormat)
end

function PaintTownClaimListener(event) --doesnt record any data.
    if event.status == 200 then 
        netUp() 
        --native.showAlert("PTT", "data saved to server")
    else 
        native.showAlert("PTT", "data call to server failed: " .. event.response)
        if (debug) then print("paint the town claim failed") end
        netDown(event) 
    end
end

function GetTeamAssignment()
    local url = serverURL .. "Data/Player/"  .. system.getInfo("deviceID") .. "/team" .. defaultQueryString
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
    local url = serverURL .. "Data/Player/"  .. system.getInfo("deviceID") .. "/team/" .. teamId .. defaultQueryString
    network.request(url, "PUT", DefaultNetCallHandler) 
    if (debug) then print("Team change sent to " .. url) end
    netTransfer()
end

function GetMyScore()
    local url = serverURL .. "Data/Player/"  .. system.getInfo("deviceID") .. "/score" .. defaultQueryString
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
    local url = serverURL .. "Data/ServerBounds" .. defaultQueryString
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

function SendGeocachePublic(text)
    local url = serverURL .. "Data/Area/" .. Cell10 .. "/geocachepublic/" .. text .. defaultQueryString
    network.request(url, "GPU", DefaultNetCallHandler) 
end

function SendGeocacheSecret(text)
    -- set data so it expires in 30 days. Don't overwrite existing data if its not expired.
    local url = serverURL .. "SecureData/Area/" .. Cell10 .. "/geocachesecret/" .. text .. '/2592000' .. defaultQueryString
    network.request(url, "PUT", DefaultNetCallHandler) 
end

function checkTileGeneration(plusCode, styleSet)
    --print("Calling checkTileGen " .. plusCode .. " " .. styleSet .. ".")

    if (styleSet == 'mapTiles') and (requestedMapTileCells[plusCode] == 1) then
        return --only check baseline tiles once per run. Check for updates on next run.
    end

    local url = serverURL .. "MapTile/Generation/" .. plusCode .. "/" ..styleSet .. defaultQueryString
    network.request(url, "GET", tileGenHandler) 
end

function tileGenHandler(event)
    -- pull out values, check DB
    local piece = string.gsub(string.gsub(event.url, defaultQueryString, ""), serverURL .. "MapTile/Generation/", "")
    local pieces = Split(piece, '/')
    local answer = event.response

    if (answer == 'Timed out') then
        --abort this logic!
        return
    end

    --print("tileGenHandler " .. pieces[1] .. " " .. pieces[2] .. " " .. answer)

    local imageExists = false
    if pieces[2] == "mapTiles" then
        imageExists = doesFileExist(pieces[1] .. "-11.png", system.CachesDirectory)
    elseif pieces[2] == "teamColor" then
        imageExists = doesFileExist(pieces[1] .. "-AC-11.png", system.TemporaryDirectory)
    end

    local currentGenQuery =  'SELECT generationId from tileGenerationData WHERE plusCode = "' .. pieces[1] .. '" and styleSet = "' .. pieces[2] .. '"'
    local hasData = false
    local redownload = false


    --loop, but should be 1 result.
    for i, v in ipairs(Query(currentGenQuery)) do
        hasData = true
        if tonumber(v[1]) < tonumber(answer)then
            local exec = 'UPDATE tileGenerationData SET generationId = ' .. answer .. ' WHERE plusCode ="' .. pieces[1] .. '" AND styleSet = "' .. pieces[2] .. '"'
            Exec(exec)
            redownload = true
        else
            --print("same value, no updates")
        end
    end

    if hasData == false then
        local sql = 'INSERT INTO tileGenerationData(plusCode, styleSet, generationId) VALUES ("' .. pieces[1] .. '", "' .. pieces[2] .. '", ' .. answer .. ')'
        Exec(sql)
        redownload = true
    end

    if (imageExists == false) then
        print('redownloading ' .. pieces[1]  .. ' ' .. pieces[2] .. ' because image doesnt exist')
    elseif answer == '-1' then
        print('redownloading ' .. pieces[1] .. ' '.. pieces[2] .. ' because answer was -1')
    elseif redownload then
        print('redownloading ' .. pieces[1] .. ' '.. pieces[2] .. ' because data changed')
    end
    
    redownload = (imageExists == false) or redownload or answer == '-1'
    if redownload then
        if pieces[2] == "mapTiles" then
            TrackerGetCell8Image11(pieces[1])
        elseif pieces[2] == "teamColor" then
            GetTeamControlMapTile8(pieces[1])
        end
    end

    if event.status == 200 and pieces[2] == 'mapTiles' then
        requestedMapTileCells[pieces[1]] = 0
    end
end

networkQueue = {}
networkQueueBusy = false --current idea, check every 50ms if the network queue is busy, if not then call next.

--a quick queue doesnt seem to work better than calling it all at once. 
function nextNetworkQueue()
    networkQueueBusy = true
    netData = networkQueue[1]
    print('firing network queue for ' .. dump(netData))
    network.request(netData.url, netData.verb, netData.handlerFunc, netData.params)
    table.remove(networkQueue, 1)
end

function saveHint(plusCode, hint)
    print("SaveHint")
    local url = serverURL .. "Data/Area/" .. plusCode .. "/geocacheHint/" ..  hint .. defaultQueryString
    network.request(url, "PUT", saveHintHandler) 
    netTransfer()
    --might want to have a handler to update count of hints left.
end

function saveHintHandler(event)
    print("SaveHintHandler")
    local plusCode = Split(string.gsub(string.gsub(event.url, serverURL .. "Data/Area/", ""), "/geocacheHint", ""), '/')[1]
    print(plusCode:sub(1,8))

    if event.status == 200 then
        print("spending")
        spendHint(plusCode:sub(1,8))
        print("spent")
        netUp()
    else
        netDown()
    end
end