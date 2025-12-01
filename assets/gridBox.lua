-- classe qui manage les cases des fermes des joueurs

local numberFont = TTFont.new("fonts/K2D-Bold.ttf",28)

GridBox = Core.class(Sprite)

function GridBox:init(col, row, player)
	local backImg = Bitmap.new(Texture.new("gfx/playerboard/farmBackTile_square.png"))
	self:addChild(backImg)
	self.backImg = backImg
	
    self.col = col
    self.row = row
	self.myPlayer = player
	
	--self.state = "friche" -- gestion du visuel
	
	self.myType = "empty" -- "field", "pasture", "house"
		self.mySeed = nil -- "grain", "vegetable" ou nil (default) 
		self.mySeedAmount = 0 -- nb de graines restantes 
		self.mySpecies = nil -- "sheep", "pig", "cattle" 
		self.animals = {sheep = 0, pig = 0, cattle = 0}  -- Animaux dans cette case
		self.pastureLimit = 0 -- capacité max 
		self.hasStable = false -- if true >>> pastureLimit +2
		self:setGrowingStatus()  -- une graine est-elle en cours de pousse ?
		
    -- visuels possibles
	self.imgs = {
		friche   = Bitmap.new(Texture.new("gfx/playerboard/friche_box_square.png")),
		laboure  = Bitmap.new(Texture.new("gfx/playerboard/labourage_box_square.png")),
		pasture  = Bitmap.new(Texture.new("gfx/playerboard/paturage_box_square.png")),
		etable   = Bitmap.new(Texture.new("gfx/playerboard/etable_box.png")),
		
		-- Maisons bois
		woodhouse   = Bitmap.new(Texture.new("gfx/playerboard/woodhouse_box1_square.png")),
		woodhouse2  = Bitmap.new(Texture.new("gfx/playerboard/woodhouse_box2_square.png")),
		woodhouse3  = Bitmap.new(Texture.new("gfx/playerboard/woodhouse_box3_square.png")),
		
		-- Maisons argile
		clayhouse   = Bitmap.new(Texture.new("gfx/playerboard/clayhouse_box1_square.png")),
		clayhouse2  = Bitmap.new(Texture.new("gfx/playerboard/clayhouse_box2_square.png")),
		clayhouse3  = Bitmap.new(Texture.new("gfx/playerboard/clayhouse_box3_square.png")),
		
		-- Maisons pierre
		stonehouse  = Bitmap.new(Texture.new("gfx/playerboard/stonehouse_box1.png")),
		stonehouse2 = Bitmap.new(Texture.new("gfx/playerboard/stonehouse_box2.png")),
		stonehouse3 = Bitmap.new(Texture.new("gfx/playerboard/stonehouse_box3.png"))
	}

    -- ajouter tous les visuels mais invisibles
    for _, img in pairs(self.imgs) do
        img:setVisible(false)
        self:addChild(img)
    end
	
	self.meepleLayer = Sprite.new()
        self:addChild(self.meepleLayer)
	
	self.sheepSprite = Bitmap.new(Texture.new("gfx/fences/sheepMeeple.png"))
		self.sheepSprite:setAnchorPoint(0.5,0.5)
		self.sheepSprite:setPosition(132,100)
		self.meepleLayer:addChild(self.sheepSprite)
		self.sheepSprite:setVisible(false)

	self.pigSprite = Bitmap.new(Texture.new("gfx/fences/pigMeeple.png"))
		self.pigSprite:setAnchorPoint(0.5,0.5)
		self.pigSprite:setPosition(132,100)		
		self.meepleLayer:addChild(self.pigSprite)
		self.pigSprite:setVisible(false)
		
	self.cattleSprite = Bitmap.new(Texture.new("gfx/fences/cattleMeeple.png"))
		self.cattleSprite:setAnchorPoint(0.5,0.5)
		self.cattleSprite:setPosition(132,100)	
		self.meepleLayer:addChild(self.cattleSprite)
		self.cattleSprite:setVisible(false)	
	
	-- plantation: legumes et grain
	--  MovieClip grain (9 frames : 3×3grains, 3×2grains, 3×1grain)
	self.grainMeeple = MovieClip.new({
		-- 3 grains (frames 1-3)
		{1, 1, Bitmap.new(Texture.new("gfx/fences/grain_31.png"))},
		{2, 2, Bitmap.new(Texture.new("gfx/fences/grain_32.png"))},
		{3, 3, Bitmap.new(Texture.new("gfx/fences/grain_33.png"))},
		-- 2 grains (frames 4-6)
		{4, 4, Bitmap.new(Texture.new("gfx/fences/grain_21.png"))},
		{5, 5, Bitmap.new(Texture.new("gfx/fences/grain_22.png"))},
		{6, 6, Bitmap.new(Texture.new("gfx/fences/grain_23.png"))},
		-- 1 grain (frames 7-9)
		{7, 7, Bitmap.new(Texture.new("gfx/fences/grain_11.png"))},
		{8, 8, Bitmap.new(Texture.new("gfx/fences/grain_12.png"))},
		{9, 9, Bitmap.new(Texture.new("gfx/fences/grain_13.png"))}
	})
	self.grainMeeple:setAnchorPoint(0.5, 0.5)
	self.grainMeeple:setPosition(132, 132)
	self.grainMeeple:setVisible(false)
	self.grainMeeple:stop()
	self:addChild(self.grainMeeple)

	-- MovieClip vegetable (même structure)
	self.vegeMeeple = MovieClip.new({
		-- 2 légumes (frames 1-3)
		{1, 1, Bitmap.new(Texture.new("gfx/fences/vege_21.png"))},
		{2, 2, Bitmap.new(Texture.new("gfx/fences/vege_22.png"))},
		{3, 3, Bitmap.new(Texture.new("gfx/fences/vege_23.png"))},
		-- 1 légume (frames 4-6)
		{4, 4, Bitmap.new(Texture.new("gfx/fences/vege_11.png"))},
		{5, 5, Bitmap.new(Texture.new("gfx/fences/vege_12.png"))},
		{6, 6, Bitmap.new(Texture.new("gfx/fences/vege_13.png"))}
	})
	self.vegeMeeple:setAnchorPoint(0.5, 0.5)
	self.vegeMeeple:setPosition(132, 148)
	self.vegeMeeple:setVisible(false)
	self.vegeMeeple:stop()
	self:addChild(self.vegeMeeple)
	
	-- Stocker la frame actuelle 
	self.currentGrainFrame = nil
	self.currentVegeFrame = nil
	
    -- badge
    local badge = Bitmap.new(Texture.new("gfx/playerboard/harvestCount_box.png"))
		badge:setAnchorPoint(0.5,0.5)
		badge:setPosition(212, 188) 
		self:addChild(badge)
		self.badge = badge

    local badgeCount = TextField.new(numberFont, "0")
		badgeCount:setAnchorPoint(0.5,1)
		badgeCount:setTextColor(0xffffff)
		badgeCount:setPosition(0, 24) -- centre du badge
		badge:addChild(badgeCount)
		self.badgeCount = badgeCount
		
	self.badge:setVisible(false)	-- init de la classe gridBox. Tous les badges sont masqués

	-- Sprite animal (meeple par-dessus)
	self.animalSprite = Bitmap.new(Texture.new("gfx/fences/sheepMeeple.png"))
	self.animalSprite:setVisible(false)
	self:addChild(self.animalSprite)

 -- === NOUVEAU : Gestion des clôtures et enclos ===
	self.enclosureId = nil
	self.fenceData = {
		top = false,
		bottom = false,
		left = false,
		right = false
	}
	self.fenceTurnCreated = nil
	
	 -- === NOUVEAU : Visuels des clôtures ===
    self.fenceSprites = {}
    
    -- Clôture horizontale du haut
    local fenceTop = Bitmap.new(Texture.new("gfx/fences/horizontalFence.png"))
    fenceTop:setAnchorPoint(0.5, 0.5)
    fenceTop:setPosition(self.backImg:getWidth()/2, 16)
    self:addChild(fenceTop)
	--fenceTop:setRotation(math.random(5)-3)
    fenceTop:setVisible(false)
    self.fenceSprites.top = fenceTop
    
    -- Clôture horizontale du bas
    local fenceBottom = Bitmap.new(Texture.new("gfx/fences/horizontalFence.png"))
    fenceBottom:setAnchorPoint(0.5, 0.5)
    fenceBottom:setPosition(self.backImg:getWidth()/2, self.backImg:getHeight()-16)
    self:addChild(fenceBottom)
	--fenceBottom:setRotation(math.random(5)-2)
    fenceBottom:setVisible(false)
    self.fenceSprites.bottom = fenceBottom
    
    -- Clôture verticale gauche
    local fenceLeft = Bitmap.new(Texture.new("gfx/fences/verticalFence.png"))
	fenceLeft:setAnchorPoint(0.5, 0.5)
    fenceLeft:setPosition(10, self.backImg:getHeight()/2)
    self:addChild(fenceLeft)
	--fenceLeft:setRotation(math.random(5)-3)
    fenceLeft:setVisible(false)
    self.fenceSprites.left = fenceLeft
    
    -- Clôture verticale droite
    local fenceRight = Bitmap.new(Texture.new("gfx/fences/verticalFence.png"))
	fenceRight:setAnchorPoint(0.5, 0.5)
    fenceRight:setPosition(self.backImg:getWidth()-8, self.backImg:getHeight()/2)
    self:addChild(fenceRight)
	--fenceRight:setRotation(math.random(5)-2)
    fenceRight:setVisible(false)
    self.fenceSprites.right = fenceRight	

    local stable = Bitmap.new(Texture.new("gfx/playerboard/stable.png"))
		stable:setAnchorPoint(0,0)
		stable:setPosition(12, 12) -- ajuste selon ton sprite
		self:addChild(stable)
		self.stable = stable
		self.stable:setVisible(false)	
		
	self:addEventListener(Event.MOUSE_DOWN, self.onClick, self)
	
    -- état initial
    self:updateVisual()
