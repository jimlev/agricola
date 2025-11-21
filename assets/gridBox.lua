-- classe qui manage les cases des fermes des joueurs

local numberFont = TTFont.new("fonts/K2D-Bold.ttf",28)

GridBox = Core.class(Sprite)

function GridBox:init(col, row, player)
	local backImg = Bitmap.new(Texture.new("gfx/playerboard/bgherbe_box2.png"))
	self:addChild(backImg)
	self.backImg = backImg
	
    self.col = col
    self.row = row
	self.myPlayer = player
	
	self.state = "friche" -- gestion du visuel
	
	self.myType = "empty" -- "field", "pasture", "house"
		self.mySeed = nil -- "ble", "vegetable" ou nil (default) 
		self.mySeedAmount = 0 -- nb de graines restantes 
		self.mySpecies = nil -- "sheep", "pig", "cattle" 
		self.animals = {sheep = 0, pig = 0, cattle = 0}  -- Animaux dans cette case
		self.pastureLimit = 0 -- capacité max 
		self.hasStable = false -- if true >>> pastureLimit +2
		self:setGrowingStatus()  -- une graine est-elle en cours de pousse ?
		
    -- visuels possibles
    self.imgs = {
        friche   = Bitmap.new(Texture.new("gfx/playerboard/friche_box.png")),
        laboure  = Bitmap.new(Texture.new("gfx/playerboard/labourage_box.png")),
        ble      = Bitmap.new(Texture.new("gfx/playerboard/ble_box.png")),
        legume   = Bitmap.new(Texture.new("gfx/playerboard/legume_box.png")),
		pasture  = Bitmap.new(Texture.new("gfx/playerboard/paturage_box.png")),
        m_wood   = Bitmap.new(Texture.new("gfx/positron.png")),
        m_clay    = Bitmap.new(Texture.new("gfx/playerboard/clayhouse_box.png")),
        m_stone   = Bitmap.new(Texture.new("gfx/playerboard/stonehouse_box.png"))
    }

    -- ajouter tous les visuels mais invisibles
    for _, img in pairs(self.imgs) do
        img:setVisible(false)
        self:addChild(img)
    end

    local stable = Bitmap.new(Texture.new("gfx/playerboard/stable.png"))
		stable:setAnchorPoint(0,0)
		stable:setPosition(32, 24) -- ajuste selon ton sprite
		self:addChild(stable)
		self.stable = stable
		self.stable:setVisible(false)
		
		
	self.sheepSprite = Bitmap.new(Texture.new("gfx/fences/sheepMeeple.png"))
		self.sheepSprite:setAnchorPoint(0.5,0.5)
		self.sheepSprite:setPosition(132,100)
		self:addChild(self.sheepSprite)
		self.sheepSprite:setVisible(false)

	self.pigSprite = Bitmap.new(Texture.new("gfx/fences/pigMeeple.png"))
		self.pigSprite:setAnchorPoint(0.5,0.5)
		self.pigSprite:setPosition(132,100)		
		self:addChild(self.pigSprite)
		self.pigSprite:setVisible(false)
		
	self.cattleSprite = Bitmap.new(Texture.new("gfx/fences/cattleMeeple.png"))
		self.cattleSprite:setAnchorPoint(0.5,0.5)
		self.cattleSprite:setPosition(132,100)	
		self:addChild(self.cattleSprite)
		self.cattleSprite:setVisible(false)	
		
    -- badge (comme pour les Sign)
    local badge = Bitmap.new(Texture.new("gfx/playerboard/harvestCount_box.png"))
		badge:setAnchorPoint(0.5,0.5)
		badge:setPosition(232, 166) -- ajuste selon ton sprite
		self:addChild(badge)
		self.badge = badge

    local badgeCount = TextField.new(numberFont, "0")
		badgeCount:setAnchorPoint(0.5,1)
		badgeCount:setTextColor(0xffffff)
		badgeCount:setPosition(0, 24) -- centre du badge
		badge:addChild(badgeCount)
		self.badgeCount = badgeCount

    self.badge:setVisible(false)
 
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
	fenceTop:setRotation(math.random(5)-3)
    fenceTop:setVisible(false)
    self.fenceSprites.top = fenceTop
    
    -- Clôture horizontale du bas
    local fenceBottom = Bitmap.new(Texture.new("gfx/fences/horizontalFence.png"))
    fenceBottom:setAnchorPoint(0.5, 0.5)
    fenceBottom:setPosition(self.backImg:getWidth()/2, self.backImg:getHeight()-16)
    self:addChild(fenceBottom)
	fenceBottom:setRotation(math.random(5)-2)
    fenceBottom:setVisible(false)
    self.fenceSprites.bottom = fenceBottom
    
    -- Clôture verticale gauche
    local fenceLeft = Bitmap.new(Texture.new("gfx/fences/verticalFence.png"))
	fenceLeft:setAnchorPoint(0.5, 0.5)
    fenceLeft:setPosition(12, self.backImg:getHeight()/2)
    self:addChild(fenceLeft)
	fenceLeft:setRotation(math.random(5)-3)
    fenceLeft:setVisible(false)
    self.fenceSprites.left = fenceLeft
    
    -- Clôture verticale droite
    local fenceRight = Bitmap.new(Texture.new("gfx/fences/verticalFence.png"))
	fenceRight:setAnchorPoint(0.5, 0.5)
    fenceRight:setPosition(self.backImg:getWidth()-12, self.backImg:getHeight()/2)
    self:addChild(fenceRight)
	fenceRight:setRotation(math.random(5)-2)
    fenceRight:setVisible(false)
    self.fenceSprites.right = fenceRight
