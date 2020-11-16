-- the class for handling sending data to/from the API server
-- NOTE: naming this 'network' overrides the internal library with the same name and breaks everything.
-- TODO:
--also need to work out plan to update saved location type/name data eventually
require("database")
require("helpers") --for Split

--serverURL = "https://localhost:44384/GPSExplore/" -- simulator testing, on the same machine.
--serverURL = "http://192.168.50.247:64374/GPSExplore/" -- local network IISExpress, doesnt work on https due to self-signed certs.
--serverURL = "http://localhost/GPSExploreServerAPI/" -- local network IIS. works on the simulator
--serverURL = "http://192.168.50.247/GPSExploreServerAPI/" -- local network, doesnt work on https due to self-signed certs.
serverURL = "http://ec2-18-189-29-204.us-east-2.compute.amazonaws.com/" --AWS Test server, IP part of address will change each time instance is launched.

--note: GpsExplore/" is now half of it, the other half is MapData/
--local requestedCells = "" this is now in main and global

--In-process change:
--look into changing from downloading a whole 6-cell to pulling areas .01 degree at at time (~4 8-cells at once)
--and request the data when it scrolls onto screen?
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

--replaced by plusCode6 listener.
function plusCode8Listener(event)
    if (debug) then print("plus code 8 event started") end
    if event.status == 200 then netUp() else netDown() end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.

    --This one splits each 10cell via newline.
    local resultsTable = Split(event.response, "\r\n") --windows newlines
    --if (debugNetwork) then print(dump(resultsTable)) end
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
            --print(insertString)
            local results = db:exec(insertString)
            --print(results)
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

    --tell the user we're working
    --had to move this earlier for it to appear.
    --ShowLoadingPopup()

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
            --print(insertString)
            local results = db:exec(insertString)
            --print(results)
        end
    end
    local e2 = db:exec("END TRANSACTION")
    if(debugNetwork) then print("table done") end

    --save these results to the DB.
    --TODO: fix columsn to indicate these are 6 cells that have been downloaded, not 8 cells.
    local updateCmd = "INSERT INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode6 .. "', " .. os.time() .. ")"
    Exec(updateCmd)

    networkReqPending = false 
    forceRedraw = true
    netUp()
    HideLoadingPopup()
end

-- function flexListener(event)
--     if (debugNetwork) then print("flex event response status: " .. event.status) end --these are fairly large, 10k entries isnt weird.
--     if event.status == 200 then netUp() else netDown() end
--     if (event.status ~= 200) then 
--         networkReqPending = false --allow the download to retry on the next event.
--         HideLoadingPopup()
--         return --dont' save invalid results on an error.
--     end 

