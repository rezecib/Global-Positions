local ANR_BETA = kleifileexists("scripts/prefabs/globalmapicon") or BRANCH == "staging"

local function RemoveIcon(inst)
	inst.icon:Remove()
end

local function MakePing(prefabname)
	local function fn()
		local inst = CreateEntity()
		
		inst.entity:SetCanSleep(false)
		inst.persists = false
		inst:AddTag("FX") -- make sure this doesn't block placement

		inst.entity:AddTransform()
		inst.entity:AddMiniMapEntity()
		
		if ANR_BETA then
			-- inst.icon = SpawnPrefab("globalmapicon")
			-- inst.icon.MiniMapEntity:SetIcon(prefabname..".tex")		
			-- inst:DoTaskInTime(0, function() inst.icon.Transform:SetPosition(inst.Transform:GetWorldPosition()) end)
			-- inst.OnRemoveEntity = RemoveIcon
		else		
			inst.MiniMapEntity:SetIcon(prefabname..".png")
			inst.MiniMapEntity:SetPriority(10)
			inst.MiniMapEntity:SetCanUseCache(false)
			inst.MiniMapEntity:SetDrawOverFogOfWar(true)
		end
		
		inst:DoTaskInTime(0, function() inst:AddComponent("globalposition") end)
		
		inst:DoTaskInTime(TUNING.TOTAL_DAY_TIME, inst.Remove)		
		
		return inst
	end
	return Prefab(prefabname, fn)
end

local pingnames = {"generic", "omw", "danger", "explore", "gohere"}
local prefabs = {}
for _,pingname in ipairs(pingnames) do
	table.insert(prefabs, MakePing("ping_"..pingname))
end
return unpack(prefabs)
