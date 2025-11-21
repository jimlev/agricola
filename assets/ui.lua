
local basefont = TTFont.new("fonts/GentiumPlus-Bold.ttf",30)
local titlefont = TTFont.new("fonts/K2D-Bold.ttf",72)
local regularFont = TTFont.new("fonts/K2D-Regular.ttf",48)

UI = Core.class(Sprite)

UI.infoQueue = {}
UI.isDisplayingInfo = false
UI.currentInfoTimer = nil

function UI:init()
	self.name = "UI object"
    -- conteneur pour les popups
    -- self.popupLayer = Sprite.new()
    -- self:addChild(self.popupLayer)
end

function UI:showConfirmPopup(buttons)
	
    -- assombrir le plateau
    stage.gameBoard:setColorTransform(0.6,0.6,0.6)

    -- créer le layer popup
	if not self.popupLayer then
        self.popupLayer = Sprite.new()
        self:addChild(self.popupLayer)
    end

    -- Bouton VALIDER
	if table.find(buttons, "valid") then
		local validBtn = btn.new("valid")
		validBtn:setPosition(gRight-80, gBottom/2)
		self.popupLayer:addChild(validBtn)
		self.popupLayer.validBtn = validBtn
	end
	
    -- Bouton CONTINUE
	if table.find(buttons, "continue") then
		local continueBtn = btn.new("continue")
		continueBtn:setPosition(gLeft + 260, gBottom/2)
		self.popupLayer:addChild(continueBtn)
		self.popupLayer.continueBtn = continueBtn
	end
	
	-- Bouton ROLLBACK
	if table.find(buttons, "rollback") then
		local rollbackBtn = btn.new("rollback")
		rollbackBtn:setPosition(gLeft + 80, gBottom/2)
		self.popupLayer:addChild(rollbackBtn)
	end
end

function UI:createChoicePopup(action1, fct1, action2, fct2)
	local popup = Sprite.new()
	self.popupLayer:addChild(popup)

	local choicePopUp = Bitmap.new(Texture.new("gfx/pancarte.png"))
		choicePopUp:setAnchorPoint(0.5,0.5)
		choicePopUp:setPosition(gRight/2, H/2)
		popup:addChild(choicePopUp)
		popup.choicePopUp = choicePopUp

	local hs1 = Bitmap.new(Texture.new("gfx/UI/hotspot_640132.png"))
		hs1:setAnchorPoint(0.5,0.5)
		choicePopUp:addChild(hs1)
		hs1:setPosition(0, -142)
		choicePopUp.hs1 = hs1
		hs1.event = fct1
		hs1:addEventListener(Event.MOUSE_UP, self.onMouseUp, hs1)
		
	local title1 = TextField.new(regularFont, action1.title)
		title1:setAnchorPoint(0.5,0.5)
		title1:setTextColor(0x4b2c31)
		--title1:setPosition(-104,-18)	
		hs1:addChild(title1)
		choicePopUp.title1 = title1
		
	local hs2 = Bitmap.new(Texture.new("gfx/UI/hotspot_640132.png"))
		hs2:setAnchorPoint(0.5,0.5)
		choicePopUp:addChild(hs2)
		hs2:setPosition(0, 88)
		choicePopUp.hs2 = hs2	
		hs2.event = fct2
		hs2:addEventListener(Event.MOUSE_UP, self.onMouseUp, hs2)
		
	local title2 = TextField.new(regularFont, action2.title)
		title2:setAnchorPoint(.5,.5)
		title2:setTextColor(0x4b2c31)
		--title2:setPosition(-104,-18)	
		hs2:addChild(title2)
		choicePopUp.title2 = title2	
	
	return popup
end

function UI:onMouseUp(event)
	if self:hitTestPoint(event.x, event.y) and self:isVisible(true) then
		event:stopPropagation()
		self.event()
		
		gameManager.actionPopup:setVisible(false)	
	end
end

function UI:killConfirmPopup()
	self.popupLayer:removeFromParent()
	self.popupLayer = nil
	stage.gameBoard:setColorTransform(1,1,1)
	collectgarbage()
end

function UI:killValidButton()
    if self.popupLayer and self.popupLayer.validBtn then
        self.popupLayer:removeChild(self.popupLayer.validBtn)
        self.popupLayer.validBtn = nil
        --print("Bouton valid détruit")
    else
        print("Impossible de détruire validBtn - non trouvé")
    end
