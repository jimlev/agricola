 --[[
GAMEPLAY FLOW - Machine à états gameManager

=== DÉCOUPAGE MACRO ===
1. GAME_SETUP       : Init unique qui setup l'écran selon les settings (nombre joueurs, actions dispo)
2. ROUND_INIT       : Init du round - affichage numéro round + nouvelle action révélée sur plateau  
3. PLAYER_ACTIVE    : Tour du joueur - meeple dispo + grisage des panneaux interdits
4. ACTION_PENDING   : Action sélectionnée - popup validation/annulation, meeple figé sur panneau
5. ACTION_RESOLVING : Validation - animations récompenses + mise à jour inventaire
6. TURN_END         : Fin du tour joueur → retour PLAYER_ACTIVE (suivant) ou ROUND_END (si tous finis)
7. ROUND_END        : Phase de fin de round → remise des meeples, nourritures/repro, round suivant
7.b HARVEST			: Phase intermediaire dédiée à la récolte
8. GAME_END         : Fin de partie

=== TRANSITIONS ===
Menu Settings 
  → GAME_SETUP 
  → ROUND_INIT 
  → PLAYER_ACTIVE 
      ↔ ACTION_PENDING 
      → ACTION_RESOLVING 
      → TURN_END 
      → ROUND_END 
  → GAME_END

=== FLAGS & CONDITIONS ===
- gameIsPaused : blocage des interactions pour laisser le champ libre aux pop-up temporaires	
- inBuyCardMode : détermine si le joueur consulte les pioches pour acheter ou non
- bakingTime : flag à true quand la cuisson est autorisée
- player.board.isPlayable : blocage des interactions sur le terrain de la ferme du joueur



+== FLOW DE GESTION DES ACTIONS +++  par sécu, le flow se déroule sur un snapshot du joueur.
1. initPendingCreation() a défini le pendingAction > state suivant   
2. pendingDispatcher() : affiche UI. noSpecial / Special >>> handleSpecialAction
3. handleSpecialAction() dispatch vers des fonctions dédiées. Ex. beginLabourAction() 
4. Special Duo > createChoicePopup()
5. les actions sur player.board / gridBox >>> gameManager:handleBoxClick()
6. handleBoxClick() >>> if telle Action then faire ça...
7. le bouton 'valid' de la popup enterine les changement via gameManager:executeAction()

+=======
model pendingAction
 self.pendingAction = {
        player     = player,
        signId     = signId,
        meeple     = meeple,
        sign       = sign,               -- pour l’UI
        actionId   = sign.actionData.id, -- id de l'action métier
        isSpecial  = sign:isSpecialAction()
    }
--]]

-- États du jeu
local GAME_STATES = {
    GAME_SETUP       = "GAME_SETUP",
    ROUND_INIT       = "ROUND_INIT", 
    PLAYER_ACTIVE    = "PLAYER_ACTIVE",
    ACTION_PENDING   = "ACTION_PENDING",   -- Choix posé, popup ouverte
    ACTION_RESOLVING = "ACTION_RESOLVING", -- Validation / exécution
    TURN_END         = "TURN_END",
	HARVEST 		 = "HARVEST",  -- ✨ Nouvel état
    ROUND_END        = "ROUND_END",
    GAME_END         = "GAME_END"
}

-- gameManager principal
gameManager = {
    -- États
    currentState  = GAME_STATES.GAME_SETUP,
    currentPlayer = 1,
    currentRound  = 1,
    maxRounds     = 14,
    gameIsPaused = false,	-- state pour bloquer le jeu pendant certaines gestions
	inBuyCardMode = false ,
	meepleInPlay = nil,
    -- Données de jeu
    playerList    = {},
    gameBoard     = nil,
    ui            = nil,
    
    -- Action en cours
    pendingAction = nil,  -- {playerId, signId, meeple, rewards}
    
    -- Configuration
    playerCount   = 2,
    signs         = {}
}

local playerColors = {"blue","pink","green","brown","yellow","purple"}

-- Machine à états du gameManager
function gameManager:init(playerCount)
	self.ui = stage.UI

	self.playerCount = playerCount or 2
	local rndHuman = math.random(self.playerCount)
 
    print("gameManager: partie initialisée avec: " .. self.playerCount .. " joueurs")
    -- Créer les joueurs
    for i = 1, self.playerCount do
		local isHuman = false
		if i == rndHuman then isHuman = true end
		
		local player = Player.new(i, nil, playerColors[i],isHuman)
		table.insert(self.playerList, player)
    end
    
    self:changeState(GAME_STATES.GAME_SETUP)
end

function gameManager:changeState(newState)
--    print("Transition de " .. self.currentState .. " → " .. newState)
    
    -- Actions de sortie de l'état actuel
    self:exitState(self.currentState)
    
    -- Changer l'état
    local oldState = self.currentState
    self.currentState = newState
    
    -- Actions d'entrée dans le nouvel état
    self:enterState(newState, oldState)
end

function gameManager:exitState(state)
    if state == GAME_STATES.PLAYER_ACTIVE then
        self:setPlayerInteractionsEnabled(false)
    elseif state == GAME_STATES.ACTION_PENDING then

    elseif state == GAME_STATES.TURN_END then
		print("_____________________________________________________ fin de tour")
    end
end

