local ACTIONS_DATA = {
    -- Actions permanentes (gardées inchangées)
    permanent = {
        { id = 1, title = "Bois", icon = "gfx/signs/ic_bois.png",
          resources = { { rscType="wood", amount=7 } },
          accumulate = true, col = 2, row = 1,
          comment = "+3 bois par tour" },

        { id = 2, title = "Argile", icon = "gfx/signs/ic_argile.png",
          resources = { { rscType="clay", amount=1 } },
          accumulate = true, col = 1, row = 3,
          comment = "+1 argile par tour" },

        { id = 3, title = "Roseau", icon = "gfx/signs/ic_roseau.png",
          resources = { { rscType="reed", amount=1 } },
          accumulate = true, col = 1, row = 2,
          comment = "+1 roseau par tour" },

        { id = 4, title = "Pêche dans l'étang", icon = "gfx/signs/ic_fish.png",
          resources = { { rscType="food", amount=1 } },
          accumulate = true, col = 1, row = 1,
          comment = "+1 nourriture par tour" },

        { id = 5, title = "Labourer un champ", icon = "gfx/signs/ic_labourage.png",
          special = "labourer",
          workers = 1, col = 4, row = 1,
          comment = "Labourer 1 champ" },

        { id = 6, title = "Construire une pièce", icon = "gfx/signs/ic_room.png",
          special = "construire",
          workers = 1, col = 2, row = 3,
          cost = { material = 5, reed = 2 }, -- par nouvelle pièce
          extraActionId = 26, -- proposer aussi 'Construire une étable'
          comment = "5 bois/argile/pierre\n+ 2 roseaux par pièce" },

        { id = 7, title = "Prendre 1 céréale", icon = "gfx/signs/ic_cereale.png",
          resources = { { rscType="grain", amount=1 } },
          accumulate = false, col = 3, row = 1,
          comment = "Recevez 1 céréale" },

        { id = 8, title = "Premier joueur", icon = "gfx/signs/ic_firstplayer.png",
          special = "first_player",
          resources = { { rscType="food", amount=1 } },
          accumulate = false, col = 2, row = 2,
          comment = "Devenez premier joueur\n+ 1 nourriture" },

        { id = 9, title = "Savoir-faire", icon = "gfx/signs/ic_savoirfaire.png",
          special = "knowledge",
          workers = 1, col = 3, row = 3,
		  cost = { food = 1 },
          comment = "Jouer un savoir faire\nCoûte 1 PN" },

        { id = 10, title = "Journalier", icon = "gfx/signs/ic_repas.png",
          resources = { { rscType="food", amount=2 } },
          accumulate = false, col = 3, row = 2,
          comment = "+2 nourriture" },
    },

    -- Round 1 (tours 2–4) - Colonne 5
    round1 = {
        { id = 11, title = "Aménagement", icon = "gfx/signs/ic_major.png",
          special = "any_improvement",
          workers = 1, col = 5, row = 1,
          comment = "Mineur ou majeur" },

        { id = 12, title = "Semailles", icon = "gfx/signs/ic_semaille.png",
          special = "semaille", noCount = true ,
          workers = 1, col = 5, row = 2,
          extraActionId = 25, -- cuisson comme extra
          comment = "Cuire du pain\n(nécessite un four)" },

        { id = 13, title = "Mouton", icon = "gfx/signs/ic_mouton.png",
          special = "sheep",	
          resources = { { rscType="sheep", amount=1 } },
          accumulate = true, col = 5, row = 3,
          comment = "+1 mouton par tour" },

        { id = 14, title = "Clôtures", icon = "gfx/signs/ic_cloture.png",
          special = "cloture",
          workers = 1, col = 5, row = 4,
		  cost = { wood = 1 },
          comment = "Construire des clôtures" },
    },

    -- Round 2 (tours 5–7) - Colonne 6
    round2 = {
        { id = 15, title = "1 Pierre", icon = "gfx/signs/ic_pierre.png",
          resources = { { rscType="stone", amount=1 } },
          accumulate = true, col = 6, row = 1,
          comment = "+1 pierre par tour" },

        { id = 16, title = "Naissance + Amélioration", icon = "gfx/signs/ic_birth.png",
          special = "naissance",
          workers = 1, col = 6, row = 2,
          extraActionId = 9, -- amélioration mineure (référence au id 9)
          comment = "Agrandir famille\n+ amélioration mineure" },

        { id = 17, title = "Rénovation + Amélioration", icon = "gfx/signs/ic_renovation.png",
          special = "renovation",
          workers = 1, col = 6, row = 3,
          cost = { material = 1, reed = 1 }, -- 99 = per_room (detrompeur)
          extraActionId = 11, -- propose aussi 'Amélioration' (id 11)
          comment = "Rénover la maison:\n1 matériau/pièce + 1 roseau\n+ amélioration" },
    },

    -- Round 3 (tours 8–9) - Colonne 7
    round3 = {
        { id = 18, title = "1 Légume", icon = "gfx/signs/ic_vegetable.png",
          resources = { { rscType="vegetable", amount=1 } },
          accumulate = true, col = 7, row = 1,
          comment = "+1 légume par tour" },

        { id = 19, title = "1 Sanglier", icon = "gfx/signs/ic_cochon.png",
          resources = { { rscType="pig", amount=1 } },
          accumulate = true, col = 7, row = 2,
          comment = "+1 sanglier par tour" },
    },

    -- Round 4 (tours 10–11) - Colonne 7
    round4 = {
        { id = 20, title = "1 Boeuf", icon = "gfx/signs/ic_vache.png",
          resources = { { rscType="cattle", amount=1 } },
          accumulate = true, col = 7, row = 3,
          comment = "+1 boeuf par tour" },

        { id = 21, title = "1 Pierre", icon = "gfx/signs/ic_pierre.png",
          resources = { { rscType="stone", amount=1 } },
          accumulate = true, col = 7, row = 4,
          comment = "+1 pierre par tour" },
    },

    -- Round 5 (tours 12–13) - Colonne 8
    round5 = {
        { id = 22, title = "Labourer", icon = "gfx/signs/ic_labousemaille.png",
          special = "labourer",
          workers = 1, col = 8, row = 1,
          extraActionId = 12, -- semer réutilise la case 12
          comment = "Labourer 1 parcelle et/ou semer" },

        { id = 23, title = "Naissance", icon = "gfx/signs/ic_birth.png",
          special = "naissance",
          workers = 1, col = 8, row = 2,
          comment = "Agrandir famille (même sans place)" },
    },

    -- Round 6 (tours 14+) - Colonne 8
    round6 = {
        { id = 24, title = "Rénovation + Clôtures", icon = "gfx/signs/ic_renovation.png",
          special = "renovation",
          workers = 1, col = 8, row = 3,
          cost = { material = 1, reed = 1 }, --  = per_room
          extraActionId = 14, -- proposer aussi 'Clôtures' (id 14)
          comment = "Rénover toute la maison (1 matériau par pièce + 1 roseau fixe) + clôtures" }
    },

    -- Extra actions (popups secondaires, référencées par extraActionId)
    extra = {
        { id = 25, title = "Cuisson du pain", icon = "gfx/signs/ic_major.png",
          special = "cuisson",
          workers = 0,
		  cost = { grain = 1 }, 
          comment = "Cuire du pain" },

        { id = 26, title = "Construire une étable", icon = "gfx/signs/ic_room.png",
          special = "etable",
          workers = 1,
          cost = { wood = 2 }, -- règle : 2 bois par étable
          comment = "Construire une étable (2 bois par étable)" },
    }
}

