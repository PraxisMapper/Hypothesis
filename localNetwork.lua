-- the class for handling sending data to/from the API server
-- NOTE: naming this 'network' overrides the internal Solar2d library with the same name and breaks everything.
local composer = require("composer")
require("database")
require("helpers") --for Split



networkReqPending = false

function uploadListener(event)
    if (debugNetwork) then
        print("listener fired ")
        print(event.isError)
        print(event.status)
    end
    print("response: " .. event.response)
    if event.status == 200 then netUp() else netDown() end
    print("upload listener ending")
end

function UploadData()
    netTransfer()
    print("uploading data")
    local uploadURL = serverURL .. "GpsExplore/UploadData"
    local params = {}
    local bodyString = "" -- the | separated values
    print(uploadURL)

    local trophyDate = ""  
    local query = "SELECT boughtOn FROM trophysBought WHERE itemcode = 14"
    local q1Results = Query(query)[1]
    print(q1Results)
    if (q1Results == nil) then q1Results = "0" end

    local q = Query("SELECT * FROM playerData")[1]
    local altSpread = q[8] - q[9]

    -- 1           2             3                 4         5     6       7      8       9           10          11
    -- DeviceID|cellVisits|DateFinalTrophyBought|distance|Maxspeed|score|10cells|8cells|timeplayed|totalSpeed|maxAltitude
    bodyString = system.getInfo("deviceID") .. "|" .. q[4] .. "|" ..  q1Results .. "|" .. q[2] .. "|" .. q[6] .. "|"-- ends with maxspeed
    bodyString = bodyString .. q[3] .. "|" .. TotalExploredCells() .. "|" .. TotalExplored8Cells() .. "|"
    bodyString = bodyString .. q[5] .. "|" .. q[7] .. "|" .. altSpread

    -- get data to match backend setup.
    if (debugNetwork) then print(bodyString) end
    params.body = bodyString
    if (debugNetwork) then print("sending request") end
    network.request(uploadURL, "POST", uploadListener, params)
    if (debugNetwork) then print("sent") end
end

