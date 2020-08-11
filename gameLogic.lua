--todo:
--Maybe consolidate commands that get run every seconds into a single statement when possible?
--connect to OpenStreetMaps to detect type of cell? This is a lot of server-side work

function grantPoints(code)
    --new city block: 100 points!
    --New cell: 10 points!
    --weekly bonus: 5 points
    --daily checkin: 1 point
    local addPoints = 0
    if(debug) then print("granting points for cell " .. code) end

    --check 1: is this the first time we've entered this 8code?
    query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE substr(pluscode, 0, 9) = '" .. code:sub(1,8) .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
        if (row[1] == 0) then --we have not yet visited this cell
            --new visit to this 8cell
            addPoints = addPoints + 100
        end
    end

    --check 2: is this a brand new 10cell?
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
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

    --check 3: this our first visit today?
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

    --check 4: this our first visit this week?
    query = "SELECT COUNT(*) as c FROM weeklyVisited WHERE pluscode = '" .. code .. "'"
    for i,row in ipairs(Query(query)) do --todo: find better parsing method
        if (row[1] == 0) then --we have not yet visited this cell this week
            local cmd = "INSERT INTO weeklyVisited (pluscode, VisitedOn) VALUES('" .. code .. "', " .. os.time() .. ")"
            Exec(cmd)
            addPoints = addPoints + 5
        end
    end
  
        local cmd = "UPDATE playerData SET totalCellVisits = totalCellVisits + 1, totalPoints = totalPoints + " .. addPoints
        Exec(cmd)

    if(debug) then print("earned " .. addPoints .. " points for cell " .. code) end
    return addPoints
end


--unlock format:
--score, 8cells, 10cells, description/text, imagefile, x-coords, y-coords
--x and y are inside the trophy room image bounds, not the screen itself, and upper-left anchor.
--images are 25x25px for now, for testing purposes
trophyUnlocks = {
    {100,      1,    1,   "The first Trophy", "TrophyImgs/1.png", 1, 1},
    {500,      2,    21,  "The second Trophy", "TrophyImgs/2.png", 26, 26}, -- this should not be unlockable on the simulator
    {1000,     3,    50,  "The third Trophy", "TrophyImgs/3.png", 51, 51},
    {2000,     5,    100, "The fourth Trophy", "TrophyImgs/4.png", 76, 76},
    {5000,     8,    250, "The fifth Trophy", "TrophyImgs/5.png", 101, 101},
    {10000,    13,   500, "The sixth Trophy", "TrophyImgs/6.png", 126, 126},
    {20000,    21,   1000, "The seventh Trophy", "TrophyImgs/7.png", 126, 26},
    {36000,    34,   2000, "The eight Trophy", "TrophyImgs/8.png", 126, 51},
    {70000,    55,   4000, "The nineth Trophy", "TrophyImgs/9.png", 176, 76},
    {140000,   89,   8000, "The tenth Trophy", "TrophyImgs/10.png", 276, 276},
    {300000,   144,  16000, "The eleventh Trophy", "TrophyImgs/11.png", 126, 326},
    {550000,   233,  32000, "The twelfth Trophy", "TrophyImgs/12.png", 226, 226},
    {1100000,  377,  64000, "The thirteenth Trophy", "TrophyImgs/13.png", 326, 26},
    {2500000,  610,  128000, "The last Trophy", "TrophyImgs/14.png", 426, 426}
}

local sampleExampleTable = {
    ["namedindex"] = 1,
    ["namedIndexAgain"] = "Asdf"

}
