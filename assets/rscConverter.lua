local numberFont = TTFont.new("fonts/K2D-Bold.ttf",36)

RscConverter = Core.class()

function RscConverter:init(player, source, options)
    options = options or {}
	self.mi = source
    self.view = Sprite.new() 
	
	self.name = self.mi.name
	self.player = player

	local slotId = "slot"..player.board.slotList[1]
	table.remove(player.board.slotList,1)
    local freeSlot = player.board[slotId]
	freeSlot:addChild(self.view)

    -- état
	self.useCount = 0
    self.pendingFood = 0
    self.refund = { grain = 0, vegetable = 0, sheep = 0, pig = 0, cattle = 0, wood = 0, reed = 0, clay = 0  }
    self.buttons = {}

	self:createVisualUI(self.mi.uiModel)

    -- ok / cancel handlers
    self.okButton:addEventListener(Event.MOUSE_DOWN, function(event)
        if self.okButton:hitTestPoint(event.x, event.y) and self.okButton:isVisible() then
            event:stopPropagation()
            self:commit()
        end
    end)

    self.cancelButton:addEventListener(Event.MOUSE_DOWN, function(event)
        if self.cancelButton:hitTestPoint(event.x, event.y) and self.cancelButton:isVisible() then
            event:stopPropagation()
            self:cancel()
			self:updateButtons()
        end
    end)

    -- visibilités initiales
    self.okButton:setVisible(false)
    self.cancelButton:setVisible(false)
end


-- Active/désactive un bouton visuellement
function RscConverter:setButtonEnabled(kind, enabled)

    local b = self.buttons[kind]
	if not b then return end -- je m'arrête si une ressource n'existe pas dans ce converter
	
    --b:setVisible(true) -- on garde les boutons en place, on change l'apparence
    if enabled then
        b:setColorTransform(1,1,1,1)
        b:setAlpha(1)
		b.isActive = true
    else
        b:setColorTransform(0.5,0.5,0.5,1)
        b:setAlpha(0.6)
		b.isActive = false
    end
end


-- Met à jour les boutons en fonction du joueur et du contexte 
function RscConverter:updateButtons(context)

   -- local p = self.player or gameManager:getActivePlayer()
	local p = self.player
    if not p then return end

    -- boutons "toujours" visibles mais activés seulement si ressources dispo
	
    self:setButtonEnabled("vegetable", p:canAfford({vegetable = 1}))
    self:setButtonEnabled("sheep", p:canAfford({sheep = 1}))
    self:setButtonEnabled("pig", p:canAfford({pig = 1}))
    self:setButtonEnabled("cattle", p:canAfford({cattle = 1}))
    self:setButtonEnabled("wood", p:canAfford({wood = 1}))
    self:setButtonEnabled("clay", p:canAfford({clay = 1}))
    self:setButtonEnabled("reed", p:canAfford({reed = 1}))	


	if self.mi.id == 0 then
        self:setButtonEnabled("grain", p:canAfford({grain = 1}))
        return 
    end
	
	if not gameManager.bakingTime then
        print(self.mi.id, "désactivé : Le jeu n'est pas en mode cuisson")
        self:setButtonEnabled("grain", false)
        return
    end
	
	-- On est en mode cuisson : vérifier le useLimit
	if self.useCount == 99 then
        self:setButtonEnabled("grain", false)
        return
    end
	
	
    if self.mi.useLimit and self.useCount >= self.mi.useLimit then
        print(self.mi.id, "désactivé : limite d'utilisation atteinte")
        self:setButtonEnabled("grain", false)
        return
    end
	
	-- Sinon, tout est bon : activer si le joueur a du grain
    local canCook = p:canAfford({grain = 1})
    print(self.mi.id, " -> état bouton :", canCook)
    self:setButtonEnabled("grain", p:canAfford({grain = 1}))
end


-- Appelé lorsqu'on clique sur un bouton de conversion
function RscConverter:onPressConversion(rscKind)
--    local p, isSnapshot = gameManager:getActivePlayer()
--
--	if gameManager.currentState == "HARVEST" then -- on est en phase Récolte
--		local p = gameManager.playerList[gameManager.harvestPlayerIndex]	
--	end
	local p = self.player
    -- montrer ok / cancel
    self.okButton:setVisible(true)
    self.cancelButton:setVisible(true)
    self.converterBase:setAlpha(1)

	self:inOutConversion(p,rscKind)
	
    -- update affichage compteur
    self.totalFoodConvert:setText(tostring(self.pendingFood))
	local w = self.totalFoodConvert:getWidth()
	local x = self.totalFoodConvert.myX 
	self.totalFoodConvert:setX(math.floor(x - w/2)) -- utiliser text:center() ici !
	
	p:updateConverterBtn()
    p:updateInventory()
