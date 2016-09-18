PrefabFiles = {
	"globalposition_classified",
	"smoketrail",
	"globalplayericon",
	"pings",
}

Assets = {
	Asset( "IMAGE", "minimap/campfire.tex" ),
	Asset( "ATLAS", "minimap/campfire.xml" ),
    Asset( "IMAGE", "minimap/ping_generic.tex" ),
    Asset( "ATLAS", "minimap/ping_generic.xml" ),
    Asset( "IMAGE", "minimap/ping_danger.tex" ),
    Asset( "ATLAS", "minimap/ping_danger.xml" ),
    Asset( "IMAGE", "minimap/ping_explore.tex" ),
    Asset( "ATLAS", "minimap/ping_explore.xml" ),
    Asset( "IMAGE", "minimap/ping_gohere.tex" ),
    Asset( "ATLAS", "minimap/ping_gohere.xml" ),
    Asset( "IMAGE", "minimap/ping_omw.tex" ),
    Asset( "ATLAS", "minimap/ping_omw.xml" ),
	
	Asset( "IMAGE", "images/status_bg.tex" ),
	Asset( "ATLAS", "images/status_bg.xml" ),
    Asset( "IMAGE", "images/sharelocation.tex" ),
    Asset( "ATLAS", "images/sharelocation.xml" ),
    Asset( "IMAGE", "images/unsharelocation.tex" ),
    Asset( "ATLAS", "images/unsharelocation.xml" ),
    Asset( "IMAGE", "images/Ping.tex" ),
    Asset( "ATLAS", "images/Ping.xml" ),
    Asset( "IMAGE", "images/PingDanger.tex" ),
    Asset( "ATLAS", "images/PingDanger.xml" ),
    Asset( "IMAGE", "images/PingExplore.tex" ),
    Asset( "ATLAS", "images/PingExplore.xml" ),
    Asset( "IMAGE", "images/PingGoHere.tex" ),
    Asset( "ATLAS", "images/PingGoHere.xml" ),
    Asset( "IMAGE", "images/PingOmw.tex" ),
    Asset( "ATLAS", "images/PingOmw.xml" ),
    Asset( "IMAGE", "images/PingCancel.tex" ),
    Asset( "ATLAS", "images/PingCancel.xml" ),
    Asset( "IMAGE", "images/PingDelete.tex" ),
    Asset( "ATLAS", "images/PingDelete.xml" ),
    Asset( "IMAGE", "images/PingClear.tex" ),
    Asset( "ATLAS", "images/PingClear.xml" ),
}

AddMinimapAtlas("minimap/campfire.xml")
AddMinimapAtlas("minimap/ping_generic.xml")
AddMinimapAtlas("minimap/ping_gohere.xml")
AddMinimapAtlas("minimap/ping_explore.xml")
AddMinimapAtlas("minimap/ping_danger.xml")
AddMinimapAtlas("minimap/ping_omw.xml")

local require = GLOBAL.require

local ANR_BETA = GLOBAL.kleifileexists("scripts/prefabs/globalmapicon") or GLOBAL.BRANCH == "staging"

local OVERRIDEMODE = GetModConfigData("OVERRIDEMODE")
local SHOWPLAYERICONS = GetModConfigData("SHOWPLAYERICONS")
local SERVERSHOWPLAYERSOPTIONS = GetModConfigData("SHOWPLAYERSOPTIONS", false)
local CLIENTSHOWPLAYERSOPTIONS = GetModConfigData("SHOWPLAYERSOPTIONS", true)
local SHOWPLAYERINDICATORS = SERVERSHOWPLAYERSOPTIONS > 1
local SHOWPLAYERSALWAYS = SHOWPLAYERINDICATORS and CLIENTSHOWPLAYERSOPTIONS == 3
local NETWORKPLAYERPOSITIONS = SHOWPLAYERICONS or SHOWPLAYERINDICATORS
local SHAREMINIMAPPROGRESS = NETWORKPLAYERPOSITIONS and GetModConfigData("SHAREMINIMAPPROGRESS")
local FIREOPTIONS = GetModConfigData("FIREOPTIONS")
local SHOWFIRES = FIREOPTIONS < 3
local NEEDCHARCOAL = FIREOPTIONS == 2
local SHOWFIREICONS = GetModConfigData("SHOWFIREICONS")

local mode = GLOBAL.TheNet:GetServerGameMode()
if mode == "wilderness" and not OVERRIDEMODE then --by default, have different settings for wilderness
	SHOWPLAYERINDICATORS = false
	SHOWPLAYERICONS = false
	SHOWFIRES = true
	SHOWFIREICONS = false
	NEEDCHARCOAL = false
	SHAREMINIMAPPROGRESS = false
end