function gameManager:enterState(state, fromState)
    if state == GAME_STATES.GAME_SETUP then
        self:setupGame()
        
    elseif state == GAME_STATES.ROUND_INIT then
        self:initNewRound()
        
    elseif state == GAME_STATES.PLAYER_ACTIVE then
        self:startPlayerTurn()

    elseif state == GAME_STATES.ACTION_PENDING then
        self:pendingDispatcher()
        
    elseif state == GAME_STATES.ACTION_RESOLVING then
        self:executeAction()
        
    elseif state == GAME_STATES.TURN_END then
        self:endPlayerTurn()
        
	elseif state == GAME_STATES.HARVEST then
        self:onEnterHarvest()
		
    elseif state == GAME_STATES.ROUND_END then
        self:endRound()
        
    elseif state == GAME_STATES.GAME_END then
        self:endGame()
    end
end

-- Fonctions d’états spécifiques
function gameManager:setupGame()
    print("Setting up game...")
	
    local gameBoard = board.new()
    stage:addChild(gameBoard)
    stage.gameBoard = gameBoard
	
	createMeepleBank()
		
	local farmLayer = Sprite.new()
	stage:addChild(farmLayer)
    self.farmLayer = farmLayer		
	
	local marketLayer = createOverlay()
	local majorShelf = Sprite.new()
	local minorShelf = Sprite.new()	
	local occupationShelf = Sprite.new()	
	stage:addChild(marketLayer)	

    self.marketLayer = marketLayer	
	self.marketLayer:setVisible(false)
		self.marketLayer:addChild(majorShelf)
		self.marketLayer:addChild(minorShelf)
		self.marketLayer:addChild(occupationShelf)
	    self.marketLayer.majorShelf = majorShelf	
		self.marketLayer.minorShelf = minorShelf	
		self.marketLayer.occupationShelf = occupationShelf	
	
	createPlayerBoard()
	createViewPlayerBoardBtn()
	createViewCardmarketBtn()
	self:createSigns()
	
    stage:addChild(self.ui)

    self:changeState(GAME_STATES.ROUND_INIT)
end

function gameManager:initNewRound()
	-- cartel changement de tour
	local t1, t2 = getRoundInfo(self.currentRound)

	self.ui:queueInfo(t1, t2, 7)
	-- au cas où un joueur ait choisi l'action 'first_player'
	self:reorderPlayers()	
		
    -- Dévoiler les nouvelles actions dispo (règle Agricola)
	local newSign = sign.revealNewSigns(self.currentRound)
	table.insert(self.signs, newSign)
	
	self.ui:queueInfo("Nouvelle action: "..newSign.actionData.title, newSign.actionData.comment, 2)
    -- Reset de chaque sign pour le nouveau round
    for _, sign in ipairs(self.signs) do
        sign:newRound()
    end

    -- 🔄 Reset des meeples de chaque joueur
    for _, player in ipairs(self.playerList) do
        player.availableMeeples = player.familySize
        player.placedMeeples = {}
		player.hasPlayedThisRound = false
    end

    -- Déterminer le premier joueur du round
    self.currentPlayer = self:getFirstPlayer()

    -- Transition vers le premier tour du round
    self:changeState(GAME_STATES.PLAYER_ACTIVE)
end

function gameManager:startPlayerTurn()
    local player = self.playerList[self.currentPlayer]
    print("Au tour de", player.name, "("..player.color..")")
		
    if player.availableMeeples > 0 then
	
	self:updateUIForPlayer(player)
	self:setPlayerInteractionsEnabled(true)
	
		-- Si c’est le premier meeple de ce joueur ce round
		if not player.hasPlayedThisRound then
			player.hasPlayedThisRound = true
			
			local round = self.currentRound
			local message = string.format("Tour "..round.." ,à "..player.name.." de jouer!")
		--if player.timetable:hasTurnEffect(round) then blabla end
			local summary =  player.timetable:applyTurn(round)
			local summaryText = table.concat(summary, " / ")

			self.ui:queueInfo(message, summaryText, 4)

		end		
	
		if self.meepleInPlay == nil then  --c'est un vrai debut de tour, pas un rollback
			player:pickMeeple()   --créé le pointer du meeple qui va etre joué > gameManager.meepleInPlay
		end
		
    else
        print(player.name .. " has no more meeples, skipping turn")
        self:nextPlayer()  -- ⚠️ saute directement au suivant
    end
end

function gameManager:updateUIForPlayer(player)
	for _, sign in ipairs(self.signs) do
        sign:updateForPlayer(player)
    end
    player.inventaire:setVisible(true) 
	player.tokenFocus:setVisible(true)
	updateMeepleBank(player)

end

function gameManager:executeAction()
    if not self.pendingAction then return end
    
    local action = self.pendingAction
    local player = action.player
	local snapshot = player.snapshot
    local sign = self:getSignById(action.signId)

	--  local rewards = sign:calculateRewards()
	--	self:applyRewards(snapshot, rewards)
	
	-- on confirme les changements d'états des Box du playerBoard
	self.ui:killConfirmPopup()
	snapshot.board.isPlayable = false -- sécu car snapshot va être kill
	gameManager.bakingTime = false
	self.inBuyCardMode = false -- les cartes ne sont plus achetables
	
	-- je confirme l'achat de celle sélectionnée et je crée son widget
	if self.currentZoomedCard ~= nil then 
		local converter = RscConverter.new(player, self.currentZoomedCard, 0)
		table.insert(player.converters, converter)		
		
		if self.currentZoomedCard.id == 5 then -- MI 'puit'
			print(self.currentRound)
			player.timetable:addRewardAtTurn(self.currentRound + 1, { food = 1 })
			player.timetable:addRewardAtTurn(self.currentRound + 2, { food = 1 })
			player.timetable:addRewardAtTurn(self.currentRound + 3, { food = 1 })
			player.timetable:addRewardAtTurn(self.currentRound + 4, { food = 1 })
			player.timetable:addRewardAtTurn(self.currentRound + 5, { food = 1 })
		end

		self.currentZoomedCard:isTaken() 
		self.currentZoomedCard:backInMarket()
		self.currentZoomedCard = nil
	end
	-- on surcharge le player par le snapshot...
	self:commitSnapshot(player, snapshot)
	-- ... puis on détruit le snapshot
	self:killSnapshot(player)
	
