--[[
=================================================================================
========================  INITIALISATION  =======================================
=================================================================================
]]--

PlayerBoard = Core.class(Sprite)

function PlayerBoard:init(player)
    self.player = player
	self.isPlayable = false
    self.cols = 5
    self.rows = 3
    self.boxes = {}

    local startX, startY = 350, 150
    local spacingX, spacingY = 256, 256
	local gap = 16

	self.usedGrain = 0
	self.usedVegetables = 0
	
	local playerBoardBack = Bitmap.new(Texture.new("gfx/playerBoardBG.jpg"))
		self:addChild(playerBoardBack)
		self.playerBoardBack = playerBoardBack
		playerBoardBack:setPosition(gLeft, H/2)
		playerBoardBack:setAnchorPoint(0,0.5)

    for r = 1, self.rows do
        self.boxes[r] = {}
        for c = 1, self.cols do
            local box = GridBox.new(c, r, player)
            box:setPosition(startX + (c-1)*spacingX +  gap, startY + (r-1)*spacingY + gap)
			
			if (r == 2 and c == 1) or (r == 3 and c == 1) then
				box:convertToHouse("wood")
			end
			
			if (r == 3 and c == 1) then
				box.enclosureId = 0
			end
		
            self:addChild(box)
            self.boxes[r][c] = box
        end
    end
	
	-- === NOUVEAU : Relier les voisins ===
	for r = 1, self.rows do
		for c = 1, self.cols do
			local box = self.boxes[r][c]
			
			box.adjacentBox = {
				top = nil,
				bottom = nil,
				left = nil,
				right = nil
			}
			
			if r > 1 then
				box.adjacentBox.top = self.boxes[r-1][c]
			end
			
			if r < self.rows then
				box.adjacentBox.bottom = self.boxes[r+1][c]
			end
			
			if c > 1 then
				box.adjacentBox.left = self.boxes[r][c-1]
			end
			
			if c < self.cols then
				box.adjacentBox.right = self.boxes[r][c+1]
			end
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
 	
	self.nextEnclosureId = 1

	self.slot1 = Bitmap.new(Texture.new("gfx/positron.png"))
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
=========================  GESTION DES GRIDBOX  =================================
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
			self.player:payResources({grain = 1})
		print("→ Plante grain (coût: 1 grain)")
            return "grain", 3
            
        elseif vegetableAvailable > 0 then
            -- Pas de grain, essaye légume
			self.player:payResources({vegetable = 1})
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
			self.player:payResources({vegetable = 1})
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

--[[
=================================================================================
====================  CRÉATION DE CLÔTURES (TEMPORAIRE)  ========================
=================================================================================
]]--
function PlayerBoard:startFenceCreation()
    self.pendingFences = {
        boxes = {},
        woodCost = 0
    }
    print("🔨 Début création de clôtures")
end

function PlayerBoard:addBoxToFence(box)
    -- Vérifier si la case peut être clôturée
    if not box:canBeFenced() then
        print("⚠️ Cette case ne peut pas être clôturée")
        return false
    end
	
	if box.fenceTurnCreated and box.fenceTurnCreated < gameManager.currentRound then
        print("⚠️ Clôture d'un tour précédent, impossible de modifier")
        return false
    end
	
    local oldCost = self.pendingFences.woodCost  -- Coût AVANT ajout
    -- Ajouter aux cases en cours
    table.insert(self.pendingFences.boxes, box)
    
    -- Déterminer quelles clôtures ajouter
    local adjacentPending = self:getAdjacentPendingBoxes(box)
    
    -- Marquer toutes les clôtures par défaut
    box.fenceData.top = true
    box.fenceData.bottom = true
    box.fenceData.left = true
    box.fenceData.right = true
    box.fenceTurnCreated = gameManager.currentRound
    
    -- Retirer les clôtures partagées avec les adjacents
    for _, adj in ipairs(adjacentPending) do
        local oppDirection = self:getOppositeDirection(adj.direction)
        box.fenceData[adj.direction] = false
        adj.box.fenceData[oppDirection] = false
        
        -- Mettre à jour le visuel de la case adjacente
        adj.box:updateFenceVisuals()
    end
	
	 -- === NOUVEAU : Retirer aussi les nouvelles clôtures en commun avec les anciens adjacents ===
	for direction, adjBox in pairs(box.adjacentBox) do
		if adjBox then
			-- Si le voisin a déjà une clôture sur le côté commun
			local oppDirection = self:getOppositeDirection(direction)
			if adjBox:hasFence(oppDirection) then
				-- Ne pas créer de clôture sur ce côté
				box.fenceData[direction] = false
			end
		end
	end
    
    -- Afficher visuellement (temporaire = alpha 0.5)
    box:updateFenceVisuals()
    
	local newCost = self:calculateFenceCost()
    local diff = newCost - oldCost
	
	self.player:payResources({wood = diff},true)	
	
    print(string.format("✅ Case [%d,%d] ajoutée | Coût: %d bois", 
        box.col, box.row, self.pendingFences.woodCost))
    
    return true