end

function RscConverter:inOutConversion(player, rscKind)
    local cost = {[rscKind] = 1}
    local reward = self.mi.reward 

    if not player:payResources(cost) then
        print("Conversion échouée : pas assez de " .. rscKind)
        return false
    end
	
	if rscKind == "grain" and self.mi.uiModel ~= 0 then
		-- la cuisson de pain est necessaire pour débloquer la conso de grain (sauf pour le feu de base)
		if gameManager.bakingTime == false then
			return false
		else 
		
			self.refund[rscKind] = (self.refund[rscKind] or 0) + 1
			
			self.useCount = self.useCount + 1
			
			for res, amount in pairs(reward) do
				if res == "food" then
					self.pendingFood = (self.pendingFood or 0) + amount
				end
			end
		end
		print("Cuisson grain OK, useCount =", self.useCount, "sur limite", self.mi.useLimit)
	else
		self.refund[rscKind] = (self.refund[rscKind] or 0) + 1
 
		for res, amount in pairs(reward) do
			if res == "food" then
				self.pendingFood = (self.pendingFood or 0) + amount
			end
		end
	end	

    return true
end

-- #################################################################################
-- #################################################################################
-- ############################       UTILITAIRES      #############################
-- #################################################################################

-- Valider transaction : ajoute la nourriture en une fois, vide pending, hide buttons
function RscConverter:commit()
--    local p = self.player or gameManager:getActivePlayer()
--	
--	if gameManager.currentState == "HARVEST" then -- on est en phase Récolte
--		local p = gameManager.playerList[gameManager.harvestPlayerIndex]	
--	end
	
	local p = self.player
    if not p then return end
	
	local toRelocate = {}
	
	for k, spent in pairs(self.refund) do
		-- On vide les animaux SEULEMENT si on en consomme
		if (k == "sheep" or k == "pig" or k == "cattle") and spent > 0 then
			local count = p.board:getTotalAnimalCount(k)
			p.board:removeAnimal(k, count) -- je retire tous les animaux concernés du plateau
			table.insert(toRelocate, k)
		end
	end

    if self.pendingFood and self.pendingFood > 0 then
        p:addResource("food", self.pendingFood)
        p:updateInventory()
    end
	
	for _, animal in ipairs(toRelocate) do
		p.board:autoPlaceAnimals(animal, p.resources[animal])
	end

	gameManager.ui:validAnimalRepartition(p)

	self:resetPending()
    self.okButton:setVisible(false)
    self.cancelButton:setVisible(false)
    --self.converterBase:setAlpha(0.3)
	
	if self.useCount then self.useCount = 99 end
    self.totalFoodConvert:setText("0")
	p:updateConverterBtn()
end

-- CANCEL | Annuler : restitue les ressources remboursables
function RscConverter:cancel(context)
  --  local p = self.player or gameManager:getActivePlayer()
	local p = self.player
    if not p then return end

    for k, v in pairs(self.refund) do
        if v and v > 0 then
            p:addResource(k, v)
        end
    end
    p:updateInventory()	
	
	if self.useCount ~= 99 then self.useCount = 0 end

    self:resetPending()
    self.okButton:setVisible(false)
    self.cancelButton:setVisible(false)

    self.totalFoodConvert:setText("0")
	p:updateConverterBtn() 
end


function RscConverter:resetPending()
    self.pendingFood = 0
	self.refund = { grain = 0, vegetable = 0, sheep = 0, pig = 0, cattle = 0, wood = 0, reed = 0, clay = 0  }
end