function plusCode8Listener(event)
    if (debug) then print("plus code 8 event started") end
    if event.status == 200 then netUp() else netDown() end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.

    --This one splits each 10cell via newline.
    local resultsTable = Split(event.response, "\r\n") --windows newlines
    print(#resultsTable)
    --Format:
    --line1: the 8cell requested
    --remaining lines: the last 2 digits for a 10cell=name|type
    --EX: 48=Local Park|park

    db:exec("BEGIN TRANSACTION") --transactions for multiple inserts are a huge performance boost.
    local plusCode6 = resultsTable[1] 
    for i = 2, #resultsTable do
        if (resultsTable[i] ~= nil and resultsTable[i] ~= "") then 
            local data = Split(resultsTable[i], "|") --3 data parts in order
            data[2] = string.gsub(data[2], "'", "''")--escape data[2] to allow ' in name of places.
            insertString = "INSERT INTO terrainData (plusCode, name, areatype, MapDataId) VALUES ('" .. resultsTable[1] .. data[1] .. "', '" .. data[2] .. "', '" .. data[3] .. "', '" .. data[4] .. "');" --insertString .. 
            local results = db:exec(insertString)
        end
    end
    local e2 = db:exec("END TRANSACTION")
    if(debugNetwork) then print("table done") end

    --save these results to the DB.
    print("saving info to db")
    local updateCmd = "INSERT INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode6 .. "', " .. os.time() .. ")"
    Exec(updateCmd)
    print("data inserted")
    requestedCells = requestedCells:gsub(plusCode6 .. ",", "")

    netUp()
    networkReqPending = false 
end

function plusCode6Listener(event)
    if (debugNetwork) then print("plus code 6 event response status: " .. event.status) end --these are fairly large, 10k entries isnt weird.
    if event.status == 200 then netUp() else netDown() end
    if (event.status ~= 200) then 
        networkReqPending = false --allow the download to retry on the next event.
        HideLoadingPopup()
        return --dont' save invalid results on an error.
    end 

    --This one splits each 10cell via newline.
    local resultsTable = Split(event.response, "\r\n") --windows newlines
    --print(#resultsTable)
    --Format:
    --line1: the 6cell requested
    --remaining lines: the last 4 digits for a 10cell=name|type|mapDataId (for Area Control requests)
    --EX: 2248=Local Park|park|12345
  
    local insertString = ""
    local insertCount = 0

    db:exec("BEGIN TRANSACTION") --transactions for multiple inserts are a huge performance boost.
    local plusCode6 = resultsTable[1] 
    for i = 2, #resultsTable do
        if (resultsTable[i] ~= nil and resultsTable[i] ~= "") then 
            local data = Split(resultsTable[i], "|") --3 data parts in order
            data[2] = string.gsub(data[2], "'", "''")--escape data[2] to allow ' in name of places.
            insertString = "INSERT INTO terrainData (plusCode, name, areatype, MapDataId) VALUES ('" .. resultsTable[1] .. data[1] .. "', '" .. data[2] .. "', '" .. data[3] .. "', '" .. data[4] .. "');" --insertString .. 
            local results = db:exec(insertString)
        end
    end
    local e2 = db:exec("END TRANSACTION")
    if(debugNetwork) then print("table done") end

    --save these results to the DB.
    local updateCmd = "INSERT INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode6 .. "', " .. os.time() .. ")"
    Exec(updateCmd)

    networkReqPending = false 
    forceRedraw = true
    netUp()
    HideLoadingPopup()
end
 --this loads terrain data on an 8cell, loads all 10cells inside at once.
function Get8CellData(lat, lon)
    if networkReqPending == true then return end
    networkReqPending = true
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/LearnCell8/" .. lat .. "/" .. lon) end
    network.request(serverURL .. "MapData/LearnCell8/" .. lat .. "/" .. lon, "GET", plusCode8Listener)
end

function Get8CellData(code8)
    print("starting cell8 data " .. code8)
    local cellAlreadyRequested = string.find(requestedCells, code8 .. ",")
    if (cellAlreadyRequested ~= nil) then 
        print(code8 .. " exists, exiting") 
        return 
    end
    networkReqPending = true
    if debugNetwork then print("network: getting 8 cell data " .. code8) end
    requestedCells = requestedCells .. code8 .. ","
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/LearnCell8/" .. code8) end
    network.request(serverURL .. "MapData/LearnCell8/" .. code8, "GET", plusCode8Listener)
end

function Get6CellData(lat, lon)
    if networkReqPending == true then return end
    networkReqPending = true
    netTransfer()
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/LearnCell6/" .. lat .. "/" .. lon) end
    network.request(serverURL .. "MapData/LearnCell6/" .. lat .. "/" .. lon, "GET", plusCode6Listener)
end

function GetSurroundingData(lat, lon)
    if networkReqPending == true then return end
    networkReqPending = true
    netTransfer()
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/LearnSurroundingFlex/" .. pluscode6) end
    network.request(serverURL .. "MapData/LearnSurroundingFlex/" .. lat .. "/" .. long .. "/.0025", "GET", flexListener)
end

function Get8CellImage10(plusCode8)
    print("trying 8cell11 download")
    networkReqPending = true
    netTransfer()
    if (debugNetwork) then print ("getting cell image data via " .. serverURL .. "MapData/DrawCell8/" .. plusCode8) end
    local params = { response = { filename = plusCode8 .. "-10.png", baseDirectory = system.CachesDirectory}}
    network.request(serverURL .. "MapData/DrawCell8/" .. plusCode8, "GET", image810Listener, params)
end

function Get8CellImage11(plusCode8)
    networkReqPending = true
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode8 .. "-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "MapData/DrawCell8Highres/" .. plusCode8, "GET", image811Listener, params)
end

function Get10CellImage11(plusCode)
    print("DL image for " .. plusCode)
    networkReqPending = true
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "MapData/DrawCell10Highres/" .. plusCode, "GET", image1011Listener, params)
end

function image810Listener(event)
    if (debug) then print("8cell10 listener fired") end
    HideLoadingPopup()
    forceRedraw = true
    if event.status == 200 then netUp() else netDown() end
end

function image811Listener(event)
    if (debug) then print("8cell11 listener fired") end
    HideLoadingPopup()
    forceRedraw = true
    if event.status == 200 then netUp() else netDown() end
end

function image1011Listener(event)
    if (debug) then print("10cell11 listener fired:" .. event.status) end
    forceRedraw = true
    if event.status == 200 then netUp() else netDown() end
end

function GetTeamAssignment()
    print("getting team")
    local url = serverURL .. "PlayerContent/AssignTeam/"  .. system.getInfo("deviceID")
    network.request(url, "GET", GetTeamAssignmentListener)
    if (debug) then print("Team request sent to " .. url) end
end

function GetTeamAssignmentListener(event)
    if (debug) then 
        print("Team listener fired") 
        print(event.status)
    end
    if event.status == 200 then
        composer.setVariable("faction", event.response)
    end
    if (debug) then print("Team Assignment done") end
end