end

function GridBox:onClick(event)
	if self:hitTestPoint(event.x, event.y) and self:getParent():isItPlayable() then
		event:stopPropagation()
		gameManager:handleBoxClick(self)
	end 
end

function GridBox:getLogicalState()
    if self.myType == "empty" then
        return "friche"
    
    elseif self.myType == "field" then
        return "laboure"
    
    elseif self.myType == "pasture" then
        return "pasture"
    
    elseif self.myType == "house" then
        -- Construction dynamique du sprite maison
        local mat = self.myPlayer.house.rscType
        local variant = (self.col + self.row) % 3 + 1
        local suffix = variant == 1 and "" or tostring(variant)
        return string.format("%shouse%s", mat, suffix)
    else
        return "friche"
    end
end

function GridBox:updateVisual()
    local s = self:getLogicalState()

    -- 1. Cacher tous les sprites de fond
    for _, img in pairs(self.imgs) do
        img:setVisible(false)
    end
    
    -- 2. Afficher le fond correspondant au logicalstate
    local img = self.imgs[s]
    if img then 
        img:setVisible(true)
	--	self:setRotation((math.random(20)-10)/10)
    else
        print("⚠️ Sprite introuvable pour state:", s)
    end
    
	-- 3. Gérer les graines (field) - OVERLAY
	if self.myType == "field" then
		-- Badge récolte
		self.badge:setTexture(Texture.new("gfx/playerboard/harvestCount_box.png"))
		self.badgeCount:setText(self.mySeedAmount)
		self.badge:setVisible(true)
		
		if self.mySeed then
			if self.mySeed == "grain" then
				-- Calculer la plage de frames selon mySeedAmount
				local frameRanges = {
					[3] = {1, 3},   -- 3 grains = frames 1-3
					[2] = {4, 6},   -- 2 grains = frames 4-6
					[1] = {7, 9}    -- 1 grain  = frames 7-9
				}
				
				local range = frameRanges[self.mySeedAmount]
				if range then
					-- Choisir frame aléatoire si pas déjà définie pour cette quantité
					if not self.currentGrainFrame or 
					   self.currentGrainFrame < range[1] or 
					   self.currentGrainFrame > range[2] then
						self.currentGrainFrame = math.random(range[1], range[2])
					end
					
					self.grainMeeple:gotoAndStop(self.currentGrainFrame)
					self.grainMeeple:setVisible(true)
				end
				
				self.vegeMeeple:setVisible(false)
				
			elseif self.mySeed == "vegetable" then
				-- Calculer la plage de frames selon mySeedAmount
				local frameRanges = {
					[2] = {1, 3},   -- 2 légumes = frames 1-3
					[1] = {4, 6}    -- 1 légume  = frames 4-6
				}
				
				local range = frameRanges[self.mySeedAmount]
				if range then
					if not self.currentVegeFrame or 
					   self.currentVegeFrame < range[1] or 
					   self.currentVegeFrame > range[2] then
						self.currentVegeFrame = math.random(range[1], range[2])
					end
					
					self.vegeMeeple:gotoAndStop(self.currentVegeFrame)
					self.vegeMeeple:setVisible(true)
				end
				
				self.grainMeeple:setVisible(false)
			end
		else
			-- Champ vide
			self.grainMeeple:setVisible(false)
			self.vegeMeeple:setVisible(false)
			self.currentGrainFrame = nil
			self.currentVegeFrame = nil
		end
		