-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@@@@@@@@@@@@@@@@@@@@@    CREATION DU VISUEL    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function RscConverter:createVisualUI(model)
 
	-- ok / cancel
	local ok = Bitmap.new(Texture.new("gfx/major/converter/valid_foodConv.png"))
		ok:setPosition(250, -124)
		self.view:addChild(ok)
		self.okButton = ok

	local cancel = Bitmap.new(Texture.new("gfx/major/converter/cancel_foodConv.png"))
		cancel:setPosition(250, -246)
		self.view:addChild(cancel)
		self.cancelButton = cancel

    -- création des boutons 'ressources' qui sont ajoutés à la table self.buttons
	local function makeButton(imgPath, x, y, key)
		local bmp = Bitmap.new(Texture.new(imgPath))
		bmp:setPosition(x, y)
		self.view:addChild(bmp)
		self.buttons[key] = bmp

		-- Ajoute le hotspot cliquable + animation
		addHotspotInteractive(bmp, function()
			self:onPressConversion(key)
		end)

		return bmp
	end	
	
	  -- base du converter
	local converterBase

    -- compteur affiché
    local totalFoodConvert = TextField.new(numberFont, "0")
		totalFoodConvert:setAnchorPoint(0.5,1)
		totalFoodConvert:setTextColor(0x4b2c31)

    self.totalFoodConvert = totalFoodConvert
	
	if model == 0 then -- feu de camp du depart
		converterBase = Bitmap.new(Texture.new("gfx/major/converter/model0_1_base.png"))
		local picIcon = Bitmap.new(Texture.new("gfx/major/converter/model0_1_pic_base.png"))
		converterBase:addChild(picIcon)
		picIcon:setPosition(-150,-150)
		makeButton("gfx/major/converter/model0_btn1.png", 0, -242, "grain")
		makeButton("gfx/major/converter/model1_btn2.png", 124, -242, "vegetable")
		
		totalFoodConvert:setPosition(124, -20)
		totalFoodConvert.myX = 134
		
	elseif model == 11 or model == 12 then -- foyer et fourneau
		if model == 11 then
			converterBase = Bitmap.new(Texture.new("gfx/major/converter/model1_1_base.png"))
		else 
			converterBase = Bitmap.new(Texture.new("gfx/major/converter/model1_2_base.png"))
		end
		
		makeButton("gfx/major/converter/model1_btn1.png", 0, -364, "sheep")
		makeButton("gfx/major/converter/model1_btn2.png", 124, -364, "vegetable")
		makeButton("gfx/major/converter/model1_btn3.png", 0, -488, "pig")
		makeButton("gfx/major/converter/model1_btn4.png", 124, -488, "cattle")
		makeButton("gfx/major/converter/model1_btn5.png", -122, -124, "grain")
		
		totalFoodConvert:setPosition(128, -140)
		totalFoodConvert.myX = 134
		
	elseif model == 21 or model == 22 then -- four argile et four pierre
		if model == 21 then
			converterBase = Bitmap.new(Texture.new("gfx/major/converter/model2_1_base.png"))
		else 
			converterBase = Bitmap.new(Texture.new("gfx/major/converter/model2_2_base.png"))
		end
		
		makeButton("gfx/major/converter/model0_btn1.png", 0, -364, "grain")
		
		totalFoodConvert:setPosition(60, -20)
		totalFoodConvert.myX = 72
		ok:setPosition(126, -124)
		cancel:setPosition(126, -246)
		
	elseif model == 31 or model == 32 or model == 33 then --  menuiserie /  poterie  / vannerie
		if model == 31 then
			converterBase = Bitmap.new(Texture.new("gfx/major/converter/model3_1_base.png"))
			makeButton("gfx/major/converter/model3_1_btn1.png", 0, -364, "wood")
		elseif model == 32 then
			converterBase = Bitmap.new(Texture.new("gfx/major/converter/model3_2_base.png"))
			makeButton("gfx/major/converter/model3_2_btn1.png", 0, -364, "clay")
		else	
			converterBase = Bitmap.new(Texture.new("gfx/major/converter/model3_3_base.png"))
			makeButton("gfx/major/converter/model0_btn1.png", 0, -364, "reed")
		end
		
		totalFoodConvert:setPosition(60, -20)	
		totalFoodConvert.myX = 72
		ok:setPosition(126, -124)
		cancel:setPosition(126, -246)
		
	elseif model == 4 then -- le puit (pas d'interaction)

		converterBase = Bitmap.new(Texture.new("gfx/major/converter/model4_ic_base.png"))
		totalFoodConvert:setVisible(false)

	end
	
    converterBase:setAnchorPoint(0,1)
	converterBase:addChild(totalFoodConvert)
    self.view:addChild(converterBase)
    self.converterBase = converterBase
	
	self:updateButtons() 
end

function addHotspotInteractive(button, onClick)
    local hotspot = Bitmap.new(Texture.new("gfx/major/converter/boutonCarre_hotspot124.png"))
	hotspot:setAnchorPoint(0, 0)

    button:addChild(hotspot)

    -- Animation "pulse" douce (apparition puis extinction rapide)
    local anim = MovieClip.new({
        {1, 1, hotspot, {alpha = 0}},
        {2, 6, hotspot, {alpha = {0, 1, "Linear"}}},
        {8, 14, hotspot, {alpha = {1, 0, "Linear"}}},
    })
    anim:setStopAction(1)
    anim:stop()

    hotspot:addEventListener(Event.MOUSE_DOWN, function(event)
        if hotspot:hitTestPoint(event.x, event.y) and button:getParent():isVisible() and button.isActive then
            event:stopPropagation()
            anim:gotoAndPlay(2)
            if onClick then onClick(event) end
        end
    end)

    button.hotspot = hotspot
    button.hotspotAnim = anim
end
