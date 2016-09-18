local Image = require "widgets/image"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"

local ATLAS = "images/avatars.xml"

local SMALLSCALE = 0.8
local LARGESCALE = 1.0
local BROWN = {80/255, 60/255, 30/255, 1}

local PingBadge = Class(Widget, function(self, image, text)
    Widget._ctor(self, "PingBadge")
    self.isFE = false
    self:SetClickable(false)

    self.root = self:AddChild(Widget("root"))

    self.icon = self.root:AddChild(Widget("target"))
    self.icon:SetScale(SMALLSCALE)
	self.expanded = false

	self.headbg = self.icon:AddChild(Image(ATLAS, "avatar_bg.tex"))
	self.head = self.icon:AddChild(Image("images/Ping"..image..".xml", "Ping"..image..".tex"))

	self.headframe = self.icon:AddChild(Image(ATLAS, "avatar_frame_white.tex"))
	self.headframe:SetTint(unpack(BROWN))
	
	self.bg = self.icon:AddChild(Image("images/status_bg.xml", "status_bg.tex"))
	self.bg:SetScale(.11*(text:len()),.5,0)
	self.bg:SetPosition(-.5,-34,0)
	self.bg:SetTint(unpack(DEFAULT_PLAYER_COLOUR))

	self.text = self.icon:AddChild(Text(NUMBERFONT, 28))
	self.text:SetHAlign(ANCHOR_MIDDLE)
	self.text:SetPosition(3.5, -50, 0)
	self.text:SetScale(1,.78,1)
	self.text:SetString(text)
end)

function PingBadge:Expand()
	if self.expanded then return end
	self.expanded = true
	self.icon:ScaleTo(SMALLSCALE, LARGESCALE, .25)
    if self.headframe then self.headframe:SetTint(unpack(PLAYERCOLOURS.GREEN)) end
	if self.text then self.bg:SetTint(unpack(PLAYERCOLOURS.GREEN)) end
	self:MoveToFront()
end

function PingBadge:Contract()
	if not self.expanded then return end
	self.expanded = false
	self.icon:ScaleTo(LARGESCALE, SMALLSCALE, .25)
    if self.headframe then self.headframe:SetTint(unpack(BROWN)) end
    if self.text then self.bg:SetTint(unpack(DEFAULT_PLAYER_COLOUR)) end
	self:MoveToBack()
end

return PingBadge