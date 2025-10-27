-- classe qui manage les cases des fermes des joueurs
-- Exemples:
-- Labourer
-- box:setState("laboure")
--
-- Planter blé avec 3 grains
-- box:setState("ble", {qty = 3})

-- isGrowing  (boleen) indique si un champ a une culture en cours
local numberFont = TTFont.new("fonts/K2D-Bold.ttf",28)

GridBox = Core.class(Sprite)

function GridBox:init(col, row, player)
	local backImg = Bitmap.new(Texture.new("gfx/playerboard/bgherbe_box.png"))
	self:addChild(backImg)
	
    self.col = col
    self.row = row
	self.myPlayer = player
	
	self.state = "friche" -- gestion du visuel
	
	self.myType = "empty" -- "field", "pasture", "house"
		self.mySeed = nil -- "ble", "vegetable" ou nil (default)
		self.isGrowing = false  -- indique qu'un champ est ou n'est pas deja planté 
		self.mySeedAmount = 0 -- nb de graines restantes 
		self.mySpecies = nil -- "sheep", "boar", "cattle" 
		self.animals = 0 -- nb d’animaux dans la case 
		self.pastureLimit = 0 -- capacité max 
		self.hasStable = false -- if true >>> pastureLimit +2

    -- visuels possibles
    self.imgs = {
        friche   = Bitmap.new(Texture.new("gfx/playerboard/friche_box.png")),
        laboure  = Bitmap.new(Texture.new("gfx/playerboard/labourage_box.png")),
        ble      = Bitmap.new(Texture.new("gfx/playerboard/ble_box.png")),
        legume   = Bitmap.new(Texture.new("gfx/playerboard/legume_box.png")),
        etable 	 = Bitmap.new(Texture.new("gfx/playerboard/etable_box.png")),
        m_wood   = Bitmap.new(Texture.new("gfx/playerboard/woodhouse_box.png")),
        m_clay    = Bitmap.new(Texture.new("gfx/playerboard/woodhouse_box.png")),
        m_stone   = Bitmap.new(Texture.new("gfx/playerboard/woodhouse_box.png"))
    }

    -- ajouter tous les visuels mais invisibles
    for _, img in pairs(self.imgs) do
        img:setVisible(false)
        self:addChild(img)
    end

    -- badge (comme pour les Sign)
    local badge = Bitmap.new(Texture.new("gfx/signs/ic_badge.png"))
		badge:setAnchorPoint(0.5,0.5)
		badge:setPosition(20, 170) -- ajuste selon ton sprite
		self:addChild(badge)
		self.badge = badge

    local badgeCount = TextField.new(numberFont, "")
		badgeCount:setAnchorPoint(0.5,1)
		badgeCount:setTextColor(0xffffff)
		badgeCount:setPosition(24, -12) -- centre du badge
		badge:addChild(badgeCount)
		self.badgeCount = badgeCount

    self.badge:setVisible(false)
 
	self:addEventListener(Event.MOUSE_DOWN, self.onClick, self)
	
    -- état initial
    self:setState("friche")
	
end


function GridBox:onClick(event)
	if self:hitTestPoint(event.x, event.y) and self:getParent():isItPlayable() then
		--print("GridBox:onClick: ",event.x, (self:getX()-(self:getWidth()/2)))
		event:stopPropagation()
		gameManager:handleBoxClick(self)
	end 
end


function GridBox:updateState()
    local newState = self:calculateState()
    self:setState(newState)
end

function GridBox:calculateState()
    if self.myType == "empty" then
        return "friche"
    
    elseif self.myType == "field" then
        if not self.mySeed then
			self.isGrowing = false
            return "laboure"  -- champ labouré vide
        elseif self.mySeed == "grain" then
            return "ble"      -- peu importe la quantité
        elseif self.mySeed == "vegetable" then
            return "legume"   -- peu importe la quantité
        end
    
    elseif self.myType == "pasture" then
        -- Pour l'instant, juste étable ou friche
        return self.hasStable and "etable" or "friche"
    else
        return self.state or "friche"  -- fallback
    end
end

