local function GetIcon(inst, prefabname)
		-- Would be nice if there was a MiniMapEntity:GetIcon()
		if GlobalIconAtlasTranslation and GlobalIconAtlasTranslation[prefabname] then
			return GlobalIconAtlasTranslation[prefabname]
		end
		return prefabname .. ".png"
end

local function fn()
    local inst = CreateEntity()
	
	inst.entity:SetCanSleep(false)
    inst.persists = false
	inst:AddTag("FX") -- make sure this doesn't block placement

	inst.entity:AddTransform()
	inst.entity:AddMiniMapEntity()
	
	inst.MiniMapEntity:SetIcon("wilson.png")
	inst.MiniMapEntity:SetPriority(10)
	inst.MiniMapEntity:SetCanUseCache(false)
	inst.MiniMapEntity:SetDrawOverFogOfWar(true)
	inst.MiniMapEntity:SetEnabled(false)
	
	inst.UpdateIcon = function(inst, prefabname)
		inst.MiniMapEntity:SetIcon(GetIcon(inst, prefabname))
	end
	
    return inst
end

return Prefab("globalplayericon", fn)