-- ======================= SNAPSHOT n'existe plus à partir d'ici ;)  ===	
	player.inventaire:setY(player.inventaire:getY()-500)
	player.availableMeeples = player.availableMeeples - 1
    table.insert(player.placedMeeples, action.meeple)

    sign:confirmAction() -- je signale à l'emplacement de vider ses stocks si beson
	
	self.meepleInPlay:onValidSign()
    -- Et maintenant, fin du tour
	-- self:endPlayerTurn()
    self:changeState(GAME_STATES.TURN_END)
end


function gameManager:continueAction()

    if not self.pendingAction then return end

	local action   = self.pendingAction -- on a forcement une pending1 puisqu'on est en 'continue'
    local player   = action.player
    local snapshot = player.snapshot

    -- supprimer le bouton "continue"
    if self.ui.popupLayer.continueBtn then
        self.ui.popupLayer:removeChild(self.ui.popupLayer.continueBtn)
        self.ui.popupLayer.continueBtn = nil
    end
    self.pendingAction.hasValidationButton = false

	snapshot:updateInventory()

    -- passage en step 2 - on avance
    if self.pendingAction.step == 1 then
        self.pendingAction.step = 2
		
		-- masquer le board du snapshot (UI temporaire)
		if snapshot and snapshot.board then
			snapshot.board:setVisible(false)
			snapshot.board.isPlayable = false --je bloque les interactions avec le player.board
		end
		
        -- recalcul de l'affordabilité de l’action2
        if self.pendingAction2 and self.pendingAction2.actionId then
            local actionData2 = actionDB:getActionById(self.pendingAction2.actionId)
            if actionData2 and actionData2.cost then
                local _, maxQuantity = snapshot:canAfford(actionData2.cost)
                self.pendingAction2.actionCounter = maxQuantity
            else
                self.pendingAction2.actionCounter = 1
            end
        end

        -- réafficher la choicePopup et mettre à jour son état
        if self.actionPopup then
           self.actionPopup:setVisible(true) 

            -- désactiver visuellement le bouton 1 (déjà utilisé)
            if self.actionPopup.choicePopUp then
                self.actionPopup.choicePopUp.hs1:removeAllListeners()
                self.actionPopup.choicePopUp.title1:setAlpha(0.3)
            end
			
			-- désactiver visuellement le bouton 2 si le cost est trop élevé (counter == 0)
            if self.pendingAction2.actionCounter == 0 then
                self.actionPopup.choicePopUp.hs2:removeAllListeners()
                self.actionPopup.choicePopUp.title2:setAlpha(0.3)
            end
			
			-- on propose de valider sans executer l'action 2 
			self:displayValidButton()
        end
	elseif not self.pendingAction.step then -- c'est une action simple qui utilise un continue() (double-confirmation) 
		
		if self.marketLayer:isVisible() and self.currentZoomedCard ~= nil then -- le joueur etait en train d'acheter une carte
			self.marketLayer:setVisible(false) 		
			snapshot.board:centerOnX(2600) -- je centre la camera sur les slots du board du joueur
			local id = self.currentZoomedCard.id
			if id == 6 or id == 7 then  
				self.bakingTime = true --apres l'achat de carte cuisson, on peut cuire du pain 
				snapshot:updateConverterBtn()
			else
				self.bakingTime = false
			end
			
			local converter = RscConverter.new(snapshot, self.currentZoomedCard, 0)
			table.insert(snapshot.converters, converter)
			snapshot:payResources(self.currentZoomedCard.cost)
			
			self:displayValidButton()
		end
		return
	end	
end

function gameManager:cancelAction()
    if not self.pendingAction then return end
    
    local action = self.pendingAction
    local sign = self:getSignById(action.signId)
    
    -- rollback sur le sign
    sign:cancelAction()
	gameManager.bakingTime = false

    -- rollback du meeple
    action.meeple:returnHome()

    -- cacher le board du joueur si affiché (???? c fait où ??)
    local player = action.player
	local snapshot = player.snapshot
	
	snapshot.board.isPlayable = false --je bloque les interactions avec le player.board
	-- inutile car le snapshot est kill dans 15 lignes ;) 
--    if snapshot and snapshot.board then 
--        snapshot.board:setVisible(false)
--    end
	self.inBuyCardMode = false -- les cartes ne sont plus achetables
	-- et je confirme l'achat de celle sélectionnée
	if self.currentZoomedCard ~= nil then 
		self:cleanMajorCardsMarket() 
	end
	
    if self.marketLayer:isVisible() then -- je masque puisque 'Cancel'
		if self.currentZoomedCard ~= nil then 
			self.currentZoomedCard:backInMarket()
			self.currentZoomedCard = nil
		end
		
		gameManager.currentZoomedCard = nil
        self.marketLayer:setVisible(false)
    end
	
    -- réinitialiser pendingAction et game paused
    self.pendingAction = nil
    self.gameIsPaused  = false
    if self.nextFirstPlayer == player then self.nextFirstPlayer = nil end
    -- fermer la popup
    self.ui:killConfirmPopup()
	
	-- on kill le snapshot corrompu
    self:killSnapshot(player)
	
	player.inventaire:setY(player.inventaire:getY()-500)
	
    -- retour à l'état actif du joueur
    self:changeState(GAME_STATES.PLAYER_ACTIVE)
