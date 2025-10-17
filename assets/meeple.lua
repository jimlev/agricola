
local spriteShadows = {"gfx/meeples/s_1_meeple.png","gfx/meeples/s_2_meeple.png","gfx/meeples/s_3_meeple.png","gfx/meeples/s_4_meeple.png","gfx/meeples/s_5_meeple.png"}
local pngLists = {
blue = {"gfx/meeples/blue_1_meeple.png","gfx/meeples/blue_2_meeple.png","gfx/meeples/blue_3_meeple.png","gfx/meeples/blue_4_meeple.png","gfx/meeples/blue_5_meeple.png"},
pink = {"gfx/meeples/pink_1_meeple.png","gfx/meeples/pink_2_meeple.png","gfx/meeples/pink_3_meeple.png","gfx/meeples/pink_4_meeple.png","gfx/meeples/pink_5_meeple.png"},
green = {"gfx/meeples/green_1_meeple.png","gfx/meeples/green_2_meeple.png","gfx/meeples/green_3_meeple.png","gfx/meeples/green_4_meeple.png","gfx/meeples/green_5_meeple.png"},
yellow = {"gfx/meeples/yellow_1_meeple.png","gfx/meeples/yellow_2_meeple.png","gfx/meeples/yellow_3_meeple.png","gfx/meeples/yellow_4_meeple.png","gfx/meeples/yellow_5_meeple.png"},
brown = {"gfx/meeples/brown_1_meeple.png","gfx/meeples/brown_2_meeple.png","gfx/meeples/brown_3_meeple.png","gfx/meeples/brown_4_meeple.png","gfx/meeples/brown_5_meeple.png"}
}

farmerMeeple = Core.class(Sprite)

function farmerMeeple:init(player, playerId, color, meepleId)
	self.myName = "Meeple"..playerId.."_"..meepleId

    self.playerId = playerId
	self.owner = player
	self.color = color
    self.isDragging = false
	self.available = true
	self:setPosition(0,0)
    self.homeX, self.homeY = 0, 0  -- Position dans meepleBank

    -- Visuel du meeple
	local shadow = Bitmap.new(Texture.new(spriteShadows[meepleId]))
	shadow:setAnchorPoint(.5, .4)
	self.shadow = shadow
	
	local pngPath = pngLists[self.color]
	
    local sprite = Bitmap.new(Texture.new(pngPath[meepleId]))
	sprite:setAnchorPoint(.5, .45)
	self.sprite = sprite
	
	local meepleToken = MovieClip.new{
		{1, 1, shadow,{alpha = 1, scale = 1, rotation = 0}},
		{1, 1, sprite,{alpha = 1, scale = 1, rotation = 0}},
		{2, 122, shadow,{rotation = {-6, 6, "inOutSine"}}},	
		{122, 240, shadow,{rotation = {6, -6, "inOutSine"}}},
		{2, 122, sprite,{rotation = {-2, 4, "inOutCircular"}}},	
		{122, 240, sprite,{rotation = {4, -2, "inOutCircular"}}},
	}
	
	meepleToken:stop(1)
	meepleToken:setGotoAction(240,2)	

	self:addChild(meepleToken)
	self.meepleToken = meepleToken
	self.meepleToken:setAnchorPoint(.5, .5)
	self.meepleToken:setAnchorPosition(.5, .5)
	self.meepleToken:setPosition(0+self.meepleToken:getWidth()/2,0+self.meepleToken:getHeight()/2)
	
	-- Listeners
    self:addEventListener(Event.MOUSE_DOWN, self.onTouchBegin, self)
    self:addEventListener(Event.MOUSE_MOVE, self.onTouchMove, self)  
    self:addEventListener(Event.MOUSE_UP, self.onTouchEnd, self)	
end

function farmerMeeple:onTouchBegin(event)

    if gameManager.gameIsPaused then return end	

	if self:hitTestPoint(event.x, event.y) then  
        event:stopPropagation()
		
    -- Vérifier si le meeple est disponible
	if not self.available then return end

    -- Demander permission au GameManager
	if not gameManager:canStartDrag(self.owner.myTurnOrder) then return end
    self.isDragging = true
   
    -- Feedback visuel : élever le meeple
	--self:setAnchorPoint(0.5,1)
    self:setScale(1.4)
    self.sprite:setAlpha(0.8)
	self.shadow:setScale(1.9)
	self.shadow:setAlpha(0.1)
	self.meepleToken:gotoAndPlay(2)
	
    -- Passer au premier plan
    self:getParent():addChild(self)  -- Remonte en Z-orderd
	end
end

function farmerMeeple:onTouchMove(event)
    if not self.isDragging then return end
	
    -- Suivre le doigt
    local parent = self:getParent()
    local x, y = parent:globalToLocal(event.x, event.y)

    self:setPosition(x, y)

	local targetedSign = self:checkSignCollision(event.x, event.y)
end

function farmerMeeple:onTouchEnd(event)
    if not self.isDragging then return end

    -- Vérifier collision avec les panneaux d'actions
    local droppedSign = self:checkSignCollision(event.x, event.y)
		   
	-- Reset visuel
	self:setScale(1)
	--self:setAnchorPoint(0.5,0.5)
	self.sprite:setAlpha(1)
	self.shadow:setScale(1)
	self.shadow:setAlpha(1)
	self.meepleToken:stop()
	
    if droppedSign then
       gameManager:initPendingCreation(droppedSign.actionId, self)

		self.mySign = droppedSign
		self.mySign:unhiliteMe()

		self:placeMeepleOnSign(self, self.mySign)

	else
        -- Pas de collision : retour à la maison
        print("No valid drop zone, returning home")
        self:returnHome()
    end

    self.isDragging = false
end

function farmerMeeple:checkSignCollision(globalX, globalY)
    -- Récupérer tous les panneaux d'actions actifs
    local signs = gameManager.signs
	
    for _, sign in ipairs(signs) do
        if sign.hotspot:hitTestPoint(globalX, globalY) then
            -- test si le sign peut accepter un meeple
            if sign:canAcceptWorker(self.playerId) then
                sign:hiliteMe()
                return sign
            else
                sign:unhiliteMe()
            end
        else
            sign:unhiliteMe()
        end
    end
    
    return nil
end

function farmerMeeple:onValidSign()
    local sign = self.mySign
    self.available = false
    self:setScale(1)
	self.shadow:setScale(.9)
	self.shadow:setAlpha(.3)
	self.shadow:setPosition(self.sprite:getX()-5,self.sprite:getY())
	
	sign:addChild(self)
	sign.meepleOnMe = self
	self:setAnchorPoint(0,0)
	self:setAnchorPosition(0,0)
	self:setPosition(self.mySign.meeplePlace:getX(),self.mySign.meeplePlace:getY()) 
	self.meepleToken:setPosition(0,0)

	self:removeAllListeners()
end

function farmerMeeple:returnHome()
    -- Simple retour direct (on peut ajouter une animation plus tard)
    self:setPosition(self.homeX, self.homeY)
	self:setAnchorPoint(0.5,0.5)
    self.available = true
end

function farmerMeeple:placeMeepleOnSign(meeple, sign)
    local hs = sign.meeplePlace
    
    -- Coordonnées globales du centre du hotspot
	local hsW, hsH = hs:getWidth(),hs:getHeight()
    local gx, gy = hs:localToGlobal(hsW/2, hsH/2)

    -- Transformer en coordonnées locales du parent du meeple
	local lx, ly = meeple:getParent():globalToLocal(gx, gy)

    -- Placer le meeple
    --meeple:setPosition(lx, ly-hotspotH/2)
	meeple:setY(ly-hsH)
end