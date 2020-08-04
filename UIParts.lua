function CreateSquareGrid(gridSize, cellSize, gridGroup, cellCollection)
    --instead of hard-coding the grid, how do i dynamically make it?
    --size is square, X by Y size. Must be odd so that i can have a center square. Even values get treated as one larger to be made odd.
    if (debug) then print("Starting CreateSquareGrid") end
    local padding = 1 --space between cells.
    --local cellSize = 25 -- square size in pixels
    local range = math.floor(gridSize / 2) -- 7 becomes 3, which is right. 6 also becomes 3.

    for x = -range, range, 1 do
        for y = -range, range, 1 do
            --create cell, tag it with x and y values.
            local newSquare = display.newRect(gridGroup, display.contentCenterX + (cellSize * x) + x , display.contentCenterY + (cellSize * y) + y , cellSize, cellSize) --x y w h
            newSquare.gridX = x
            newSquare.gridY = -y --invert this so cells get identified top-to-bottom, rather than bottom-to-top
            cellCollection[#cellCollection + 1] = newSquare
        end
    end

    if (debug) then print("Done CreateSquareGrid") end
end

function GoToStoreScene()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("storeScene", options)
end

function GoToLeaderboardScene()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("LeaderboardScene", options)
end

-- function SwitchToSmallGrid()
--     local options = {
--         effect = "flip",
--         time = 125,
--     }
--     composer.gotoScene("10GridScene", options)
-- end

-- function SwitchToBigGrid()
--     local options = {
--         effect = "flip",
--         time = 125,
--     }
--     composer.gotoScene("8GridScene", options)
-- end

-- function SwitchToTrophy()
--     local options = {
--         effect = "flip",
--         time = 125,
--     }
--     composer.gotoScene("trophyScene", options)
-- end