end

function gameManager:initPendingCreation(signId, meeple)
    if self.currentState ~= GAME_STATES.PLAYER_ACTIVE then return false end
    
    local sign = self:getSignById(signId)
    if not sign or not sign:canAcceptWorker(self.currentPlayer) then
        return false
    end
    
    local player = self.playerList[self.currentPlayer]

    -- construire pendingAction principale
    self.pendingAction = {
        player     = player,
        signId     = signId,
        meeple     = meeple,
        sign       = sign,               -- pour l’UI
        actionId   = sign.actionData.id, -- id de l'action métier
        isSpecial  = sign:isSpecialAction()
    }
	
	if sign.actionData.cost then
		local _, maxQuantity = player:canAfford(sign.actionData.cost)
		self.pendingAction.actionCounter = maxQuantity
	elseif sign.actionData.noCount then
		self.pendingAction.actionCounter = 999
	else
		self.pendingAction.actionCounter = 1
	end
   
   print("qui a choisi l'action ", actionDB:getActionById(self.pendingAction.actionId).title)
   
    -- préparer pendingAction2 uniquement si nécessaire
    if sign.actionData.extraActionId then
        self.pendingAction2 = {
            player     = player,
            signId     = signId,  -- même emplacement
            meeple     = meeple,
            sign       = sign,
            actionId   = sign.actionData.extraActionId,
            isSpecial  = true,    -- par nature
        }
		self.pendingAction.step = 1
		
		local xtraData = actionDB:getActionById(sign.actionData.extraActionId )
	
		if xtraData.cost then
			local _, maxQuantity = player:canAfford(xtraData.cost)
			self.pendingAction2.actionCounter = maxQuantity
		else
			self.pendingAction2.actionCounter = 1
		end
    else
        self.pendingAction2 = nil
    end
	
	 -- creation du snapshot du joueur
    player.snapshot = self:createPlayerSnapshot(player)
	player.snapshot.inventaire:setVisible(true)
	player.snapshot:updateInventory()
	player.inventaire:setY(player.inventaire:getY()+500)
    self:changeState(GAME_STATES.ACTION_PENDING)
    return true
end


function gameManager:pendingDispatcher()
    if not self.pendingAction then return end
    self.gameIsPaused = true   

    local player = self.pendingAction.player
    local snapshot = player.snapshot
	local actionId   = self.pendingAction.actionId
	
    if not self.pendingAction.isSpecial then
        -- Cas classique > attribution de ressources
		local rewards = actionDB:calculateRewards(actionDB:getActionById(actionId),self.pendingAction.sign)
		self:applyRewards(snapshot, rewards)
		
        self.ui:showConfirmPopup({"valid","rollback"})
    else
        self.ui:showConfirmPopup({"rollback"})
		self:handleSpecialAction()
    end
end



function gameManager:canStartDrag(playerId)
    return self.currentState == GAME_STATES.PLAYER_ACTIVE and 
           self.currentPlayer == playerId
end

function gameManager:nextPlayer()
    local startPlayer = self.currentPlayer

    repeat
        -- Tourne sur les joueurs en cycle
        self.currentPlayer = (self.currentPlayer % self.playerCount) + 1
        local player = self.playerList[self.currentPlayer]

        if player.availableMeeples > 0 then		
            self:changeState(GAME_STATES.PLAYER_ACTIVE)
            return
        end

    until self.currentPlayer == startPlayer

    -- Si personne n’a de meeple disponible → fin du round
    print("🏁 Plus aucun meeple → fin du round")
    self:changeState(GAME_STATES.ROUND_END)
end

function gameManager:endPlayerTurn()
	local player = self.playerList[self.currentPlayer]
	 
    self.pendingAction = nil
    self.meepleInPlay = nil
    self.gameIsPaused = false

	player:resetConverterCount()
	
	player.inventaire:setVisible(false)
	player.tokenFocus:setVisible(false)
	player.fields, player.pastures = player.board:getTypeQty()
	
    self:nextPlayer()
end

function gameManager:endRound()
    print("Round " .. self.currentRound .. " ended")
    
	local harvestRounds = {4, 7, 9, 11, 13, 14}	
    local isHarvestRound = false
	
    for _, tour in ipairs(harvestRounds) do
        if self.currentRound == tour then
            isHarvestRound = true
            break
        end
    end  
	
    self.currentRound = self.currentRound + 1

    if self.currentRound > self.maxRounds then
        self:changeState(GAME_STATES.GAME_END)
    elseif isHarvestRound then
        self:changeState(GAME_STATES.HARVEST)  -- 🌾 Passe en mode récolte
    else
        self:changeState(GAME_STATES.ROUND_INIT)
    end
end

function gameManager:endGame()
    print("Game Over! Thanks for playing.")
    -- TODO: afficher scores, retour menu, etc. 
end


-- ===========================================================
-- =====================   SPECIAL ACTIONS  ==================
-- ===========================================================
function gameManager:handleSpecialAction(pending)
    local p = pending or self.pendingAction
    local player = p.player
	local snapshot = player.snapshot

    -- Récupération de l'action
    local actionData = p.sign and p.sign.actionData or actionDB:getActionById(p.actionId)
    if not actionData then
        print("⚠️ handleSpecialAction: actionData introuvable")
        return
    end

    -- Cas où le joueur a joué une case qui donne 2 actions (il y a un extraActionID dans le pending)
    if actionData.extraActionId then
        local a1 = actionData
        local a2 = actionDB:getActionById(actionData.extraActionId)
        if not a2 then
            print("⚠️ handleSpecialAction: extraAction introuvable")
            return
        end
        self:showDuoChoicePopup(snapshot, a1, a2)

    -- Cas SINGLE
    elseif self.pendingAction.isSpecial then

        self:dispatchActionToHandler(actionData,snapshot)

	else -- cas des single de ressources, on affiche la validation immédiate
        self:dispatchActionToHandler(actionData,snapshot)
		self.ui:showConfirmPopup({"valid"}) -- 
    end
