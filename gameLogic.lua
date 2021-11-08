function grantPoints(code)
    -- area tag score:
    -- New Cell10: 10 points!
    -- daily checkin: 1 point

    --Idle mode per second scores:
    --1 point per day per cell.

    local addPoints = 0

    if (debug) then print("granting points for cell " .. code) end

    local timeValue = os.time()
    local dailyReset = timeValue + 79200 -- 22 hours
    local query ="SELECT COUNT(*) as c FROM plusCodesVisited WHERE pluscode = '" .. code .. "'"
    
    for i, row in ipairs(Query(query)) do
        if (row[1] == 0) then
            if (debug) then print("inserting new row") end
            
            local insert =
                "INSERT INTO plusCodesVisited (pluscode, firstVisitedOn, nextScoreTime, totalVisits) VALUES ('" ..
                    code .. "', " .. timeValue .. ", " .. dailyReset .. ", 1" .. ")"
            Exec(insert)
            addPoints = addPoints + 10
        else
            print("checking values")
            local sql2 = "SELECT * FROM PlusCodesVisited WHERE pluscode = '" .. code .. "'"
            local query2 = Query(sql2)
            for i, row in ipairs(query2) do
                local nextScoreTime = row[6]
                if (tonumber(nextScoreTime) < timeValue) then
                    addPoints = addPoints + 1
                end
                local update = "UPDATE plusCodesVisited SET totalVisits = totalVisits + 1,  nextScoreTime = " .. dailyReset .. " WHERE plusCode = '" .. code .. "'"
                Exec(update)
            end
        end
    end
    if (debug) then print("grant query done") end

    local cmd = "UPDATE playerData SET totalPoints = totalPoints + " .. addPoints
    Exec(cmd)

    if (addPoints > 0) then
        --Idle game update logic
        local idleGameAreaType = ''
        local column = 'all'
        query = "SELECT areatype FROM terrainData WHERE pluscode = '" .. code .. "'"
        for i, row in ipairs(Query(query)) do
            idleGameAreaType = row[1]
        end

        if (idleGameAreaType == 'park') then
            column = 'park'
        elseif (idleGameAreaType == 'natureReserve') then
            column = 'nature'
        elseif (idleGameAreaType == 'trail') then
            column = 'trail'
        elseif (idleGameAreaType == 'tourism') then
            column = 'tourism'
        elseif (idleGameAreaType == 'cemetery') then
            column = 'graveyard'
        end    

        cmd = "UPDATE IdleStats SET " .. column .. "PerSec = " .. column .. "PerSec + 1"
        Exec(cmd)
    end

    if (debug) then
        print("earned " .. addPoints .. " points for cell " .. code)
    end
    return addPoints
end