--#rezecib this makes this available outside of the modmain
-- (it will be checked in globalposition_classified)
GLOBAL._GLOBALPOSITIONS_SHAREMINIMAPPROGRESS = SHAREMINIMAPPROGRESS
GLOBAL._GLOBALPOSITIONS_SHOWPLAYERICONS = SHOWPLAYERICONS
GLOBAL._GLOBALPOSITIONS_SHOWFIREICONS = SHOWFIREICONS
GLOBAL._GLOBALPOSITIONS_SHOWPLAYERINDICATORS = SHOWPLAYERINDICATORS
GLOBAL._GLOBALPOSITIONS_SHOWFIREINDICATORS = SHOWFIRES

--#rezecib this is needed to make sure the normal ones disappear when you get far enough
-- (don't want to be clogging the screen with arrows, so only show the global ones
--  on the scoreboard screen)
local oldmaxrange = GLOBAL.TUNING.MAX_INDICATOR_RANGE
local oldmaxrangesq = (oldmaxrange*1.5)*(oldmaxrange*1.5)

--#rezecib this actually only affects the scaling/transparency of the badges
-- so I set it fairly low so you can see approximately how far they are from you
-- when in reasonable ranges
GLOBAL.TUNING.MAX_INDICATOR_RANGE = 2000

-- for post-caves merge
AddPrefabPostInit("forest_network", function(inst) inst:AddComponent("globalpositions") end)
AddPrefabPostInit("cave_network", function(inst) inst:AddComponent("globalpositions") end)

if NETWORKPLAYERPOSITIONS then
	--#rezecib this is an alternative to AddPlayerPostInit that avoids the overhead added to all prefabs
	-- however, if a character mod has a lower priority than this, it will miss them
	-- for this reason, we set the priority to -1000
	local function PlayerPostInit(inst)
		if GLOBAL.TheWorld.ismastersim then
			inst:ListenForEvent("setowner", function()
				inst:AddComponent("globalposition")
			end)
		end
		inst.MiniMapEntity:SetDrawOverFogOfWar(SHOWPLAYERICONS)
	end
	
	for k,prefabname in ipairs(GLOBAL.DST_CHARACTERLIST) do
		AddPrefabPostInit(prefabname, PlayerPostInit)
	end

	if GLOBAL.MODCHARACTERLIST then
		for k,prefabname in ipairs(GLOBAL.MODCHARACTERLIST) do
			AddPrefabPostInit(prefabname, PlayerPostInit)
		end
	end
end

--Adding the stuff for signal fires
local function FirePostInit(inst, offset)
	if GLOBAL.TheWorld.ismastersim then
		inst:AddComponent("smokeemitter")
		inst.smoke_emitter_offset = offset
		local duration = 0
		if NEEDCHARCOAL then
			local OldTakeFuelItem = inst.components.fueled.TakeFuelItem
			inst.components.fueled.TakeFuelItem = function(self, item, ...)
				if item.prefab == "charcoal" and self:CanAcceptFuelItem(item) then
					duration = duration + item.components.fuel.fuelvalue * self.bonusmult
					-- we don't want it to ever go higher than the max burn of a firepit
					-- note that this can result in smoking after burning, but this actually
					-- makes some real-world sense, so I left it in
					duration = math.min(360, duration)
					inst.components.smokeemitter:Enable(duration)
				end
				return OldTakeFuelItem(self, item, ...)
			end
		else
			local OldIgnite = inst.components.burnable.Ignite
			inst.components.burnable.Ignite = function(...)
				OldIgnite(...)
				inst.components.smokeemitter:Enable()
			end
			local OldExtinguish = inst.components.burnable.Extinguish
			inst.components.burnable.Extinguish = function(...)
				OldExtinguish(...)
				inst.components.smokeemitter:Disable()
			end
			if inst.components.burnable.burning then
				inst.components.burnable:Ignite()
			end
		end
	end
end
--Don't even bother adding it unless we have signal fires enabled
if SHOWFIRES then
	AddPrefabPostInit("campfire", function(inst) FirePostInit(inst) end)
	AddPrefabPostInit("firepit", function(inst) FirePostInit(inst) end)
	local deluxe_campfires_installed = false
	for k,v in pairs(GLOBAL.KnownModIndex:GetModsToLoad()) do
		deluxe_campfires_installed = deluxe_campfires_installed or v == "workshop-444235588"
	end
	if deluxe_campfires_installed then
		AddPrefabPostInit("deluxe_firepit", function(inst) FirePostInit(inst, {x=350,y=-350}) end)
		AddPrefabPostInit("heat_star", function(inst) FirePostInit(inst, {x=230,y=-230}) end)
	end
end