end


function gameManager:dispatchActionToHandler(actionData, snapshot)
    -- Redirection selon le type d’actiond
	self.currentAction = actionData.special
	self.currentActionCost = actionData.cost or nil
	 
    if self.currentAction == "labourer" then
        self:beginLabourAction(snapshot)
    elseif self.currentAction == "construire" then
        self:beginNewRoom(snapshot)
	elseif self.currentAction == "first_player" then
      	self.nextFirstPlayer = snapshot.originalPlayer
		
		-- ajout du point de nourriture >>> à mutualiser ?
		snapshot.resources.food = snapshot.resources.food + 1
		self:displayValidButton()

	elseif self.currentAction == "semaille" then
		self:beginSemailleAction(snapshot)
       
	elseif self.currentAction == "cloture" then
       	
	elseif self.currentAction == "naissance" then
       
	elseif self.currentAction == "renovation" then
       		
	elseif self.currentAction == "minor_improvement" then
      	
	elseif self.currentAction == "any_improvement" then
		self:beginBuyImprovement(snapshot)
		
	elseif self.currentAction == "cuisson" then
		print("CUISSON ",#snapshot.originalPlayer.majorCard)
		if #snapshot.originalPlayer.majorCard >= 1 then -- ne marche pas si le joueur a le puit ! TODO
			self:beginBakingAction(snapshot)
		end	
			
	elseif self.currentAction == "etable" then
      	self:beginAddStable(snapshot)	
    else
        print("⚠️ Tentative d'action inconnue : " .. tostring(action),tostring(action.title))
    end
end


-- Fonctions 'metiers' des differentes actions 
function gameManager:beginLabourAction(player) -- "labourer"
    player.board:setVisible(true)
	player.board.isPlayable = true
end

function gameManager:beginSemailleAction(player) -- "semaille"
    player.board:setVisible(true)
	player.board.isPlayable = true
end

function gameManager:beginNewRoom(player)  -- "construire"
    player.board:setVisible(true)
	player.board.isPlayable = true
end

function gameManager:beginAddStable(player)   -- "etable"
    player.board:setVisible(true)
	player.board.isPlayable = true
end

function gameManager:beginBakingAction(player)   -- "cuisson"
    player.board:setVisible(true)
	player.board:centerOnX(2600)
	gameManager.bakingTime = true
	player:updateConverterBtn()
	self:displayValidButton()
end


function gameManager:beginBuyImprovement(player)   -- "Amelioration"
	-- j'affiche le board du joueur pour preparer le placement du widget MI
    player.board:setVisible(true) 
	player.board.isPlayable = false
	-- j'active le mode achat des cartes (pour que le bouton Continue puisse s'afficher)
	gameManager.inBuyCardMode = true
	gameManager.marketLayer:setVisible(true)	
	self:updateMajorCardsMarket()

end
-- +++++++++++++++++++++++++++++++++++++ CLIC CLIC CLIC +++++++++++++++++++++++++++++++++++++

function gameManager:handleCardBuy(card)

	self:displayContinueButton()	
end

function gameManager:handleBoxClick(box)
    local snapshot = self.pendingAction.player.snapshot
	local cost = self.currentActionCost
	local counter = self.pendingAction.actionCounter
	
	-- si Step alors c'est un Duo. j'update counter en fct de l'avancement
	if self.pendingAction.step == 1 then  counter = self.pendingAction.actionCounter end
	if self.pendingAction.step == 2 then  counter = self.pendingAction2.actionCounter end	

    -- 1. Si plus de coups disponibles, on ignore
    if counter <= 0 then
        return
    end 

    local valid = false

    -- 2. Vérifier le type d’action
    if self.currentAction == "labourer" and box.state == "friche" then
		box:convertToField()
		valid = true
		
	elseif self.currentAction == "semaille" and box.myType == "field" then
			
		if box:canPlant() then	
			box:plantSeed()
			valid = true
		end
		
    elseif self.currentAction == "construire" and box.state == "friche" then
        local mat = "m_" .. snapshot.house.rscType
        box:setState(mat, nil)
		
		if cost then
			snapshot:payResources(cost)
			--snapshot:updateInventory()
			--self.pendingAction.player:updateInventory()
        end
        
		valid = true

    elseif self.currentAction == "etable" and box.state == "friche" then
        box:setState("etable", nil)
		
		if cost then
			snapshot:payResources(cost)
			snapshot:updateInventory()
        end
		valid = true
		
    end

    -- 3. Si clic valide, on décrémente et on affiche les bons boutons
    if valid then

        if self.pendingAction.step == 1 then
            self:displayContinueButton()
			self.pendingAction.actionCounter = self.pendingAction.actionCounter - 1
        elseif self.pendingAction.step == 2 then
			self:displayValidButton()
			self.pendingAction2.actionCounter = self.pendingAction2.actionCounter - 1
		elseif not self.pendingAction.step then
			self:displayValidButton()
			self.pendingAction.actionCounter = self.pendingAction.actionCounter - 1
		end
 
    end
end