--	else
--		self.badge:setVisible(false)
--		self.grainMeeple:setVisible(false)
--		self.vegeMeeple:setVisible(false)
	end
	
-- 4. Gérer les pâtures et animaux
	if self.myType == "pasture" then
		local totalAnimals = (self.animals.sheep or 0) + (self.animals.pig or 0) + (self.animals.cattle or 0)
		
		-- Mettre à jour le CONTENU du badge (si visible)
		if self.badge:isVisible() then
			if totalAnimals > 0 then
				self.badge:setPosition(128, 188) 
				self.badgeCount:setPosition(-16, 24) 
				self.badgeCount:setText(totalAnimals .. "/" .. (self.pastureLimit or 0))
			else
				self.badge:setPosition(128, 188)
				self.badgeCount:setPosition(-6, 24)
				self.badgeCount:setText(self.pastureLimit or 0)
			end
		end
		
		-- Meeples animaux si présents
		if self.mySpecies and totalAnimals > 0 then
			self.sheepSprite:setVisible(self.mySpecies == "sheep")
			self.pigSprite:setVisible(self.mySpecies == "pig")
			self.cattleSprite:setVisible(self.mySpecies == "cattle")
		else
			self.sheepSprite:setVisible(false)
			self.pigSprite:setVisible(false)
			self.cattleSprite:setVisible(false)
		end
    end
   
    -- 5. Gérer l'étable - OVERLAY
    if self.hasStable then
        self.stable:setVisible(true)
    else
        self.stable:setVisible(false)
    end