-- data des actions jouable
-- cas particuliers (actions speciales en duo) :
-- 'Premier joueur' et 1PN ✅
-- 'Agrandir' et 'Etable' ✅
-- 'Semailles' et/ou 'Cuisson de pain' 
-- 'Rénovation' et 'Aménagement' (facultatif)
-- 'Naissance' et 'Aménagement mineur' (facultatif)
-- 'Labourer' et/ou 'Semailles' ✅
-- 'Rénovation' et 'Clôtures' (facultatif)


Actions = Core.class()

function Actions:init()
    self.data = ACTIONS_DATA
	self:shuffleRounds()
end

function Actions:calculateRewards(actionData, sign)
    local rewards = {}

    if actionData.resources then
        for _, res in ipairs(actionData.resources) do
            rewards[res.rscType] = (rewards[res.rscType] or 0) + sign.stock
        end
    end

    if actionData.special then
        rewards.special = actionData.special
    end

    return rewards
end



-- ================================= HELPERS
function Actions:isSpecialAction()
    if self.data and self.data.special then
        return true
    else
        return false
    end
end

-- récupérer une action par type (utile parfois)
function Actions:getActionByType(typeName)
    for _, a in pairs(self.data) do
        if a.type == typeName then return a end
    end
    return nil
end

-- cherche une action par id dans self.data(permanent, round*, extra)
function Actions:getActionById(id)
    for _,group in pairs(self.data) do
		for _,a in ipairs(group) do
			if a.id == id then return a end
		end
    end
    return nil