end

function PlayerBoard:removeBoxFromFence(box)
    -- Trouver l'index de la case
    local index = nil
    for i, pendingBox in ipairs(self.pendingFences.boxes) do
        if pendingBox == box then
            index = i
            break
        end
    end
    
    if not index then return false end
    
	local oldCost = self.pendingFences.woodCost  -- Coût AVANT suppression
	
    -- Retirer de la liste
    table.remove(self.pendingFences.boxes, index)
    
    -- Retirer les données de clôture
    box.fenceData.top = false
    box.fenceData.bottom = false
    box.fenceData.left = false
    box.fenceData.right = false
    box.fenceTurnCreated = nil
    box:hideAllFences()
    
    -- Recalculer les clôtures des autres cases
    for _, otherBox in ipairs(self.pendingFences.boxes) do
        self:recalculateFencesForBox(otherBox)
    end
	
	local newCost = self:calculateFenceCost()
	local diff = oldCost - newCost
    if diff > 0 then
        self.player:addResource("wood", diff)
    end
		
    print(string.format("❌ Case [%d,%d] retirée | Coût: %d bois", 
        box.col, box.row, self.pendingFences.woodCost))
    
    return true
end

function PlayerBoard:calculateFenceCost()
    local totalCost = 0
    
    for _, box in ipairs(self.pendingFences.boxes) do
        -- Compter les clôtures actives
        for _, hasFence in pairs(box.fenceData) do
            if hasFence then
                totalCost = totalCost + 1
            end
        end
    end
    
    self.pendingFences.woodCost = totalCost
    return totalCost
end

function PlayerBoard:recalculateFencesForBox(box)
    -- Réinitialiser toutes les clôtures
    box.fenceData.top = true
    box.fenceData.bottom = true
    box.fenceData.left = true
    box.fenceData.right = true
    
    -- Retirer celles partagées
    local adjacentPending = self:getAdjacentPendingBoxes(box)
    for _, adj in ipairs(adjacentPending) do
        box.fenceData[adj.direction] = false
    end
	
	-- === NOUVEAU : Retirer aussi les clôtures déjà présentes sur les adjacents anciens ===
	for direction, adjBox in pairs(box.adjacentBox) do
		if adjBox then
			local oppDirection = self:getOppositeDirection(direction)
			if adjBox:hasFence(oppDirection) then
				box.fenceData[direction] = false
			end
		end
	end
    
    box:updateFenceVisuals()
end

function PlayerBoard:refreshAllFenceVisuals()
    for row = 1, #self.boxes do
        for col = 1, #self.boxes[row] do
            local box = self.boxes[row][col]

            if box and box.fenceData then
                for direction, hasFence in pairs(box.fenceData) do
                    if hasFence then
                        -- Fence validée, affichage opaque
                        box:showFence(direction, false)
                    else
                        -- Aucun fence, masque total
                        box:hideFence(direction)
                    end
                end
            end
        end
    end
end

function PlayerBoard:getPendingFenceCost()
    return self.pendingFences.woodCost
end

function PlayerBoard:hasPendingFences()
    return #self.pendingFences.boxes > 0
end

function PlayerBoard:isBoxInPendingFences(box)
	
    for _, pendingBox in ipairs(self.pendingFences.boxes) do
        if pendingBox == box then
            return true
        end
    end
    return false
end

