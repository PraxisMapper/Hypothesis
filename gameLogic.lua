--todo:
--Maybe consolidate commands that get run every seconds into a single statement when possible?
--display gamey stuff somehow
--add buttons to view different things
--separate walk points and explore points?
--connect to OpenStreetMaps to detect type of cell?

function grantPoints(code)
    --new city block: 100 points!
    --New cell: 10 points!
    --weekly bonus: 5 points
    --daily checkin: 1 point
    local addPoints = 0
    if(debug) then print("granting points for cell " .. code) end

    --check 4: is this the first time we've entered this 8code?
    --query = "SELECT COUNT(substr(pluscode, 0, 8)) as c FROM plusCodesVisited WHERE substr(pluscode, 0, 8) = '" .. code:sub(1,8) .. "'"
    query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE substr(pluscode, 0, 9) = '" .. code:sub(1,8) .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
        if (row[1] == 0) then --we have not yet visited this cell
            --new visit to this 8cell
            addPoints = addPoints + 100
        end
    end

    --check 1: is this a brand new cell?
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
        --if (debug) then print("row data:" .. dump(row)) end
        if (row[1] == 0) then
            if (debug) then print("inserting new row") end
            local insert = "INSERT INTO plusCodesVisited (pluscode, lat, long, firstVisitedOn, lastVisitedOn, totalVisits) VALUES ('" .. code .. "', 0,0, " .. os.time() .. ", " .. os.time() .. ", 1)"
            Exec(insert)
            addPoints = addPoints + 10
        else
            if (debug) then print("updating existing data") end
            local update = "UPDATE plusCodesVisited SET totalVisits = totalVisits + 1, lastVisitedOn = " .. os.time() .. " WHERE plusCode = '" .. code  .. "'"
            Exec(update)
        end
    end 
    if(debug) then print("grant query 1 done") end

    --check 2: this our first visit today?
    query = "SELECT COUNT(*) as c FROM dailyVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
        if (row[1] == 0) then --we have not yet visited this cell today
            --Insert this cell
            local cmd = "INSERT INTO dailyVisited (pluscode, VisitedOn) VALUES('" .. code .. "', " .. os.time() .. ")"
            Exec(cmd)
            addPoints = addPoints + 1 
        end
    end

    if(debug) then print("grant query 2 done") end


    --check 3: this our first visit this week?
    query = "SELECT COUNT(*) as c FROM weeklyVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
        if (row[1] == 0) then --we have not yet visited this cell this week
            --Insert this cell
            local cmd = "INSERT INTO weeklyVisited (pluscode, VisitedOn) VALUES('" .. code .. "', " .. os.time() .. ")"
            Exec(cmd)
            addPoints = addPoints + 5
        end
    end

    if(debug) then print("grant query 3 done") end
    
    if(debug) then print("grant query 4 done") end
    --remove the if so we can track total visits correcly.
    --if (addPoints > 0) then
        local cmd = "UPDATE playerData SET totalCellVisits = totalCellVisits + 1, totalPoints = totalPoints + " .. addPoints
        Exec(cmd)
    --end

    if(debug) then print("earned " .. addPoints .. " points for cell " .. code) end
    return addPoints


end


--unlock format:
--score, 8cells, 10cells, description/text, imagefile, x-coords, y-coords
--x and y are inside the trophy room image bounds, not the screen itself, and upper-left anchor.
--images are 25x25px for now, for testing purposes
trophyUnlocks = {
    {1, 1, 1, "The first Trophy", "TrophyImgs/1.png", 1, 1},
    {117, 2, 21, "The second Trophy", "TrophyImgs/2.png", 26, 26}, -- at 117/2/2 this should not be unlockable on the simulator

}

local sampleExampleTable = {
    ["namedindex"] = 1,
    ["namedIndexAgain"] = "Asdf"

}
