
local numberFont = TTFont.new("fonts/K2D-Bold.ttf",28)

local btnImg = {"gfx/UI/validBtn.png","gfx/UI/rollbackBtn.png","gfx/UI/cancelBtn.png","gfx/UI/continueBtn.png"}

btn = Core.class(Sprite)

function btn:init(fct)
	self.name = fct
	
	if fct == "valid" then
		self.imgPath = 1
		self.event = function() gameManager:executeAction() end
		self.name = "validation button"
	elseif fct == "rollback" then
		self.imgPath = 2
		self.event = function() gameManager:cancelAction() end
		self.name = "rollback button"
	elseif fct == "cancel" then
		self.imgPath = 3
		self.event = function() gameManager:cancelAction() end
		self.name = "cancel button"
	elseif fct == "continue" then
		self.imgPath = 4
		self.event = function() gameManager:continueAction() end
		self.name = "Continue button"	
	end
	
	local bouton = Bitmap.new(Texture.new(btnImg[self.imgPath]))
		bouton:setAnchorPoint(0.5,0.5)
		self:addChild(bouton)

	self:addEventListener(Event.MOUSE_UP, self.onMouseUp, self)
end


function btn:onMouseUp(event)
	if self:hitTestPoint(event.x, event.y) then
		event:stopPropagation()
		self.event()
	end
end

-- =================================================================
function createMeepleBank()

	local meepleBank = Bitmap.new(Texture.new("gfx/bg_meepleBank.png"))
		stage:addChild(meepleBank)
		stage.meepleBank = meepleBank
		meepleBank:setPosition(gRight-88, gBottom)
		--meepleBank:setScale(1.4)
		meepleBank:setAnchorPoint(1, 1)
	
	local meepleLayer = Sprite.new()
		meepleLayer:setAnchorPoint(0.5, 0.5)
		meepleLayer:setPosition(-82,-96)
		meepleLayer:setScale(.88)
		meepleBank.meepleLayer = meepleLayer
		meepleBank:addChild(meepleLayer)	
		
	local rscHilite = Bitmap.new(Texture.new("gfx/UI/roundHotspot.png"))
		rscHilite:setAnchorPoint(0.5,.5)
		rscHilite:setPosition(-190,-86)
		
	local hilite = MovieClip.new{
		{1, 1, rscHilite,{alpha = 0}},
		{2, 19, rscHilite,{alpha = {0, 1, "Linear"}}},
		{19, 26, rscHilite,{alpha = {1, .2, "Linear"}}},
		{26, 32, rscHilite,{alpha = {.2, 1, "Linear"}}},
		{32, 90, rscHilite,{alpha = {1, 0, "outSine"}}},
	}
	hilite:setStopAction(1)
	stage.meepleBank:addChild(hilite)
	stage.meepleBank.hilite = hilite
	
	local foodCounter = TextField.new(numberFont, "0")
		foodCounter:setAnchorPoint(1,0.5)
		foodCounter:setTextColor(0xffffff)
		foodCounter:setPosition(-194,-64)
		stage.meepleBank:addChild(foodCounter)
		stage.foodCounter = foodCounter

	local foodMax = TextField.new(numberFont, "/4")
		foodMax:setAnchorPoint(0,1)
		foodMax:setTextColor(0xffffff)
		foodMax:setPosition(-190,-64)
		foodMax:setScale(.6)
		stage.meepleBank:addChild(foodMax)
		stage.foodMax = foodMax
	
	local meepleCounter = TextField.new(numberFont, "0")
		meepleCounter:setAnchorPoint(0.5,0.5)
		meepleCounter:setTextColor(0xffffff)
		meepleCounter:setPosition(-82,-64)
		stage.meepleBank:addChild(meepleCounter)
		stage.meepleCounter = meepleCounter		
		
	local meepleNest = Bitmap.new(Texture.new("gfx/mire.png")) --Sprite.new()
		stage.meepleBank.meepleLayer:addChild(meepleNest)
		meepleNest:setAnchorPoint(0.5, 0.5)	
		--meepleNest:setScale(4)
		--meepleNest:setPosition(132, -24)
		stage.meepleNest = meepleNest
	
