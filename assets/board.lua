gScrolling = false

board = Core.class(Sprite)

function board:init()
	self.myName = "plateau de jeu"
    self.isDragging = false
    self.isFocus = false

	self.startX = 0
    self.currentX = 0
    self.scrollSpeed = 1.0
     
    local refPoint = Bitmap.new(Texture.new("gfx/mire.png"))
		refPoint:setScale(19)
		refPoint:setAnchorPoint(0.5, 0.5)
		self:addChild(refPoint)
		refPoint:setAlpha(0)
		refPoint:setPosition(W/2, H/2)
        
    self.composition = Sprite.new()
		self.composition:setAnchorPoint(0.5, 0.5)
		self:addChild(self.composition)
		self.composition:setPosition(W/2, H/2)	

    self.backLayer = Bitmap.new(Texture.new("gfx/plateau.jpg"))
		self.backLayer:setAnchorPoint(0.5, 0.5)
		self.composition:addChild(self.backLayer)

    self.midLayer = Bitmap.new(Texture.new("gfx/mire.png"))
		self.midLayer:setAnchorPoint(0.5, 0.5)
		self.composition:addChild(self.midLayer)  
		
	local realDisplayHeight = gBottom-gTop
	local scaleFactor = realDisplayHeight / self.backLayer:getHeight()		
	-- je scale la composition pour qu'elle matche 100% en hauteur
	self.composition:setScale(scaleFactor)
		--self.composition:setScale(.6)
	
	local realDisplayWidth = gRight - gLeft	
	local imgScaledWidth = self.backLayer:getWidth() * scaleFactor	
	
	-- Calcul des limites
	if imgScaledWidth > realDisplayWidth then
		self.scrollLimit = (imgScaledWidth - realDisplayWidth) / 2
		self.leftLimit = -self.scrollLimit
		self.rightLimit = self.scrollLimit
	end

	-- Les limites de scroll
	self.minX = self.composition:getX()+ self.leftLimit
	self.maxX = self.composition:getX() + self.rightLimit
   
    self:addEventListener(Event.MOUSE_DOWN, self.onTouchesBegin, self)
    self:addEventListener(Event.MOUSE_MOVE, self.onTouchesMove, self)
    self:addEventListener(Event.MOUSE_UP, self.onTouchesEnd, self)
end

function board:onTouchesBegin(event)
	if gameManager.gameIsPaused then return end	

	if self:hitTestPoint(event.x, event.y) then			
        self.isDragging = true
        self.x0 = event.x
    end
end

function board:onTouchesMove(event)
	if not self.isDragging then return end

	self.isDragging = true
		-- Figure out how far we moved since last time
		local dx = event.x - self.x0
		-- Move the camera
		self.composition:setX(self.composition:getX() + dx)		
		-- print("delta :", dx)
		
		if self.composition:getX()<= self.minX and dx<0  then
			self.composition:setX(self.minX)	
		elseif self.composition:getX()>=self.maxX and dx>0 then
			self.composition:setX(self.maxX)
		else
			--self.composition:setX(newX)		
			self.midLayer:setX((self.midLayer:getX()+ (dx *0.05)))
		end
		self.x0 = event.x 	
		event:stopPropagation()
end

function board:onTouchesEnd(event)
	if not self.isDragging then return end
    self.isDragging = false 
    event:stopPropagation()
end

function board:centerOnSign(sign)
    if not sign or not sign:getParent() then return end

    local windowWidth = gRight - gLeft
    local signX = sign:getX()
    local signWidth = sign:getWidth() or 0
    local signCenter = signX + signWidth / 2
    local windowCenter = gLeft + windowWidth / 2

    -- Cible théorique pour composition
    local targetX = windowCenter - signCenter

 -- Bornage
    if targetX < self.minX then
        targetX = self.minX
    elseif targetX > self.maxX then
        targetX = self.maxX
    end

    -- Décalage total à appliquer (comme si on avait fait un drag)
    local dx = targetX - self.composition:getX()
    local midTargetX = self.midLayer:getX() + dx * 0.05

	local distance = math.abs(dx)
	local minFrames, maxFrames = 60, 320
	local factor = .1   -- ajuste si tu veux un peu plus ou moins rapide
	local frames = math.min(maxFrames, math.max(minFrames, distance * factor))

	local mc = MovieClip.new{
		{1, frames, self.composition, {x = {self.composition:getX(), targetX, "inOutQuadratic"}}},
		{1, frames, self.midLayer,  {x = {self.midLayer:getX(), midTargetX,  "inOutQuartic"}}}
	}
	mc:play() -- play only once
	
end