end

-- *$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$
-- *$*$*$*$*$*$*$ Helpers pour la conversion de type

function GridBox:convertToField()
    if self.myType == "empty" then
        self.myType = "field"
        self.mySeed = nil
        self.mySeedAmount = 0
		self.badge:setVisible(true) -- convertToField: je crée un champ, j'affiche la pancarte
        self:updateVisual()
        return true
    end
    return false
end

function GridBox:canPlant()
	return self.myType == "field" and self.inGrowingPhase == false
end

function GridBox:plantSeed()	
    if self.myType ~= "field" then return false end
		self.mySeed, self.mySeedAmount =  self.myPlayer.board:cycleBoxSeed(self.col, self.row)
		self:updateVisual()
		print("PLANTATION ",self.mySeed, self.mySeedAmount)
    return true
end

function GridBox:old_buildStable()
    if self.myType == "house" or self.hasStable then return false end

	if self.myType == "pasture" then
		self.pastureLimit = self.pastureLimit * 2  -- sécurise le +2
	else
		self:convertToPasture(1)
		self.pastureLimit = 1
	end
	
	self.hasStable = true
	self.stable:setVisible(true)
    self:updateVisual()
	
    return true
end

function GridBox:buildStable()
    if self.myType == "house" or self.hasStable then return false end
    
    if self.myType == "pasture" then
        -- Étable sur pâture existante : doubler capacité
        self.pastureLimit = self.pastureLimit * 2
    else
        -- Étable isolée : créer un enclos minimal (1 box)
        self:convertToPasture(1)
        self.pastureLimit = 1
        
        -- ✅ AJOUT : Créer l'enclos pour gérer le badge
        self.myPlayer.board:createEnclosure({self}, gameManager.currentRound)
    end
    
    self.hasStable = true
    self:updateVisual()
    
    return true
end

function GridBox:convertToHouse(material)
    if self.myType ~= "empty" then  
        return false 
    end

    self.myType = "house"
    self.isLocked = true
    
    self:updateVisual()
    return true
end

function GridBox:renovateHouse(material)
    if self.myType ~= "house" then return false end
    self:updateVisual()  -- met à jour le visuel
    return true
end

