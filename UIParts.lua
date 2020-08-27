function CreateSquareGrid(gridSize, cellSize, gridGroup, cellCollection)
    --size is square, X by Y size. Must be odd so that i can have a center square. Even values get treated as one larger to be made odd.
    if (debug) then print("Starting CreateSquareGrid") end
    local padding = 1 --space between cells.
    local range = math.floor(gridSize / 2) -- 7 becomes 3, which is right. 6 also becomes 3.

    for x = -range, range, 1 do
        for y = -range, range, 1 do
            --create cell, tag it with x and y values.
            local newSquare = display.newRect(gridGroup, display.contentCenterX + (cellSize * x) + x , display.contentCenterY + (cellSize * y) + y , cellSize, cellSize) --x y w h
            newSquare.gridX = x
            newSquare.gridY = -y --invert this so cells get identified top-to-bottom, rather than bottom-to-top
            newSquare.name = "" --added for terrain/location support
            newSquare.type = ""--added for terrain/location support
            --newSquare:addEventListener("tap", debuggerHelperSquare) --for debugging display grid, show the cell's plus code by click/tap
            cellCollection[#cellCollection + 1] = newSquare
        end
    end

    if (debug) then print("Done CreateSquareGrid") end
end

function debuggerHelperSquare(event)
    native.showAlert("Cell", event.target.pluscode)
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