-- §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
-- §§§§§§§§§§§§§§§§§     HARVEST TIME     §§§§§§§§§§§§§§§§§§§§
-- §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
function gameManager:onEnterHarvest()
	print("🌾 Début de la phase de récolte")
	self.harvestPlayerIndex = 1 -- on va commencer par le premier joueur
    self:startHarvestPhase()
end

-- PHASE DE RÉCOLTE
function gameManager:startHarvestPhase()
	local player = self.playerList[self.harvestPlayerIndex]
    self:harvestTime_phaseOne(player)
end	
	
function gameManager:harvestTime_phaseOne(player)
     -- Étape 1 : Récolte champs
	player.board:setVisible(true)
    player.board:centerOnX(200)
    
    self.ui:queueInfo("Récolte des champs :", player:getHarvestSummary(), 3, function()
        self:harvestTime_phaseTwo(player)
    end)
end

function gameManager:harvestTime_phaseTwo(player)
     -- Étape 2 : Nourrir la famille
    player.board:centerOnX(2800)
	
    self.ui:queueInfo("Nourriture nécessaire "..player:neededFoodCount(), "Vous avez " .. player:getFoodSummary(), 5)

    self:harvestTime_phaseThree(player)
end

function gameManager:harvestTime_phaseThree(player)
     -- Étape 3 : Naissance animaux
    player.board:centerOnX(800)
    self.ui:queueInfo("Naissance chez vos animaux", "Vous obtenez : " .. player:getReproSummary(), 5)
	-- player.board:setVisible(false)
    self:endHarvestPhase()
end

function gameManager:endHarvestPhase()
    print("🌾 Fin de la phase de récolte")
    -- Retour au cycle normal
    self:changeState(GAME_STATES.ROUND_INIT)
end

-- +++++++++++++++++++++++ HELPERS +++++++++++++++++++++++++++
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function gameManager:showDuoChoicePopup()
    local player = self.pendingAction.player  
	local snapshot = player.snapshot
	
	local p1, p2 = self.pendingAction, self.pendingAction2
    local action1 = actionDB:getActionById(p1.actionId)
    local action2 = actionDB:getActionById(p2.actionId)

    -- Chaque bouton déclenche l’exécution de l’action correspondante
    local fct1 = function() self.pendingAction.step = 1; self:dispatchActionToHandler(action1,snapshot) end
    local fct2 = function() self.pendingAction.step = 2; self:dispatchActionToHandler(action2,snapshot) end

    -- On crée la popup avec les labels et callbacks
    self.actionPopup = self.ui:createChoicePopup(action1, fct1, action2, fct2)
end


function gameManager:displayValidButton()
	if not self.pendingAction.hasValidationButton then
		self.ui:showConfirmPopup({"valid"})
		self.pendingAction.hasValidationButton = true
	end
end

function gameManager:hideValidButton()
	if self.pendingAction.hasValidationButton then
		self.ui:killValidButton()
		self.pendingAction.hasValidationButton = false
	end
end
 
function gameManager:displayContinueButton()
	if not self.pendingAction.hasValidationButton then
		self.ui:showConfirmPopup({"continue"})
		self.pendingAction.hasValidationButton = true
	end
end

function gameManager:updateMajorCardsMarket()
    for i, card in ipairs(self.majorMarket) do
        card:updateMarketView()
    end
end

function gameManager:cleanMajorCardsMarket()
    for i, card in ipairs(self.majorMarket) do
        card:backInMarket()
    end
end

function gameManager:createSigns()
    self.signs = sign.createAllSigns()
end

function gameManager:getSignById(id)
    for _, s in ipairs(self.signs) do
        if s.actionId == id then return s end
    end
    return nil
end

function gameManager:applyRewards(player, rewards)
	
    for resource, amount in pairs(rewards) do
        if resource ~= "special" then
            player:addResource(resource, amount)
        else
            -- on verra si on doit faire un truc pour les reward 'special'
        end
    end
end

function gameManager:setPlayerInteractionsEnabled(enabled)
    -- À connecter avec UI/Meeple
end

function gameManager:getFirstPlayer()
    return 1
end

function gameManager:reorderPlayers()
    if not self.nextFirstPlayer then return end

    local newOrder = {}
    local index
    -- trouver sa position actuelle
    for i,player in ipairs(self.playerList) do
        if player == self.nextFirstPlayer then
            index = i
            break
        end
    end

    -- construire le nouvel ordre
    for i=index, #self.playerList do
        table.insert(newOrder, self.playerList[i])
    end
    for i=1, index-1 do
        table.insert(newOrder, self.playerList[i])
    end

    self.playerList = newOrder
	
	-- je reordonne les token
	for i, player in ipairs(self.playerList) do
        player:updateMyTokenPlace(i) -- on passe l’index courant
    end
	
    self.nextFirstPlayer = nil
end

-- ===================================================
-- =================== FONCTIONS PERIPHERIQUES
function gameManager:getActivePlayer()
	local player = self.playerList[self.currentPlayer]
    if player and player.snapshot then
        return player.snapshot, true
    end
    return player, false
end


