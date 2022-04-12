
-- the minimum stuff to get a scene with maptiles going. Copy and build upon it for new modes with maptiles.
local composer = require("composer")
local scene = composer.newScene()

local json = require("json")
require("UIParts")
require("database")
require("dataTracker")
require("plusCodes")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local cellCollection = {} -- main background map tiles
local creaturesOnMap = {} -- the icons for creatures drawn on top of map tiles.
local wildCreatures ={} --creature collector entries on the visible map.
local mostRecentCreatures = {} -- last downloaded set of data for each Cell8
local gridzoom = 2 -- 1, 2, 3.
local creatureIcons = {}
local caughtCreatures = {} --list of decimal uid values from spawned creatures we walked into.

local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end

local function ShowCreatureList()
    composer.showOverlay("creatureList")
end

local deviceId = system.getInfo("deviceID")

-- current TODOS:
-- catch a creature when you're in the same cell10 as it, and add its uid to the list of caught creatures. READY FOR TEST ON DEVICE.
-- still need to remove previously found creatures from display. READY FOR TEST ON DEVICE
-- Still need a list of creatures found and counts of times seen, probably a separate scene. READY FOR TEST ON DEVICE

--valid terrain-gameplay options:
-- university, retail, tourism, historical, building, water, wetland, park, beach, natureReserve, cemetery, trail,
--additional styles that are probably poor choices:
--tertiary, motorway, primary, secondary, admin, parking, greenspace, alsobeach, darkgreenspace, industrial, residential, greyFill
--reasoning: roads will be highly common in a lot of areas, and could overwhelm other spawns. The color areas are places that aren't really interactable.
--Industrial areas are poor places to walk and play, and residential is a common tag that isn't used evenly across a map.
--Admin is more or less the 'default' result, since essentially every area will have some kind of city/county/state/country area attached to it, and this picks the smallest of those.

--LUA limit: strings must start with a letter, so I can't save "86HW" as a key in a table this way. Adding an x to areas, i will need to :sub() that out later.

