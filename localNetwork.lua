-- the class for handling sending data to/from the API server
-- NOTE: naming this 'network' overrides the internal library with the same name and breaks everything.
-- TODO:
-- leaderboards connection
-- OpenStreetMaps stuff (pending a more-final schema)
require("database")
require("helpers") --for SPlit

--serverURL = "https://localhost:44384/GPSExplore/" -- simulator testing, on the same machine.
--serverURL = "http://192.168.1.92:64374/GPSExplore/" -- local network IISExpress, doesnt work on https due to self-signed certs.
--serverURL = "http://localhost/GPSExploreServerAPI/GpsExplore/" -- local network IIS. works on the simulator
serverURL = "http://192.168.1.92/GPSExploreServerAPI/" -- local network, doesnt work on https due to self-signed certs.
--note: GpsExplore/" is now half of it, the other half is MapData/

function uploadListener(event)
    if (debugNetwork) then
        print("listener fired ")
        print(event.isError)
        print(event.status)
    end
    print("response: " .. event.response)
    networkResults = event.response
    print("listener ending")
end

function UploadData()
    print("uploading data")
    local uploadURL = serverURL .. "GpsExplore/UploadData"
    local params = {}
    local bodyString = "" -- the | separated values
    print(uploadURL)

    -- bodyString = bodyString .. system.getInfo("deviceID") .. "|"
    -- print(bodyString)
    -- cell visits
    --local centerData = GetClientData() --all of this looked right, but it doesnt give the right data out sooooo.....
    local trophyDate = ""  
    local query = "SELECT boughtOn FROM trophysBought WHERE itemcode = 14"
    local q1Results = Query(query)[1]
    print(q1Results)
    if (q1Results == nil) then q1Results = "0" end
    --if (debugNetwork) then print(dump(centerData)) end

    local q = Query("SELECT * FROM playerData")[1]
    --dbInfo.text = "distance:" .. q[2] .." points:" .. q[3]  .. " cells:" ..q[4] .. " playtime:" ..q[5] .. " maxSpeed:" ..q[6] .. " totalSpeed:" .. q[7] .. " maxalt:" ..q[8]
    --minalt: [q9]
    local altSpread = q[8] - q[9]

    -- 1           2             3                 4         5     6       7      8       9           10          11
    -- DeviceID|cellVisits|DateFinalTrophyBought|distance|Maxspeed|score|10cells|8cells|timeplayed|totalSpeed|maxAltitude
    -- max speed is next, not yet present until i run and update the db schema.
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

function leaderboardListener()
    --Update the screen. Might need moved to the scene file.

end

function GetLeaderboard(id)
    --need to ID leaderboards somewhere.
    if (id == 1) then
        --Most 10cells.
        network.request(serverURL .. "GpsExplore/10CellLeaderboard/" .. system.getInfo("deviceID"), "GET", leaderboardListener)
    end
    if (id == 2) then
        --Most 8cells.
        network.request(serverURL .. "GpsExplore/8CellLeaderboard/" .. system.getInfo("deviceID"), "GET", leaderboardListener)
    end
    if (id == 3) then
        --Hightest score
        network.request(serverURL .. "GpsExplore/ScoreLeaderboard/" .. system.getInfo("deviceID"), "GET", leaderboardListener)
    end
    if (id == 4) then
        --Most distance 
        network.request(serverURL .. "GpsExplore/DistanceLeaderboard/" .. system.getInfo("deviceID"), "GET", leaderboardListener)
    end
    if (id == 5) then
        --Most play time
        network.request(serverURL .. "GpsExplore/TimeLeaderboard/" .. system.getInfo("deviceID"), "GET", leaderboardListener)
    end
    if (id == 6) then
        --Highest avg speed
        network.request(serverURL .. "GpsExplore/AvgSpeedLeaderboard/" .. system.getInfo("deviceID"), "GET", leaderboardListener)
    end
    if (id == 7) then
        --final Trophy 
        network.request(serverURL .. "GpsExplore/TrophiesLeaderboard/" .. system.getInfo("deviceID"), "GET", leaderboardListener)
    end
    if (id == 8) then
        --Altitude spread Trophy 
        network.request(serverURL .. "GpsExplore/AltitudeLeaderboard/" .. system.getInfo("deviceID"), "GET", leaderboardListener)
    end
end

function plusCodeListener(event)
    print("plus code event response: " .. event.response)
    if (str.length(event.response) == 10) then
        locationList[pluscode] = ""
        return
    end

    --TODO: move GPS starting point manually to somewhere that isn't boring like the default.
    --See if this fires off correctly.
    local eventData = Split(event.response, "=")
    --event data should now be
    --1: pluscode
    --2+: name|type
    --lack of 2+ means its nothing special. 
    print("plus code has properties!")
    local areaTypes = #eventData
    locationList[eventData[1]] = {eventData[2]}
end

function GetCellData(pluscode)
    print ("getting cell data via " .. serverURL .. "MapData/CellData/" .. pluscode:sub(1,8) .. pluscode:sub(10,11))
    if (locationList[pluscode]) == nil then
        network.request(serverURL .. "MapData/CellData/" .. pluscode:sub(1,8) .. pluscode:sub(10,11), "GET", plusCodeListener)
    end
    return (locationList[pluscode])
end

 