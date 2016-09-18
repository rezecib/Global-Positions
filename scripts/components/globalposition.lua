local ANR_BETA = kleifileexists("scripts/prefabs/globalmapicon") or BRANCH == "staging"

local function AddGlobalIcon(inst, isplayer)
	if not GlobalIconAtlasTranslation[inst.prefab] then return end
	inst.icon = SpawnPrefab("globalmapicon")
	inst.icon.MiniMapEntity:SetPriority(10)
	if isplayer then
		inst.icon:TrackEntity(inst, nil, GlobalIconAtlasTranslation[inst.prefab])
	else --don't want to waste resources constantly updating the position of things that don't move
		inst.icon.MiniMapEntity:SetIcon(GlobalIconAtlasTranslation[inst.prefab])
		inst.icon.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
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

local function onpos(self, pos)
	self.globalpositions:SetPosition(self.inst, pos)
end

local GlobalPosition = Class(function(self, inst)
    self.inst = inst
	self.duration = 0
	self.timeout = false
	local isplayer = inst:HasTag("player")
	if ((isplayer and _GLOBALPOSITIONS_SHOWPLAYERICONS) or (not isplayer and _GLOBALPOSITIONS_SHOWFIREICONS)) then
		if ANR_BETA then
			AddGlobalIcon(inst, isplayer)
		elseif self.inst.MiniMapEntity then
			self.inst.MiniMapEntity:SetDrawOverFogOfWar(true)
		end
	end
	
	if isplayer then
		if ANR_BETA then AddMapRevealer(inst) end
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
		self.globalpositions:AddServerEntity(self.inst)
		self.pos = nil
		self.inst:StartUpdatingComponent(self)			
	end)
end,
nil,
{
	pos = onpos
})

function GlobalPosition:OnUpdate(dt)
	self.pos = self.inst:GetPosition()
	if self.timeout then
		self.duration = self.duration - dt
		if self.duration <= 0 then
			self.inst:RemoveComponent("globalposition")
		end
	end
end

function GlobalPosition:SetDuration(duration)
	self.duration = duration
	self.timeout = true
end

function GlobalPosition:OnRemoveEntity()
	if self.inst.icon then
		self.inst.icon:Remove()
	end
	
	if self.inst.components.maprevealer then
		self.inst.components.maprevealer:Stop()
	end
	
	if self.inst.MiniMapEntity then
		self.inst.MiniMapEntity:SetDrawOverFogOfWar(false)
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
	if ANR_BETA then
		if enabled then
			self.inst.components.maprevealer:Start()
		else
			self.inst.components.maprevealer:Stop()
		end
	else	
		if self.globalpositions then
			self.globalpositions.positions[self.inst.GUID].sharemap:set(enabled)
		end
	end
end

return GlobalPosition