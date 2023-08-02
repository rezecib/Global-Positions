-- We can't use maprecorder's TeachMap directly because it calls inst:Remove
local function TeachMap(map, target)
	local Remove = map.Remove
	map.Remove = function() end
	local success = map.components.maprecorder:TeachMap(target)
	map.Remove = Remove
	return success
end

local function fn()
	local inst = CreateEntity()

    inst.entity:Hide()
    inst:AddTag("CLASSIFIED")
	
    if not TheWorld.ismastersim then
        return inst
    end
	
    --[[Non-networked entity]]
	
	inst.TeachMap = TeachMap
	
    inst:AddComponent("maprecorder")
	
	-- Avoid having save/load spawn duplicate maps
	-- Not totally sure if this is a problem,
	-- but I figured I'd do it just in case they leaked
	inst:DoTaskInTime(60, function()
		if TheWorld.components.worldmapsyncer.saved_map ~= inst then
			inst:Remove()
		end
	end)

    return inst
end

return Prefab("savedworldmap", fn)