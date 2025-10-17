

local base_basic = {"gfx/signs/sign_basic_bg1.png","gfx/signs/sign_basic_bg2.png","gfx/signs/sign_basic_bg3.png","gfx/signs/sign_basic_bg4.png","gfx/signs/sign_basic_bg5.png"}
local grey_basic = {"gfx/signs/grey_basic_bg1.png","gfx/signs/grey_basic_bg2.png","gfx/signs/grey_basic_bg3.png","gfx/signs/grey_basic_bg4.png","gfx/signs/grey_basic_bg5.png"}

local basefont = TTFont.new("fonts/GentiumPlus-Bold.ttf",30)
local secondfont = TTFont.new("fonts/GentiumPlus-Regular.ttf",24)
local numberFont = TTFont.new("fonts/K2D-Bold.ttf",28)

sign = Core.class(Sprite)

function sign:init(actionData)
    self.myType = "sign"
    self.active = true 
    self.occupied = false
    self.meepleOnMe = nil
    
    -- Données de l'action
    self.actionId = actionData.id
    self.actionData = actionData
	
	--print(self.actionData.resources[1].rscType)

    self.stock = 0
    
    -- Initialiser l'accumulation self.actionData.resources[n].rscType
    if actionData.accumulate then
        self.stock = 0
    end
	
    self:setAnchorPoint(0.5, 0.5)
	
    self:createVisuals()
end

