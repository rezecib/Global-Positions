local Image = require "widgets/image"

local pingcolours = {
	ping_generic = DEFAULT_PLAYER_COLOUR,
	ping_gohere = PLAYERCOLOURS.YELLOW,
	ping_danger = PLAYERCOLOURS.RED,
	ping_explore = PLAYERCOLOURS.GREEN,
	ping_omw = PLAYERCOLOURS.BLUE,
}

local GlobalPositions = Class(function(self, inst)
	self.inst = inst
	self.positions = {}
end)

function GlobalPositions:UpdatePortrait(inst)
	if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.targetindicators then
		for k,v in pairs(ThePlayer.HUD.targetindicators) do
			if v.target == inst then
				v.head:Kill()
				v.head = v.icon:AddChild(Image( v:GetAvatarAtlas(), v:GetAvatar(), "avatar_unknown.tex"))
				v.headbg:Kill()
				v.headbg = v.icon:AddChild(Image( "images/avatars.xml",
					v:IsGhost() and "avatar_ghost_bg.tex" or "avatar_bg.tex"))
				v.headbg:MoveToBack()
			end
		end
	end
end

function shouldShowIndicator(gpc)
	local show = gpc.userid:value() ~= "nil" and _GLOBALPOSITIONS_SHOWPLAYERINDICATORS
	show = show or (gpc.userid:value() == "nil" and _GLOBALPOSITIONS_TARGET_INDICATOR_ICONS[gpc.parentprefab:value()])
	return show
end

function GlobalPositions:AddServerEntity(inst)
	local classified = SpawnPrefab("globalposition_classified")
	self.positions[inst.GUID] = classified
	classified.parentprefab:set(inst.prefab or "")
	classified.parententity:set(inst)
	local pingcolour = pingcolours[inst.prefab]
	classified.userid:set(inst.userid or "nil")
	if pingcolour then
		classified.parentuserid:set(inst.parentuserid or "nil")
	end
	
	local player = nil
	for k,v in pairs(TheNet:GetClientTable()) do
		if v.userid == classified.userid:value() or v.userid == classified.parentuserid:value() then
			player = v
		end
	end
	
	classified.playercolour = pingcolour or (player and player.colour or classified.playercolour)
	classified.name = (pingcolour and player)
		and (inst.name .. "\n(" .. player.name ..")")
		or (player and player.name or inst.name)
	if pingcolour and player then
		classified.parentname:set(player.name)
	end
	
	if shouldShowIndicator(classified) then
		classified.portraitdirty:push()
		if ThePlayer and ThePlayer.userid ~= inst.userid and ThePlayer.HUD then
			ThePlayer.HUD:AddTargetIndicator(classified)
			ThePlayer.HUD.targetindicators[#ThePlayer.HUD.targetindicators]:Hide()
			self:UpdatePortrait(classified)
		end
	end
	
	return classified
end

function GlobalPositions:RemoveServerEntity(inst)
	if shouldShowIndicator(self.positions[inst.GUID])
	and ThePlayer and ThePlayer.userid ~= inst.userid and ThePlayer.HUD then
		ThePlayer.HUD:RemoveTargetIndicator(self.positions[inst.GUID])
	end
	self.positions[inst.GUID]:Remove()
	self.positions[inst.GUID] = nil
end

function GlobalPositions:AddClientEntity(inst)
	self.positions[inst.GUID] = inst
	local pingcolour = pingcolours[inst.parentprefab:value()]
	local player = nil
	for k,v in pairs(TheNet:GetClientTable()) do
		if v.userid == inst.userid:value() then
			player = v
		end
	end
	local prefabname = inst.parentprefab:value()
	inst.playercolour = pingcolour or (player and player.colour or inst.playercolour)
	inst.name = (not pingcolour and player) and player.name
		or STRINGS.NAMES[prefabname:upper()] or inst.parentprefab:value()
	if pingcolour then
		inst.name = inst.name .. "\n(" .. inst.parentname:value() ..")"
	end
	local show = shouldShowIndicator(inst)
	if show and ThePlayer and ThePlayer.userid ~= inst.userid:value() and ThePlayer.HUD then
		ThePlayer.HUD:AddTargetIndicator(inst)
		ThePlayer.HUD.targetindicators[#ThePlayer.HUD.targetindicators]:Hide()
		self:UpdatePortrait(inst)
	end
	inst.OnRemoveEntity = function()
		if ThePlayer and ThePlayer.HUD then
			ThePlayer.HUD:RemoveTargetIndicator(inst)
		end
		self.positions[inst.GUID] = nil
	end
end

return GlobalPositions