end

-- Retourne l'action située à l'index donné (traite toutes les actions comme une liste continue)
function Actions:getActionByIndex(idx)
    if not idx or idx < 1 then return nil end
    
    local currentIndex = 0
    
    -- Ordre de parcours des groupes (ajustez selon votre logique)
    local groupOrder = {"permanent", "round1", "round2", "round3", "round4", "round5", "round6", "extra"}
    
    for _, groupName in ipairs(groupOrder) do
        local group = self.data[groupName]
        if group then
            for _, action in ipairs(group) do
                currentIndex = currentIndex + 1
                if currentIndex == idx then
                    return action
                end
            end
        end
    end
    
    return nil -- Index trop grand
end

function Actions:updateActionCost(player)
	for _,group in pairs(self.data) do	
		for _, data in pairs(group) do       
			-- === CONSTRUCTION ===
			if data.special == "construire" then
				local mat = player.house.rscType
				data.cost = {
					[mat] = 5,
					reed = 2
				}
				
			-- === RENOVATION ===
			elseif data.special == "renovation" then
				local mat = player.house.rscType
				local nextMat
				
				-- Déterminer le matériau supérieur
				if mat == "wood" then
					nextMat = "clay"
				elseif mat == "clay" then
					nextMat = "stone"
				else
					-- Déjà maison en pierre → pas de rénovation possible. On fixe un coût "bloquant"
					data.cost = {stone = 999}
					nextMat = nil 
				end
				
				-- Si un matériau supérieur existe, calculer le coût
				if nextMat then
					local rooms = player.house.rooms or 1
					data.cost = {
						[nextMat] = rooms,
						reed = 1
					}
				end
			end
		end
	end
end

-- Fonction utilitaire pour obtenir l'index global d'une action par son id
function Actions:getIndexById(id)
    local currentIndex = 0
    local groupOrder = {"permanent", "round1", "round2", "round3", "round4", "round5", "round6", "extra"}
    
    for _, groupName in ipairs(groupOrder) do
        local group = self.data[groupName]
        if group then
            for _, action in ipairs(group) do
                currentIndex = currentIndex + 1
                if action.id == id then
                    return currentIndex
                end
            end
        end
    end
    
    return nil -- Action non trouvée
end

function Actions:shuffleRounds()
    local function shuffleArray(array)
        local shuffled = {}
        for i = 1, #array do
            shuffled[i] = array[i]
        end
        
        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end
        
        return shuffled
    end
    
    local roundsToShuffle = {"round1", "round2", "round3", "round4", "round5", "round6"}
    
    for _, roundKey in ipairs(roundsToShuffle) do
        if ACTIONS_DATA[roundKey] and #ACTIONS_DATA[roundKey] > 0 then
           -- print("🎲 Mélange du " .. roundKey .. " (positions préservées)")
            
            -- Sauvegarder les positions originales
            local originalPositions = {}
            for i, action in ipairs(ACTIONS_DATA[roundKey]) do
                originalPositions[i] = {col = action.col, row = action.row}
            end
            
            -- Mélanger les actions
            ACTIONS_DATA[roundKey] = shuffleArray(ACTIONS_DATA[roundKey])
            
            -- Restaurer les positions dans l'ordre original
            for i, action in ipairs(ACTIONS_DATA[roundKey]) do
                action.col = originalPositions[i].col
                action.row = originalPositions[i].row
            end
        end
    end
    
    print("✅ Mélange des cartes terminé")
end