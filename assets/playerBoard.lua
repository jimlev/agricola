
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
	
	-- === NOUVEAU : Gestion des enclos ===
    self.enclosures = {}  -- { [id] = {boxes={}, capacity=0, animals={}, turnCreated=X} }
    self.nextEnclosureId = 1
	self.pendingFences = {
		boxes = {},
		woodCost = 0
    }
	
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

--[[
=================================================================================
=========================  GESTION DES ENCLOS  ==================================
=================================================================================
]]--

function PlayerBoard:createEnclosure(boxList, turn)
    local enclosureId = self.nextEnclosureId
    self.nextEnclosureId = self.nextEnclosureId + 1
    
    local enclosure = {
        id = enclosureId,
        boxes = boxList,
        capacity = 0,
        animals = {},  -- { sheep=0, pig=0, cattle=0 }
        turnCreated = turn or gameManager.currentRound
    }
    
    -- Assigner l'ID à toutes les cases
    for _, box in ipairs(boxList) do
        box.enclosureId = enclosureId
        box:convertToPasture(0)  -- Convertir en pâturage avec capacité 0 (sera recalculée)
		print(string.format("Box [%d,%d] → pasture, enclosureId=%d", box.col, box.row, enclosureId))
	end
    
    self.enclosures[enclosureId] = enclosure
    self:updateEnclosureCapacity(enclosureId)
    
    return enclosureId
end

function PlayerBoard:updateEnclosureCapacity(enclosureId)
    local enclosure = self.enclosures[enclosureId]
    if not enclosure then return end
    
    local baseCapacity = #enclosure.boxes * 2  -- 2 animaux par case
    local stableBonus = 0
    
    -- Compter les étables dans l'enclos
    for _, box in ipairs(enclosure.boxes) do
        if box.hasStable then
            stableBonus = baseCapacity  -- Double la capacité
            break  -- Une seule étable suffit
        end
    end
    
    enclosure.capacity = baseCapacity + stableBonus
    
    -- Mettre à jour la capacité de chaque case
    for _, box in ipairs(enclosure.boxes) do
        box.pastureLimit = enclosure.capacity
    end
end

function PlayerBoard:getEnclosure(enclosureId)
    return self.enclosures[enclosureId]
end

function PlayerBoard:getEnclosureByBox(box)
    if not box.enclosureId then return nil end
    return self.enclosures[box.enclosureId]
end

function PlayerBoard:mergeEnclosures(enclosureId1, enclosureId2)
    local enc1 = self.enclosures[enclosureId1]
    local enc2 = self.enclosures[enclosureId2]
    
    if not enc1 or not enc2 then return false end
    
    -- Fusionner les cases
    for _, box in ipairs(enc2.boxes) do
        box.enclosureId = enclosureId1
        table.insert(enc1.boxes, box)
    end
    
    -- Fusionner les animaux
    for species, count in pairs(enc2.animals) do
        enc1.animals[species] = (enc1.animals[species] or 0) + count
    end
    
    -- Supprimer l'ancien enclos
    self.enclosures[enclosureId2] = nil
    
    -- Recalculer la capacité
    self:updateEnclosureCapacity(enclosureId1)
    
    return true
end

function PlayerBoard:getAdjacentBoxes(box)
    local adjacent = {}
    local col, row = box.col, box.row
    
    -- Nord
    if row > 1 and self.boxes[row-1] and self.boxes[row-1][col] then
		table.insert(adjacent, {box = self.boxes[row-1][col], direction = "top"})
    end
    
    -- Sud
    if row < self.rows and self.boxes[row+1] and self.boxes[row+1][col] then
        table.insert(adjacent, {box = self.boxes[row+1][col], direction = "bottom"})
    end
    
    -- Ouest
    if col > 1 and self.boxes[row][col-1] then
        table.insert(adjacent, {box = self.boxes[row][col-1], direction = "left"})
    end
    
    -- Est
    if col < self.cols and self.boxes[row][col+1] then
        table.insert(adjacent, {box = self.boxes[row][col+1], direction = "right"})
    end
    
    return adjacent
end

-- ====== GESTION DES ENCLOS / SPECIES  =======
-- ============================================