--initial plan: give each creature 5 points in terrain spawn slots. Most should have an entry in area for the whole state (86).
--some should be limited to a region of the state. AreaSpawns are added to the table after terrain, so they may need different numbers since terrain will have up to 400 entries.
--I have 4 region-specific entries here to demonstrate how to set those up client-side (a server-side app might be able to attach it to specific admin areas, perhaps.)
--and 4 entries that only spawn in their terrain types.
defaultConfig ={
    creaturesPerCell8 = 12,
    minWalkableSpacesOnSpawn = 3,
    minOtherSpacesOnSpawn =3,
    creatureCountToRespawn = 3,
    creatureDurationMin = 30,
    creatureDurationMax = 60,
    creatures = {
        -- These are CC-NC-BY, need to credit Pheonixsong at https://phoenixdex.alteredorigin.net
        Acafia = { name ="Acafia", type1 ="Grass", type2 = "", imageName ="themables/CreatureImages/acafia.png", terrainSpawns = {park = 3, natureReserve = 1, trail = 1}, areaSpawns = {} },
        Acceleret = { name ="Acceleret", type1 ="Normal", type2 = "Flying", imageName ="themables/CreatureImages/acceleret.png", terrainSpawns ={}, areaSpawns = {x86HQ =1, x86HR = 1, x86HV =1, x86GQ =1,}, }, -- toledo area
        Aeolagio = { name ="Aeolagio", type1 ="Water", type2 = "Poison", imageName ="themables/CreatureImages/aeolagio.png", terrainSpawns ={water = 2, wetland = 1, beach = 2}, areaSpawns = {x86 = 1}, },
        Bandibat = { name ="Bandibat", type1 ="Electric", type2 = "Dark", imageName ="themables/CreatureImages/bandibat.png", terrainSpawns ={building = 5}, areaSpawns = {x86 = 1}, },
        Belmarine = { name ="Belmarine", type1 ="Bug", type2 = "Water", imageName ="themables/CreatureImages/belmarine.png", terrainSpawns ={water = 2, beach = 2, natureReserve = 1, }, areaSpawns = {x86 = 1}, },
        Bojina = { name ="Bojina", type1 ="Ghost", type2 = "", imageName ="themables/CreatureImages/bojina.png", terrainSpawns ={cemetery = 5}, areaSpawns = {x86 = 1}, },
        Caslot = { name ="Caslot", type1 ="Dark", type2 = "Fairy", imageName ="themables/CreatureImages/caslot.png", terrainSpawns ={tourism = 3, building = 2}, areaSpawns = {x86 = 1}, },
        Cindigre = { name ="Cindigre", type1 ="Fire", type2 = "", imageName ="themables/CreatureImages/cindigre.png", terrainSpawns ={}, areaSpawns = {x86HW = 1, x86HX = 1, x86GW =1, x86GX =1, x86FX = 1, x86FW =1}, }, --cleveland area
        Curlsa = { name ="Curlsa", type1 ="Fairy", type2 = "", imageName ="themables/CreatureImages/curlsa.png", terrainSpawns ={university = 2, tourism = 2, historical = 1}, areaSpawns = {x86 = 1}, },
        Decicorn = { name ="Decicorn", type1 ="Poison", type2 = "", imageName ="themables/CreatureImages/decicorn.png", terrainSpawns ={wetland = 2, retail = 3}, areaSpawns = {x86 = 1}, },
        Dauvespa = { name ="Dauvespa", type1 ="Bug", type2 = "Ground", imageName ="themables/CreatureImages/dauvespa.png", terrainSpawns ={retail = 3, trail = 2}, areaSpawns = {}, },
        Drakella = { name ="Drakella", type1 ="Water", type2 = "Grass", imageName ="themables/CreatureImages/drakella.png", terrainSpawns ={water = 1, park = 1, natureReserve = 1, wetland = 1, beach = 1}, areaSpawns = {x86 = 1}, },
        Eidograph = { name ="Eidograph", type1 ="Ghost", type2 = "Psychic", imageName ="themables/CreatureImages/eidograph.png", terrainSpawns ={cemetery = 7, }, areaSpawns = {x86 = 1}, },
        Encanoto = { name ="Encanoto", type1 ="Psychic", type2 = "", imageName ="themables/CreatureImages/encanoto.png", terrainSpawns ={university = 4, historical = 1}, areaSpawns = {x86 = 1}, },
        Faintrick = { name ="Faintrick", type1 ="Normal", type2 = "", imageName ="themables/CreatureImages/faintrick.png", terrainSpawns ={}, areaSpawns = {x86GR =1, x86GV = 1, x86FR =1, x86FV =1, }, }, -- columbus area
        Galavena = { name ="Galavena", type1 ="Rock", type2 = "Psychic", imageName ="themables/CreatureImages/galavena.png", terrainSpawns ={historical = 3, university = 2}, areaSpawns = {x86 = 1}, },
        Grotuille = { name ="Grotuille", type1 ="Water", type2 = "Rock", imageName ="themables/CreatureImages/grotuille.png", terrainSpawns ={beach = 3, water = 1, historical = 1}, areaSpawns = {x86 = 1}, },
        Gumbwaal = { name ="Gumbwaal", type1 ="Normal", type2 = "", imageName ="themables/CreatureImages/gumbwaal.png", terrainSpawns ={}, areaSpawns = {x86FQ =1, x86CQ =1, x86CR =1, x86CV =1}, }, -- cincinnatti area
        Mandragoon = { name ="Mandragoon", type1 ="Grass", type2 = "Dragon", imageName ="themables/CreatureImages/mandragoon.png", terrainSpawns ={park = 2, trail = 3}, areaSpawns = {}, },
        Ibazel = { name ="Ibazel", type1 ="Dark", type2 = "", imageName ="themables/CreatureImages/ibazel.png", terrainSpawns ={building = 5}, areaSpawns = {x86 = 1}, },
        Makappa = { name ="Makappa", type1 ="Ice", type2 = "Fire", imageName ="themables/CreatureImages/makappa.png", terrainSpawns ={water = 1, retail = 1, wetland = 1, beach = 1, cemetery = 1}, areaSpawns = {}, },
        Pyrobin = { name ="Pyrobin", type1 ="Fire", type2 = "Fairy", imageName ="themables/CreatureImages/pyrobin.png", terrainSpawns ={university = 3, historical = 2, tourism = 1}, areaSpawns = {x86 = 1}, },
        Rocklantis = { name ="Rocklantis", type1 ="Water", type2 = "Fighting", imageName ="themables/CreatureImages/rocklantis.png", terrainSpawns ={water = 2, beach = 2, building = 1}, areaSpawns = {x86 = 1}, },
        Strixlan = { name ="Strixlan", type1 ="Dark", type2 = "Flying", imageName ="themables/CreatureImages/strixlan.png", terrainSpawns ={building = 3, park = 2}, areaSpawns = {x86 = 1}, },
        Tinimer = { name ="Tinimer", type1 ="Bug", type2 = "", imageName ="themables/CreatureImages/tinimer.png", terrainSpawns ={retail = 5}, areaSpawns = {x86 = 1}, },
        Vanitarch = { name ="Vanitarch", type1 ="Bug", type2 = "Fairy", imageName ="themables/CreatureImages/vanitarch.png", terrainSpawns ={retail =2, university = 1, historical = 1, tourism = 1}, areaSpawns = {x86 = 1}, },
        Vaquerado = { name ="Vaquerado", type1 ="Bug", type2 = "Ground", imageName ="themables/CreatureImages/vaquerado.png", terrainSpawns ={trail = 4, retail = 1}, areaSpawns = {x86 = 1}, },
    }
}