-- ===	

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


-- fonction qui retourne le state d'une case en fonction de son type
function GridBox:getLogicalState()
    if self.myType == "empty" then
        return "friche"
    elseif self.myType == "field" then
        if not self.mySeed then
			self.state = "laboure"
            return "laboure"
        elseif self.mySeed == "grain" then
			self.state = "ble"
            return "ble"
        elseif self.mySeed == "vegetable" then
			self.state = "legume"
            return "legume"
        end
    elseif self.myType == "house" then
		--self.state = "m_"..self.myPlayer.house.rscType
        return self.state
    elseif self.myType == "pasture" then
		self.state = self:getDominantSpecies()
		return self.state
	else
        return self.state or "friche"
    end

end

function GridBox:updateVisual()	
    local s = self:getLogicalState()

    for _, img in pairs(self.imgs) do
        img:setVisible(false)
    end
    
    local img = self.imgs[s]
    if img then img:setVisible(true) end

    if s == "ble" or s == "legume" then
        self.badgeCount:setText(self.mySeedAmount)
        self.badge:setVisible(true)
    elseif s == "sheep" or s == "pig" or s == "cattle"  then
        self.badgeCount:setText(#self.animals.."/"..self.pastureLimit)
		self.badge:setPosition(214, 140)
        self.badge:setVisible(true)
			
		local spriteName = s.."Sprite"	
		self[spriteName]:setVisible(true)
    else
        self.badge:setVisible(false)
    end
end


-- Helpers pour la gestion des champs
function GridBox:harvest()
    if self.myType ~= "field" or not self.mySeed then return 0 end

    local production = 1
    local seedType = self.mySeed
    self.mySeedAmount = self.mySeedAmount - 1
	if self.mySeedAmount == 0 then   
		self.mySeed = nil 
	end
		
    self:updateVisual()
    return seedType, production
end


-- *$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$*$
-- *$*$*$*$*$*$*$ Helpers pour la conversion de type

function GridBox:convertToField()
    if self.myType == "empty" then
        self.myType = "field"
        self.mySeed = nil
        self.mySeedAmount = 0
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
    return true
end


function GridBox:buildStable()
    if self.myType == "house" or self.hasStable then return false end
    print("JE CONSTRUIS UNE ETABLE")
	
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

function GridBox:convertToHouse(material)
    -- vérification minimale
    if self.myType ~= "empty" and self.state ~= "friche" then 
        return false 
    end

    self.myType = "house"
	self.isLocked = true
	
    self.state = "m_" .. material  -- ex: m_wood, m_clay, m_stone

    self:updateVisual()  -- met à jour le visuel
    return true
end

function GridBox:renovateHouse(material)
    if self.myType ~= "house" then return false end
	
	print(self.col,self.row," converti en",material)

    self.state = "m_" .. material  -- ex: m_wood, m_clay, m_stone
	
    self:updateVisual()  -- met à jour le visuel
    return true
end


function GridBox:convertToPasture(capacity)
print("convertToPasture: ",self.row, self.col,self.myType)
    if self.myType == "empty" then
        self.myType = "pasture"
        self.mySpecies = nil
		self.animals = {sheep = 0, pig = 0, cattle = 0}  -- Animaux dans cette case
        self.pastureLimit = capacity or 1  -- capacité de base
		--self.hasStable = false
			print("convertToPasture | self.myType == empty > myType: ",self.myType)	
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
    if self.mySeed then 
		self.inGrowingPhase = true 
	else
		self.inGrowingPhase = false 	
	end
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
            local isTemporary = self.myPlayer.board:isBoxInPendingFences(self,"updateFenceVisuals ")
            self:showFence(direction, isTemporary)
        else
            self:hideFence(direction)
        end
    end
end