end

function updateMeepleBank(player)
	local curVal = tonumber(stage.foodCounter:getText())
	local newVal = player.resources['food']

	if curVal ~= newVal then -- je surveille que l'update soit justifié
		stage.foodCounter:setText(player.resources.food)
		--stage.meepleBank.hilite:gotoAndPlay(2)
	end
	stage.meepleCounter:setText(player.availableMeeples)
	stage.foodMax:setText("/"..(player.familySize *2))
end

function createPlayerBoard()

	local tokenTrack = Bitmap.new(Texture.new("gfx/UI/playerModuleBig.png"))
		stage:addChild(tokenTrack)
		stage.tokenTrack = tokenTrack
		tokenTrack:setPosition(gLeft+0, gTop+0)
		tokenTrack:setAnchorPoint(0,0)
	
	local tokenLayer = Sprite.new()
		tokenLayer:setAnchorPoint(0.5, 0.5)
		tokenLayer:setPosition(108,84)
		tokenTrack.tokenLayer = tokenLayer
		tokenTrack:addChild(tokenLayer)	
		
--	local playerNameField = TextField.new(numberFont, "0")
--		playerNameField:setAnchorPoint(0.5,0.5)
--		playerNameField:setTextColor(0xffffff)
--		playerNameField:setPosition(-190,-64)
--		stage.tokenTrack:addChild(playerNameField)
--		stage.playerNameField = playerNameField

	local xStep = 100	
	local slotImg = "gfx/mire.png"
	
	local slot1 = Bitmap.new(Texture.new(slotImg)) 
		slot1:setAnchorPoint(0.5, 0.5)	
		slot1:setPosition(0,0)
		stage.tokenTrack.tokenLayer:addChild(slot1)
		stage.slot1 = slot1
	local slot2 = Bitmap.new(Texture.new(slotImg)) 
		slot2:setAnchorPoint(0.5, 0.5)	
		slot2:setPosition(xStep,0)
		stage.tokenTrack.tokenLayer:addChild(slot2)
		stage.slot2 = slot2
	local slot3 = Bitmap.new(Texture.new(slotImg)) 
		slot3:setAnchorPoint(0.5, 0.5)	
		slot3:setPosition(2*xStep,0)
		stage.tokenTrack.tokenLayer:addChild(slot3)
		stage.slot3 = slot3
	local slot4 = Bitmap.new(Texture.new(slotImg)) 
		slot4:setAnchorPoint(0.5, 0.5)	
		slot4:setPosition(3*xStep,0)
		stage.tokenTrack.tokenLayer:addChild(slot4)
		stage.slot4 = slot4
	local slot5 = Bitmap.new(Texture.new(slotImg)) 
		slot5:setAnchorPoint(0.5, 0.5)	
		slot5:setPosition(4*xStep,0)
		stage.tokenTrack.tokenLayer:addChild(slot5)
		stage.slot5 = slot5
		
	for _, player in ipairs(gameManager.playerList) do
		player:spawnPlayerBoard()
        player:spawnPlayerToken()
    end	
end

-- Gestion du bouton d'acces au player.board
function createViewPlayerBoardBtn()

	local btnViewPBoard = Bitmap.new(Texture.new("gfx/UI/btn_playerboard_off.png"))
		gameManager.ui:addChild(btnViewPBoard)
		gameManager.btnViewPBoard = btnViewPBoard
		btnViewPBoard:setPosition(gLeft+160, gBottom)
		btnViewPBoard:setAnchorPoint(0, 1)

	local btnViewPBoardOn = Bitmap.new(Texture.new("gfx/UI/btn_playerboard_on.png"))
		gameManager.ui:addChild(btnViewPBoardOn)
		gameManager.btnViewPBoardOn = btnViewPBoardOn
		btnViewPBoardOn:setPosition(gLeft+160, gBottom)		
		btnViewPBoardOn:setAnchorPoint(0, 1)
		btnViewPBoardOn:setVisible(false) 
	
	local function onClick(target, event)
		if target:hitTestPoint(event.x, event.y) then
			event:stopPropagation()
			
			local player, isSnapshot = gameManager:getActivePlayer()		
			 
			if not isSnapshot then 
				if player.board:isVisible() then -- le player.board est affiché
					player.board:setVisible(false)
					gameManager.btnViewPBoard:setVisible(true)
					gameManager.btnViewPBoardOn:setVisible(false)
					gameManager.gameIsPaused = false
					
					player:resetConverters()
					
				else
					player.board:setVisible(true)
					player.board.isPlayable = false
					gameManager.btnViewPBoard:setVisible(false)
					gameManager.btnViewPBoardOn:setVisible(true)
					gameManager.gameIsPaused = true
					
					player:updateConverterBtn()
				end 
			end
		end
	end
		btnViewPBoard:addEventListener(Event.MOUSE_DOWN, onClick, btnViewPBoard)