terrainSpawns = {}  --{ terrain = { A, A, B, B, C}, }
areaSpawns = {} --{area = {A, B, C, D}}
function buildSpawnTable()
    print("building spawn")
    for i,m in pairs(defaultConfig.creatures) do
        for k,v in pairs(m.terrainSpawns) do
            for i = 1, v do
                if terrainSpawns[k] == nil then
                    terrainSpawns[k] = {}
                end
                table.insert(terrainSpawns[k], m.name)
            end
        end

        for k,v in pairs(m.areaSpawns) do
            for i = 0, v do
                if areaSpawns[k] == nil then
                    areaSpawns[k] = {}
                end
                table.insert(areaSpawns[k], m.name)
            end
        end
        print("done with " .. m.name)
    end

    print(dump(terrainSpawns))
    print(dump(areaSpawns))

    --I could save these tables into RAM in another table, and keep attempting to generate them until they exist each updateLocal loop
    -- local thisTable = generateSpawnTableForCell8(currentPlusCode:sub(1,8))
    -- print("starting pulls")
    -- for i =0, defaultConfig.creaturesPerCell8 do
    --     local nextCreature = defaultConfig.creatures[thisTable[math.random(1, #thisTable)]]
    --     nextCreature.duration = math.random(1800, 3600)
    --     --print(dump(nextCreature))
    --     --pick area.
    --     --TODO: follow rules for placement. (min 3 on tertiary/trail, min 3 NOT on those, don't overwrite existing creatures)
    --     local rollX = math.random(1,20)
    --     local rollY = math.random(1,20)
    --     local areaSpawned = currentPlusCode:sub(1,8) .. CODE_ALPHABET_:sub(rollY, rollY) .. CODE_ALPHABET_:sub(rollX, rollX)
    --     --print(areaSpawned)
    --     --TODO: custom handler for this.
    --     local data = json.encode(nextCreature)
    --     local params = {}
    --     params.body = data
    --     table.insert(networkQueue, {url = serverURL .. "Data/Area/" .. areaSpawned .."/creature/noval/" .. nextCreature.duration ..defaultQueryString, verb="PUT", handlerFunc = spawnCreatureToServerHandler, params = params})
    -- end
end

function spawnCreatureToServerHandler(event)
    networkQueueBusy = false
end

function generateSpawnTableForCell8(plusCode8)
    -- need terrain info for this cell8
    print("generating spawn table for " .. plusCode8)
    local sql1 = "SELECT * FROM dataDownloaded WHERE pluscode8 = '" .. plusCode8 .. "'"
    print("A")
    results = Query(sql1)
    print("B")
    if (#results <= 0) then
        print("exit early")
        return -- We will check again in a second to see if we've pulled this data yet.
    end
    print("C")

    print("have data locally")

    local sql2 = "SELECT areaType FROM terrainData WHERE plusCode LIKE '" .. plusCode8 .. "%'"
    results = Query(sql2)

    print("have info loaded ")
    print(#results)
    local resultsTable = {}

    for k,d in pairs(results) do
        --print(dump(d))
        if terrainSpawns[d] ~= nil then
            --skip nulls, we dont have any entries for this terrain type in our core table.
            local dataToAdd = terrainSpawns[d]
            for k, entry in dataToAdd do
                --print("adding entry ")
                --print(entry)
                table.insert(resultsTable, entry)
            end
        end
    end
    print("past terrain data")

    -- check area table, add those entries to the end.
    for k,v in pairs(areaSpawns) do
        --k is x[PLUSCODE], so i need to pull the x out for a search.
        if plusCode8:find(k:sub(2, #k)) ~= nil then
            for i, entry in ipairs(v) do
                table.insert(resultsTable, entry)
            end
        end
    end
    print("past area table")

    print(dump(resultsTable))

    return resultsTable
end

-- This chain of functions should create the Creaturecollector data on the server if its missing.
function ccSetupCheck()
    print("ccsetupcheck")
    network.request(serverURL .. "Data/Global/ccSetup" .. defaultQueryString, "GET", cc1Listener)
end

local uploadPicsLeft = 0
function cc1Listener(event)
    --Response meanings:
    --blank: server hasn't been setup. Claim the right to bootstrap up CC mode
    --a player ID: this player has claimed to be running setup, check their ID to see if its still reserved or if that attempt expired.
    --true: Server has been configured and is ready to play.
    print("cc1Listener")
    if (event.response == "true") then
        print("response true, bailing on setup.")
        --skip to normal logic? might need a flag to confirm ive done the setup check or bootstrap
        return
    elseif event.response == deviceId then
        --oh, we're the ones setting it up, continue on.
    else
        --this should be someone else'se deviceId, we have to wait for them.
        --exiting for now, TODO indicate to the player whats going on.
        print("other player mid-setup, bailing.")
        return
    end
    print("staring cc load")
    --Global entries can't expire, so i may have issues if these get set to pending and never changed or updating is cancelled.
    --Plan 2: put deviceID in ccSetup, and attach expiration to an entry on that player? If they're not configuring things, you are allowed to instead.
    network.request(serverURL .. "Data/Global/ccSetup/" .. deviceId .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Player/" .. deviceId .. "/ccSetup/pending/120" .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Global/ccConfigId/1" .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Global/ccPics/" .. deviceId .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Player/" .. deviceId .. "/ccPics/pending/60" .. defaultQueryString, "PUT", DefaultNetCallHandler)
    network.request(serverURL .. "Data/Global/ccPicsId/1" .. defaultQueryString, "PUT", DefaultNetCallHandler)

    print("post-claiming config")

    local headers = {}
    headers["Content-Type"] = "application/octet-stream"
    --queue all these calls up.
    for i,v in ipairs(defaultConfig.creatures) do
        --todo: add line here to copy file to temporary files.
        print("copying file")
        local filenameparts = Split(v.imageName, "/")
        print(dump(filenameparts))
        copyFile(v.imageName, system.ResourceDirectory, filenameparts[3], system.TemporaryDirectory, true )
        print("file copied")
        local params = {
            headers = headers,
            bodyType = "binary",
            body = {
                filename = filenameparts[3], --NOTE: Android won't read .png files from the ResourceDirectory, those need moved or renamed.
                baseDirectory = system.TemporaryDirectory
            }
        }
        --might have an issue here if I have slashes in the imageName value. Might need to escape that here. &#47 == / or %2f
        --print(v.imageName)
        --print(string.gsub(v.imageName, "\/", "-"))
        local url = serverURL .. "StyleData/Bitmap/" .. string.gsub(v.imageName, "\/", "-") .. defaultQueryString
        print(url)
        table.insert(networkQueue, { url = serverURL .. "StyleData/Bitmap/" .. filenameparts[3] .. defaultQueryString, verb = "PUT", handlerFunc = picUploadHandler, params = params})
        uploadPicsLeft = uploadPicsLeft + 1
        print("upload queued")
    end

    --wait for queue to empty, then continue.

end

function picUploadHandler(event)
    print("picUploadhandler")
    if (event.status ~= 200) then
        --requeue this call? Might need to be done on a specific status call.
        print("pic upload failed.")

        print(event.response)
    else
        print("pic uploaded")
        uploadPicsLeft = uploadPicsLeft - 1
        networkQueueBusy = false
        --todo: delete temporary file bitmap matching this call.
        if (uploadPicsLeft == 0) then
            --go on to the next step
            --NOTE: this might fail on the server since a null value would read the body, which is also null, and may not like that. Might need actual delete calls.
            network.request(serverURL .. "Data/Global/ccPics" .. defaultQueryString, "DELETE", DefaultNetCallHandler)
            network.request(serverURL .. "Data/Global/ccSpawnRuleUpload/" .. deviceId .. defaultQueryString, "PUT", DefaultNetCallHandler)
            network.request(serverURL .. "Data/Global/ccSpawnRuleId/1" .. defaultQueryString, "PUT", DefaultNetCallHandler)
            sendSpawnRules()
        end
    end
end

function sendSpawnRules()
    print("sendSpawnRules")
    --turn defaultConfig into a string, upload it
    local convertedDefaultConfig = json.encode(defaultConfig)
    --set this convertedDefaultConfig to the request's body.
    local params = {}
    params.body = convertedDefaultConfig
    table.insert(networkQueue, { url = serverURL .. "Data/Global/ccConfig" .. defaultQueryString, verb = "PUT", handlerFunc = spawnRuleUploadHandler, params = params})
end

function spawnRuleUploadHandler(event)
    print("spawnRulesHandler")
    networkQueueBusy = false
    print(event.status)
    print(event.response)
    if (event.status == 200) then
        --i think this means CreatureCollector mode is configured up.
        network.request(serverURL .. "Data/Global/ccSpawnRuleUpload" .. deviceId .. defaultQueryString, "DELETE", DefaultNetCallHandler)
        network.request(serverURL .. "Data/Global/ccSetup/true" .. defaultQueryString, "PUT", DefaultNetCallHandler)
        network.request(serverURL .. "Data/Player/" .. deviceId .. "/ccSetup/done/1" .. defaultQueryString, "PUT", DefaultNetCallHandler)
        network.request(serverURL .. "Data/Player/" .. deviceId .. "/ccPics/done/1" .. defaultQueryString, "PUT", DefaultNetCallHandler)
        print("all good")
    end
end


function spawnProcess(pluscode8)
    --Get data and/or terrain for this area.
    --we may already have them in memory, we may not.
    print("spawning")
    local terrainInfo = LoadTerrainDataCell8(pluscode8)

    if #terrainInfo == 0 then
        --let this call again next loop, we don't have terrain data downloaded yet.
        print("no terrain data, aborting spawn.")
        return
    end

    --In theory, we already have this data, since ideally this is the function that would call spawnProcess.
    --GetCreaturesInArea(pluscode8) -- this should be called regularly, not explicitly in this loop.
    --so we have creature info in wildCreatures.

    local thisTable = generateSpawnTableForCell8(currentPlusCode:sub(1,8))
    print("have table")

    --check for spawnLock
    --if not found, claim spawnlock
    --recheck, if we have spawn lock then advance:

    --make 3 lists:
    --forbidden areas (don't spawn things here. Includes cells that currently have a creature in them. May have other rules later.)
    --Walkable areas (which cells have tertiary or trail terrains)
    --not-walkable areas (cells not in the above list)

    local forbidden = {}
    local walkable = {}
    local other = {}
    print("have lists")

    for k,v in pairs(wildCreatures) do
        --block spawning in a space with an existing creature.
        table.insert(forbidden, k)
    end
    print("past existing creatures")

    for i,v in ipairs(terrainInfo) do
        print(dump(v))
        --tertiary being a walkable space is a fairly big assumption, but I can't leave this logic ONLY applying to hiking trails.
        if (v[4] == 'trail' or v[4] == 'tertiary') then
            table.insert(walkable, v[2])
        else
            table.insert(other, v[2])
        end
    end
    print("past split into walkable/other")
    print("sizes")
    print(#walkable)
    print(#other)

    local i = 0
    --pick 3 (if available) cells from walkable
    local walkableTotal = #walkable
    print("start walkable pull")
    while i < defaultConfig.minWalkableSpacesOnSpawn and i < walkableTotal do
        print(i)
        local pos = math.random(1, #walkable)
        spawnCell = walkable[pos]
        print(spawnCell)
        table.remove(walkable, pos)
        print("removed")
        PullOneEntryFromTable(thisTable, spawnCell)
        print("pulled")
        i = i + 1
    end
    print("past pulling walkables")

    i = 0
    --pick 3 (if available) cells from not-walkable
    local otherTotal = #other
    while i < defaultConfig.minOtherSpacesOnSpawn and i < otherTotal do
        local pos = math.random(1, #other)
        spawnCell = other[pos]
        table.remove(other, pos)
        PullOneEntryFromTable(thisTable, spawnCell)
        i = i + 1
    end

    print("past pulling forced-others")

    print("sizes")
    print(#walkable)
    print(#other)

    i = 0
    --pick rest (if available) cells that aren't on the forbidden list.
    --This loop probably doesn't handle edge cases nicely where there are less than 12 non-forbidden spaces, but I would have to see it to figure out how.
    while i < (defaultConfig.creaturesPerCell8 - defaultConfig.minWalkableSpacesOnSpawn - defaultConfig.minOtherSpacesOnSpawn) do -- and i < (400 - #forbidden)
        print("A")
        print(i)
        if (math.random(1,2) == 2 and #other >= 1) or #walkable == 0 then
            print("B")
            print(#other)
            local pos = math.random(1, #other)
            spawnCell = other[math.random(1, #other)]
            print("B2")
            table.remove(other, pos)
            print("B3")
        elseif #walkable >= 1  or #other == 0 then
            print("C")
            local pos = math.random(1, #walkable)
            spawnCell = walkable[pos]
            table.remove(walkable, pos)
        end
        print("D")
        PullOneEntryFromTable(thisTable, spawnCell)
        i = i + 1
    end
    print("done spawning for " .. pluscode8)

end

function PullOneEntryFromTable(spawnTable, pluscode10)
    local nextCreature = defaultConfig.creatures[spawnTable[math.random(1, #spawnTable)]]
    nextCreature.duration = math.random(1800, 3600)
    nextCreature.uid = math.random() --client tracks this value to determine which creatures to show or not show.

    local data = json.encode(nextCreature)
    local params = {}
    params.body = data
    table.insert(networkQueue, {url = serverURL .. "Data/Area/" .. pluscode10 .."/creature/noval/" .. nextCreature.duration ..defaultQueryString, verb="PUT", handlerFunc = spawnCreatureToServerHandler, params = params})
end

function GetCreaturesInArea(Cell8) --
    --this doesn't get saved to the device at all. Keep it in memory, update it every few seconds.
    netTransfer()
    table.insert(networkQueue, { url = serverURL .. "Data/Area/All/" .. Cell8 .. defaultQueryString, verb = "GET", handlerFunc = creaturesListener})
end

function creaturesListener(event)
    if (debug) then print("creatures event started") end
    if event.status == 200 then
        netUp()
        networkQueueBusy = false
    else
        if (debug) then print("creatures listener failed") end
        netDown(event)
        networkQueueBusy = false
        return
    end

    local plusCode = Split(string.gsub(event.url, serverURL .. "Data/Area/All/", ""), '?')[1]
    --Format:
    --Cell10|dataTag|dataValue\n
    local resultsTable = Split(event.response, "\n")
    -- if #resultsTable < 3 then
    --     print("spawning creatures")
    --     spawnProcess()
    --     return
    -- end
    --print('loading to hint memory ' .. #resultsTable)
    --print(event.response)

    --wildCreatures = {} -- clear out existing entries. TODO correctly repopulate this table from mostRecentCreatures cache
    if mostRecentCreatures[plusCode] == nil then
        mostRecentCreatures[plusCode] = {}
    end
    thisCellCreatures = mostRecentCreatures[plusCode]
    thisCellCreatures = {}
    local creatureCount = 0

    print(#resultsTable)
    for cell = 1, #resultsTable do
        print("in loop")
        local splitData = Split(resultsTable[cell], "|")
        if (#splitData == 3)  then
            local key = splitData[1]
            print(dump(splitData))
            if (splitData[2] == "creature") then
                --creature data is JSON here, so we'll decode it to table.
                creatureCount = creatureCount + 1
                local creatureData = json.decode(splitData[3])
                --print(dump(creatureData))
                thisCellCreatures[splitData[1]] = creatureData
                --print(dump(thisCellCreatures[splitData[1]]))
            end
        else
            --this row is empty, don't do anything
        end
    end

    mostRecentCreatures[plusCode] = thisCellCreatures

    forceRedraw = true
    print(creatureCount)
    print("vs")
    print(defaultConfig.creatureCountToRespawn)
    if (creatureCount < defaultConfig.creatureCountToRespawn) then
        --call spawn process
        print("running spawn process for " .. plusCode)
        spawnProcess(plusCode)
    end

    if(debug) then print("creatures event ended") end

end

function differenceX(centerPlusCode, destPlusCode)
    --Takes in 2 Cell10 values (no pluses), returns cells away on the X axis they are
    local xCellsAway = 0
    --print("diff x")

    --center is FF, dest of GG should be + 1. Only have to check the last 2 since we cannot draw enough maptiles for higher boundaries to matter.
    xCellsAway = CODE_ALPHABET_:find(destPlusCode:sub(10,10)) - CODE_ALPHABET_:find(centerPlusCode:sub(10,10))
    --print("1")
    xCellsAway = xCellsAway + ((CODE_ALPHABET_:find(destPlusCode:sub(8,8)) - CODE_ALPHABET_:find(centerPlusCode:sub(8,8))) * 20)
    --print("2")
    return xCellsAway
end

function differenceY(centerPlusCode, destPlusCode)
    --Takes in 2 Cell10 values (no pluses), returns cells away on the Y axis they are
    local yCellsAway = 0

    --center is FF, dest of GG should be + 1. Only have to check the last 2 since we cannot draw enough maptiles for higher boundaries to matter.
    yCellsAway = CODE_ALPHABET_:find(destPlusCode:sub(9,9)) - CODE_ALPHABET_:find(centerPlusCode:sub(9,9))
    yCellsAway = yCellsAway + ((CODE_ALPHABET_:find(destPlusCode:sub(7,7)) - CODE_ALPHABET_:find(centerPlusCode:sub(7,7))) * 20)

    return yCellsAway
end

function drawIcons()
    -- check for all the creatures in range.
    -- Put the ? icon on the spaces they are in
    --local sceneGroup = self.view

    print("starting drawIcon")
    --remove existing icons
    if (creatureIcons ~= nil) then
        print("removing existing icons")
        print(#creatureIcons)
        for i = 1, #creatureIcons do
            creatureIcons[i]:removeSelf()
        end
    end
    creatureIcons = {}


    local currentCell8 = currentPlusCode:sub(1,8)
    print(currentCell8)
    if cellCollection == nil then
        print("no cell collection?")
        return
    end

    print(#cellCollection)
    --make a list of the cells to use for icons.
    local cellList = {}
     for square = 1, #cellCollection do
         print("adding " .. removePlus(cellCollection[square].pluscode):sub(1,8))
         cellList[square] = removePlus(cellCollection[square].pluscode):sub(1,8)
     end

    --cellList[1] = currentCell8

    print("built Cell list")
    print(dump(cellList))

    --rebuild visible wildCreaturesTable
    wildCreatures = {}
    print(#cellList)
    for i, v in ipairs(cellList) do
        print(i)
        print(v)
        if(mostRecentCreatures[v] == nil) then
            print("no creature list for " .. v)
            return
        end
        for kk, vv in pairs(mostRecentCreatures[v]) do
            print("adding creature at " .. kk)
            print(dump(vv))
            if (caughtCreatures[vv.uid] == nil) then --skip adding if we already caught this creature.
                wildCreatures[kk] = vv
            end

        end
    end
    print("wild creatures built")


    --for i = 1, #mostRecentCreatures[currentCell8] do




    --print("get scene group")
    --local sceneGroup = scene.view
    print("drawing icons")

    -- if (#wildCreatures == 0) then
    --     print("no wild creatures, cancelling")
    --     return
    -- end

    print("going on")

    local shiftPixelsX = 0
    local shiftPixelsY= 0
    print(gridzoom)

    -- +FF is the center square of the current Cell8.
    -- adjust some scaling values for the current zoom levels.
    if (gridzoom == 1) then
        shiftPixelsX = 32
        shiftPixelsY = 40
    elseif (gridzoom == 2) then
        shiftPixelsX = 16
        shiftPixelsY = 20
    elseif (gridzoom == 3) then
        shiftPixelsX = 8
        shiftPixelsY = 10
    end

    -- filter out ones we've caught already.
    -- this might be sort of a backwards version of my touch detector logic, since its finding where to draw a position on an open grid.
    -- i will have more tracking  and removing unnecessary things than just updating a grid of 400 things.
    local centerValue = removePlus(currentPlusCode):sub(1,8) .. "FF" -- center of the plus code in the center of the screen.
    print(centerValue)

    --dumb test check
    --creatureIcons:toFront()
    for k,v in pairs(wildCreatures) do
        -- k is Cell10, v is json data.
        print("wild creature")
        print(k)
        print(dump(v))


        local moveX = differenceX(centerValue, k)
        --print(moveX)
        local moveY = differenceY(centerValue, k)
        --print(moveY)
        --print("moves calced")

        thisIcon = display.newImageRect(creaturesOnMap, "themables/creatureSpot.png", shiftPixelsX, shiftPixelsY)

        --print("icon exists")
        thisIcon.x = display.contentCenterX + (moveX * shiftPixelsX)
        thisIcon.anchorX = .5
        --print("xs set")
        thisIcon.y = display.contentCenterY + (moveY * shiftPixelsY)
        thisIcon.anchorY = .5
        --print("ys set")
        table.insert(creatureIcons, thisIcon)
        print(thisIcon.x)
        print(thisIcon.y)
        print(thisIcon.width)
        print(thisIcon.height)
        thisIcon:toFront()
        print("icon added")
    end

    print("done drawing icons")
end



local overlayCollection = {} -- any overlay tiles needed.


local touchDetector = {} -- Determines what cell10 was tapped on the screen.

local timerResults = nil
local firstRun = true
local mapTileUpdater = nil
local iconUpdater = nil

local locationText = ""
local timeText = ""
local directionArrow = ""
local debugText = {}
local locationName = ""

local creatureIDsToSkip = {}

local function testDrift()
    if (os.time() % 2 == 0) then
        currentPlusCode = shiftCell(currentPlusCode, 1, 9) -- move north
    else
        currentPlusCode = shiftCell(currentPlusCode, 1, 10) -- move west
    end
end

local function ToggleZoom()
    print("zoom tapped")
    gridzoom = gridzoom + 1
    if (gridzoom > 3) then gridzoom = 1 end
    timer.pause(timerResults)

    for i = 1, #cellCollection do cellCollection[i]:removeSelf() end
    for i = 1, #overlayCollection do overlayCollection[i]:removeSelf() end

    cellCollection = {}
    overlayCollection = {}
    makeGrid()

    directionArrow:toFront()
    drawIcons()
    forceRedraw = true
    timer.resume(timerResults)
    return true
end

function makeGrid()
    local sceneGroup = scene.view
    if (gridzoom == 1) then
        CreateRectangleGrid(3, 640, 800, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(3, 640, 800, sceneGroup, overlayCollection) -- rectangular Cell11 grid with overlay
    elseif (gridzoom == 2) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(3, 320, 400, sceneGroup, overlayCollection) -- rectangular Cell11 grid with overlay
    elseif (gridzoom == 3) then
        CreateRectangleGrid(5, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(5, 160, 200, sceneGroup, overlayCollection) -- rectangular Cell11 grid with overlay
    end

    for square = 1, #overlayCollection do
        overlayCollection[square]:toBack()
        cellCollection[square]:toBack() --same count
    end
    touchDetector:toBack()
end

--"tap" event
local function DetectLocationClick(event)
    print("Detecting location")
    -- we have a click somewhere in our rectangle.
    -- gridzoom3 is 5x5 lowres tiles, 800 x 1000 total, each pixel is 1 Cell 11
    -- gridzoom2 is 3x3 highres tiles, 960 x 1200 total, each 2x2 pixels is 1 Cell 11
    -- gridzoom1 is 3x3 doubled highres tiles, 1960 x 2400 total, each 4x4 pixels is 1 cell 11.

    -- figure out how many pixels from the center of the item each tap is
    local screenX = event.x
    local screenY = event.y
    local centerX = display.contentCenterX
    local centerY = display.contentCenterY

    --remember that the CENTER of the center square is the center pixel on screen, not the SW corner
    --so i have to shift info by half a square somewhere.

    local pixelshiftX = screenX - centerX
    local pixelshiftY = centerY - screenY --flips the sign to get things to line up correctly.
    local plusCodeShiftX = 0
    local plusCodeShiftY = 0

    if (gridzoom == 1) then
        pixelshiftX = pixelshiftX + 16
        pixelshiftY =  pixelshiftY + 20
        plusCodeShiftX = pixelshiftX / 32
        plusCodeShiftY = pixelshiftY / 40
    elseif (gridzoom == 2) then
        pixelshiftX = pixelshiftX + 8
        pixelshiftY =  pixelshiftY + 10
        plusCodeShiftX = pixelshiftX / 16
        plusCodeShiftY = pixelshiftY / 20
    elseif (gridzoom == 3) then
        pixelshiftX = pixelshiftX + 4
        pixelshiftY =  pixelshiftY + 5
        plusCodeShiftX = pixelshiftX / 8
        plusCodeShiftY = pixelshiftY / 10
    end

    local newCell = currentPlusCode:sub(0,8) .. "+FF" --might be GG, depends on direction of shift
    newCell = shiftCell(newCell, plusCodeShiftY, 9) --Y axis
    newCell = shiftCell(newCell, plusCodeShiftX, 10) --X axis
    print("Detected cell tap: " .. newCell)
    tapData.text = "Cell Tapped: " .. newCell

    local pluscodenoplus = removePlus(newCell)
    local terrainInfo = LoadTerrainData(pluscodenoplus)

    -- 3 is name, 4 is area type, 6 is mapDataID (privacyID)
    if (terrainInfo[3] == "") then
        tappedAreaName = terrainInfo[4]
    else
        tappedAreaName = terrainInfo[3]
    end

    --tappedCell = newCell
    --tappedAreaScore = 0 --i don't save this locally, this requires a network call to get and update
    --tappedAreaMapDataId = terrainInfo[6]
    --composer.showOverlay("overlayMPAreaClaim", {isModal = true})

end

local function GoToSceneSelect()
    print("back to scene select")
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
    return true
end

local function UpdateLocalOptimized()
    if timerResults == nil then
        timerResults = timer.performWithDelay(450, UpdateLocalOptimized, -1)
    end

    if not playerInBounds then
        return
    end

    if (debugLocal) then print("start UpdateLocalOptimized") end
    if (currentPlusCode == "") then
        if (debugLocal) then print("skipping, no location.") end
        return
    end

    if (debug) then debugText.text = dump(lastLocationEvent) end

    if (timerResults ~= nil) then timer.pause(timerResults) end
    local innerForceRedraw = forceRedraw or firstRun or (currentPlusCode:sub(1,8) ~= previousPlusCode:sub(1,8))
    firstRun = false
    forceRedraw = false
    previousPlusCode = currentPlusCode

    -- Step 1: set background MAC map tiles for the Cell8.
    if (innerForceRedraw == false) then -- none of this needs to get processed if we haven't moved and there's no new maptiles to refresh.
    for square = 1, #cellCollection do
        -- check each spot based on current cell, modified by gridX and gridY
        local thisSquaresPluscode = currentPlusCode
        thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridX, 8)
        thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridY, 7)
        cellCollection[square].pluscode = thisSquaresPluscode
        local plusCodeNoPlus = removePlus(thisSquaresPluscode):sub(1, 8)
        --GetMapData8(plusCodeNoPlus)
        --checkTileGeneration(plusCodeNoPlus, "mapTiles")
        local imageExists = doesFileExist(plusCodeNoPlus .. "-11.png", system.CachesDirectory)
        if imageExists == true then
            cellCollection[square].fill = {0.1, 0.1} -- required to make Solar2d actually update the texture.
            local paint = {
                type = "image",
                filename = plusCodeNoPlus .. "-11.png",
                baseDir = system.CachesDirectory
            }
            cellCollection[square].fill = paint
        end

            --Update this loop to pull the overlay tiles if needed
            -- imageRequested = requestedMPMapTileCells[plusCodeNoPlus] -- read from DataTracker because we want to know if we can paint the cell or not.
            -- imageExists = doesFileExist(plusCodeNoPlus .. "-AC-11.png", system.TemporaryDirectory)
            -- if (imageRequested == nil) then
            --     imageExists = doesFileExist(plusCodeNoPlus .. "-AC-11.png", system.TemporaryDirectory)
            -- end

            -- if (imageExists == false or imageExists == nil) then
            --      GetTeamControlMapTile8(plusCodeNoPlus)
            -- else
            --     overlayCollection[square].fill = {0, 0} -- required to make Solar2d actually update the texture.
            --     local paint = {
            --         type = "image",
            --         filename = plusCodeNoPlus .. "-AC-11.png",
            --         baseDir = system.TemporaryDirectory
            --     }
            --     overlayCollection[square].fill = paint
            -- end
        end
    end

    --drawIcons()

    if (timerResults ~= nil) then timer.resume(timerResults) end
    if (debugLocal) then print("grid done or skipped") end
    locationText.text = "Current location:" .. currentPlusCode
    timeText.text = "Current time:" .. os.date("%X")
    directionArrow.rotation = currentHeading

    --Remember, currentPlusCode has the +, so i want chars 10 and 11, not 9 and 10.
    --Shift is how many blocks to move. Multiply it by how big each block is. These offsets place the arrow in the correct Cell10.
    local shift = CODE_ALPHABET_:find(currentPlusCode:sub(11, 11)) - 11
    local shift2 = CODE_ALPHABET_:find(currentPlusCode:sub(10, 10)) - 10
    if (gridzoom == 1) then
        directionArrow.x = display.contentCenterX + (shift * 32)  + 16
        directionArrow.y = display.contentCenterY - (shift2 * 40) + 20
    elseif (gridzoom == 2) then
        directionArrow.x = display.contentCenterX + (shift * 16)  + 8
        directionArrow.y = display.contentCenterY - (shift2 * 20) + 10
    elseif (gridzoom == 3) then
        directionArrow.x = display.contentCenterX + (shift * 8) + 4
        directionArrow.y = display.contentCenterY - (shift2 * 10) + 5
    end

    if wildCreatures[currentPlusCode] ~= nil then
        local creatureName = wildCreatures[currentPlusCode].name
        composer.setVariable("creatureCaught", creatureName)
        caughtCreatures[wildCreatures[currentPlusCode].uid] = 1 --mark this ID as caught so we won't redisplay it again.
        table.remove(wildCreatures, currentPlusCode)
        Exec("UPDATE creaturesCaught SET count = count + 1 WHERE name = '" .. creatureName .. "', 0)")
        composer.showOverlay("creatureOverlay", {effect = "fromLeft", time = 100})
    end


    locationText:toFront()
    timeText:toFront()
    directionArrow:toFront()
    locationName:toFront()

    if (debugLocal) then print("end updateLocalOptimized") end
end

local function UpdateMapTiles()
    --set this to run every 5 seconds
    for square = 1, #cellCollection do
        -- check each spot based on current cell, modified by gridX and gridY
        local thisSquaresPluscode = currentPlusCode
        thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridX, 8)
        thisSquaresPluscode = shiftCell(thisSquaresPluscode, cellCollection[square].gridY, 7)
        cellCollection[square].pluscode = thisSquaresPluscode
        local plusCodeNoPlus = removePlus(thisSquaresPluscode):sub(1, 8)
        GetMapData8(plusCodeNoPlus)
        checkTileGeneration(plusCodeNoPlus, "mapTiles")
        GetCreaturesInArea(plusCodeNoPlus)
    end -- for
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)
    composer.setVariable("myScore", "0")

    if (debug) then print("creating MPAreaControlScene2") end
    local sceneGroup = self.view

    creaturesOnMap = display.newGroup()
    sceneGroup:insert(creaturesOnMap)
    creaturesOnMap:toFront()

    touchDetector = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 720, 1280)
    touchDetector:addEventListener("tap", DetectLocationClick)
    touchDetector.fill = {0, 0.1}
    touchDetector:toBack()

    contrastSquare = display.newRect(sceneGroup, display.contentCenterX, 230, 400, 100)
    contrastSquare:setFillColor(.8, .8, .8, .7)

    locationText = display.newText(sceneGroup, "Current location:" .. currentPlusCode, display.contentCenterX, 200, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"), display.contentCenterX, 220, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 240, native.systemFont, 20)

    locationText:setFillColor(0, 0, 0);
    timeText:setFillColor(0, 0, 0);
    locationName:setFillColor(0, 0, 0);

    --CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
    --CreateRectangleGrid(3, 320, 400, sceneGroup, overlayCollection) -- rectangular Cell11 grid with overlay
    makeGrid()

    directionArrow = display.newImageRect(sceneGroup, "themables/arrow1.png", 16, 20)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY
    directionArrow.anchorX = .5
    directionArrow.anchorY = .5
    directionArrow:toFront()

    local header = display.newImageRect(sceneGroup, "themables/creatureCollector.png",300, 100)
    header.x = display.contentCenterX
    header.y = 100
    header:addEventListener("tap", GoToSceneSelect)
    header:toFront()

    local zoom = display.newImageRect(sceneGroup, "themables/ToggleZoom.png", 100, 100)
    zoom.anchorX = 0
    zoom.x = 50
    zoom.y = 100
    zoom:addEventListener("tap", ToggleZoom)

    local listbutton = display.newImageRect(sceneGroup, "themables/creatureList.png",300, 100)
    listbutton.x = display.contentCenterX
    listbutton.y = 1100
    listbutton:addEventListener("tap", ShowCreatureList)
    listbutton:toFront()


    if (debug) then
        debugText = display.newText(sceneGroup, "location data", display.contentCenterX, 1180, 600, 0, native.systemFont, 22)
        debugText:toFront()
    end
    zoom:toFront()
    contrastSquare:toFront()


    --first-time database setup
    local tableEntries = Query("SELECT name FROM creaturesCaught")
    print(dump(tableEntries))
    if #tableEntries == 0 then
        for k,v in pairs(defaultConfig["creatures"]) do
            Exec("INSERT INTO creaturesCaught(name, count) VALUES ('" .. k .. "', 0)")
        end
    end

    ccSetupCheck()
end

function scene:show(event)
    if (debug) then print("showing baseline scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        firstRun = true
    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen
        timer.performWithDelay(50, UpdateLocalOptimized, 1)
        if (debugGPS) then timer.performWithDelay(3000, testDrift, -1) end
        mapTileUpdater = timer.performWithDelay(5000, UpdateMapTiles, -1)
        iconUpdater = timer.performWithDelay(3000, drawIcons, -1)


        buildSpawnTable() --TODO: move this call to after checking that we have the latest config and/or downloading said latest config.
    end
end

function scene:hide(event)
    if (debug) then print("hiding baseline scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        timer.cancel(timerResults)
        timerResults = nil
        timer.cancel(mapTileUpdater)
        timer.cancel(iconUpdater)

    elseif (phase == "did") then
        -- Code here runs immediately after the scene goes entirely off screen
    end
end

function scene:destroy(event)
    if (debug) then print("destroying baseline scene") end

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)
-- -----------------------------------------------------------------------------------

return scene