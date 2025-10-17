
local initI_DATA = {
	{
        name = "base camp",
        cost = { clay=0 },
        effectType = "active",
		reward = {food=1},
        png = "gfx/major/converter/base_foodConv.png",
		uiModel = 0
    }
}

local MajI_DATA = {
    {
        name = "Foyer1",
        cost = { clay=2 },
        effectType = "active",
		reward = {food=2},
		useLimit = 1,
        png = "gfx/major/major_01.png",
		uiModel = 11
    },
	{
        name = "Foyer2",
        cost = { clay=3 },
        effectType = "active",
		reward = {food=2},
		useLimit = 1,
        png = "gfx/major/major_02.png",
		uiModel = 11
    },
    {
        name = "Fourneau1",
        cost = {clay=4 },
        effectType = "active",
		reward = {food=3},
		useLimit = 1,
        png = "gfx/major/major_03.png",
		uiModel = 12
    },
	{
        name = "Fourneau2",
        cost = { clay=5 },
        effectType = "active",
		reward = {food=3},
		useLimit = 1,
        png = "gfx/major/major_04.png",
		uiModel = 12
    },
	-- AMÉLIORATION PASSIVE    
    {
        name = "Puits",
        cost = { stone=3, clay=1 },
        effectType = "passive",
		reward = {food=5},
        png = "gfx/major/major_05.png",
		uiModel = 4
    },
    {
        name = "Four en argile",
        cost = { clay=3, stone=1 },
        effectType = "active",
		reward = {food=5},
		useLimit = 1,
        png = "gfx/major/major_06.png",
		uiModel = 21
    },
    {
        name = "Four en pierre",
        cost = { clay=1, stone=3 },
        effectType = "active",
		reward = {food=4},
		useLimit = 2,
        png = "gfx/major/major_07.png",
		uiModel = 22
    },
	-- AMÉLIORATION PASSIVE
    {
        name = "Menuiserie",
        cost = { wood=2, stone=2 },
        effectType = "active",
		reward = {food=2},
        png = "gfx/major/major_08.png",
		uiModel = 31
    },
	-- AMÉLIORATION PASSIVE
    {
        name = "Poterie",
        cost = { clay=2, stone=2 },
        effectType = "active",
		reward = {food=2},		
        png = "gfx/major/major_09.png",
		uiModel = 32
    },
	-- AMÉLIORATION PASSIVE
    {
        name = "Vannerie",
        cost = { reed=2, stone=2 },
        effectType = "active",
		reward = {food=3},		
        png = "gfx/major/major_10.png",
		uiModel = 33
    }
}

-- Classe MajorImprovement
MajorImprovement = Core.class(Sprite)

function MajorImprovement:init(id)
    local data = MajI_DATA[id]
	if id == 0 then data = initI_DATA[1] end -- le feu par defaut pour tous les joueurs
    
	self.id = id
    self.name = data.name
    self.cost = data.cost or {}
    self.reward = data.reward or {}
    self.effectType = data.effectType
	if data.useLimit then self.useLimit = data.useLimit end

    self.uiModel = data.uiModel
	self:setAnchorPoint(0.5, 0.5)

    local path = string.format("gfx/major/major_"..id..".png")
    self.cardImg = Bitmap.new(Texture.new(path))
		self.cardImg:setAnchorPoint(0.5, 0.5)
	self.placeholder = Bitmap.new(Texture.new("gfx/major/major_none.png"))
		self.placeholder:setAnchorPoint(0.5, 0.5)	
	self.focus = Bitmap.new(Texture.new("gfx/major/major_focus.png"))
		self.focus:setAnchorPoint(0.5, 0.5)
	
	self:addChild(self.cardImg)
		
	self.taken = false
	self.isZoomed = false
	
	self:addEventListener(Event.MOUSE_DOWN, self.onClick, self)
    self:addEventListener(Event.MOUSE_MOVE, self.onBeginSwipe, self)
	self:addEventListener(Event.MOUSE_UP, self.onTouchesEnd, self)
end

