local SmokeEmitter = Class(function(self, inst)
	self.inst = inst
    self.smoketrail = nil
	self.time_since_last_puff = 0
	self.duration = 0
end)

function SmokeEmitter:LongUpdate(dt)
	self:OnUpdate(dt)
end

function SmokeEmitter:OnUpdate(dt)
	--#rezecib duration is only handled on the server; the client only sees self.enabled
	if TheWorld.ismastersim and self.duration then
		self.duration = self.duration - dt
		if self.duration <= 0 then
			self:Disable()
			return
		end
	end
end

function SmokeEmitter:Enable(duration)
	self.duration = duration
	if not self.smoketrail then
		self.inst:AddComponent("globalposition")
		self.smoketrail = SpawnPrefab( "smoketrail" )
		self.inst:AddChild(self.smoketrail)
		if self.inst.smoke_emitter_offset then
			self.smoketrail.entity:SetParent(self.inst.entity)
			self.smoketrail.entity:AddFollower()
			self.smoketrail.Follower:FollowSymbol(self.inst.GUID, "symbol0",
				self.inst.smoke_emitter_offset.x, self.inst.smoke_emitter_offset.y, 0)
		else
			self.smoketrail.Transform:SetPosition(0, 1, 0)
		end
		if duration then
			self.inst:StartUpdatingComponent(self)
		end
	end
end

function SmokeEmitter:Disable()
	if self.smoketrail then
		self.inst:RemoveComponent("globalposition")
		self.smoketrail:CancelAllPendingTasks()
		self.smoketrail:DoTaskInTime(5, function(inst)
			self.inst:RemoveChild(inst)
			inst:Remove()
		end)
		self.smoketrail = nil
		self.inst:StopUpdatingComponent(self)
	end
end

function SmokeEmitter:OnSave()
	return {duration = self.duration}
end

function SmokeEmitter:OnLoad(data)
	if data.duration and data.duration > 0 then
		-- self.inst:AddComponent("globalposition")
		-- self.inst.components.globalposition:SetDuration(data.duration)
		self.inst.components.smokeemitter:Enable(data.duration)
	end
end

return SmokeEmitter