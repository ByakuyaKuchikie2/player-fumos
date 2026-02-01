AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("fumo_ren.onUse")
util.AddNetworkString("fumo_ren.explode")

local delay = 1

function ENT:Initialize()
    self:SetModel( "models/niko_plush/niko_plush.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetUseType( SIMPLE_USE )
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end

    self.exploding = false
    self.lastUsed = 0

    self.pitch = 0
end

function ENT:Use(activator, caller, useType, value)
    self.lastUsed = CurTime()

    if self.exploding then return end

    if self.pitch >= 1.25 then
        net.Start("fumo_ren.explode")
            net.WriteEntity(self)
        net.SendPVS(self:GetPos())
        self.exploding = true

        timer.Simple(2, function() 
            if not self or not self:IsValid() then return end
            self:Remove() 
        end)

        return
    end
    
    net.Start("fumo_ren.onUse")
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