function GridBox:setState(s, data)

    -- cacher toutes les images
    for _, img in pairs(self.imgs) do
        img:setVisible(false)
    end

    -- montrer la bonne
    local img = self.imgs[s]
    if img then img:setVisible(true) end

    -- badge pour blé/légume
    if s == "ble" or s == "legume" then
        local q = data and data.qty or 0
        self.badgeCount:setText(self.mySeedAmount)
        self.badge:setVisible(true)
    else
        self.badge:setVisible(false)
    end

    self.state = s

end


-- Helpers pour la gestion des champs

--function GridBox:plantSeed(seedType, amount)
function GridBox:plantSeed()	
    if self.myType ~= "field" then return false end
		self.mySeed, self.mySeedAmount =  self.myPlayer.board:cycleBoxSeed( self.col, self.row, snapshot)
		self:updateState()
    return true
end

function GridBox:harvest()
    if self.myType ~= "field" or not self.isGrowing then return 0 end
    
    local production = 1
    local seedType = self.mySeed
    self.mySeedAmount = self.mySeedAmount - 1
	if self.mySeedAmount == 0 then 
		self.isGrowing = false  
		self.mySeed = nil 
	end
		
    self:updateState()
	print("gridBox harvest: "..self.row.."|"..self.col.." >>> ", seedType, production)
    return seedType, production
end

function GridBox:canPlant()
    return self.myType == "field" and not self.isGrowing 
end

-- Helpers pour la gestion des pâtures
function GridBox:addAnimals(species, count)
    if self.myType ~= "pasture" then return false end
    
    -- Vérifier si on peut mélanger les espèces (règles Agricola)
    if self.animals > 0 and self.mySpecies ~= species then
        return false  -- pas de mélange d'espèces
    end
    
    -- Vérifier la capacité
    if self.animals + count > self.pastureLimit then
        return false  -- pas assez de place
    end
    
    self.mySpecies = species
    self.animals = self.animals + count
    self:updateState()
    return true
end

function GridBox:removeAnimals(count)
    if self.myType ~= "pasture" or count > self.animals then return 0 end
    
    local removed = math.min(count, self.animals)
    self.animals = self.animals - removed
    
    -- Si plus d'animaux, reset l'espèce
    if self.animals == 0 then
        self.mySpecies = nil
    end
    
    self:updateState()
    return removed
end

function GridBox:buildStable()
    if self.myType ~= "pasture" or self.hasStable then return false end
    
    self.hasStable = true
    self.pastureLimit = self.pastureLimit + 2  -- +2 capacité avec étable
    self:updateState()
    return true
end

function GridBox:canAddAnimals(species, count)
    if self.myType ~= "pasture" then return false end
    
    -- Vérifier mélange d'espèces
    if self.animals > 0 and self.mySpecies ~= species then
        return false
    end
    
    -- Vérifier capacité
    return self.animals + count <= self.pastureLimit
end

-- Helpers pour la conversion de type
function GridBox:convertToField()
    if self.myType == "empty" then
        self.myType = "field"
        self.mySeed = nil
        self.mySeedAmount = 0
        self:updateState()
        return true
    end
    return false
end

function GridBox:convertToPasture(capacity)
    if self.myType == "empty" then
        self.myType = "pasture"
        self.mySpecies = nil
        self.animals = 0
        self.pastureLimit = capacity or 2  -- capacité de base
    self.hasStable = false
        self:updateState()
        return true
    end
    return false
end

-- Helpers d'information
function GridBox:isEmpty()
    return self.myType == "empty"
end

function GridBox:isField()
    return self.myType == "field", self.mySeed
end

function GridBox:isPasture()
    return self.myType == "pasture"
end

function GridBox:hasSpace(count)
    if self.myType == "pasture" then
        return self.animals + (count or 1) <= self.pastureLimit
    end
    return false
end

function GridBox:getCapacityInfo()
    if self.myType == "pasture" then
        return {
            current = self.animals,
            max = self.pastureLimit,
            available = self.pastureLimit - self.animals,
            species = self.mySpecies
        }
    end
    return nil
end
