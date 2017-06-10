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
	if not TheWorld.ismastersim
	or not _GLOBALPOSITIONS_SHAREMINIMAPPROGRESS
	or not TheNet:IsDedicated() then return end
	-- Players will wait to get their map from here until this says it's loaded
	self.map_loaded = false
end)

function GlobalPositions:OnSave()
	if not TheNet:IsDedicated() then return end
	local data = {}
	if TheWorld.worldmapexplorer.MapExplorer then
		data.worldmap = TheWorld.worldmapexplorer.MapExplorer:RecordMap()
	elseif self.cached_worldmap then
		-- They had map sharing enabled before but disabled it,
		-- cache the map and pass it along in case they reenable it later
		data.worldmap = self.cached_worldmap
	end
	return data
end

function GlobalPositions:OnLoad(data)
	-- TheWorld can't have its own map on non-dedicated servers
	if TheNet:IsDedicated() and data and data.worldmap then
		if TheWorld.worldmapexplorer.MapExplorer then
			-- This seems to depend on some networking before it can succeed
			-- However, it always in my testing succeeds before it tries to load the player map
			-- So that's good enough, I suppose?
			local function TryLoadingWorldMap()
				-- if TheNet:IsDedicated() then
				if TheWorld.worldmapexplorer.MapExplorer:LearnRecordedMap(data.worldmap) then
					-- print("Succeeded at loading the world map.")
					self.map_loaded = true
				else
					-- print("Failed to load world map, trying again...")
					self.inst:DoTaskInTime(0, TryLoadingWorldMap)
				end
				-- end
			end
			TryLoadingWorldMap()
		else
			-- Pass it along in case they reenable map sharing later
			self.cached_worldmap = data.worldmap
		end
	end
end

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