local function AddGlobalIcon(inst, isplayer, classified)
	if not (GlobalIconAtlasTranslation[inst.prefab] or inst.MiniMapEntity) then return end
	classified.icon = SpawnPrefab("globalmapicon_noproxy")
	classified.icon.MiniMapEntity:SetPriority(10)
	classified.icon2 = SpawnPrefab("globalmapicon")
	classified.icon2.MiniMapEntity:SetPriority(10)
	if inst.MiniMapEntity then
		inst.MiniMapEntity:SetEnabled(false)
		classified.icon.MiniMapEntity:CopyIcon(inst.MiniMapEntity)
		classified.icon2.MiniMapEntity:CopyIcon(inst.MiniMapEntity)
	else
		classified.icon.MiniMapEntity:SetIcon(GlobalIconAtlasTranslation[inst.prefab])
		classified.icon2.MiniMapEntity:SetIcon(GlobalIconAtlasTranslation[inst.prefab])
	end
	classified:AddChild(classified.icon)
	classified:AddChild(classified.icon2)
end

local function AddMapRevealer(inst)
	if not inst.components.maprevealer then
		inst:AddComponent("maprevealer")
	end
	inst.components.maprevealer.revealperiod = 0.5
	inst.components.maprevealer:Stop()
	if _GLOBALPOSITIONS_SHAREMINIMAPPROGRESS then
		inst.components.maprevealer:Start()
	end
end

local GlobalPosition = Class(function(self, inst)
    self.inst = inst
	self.classified = nil
	
	local isplayer = inst:HasTag("player")

	if isplayer then
		AddMapRevealer(inst)
		self.respawnedfromghostfn = function()
			self:SetMapSharing(_GLOBALPOSITIONS_SHAREMINIMAPPROGRESS)
			self:PushPortraitDirty()
		end
		self.becameghostfn = function()
			self:SetMapSharing(false)
			self:PushPortraitDirty()
		end
		self.inst:ListenForEvent("ms_respawnedfromghost", self.respawnedfromghostfn)
		self.inst:ListenForEvent("ms_becameghost", self.becameghostfn)
	end
	
	self.inittask = self.inst:DoTaskInTime(0, function()
		self.inittask = nil
		self.globalpositions = TheWorld.net.components.globalpositions
		self.classified = self.globalpositions:AddServerEntity(self.inst)
		if ((isplayer and _GLOBALPOSITIONS_SHOWPLAYERICONS)
		or (not isplayer and _GLOBALPOSITIONS_SHOWFIREICONS)) then
			AddGlobalIcon(inst, isplayer, self.classified)
		end
		self.inst:StartUpdatingComponent(self)			
	end)
end,
nil,
{
})

function GlobalPosition:OnUpdate(dt)
	local pos = self.inst:GetPosition()
	if self._x ~= pos.x or self._z ~= pos.z then
		self._x = pos.x
		self._z = pos.z
		self.classified.Transform:SetPosition(pos:Get())
	end
end

function GlobalPosition:OnRemoveEntity()
	if self.inst.MiniMapEntity then
		self.inst.MiniMapEntity:SetEnabled(true)
	end
	
	if self.inst.components.maprevealer then
		self.inst.components.maprevealer:Stop()
	end
	
	if self.respawnedfromghostfn then
		self.inst:RemoveEventCallback("ms_respawnedfromghost", self.respawnedfromghostfn)
	end
	if self.becameghostfn then
		self.inst:RemoveEventCallback("ms_becameghost", self.becameghostfn)
	end
	
	if self.inittask then self.inittask:Cancel() end
	
	if self.globalpositions then
		self.globalpositions:RemoveServerEntity(self.inst)
	end
end

GlobalPosition.OnRemoveFromEntity = GlobalPosition.OnRemoveEntity

function GlobalPosition:PushPortraitDirty()
	self.inst:DoTaskInTime(1, function()
		if self.globalpositions then
			local pos = self.globalpositions.positions[self.inst.GUID]
			pos.portraitdirty:push()
		end
	end)
end

function GlobalPosition:SetMapSharing(enabled)
	if enabled then
		self.inst.components.maprevealer:Start()
	else
		self.inst.components.maprevealer:Stop()
	end
end

return GlobalPosition