-- clone de player
function gameManager:createPlayerSnapshot(player)
    local originalPlayer = player

    if not originalPlayer then return nil end
    
	local cloneName = originalPlayer.name .." clone" 
    -- Créer un nouveau joueur de base
    local snapshot = Player.new(
        originalPlayer.id,
        cloneName,
        originalPlayer.color,
        originalPlayer.isHuman
    )
   
    snapshot.originalPlayer = originalPlayer
	-- Copier uniquement les données nécessaires avec deep snapshot
    snapshot.resources = table.clone(originalPlayer.resources, nil, true)
	snapshot.majorCard = table.clone(originalPlayer.majorCard, nil, true)
	--snapshot.converters = table.clone(originalPlayer.converters, nil, true)

    snapshot.familySize = originalPlayer.familySize
    snapshot.house = table.clone(originalPlayer.house, nil, true)
    snapshot.fields = originalPlayer.fields
    snapshot.pastures = originalPlayer.pastures
    snapshot.availableMeeples = originalPlayer.availableMeeples

    snapshot.pendingMajorCardIndex = originalPlayer.pendingMajorCardIndex

	snapshot:spawnPlayerBoard() 
	
	for row = 1, #snapshot.board.boxes do
        for col = 1, #snapshot.board.boxes[row] do
            local snapshotGridBox = snapshot.board.boxes[row][col]
            local playerGridBox = originalPlayer.board.boxes[row][col]
            
			snapshotGridBox.myType = playerGridBox.myType 
			snapshotGridBox.mySeed = playerGridBox.mySeed  
			snapshotGridBox.isGrowing = playerGridBox.isGrowing 
			snapshotGridBox.mySeedAmount = playerGridBox.mySeedAmount
			snapshotGridBox.mySpecies = playerGridBox.mySpecies
			snapshotGridBox.animals = playerGridBox.animals
			snapshotGridBox.pastureLimit = playerGridBox.pastureLimit
			snapshotGridBox.hasStable = playerGridBox.hasStable
			
			snapshotGridBox:setState(playerGridBox.state)
        end
    end

	for i = 2, #originalPlayer.converters do -- je ne prends pas l'index 1 qui est spawn a la créa du joueur
		local converter = RscConverter.new(snapshot, originalPlayer.converters[i].mi, 0)
		table.insert(snapshot.converters, converter)
	end
	--snapshot.board.slotList = table.clone(originalPlayer.board.slotList, nil, true)
	return snapshot
end

function gameManager:killSnapshot(player)
	local originalPlayer = player
	self:cleanupSnapshot(originalPlayer.snapshot)
	--originalPlayer.snapshot.inventaire = nil
    originalPlayer.snapshot = nil
	collectgarbage()
end

-- Fonction pour nettoyer un snapshot et libérer ses ressources
function gameManager:cleanupSnapshot(snapshot)
    if not snapshot then return end
    
    -- Supprimer le board du snapshot s'il existe
    if snapshot.board and snapshot.board:getParent() then
        snapshot.board:getParent():removeChild(snapshot.board)
        snapshot.board = nil
    end
    
    -- Supprimer l'inventaire du snapshot s'il existe
    if snapshot.inventaire and snapshot.inventaire:getParent() then
        snapshot.inventaire:getParent():removeChild(snapshot.inventaire)
        snapshot.inventaire = nil
    end
    
    -- Nettoyer les références
    snapshot.originalPlayer = nil
    snapshot.inventoryCounters = nil
    
--    print("🧹 Snapshot nettoyé")
end

function gameManager:commitSnapshot(player, clone)
    local originalPlayer = player
    if not originalPlayer or not clone then return false end
    
    -- Copier toutes les données du clone vers le joueur original
    originalPlayer.resources = table.clone(clone.resources, nil, true)
    originalPlayer.familySize = clone.familySize
    originalPlayer.house = table.clone(clone.house, nil, true)
    originalPlayer.fields = clone.fields
    originalPlayer.pastures = clone.pastures
    originalPlayer.availableMeeples = clone.availableMeeples

	originalPlayer.majorCard = table.clone(clone.majorCard, nil, true)
	--originalPlayer.converters = table.clone(clone.converters, nil, true)
	
    -- Mettre à jour l'interface du joueur original
    originalPlayer:updateInventory()
    
	--originalPlayer.board.boxes = table.clone(clone.board.boxes, nil, true)
	    -- IMPORTANT : Synchroniser les états des GridBox sans remplacer les objets
    for row = 1, #originalPlayer.board.boxes do
        for col = 1, #originalPlayer.board.boxes[row] do
            local originalGridBox = originalPlayer.board.boxes[row][col]
            local cloneGridBox = clone.board.boxes[row][col]
            if originalGridBox and cloneGridBox then
				
				originalGridBox.myType = cloneGridBox.myType 
				originalGridBox.mySeed = cloneGridBox.mySeed 
				originalGridBox.isGrowing = (cloneGridBox.mySeed ~= nil) 
				originalGridBox.mySeedAmount = cloneGridBox.mySeedAmount
				originalGridBox.mySpecies = cloneGridBox.mySpecies
				originalGridBox.animals = cloneGridBox.animals
				originalGridBox.pastureLimit = cloneGridBox.pastureLimit
				originalGridBox.hasStable = cloneGridBox.hasStable
				
				originalGridBox:setState(cloneGridBox.state)
            end
        end
    end
--	print("--------------------------------  < < < 🧑‍🤝‍🧑 Player rétabli")
    return true
end


-- Sauvegarde (structure de base)
function gameManager:saveGame()
    local saveData = {
        currentState  = self.currentState,
        currentPlayer = self.currentPlayer,
        currentRound  = self.currentRound,
        playerList    = {}
    }
    
    -- Sauver les données des joueurs
    for _, player in ipairs(self.playerList) do
        table.insert(saveData.playerList, {
            id              = player.id,
            name            = player.name,
            resources       = player.resources,
            availableMeeples= player.availableMeeples
            -- ... autres données utiles à rajouter
        })
    end
    
    -- TODO: Écrire dans un fichier ou serialization
    print("💾 Game saved!")
    return saveData
end

