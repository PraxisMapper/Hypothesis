-- the class for handling sending data to/from the API server
-- NOTE: naming this 'network' overrides the internal library with the same name and breaks everything.
-- TODO:
-- leaderboards connection
-- OpenStreetMaps stuff (future idea, separate game? should test here anyways)
require("database")

serverURL = "https://localhost:44384/GPSExplore/" -- simulator testing, on the same machine.
--local serverURL = "https://192.168.1.92:44384/GPSExplore/" -- local network, doesnt work due to self-signed certs

function uploadListener(event)
    if (debugNetwork) then
        print("listener fired ")
        print(event.isError)
        print(event.status)
    end
    print("response: " .. event.response)
    print("listener ending")
end

function UploadData()
    print("uploading data")
    local uploadURL = serverURL .. "UploadData"
    local params = {}
    local bodyString = "" -- the | separated values
    print(uploadURL)

    -- bodyString = bodyString .. system.getInfo("deviceID") .. "|"
    -- print(bodyString)
    -- cell visits
    local centerData = GetClientData()
    local trophyDate = ""  
    local query = "SELECT boughtOn FROM trophysBought WHERE itemcode = 14"
    local q1Results = Query(query)[1]
    print(q1Results)
    if (q1Results == nil) then q1Results = "0" end
    if (debugNetwork) then print(dump(centerData)) end

    -- 1           2             3                 4         5     6       7      8       9           10          11
    -- DeviceID|cellVisits|DateFinalTrophyBought|distance|Maxspeed|score|10cells|8cells|timeplayed|totalSpeed|maxAltitude
    -- max speed is next, not yet present until i run and update the db schema.
    bodyString = system.getInfo("deviceID") .. "|" .. centerData[4] .. "|" ..  q1Results .. "|" .. centerData[2] .. "|" .. centerData[6] .. "|"-- ends with maxspeed
    bodyString = bodyString .. centerData[3] .. "|" .. TotalExploredCells() .. "|" .. TotalExplored8Cells() .. "|"
    bodyString = bodyString .. centerData[5] .. "|" .. centerData[7] .. "|" .. centerData[8]

    -- get data to match backend setup.
    if (debugNetwork) then print(bodyString) end
    params.body = bodyString
    if (debugNetwork) then print("sending request") end
    network.request(uploadURL, "POST", uploadListener, params)
    if (debugNetwork) then print("sent") end
end

function leaderboardListener()

end

function GetLeaderboard(id)
    --need to ID leaderboards somewhere.
    if (id == 1) then
        --Most 10cells.
        network.request(serverURL .. "10CellLeaderboard/" .. system.getInfo("deviceID"), "GET", leaderboardListener)

    end


end

 