end


-- #######################################################################################
-- ##########################        DISPLAY MODULES        ##############################
function UI:displayInfo(t1, t2)	
	
    local popupName = "infoPopup"..math.random(999)
    self[popupName] = Sprite.new()
    self:addChild(self[popupName])
    
    local popup = self[popupName]
    
    popup.touchListener = function(event)
        if self.isDisplayingInfo and popup:getParent() then
--            print("⚡ SKIP vers popup suivante")
            self:hideInfoPanel(popup)
            event:stopPropagation()
        end
    end
    popup:addEventListener(Event.MOUSE_DOWN, popup.touchListener)
    
    local infoPanel = Bitmap.new(Texture.new("gfx/UI/turnPanel.png"))
    popup:addChild(infoPanel)
    infoPanel:setPosition(W/2, H/1.6)
    infoPanel:setAnchorPoint(0.5, 1)
    
    local title = TextField.new(titlefont, t1)
    title:setAnchorPoint(0.5,0.5)
    title:setTextColor(0xffffff)
    title:setPosition(0,-180)
    infoPanel:addChild(title)
    
    local msg = TextField.new(regularFont, t2)
    msg:setAnchorPoint(0.5,0.5)
    msg:setTextColor(0xffffff)
    msg:setPosition(0,-80)
    infoPanel:addChild(msg)	
    
    return popup
end

function UI:processQueue()
    if self.isDisplayingInfo or #self.infoQueue == 0 then
        return
    end

    stage.gameBoard:setColorTransform(0.6, 0.6, 0.6)
	gameManager.gameIsPaused = true -- je bloque le gameplay
    self.isDisplayingInfo = true
	
	local nextMsg = table.remove(self.infoQueue, 1)
	self.currentInfo = nextMsg
	
	local popup = self:displayInfo(nextMsg.title, nextMsg.text)

    -- Lancer le timer de fermeture automatique
    self.currentInfoTimer = Timer.delayedCall(nextMsg.duration * 1000, function()
        self:hideInfoPanel(popup)
    end)
end

function UI:hideInfoPanel(popup)
    if self.currentInfoTimer then
        self.currentInfoTimer:stop()
        self.currentInfoTimer = nil
    end
    self:killThatPopup(popup) -- on kill la popup
	
	-- ✅ Appeler le callback du message courant, si présent
    if self.currentInfo and self.currentInfo.callback then
        pcall(self.currentInfo.callback)  -- pcall = protection contre erreurs
    end
    self.currentInfo = nil
	
    self.isDisplayingInfo = false
	gameManager.gameIsPaused = false -- je débloque le gameplay
	stage.gameBoard:setColorTransform(1,1,1)
    self:processQueue() -- on interroge le processeur pour voir si d'autres msg attendent
end

function UI:killThatPopup(target)   
    if target.touchListener then
        target:removeEventListener(Event.MOUSE_DOWN, target.touchListener)
        target.touchListener = nil
    end
    
    target:removeFromParent()
    target = nil
    
    stage.gameBoard:setColorTransform(1,1,1)
    collectgarbage()
end 


-- *=**=**=**=**=**=**=**=**=**=**=*
-- *=**=**=*  SIDE FCT  *=**=**=**=*

function UI:queueInfo(title, text, duration, callback)
	table.insert(self.infoQueue, {
        title = title,
        text = text,
        duration = duration or 3,
        callback = callback -- optionnel
    })
    self:processQueue()
end

