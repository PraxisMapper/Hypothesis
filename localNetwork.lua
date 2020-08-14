--the class for handling sending data to/from the API server
--NOTE: naming this 'network' overrides the internal library with the same name and breaks everything.
--TODO:
--leaderboards connection
--OpenStreetMaps stuff (future idea, separate game? should test here anyways)

require("database")

local serverURL = "https://localhost:44384/GPSExplore/" --in my house, on the local network for testing.

function uploadListener(event)
    print("listener fired")
    print(event.isError)
    print(event.status)
    print("response: " .. event.response)
    print("listener ending")
end

function UploadData()
    print("uploading data")
    local uploadURL = serverURL .. "UploadData"
    local params = {}
    local bodyString = "" --the | separated values
    print(uploadURL)

    bodyString = bodyString .. system.getInfo("deviceID") .. "|"
    print(bodyString)
    --cell visits
    local centerData = GetClientData() 
    local trophyDate = ""
    local query = "SELECT boughtOn FROM trophysBought WHERE itemcode = 14"
    local q1Results = Query(query)[1]
    print(q1Results)
    if (q1Results == nil) then
        q1Results = "0"
    end 

    --max speed is next, not yet present until i run and update the db schema.
    bodyString = bodyString .. centerData[4] .. "|" .. q1Results .. "|" ..centerData[2] .."|"

    --get data to match backend setup.
    print(bodyString)
    params.body = bodyString 
    print("sending request")
    network.request(uploadURL, "POST", uploadListener, params) --uploadURL
    print("sent")
end

