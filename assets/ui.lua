

local basefont = TTFont.new("fonts/GentiumPlus-Bold.ttf",48)
local titlefont = TTFont.new("fonts/K2D-Bold.ttf",88)
local regularFont = TTFont.new("fonts/K2D-Regular.ttf",54)

UI = Core.class(Sprite)


function UI:init()
	self.name = "UI object"
    -- conteneur pour les popups
   -- self.popupLayer = Sprite.new()
    --self:addChild(self.popupLayer)
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
		
	local title1 = TextField.new(basefont, action1.title)
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
		
	local title2 = TextField.new(basefont, action2.title)
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
    print("destroyValidButton appelé")
    print("self.popupLayer existe?", self.popupLayer ~= nil)
    if self.popupLayer then
        print("self.popupLayer.validBtn existe?", self.popupLayer.validBtn ~= nil)
        print("Type de validBtn:", type(self.popupLayer.validBtn))
    end
    
    if self.popupLayer and self.popupLayer.validBtn then
        self.popupLayer:removeChild(self.popupLayer.validBtn)
        self.popupLayer.validBtn = nil
        print("Bouton valid détruit")
    else
        print("Impossible de détruire validBtn - non trouvé")
    end
end




function UI:showTurnPanel(t1, t2, tempo)
    displayTime = tempo or 3  -- 3 secondes par défaut
	gameManager.gameIsPaused = true
    -- assombrir le plateau
    stage.gameBoard:setColorTransform(0.6,0.6,0.6)

	stage.gameBoard:centerOnSign(gameManager.signs[#gameManager.signs])	
	
    -- créer le layer popup
	if not self.popupLayer then
        self.popupLayer = Sprite.new()
        self:addChild(self.popupLayer)
    end
	
	local turnPanel = Bitmap.new(Texture.new("gfx/UI/turnPanel.png"))
		self.popupLayer:addChild(turnPanel)
		turnPanel:setPosition(W/2, H/1.6)
		turnPanel:setAnchorPoint(0.5, 1)

	local turnTitle = TextField.new(titlefont, t1)
		turnTitle:setAnchorPoint(0.5,0.5)
		turnTitle:setTextColor(0xffffff)
		turnTitle:setPosition(0,-130)
		turnPanel:addChild(turnTitle)
		
	local turnBase = TextField.new(regularFont, t2)
		turnBase:setAnchorPoint(0.5,0.5)
		turnBase:setTextColor(0xffffff)
		turnBase:setPosition(0,-80)
		turnPanel:addChild(turnBase)	
		
    -- Fermeture automatique après X secondes
    Timer.delayedCall(displayTime * 1000, function()
        self:killConfirmPopup()  -- Utilise votre fonction existante
        gameManager.gameIsPaused = false  -- Réactiver le jeu
    end)	
end


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