-- Cherche le meilleur enclos pour accueillir "quantity" animaux de type "species".
-- Retourne :
--   {
--       type = "enclosure" | "house" | "none",
--       enclosureId = id ou nil,
--       canPlace = nombre possible,
--       leftover = ce qui ne peut pas être placé
--   }
function PlayerBoard:findBestEnclosure(species, quantity)
	print("-------------->>>>>>  Recherche d'enclos pour ",quantity,species)
    local groupSame = {}
    local groupEmpty = {}

    -- Parcours de tous les enclos
    for id, enc in pairs(self.enclosures) do
        local free = self:getEnclosureFreeSpace(enc, species)
        local hasOther = self:enclosureHasOtherSpecies(enc, species)
        local isEmpty = self:isEnclosureEmpty(enc)

        if hasOther then
            -- pas candidat
        else
            local count = enc.animals[species] or 0

            -- groupe 1 : enclos contenant déjà l’espèce
            if count > 0 and free > 0 then
                table.insert(groupSame, {enc = enc, free = free})
            
            -- groupe 2 : enclos vides
            elseif isEmpty and free > 0 then
                table.insert(groupEmpty, {enc = enc, free = free})
            end
        end
    end
	print("-------------->>>>>>  Recherche d'enclos",species," ou vide: ",#groupSame,#groupEmpty)
	print("=== findBestEnclosure ===")
--print("species =", species, " quantity =", quantity)
--
--print("Board ref =", self)
--print("Nb enclos =", self.enclosures and #self.enclosures or "nil")
--
--for id, enc in pairs(self.enclosures or {}) do
--    print(" → Enclos", id, ":", #enc.boxes, "cases / capacity", enc.capacity)
--end
    ------------------------------------------------------------
    -- 1) PRIORITÉ : étendre un enclos contenant déjà l’espèce
    ------------------------------------------------------------
    if #groupSame > 0 then
        -- tri par freeSpace descendant
        table.sort(groupSame, function(a,b) return a.free > b.free end)

        local best = groupSame[1]
        local canPlace = math.min(quantity, best.free)

        return {
            type = "enclosure",
            enclosureId = best.enc.id,
            canPlace = canPlace,
            leftover = quantity - canPlace
        }
    end

    ------------------------------------------------------------
    -- 2) SINON : choisir un enclos vide
    ------------------------------------------------------------
    if #groupEmpty > 0 then
        -- tri par capacité croissante (évite gaspillage)
        table.sort(groupEmpty, function(a,b)
            return a.enc.capacity < b.enc.capacity
        end)

        local best = groupEmpty[1]
        local canPlace = math.min(quantity, best.free)

        return {
            type = "enclosure",
            enclosureId = best.enc.id,
            canPlace = canPlace,
            leftover = quantity - canPlace
        }
		
    end

    ------------------------------------------------------------
    -- 3) SINON : maison (1 max, si vide ou même espèce)
    ------------------------------------------------------------
    if (self.houseAnimal == nil or self.houseAnimal == species) and self.player.resources.houseSpace > 0 then

        local canPlace = math.min(quantity, 1)
        return {
            type = "house",
            enclosureId = nil,
            canPlace = canPlace,
            leftover = quantity - canPlace
        }
    end

    ------------------------------------------------------------
    -- 4) AUCUN EMPLACEMENT POSSIBLE
    ------------------------------------------------------------
    return {
        type = "none",
        enclosureId = nil,
        canPlace = 0,
        leftover = quantity
    }
end

-- Place automatiquement des animaux dans les enclos du joueur.
-- Ne déplace JAMAIS les animaux déjà présents.
-- Ne choisit que des enclos compatibles.
-- Remplit d'abord les enclos qui contiennent déjà l'espèce.
-- Puis remplit les enclos vides.
-- Retourne (placed, leftover).

function PlayerBoard:autoPlaceAnimals(species, quantity)
    print("\n=== autoPlaceAnimals ===")
    print("Species =", species, " | Quantity =", quantity)

    if quantity <= 0 then
        return 0, 0
    end

    local placed = 0
    local leftover = quantity

    --------------------------------------------------------------------------
    -- 1. Priorité : remplir les enclos déjà occupés par cette espèce
    --------------------------------------------------------------------------
    for id, enclosure in pairs(self.enclosures) do
        -- espèce identique ?
        if enclosure.animals[species] and enclosure.animals[species] > 0 then
            local current = enclosure.animals[species]
            local freeSpace = enclosure.capacity - current

            if freeSpace > 0 then
                local amount = math.min(leftover, freeSpace)
                enclosure.animals[species] = current + amount

                placed = placed + amount
                leftover = leftover - amount

                print("→ Remplissage enclos existant #" .. id .. " +" .. amount)

                if leftover == 0 then
                    return placed, 0
                end
            end
        end
    end

    --------------------------------------------------------------------------
    -- 2. Deuxième priorité : enclos vides
    --------------------------------------------------------------------------
    for id, enclosure in pairs(self.enclosures) do
        -- enclos totalement vide ?
        if self:isEnclosureEmpty(enclosure) then
            local freeSpace = enclosure.capacity

            if freeSpace > 0 then
                local amount = math.min(leftover, freeSpace)
                enclosure.animals[species] = amount -- première pose

                placed = placed + amount
                leftover = leftover - amount

                print("→ Remplissage enclos vide #" .. id .. " +" .. amount)

                if leftover == 0 then
                    return placed, 0
                end
            end
        end
    end

    --------------------------------------------------------------------------
    -- 3. Aucune place pour le surplus → leftover renvoyé
    --------------------------------------------------------------------------
    print("=== Résultat autoPlaceAnimals ===")
    print("Placed:", placed, " | Leftover:", leftover)

    return placed, leftover
