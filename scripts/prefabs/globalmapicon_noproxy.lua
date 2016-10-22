local function fn()
	local inst = Prefabs.globalmapicon.fn()
	
	inst.MiniMapEntity:SetIsProxy(false)
	
	return inst
end

return Prefab("globalmapicon_noproxy", fn)
