

-- Fichier main.lua >> point de départ du programme
-- après la lecture de l'ensemble des fichiers lua pour vérifier que tout semble conforme
-- le programme commence en exécutant les commandes de main.lua

-- ++++++++++++++++++++++++++ FONCTION STARTGAME +++++++++++++++++++++++++++++++++++++++++
print("") 
print("=====================================================================")
print("=====================================================================")
print("======================     NEW GAME     =============================")
print("=====================================================================")
print("=====================================================================")
print("")
print("🚨 À GERER :  ")
print("🚨 EN COURS :")
print("🚨 À GERER :  Gérer la problematique de bouffe post Naissance")

function startGame()
	actionDB = Actions.new()
	
	local UI = UI.new()
		stage:addChild(UI)
		stage.UI = UI
		
	gameManager:init(1)
	
	stage:addEventListener(Event.KEY_DOWN, function(e)
		if e.keyCode == KeyCode.D then  -- touche D pour Debug
			gameManager:debugState()
		end
	local p = gameManager:getActivePlayer()
		if e.keyCode == KeyCode.R then  -- touche R pour Debug
			p:counterState()
		end
		if e.keyCode == KeyCode.T then  -- touche T pour Debug
			p.timetable:debugPrint()
		end
		if e.keyCode == KeyCode.B then  -- touche B pour Debug
			p:printFarmInfo()
			--p:debugHouseState()
		end
		
		   -- NOUVEAU : Test enclos
		if e.keyCode == KeyCode.E then
			local p = gameManager:getActivePlayer()
			if p.board then
				p.board:debugEnclosures()
			end
		end

	end)
end
startGame()


function displayFPScounter()
    fpsFont = TTFont.new("fonts/K2D-Bold.ttf",32)
    local lastTime = os.timer()
    local frameCount = 0
    local fpsText = TextField.new(fpsFont, "FPS: 0")
    fpsText:setPosition(gRight-320, 32)
    stage.UI:addChild(fpsText)

    stage:addEventListener(Event.ENTER_FRAME, function()
    frameCount = frameCount + 1
    if os.timer() - lastTime >= 1 then
        fpsText:setText("FPS: "..frameCount)
        frameCount = 0
        lastTime = os.timer()
    end
    end)
end
displayFPScounter()