function PlayerBoard:getAdjacentPendingBoxes(box)
    local adjacent = {}
    
    -- Vérifier chaque direction dans adjacentBox
    for direction, adjBox in pairs(box.adjacentBox) do
        if adjBox and self:isBoxInPendingFences(adjBox) then
            table.insert(adjacent, {
                box = adjBox,
                direction = direction
            })
        end
    end
    
    return adjacent
end

function PlayerBoard:getOppositeDirection(direction)
    local opposites = {
        top = "bottom",
        bottom = "top",
        left = "right",
        right = "left"
    }
    return opposites[direction]
end

function PlayerBoard:commitFences()
    if #self.pendingFences.boxes == 0 then
        print("⚠️ Aucune clôture à valider")
        return false
    end
    
    -- Séparer les cases en groupes connectés
    local groups = self:findConnectedGroups(self.pendingFences.boxes)
    
    -- Créer un enclos par groupe
    for i, group in ipairs(groups) do
        -- Valider les clôtures du groupe (alpha = 1)
        for _, box in ipairs(group) do
            for direction, hasFence in pairs(box.fenceData) do
                if hasFence then
                    box:showFence(direction, false)  -- false = pas temporaire
                end
            end
        end
        
        -- Créer l'enclos
        local enclosureId = self:createEnclosure(group, gameManager.currentRound)
    end
    
    -- Nettoyer l'état temporaire
    self.pendingFences = {
        boxes = {},
        woodCost = 0
    }
    
    return true
end

--[[
=================================================================================
======================  GESTION DES ENCLOS  =====================================
=================================================================================
]]--
function PlayerBoard:createEnclosure(boxList, turn)
    local enclosureId = self.nextEnclosureId
    self.nextEnclosureId = self.nextEnclosureId + 1
    
    -- Assigner l'ID à toutes les cases
    for _, box in ipairs(boxList) do
        box.enclosureId = enclosureId
        box:convertToPasture(0)  -- Le reste est géré par les fences
    end
	
    -- Calculer et attribuer la capacité
    self:updateEnclosureCapacity(enclosureId)  

	for i, box in ipairs(boxList) do
		if i == 1 then
			box.badge:setTexture(Texture.new("gfx/fences/badgeCount.png"))
			box.badge:setVisible(true) -- createEnclosure: je crée un enclos, j'affiche la pancerte dans la box 'id 1'
		end
	end
   
    return enclosureId
end

