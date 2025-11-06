
PlayerBoard = Core.class(Sprite)

function PlayerBoard:init(player)
    self.player = player
	self.isPlayable = false
    self.cols = 5
    self.rows = 3
    self.boxes = {}

    local startX, startY = 350, 250
    local spacingX, spacingY = 270, 200

	self.usedGrain = 0
	self.usedVegetables = 0
	
	local playerBoardBack = Bitmap.new(Texture.new("gfx/playerBoardBG.jpg"))
		self:addChild(playerBoardBack)
		self.playerBoardBack = playerBoardBack
		--playerBoardBack:setAlpha(.4)
		playerBoardBack:setPosition(gLeft, H/2)
		playerBoardBack:setAnchorPoint(0,0.5)

    for r = 1, self.rows do
        self.boxes[r] = {}
        for c = 1, self.cols do
            local box = GridBox.new(c, r, player)
            box:setPosition(startX + (c-1)*spacingX, startY + (r-1)*spacingY)
			
			if (r == 2 and c == 1) or (r == 3 and c == 1) then
				box:convertToHouse("wood")
			end
		
            self:addChild(box)
            self.boxes[r][c] = box
        end
    end
	
	local spacingX, spacingY = 132, 140
	-- Les limites de scroll
	self.scrollLimit = (self.playerBoardBack:getWidth()/ 2)
		self.leftLimit = -self.scrollLimit
		self.rightLimit = self.scrollLimit
	self.minX = self.leftLimit 
	self.maxX = 0 -- on ne positionne rien à gauche de la ferme du joueur
	
    self:addEventListener(Event.MOUSE_DOWN, self.onTouchesBegin, self)
    self:addEventListener(Event.MOUSE_MOVE, self.onTouchesMove, self)
	self:addEventListener(Event.MOUSE_UP, self.onTouchesEnd, self)
	
	--self.slot1 = Bitmap.new(Texture.new("gfx/positron.png"))
	self.slot1 = Sprite.new()
	self:addChild(self.slot1)
	self.slot1:setAnchorPoint(0, 1)
	self.slot1:setPosition(self.rightLimit + spacingX * 1, startY+spacingY * 5)
	
	self.slot2  = Sprite.new()
	self:addChild(self.slot2)
	self.slot2:setAnchorPoint(0, 1)
	self.slot2:setPosition(self.rightLimit + spacingX * 1, startY+spacingY * 1)

	self.slot3  = Sprite.new()
	self:addChild(self.slot3)
	self.slot3:setAnchorPoint(0, 1)
	self.slot3:setPosition(self.rightLimit + (spacingX * 5), startY+spacingY * 5)
	
	self.slot4  = Sprite.new()
	self:addChild(self.slot4)
	self.slot4:setAnchorPoint(0, 1)
	self.slot4:setPosition(self.rightLimit + (spacingX * 5), startY+spacingY * 1)	
	
	self.slot5  = Sprite.new()
    self:addChild(self.slot5)
    self.slot5:setAnchorPoint(0, 1)
    self.slot5:setPosition(self.rightLimit + (spacingX * 9), startY + spacingY * 5)

    self.slot6  = Sprite.new()
    self:addChild(self.slot6)
    self.slot6:setAnchorPoint(0, 1)
    self.slot6:setPosition(self.rightLimit + (spacingX * 9), startY + spacingY * 1)
	
	self.slot7  = Sprite.new()
    self:addChild(self.slot7)
    self.slot7:setAnchorPoint(0, 1)
    self.slot7:setPosition(self.rightLimit + (spacingX * 13), startY + spacingY * 5)

    self.slot8  = Sprite.new()
    self:addChild(self.slot8)
    self.slot8:setAnchorPoint(0, 1)
    self.slot8:setPosition(self.rightLimit + (spacingX * 13), startY + spacingY * 1)

	self.slotList = {2,1,3,4,5,6,7,8} -- emplacement des widget MI
end

function PlayerBoard:onTouchesBegin(event)
	if self:hitTestPoint(event.x, event.y) and self:isVisible() then	
		event:stopPropagation()
        self.isDragging = true
		
        self.x0 = event.x
    end
end

function PlayerBoard:onTouchesMove(event)
	if not self.isDragging then return end

	self.isDragging = true
		-- Figure out how far we moved since last time
		local dx = event.x - self.x0
		-- Move the camera
		self:setX(self:getX() + dx)		
		-- print("delta :", dx)
		
		if self:getX()<= self.minX and dx<0  then
			self:setX(self.minX)	
		elseif self:getX()>=self.maxX and dx>0 then
			self:setX(self.maxX)
		end
		self.x0 = event.x 	
		event:stopPropagation()
