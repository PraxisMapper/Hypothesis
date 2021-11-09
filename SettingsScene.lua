local composer = require( "composer" )
local scene = composer.newScene()
--Native controls here need removed manually on hide().
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
 local ipTextField = ""
 local ipLabel = ""
 local header = ""
 local teamButton = ""
 local teamLabel = ""
 local teamTimer = ""
 local debugToggle = "" 
 
 local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end

 local function UpdateURL(event)
    SetServerAddress(event.text)    
 end

 local function TeamChangeListener(event)
    --button clicked to change team.
    local newTeam =0;
    if (factionID == 0 or factionID == 3) then
       newTeam = 1
    elseif (factionID == 1) then
        newTeam = 2
    elseif (factionID == 2) then
        newTeam = 3
    end
    SetTeamAssignment(newTeam)
    factionID = newTeam
 end

 local function checkTeamMembership()
    if (factionID == 0) then
        teamLabel.text = "Active Team: Undetermined"
    elseif (factionID == 1) then
            teamLabel.text = "Active Team: Red"
    elseif (factionID == 2) then
            teamLabel.text = "Active Team: Green"
    elseif (factionID == 3) then
            teamLabel.text = "Active Team: Blue"
    end
 end

 function setDebugImg()
    debug = not debug
    if (debug) then
        debugToggle.fill = {type = "image", filename = "themables/debugOn.png"}
    else
        debugToggle.fill = {type = "image", filename = "themables/debugOff.png"}
    end
    debugToggle.x = display.contentCenterX
    debugToggle.y = 650
 end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    debugToggle = display.newImageRect(sceneGroup, "themables/debugOn.png",300, 100)
    setDebugImg()
    debugToggle:addEventListener("tap", setDebugImg)
end 
 
-- show()
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

    header = display.newImageRect(sceneGroup, "themables/Settings.png",300, 100)
    header.x = display.contentCenterX
    header.y = 100
    header:addEventListener("tap", GoToSceneSelect)
        
    --native components dont play nicely like the built in OpenGL stuff does, so manage it slightly differently.
    ipLabel = display.newText(sceneGroup, "Server URL: (Start with 'http://', end with '/')", 25, 210, 600, 50, native.systemFont, 30)
    ipLabel.anchorX = 0

    teamLabel = display.newText(sceneGroup, "Active Team: ", 25, 410, 600, 50, native.systemFont, 30)
    teamLabel.anchorX = 0
    teamTimer = timer.performWithDelay(500, checkTeamMembership, -1)

    teamButton = display.newImageRect(sceneGroup, "themables/ChangeTeam.png",300, 100)
    teamButton.x = display.contentCenterX
    teamButton.y = 500
    teamButton:addEventListener("tap", TeamChangeListener)

    ipTextField = native.newTextField(350, 250, 650, 50)
    ipTextField.placeholder = "https://YourPraxisMapper.com/"
    ipTextField:addEventListener("userInput", UpdateURL)

    --TODO: GDPR delete button

    
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        ipTextField.text = GetServerAddress()
    end
end
 
-- hide()
function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        ipTextField:removeSelf() --native components dont automatically leave the screen.
        serverURL = GetServerAddress()
        timer.cancel(teamTimer)
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
    end
end
 
-- destroy()
function scene:destroy( event )
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