local composer = require( "composer" )
local scene = composer.newScene()

require("helpers")
require("gameLogic")
require("database")

--TODO 
--actually display things user has bought.
--Display data for the next trophy to unlock (score, 10Cell, 8Cell)
--Change up how trophies are awarded (per game, possibly)

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local nextUnlockAt = "" --displayText object
local lastTrophyBought = 0

local picturesToDisplay = {} --similar to the grid on 10cell and 8cell
local sceneGroupCopy = {} -- for DrawTrophy, possibly?
 
 
local function SwitchToSmallGrid()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("10GridScene", options)
end

local function SwitchToBigGrid()
    local options = {
        effect = "flip",
        time = 125,
    }
    composer.gotoScene("8GridScene", options)
end

local function DrawTrophy(index)
    if (index > #trophyUnlocks) then
        return
    end

    local trophyItem = trophyUnlocks[index]
    print(dump(trophyItem))
    local trophyRect = display.newImageRect(sceneGroupCopy, trophyItem[5], 25, 25)
    print ("got trophy rect")
    trophyRect.anchorX = 0
    trophyRect.anchorY = 0
    trophyRect.x = trophyItem[6]
    trophyRect.y = 200 + trophyItem[7] --offset to start inside the background image
    print ("rect done")

    table.insert(picturesToDisplay, trophyItem)
    print("item displayed")
end

local function FindNextTrophy()
    if (debug) then print("finding next trophy") end
    local query = "SELECT MAX(itemCode) FROM trophysBought"
    lastTrophyBought = Query(query)[1][1] --not sure why the double index is needed here, possibly because not ipairs() or iterating or anything.
    

    local dataindex = lastTrophyBought + 1
    if (dataindex > #trophyUnlocks) then
        nextUnlockAt.text = "You unlocked them all! Impressive!"
        return
    end

    local nextData = trophyUnlocks[dataindex]

    nextUnlockAt.text = "Next Trophy At " .. nextData[1] .. " Score, " .. nextData[2] .. " City Blocks, " .. nextData[3] .. " Routine Cells"

    for i = 1, lastTrophyBought, 1 do 
        DrawTrophy(i)
    end
end

local function BuyTrophy()
     local dataindex = lastTrophyBought + 1
     if (dataindex > #trophyUnlocks) then
        return
    end
    
     local nextData = trophyUnlocks[dataindex]
    --get score and cell count, compare to indexed data

    if (debug) then print(dump(nextData)) end

    local totalScore = Score()
    if (debug) then print("checking explored cells") end
    local CellCount10 = TotalExploredCells()
    local CellCount8 = TotalExplored8Cells()
    if (debug) then print(totalScore .. " " .. CellCount10 .. " " .. CellCount8) end
    if (debug) then print(nextData[1] .. " " .. nextData[2] .. " " .. nextData[3]) end

     if (totalScore >= nextData[1] and CellCount8 >= nextData[2] and CellCount10 >= nextData[3]) then
         --buy this trophy in the DB
         --display this trophy in the room.
         if (debug) then print("buying trophy") end
         --TODO actually buy the trophy
         local sql = "INSERT INTO trophysBought (itemCode, boughtOn) VALUES (" .. dataindex ..  ", " .. os.time() ..")"
         Exec(sql)
         lastTrophyBought = dataindex
         --DrawTrophy(dataindex)
         FindNextTrophy()

     else
        if (debug) then print("can't afford this next trophy") end
     end

end

 
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    if (debug) then print("creating trophy scene") end
    local sceneGroup = self.view
    sceneGroupCopy = sceneGroup
    -- Code here runs when the scene is first created but has not yet appeared on screen

    local changeGrid = display.newImageRect(sceneGroup, "themables/SmallGridButton.png", 300, 100)
    changeGrid.anchorX = 0
    changeGrid.anchorY = 0
    changeGrid.x = 60
    changeGrid.y = 1000

    changeGrid:addEventListener("tap", SwitchToSmallGrid)

    local changeGrid2 = display.newImageRect(sceneGroup, "themables/BigGridButton.png", 300, 100)
    changeGrid2.anchorX = 0
    changeGrid2.anchorY = 0
    changeGrid2.x = 390
    changeGrid2.y = 1000

    changeGrid2:addEventListener("tap", SwitchToBigGrid)

    local unlockTrophy = display.newImageRect(sceneGroup, "themables/UnlockTrophy.png", 300, 100)
    unlockTrophy.anchorX = 0
    unlockTrophy.anchorY = 0
    unlockTrophy.x = 210
    unlockTrophy.y = 1110

    unlockTrophy:addEventListener("tap", BuyTrophy)
    if (debug) then print("trophy event listener added") end

    local bg = display.newImageRect(sceneGroup, "themables/TrophyRoomBG.png", 720, 750 )
    bg.anchorX = 0
    bg.anchorY = 0
    bg.x = 0
    bg.y = 200


    local header = display.newImageRect(sceneGroup, "themables/TrophyRoom.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 100

    local textOptions = {}
    textOptions.parent =  sceneGroup
    textOptions.text = "Next Unlock at "
    textOptions.x = display.contentCenterX
    textOptions.y = 160
    textOptions.width = 550
    textOptions.height = 0
    textOptions.font = native.systemFont
    textOptions.fontSize = 20

    nextUnlockAt = display.newText(textOptions)
    nextUnlockAt.anchorY = 0
    
    if (debug) then print("created TrophyScene") end
 
end
 
 
-- show()
function scene:show( event )
 
    if (debug) then print("showing trophy scene") end
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        FindNextTrophy(sceneGroup)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
    end
end
 
 
-- hide()
function scene:hide( event )
    if (debug) then print("hiding trophy scene") end
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
 
    end
end
 
 
-- destroy()
function scene:destroy( event ) 
    if (debug) then print("destroyed trophy scene") end
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
 
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene