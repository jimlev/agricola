--set logical dimensions (always like these, no matter if portrait or lanscape)
application:setLogicalDimensions(1080, 1920)
--set orientation
application:setOrientation(Application.LANDSCAPE_LEFT)
--set scaling mode
application:setScaleMode("letterbox")
-- bg color
application:setBackgroundColor(0x000000)
--get dimensions
W = application:getContentWidth() -- 1920
H = application:getContentHeight()  -- 1080

local dx = application:getLogicalTranslateX() / application:getLogicalScaleX()
local dy = application:getLogicalTranslateY() / application:getLogicalScaleY()

print("") print("")
print("=====================================================================")
print("=====================================================================")
gLeft = -dx
gTop = -dy
gRight = dx + W
gBottom = dy + H

local lox,loy=application:getLogicalTranslateX(),application:getLogicalTranslateY()
local lsx,lsy=application:getLogicalScaleX(),application:getLogicalScaleY()
local cw,ch=application:getContentWidth(),application:getContentHeight()
local scx,scy,scw,sch=-lox/lsx,-loy/lsy,cw+lox/lsx,ch+loy/lsy

-- p30 >>>  1080 x 2340 pixels
-- tab S9 >>>  2560 x 1600 pixels

print(gTop -gBottom, sch, application:getContentHeight(),application:getDeviceHeight(),application:getLogicalHeight())
print("gTop, gRight, gBottom, gLeft: ", gTop, gRight, gBottom, gLeft)



regularFont = TTFont.new("fonts/GentiumPlus-Bold.ttf",12)
screenDisplay = TextField.new(regularFont, "ABCDEFGHIJKLMNOPQRSTUVWXYZ àéô 0123456789")

c1 = Bitmap.new(Texture.new("gfx/positron.png"))
stage:addChild(c1)
c1:setAnchorPoint(0, 0)
c1:setPosition(gLeft, gTop)

c2 = Bitmap.new(Texture.new("gfx/positron.png"))
stage:addChild(c2)
c2:setAnchorPoint(1,0)
c2:setPosition(gRight, gTop)

c3 = Bitmap.new(Texture.new("gfx/positron.png"))
stage:addChild(c3)
c3:setAnchorPoint(1, 1)
c3:setPosition(gRight, gBottom)

c4 = Bitmap.new(Texture.new("gfx/positron.png"))
stage:addChild(c4)
c4:setAnchorPoint(0,1)
c4:setPosition(gLeft, gBottom)

c5 = Bitmap.new(Texture.new("gfx/positron.png"))
stage:addChild(c5)
c5:setAnchorPoint(0.5,0.5)
c5:setPosition(W/2, (gBottom - gTop)/2)

-- ==============================================================================================
-- ==============================================================================================
-- ==============================================================================================
-- ==============================================================================================
-- ==============================================================================================

