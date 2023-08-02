local function GetMapExplorer(target)
    --Only supports players
    return target ~= nil and target.player_classified ~= nil and target.player_classified.MapExplorer or nil
end

local WorldMapSyncer = Class(function(self, inst)
    self.inst = inst
	self.last_sync_time = -1
	self.saved_map = SpawnPrefab("savedworldmap")
	self.map_version = -1
	self.player_map_versions = {}
	
	self.inst:ListenForEvent("ms_playerspawn", function(world, player) self:OnPlayerSpawn(player) end)
	self.inst:ListenForEvent("ms_playerleft", function(world, player) self:OnPlayerLeft(player) end)
end,
nil,
{
})

function WorldMapSyncer:OnSave()
	return {
		saved_map = self.saved_map:GetSaveRecord(),
		map_version = self.map_version,
		player_map_versions = self.player_map_versions,
	}
end

function WorldMapSyncer:OnLoad(data)
	if data ~= nil then
		if data.saved_map then
			self.saved_map = SpawnSaveRecord(data.saved_map)
		end
		self.map_version = data.map_version
		self.player_map_verison = data.player_map_versions
	end
end

function WorldMapSyncer:OnPlayerSpawn(player)
	self:TrySaveBestPlayerMap(player)
	self.saved_map:TeachMap(player)
	self.player_map_versions[player.userid] = self.map_version
end

function WorldMapSyncer:OnPlayerLeft(player)
	self.saved_map:TeachMap(player)
	local player_map_version = self.player_map_versions[player.userid] or -1
	self.saved_map:RecordMap(player)
	self.map_version = math.max(self.map_version, player_map_version) + 1	
end

function WorldMapSyncer:TrySaveBestPlayerMap(player)
	local cur_time = os.clock()
	if cur_time - self.last_sync_time < 1 then
		return
	else
		self.last_sync_time = cur_time
	end
	local max_map_version = -1
	local max_map_player = nil
	for _, other in pairs(AllPlayers) do
		local player_map_version = self.player_map_versions[other.userid] or -1
		if player ~= other and player_map_version > max_map_version then
			max_map_version = player_map_version
			max_map_player = other
		end
	end
	if max_map_player ~= nil then
		self:OnPlayerLeft(max_map_player)
	end
end

return WorldMapSyncer