function UI:validFenceTransaction(player)

    local validFenceBtn = Bitmap.new(Texture.new("gfx/positron.png"))
    validFenceBtn:setAnchorPoint(1, 0.5)
    validFenceBtn:setPosition(gRight - 80, gBottom / 2)
    self:addChild(validFenceBtn)
    self.validFenceBtn = validFenceBtn

    local numberFont = TTFont.new("fonts/K2D-Bold.ttf", 48)
    local count = TextField.new(numberFont, wood)
    count:setAnchorPoint(0, 0.5)
    count:setTextColor(0xc70404)
    count:setPosition(-360, 20)
    validFenceBtn:addChild(count)
    validFenceBtn.count = count

    -- on stocke ici le listener pour pouvoir le retirer plus tard
    validFenceBtn.onClick = function(event)
        if validFenceBtn:hitTestPoint(event.x, event.y) then
            event:stopPropagation()
            local parent = validFenceBtn:getParent()
            parent:removeChild(validFenceBtn)
            parent.validFenceBtn = nil

            gameManager:executeAction()
        end
    end

    function validFenceBtn:updateButtonState(wood)
        local woodNeeded = wood
        local woodAvailable = player.resources.wood or 0

        self:setTexture(Texture.new("gfx/UI/fenceWoodBtn.png"))
        self.count:setText(woodNeeded)

        if woodAvailable >= 0 then
            self.count:setTextColor(0x533831)
			self:setAlpha(1)
            -- Ajouter le listener
            self:addEventListener(Event.MOUSE_DOWN, self.onClick)

        else
            self.count:setTextColor(0xe70000)
			self:setAlpha(.7)
            -- 🔥 Retirer correctement
            self:removeEventListener(Event.MOUSE_DOWN, self.onClick)
        end
    end

    validFenceBtn:updateButtonState(0)
end


function UI:validAnimalRepartition(player)

    local validAnimalPlaceBtn = Bitmap.new(Texture.new("gfx/positron.png"))
    validAnimalPlaceBtn:setAnchorPoint(1, 0.5)
    validAnimalPlaceBtn:setPosition(gRight - 80, gBottom / 2)
    self:addChild(validAnimalPlaceBtn)
    self.validAnimalPlaceBtn = validAnimalPlaceBtn

    local numberFont = TTFont.new("fonts/K2D-Bold.ttf", 48)
    local sheepcount = TextField.new(numberFont, 0)
		sheepcount:setAnchorPoint(0, 0.5)
		sheepcount:setTextColor(0xc70404)
		sheepcount:setPosition(-440, 80)
		validAnimalPlaceBtn:addChild(sheepcount)
		validAnimalPlaceBtn.sheepcount = sheepcount
	
	local pigcount = TextField.new(numberFont, 0)
		pigcount:setAnchorPoint(0, 0.5)
		pigcount:setTextColor(0xc70404)
		pigcount:setPosition(-330, 80)
		validAnimalPlaceBtn:addChild(pigcount)
		validAnimalPlaceBtn.pigcount = pigcount
	
	local cattlecount = TextField.new(numberFont, 0)
		cattlecount:setAnchorPoint(0, 0.5)
		cattlecount:setTextColor(0xc70404)
		cattlecount:setPosition(-220, 80)
		validAnimalPlaceBtn:addChild(cattlecount)
		validAnimalPlaceBtn.cattlecount = cattlecount

    -- on stocke ici le listener pour pouvoir le retirer plus tard
    validAnimalPlaceBtn.onClick = function(event)
        if validAnimalPlaceBtn:hitTestPoint(event.x, event.y) then
            event:stopPropagation()
            local parent = validAnimalPlaceBtn:getParent()
            parent:removeChild(validAnimalPlaceBtn)
            parent.validAnimalPlaceBtn = nil
			
            gameManager:executeAction()
        end
    end

    function validAnimalPlaceBtn:updateButtonState()
        local s, p, c = player.resources.sheep, player.resources.pig, player.resources.cattle

        self:setTexture(Texture.new("gfx/UI/animalsBtn.png"))
        self.sheepcount:setText(s)
		self.pigcount:setText(p)
		self.cattlecount:setText(c)
		
        if s >= 0 then
            self.sheepcount:setTextColor(0x533831)
        elseif s<0 then 
            self.sheepcount:setTextColor(0xe70000)
        end
		if p >= 0 then
            self.pigcount:setTextColor(0x533831)
        elseif p <0 then 
            self.pigcount:setTextColor(0xe70000)
        end
		if c >= 0 then
            self.cattlecount:setTextColor(0x533831)
        elseif c <0 then 
            self.cattlecount:setTextColor(0xe70000)
        end
	
		self:addEventListener(Event.MOUSE_DOWN, self.onClick)
    end

    validAnimalPlaceBtn:updateButtonState()
end

-- ======================= out of class
function createOverlay()
	local overlay = Shape.new()
		overlay:setFillStyle(Shape.SOLID, 0x000000, .8)
		overlay:beginPath()
		overlay:moveTo(gLeft, gTop)
		overlay:lineTo(gRight, gTop)
		overlay:lineTo(gRight, gBottom)
		overlay:lineTo(gLeft, gBottom)
		overlay:closePath()
		overlay:endPath()

	return overlay
end
