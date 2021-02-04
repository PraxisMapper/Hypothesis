function grantPoints(code)
    --new Cell8: 100 points!
    --New Cell10: 10 points!
    --weekly bonus: 5 points
    --daily checkin: 1 point
    local addPoints = 0
    if(debug) then print("granting points for cell " .. code) end

    --check 1: is this the first time we've entered this Cell8?
    query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE eightCode = '" .. code:sub(1,8) .. "'"
    for i,row in ipairs(Query(query)) do 
        if (row[1] == 0) then --we have not yet visited this cell
            --new visit to this cell8
            addPoints = addPoints + 100
        end
    end

    --check 2: is this a brand new Cell10?
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do 
        if (row[1] == 0) then
            if (debug) then print("inserting new row") end
            local insert = "INSERT INTO plusCodesVisited (pluscode, lat, long, firstVisitedOn, lastVisitedOn, totalVisits, eightCode) VALUES ('" .. code .. "', 0,0, " .. os.time() .. ", " .. os.time() .. ", 1, '" .. code:sub(1,8) .. "')"
            Exec(insert)
            addPoints = addPoints + 10
        else
            if (debug) then print("updating existing data") end
            local update = "UPDATE plusCodesVisited SET totalVisits = totalVisits + 1, lastVisitedOn = " .. os.time() .. " WHERE plusCode = '" .. code  .. "'"
            Exec(update)
        end
    end 
    if(debug) then print("grant query 1 done") end

    --check 3: this our first visit today?
    query = "SELECT COUNT(*) as c FROM dailyVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do
        if (row[1] == 0) then --we have not yet visited this cell today
            local cmd = "INSERT INTO dailyVisited (pluscode, VisitedOn) VALUES('" .. code .. "', " .. os.time() .. ")"
            Exec(cmd)
            addPoints = addPoints + 1 
        end
    end

    if(debug) then print("grant query 2 done") end

    --check 4: this our first visit this week?
    query = "SELECT COUNT(*) as c FROM weeklyVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do 
        if (row[1] == 0) then --we have not yet visited this cell this week
            local cmd = "INSERT INTO weeklyVisited (pluscode, VisitedOn) VALUES('" .. code .. "', " .. os.time() .. ")"
            Exec(cmd)
            addPoints = addPoints + 5
        end
    end
  
        local cmd = "UPDATE playerData SET totalPoints = totalPoints + " .. addPoints
        Exec(cmd)

    if(debug) then print("earned " .. addPoints .. " points for cell " .. code) end
    return addPoints
end