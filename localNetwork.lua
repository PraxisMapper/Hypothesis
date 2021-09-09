-- the class for handling sending data to/from the API server
-- NOTE: naming this 'network' overrides the internal Solar2d library with the same name and breaks everything.
local composer = require("composer")
require("database")
require("helpers") --for Split

serverURL = ""

function plusCode8Listener(event)
    if (debug) then print("plus code 8 event started") end
    if event.status == 200 then netUp() else netDown() end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.

    --This one splits each cell10 via newline.
    local resultsTable = Split(event.response, "\r\n") --windows newlines
    --Format:
    --line1: the cell8 requested
    --remaining lines: the last 2 digits for a cell10=name|type
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
    local updateCmd = "INSERT INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode6 .. "', " .. os.time() .. ")"
    Exec(updateCmd)
    requestedCells = requestedCells:gsub(plusCode6 .. ",", "")

    netUp()
end

function GetCell8Data(code8)
    local cellAlreadyRequested = string.find(requestedCells, code8 .. ",")
    if (cellAlreadyRequested ~= nil) then 
        return 
    end
    if debugNetwork then print("network: getting 8 cell data " .. code8) end
    requestedCells = requestedCells .. code8 .. ","
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "Data/GetPlusCodeTerrainData/" .. code8) end
    network.request(serverURL .. "MapData/LearnCell8/" .. code8, "GET", plusCode8Listener)
    netTransfer()
end

function GetCell8Image10(plusCode8)
    netTransfer()
    if (debugNetwork) then print ("getting cell image data via " .. serverURL .. "MapData/DrawCell8/" .. plusCode8) end
    local params = { response = { filename = plusCode8 .. "-10.png", baseDirectory = system.CachesDirectory}}
    network.request(serverURL .. "MapData/DrawCell8/" .. plusCode8, "GET", image810Listener, params)
end

function GetCell8Image11(plusCode8)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode8 .. "-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "MapData/DrawCell8Highres/" .. plusCode8, "GET", image811Listener, params)
end

function image810Listener(event)
    forceRedraw = true
    if event.status == 200 then netUp() else netDown() end
end

function image811Listener(event)
    forceRedraw = true
    if event.status == 200 then netUp() else netDown() end
end

function image1011Listener(event)
    forceRedraw = true
    if event.status == 200 then netUp() else netDown() end
end