--     --This one splits each 10cell via newline.
--     local resultsTable = Split(event.response, "\r\n") --windows newlines
--     --print(#resultsTable)
--     --Format:
--     --10cell|name|typeID|size
--     --EX: 86CCXX2248=Local Park|park|12345
  
--     local insertString = ""
--     local insertCount = 0

--     db:exec("BEGIN TRANSACTION") --transactions for multiple inserts are a huge performance boost.
--     for i = 1, #resultsTable do
--         if (resultsTable[i] ~= nil and resultsTable[i] ~= "") then 
--             local data = Split(resultsTable[i], "|") --3 data parts in order
--             data[2] = string.gsub(data[2], "'", "''")--escape data[2] to allow ' in name of places.
--             insertString = "INSERT INTO terrainData (plusCode, name, areatype, MapDataId) VALUES ('" .. data[1] .. "', '" .. data[2] .. "', '" .. data[3] .. "', '" .. data[4] .. "');" --insertString .. 
--             --print(insertString)
--             local results = db:exec(insertString)
--             --print(results)
--         end
--     end
--     local e2 = db:exec("END TRANSACTION")
--     if(debugNetwork) then print("table done") end

--     --save these results to the DB.
--     --TODO: fix columsn to indicate these are 6 cells that have been downloaded, not 8 cells.
--     --local updateCmd = "INSERT INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode6 .. "', " .. os.time() .. ")"
--     --Exec(updateCmd)

--     networkReqPending = false 
--     forceRedraw = true
--     netUp()
--     HideLoadingPopup()
-- end

 --this loads terrain data on an 8cell, loads all 10cells inside at once.
function Get8CellData(lat, lon)
    if networkReqPending == true then return end
    networkReqPending = true
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/Cell8Info/" .. lat .. "/" .. lon) end
    network.request(serverURL .. "MapData/Cell8Info/" .. lat .. "/" .. lon, "GET", plusCode8Listener)
end

function Get8CellData(code8)
    --if networkReqPending == true then return end
    print("starting cell8 data " .. code8)
    local cellAlreadyRequested = string.find(requestedCells, code8 .. ",")
    --print(cellAlreadyRequested)
    if (cellAlreadyRequested ~= nil) then 
        print("or not") 
        return 
    end
    --print("found requested cell")
    networkReqPending = true
    if debugNetwork then print("network: getting 8 cell data " .. code8) end
    requestedCells = requestedCells .. code8 .. ","
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/Cell8Info/" .. code8) end
    network.request(serverURL .. "MapData/Cell8Info/" .. code8, "GET", plusCode8Listener)
end

function Get6CellData(lat, lon)
    if networkReqPending == true then return end
    networkReqPending = true
    netTransfer()
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/Cell6Info/" .. lat .. "/" .. lon) end
    network.request(serverURL .. "MapData/Cell6Info/" .. lat .. "/" .. lon, "GET", plusCode6Listener)
end

function GetSurroundingData(lat, lon)
    if networkReqPending == true then return end
    networkReqPending = true
    netTransfer()
    --ShowLoadingPopup()
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/LearnSurroundingFlex/" .. pluscode6) end
    network.request(serverURL .. "MapData/LearnSurroundingFlex/" .. lat .. "/" .. long .. "/.0025", "GET", flexListener)
end

function Get8CellImage10(plusCode8)
    print("trying 8cell11 download")
    --if networkReqPending == true then return end
    networkReqPending = true
    netTransfer()
    --ShowLoadingPopup()
    --print("past loading popup")
    if (debugNetwork) then print ("getting cell image data via " .. serverURL .. "MapData/8cellbitmap/" .. plusCode8) end
    local params = { response = { filename = plusCode8 .. "-10.png", baseDirectory = system.DocumentsDirectory}}
    network.request(serverURL .. "MapData/8cellBitmap/" .. plusCode8, "GET", image810Listener, params)
end

function Get8CellImage11(plusCode8)
    --print("trying 8cell11 download")
    --print(plusCode8)
    --if networkReqPending == true then return end
    networkReqPending = true
    netTransfer()
    --ShowLoadingPopup()
    --print("past loading popup")
    --if (debugNetwork) then print ("getting cell image data via " .. serverURL .. "MapData/8cellbitmap11/" .. plusCode8) end
    local params = {}
    params.response  = {filename = plusCode8 .. "-11.png", baseDirectory = system.DocumentsDirectory}
    --print("params set")
    network.request(serverURL .. "MapData/8cellBitmap11/" .. plusCode8, "GET", image811Listener, params)
end

function Get10CellImage11(plusCode)
    --print("trying 10cell11 download")
    print("DL image for " .. plusCode)
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
    network.request(serverURL .. "MapData/10cellBitmap11/" .. plusCode, "GET", image1011Listener, params)
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
    --HideLoadingPopup()
    forceRedraw = true
    if event.status == 200 then netUp() else netDown() end
end

--new ARea Control functions
function GetAreaSizes()
end

-- function GetAreaScore(mapdataid)
--     if (debug) then print("getting score for " .. mapdataid) end
--     network.request(serverURL .. "MapData/CalculateMapDataScore/" .. mapdataid, "GET", AreaSizeListener)
-- end

-- function AreaSizeListener(event)
--     if (debug) then print("AreaSize response: " .. event.response .. " " .. event.status) end
--     local scoreResults = Split(event.response, "|")
-- end