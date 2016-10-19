local function UpdatePortrait(inst)
	TheWorld.net.components.globalpositions:UpdatePortrait(inst)
end

local function fn()
    local inst = CreateEntity()
    inst.persists = false

	inst.entity:AddTransform()
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

	inst.entity:SetCanSleep(false)
	
    inst.entity:SetPristine()
	
	if _GLOBALPOSITIONS_SHOWPLAYERINDICATORS then
		inst:ListenForEvent("portraitdirty", UpdatePortrait)
	end
    if not TheWorld.ismastersim then
		inst:ListenForEvent("useriddirty", function()
			TheWorld.net.components.globalpositions:AddClientEntity(inst)
		end)
        return inst
    end

    return inst
end

return Prefab("globalposition_classified", fn)