if GLOBAL.TheNet:GetIsServer() then
	--have to fix the normal indicators sticking around forever on the server
	PlayerTargetIndicator = require("components/playertargetindicator")
	
	local function ShouldRemove(x, z, v)
		local vx, vy, vz = v.Transform:GetWorldPosition()
		return GLOBAL.distsq(x, z, vx, vz) > oldmaxrangesq
	end
	
	local OldOnUpdate = PlayerTargetIndicator.OnUpdate
	function PlayerTargetIndicator:OnUpdate(...)
		local ret = OldOnUpdate(self, ...)
		local x, y, z = self.inst.Transform:GetWorldPosition()
		for i,v in ipairs(self.offScreenPlayers) do
			while ShouldRemove(x, z, v) do
				self.inst.HUD:RemoveTargetIndicator(v)
				GLOBAL.table.remove(self.offScreenPlayers, i)
				v = self.offScreenPlayers[i]
				if v == nil then break end
			end
		end
		return ret
	end
end

local USERFLAGS = GLOBAL.USERFLAGS
local checkbit = GLOBAL.checkbit
local DST_CHARACTERLIST = GLOBAL.DST_CHARACTERLIST
local MODCHARACTERLIST = GLOBAL.MODCHARACTERLIST
local MOD_AVATAR_LOCATIONS = GLOBAL.MOD_AVATAR_LOCATIONS

-- Using the require approach so that we can modify the class table directly, instead
-- of AddClassPostConstruct, which patches the instances after each initialization;
-- this allows us to get at errors/warnings that would otherwise pop up in the constructor (_ctor),
-- and is also generally more efficient because it runs once
TargetIndicator = require("widgets/targetindicator")
local OldTargetIndicator_ctor = TargetIndicator._ctor
TargetIndicator._ctor = function(self, owner, target, ...)
	OldTargetIndicator_ctor(self, owner, target, ...)
	if type(target.userid) == "userdata" then
		self.is_character = true
		self.inst.startindicatortask:Cancel()
		local updating = false
		local OldShow = self.Show
		function self:Show(...)
			if not updating then
				updating = true
				self.colour = self.target.playercolour
				self:StartUpdating()
			end
			return OldShow(self, ...)
		end
	end
end