--gameManager:getActivePlayer()
function MajorImprovement:zoomCard()
	local player, isSnapshot = gameManager:getActivePlayer()

    if not self.isZoomed then
	--	gameManager.gameIsPaused = true
        self.isZoomed = true
        gameManager.currentZoomedCard = self
    end
	if gameManager.inBuyCardMode then
		if self:canAfford(player) then	--on stocke la carte convoitée pour l'achat
			-- Si aucune carte en attente, on ajoute une nouvelle entrée
			if not player.pendingMajorCardIndex then
				table.insert(player.majorCard, self.id)
				player.pendingMajorCardIndex = #player.majorCard
			else
				-- Sinon, on remplace la carte en attente
				player.majorCard[player.pendingMajorCardIndex] = self.id
			end
			
				gameManager:handleCardBuy(self)
		else 
			if gameManager.ui.popupLayer.continueBtn then
			-- Cette carte est trop chère !
				gameManager.ui.popupLayer:removeChild(gameManager.ui.popupLayer.continueBtn)
				gameManager.ui.popupLayer.continueBtn = nil
				gameManager.pendingAction.hasValidationButton = false
			end
		end
	end	
end


-- ##########################################################
-- ##################  SWIPE SWIPE SWIPE ####################
-- ##########################################################
function MajorImprovement:onClick(event)
	if gameManager.marketLayer:isVisible() and self:hitTestPoint(event.x, event.y) and not self.isZoomed then
		event:stopPropagation()
		self:clicToCard(self)	
	end	
end

-- =========================================================
-- =================================   HELPERS  ============
-- ========================================================= 

function MajorImprovement:backInMarket()
	local card = gameManager.currentZoomedCard
	
	if gameManager.currentZoomedCard and gameManager.currentZoomedCard == self then

		local originX = self.myCoords[1]										 
        local originY = self.myCoords[2]

        local mc = MovieClip.new{
            {1, 15, self, {
                x = {self:getX(), originX, "easeOutQuad"},
                y = {self:getY(), originY, "outCircular"},
				scale = {self:getScale(), self.scaleFactor, "linear"}
            }}
        }
        gameManager.marketLayer.majorShelf:addChild(mc)
		gameManager.marketLayer.majorShelf.mc = mc
		self.isZoomed = false
	end
end

function MajorImprovement:greyOut()
    if self.cardImg then
        self.cardImg:setColorTransform(0.8, 0.8, 0.8, 1) -- tons gris
    end
	self.focus:setVisible(false)
    self.isGreyed = true
end


function MajorImprovement:restore()
    if self.cardImg then
        self.cardImg:setColorTransform(1, 1, 1, 1) -- reset couleurs
    end
    self.isGreyed = false
end


function MajorImprovement:updateMarketView()
	local player, isSnapshot = gameManager:getActivePlayer()
    if self.taken then
		return
    end

    if self:canAfford(player) then
        self:restore()
		self:addChild(self.focus)
		self.focus:setVisible(true)
    else
        self:greyOut()
    end
end


function MajorImprovement:isTaken()
	
    self.taken = true
	self.focus:setVisible(false)
	self:removeChild(self.cardImg)
	self:addChild(self.placeholder)
    -- On enlève l’event clic
	self:removeListeners()
	self:updateMarketView()
end

function MajorImprovement:removeListeners() -- les cartes ne sont plus cliquables
    self:removeEventListener(Event.MOUSE_DOWN, self.onClick, self)
    self:removeEventListener(Event.MOUSE_MOVE, self.onBeginSwipe, self)
    self:removeEventListener(Event.MOUSE_UP, self.onTouchesEnd, self)
end


-- Vérifie si un joueur peut se la payer
function MajorImprovement:canAfford(player)
        return player:canAfford(self.cost)
end

-- ##########################################################
-- ##################  SWIPE SWIPE SWIPE ####################
-- ##########################################################

 
function MajorImprovement:onBeginSwipe(event)
	if not gameManager.marketLayer:isVisible() then return end
    if not self.isZoomed then return end
    event:stopPropagation()
    -- Stocker la position de départ du swipe
    if not self.swipeStartX then
        self.swipeStartX = event.x
        self.swipeStartY = event.y
    end
end

