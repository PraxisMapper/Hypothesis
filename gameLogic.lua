--todo:
--track points earned here
--display gamey stuff somehow
--add buttons to view different things
--IAP? buy dev a coffee?
--separate walk points and explore points?
--reconsider if i want to use level 10 (my house is 8 cells) or 9 (my city block is one cell)
--add a display log at hte bottom of the screen to remind me what's happened recently. (or pop-up events that fall away)

function grantPoints(code)
    --New cell: 10 points!
    --weekly bonus: 5 points
    --daily checkin: 1 point
    local addPoints = 0

    --check 1: is this a brand new cell?
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
        --if (debug) then print("row data:" .. dump(row)) end
        if (row[1] == 0) then
            if (debug) then print("inserting new row") end
            local insert = "INSERT INTO plusCodesVisited (pluscode, lat, long, firstVisitedOn, totalVisits) VALUES ('" .. code .. "', 0,0, " .. os.time() .. ", 1)"
            Exec(insert)
            addPoints = 10
        else
            if (debug) then print("updating existing data") end
            local update = "UPDATE plusCodesVisited SET totalVisits = totalVisits + 1 WHERE plusCode = '" .. code  .. "'"
            Exec(update)
        end
    end 

    --check 2: this our first visit this week?
    query = "SELECT COUNT(*) as c FROM weeklyVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
        if (row[1] == 0) then --we have not yet visited this cell this week
            --Insert this cell
            local cmd = "INSERT INTO weeklyVisited (pluscode, VisitedOn) VALUES('" .. code .. "', " .. os.time() .. ")"
            Exec(cmd)
            if (addPoints == 0) then addPoints = 5 end
        end
    end

    --check 3? this our first visit today?
    query = "SELECT COUNT(*) as c FROM dailyVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
        if (row[1] == 0) then --we have not yet visited this cell today
            --Insert this cell
            local cmd = "INSERT INTO dailyVisited (pluscode, VisitedOn) VALUES('" .. code .. "', " .. os.time() .. ")"
            Exec(cmd)
            if (addPoints == 0) then addPoints = 1 end
        end
    end

    if (addPoints > 0) then
        local cmd = "UPDATE playerData SET totalCellVisits = totalCellVisits + 1, totalPoints = totalPoints + " .. addPoints
        Exec(cmd)
    end


end