end

function PlayerBoard:onTouchesEnd(event)
	if not self.isDragging then return end
	
    self.isDragging = false 
    event:stopPropagation()
end

function PlayerBoard:isItPlayable()	
	return self.isPlayable  and self:isVisible() 
end

--[[
=================================================================================
=============================  GESTION DES BOXES  ===============================
=================================================================================
]]--
function PlayerBoard:cycleBoxSeed(col, row)
    local box = self.boxes[row][col]
    local currentSeed = box.mySeed  -- nil, "grain", "vegetable"
    
    -- On récupère les ressources disponibles du joueur
    local grainAvailable = self.player.resources.grain
    local vegetableAvailable = self.player.resources.vegetable
    
    print(" ")
    print("cycleBoxSeed - État actuel:", currentSeed)
    print("Ressources joueur - Grain:", grainAvailable, "Légumes:", vegetableAvailable)
    
    -- Logique de cycle : nil → grain → vegetable → nil
    if currentSeed == nil then
        -- Vide → essaye grain en premier
        if grainAvailable > 0 then
            -- Plante du grain
            self.player.resources.grain = self.player.resources.grain - 1
            self.player:updateInventory()
		print("→ Plante grain (coût: 1 grain)")
            return "grain", 3
            
        elseif vegetableAvailable > 0 then
            -- Pas de grain, essaye légume
            self.player.resources.vegetable = self.player.resources.vegetable - 1
            self.player:updateInventory()
		print("→ Plante légume (coût: 1 légume)")
            return "vegetable", 2
            
        else
            -- Rien disponible, reste vide
		print("→ Reste vide (pas de ressources)")
            return nil, 0
        end
        
    elseif currentSeed == "grain" then
        -- Grain → essaye de passer à légume
        if vegetableAvailable > 0 then
            -- Remplace grain par légume : rembourse le grain, débite le légume
            self.player.resources.grain = self.player.resources.grain + 1
            self.player.resources.vegetable = self.player.resources.vegetable - 1
            self.player:updateInventory()
		print("→ Remplace grain par légume (rembourse 1 grain, coût 1 légume)")
            return "vegetable", 2
            
        else
            -- Pas de légume, retour à vide : rembourse le grain
            self.player.resources.grain = self.player.resources.grain + 1
            self.player:updateInventory()
		print("→ Retire grain (rembourse 1 grain)")
            return nil, 0
        end
        
    elseif currentSeed == "vegetable" then
        -- Légume → retour à vide : rembourse le légume
        self.player.resources.vegetable = self.player.resources.vegetable + 1
        self.player:updateInventory()
        print("→ Retire légume (rembourse 1 légume)")
        return nil, 0
    end
    
    -- Fallback (ne devrait jamais arriver)
    return nil, 0
end
--[[
function PlayerBoard:getBox(col, row)
    if self.boxes[row] and self.boxes[row][col] then
        return self.boxes[row][col]
    end
    return nil
end

]]--

-- applique plusieurs modifications en une fois
function PlayerBoard:getTypeQty()
	local fieldCount, pastureCount, houseCount = 0,0,0
    for r = 1, self.rows do
        for c = 1, self.cols do
			local box = self.boxes[r][c]
			if box:isField() then  fieldCount = fieldCount +1 end
			if box:isPasture() then pastureCount = pastureCount +1 end
			if box:isHouse() then houseCount = houseCount +1 end
		end
    end
	return fieldCount, pastureCount, houseCount
end


-- ================================= UTILS
function PlayerBoard:centerOnX(targetX)

	if not targetX then return end

	local windowWidth = gRight - gLeft
	local windowCenter = gLeft + windowWidth / 2

	-- Calcule la position cible du board pour centrer targetX à l’écran
	local targetBoardX = windowCenter - targetX
	
	-- Bornage (empêche de sortir des limites)
	if targetBoardX < self.minX then
		targetBoardX = self.minX
	elseif targetBoardX > self.maxX then
		targetBoardX = self.maxX
	end

	-- Animation fluide vers la position cible
	local currentX = self:getX()
	local dx = targetBoardX - currentX
	local distance = math.abs(dx)

	local minFrames, maxFrames = 60, 240
	local factor = 0.1
	local frames = math.min(maxFrames, math.max(minFrames, distance * factor))

	local mc = MovieClip.new{
		{1, frames, self, {x = {currentX, targetBoardX, "inOutQuadratic"}}}
	}
	mc:play()
end