end

-- Gestion du bouton d'acces au player.board
function createViewCardmarketBtn()
	if not gameManager.majorMarket then 
		gameManager.majorMarket = MajorImprovement.createAllMajorCards()
	end
	
	local btnViewCardMarket = Bitmap.new(Texture.new("gfx/UI/btn_cardmarket_off.png"))
		gameManager.ui:addChild(btnViewCardMarket)
		gameManager.btnViewCardMarket = btnViewCardMarket
		btnViewCardMarket:setPosition(gLeft+250, gBottom)
		btnViewCardMarket:setAnchorPoint(0, 1)

	local btnViewCardMarketOn = Bitmap.new(Texture.new("gfx/UI/btn_cardmarket_on.png"))
		gameManager.ui:addChild(btnViewCardMarketOn)
		gameManager.btnViewCardMarketOn = btnViewCardMarketOn
		btnViewCardMarketOn:setPosition(gLeft+250, gBottom)		
		btnViewCardMarketOn:setAnchorPoint(0, 1)
		btnViewCardMarketOn:setVisible(false) 
	
	local function onClick(target, event)
		if target:hitTestPoint(event.x, event.y) then
			event:stopPropagation()
			
			local player, isSnapshot = gameManager:getActivePlayer()		
			
			if not isSnapshot then 
				if gameManager.marketLayer:isVisible() then -- le marché est affiché...
					gameManager.marketLayer:setVisible(false)
					gameManager:cleanMajorCardsMarket()
					gameManager.gameIsPaused = false
					gameManager.btnViewCardMarket:setVisible(true)
					gameManager.btnViewCardMarketOn:setVisible(false)
					
				    gameManager.currentZoomedCard = nil
				else
					gameManager.marketLayer:setVisible(true)
					gameManager:updateMajorCardsMarket() 
					gameManager.gameIsPaused = true
					gameManager.btnViewCardMarket:setVisible(false)
					gameManager.btnViewCardMarketOn:setVisible(true)
				end 
			end
		end
	end
		btnViewCardMarket:addEventListener(Event.MOUSE_DOWN, onClick, btnViewCardMarket)
	
end


function getRoundInfo(currentRound)
    local harvestRounds = {4, 7, 9, 11, 13, 14}
    
    local currentPeriod = 1
    for i, harvestRound in ipairs(harvestRounds) do
        if currentRound <= harvestRound then
            currentPeriod = i
            break
        end
    end
    
    local t1, t2
    
    for i, harvestRound in ipairs(harvestRounds) do
        if harvestRound >= currentRound then
            local turnsUntilHarvest = harvestRound - currentRound + 1  -- +1 pour inclure le tour actuel
            
            if currentRound == harvestRound then
                t1 = string.format("Période %d - RÉCOLTE !", currentPeriod)
                t2 = "Phase de récolte en cours"
            elseif currentRound == 14 then
                t1 = "Dernier tour !" 
                t2 = "Récolte finale"
            elseif turnsUntilHarvest == 1 then
                t1 = string.format("Période %d, tour %d", currentPeriod, currentRound)
                t2 = "Dernier tour avant récolte !"
            else
                t1 = string.format("Période %d, tour %d", currentPeriod, currentRound)
                t2 = string.format("Récolte dans %d tours", turnsUntilHarvest)
            end
            break
        end
    end
    
    return t1, t2
end