end

-- Espace disponible dans un enclos	
function PlayerBoard:getEnclosureFreeSpace(enc, species)
    local current = enc.animals[species] or 0
    return enc.capacity - current
end

-- Retourne true si l'enclos ne contient aucun animal (toutes espèces confondues)
function PlayerBoard:isEnclosureEmpty(enclosure)
    for species, count in pairs(enclosure.animals) do
        if count > 0 then
            return false
        end
    end
    return true
end


-- l'enclos contient-il une autre espece?
function PlayerBoard:enclosureHasOtherSpecies(enc, species)
    for sp, qty in pairs(enc.animals) do
        if qty > 0 and sp ~= species then
            return true
        end
    end
    return false
end

	

-- ============================================
-- === CRÉATION TEMPORAIRE DE CLÔTURES ===
-- ============================================

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
	
	 -- === NOUVEAU : Retirer aussi les clôtures déjà présentes sur les anciens adjacents ===
    local allAdjacent = self:getAdjacentBoxes(box)
    for _, adj in ipairs(allAdjacent) do
        -- Si le voisin a déjà une clôture sur le côté commun
        local oppDirection = self:getOppositeDirection(adj.direction)
        if adj.box:hasFence(oppDirection) then
            -- Ne pas créer de clôture sur ce côté
            box.fenceData[adj.direction] = false
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
    local allAdjacent = self:getAdjacentBoxes(box)
    
    for _, adj in ipairs(allAdjacent) do
        if self:isBoxInPendingFences(adj.box) then
            table.insert(adjacent, adj)
        end
    end
    
    return adjacent
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
    local allAdjacent = self:getAdjacentBoxes(box)
    for _, adj in ipairs(allAdjacent) do
        local oppDirection = self:getOppositeDirection(adj.direction)
        if adj.box:hasFence(oppDirection) then
            box.fenceData[adj.direction] = false
        end
    end
    
    box:updateFenceVisuals()
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

function PlayerBoard:getPendingFenceCost()
    return self.pendingFences.woodCost
end

function PlayerBoard:hasPendingFences()
    return #self.pendingFences.boxes > 0
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
    
    print(string.format("🔍 %d groupe(s) d'enclos détecté(s)", #groups))
    
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
        print(string.format("✅ Enclos #%d créé avec %d cases", enclosureId, #group))
    end
    
    -- Nettoyer l'état temporaire
    self.pendingFences = {
        boxes = {},
        woodCost = 0
    }
    
    return true
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
    
    -- Récupérer les voisins de cette case
    local adjacent = self:getAdjacentBoxes(box)
    
    for _, adj in ipairs(adjacent) do
        local adjBox = adj.box
        
        if not visited[adjBox] then
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

function PlayerBoard:cancelFences()
    -- Annuler toutes les clôtures temporaires
    for _, box in ipairs(self.pendingFences.boxes) do
        box.fenceData.top = false
        box.fenceData.bottom = false
        box.fenceData.left = false
        box.fenceData.right = false
        box.fenceTurnCreated = nil
        box:hideAllFences()
    end
    
    self.pendingFences = {
        boxes = {},
        woodCost = 0
    }
    
    print("❌ Création de clôtures annulée")
end


function PlayerBoard:debugEnclosures()
    print("\n=== ENCLOS DU JOUEUR " .. self.player.name .. " ===")
    for id, enclosure in pairs(self.enclosures) do
        print(string.format("Enclos #%d | Cases: %d | Capacité: %d | Tour: %d",
            id, #enclosure.boxes, enclosure.capacity, enclosure.turnCreated))
        
        for species, count in pairs(enclosure.animals) do
            if count > 0 then
                print(string.format("  → %s: %d", species, count))
            end
        end
    end
    print("===================================\n")
end


-- ================================================
-- ================================= UTILS  =======
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