function MajorImprovement:onTouchesEnd(event)
	 if not gameManager.marketLayer:isVisible() then return end
    if not self.isZoomed or not self.swipeStartX then 
        self.swipeStartX = nil
        self.swipeStartY = nil
        return 
    end
    
    local deltaX = event.x - self.swipeStartX
    local deltaY = event.y - self.swipeStartY
    
    -- Détecter un swipe horizontal (et pas vertical)
    local minSwipeDistance = 50
    if math.abs(deltaX) > minSwipeDistance and math.abs(deltaX) > math.abs(deltaY) then
        --local player = gameManager:getActivePlayer()
        
        if deltaX > 0 then
            -- Swipe vers la droite = carte précédente
            self:navigateToCard( -1)
        else
            -- Swipe vers la gauche = carte suivante
            self:navigateToCard( 1)
        end
    end
    
    -- Reset
    self.swipeStartX = nil
    self.swipeStartY = nil
end

function MajorImprovement:navigateToCard(direction)

	local nextCard, nextIndex = MajorImprovement.nextNotTakenCard(self.id, direction)
	
    if nextCard and not nextCard.taken then
		
		-- je range la carte actuellement zoomée
		self:backInMarket()
		
		-- Animation vers le zoom pour la nouvelle carte
		local endX = W / 2
		local endY = H / 2 - 120

		local mcZoom = MovieClip.new{
			{1, 20, nextCard, {
				x = {nextCard:getX(), endX, "easeInOutQuad"},
				y = {nextCard:getY(), endY, "outCircular"},
				scale = {nextCard.scaleFactor, 1.2, "linear"}
			}}
		}
		gameManager.marketLayer.majorShelf:addChild(mcZoom)
		gameManager.marketLayer.majorShelf.mcZoom = mcZoom
		mcZoom:addEventListener(Event.COMPLETE, function()
			nextCard:zoomCard()
		end)
    end
end

function MajorImprovement:clicToCard(card)
    if card.taken then return end
	
    if gameManager.currentZoomedCard ~= nil then
	   gameManager.currentZoomedCard:backInMarket()
	end
	

    local endX = W / 2
    local endY = H / 2 - 120

    local mc = MovieClip.new{
       {1, 20, card, {
				x = {card:getX(), endX, "easeInOutQuad"},
				y = {card:getY(), endY, "outCircular"},
				scale = {card.scaleFactor, 1.2, "linear"}
			}}
    }
    gameManager.marketLayer.majorShelf:addChild(mc)

    mc:addEventListener(Event.COMPLETE, function()
        card:zoomCard()
    end)
end

-- ===========================================================================
-- ============================ FONCTIONS UTILITAIRES ========================
-- ===========================================================================


-- pour naviguer uniquement entre les cartes disponibles
function MajorImprovement.nextNotTakenCard(startIndex, direction)
    local totalCards = #gameManager.majorMarket
    local index = startIndex

    for i = 1, totalCards do
        index = index + direction

        -- Boucle circulaire
--        if index < 1 then
--            index = totalCards
--        elseif index > totalCards then
--            index = 1
--        end

        local candidate = gameManager.majorMarket[index]
        if candidate and not candidate.taken then
            return candidate, index
        end
    end

    -- Aucun candidat disponible
    return nil, nil
end


-- Fonction pour créer tous les panneaux selon le contexte
function MajorImprovement.createAllMajorCards()
    local majorCards = {}

	local cardImgSize = Bitmap.new(Texture.new("gfx/major/major_focus.png")) --chargée pour interroger sa Width

	local margin = 200
	local marketSize = (gRight-gLeft) - margin
	local cardSize = marketSize / 10
	local cardScaling = ((cardSize / cardImgSize:getWidth()) * 100) / 100
	
	local col = cardSize
	local startX, startY = gLeft + margin/2 + (cardSize/2) , gBottom - 275
	
	for i, id in ipairs(MajI_DATA) do
		
		local cardInstance = MajorImprovement.new(i)
		
        table.insert(majorCards, cardInstance)

		gameManager.marketLayer.majorShelf:addChild(cardInstance)
		cardInstance.myCoords = {startX + ((i-1)* col ),startY}
		cardInstance:setPosition(cardInstance.myCoords[1],cardInstance.myCoords[2])
		
		cardInstance.scaleFactor = cardScaling
		cardInstance:setScale(cardInstance.scaleFactor)
    end
	return majorCards
end
