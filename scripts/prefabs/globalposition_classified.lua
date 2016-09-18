local function UpdatePortrait(inst)
	TheWorld.net.components.globalpositions:UpdatePortrait(inst)
end

local function UpdateIconPosition(inst)
	if inst.icon then
		--enable it if it's not a player, but if it is...
		-- disable it if the player is in range (and thus has an icon already)
		inst.icon.MiniMapEntity:SetEnabled(not TheFrontEnd.mutedPlayers[inst.parentuserid:value()]
			and (inst.userid:value() == "nil" or inst.parententity:value() == nil))
		--enable otherwise
		inst.icon.Transform:SetPosition(inst.pos.x:value(), 0, inst.pos.z:value())
	end
	if inst.sharemap:value() then
		local x,z = inst.pos.x:value(), inst.pos.z:value()
		TheWorld.minimap.MiniMap:ShowArea(x, 0, z, 30) -- reveal the area
		TheWorld.Map:VisitTile(TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)) -- save it as revealed
	end
end

local function fn()
    local inst = CreateEntity()
    inst.persists = false

    inst.entity:AddNetwork()
    inst.entity:Hide()
	
    inst:AddTag("CLASSIFIED")
	
	inst.playercolour = DEFAULT_PLAYER_COLOUR
	inst.name = "unknown"
	
	inst.parentprefab = net_string(inst.GUID, "prefab")
	inst.parententity = net_entity(inst.GUID, "parent")
	inst.userid = net_string(inst.GUID, "userid", "useriddirty")
	inst.parentuserid = net_string(inst.GUID, "parentuserid")
	inst.parentname = net_string(inst.GUID, "parentname")
	inst.portraitdirty = net_event(inst.GUID, "portraitdirty", "portraitdirty")
	inst.UpdatePortrait = UpdatePortrait

    inst.pos =
    {
        x = net_float(inst.GUID, "pos.x"),
        z = net_float(inst.GUID, "pos.z"),
    }
	
	inst.sharemap = net_bool(inst.GUID, "sharemap")
	inst.sharemap:set(false)
	
	--#rezecib le hack extrem
	-- We don't want an actual transform, because that will cause it to sleep/wake based on distance
	-- but we DO want to be able to use the normal distance calculation functions, which use this
	inst.Transform = {}
	inst.Transform.GetWorldPosition = function()
		return inst.pos.x:value(), 0, inst.pos.z:value()
	end
	
	if _GLOBALPOSITIONS_SHOWPLAYERINDICATORS then
		inst:ListenForEvent("portraitdirty", UpdatePortrait)
	end
	inst.icon = SpawnPrefab("globalplayericon")
	inst:AddChild(inst.icon) --makes the icon get removed with this
	inst:DoPeriodicTask(0.1, function() UpdateIconPosition(inst) end)
	local function check_icon()
		local isplayer = inst.userid:value() ~= "nil"
		if (not isplayer and _GLOBALPOSITIONS_SHOWFIREICONS)
		or (isplayer and _GLOBALPOSITIONS_SHOWPLAYERICONS)then
			inst.icon:UpdateIcon(inst.parentprefab:value())
		else
			inst.icon:Remove()
			inst.icon = nil
		end
	end
    if TheWorld.ismastersim then
		inst:ListenForEvent("useriddirty", function()
			check_icon()
		end)
	else
		inst:ListenForEvent("useriddirty", function()
			TheWorld.net.components.globalpositions:AddClientEntity(inst)
			check_icon()
		end)
        return inst
    end
	
	--#rezecib removed because we don't want to follow their sleep state?
    -- inst.entity:AddTransform() --So we can follow parent's sleep state
    inst.entity:SetPristine()

    return inst
end

return Prefab("globalposition_classified", fn)