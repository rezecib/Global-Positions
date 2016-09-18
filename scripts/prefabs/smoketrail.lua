local texture = "fx/frostbreath.tex"
local shader = "shaders/particle.ksh"
local colour_envelope_name = "smokecolourenvelope"
local scale_envelope_name = "smokescaleenvelope"

local assets =
{
	Asset( "IMAGE", texture ),
	Asset( "SHADER", shader ),
}

local min_scale = 1
local max_scale = 3

local function IntColour( r, g, b, a )
	return { r / 255.0, g / 255.0, b / 255.0, a / 255.0 }
end

local init = false
local function InitEnvelopes()
	
	if EnvelopeManager and not init then
		init = true
		EnvelopeManager:AddColourEnvelope(
			colour_envelope_name,
			{	{ 0,	IntColour( 0, 0, 0, 0 ) },
				{ 0.1,	IntColour( 0, 0, 0, 255 ) },
				{ 0.3,	IntColour( 0, 0, 0, 255 ) },
				{ 1,	IntColour( 0, 0, 0, 0 ) },
			} )

		EnvelopeManager:AddVector2Envelope(
			scale_envelope_name,
			{
				{ 0,	{ min_scale, min_scale } },
				{ 1,	{ max_scale, max_scale } },
			} )
	end
end

local max_lifetime = 6

local function Emit(inst)
	local emitter = inst.ParticleEmitter
	local sphere_emitter = CreateSphereEmitter(0.1)

	local vx, vy, vz = 0, .05, 0
	local lifetime = max_lifetime * (0.9 + UnitRand() * 0.1)
	local px, py, pz

	px, py, pz = sphere_emitter()

	local angle = UnitRand() * 360
	local angular_velocity = UnitRand()*5

	emitter:AddRotatingParticleUV(
		lifetime,			-- lifetime
		px, py, pz,			-- position
		vx, vy, vz,			-- velocity
		angle,				-- rotation
		angular_velocity,	-- angular_velocity :P
		0, 0				-- uv offset
	)

end

local function empty_func()
end

local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

	InitEnvelopes()

    local emitter = inst.entity:AddParticleEmitter()
	emitter:SetRenderResources( texture, shader )
	emitter:SetRotationStatus( true )
	emitter:SetMaxNumParticles( 64 )
	emitter:SetMaxLifetime( max_lifetime )
	emitter:SetColourEnvelope( colour_envelope_name )
	emitter:SetScaleEnvelope( scale_envelope_name );
	emitter:SetBlendMode( BLENDMODE.Premultiplied )
	emitter:SetUVFrameSize( 1.0, 1.0 )

	-----------------------------------------------------
	inst.Emit = Emit

	EmitterManager:AddEmitter(inst, nil, empty_func)
	
	inst:DoPeriodicTask(0.5, function() inst:Emit() end)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddTag("FX")
    inst.persists = false

    return inst
end

return Prefab("common/fx/smoketrail", fn, assets)