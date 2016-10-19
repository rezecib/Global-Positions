local function MakePing(prefabname)
	local function fn()
		local inst = CreateEntity()
		
		inst.entity:SetCanSleep(false)
		inst.persists = false
		inst:AddTag("FX") -- make sure this doesn't block placement

		inst.entity:AddTransform()
		inst.entity:AddMiniMapEntity()
		
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