-- ======================================
-- ============ DEBUGGUEUR  =====
function gameManager:debugState()
    print("\n===== DEBUG STATE ======")
	print("Mémoire utilisée : " .. math.floor(collectgarbage("count")) .. " Ko")

	-- Round et state
    print(string.format("Round: %d | State: %s", self.currentRound or 1, self.currentState or "nil"))

    -- Current player
    local currentPlayerStr = "nil"
    if self.currentPlayer and self.playerList[self.currentPlayer] then
        currentPlayerStr = self.currentPlayer .. " - " .. self.playerList[self.currentPlayer].name
    end
    print("Current Player:", currentPlayerStr)

    -- Pending action
    if self.pendingAction then
        local sign = self:getSignById(self.pendingAction.signId)
        local signTitle = sign and sign.actionData.title or "nil"
        print(string.format("PendingAction: ID=%s | Sign='%s' | Meeple=%s | Player=%s | Counter=%s",
            tostring(self.pendingAction.signId),
            signTitle,
            self.pendingAction.meeple and self.pendingAction.meeple.myName or "nil",
            self.pendingAction.player.name or "nil", self.pendingAction.actionCounter or "nil"
        ))
    else
        print("PendingAction: nil")
    end

    -- Meeple en cours de déplacement
    print("MeepleInPlay:", self.meepleInPlay and self.meepleInPlay.myName or "nil")

    -- Game paused
    print("Game Paused:", self.gameIsPaused and "YES" or "NO")

    -- Joueurs
    for idx, player in ipairs(self.playerList) do
        print(string.format("\nPlayer %d - %s  - %s", idx, player.name, player.color))
        print("  Meeples placed:", #player.placedMeeples, " | Meeple total :" ..player.familySize)
        for _, m in ipairs(player.placedMeeples) do
            print("    •", m.myName, "available=", m.available)
        end

        -- Tableau des ressources 
        print(string.format(
            "  Inventaire || wood: %d | clay: %d | stone: %d | reed: %d | grain: %d | vegetable: %d | sheep: %d | pig: %d | cattle: %d | food: %d |",
            player.resources["wood"], player.resources["clay"], player.resources["stone"], player.resources["reed"], 
            player.resources["grain"], player.resources["vegetable"], player.resources["sheep"], player.resources["pig"], 
            player.resources["cattle"], player.resources["food"]
        ))

        -- États des GridBox du PlayerBoard
        if player.board and player.board.boxes then
            local stateCounts = {}

            for r = 1, player.board.rows do
                for c = 1, player.board.cols do
                    local box = player.board.boxes[r][c]
                    if box then
                        local st = box.state or "friche"  -- fallback si nil
                        stateCounts[st] = (stateCounts[st] or 0) + 1
                    end
                end
            end

            -- Résumé formaté
            local parts = {}
            for st, count in pairs(stateCounts) do
                table.insert(parts, st .. ": " .. count)
            end
            print("  PlayerBoard || " .. table.concat(parts, " | "), "| Nbre de converter: ",#player.converters)
        end

        -- Afficher le snapshot s'il existe
        if player.snapshot then
            print("  --- SNAPSHOT --- ", player.snapshot.name)
            
            -- Ressources du snapshot
            if player.snapshot.resources then
                print(string.format(
                    "  Snapventaire || wood: %d | clay: %d | stone: %d | reed: %d | grain: %d | vegetable: %d | sheep: %d | pig: %d | cattle: %d | food: %d |",
                    player.snapshot.resources["wood"] or 0, 
                    player.snapshot.resources["clay"] or 0, 
                    player.snapshot.resources["stone"] or 0, 
                    player.snapshot.resources["reed"] or 0, 
                    player.snapshot.resources["grain"] or 0, 
                    player.snapshot.resources["vegetable"] or 0, 
                    player.snapshot.resources["sheep"] or 0, 
                    player.snapshot.resources["pig"] or 0, 
                    player.snapshot.resources["cattle"] or 0, 
                    player.snapshot.resources["food"] or 0
                ))
            else
                print("  Snapventaire: nil")
            end

            -- GridBox du snapshot
			if player.snapshot.board and player.snapshot.board.boxes then
                local snapshotStateCounts = {}

				for r = 1, player.snapshot.board.rows do
					for c = 1, player.snapshot.board.cols do
						local box = player.snapshot.board.boxes[r][c]
						if box then
							local st = box.state or "friche"  -- fallback si nil
							snapshotStateCounts[st] = (snapshotStateCounts[st] or 0) + 1
						end
					end
				end
               
                -- Résumé formaté
                local snapshotParts = {}
                for st, count in pairs(snapshotStateCounts) do
                     table.insert(snapshotParts, st .. ": " .. count)
                end
                print("  SnapshotBoard || " .. table.concat(snapshotParts, " | "), "| Nbre de converter: ",#player.snapshot.converters)
            else
                print("  Snapshot GridBox: nil")
            end
			--print("Converter : ", #player.snapshot.converters)
			--if #player.snapshot.converters > 0  then player.snapshot.converters[1]:createVisualUI(player.snapshot.converters[1].mi.uiModel) end
        else
            print("  Snapshot: nil")
        end
    end
    
    -- Vérifier les conditions de drag possibles
    print("\n--- Drag Checks ---")
    if self.currentPlayer and self.playerList[self.currentPlayer] then
        local player = self.playerList[self.currentPlayer]
        print("Player available meeples:", player.availableMeeples - #player.placedMeeples)
        print("Is GameIsPaused ?", self.gameIsPaused)
		print("Is it bakingTime ?", gameManager.bakingTime)
    end
    print("========================\n")
end