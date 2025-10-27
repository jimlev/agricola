
local basefont = TTFont.new("fonts/K2D-Bold.ttf",24)
--local basefont = TTFont.new("fonts/GentiumPlus-Bold.ttf",30)
local playerName = {"Jean-Pierre", "Roberto", "Sonia", "Bastien", "Hafid", "Agnès","Mona","Emilie","Ivan"}

local playerColors = {"blue","pink","green","brown","yellow","purple"}


-- Classe Player
Player = Core.class()

function Player:init(id, name, color, humanOrNot)
    self.id = id
	self.isHuman = humanOrNot
	self.name = name or table.remove(playerName, math.random(#playerName))
    self.color = color or id
	self.myTurnOrder = id
	self.hasPlayedThisRound = false
    -- Ressources
    self.resources = {
        wood = 0,
        clay = 0,
        stone = 0,
		reed = 0,
        grain = 0,
        vegetable = 1,
        sheep = 0,
        pig = 0,
        cattle = 0,
        food = 0  -- Démarrage avec 2 nourritures		
    }
	self.majorCard = {0}
	self.converters = {}
	self.pendingMajorCardIndex = nil
    -- Progression
    self.familySize = 2 -- total quand la famille s'aggrandit
    self.house = {rscType = "wood", rooms = 3}
    self.fields = 0
    self.pastures = 0
    
    -- Meeples disponibles
    self.availableMeeples = self.familySize  -- Démarre avec 2, peut aller jusqu'à 5
    self.placedMeeples = {}    -- Meeples déjà joués ce round
	
	self:initInventory()
	self.timetable = Timetable.new(self)
end

function Player:addResource(resource, amount)
    self.resources[resource] = (self.resources[resource] or 0) + amount
    -- Cibler le compteur lié à la ressource
	
    local counter = self.inventoryCounters[resource]

    if counter and counter.hilite then
		
		counter.hilite:gotoAndPlay(2) -- lance l’anim du highlight
    end
	self:updateInventory()
end


--  costs = { material = 5, reed = 2 } par exemple
function Player:canAfford(costs)
    if not costs or type(costs) ~= "table" then
        return true, 1  -- Si pas de coût, on peut "acheter" une fois
    end
    
    local maxQuantity = math.huge  -- Commence avec l'infini

    for resource, costPerUnit in pairs(costs) do
        local actualResource = resource

        -- Traduire le placeholder "material" vers la ressource réelle
        if resource == "material" and self.house and self.house.rscType then
            actualResource = string.gsub(self.house.rscType, "^m_", "")
        end
        -- Si le coût est 0, on ignore cette ressource
        if costPerUnit > 0 then
            local playerAmount = self.resources[actualResource] or 0
            if playerAmount < costPerUnit then
                return false, 0  -- Pas assez ne serait-ce que pour un
            end
            
            -- Calcule le nombre maximum possible pour cette ressource
            local maxForThisResource = math.floor(playerAmount / costPerUnit)
            if maxForThisResource < maxQuantity then
                maxQuantity = maxForThisResource
            end
	--    print(self.name.." peut acheter "..maxQuantity.." fois l'action grace à ses "..playerAmount,actualResource)
	      
        end
    end
    
    -- Si maxQuantity est encore infini (tous les coûts étaient 0)
    if maxQuantity == math.huge then
        return true, 1
    end
    
    return true, maxQuantity
end


function Player:payResources(costs)
    if not self:canAfford(costs) then return false end

    for resource, cost in pairs(costs) do
        local actualResource = resource

        -- Traduire le placeholder "material" vers la ressource réelle
        if resource == "material" and self.house and self.house.rscType then
            actualResource = string.gsub(self.house.rscType, "^m_", "")
        end

        -- Sécurité au cas où la ressource n’existe pas
        if not self.resources[actualResource] then
           print("⚠️ ["..self.name.."] Resource inconnue : "..tostring(actualResource))
            return false
        end

        -- Débit
        self.resources[actualResource] = self.resources[actualResource] - cost
		local counter = self.inventoryCounters[actualResource]
		counter.hilite:gotoAndPlay(2)
        print("💰 ["..self.name.."] paie "..cost.." "..actualResource.." (reste "..self.resources[actualResource]..")")
    end
	self:updateInventory()
    return true
end


function Player:spawnPlayerToken()
    local tokenFocus = Bitmap.new(Texture.new("gfx/UI/focusP_Token.png"))
	local token = Bitmap.new(Texture.new("gfx/UI/" .. self.color .. "P_Token.png"))
	
	tokenFocus:setAnchorPoint(.5,.5)
	token:setAnchorPoint(.5,.5)
	local slotNum = "slot"..self.id	
	
	self.token = token
	self.token:addChild(tokenFocus)
	self.tokenFocus = tokenFocus
	self:updateMyTokenPlace(self.myTurnOrder)
	
	self.token:addEventListener(Event.MOUSE_DOWN, self.showMePlayer, self)
	self.token:addEventListener(Event.MOUSE_UP, self.hideMePlayer, self)
end


function Player:updateMyTokenPlace(orderIndex)
    local slot = stage["slot"..orderIndex]

    -- ⚠️ On vire le token de son emplacement actuel sinon c'est le merdier
    if self.token:getParent() then
        self.token:getParent():removeChild(self.token)
    end

    slot:addChild(self.token)

    self.myTurnOrder = orderIndex
    if self.myTurnOrder ~= 1 then self.tokenFocus:setVisible(false) end
end

function Player:showMePlayer(event)
	if self.token:hitTestPoint(event.x, event.y) and gameManager.currentPlayer ~= self.myTurnOrder then
		self.inventaire:setVisible(true)
		gameManager.playerList[gameManager.currentPlayer].inventaire:setVisible(false)
		self.board:setVisible(true)
		self.tokenIsPressed = true
	end
end


function Player:hideMePlayer(event)
	if self.tokenIsPressed then
		self.inventaire:setVisible(false)
		gameManager.playerList[gameManager.currentPlayer].inventaire:setVisible(true)
		self.board:setVisible(false)
		self.tokenIsPressed = false
	end
end


function Player:pickMeeple()
	if self.availableMeeples == 0 then return false end
	
	local currentMeepleId = (self.familySize - self.availableMeeples)+1
	
 	local meeple = farmerMeeple.new(self, self.id, self.color, currentMeepleId)
	meeple:setAnchorPoint(.5,.5)
	stage.meepleNest:addChild(meeple)

	gameManager.meepleInPlay = meeple	
end	

function Player:initInventory()

	local inventaire = Bitmap.new(Texture.new("gfx/bg_inventaire.png"))
		stage.UI:addChild(inventaire)
		inventaire:setPosition(W/2, gBottom)
		inventaire:setAnchorPoint(0.5, 1)
		self.inventaire = inventaire
		self.inventaire:setVisible(false)
			
	local myColorEnv = Bitmap.new(Texture.new("gfx/UI/" .. self.color .. "Inv_focus.png"))
		self.inventaire:addChild(myColorEnv)
		myColorEnv:setAnchorPoint(0.5, 1)
		myColorEnv:setX(-44)
	
	self.inventoryCounters = {}
	
	local resourceOrder = {"wood","clay","stone","reed","grain","vegetable","sheep","pig","cattle","food"}

	for i, resourceName in ipairs(resourceOrder) do
	local counter = TextField.new(basefont, "0")
		counter:setAnchorPoint(0.5,0)
		counter:setTextColor(0xffffff)
		counter:setPosition(-528+(97 * i),-42)	
		inventaire:addChild(counter)
		
		self.inventoryCounters[resourceName] = counter
	--	if resourceName == 'food' then counter:setVisible(false) end -- le Grand compteur fait l'affichage
		
	local rscHilite = Bitmap.new(Texture.new("gfx/focus_inventaire.png"))
	rscHilite:setAnchorPoint(0.5,.5)
	rscHilite:setPosition(4,-38)
	
	local hilite = MovieClip.new{
		{1, 1, rscHilite,{alpha = 0}},
		{2, 19, rscHilite,{alpha = {0, 1, "Linear"}}},
		{19, 26, rscHilite,{alpha = {1, .2, "Linear"}}},
		{26, 32, rscHilite,{alpha = {.2, 1, "Linear"}}},
		{32, 90, rscHilite,{alpha = {1, 0, "outSine"}}},
	}

		hilite:setStopAction(1)
		self.inventoryCounters[resourceName]:addChild(hilite)
		self.inventoryCounters[resourceName].hilite = hilite
	end
	self:updateInventory()
end

function Player:updateInventory()
    for resourceName, counter in pairs(self.inventoryCounters) do
		
		if resourceName == 'food' and stage.foodCounter then 
			updateMeepleBank(self)
		end
		counter:setText(tostring(self.resources[resourceName] or 0))
    end
end

function Player:spawnPlayerBoard()
	self.board = PlayerBoard.new(self)
	gameManager.farmLayer:addChild(self.board)
	self.board:setVisible(false)

	local initialMi = MajorImprovement.new(0)
	self.majorCard = {initialMi}
	local majorI_one = RscConverter.new(self, initialMi, 0)
	table.insert(self.converters, majorI_one)
end

function Player:neededFoodCount() -- TODO gérer l'aggrandissement de famille de fin de tour
	local foodQty
	if gameManager.playerCount == 1 then
		foodQty = 3 * self.familySize
	else
		foodQty = 2 * self.familySize
	end
	
	return foodQty
end	

-- ########################## HELPERS CONVERTER

function Player:updateConverterBtn()
	for i = 1, #self.converters do
		self.converters[i]:updateButtons()
	end
end

function Player:resetConverters()
	for i = 1, #self.converters do
		self.converters[i]:cancel("reset global ")
	end
end

function Player:resetConverterCount()
	for i = 1, #self.converters do
		self.converters[i].useCount = 0
	end
end

function Player:counterState()
	for i = 1, #self.converters do
		print(self.converters[i].mi.name,self.converters[i].useCount)
	end
end


-- !#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!
-- !#!#!#!#!#!#!#!#!#!#!#  HELPERS DES RECOLTES   !#!#!#!#!#!#!#!#!#!#!#
-- !#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!

-- Retourne une phrase récapitulative de la récolte
function Player:getHarvestSummary()

    local summary = { grain = 0, vegetable = 0 }

    for row = 1, #self.board.boxes do
        for col = 1, #self.board.boxes[row] do
            local box = self.board.boxes[row][col]
            local seedType, production = box:harvest()
            if seedType and summary[seedType] then
                summary[seedType] = summary[seedType] + production
				self:addResource(seedType, production)
            end
        end
    end

    if summary.grain == 0 and summary.vegetable == 0 then
        return "Rien à récolter cette saison."
    else
        return string.format("Vous obtenez: %d blé et %d légume", summary.grain, summary.vegetable)
    end
end

function Player:getFoodSummary()
	return "à table"
end

function Player:getReproSummary()
	return "233"
end