function GridBox:convertToPasture(capacity)
    if self.myType == "empty" then
        self.myType = "pasture"
        self.mySpecies = nil
		self.animals = {sheep = 0, pig = 0, cattle = 0}  -- Animaux dans cette case
        self.pastureLimit = capacity or 1  -- capacité de base
        self:updateVisual()
        return true
    end
    return false
end

-- ========== HELPERS D'INFORMATION ================
-- =================================================
function GridBox:isEmpty()
    return self.myType == "empty"
end

function GridBox:isField()
    return self.myType == "field", self.mySeed
end

function GridBox:isHouse()
    return self.myType == "house"
end

function GridBox:isPasture()
    return self.myType == "pasture"
end

function GridBox:hasSpace(count)
    count = count or 1

    if self.myType ~= "pasture" then return false end

    local total = 0
    for _, n in pairs(self.animals) do total = total + n end

    return total + count <= self.pastureLimit
end

function GridBox:setGrowingStatus()
    if self.mySeedAmount > 0 then 
		self.inGrowingPhase = true 
	else
		self.inGrowingPhase = false 	
	end
end

function GridBox:getMyEnclosureInfo(property)
    if not self.enclosureId then return nil end
    
    local info = self.myPlayer.board:getEnclosureInfo(self.enclosureId)
    if not info then return nil end
    
    return info[property]
end

function GridBox:getCapacityInfo()
	if self.myType ~= "pasture" then return nil end
	
	local total = 0
    for _, n in pairs(self.animals) do total = total + n end

    return {
        current = total,
        max     = self.pastureLimit,
        available = self.pastureLimit - total
    }
end

function GridBox:getDominantSpecies()
    local max = 0
    local dominant = nil
    for sp, n in pairs(self.animals) do
        if n > max then
            max = n
            dominant = sp
        end
    end
    return dominant, max
end

-- ============================================
-- === GESTION DES CLÔTURES ET ENCLOS ===
-- ============================================

function GridBox:hasFence(direction)
    return self.fenceData[direction] == true
end

function GridBox:addFence(direction, turn)
    self.fenceData[direction] = true
    if not self.fenceTurnCreated then
        self.fenceTurnCreated = turn
    end
end

function GridBox:removeFence(direction)
    if self.fenceTurnCreated and self.fenceTurnCreated < gameManager.currentRound then
        return false
    end
    self.fenceData[direction] = false
    return true
end

function GridBox:hasAnyFence()
    return self.fenceData.top or self.fenceData.bottom or 
           self.fenceData.left or self.fenceData.right
end

function GridBox:isInEnclosure()
    return self.enclosureId ~= nil
end

function GridBox:canBeFenced()
    return self.myType == "empty" or self.myType == "pasture"
end

-- Affiche/masque une clôture
function GridBox:showFence(direction, temporary)
    if not self.fenceSprites[direction] then return end
    
    self.fenceSprites[direction]:setVisible(true)
    if temporary then
        self.fenceSprites[direction]:setAlpha(0.5)
    else
        self.fenceSprites[direction]:setAlpha(1)
    end
end

function GridBox:hideFence(direction)
    if not self.fenceSprites[direction] then return end
    self.fenceSprites[direction]:setVisible(false)
end

function GridBox:showAllFences(temporary)
    for direction, _ in pairs(self.fenceData) do
        if self.fenceData[direction] then
            self:showFence(direction, temporary)
        end
    end
end

function GridBox:hideAllFences()
    for direction, _ in pairs(self.fenceSprites) do
        self:hideFence(direction)
    end
end

function GridBox:updateFenceVisuals()
	--if not board.pendingFences or not board.pendingFences.boxes then return end
    for direction, hasFence in pairs(self.fenceData) do
        if hasFence then
            local isTemporary = self.myPlayer.board:isBoxInPendingFences(self)
            self:showFence(direction, isTemporary)
        else
            self:hideFence(direction)
        end
    end
end

-- **************  Helpers pour la gestion des champs durant le HARVEST 
-- ********************************
function GridBox:harvest()
    if self.myType ~= "field" or not self.mySeed then return 0 end

    local production = 1
    local seedType = self.mySeed
    self.mySeedAmount = self.mySeedAmount - 1
	if self.mySeedAmount == 0 then   
		self.mySeed = nil 
		self.inGrowingPhase = false
	end
		
    self:updateVisual()
    return seedType, production
end