function PlayerBoard:getEnclosureInfo(enclosureId)
    if enclosureId == nil then return nil end
    
    local boxes = {}
    local totalAnimals = {sheep = 0, pig = 0, cattle = 0}
    local hasStable = false
	local multiplier = 1 -- multiplier pour factoriser selon le nbre d'etable
    
    for r = 1, self.rows do
        for c = 1, self.cols do
            local box = self.boxes[r][c]
            if box.enclosureId == enclosureId then
                table.insert(boxes, box)
                
                for species, count in pairs(box.animals) do
                    totalAnimals[species] = totalAnimals[species] + count
                end
                
                if box.hasStable then
                    hasStable = true
					multiplier = multiplier * 2
                end
            end
        end
    end

    if #boxes == 0 then return nil end
	

    local capacity
    if enclosureId == 0 then
        capacity = self.houseAnimalCapacity or 1   -- par défaut 1, cartes pourront modifier
    else
        local baseCapacity = (#boxes * 2)
		capacity = baseCapacity * multiplier
    end

    local dominant = nil
    local maxCount = 0
    for s, n in pairs(totalAnimals) do
        if n > maxCount then
            maxCount = n
            dominant = s
        end
    end

    return {
		id = enclosureId,                    -- L'ID de l'enclos (ex: 1, 2, 3, ou 0 pour maison)
		boxes = boxes,                       -- Liste des GridBox qui composent cet enclos |Permet d'itérer sur toutes les cases
		animals = totalAnimals,              -- Table des animaux TOTAUX de l'enclos | {sheep = 5, pig = 0, cattle = 2}
		dominantSpecies = dominant,          -- L'espèce la plus nombreuse dans l'enclos | "sheep", "pig", "cattle" ou nil
		totalCount = totalAnimals.sheep + totalAnimals.pig + totalAnimals.cattle,-- Nombre TOTAL d'animaux (toutes espèces)
		capacity = capacity                  -- Capacité MAXIMALE de l'enclos `| = nb_cases × 2 (× 2 si étable présente)
    }
end

function PlayerBoard:findConnectedGroups(boxes)
    local groups = {}
    local visited = {}
    
    for _, box in ipairs(boxes) do
        if not visited[box] then
            local group = {}
            self:collectConnectedBoxes(box, boxes, visited, group)
            table.insert(groups, group)
        end
    end
    
    return groups
end

function PlayerBoard:collectConnectedBoxes(box, allBoxes, visited, group)
    visited[box] = true
    table.insert(group, box)
    
	for direction, adjBox in pairs(box.adjacentBox) do
		if adjBox and not visited[adjBox] then
			-- Vérifier si adjBox est dans allBoxes (les cases clôturées)
			local isInPending = false
			for _, b in ipairs(allBoxes) do
				if b == adjBox then
					isInPending = true
					break
				end
			end
			
			if isInPending then
				self:collectConnectedBoxes(adjBox, allBoxes, visited, group)
			end
		end
	end
end

function PlayerBoard:updateEnclosureCapacity(enclosureId)
    local info = self:getEnclosureInfo(enclosureId)
    if not info then return end
    
    -- Met à jour toutes les cases de l'enclos
    for _, box in ipairs(info.boxes) do
        box.pastureLimit = info.capacity
		box:updateVisual()
    end
end

function PlayerBoard:getAllEnclosureIds()
    local ids = {}
    local seen = {}
    
    for r = 1, self.rows do
        for c = 1, self.cols do
            local box = self.boxes[r][c]
            if box.enclosureId and not seen[box.enclosureId] then
                table.insert(ids, box.enclosureId)
                seen[box.enclosureId] = true
            end
        end
    end    
    return ids
end

-- dispatching des animaux d'un enclos au sein des box qui le composent
function PlayerBoard:redistributeAnimalsInEnclosure(enclosureId)
    local info = self:getEnclosureInfo(enclosureId)
    if not info or info.totalCount == 0 then return end
    
--[[
	id = enclosureId,                    -- L'ID de l'enclos (ex: 1, 2, 3, ou 0 pour maison)
	boxes = boxes,                       -- Liste des GridBox qui composent cet enclos |Permet d'itérer sur toutes les cases
	animals = totalAnimals,              -- Table des animaux TOTAUX de l'enclos | {sheep = 5, pig = 0, cattle = 2}
	dominantSpecies = dominant,          -- L'espèce la plus nombreuse dans l'enclos | "sheep", "pig", "cattle" ou nil
	totalCount = totalAnimals.sheep + totalAnimals.pig + totalAnimals.cattle,-- Nombre TOTAL d'animaux (toutes espèces)
	capacity = capacity                  -- Capacité MAXIMALE de l'enclos `| = nb_cases × 2 (× 2 si étable présente)
]]--
	
    print("→ Redistribution enclos #" .. enclosureId)
    
    -- 1) Collecter tous les animaux de l'enclos
    local allAnimals = {}
    for species, count in pairs(info.animals) do
        for i = 1, count do
            table.insert(allAnimals, species)
        end
    end
    
    -- 2) Vider toutes les boxes de l'enclos
    for _, box in ipairs(info.boxes) do
        for species, count in pairs(box.animals) do
            box.animals[species] = 0
        end
    end
    
    -- 3) Répartir équitablement en cycle
    local boxIndex = 1
    for i, species in ipairs(allAnimals) do
        local box = info.boxes[boxIndex]
        box.animals[species] = (box.animals[species] or 0) + 1
        
        -- Passer à la box suivante (cycle)
        boxIndex = boxIndex + 1
        if boxIndex > #info.boxes then
            boxIndex = 1
        end
    end
    
    print("✅ " .. #allAnimals .. " animaux répartis sur " .. #info.boxes .. " boxes")
	for _, box in ipairs(info.boxes) do
        -- Déterminer l'espèce dominante de cette box
        local dominantSpecies = box:getDominantSpecies()
        box.mySpecies = dominantSpecies  -- "sheep", "pig", "cattle" ou "pasture" si vide
        box:updateVisual()
    end

end
--[[
========================================================================================
=======================  LES PATURAGES === LES ANIMAUX  ================================
========================================================================================
]]--
function PlayerBoard:_addToEnclosure(enclosureInfo, species, count)
	  print("_addToEnclosure appelé sur board de:", self.player.name)
    -- Placer les animaux dans la première case (dispatch après)
    local firstBox = enclosureInfo.boxes[1]
    firstBox.animals[species] = (firstBox.animals[species] or 0) + count
    firstBox.mySpecies = species
    
    -- Redistribuer sur toutes les cases
    self:redistributeAnimalsInEnclosure(enclosureInfo.id)
end

function PlayerBoard:_clearEnclosure(enclosureInfo)
    for _, box in ipairs(enclosureInfo.boxes) do
        box.animals = {sheep = 0, pig = 0, cattle = 0}
        box.mySpecies = nil
		--box.myType = "pasture"
        box:updateVisual()
    end
end

function PlayerBoard:addAnimalsToEnclosure(enclosureId, species, count)
    local info = self:getEnclosureInfo(enclosureId)
    if not info then return false end
    
    -- Vérifier capacité
    if info.totalCount + count > info.capacity then
        print(string.format("⚠️ Enclos #%d plein ou trop petit (%d/%d)", enclosureId, info.totalCount, info.capacity))
        return false
    end
    
    -- Vérifier espèce unique (si enclos non vide)
    if info.totalCount > 0 and info.dominantSpecies ~= species then
        print(string.format("⚠️ Enclos #%d contient déjà des %s", enclosureId, info.dominantSpecies))
        return false
    end
    
    -- Répartir les animaux sur les cases (pour l'instant, tout sur la première)
    local firstBox = info.boxes[1]
    firstBox.animals[species] = firstBox.animals[species] + count
    
    -- Mettre à jour le state visuel de toutes les cases
--    for _, box in ipairs(info.boxes) do
--        box:updateVisual()
--    end
	self.player:updateAllBoxVisual()
    
    print(string.format("✅ +%d %s dans enclos #%d (%d/%d)",count, species, enclosureId, info.totalCount + count, info.capacity))
    
    return true
end

function PlayerBoard:autoPlaceAnimals(species, quantity)
    print("\n=== autoPlaceAnimals ===")
    print("Species =", species, "| Quantity =", quantity)

    if quantity <= 0 then return 0 end

	-----------------------------------------------------
    -- PHASE INIT : Vérifier la maison (enclos #0)
    -----------------------------------------------------
    local house = self:getEnclosureInfo(0)
    if house and house.totalCount == 1 and house.dominantSpecies == species then
        print("→ Phase 0 : Récupération maison #0 avec 1 " .. species)
        quantity = quantity + 1  -- Ajouter l'animal de la maison
        self:_clearEnclosure(house)  -- Vider la maison
        print("   Nouvelle quantity = " .. quantity)
    end

    -----------------------------------------------------
    -- PHASE A : Enclos contenant déjà la même espèce
    -----------------------------------------------------
    local processedIds = {}
    
    while quantity > 0 do
        local sameSpeciesEnclosure = nil
        
        for id = 1, self.nextEnclosureId - 1 do
            if not processedIds[id] then
                local info = self:getEnclosureInfo(id)
                if info and info.totalCount > 0 and info.dominantSpecies == species then
                    sameSpeciesEnclosure = info
                    break
                end
            end
        end

        if not sameSpeciesEnclosure then
            break  -- Plus d'enclos de même espèce → Phase B
        end

        local freeSpace = sameSpeciesEnclosure.capacity - sameSpeciesEnclosure.totalCount
        
        if freeSpace > quantity then  -- > pour laisser place naissance
            self:_addToEnclosure(sameSpeciesEnclosure, species, quantity)
            print("→ Phase A : Remplissage enclos #" .. sameSpeciesEnclosure.id .. " +" .. quantity)
            return 0
        else
            -- Trop petit → vider et récupérer
            print("⚠️ Phase A : Enclos #" .. sameSpeciesEnclosure.id .. " trop petit, vidage...")
            quantity = quantity + sameSpeciesEnclosure.totalCount
            self:_clearEnclosure(sameSpeciesEnclosure)
           -- processedIds[sameSpeciesEnclosure.id] = true
        end
    end

	-----------------------------------------------------
	-- PHASE B : Enclos vide pouvant contenir TOUT + 1
	-----------------------------------------------------
	local maxFreeSizeEnclosure = nil
	local maxFreeSize = 0

	for id = 1, self.nextEnclosureId - 1 do
		local info = self:getEnclosureInfo(id)
		
		-- Éliminer si pas vide
		if info and info.totalCount == 0 then
			local cap = info.capacity
			
			-- Mémoriser le plus grand
			if cap > maxFreeSize then
				maxFreeSize = cap
				maxFreeSizeEnclosure = id
			end
			
			-- Assez grand pour TOUT + 1 (naissance) ?
			if cap > quantity then
				self:_addToEnclosure(info, species, quantity)
				print("→ Phase B : Tout dans enclos #" .. id .. " +" .. quantity)
				return 0
			end
		end
	end
	
	-----------------------------------------------------
	-- PHASE C : Répartition du plus grand au plus petit
	-----------------------------------------------------
	-- 1) Remplir maxFreeSizeEnclosure d'abord
	if maxFreeSizeEnclosure then
		local info = self:getEnclosureInfo(maxFreeSizeEnclosure)
		local toPlace = math.min(quantity, maxFreeSize)
		self:_addToEnclosure(info, species, toPlace)
		print("→ Phase C : Remplissage enclos #" .. maxFreeSizeEnclosure .. " +" .. toPlace)
		quantity = quantity - toPlace
	end

	-- 2) Tester le remaining
	while quantity > 0 do
		print("→ Phase C : il reste encore ",quantity)
		-- Si reste 1 → maison
--		if quantity == 1 then
--			local house = self:getEnclosureInfo(0)
--			if house and house.totalCount == 0 and house.capacity >= 1 then
--				self:_addToEnclosure(house, species, 1)
--				print("→ Phase C : Dernier animal dans maison")
--				return 0
--			else
--				break  -- Maison pleine ou inexistante
--			end
--		end
		
		-- Si remaining > 1 → chercher un enclos vide qui peut tout contenir
		local foundEnclosure = false
		for id = 0, self.nextEnclosureId - 1 do
			if id ~= maxFreeSizeEnclosure then  -- Éviter celui déjà rempli
				local info = self:getEnclosureInfo(id)
				if info and info.totalCount == 0 then 
					if info.capacity >= quantity then
						self:_addToEnclosure(info, species, quantity)
						print("→ Phase C : Remplissage enclos #" .. id .. " +" .. quantity)
						quantity = 0
						foundEnclosure = true
						break
					else
						self:_addToEnclosure(info, species, info.capacity)
						print("→ Phase C : Remplissage enclos #" .. id .. " +" .. info.capacity)
						quantity = quantity - info.capacity
					end
				end
			end
		end
		
		
		
		if not foundEnclosure then
			break  -- Plus d'options
		end
	end
	
    -- Mettre à jour le state visuel de toutes les cases
	print("⚠️ autoPlaceAnimals. Juste avant getUnassignedAnimals() ")
		local remaining =  self:getUnassignedAnimals()
	self.player:updateAllBoxVisual()
	print("⚠️ autoPlaceAnimals. Appel à getUnassignedAnimals() >>> ", remaining.sheep, remaining.pig, remaining.cattle)

	gameManager.ui.validAnimalPlaceBtn:updateButtonState(remaining)

	print("⚠️ Animaux non placés :", remaining.sheep, remaining.pig, remaining.cattle)
	return remaining
end

function PlayerBoard:getTotalAnimalCount(species)
    local count = 0
    
    for id = 0, self.nextEnclosureId - 1 do
        local info = self:getEnclosureInfo(id)
        if info and info.animals then
            count = count + (info.animals[species] or 0)
        end
    end
    
    return count
end


function PlayerBoard:removeAnimal(species, quantity)
    local toRemove = quantity

    -- Liste des enclos contenant cette espèce
    local enclosureList = {}

    for id = 0, self.maxEnclosureId or 10 do
        local info = self:getEnclosureInfo(id)
        if info and info.animals[species] > 0 then
            table.insert(enclosureList, info)
        end
    end

    -- Trier pour vider en priorité les enclos les plus fournis
    table.sort(enclosureList, function(a, b)
        return a.animals[species] > b.animals[species]
    end)

    -- --- Suppression ---
    for _, enclosure in ipairs(enclosureList) do
        if toRemove <= 0 then break end

        local countHere = enclosure.animals[species]
        if countHere > 0 then
            local removeHere = math.min(countHere, toRemove)
            toRemove = toRemove - removeHere

            -- Enlever dans les cases de l’enclos
            for _, box in ipairs(enclosure.boxes) do
                local n = box.animals[species]
                if n > 0 then
                    local r = math.min(n, removeHere)
                    box.animals[species] = box.animals[species] - r
                    removeHere = removeHere - r

                    -- Gestion du visuel / état
                    if box.animals[species] == 0 then
                        box.mySpecies = nil
                       -- box.myType = "pasture"
                    else
                        box.mySpecies = species
                    end
                    box:updateVisual()

                    if removeHere <= 0 then break end
                end
            end
        end
    end
	
    -- Renvoie la quantité NON retirée
    if toRemove > 0 then
        print("⚠️ removeAnimal: Impossible de retirer toute la quantité demandée. Restant: "..toRemove)
    end

    return toRemove
end

function PlayerBoard:getUnassignedAnimals()
    local assigned = { sheep=0, pig=0, cattle=0 }

    -- Parcours tous les enclos
    local ids = self:getAllEnclosureIds()
    for _, id in ipairs(ids) do
        local info = self:getEnclosureInfo(id)
        for species, count in pairs(info.animals) do
            assigned[species] = assigned[species] + count
        end
    end

    -- Total possédé par le joueur
    local total = self.player.resources

    -- Calcul final
	local remaining = {
        sheep  = total.sheep  - assigned.sheep,
        pig    = total.pig    - assigned.pig,
        cattle = total.cattle - assigned.cattle
    }
	
	print(">>> getUnassignedAnimals() reached final return")
	--if gameManager.ui.validAnimalPlaceBtn then
	--	gameManager.ui.validAnimalPlaceBtn:updateButtonState(remaining)
	--end
    return {
        sheep  = total.sheep  - assigned.sheep,
        pig    = total.pig    - assigned.pig,
        cattle = total.cattle - assigned.cattle
    }
end


--[[
=================================================================================
============================  UTILITAIRES  ======================================
=================================================================================
]]--
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

-- ================================================================================
-- ================================================================================
-- ============================       DEBUG        ================================
-- ================================================================================

function PlayerBoard:debugEnclosures()
    print("\n=== ENCLOS De "..self.player.name.." ===")
    local ids = self:getAllEnclosureIds()
    
    if #ids == 0 then
        print("Aucun enclos")
    end
    
    for _, id in ipairs(ids) do
        local info = self:getEnclosureInfo(id)
        
        local stableCount = 0
        local animalStr = "vide"
        if info.totalCount > 0 then
            local parts = {}
            for species, count in pairs(info.animals) do
                if count > 0 then
                    table.insert(parts, string.format("%d %s", count, species))
                end
            end
            animalStr = table.concat(parts, ", ")
        end
        
        -- Debug des boxes individuelles
        local boxDetails = {}
        for i, box in ipairs(info.boxes) do
            local boxAnimals = {}
            for species, count in pairs(box.animals or {}) do
                if count > 0 then
                    table.insert(boxAnimals, string.format("%s:%d", species, count))
                end
            end
            local boxAnimalStr = #boxAnimals > 0 and table.concat(boxAnimals, ",") or "vide"
            local stableMark = box.hasStable and " [STABLE]" or ""
            table.insert(boxDetails, string.format("Box%d:%s%s", i, boxAnimalStr, stableMark))
            
            if box.hasStable then
                stableCount = stableCount + 1
            end
        end
        
        local boxesDetailStr = table.concat(boxDetails, " | ")
        
        print(string.format("• Enclos #%d : %d cases | capacité= %d | animaux= %s | stables: %d",
            id, #info.boxes, info.capacity, animalStr, stableCount))
        print(string.format("  ↳ Répartition: %s", boxesDetailStr))
    end
    print("===============\n")
end