-- Wrapping these in a function so they can get rechecked when portraitdirty events are pushed
-- (normal target indicators actually don't check after being created)
function TargetIndicator:IsGhost()
	return self.userflags and checkbit(self.userflags, USERFLAGS.IS_GHOST)
end
-- AFK flag not used yet, but futureproofing and stuff
function TargetIndicator:IsAFK()
	return self.userflags and checkbit(self.userflags, USERFLAGS.IS_AFK)
end
function TargetIndicator:IsCharacterState1()
	return self.userflags and checkbit(self.userflags, USERFLAGS.CHARACTER_STATE_1)
end
function TargetIndicator:IsCharacterState2()
	return self.userflags and checkbit(self.userflags, USERFLAGS.CHARACTER_STATE_2)
end

-- This is for the target indicator images; map icons inherit directly from the prefab
local GLOBAL_VISIBILITY_LIST = {
	-- atlas is left nil if the image is in inventoryimages
	-- image is left nil if the image is just the key.tex
	-- for example, setting both fields for campfire to nil would result in these values:
	-- campfire = {atlas = "images/inventoryimages.xml", image = "campfire.tex"}
	campfire = {atlas = nil, image = nil},
	firepit = {atlas = nil, image = nil},
	deluxe_firepit = {atlas = "images/inventoryimages/deluxe_firepit.xml", image = nil},
	heat_star = {atlas = "images/inventoryimages/heat_star.xml", image = nil},
	ping_generic = {atlas = "images/Ping.xml", image = "Ping.tex"},
	ping_danger = {atlas = "images/PingDanger.xml", image = "PingDanger.tex"},
	ping_omw = {atlas = "images/PingOmw.xml", image = "PingOmw.tex"},
	ping_explore = {atlas = "images/PingExplore.xml", image = "PingExplore.tex"},
	ping_gohere = {atlas = "images/PingGoHere.xml", image = "PingGoHere.tex"},
}

GLOBAL.STRINGS.NAMES.PING_GENERIC = "Point of Interest"
GLOBAL.STRINGS.NAMES.PING_DANGER = "Danger"
GLOBAL.STRINGS.NAMES.PING_OMW = "On My Way"
GLOBAL.STRINGS.NAMES.PING_EXPLORE = "Explore Here"
GLOBAL.STRINGS.NAMES.PING_GOHERE = "Go Here"

local OldOnMouseButton = TargetIndicator.OnMouseButton
function TargetIndicator:OnMouseButton(button, down, ...)
	OldOnMouseButton(self, button, down, ...)
	-- Lets you dismiss the target indicator
	if button == GLOBAL.MOUSEBUTTON_RIGHT then
		-- this gets checked in the PlayerHud OnUpdate below
		self.onlyshowonscoreboard = true
	end
end

--#rezecib Most of this code is adapted from playerbadge
-- I used playerbadge because that is what's used on the scoreboard, which
-- also parses the TheNet:GetClientTable() to determine what it shows
local OldGetAvatarAtlas = TargetIndicator.GetAvatarAtlas
function TargetIndicator:GetAvatarAtlas(...)
	self.is_character = true
	if type(self.target.userid) == "userdata" then --this is a globalposition_classified
		local prefab = self.target.parentprefab:value()
		if self.target.userid:value() == "nil" then -- this isn't a player
			self.is_character = false
			if GLOBAL_VISIBILITY_LIST[prefab] then
				self.prefabname = prefab
				if self.name_label then
					self.name_label:SetString(self.target.name .. "\n" .. GLOBAL.STRINGS.RMB .. " Dismiss")
				end
			else
				self.prefabname = ""
			end
		else -- this is a player
			for k,v in pairs(GLOBAL.TheNet:GetClientTable() or {}) do -- find the right player
				if self.target.userid:value() == v.userid then -- this is the right player
					if self.prefabname ~= prefab then
						self.is_mod_character = false
						if not table.contains(DST_CHARACTERLIST, prefab)
						and not table.contains(MODCHARACTERLIST, prefab) then
							self.prefabname = "" -- this shouldn't happen
						else
							self.prefabname = prefab
							if table.contains(MODCHARACTERLIST, prefab) then
								self.is_mod_character = true
							end
						end
					end
					if self.userflags ~= v.userflags then
						self.userflags = v.userflags
					end
				end
			end
		end
		if self.is_character and self.is_mod_character and not self:IsAFK() then
			local location = MOD_AVATAR_LOCATIONS["Default"]
			if MOD_AVATAR_LOCATIONS[self.prefabname] ~= nil then
				location = MOD_AVATAR_LOCATIONS[self.prefabname]
			end
			
			local starting = "avatar_"
			if self:IsGhost() then
				starting = starting .. "ghost_"
			end
			
			local ending = ""
			if self:IsCharacterState1() then
				ending = "_1"
			end		
			if self:IsCharacterState2() then
				ending = "_2"
			end
			
			return location .. starting .. self.prefabname .. ending .. ".xml"
		elseif not self.is_character then
			return GLOBAL_VISIBILITY_LIST[self.prefabname].atlas
				or "images/inventoryimages.xml"
		end
		return "images/avatars.xml"
	else
		return OldGetAvatarAtlas(self, ...)
	end
end
local OldGetAvatar = TargetIndicator.GetAvatar
function TargetIndicator:GetAvatar(...)
	if type(self.target.userid) == "userdata" then --this is a globalposition_classified
		local prefab = self.target.parentprefab:value()
		if self.is_mod_character and not self:IsAFK() then
			local starting = "avatar_"
			if self:IsGhost() then
				starting = starting .. "ghost_"
			end
			
			local ending = ""
			if self:IsCharacterState1() then
				ending = "_1"
			end		
			if self:IsCharacterState2() then
				ending = "_2"
			end
			
			return starting .. self.prefabname .. ending .. ".tex"
		elseif not self.is_character then
			return GLOBAL_VISIBILITY_LIST[self.prefabname].image
				or self.prefabname .. ".tex"
		else
			if self.ishost and self.prefabname == "" then
				return "avatar_server.tex"
			elseif self:IsAFK() then
				return "avatar_afk.tex"
			elseif self:IsGhost() then
				return "avatar_ghost_"..(self.prefabname ~= "" and self.prefabname or "unknown")..".tex"
			else
				return "avatar_"..(self.prefabname ~= "" and self.prefabname or "unknown")..".tex"
			end				
		end
	else
		return OldGetAvatar(self, ...)
	end
end

-- The OnRemoveEntity in globalposition_classified (GPC) should really be handling this,
-- but for some reason sometimes an invalid GPC still gets its target indicator updated,
-- and this causes a crash
OldTargetIndicatorOnUpdate = TargetIndicator.OnUpdate
function TargetIndicator:OnUpdate()
	if self.target:IsValid() then
		OldTargetIndicatorOnUpdate(self)
	else
		-- If this gets spammed in logs then there's a real problem
		-- Otherwise this is just a hacky fix to a rare and temporary scenario
		print("GlobalPositions warning: Invalid GPC")
	end
end

AddClassPostConstruct("screens/playerhud", function(PlayerHud)
	PlayerHud.targetindicators = {}
	local mastersim = GLOBAL.TheNet:GetIsServer()
	local OldSetMainCharacter = PlayerHud.SetMainCharacter
	function PlayerHud:SetMainCharacter(...)
		local ret = OldSetMainCharacter(self, ...)
		local client_table = GLOBAL.TheNet:GetClientTable() or {}
		for k,v in pairs(GLOBAL.TheWorld.net.components.globalpositions.positions) do
			if v.userid:value() == "nil" then
				self:AddTargetIndicator(v)
				self.targetindicators[#self.targetindicators]:Hide()
				v:UpdatePortrait()
			end
			--for each global position already added to the table...
			if SHOWPLAYERINDICATORS then
				for j,w in pairs(client_table) do
					if v.userid:value() == w.userid -- find the corresponding player...
					and w.userid ~= self.owner.userid then -- but not the local player...
						v.playercolor = w.colour
						v.name = w.name
						self:AddTargetIndicator(v)
						self.targetindicators[#self.targetindicators]:Hide()
						v:UpdatePortrait()
					end
				end
			end
		end
		return ret
	end
		
	--Basically the following two functions cause it to find the matching globalposition_classified's
	-- indicator, and tell it to be hidden while the normal indicator is up.
	local OldAddTargetIndicator = PlayerHud.AddTargetIndicator
	function PlayerHud:AddTargetIndicator(target)
		if type(target.userid) ~= "userdata" then --this is a normal player target indicator
			for k,v in pairs(self.targetindicators) do
				if type(v.target.userid) == "userdata" and v.target.userid:value() == target.userid then
					-- this is a target indicator for the same player's globalposition_classified
					v.hidewhileclose = true
				end
			end
		end
		OldAddTargetIndicator(self, target)
	end
	local OldRemoveTargetIndicator = PlayerHud.RemoveTargetIndicator
	function PlayerHud:RemoveTargetIndicator(target)
		if type(target.userid) ~= "userdata" then --this is a normal player target indicator
			for k,v in pairs(self.targetindicators) do
				if type(v.target.userid) == "userdata" and v.target.userid:value() == target.userid then
					-- this is a target indicator for the same player's globalposition_classified
					v.hidewhileclose = false
				end
			end
		end
		OldRemoveTargetIndicator(self, target)
	end
	
	local OldOnUpdate = PlayerHud.OnUpdate
	function PlayerHud:OnUpdate(...)
		local ret = OldOnUpdate(self, ...)
		local onscreen = {}
		if self.owner and self.owner.components and self.owner.components.playertargetindicator then
			onscreen = self.owner.components.playertargetindicator.onScreenPlayersLastTick
		end
		if self.targetindicators then
			for j,w in pairs(self.targetindicators) do --for each target indicator...
				local show = true
				if type(w.target.userid) == "userdata" then --if it's a globalposition_classified...
					-- globalpositions should only be shown on the scoreboard screen
					-- or if the show always option is set
					-- but we also don't want to have it showing when the normal indicator is,
					-- because that produces awful flickering
					show = SHOWPLAYERSALWAYS and (not w.hidewhileclose) or self:IsStatusScreenOpen()
					if not w.is_character then
						local parent_entity = w.target.parententity:value()
						show = not (parent_entity and parent_entity.entity:FrustumCheck())
						if w.onlyshowonscoreboard then
							show = show and self:IsStatusScreenOpen()
						end
					end
					for k,v in pairs(onscreen) do --check if its userid matches an onscreen player...
						if w.target.userid:value() == v.userid then
							show = false
						end
					end
					if w.is_character then 
						if self:IsStatusScreenOpen() then
							w.name_label:Show()
						elseif not w.focus then
							w.name_label:Hide()
						end
					end
					if GLOBAL.TheFrontEnd.mutedPlayers[w.target.parentuserid:value()] then
						show = false -- for pings from muted players
					end
				elseif mastersim then
					w:Hide()
				end
				if show then
					w:Show()
				else
					w:Hide()
				end
			end
		end
		return ret
	end
	
	local OldShowPlayerStatusScreen = PlayerHud.ShowPlayerStatusScreen
	function PlayerHud:ShowPlayerStatusScreen(...)
		local ret = OldShowPlayerStatusScreen(self, ...)
		self:OnUpdate(0.0001)
		return ret
	end
end)

--[[ Patch TheFrontEnd to track changes in muted players ]]--
require("frontend")
local OldFrontEnd_ctor = GLOBAL.FrontEnd._ctor
GLOBAL.FrontEnd._ctor = function(TheFrontEnd, ...)
	OldFrontEnd_ctor(TheFrontEnd, ...)
	TheFrontEnd.mutedPlayers = {DontDeleteMePlz = true} -- to prevent the table from getting deleted
end

--[[ Patch the map to allow names to show on hover-over and pings ]]--

local pings = {}

local function ReceivePing(player, pingtype, x, y, z)
	if pingtype == "delete" then
		--Find the nearest ping and delete it (if it was actually somewhat close)
		mindistsq, minping = math.huge, nil
		for _,ping in pairs(pings) do
			local px, py, pz = ping.Transform:GetWorldPosition()
			dq = GLOBAL.distsq(x, z, px, pz)
			if dq < mindistsq then
				mindistsq = dq
				minping = ping
			end
		end
		-- Check that their mouse is actually somewhat close to it first, ~20
		if mindistsq < 400 then
			pings[minping.GUID] = nil
			minping:Remove()
		end
	elseif pingtype == "clear" then
		for _,ping in pairs(pings) do
			ping:Remove()
		end
	else
		local ping = GLOBAL.SpawnPrefab("ping_"..pingtype)
		ping.OnRemoveEntity = function(inst) pings[inst.GUID] = nil end
		ping.parentuserid = player.userid
		ping.Transform:SetPosition(x,y,z)
		pings[ping.GUID] = ping
	end
end
AddModRPCHandler(modname, "Ping", ReceivePing)

local STARTSCALE = 0.25
local NORMSCALE = 1
local pingwheel = nil
local pingwheelup = false
local activepos = nil
local function ShowPingWheel(position)
	if pingwheelup then return end
	pingwheelup = true
	SetModHUDFocus("PingWheel", true)
		
	activepos = position
	if GLOBAL.TheInput:ControllerAttached() then
		local scr_w, scr_h = TheSim:GetScreenSize()
		pingwheel:SetPosition(scr_w/2, scr_h/2)
	else	
		pingwheel:SetPosition(GLOBAL.TheInput:GetScreenPosition():Get())
	end
	pingwheel:Show()
	pingwheel:ScaleTo(STARTSCALE, NORMSCALE, .25)
end

local function HidePingWheel(cancel)
	if not pingwheelup or activepos == nil then return end
	pingwheelup = false
	SetModHUDFocus("PingWheel", false)
	
	pingwheel:Hide()
	pingwheel.inst.UITransform:SetScale(STARTSCALE, STARTSCALE, 1)
				
	if pingwheel.activegesture and pingwheel.activegesture ~= "cancel" and not cancel then
		SendModRPCToServer(MOD_RPC[modname]["Ping"], pingwheel.activegesture, activepos:Get())
	end
	activepos = nil
end
GLOBAL.TheInput:AddMouseButtonHandler(function(button, down, x, y)
	if button == 1000 and not down then
		HidePingWheel()
	end
end)

AddClassPostConstruct("widgets/mapwidget", function(MapWidget)
	MapWidget.offset = GLOBAL.Vector3(0,0,0)
	-- Hoverers get their text from the owner's tooltip; we set the MapWidget to the owner
	MapWidget.nametext = require("widgets/maphoverer")()
	MapWidget.pingwheel = require("widgets/pingwheel")()
	pingwheel = MapWidget.pingwheel
	pingwheel.radius = pingwheel.radius * 1.1
	pingwheel:Hide()
	pingwheel.inst.UITransform:SetScale(STARTSCALE, STARTSCALE, 1)

	function MapWidget:OnUpdate(dt)
		pingwheel:OnUpdate()
		if not self.shown or pingwheelup then return end
		
		-- Begin copy-pasted code (small edits to match modmain environment)
		if GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_PRIMARY) then
			local pos = GLOBAL.TheInput:GetScreenPosition()
			if self.lastpos then
				local scale = 0.25
				local dx = scale * ( pos.x - self.lastpos.x )
				local dy = scale * ( pos.y - self.lastpos.y )
				self:Offset( dx, dy ) --#rezecib changed this so we can capture offsets
			end
			
			self.lastpos = pos
		else
			self.lastpos = nil
		end
		-- End copy-pasted code
		
		if SHOWPLAYERICONS then
			local p = self:GetWorldMousePosition()
			mindistsq, gpc = math.huge, nil
			for k,v in pairs(GLOBAL.TheWorld.net.components.globalpositions.positions) do
				if not GLOBAL.TheFrontEnd.mutedPlayers[v.parentuserid:value()] then--v.userid:value() ~= "nil" then -- this is a player's position
					local x, y, z = v.Transform:GetWorldPosition()
					dq = GLOBAL.distsq(p.x, p.z, x, z)
					if dq < mindistsq then
						mindistsq = dq
						gpc = v
					end
				end
			end
			-- Check that their mouse is actually somewhat close to them first
			if math.sqrt(mindistsq) < self.minimap:GetZoom()*10 then
				if self.nametext:GetString() ~= gpc.name then
					self.nametext:SetString(gpc.name)
					self.nametext:SetColour(gpc.playercolour)
				end
			else -- nobody is being moused over
				self.nametext:SetString("")
			end
		end
	end
	
	local OldOffset = MapWidget.Offset
	function MapWidget:Offset(dx, dy, ...)
		self.offset.x = self.offset.x + dx
		self.offset.y = self.offset.y + dy
		OldOffset(self, dx, dy, ...)
	end
	
	local OldOnShow = MapWidget.OnShow
	function MapWidget:OnShow(...)
		self.offset.x = 0
		self.offset.y = 0
		OldOnShow(self, ...)
	end
	
	local OldOnZoomIn = MapWidget.OnZoomIn
	function MapWidget:OnZoomIn(...)
		local zoom1 = self.minimap:GetZoom()
		OldOnZoomIn(self, ...)
		local zoom2 = self.minimap:GetZoom()
		if self.shown then
			self.offset = self.offset*zoom1/zoom2
		end
	end

	local OldOnZoomOut = MapWidget.OnZoomOut
	function MapWidget:OnZoomOut(...)
		local zoom1 = self.minimap:GetZoom()
		OldOnZoomOut(self, ...)
		local zoom2 = self.minimap:GetZoom()
		if self.shown and zoom1 < 20 then
			self.offset = self.offset*zoom1/zoom2
		end
	end
	
	function MapWidget:GetWorldMousePosition()
		-- Get the screen size so we can figure out the position of the center
		local screenwidth, screenheight = GLOBAL.TheSim:GetScreenSize()
		-- But also adjust the center to the position of the player
		-- (this makes it so we only have to take into account camera angle once)
		local cx = screenwidth*.5 + self.offset.x*4.5
		local cy = screenheight*.5 + self.offset.y*4.5
		local mx, my = GLOBAL.TheInput:GetScreenPosition():Get()
		if GLOBAL.TheInput:ControllerAttached() then
			mx, my = screenwidth*.5, screenheight*.5
		end
		-- Calculate the offset of the mouse from the center
		local ox = mx - cx
		local oy = my - cy
		-- Calculate the world distance and world angle
		local angle = GLOBAL.TheCamera:GetHeadingTarget()*math.pi/180
		local wd = math.sqrt(ox*ox + oy*oy)*self.minimap:GetZoom()/4.5
		local wa = math.atan2(ox, oy) - angle
		-- Convert to world x and z coordinates, adding in the offset from the player
		local px, _, pz = GLOBAL.ThePlayer:GetPosition():Get()
		local wx = px - wd*math.cos(wa)
		local wz = pz + wd*math.sin(wa)
		return GLOBAL.Vector3(wx, 0, wz)
	end
end)

--[[ Patch the Map Screen to disable the hovertext when getting closed, and add ping interface]]--
AddClassPostConstruct("screens/mapscreen", function(MapScreen)
	if GLOBAL.TheInput:ControllerAttached() then
		MapScreen.ping_reticule = MapScreen:AddChild(GLOBAL.require("widgets/uianim")())
		MapScreen.ping_reticule:GetAnimState():SetBank("reticule")
		MapScreen.ping_reticule:GetAnimState():SetBuild("reticule")
		MapScreen.ping_reticule:GetAnimState():PlayAnimation("idle")
		MapScreen.ping_reticule:SetScale(.35)
		local screenwidth, screenheight = GLOBAL.TheSim:GetScreenSize()
		MapScreen.ping_reticule:SetPosition(screenwidth*.5, screenheight*.5)
	end

	local OldOnBecomeInactive = MapScreen.OnBecomeInactive
	function MapScreen:OnBecomeInactive(...)
		self.minimap.nametext:SetString("")
		HidePingWheel(true) -- consider it to be a cancellation
		OldOnBecomeInactive(self, ...)
	end
	
	function MapScreen:OnMouseButton(button, down, ...)
		-- Alt-click
		if button == 1000 and down and GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
			ShowPingWheel(self.minimap:GetWorldMousePosition())
		end
	end
	
	local OldOnControl = MapScreen.OnControl
	function MapScreen:OnControl(control, down, ...)
		if control == GLOBAL.CONTROL_MENU_MISC_4 then --right-stick click
			if down then
				ShowPingWheel(self.minimap:GetWorldMousePosition())
			else
				HidePingWheel()
			end
			return true
		end
		return OldOnControl(self, control, down, ...)
	end
	local OldGetHelpText = MapScreen.GetHelpText
	function MapScreen:GetHelpText(...)
		return OldGetHelpText(self, ...) .. "  " .. GLOBAL.TheInput:GetLocalizedControl(
			GLOBAL.TheInput:GetControllerID(), GLOBAL.CONTROL_MENU_MISC_4) .. " Ping"
	end
end)

--[[ Patch the scoreboard to add a button and RPC for disable location sharing ]]--
ImageButton = require("widgets/imagebutton")
if NETWORKPLAYERPOSITIONS then --Don't bother unless positions are actually being networked
	-- First we need to make the mod RPC that the clients will send to stop sharing their location
	local function SetLocationSharing(player, is_sharing)
		gp = player.components.globalposition
		if is_sharing then --they want to share
			-- if ANR_BETA then
				-- if SHOWPLAYERICONS then
					-- AddGlobalIcon(player)
				-- end
				-- if SHAREMINIMAPPROGRESS then
					-- AddMapRevealer(player)
				-- end
			-- end
			if not gp then -- don't add it again if they already have it
				player:AddComponent("globalposition")
			end
		else
			-- if ANR_BETA then
				-- if SHOWPLAYERICONS then
					-- player.icon:Remove()
					-- player.icon = nil
				-- end
				-- if SHAREMINIMAPPROGRESS then
					-- player:RemoveComponent("maprevealer")
				-- end
			-- end
			if gp then -- make sure they do have it before trying to remove it
				player:RemoveComponent("globalposition")
			end
		end
	end
	AddModRPCHandler(modname, "ShareLocation", SetLocationSharing)

	local is_sharing = true --keep track locally of whether we're sharing or not
	-- why does GUI code have to be so long....................
	local PlayerStatusScreen = require("screens/playerstatusscreen")
	local OldDoInit = PlayerStatusScreen.DoInit
	function PlayerStatusScreen:DoInit(ClientObjs, ...)
		OldDoInit(self, ClientObjs, ...)
		if not self.scroll_list.old_updatefn then -- if we haven't already patched the widgets
			for i,playerListing in pairs(self.scroll_list.static_widgets) do
				local un = is_sharing and "" or "un"
				playerListing.shareloc = playerListing:AddChild(ImageButton("images/"..un.."sharelocation.xml",
				 un.."sharelocation.tex", un.."sharelocation.tex",
				 un.."sharelocation.tex", un.."sharelocation.tex",
				 nil, {1,1}, {0,0}))
				playerListing.shareloc:SetPosition(playerListing.mute:GetPosition():Get())
				playerListing.shareloc.scale_on_focus = false
				playerListing.shareloc:SetHoverText((is_sharing and "Uns" or "S").."hare Location", { font = GLOBAL.NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
				tint = is_sharing and {1,1,1,1} or {242/255, 99/255, 99/255, 255/255}
				playerListing.shareloc.image:SetTint(GLOBAL.unpack(tint))
				local gainfocusfn = playerListing.shareloc.OnGainFocus
				playerListing.shareloc.OnGainFocus = function()
					gainfocusfn(playerListing.shareloc)
					GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
					playerListing.shareloc.image:SetScale(1.1)
				end
				local losefocusfn = playerListing.shareloc.OnLoseFocus
				playerListing.shareloc.OnLoseFocus = function()
					losefocusfn(playerListing.shareloc)
					playerListing.shareloc.image:SetScale(1)
				end
				playerListing.shareloc:SetOnClick(function()
					is_sharing = not is_sharing
					local un = is_sharing and "" or "un"
					playerListing.shareloc.image_focus = un.."shareLocation.tex"
					playerListing.shareloc.image:SetTexture("images/"..un.."sharelocation.xml", un.."sharelocation.tex")
					playerListing.shareloc:SetTextures("images/"..un.."sharelocation.xml", un.."shareLocation.tex")
					playerListing.shareloc:SetHoverText((is_sharing and "Uns" or "S").."hare Location")
					tint = is_sharing and {1,1,1,1} or {242/255, 99/255, 99/255, 255/255}
					playerListing.shareloc.image:SetTint(GLOBAL.unpack(tint))
					
					SendModRPCToServer(MOD_RPC[modname]["ShareLocation"], is_sharing)
				end)
				
				if playerListing.userid == self.owner.userid then
					playerListing.viewprofile:SetFocusChangeDir(GLOBAL.MOVE_RIGHT, playerListing.shareloc)
					playerListing.shareloc:SetFocusChangeDir(GLOBAL.MOVE_LEFT, playerListing.viewprofile)
				else
					playerListing.shareloc:Hide()
				end
			end
			
			self.scroll_list.old_updatefn = self.scroll_list.updatefn
			self.scroll_list.updatefn = function(playerListing, client, ...)
				self.scroll_list.old_updatefn(playerListing, client, ...)
				if client.userid == self.owner.userid then
					playerListing.shareloc:SetPosition(playerListing.mute:GetPosition():Get())
					playerListing.viewprofile:SetFocusChangeDir(GLOBAL.MOVE_RIGHT, playerListing.shareloc)
					playerListing.shareloc:SetFocusChangeDir(GLOBAL.MOVE_LEFT, playerListing.viewprofile)
					playerListing.shareloc:Show()
				else
					playerListing.shareloc:Hide()
				end
			end
		end
	end
end

--[[ Capture nonstandard minimap icons for mod characters ]]--
--#rezecib code from Global Player Icons, by Sarcen (also see prefabs/globalplayericon.lua)
GLOBAL.AllGlobalIcons = {}
GLOBAL.GlobalIconAtlasTranslation = {}

-- Hack to determine MiniMap icon names
for i,atlases in ipairs(GLOBAL.ModManager:GetPostInitData("MinimapAtlases")) do
	for i,path in ipairs(atlases) do
		local file = GLOBAL.io.open(GLOBAL.resolvefilepath(path), "r")
		if file then
			local xml = file:read("*a")
			if xml then
				for element in string.gmatch(xml, "<Element[^>]*name=\"([^\"]*)\"") do
					if element then
						local elementName = string.match(element, "^(.*)[.]")
						if elementName then
							GLOBAL.GlobalIconAtlasTranslation[elementName] = element
						end
					end
				end
			end
			file:close()
		end
	end
end

for prefab,data in pairs(GLOBAL_VISIBILITY_LIST) do
	GLOBAL.GlobalIconAtlasTranslation[prefab] = prefab .. ".tex"
end

for _,prefab in pairs(GLOBAL.DST_CHARACTERLIST) do
	GLOBAL.GlobalIconAtlasTranslation[prefab] = prefab .. ".png"
end