function sign:createVisuals()
    -- Fond aléatoire
	local randBg = math.random(#base_basic)
	
    local fond = Bitmap.new(Texture.new(base_basic[randBg]))
    self:addChild(fond)
	fond:setAnchorPoint(0.5, 0.5)
    self.background = fond
	
	local greyed = Bitmap.new(Texture.new(grey_basic[randBg]))
    fond:addChild(greyed)
	greyed:setAnchorPoint(0.5, 0.5)
    self.greyed = greyed	
	self.greyed:setVisible(false)
    
	local hotspot = Bitmap.new(Texture.new("gfx/signs/sign_hotspot_basic.png"))
    self:addChild(hotspot)
	hotspot:setAnchorPoint(0.5, 0.56)
    self.hotspot = hotspot
	self.hotspot:setVisible(false)
	
    -- Icône de l'action
	local icon = Bitmap.new(Texture.new(self.actionData.icon))
	icon:setAnchorPoint(0.5, 0.5)
	icon:setPosition(-154,-8)
	fond:addChild(icon)
	self.icon = icon
	
	-- Badge pour actions accumulatives
	if self.actionData.accumulate then
		local badge = Bitmap.new(Texture.new("gfx/signs/ic_badge.png"))
		badge:setAnchorPoint(0,0)
		badge:setPosition(-76,-52)
		icon:addChild(badge)
		self.badge = badge
		
		local badgeCount = TextField.new(numberFont, tostring(self.stock))
		badgeCount:setAnchorPoint(0.5,0)
		badgeCount:setTextColor(0xffffff)
		badgeCount:setPosition(100,38)	
		badge:addChild(badgeCount)
		self.badgeCount = badgeCount
	end
    
    -- Titre de l'action
    local signTitle = TextField.new(basefont, self.actionData.title)
    signTitle:setAnchorPoint(0,0)
    signTitle:setTextColor(0x4b2c31)
    signTitle:setPosition(-100,-24)	
    fond:addChild(signTitle)
	self.title = signTitle
    
    -- Commentaire
    if self.actionData.comment then
        local comment = TextField.new(secondfont, self.actionData.comment, self.actionData.comment)
        comment:setAnchorPoint(0,0)
        comment:setTextColor(0x4b2c31)
        comment:setPosition(0,8)	
		comment:setLayout( {w=340,lineSpacing=-8,flags=FontBase.TLF_TOP})
        signTitle:addChild(comment)
		self.comment = comment
    end
	
	self.meeplePlace = Sprite.new()
		self:addChild(self.meeplePlace)
		self.meeplePlace:setAnchorPoint(0.5, 0.5)
		self.meeplePlace:setPosition(132, -24)		
end

function sign:canAcceptWorker(playerId)
    return self.active and not self.occupied
end


function sign:confirmAction()
    -- Finaliser le placement
    self.occupied = true
	
	if self.actionData.resources and #self.actionData.resources > 0 then
		self.stock = 0
    else
        -- action spéciale 
    end

    self:updateVisuals()
end

function sign:cancelAction()
    -- Annuler le placement
    self.currentWorker = nil
end

-- appelé à chaque début de round sur chaque sign
function sign:newRound()
    -- nettoyage visuel / état
    self.occupied = false
    if self.meepleOnMe then
        self:removeChild(self.meepleOnMe)
        self.meepleOnMe = nil
    end

    -- safe guard : self.actionData peut être nil pour certains signs (rare)
    if not self.actionData then
        self.stock = 0
        return
    end

    -- si le panneau a des ressources définies (table non vide)
    if self.actionData.resources and #self.actionData.resources > 0 then

        local resInfo = self.actionData.resources[1]  -- généralement 1 entrée
        local amount = tonumber(resInfo.amount) or 0

        if self.actionData.accumulate then
            -- accumulate : on ajoute la quantité au stock existant
            self.stock = (self.stock or 0) + amount
        else
            -- non-accumulate : stock = quantité fixe (ex: 1 grain)
            self.stock = amount
        end
    else
        -- action spéciale (pas de ressources directes) → stock à 0
        self.stock = 0
    end
	
	self:updateVisuals()
end

function sign:updateVisuals()
    -- Mettre à jour le badge
    if self.badgeCount then
        self.badgeCount:setText(tostring(self.stock))
		self.badgeCount:setX(108-math.floor(self.badgeCount:getWidth()/2))
    end
    
    -- Changer l'apparence si occupé
    if self.occupied then
		self.greyed:setVisible(true)
		self.icon:setAlpha(.8)
		if self.actionData.accumulate then
			self.badgeCount:setVisible(false)
			self.badge:setVisible(false)
		end
		self.title:setTextColor(0x444444)
		self.comment:setTextColor(0x444444) 
	elseif not self.active then 	
		self.greyed:setVisible(true)
		self.icon:setAlpha(.8)
		if self.actionData.accumulate then
			--self.badgeCount:setColorTransform(.5,.5,.5)
			self.badge:setColorTransform(.5,.5,.5)
		end
		self.title:setTextColor(0x444444)
		self.comment:setTextColor(0x444444) 
    else
		self.greyed:setVisible(false)
		self.icon:setAlpha(1)
		if self.actionData.accumulate then
			self.badgeCount:setVisible(true)
			self.badge:setVisible(true)
		end
		self.title:setTextColor(0x4b2c31)
		self.comment:setTextColor(0x4b2c31) 
        self.background:setAlpha(1.0)
    end
end


-- Mettre à jour les actions en fonction des possibilités des joueurs (ressource dispo)
function sign:updateForPlayer(player)
    local data = self.actionData
    local canUse = true

    -- si pas de cost, on laisse visible sinon...
    if data.cost then
		
        for rsc, amount in pairs(data.cost) do
            local actualResource = rsc
            if rsc == "material" then
                actualResource = player.house.rscType
            end

            local playerAmount = player.resources[actualResource] or 0
            if playerAmount < amount then
                canUse = false
                break  -- si une ressource manque, on stoppe la vérification
            end
        end
		
    end
	if data.special == "semaille" and player.fields == 0 then  
		canUse = false
	end	
	self.active = canUse
	self:updateVisuals()
end

function sign:hiliteMe()
	if self.active and not self.occupied then
		self:setScale(1.2)
	end
end

function sign:unhiliteMe()
	self:setScale(1)
end

-- Fonction pour créer tous les panneaux selon le contexte
function sign.createAllSigns()
    local signs = {}
    -- Actions permanentes
    for _, actionData in ipairs(actionDB.data.permanent) do
        local signInstance = sign.new(actionData)
        table.insert(signs, signInstance)
		stage.gameBoard.midLayer:addChild(signInstance)
		signInstance:setPosition(sign.getCoords(signInstance.actionData.col, signInstance.actionData.row))
    end
	return signs
end

function sign.getCoords(col,row)
	local posX = (col*600)-2680
	local posY = (row*200)-470
	
	return posX,posY
end	

-- Fonction pour révéler de nouvelles actions
function sign.revealNewSigns(currentRound)

    local permanentActionQty = #actionDB.data.permanent  -- on saute les actions permanente de l'init
	local actionData = actionDB:getActionByIndex (currentRound+permanentActionQty)	
	
	local signInstance = sign.new(actionData)
	stage.gameBoard.midLayer:addChild(signInstance)
	signInstance:setPosition(sign.getCoords(signInstance.actionData.col, signInstance.actionData.row))

    print("! ! ! ! ! ! ! ! ! ! ! ! ! 🍻 CE TOUR, on ajoute l'action :",signInstance.actionData.title)
    return signInstance
end


-- ================================= HELPERS

function sign:isSpecialAction()
    if self.actionData and self.actionData.special then
        return true
    else
        return false
    end
end

function sign:actionType()
    if self.actionData and self.actionData.special then
        return self.actionData.special
    end
end




