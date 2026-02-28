AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("fumo_shank.onUse")
util.AddNetworkString("fumo_shank.explode")

local delay = 1

function ENT:Initialize()
    self:SetModel( "models/bs/shankplush/shankplush.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetUseType( SIMPLE_USE )
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end

    self:EmitSound("shank-spawn.mp3", 75, 100, 1, CHAN_ITEM)

    self.exploding = false
    self.lastUsed = 0

    self.pitch = 0
end

local props = {
    "models/props_junk/wood_crate001a.mdl",
    "models/props_junk/wood_crate001a_damaged.mdl"
}

local function boxify(invoker)
    invoker:EmitSound("snaptic/bowling_pins.mp3")

    local center = invoker:GetPos() + invoker:OBBCenter()
    local cache = {}
    
    for i=1, 15 do
        local death_prop = ents.Create("prop_physics")
        death_prop:SetModel(props[math.random(1, #props)])
        death_prop:SetPos(center + Vector(math.random(-10, 10), math.random(-10, 10), math.random(5, 10)))
        death_prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        death_prop:Activate()
        death_prop:Spawn()
        local dir = (death_prop:GetPos() - center):GetNormalized()
        local phys = death_prop:GetPhysicsObject()
        if IsValid(phys) then
            phys:ApplyForceCenter(dir * math.random(1000, 2000) * phys:GetMass())
            phys:ApplyTorqueCenter(Vector(math.random(-1,1),math.random(-1,1),math.random(-1,1)) * math.random(500, 1000) * phys:GetMass())
        end
        cache[#cache+1] = death_prop
    end

    timer.Simple(3, function()
        for i=1, #cache do
            local entry = cache[i]
            if IsValid(entry) then
                entry:Fire("break",1,0)
            end
        end
    end)

    timer.Simple(4, function()
        for i=1, #cache do
            local entry = cache[i]
            if IsValid(entry) then
                entry:Remove()
            end
        end
    end)
end

function ENT:Use(activator, caller, useType, value)
    self.lastUsed = CurTime()

    if self.exploding then return end

    if self.pitch >= 1.25 then
        boxify(self)
        EmitSound("shank-die.mp3", self:GetPos())
        self:Remove()
        --[[ net.Start("fumo_shank.explode")
            net.WriteEntity(self)
        net.SendPVS(self:GetPos())
        self.exploding = true

        timer.Simple(2, function() 
            if not self or not self:IsValid() then return end
            self:Remove() 
        end) ]]

        return
    end
    
    net.Start("fumo_shank.onUse")
        net.WriteEntity(self)
        net.WriteFloat(self.pitch)
    net.SendPVS(self:GetPos())

    local dt = engine.TickInterval()
    self.pitch = self.pitch + dt * 5
end

function ENT:Think()
    self:NextThink(CurTime())
    if self.lastUsed+delay < CurTime() then
        self.pitch = 0
    end

    return true
end