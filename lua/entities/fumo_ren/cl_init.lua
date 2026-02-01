include("shared.lua")

-- Initialize empty vars for sound and clientside models
--

local dt = FrameTime()
local duration = 0.5
local maxreps = math.floor(duration / dt)
function ENT:Initialize()

    -- Create the sound the plush will make when used
    --
    self.snd = nil
    sound.PlayFile('sound/ren.mp3', '3d noplay noplay', function(snd)
        if snd then
            print('sound initialized')
            self.snd = snd
            self.snd:Set3DFadeDistance(256, 512)
        end
    end)

    -- Create the clientside model the explosion vtf will play on
    --
    self.explodeSheet = ClientsideModel("models/hunter/plates/plate1x1.mdl")
    self.explodeSheet:SetPos(self:GetPos())
    self.explodeSheet:SetParent(self)
    self.explodeSheet:SetNoDraw(true)
    self.explodeSheet:SetMaterial("explosion/explosion.vmt")

    self.currep = maxreps --setting it the this in the init so it doesn't play the animation on first spawn
end

function ENT:Draw()
    self:DrawModel()
end

-- Remove the think hook for the audio and remove the clientide model
--
function ENT:OnRemove()
    self.explodeSheet:Remove()
    if self.snd:IsValid() then self.snd:Stop() end 
end

-- play the sound and animation
--
net.Receive('fumo_ren.onUse', function()
    local self = net.ReadEntity()

    local p = net.ReadFloat()
    self.snd:SetPlaybackRate(1+p)
    self.snd:SetTime(0)
    self.snd:Play()
    self.currep = 0
end)

function ENT:Think()
    if not self or not self:IsValid() then return end
    self.currep = self.currep + 1
    if self.currep <= maxreps then
        local repsleft = maxreps - self.currep
        local elapsedtime = (maxreps - repsleft) * dt
        local t = 1-(duration-elapsedtime) / duration

        local bell = math.sin(math.pi * t)
        
        local scale = Vector(1,1,1 - bell*0.3)
        if repsleft == 0 then
            scale = Vector(1,1,1)
        end
        
        -- Thanks gmod wiki!
        local mat = Matrix()
        mat:Scale(scale)
        self:EnableMatrix("RenderMultiply", mat)
    end

    -- Angle the clientside model towards the player eyes
    --
    local dir = (EyePos() - self:GetPos()):GetNormalized()
    local ang = dir:Angle()
    ang:RotateAroundAxis(ang:Right(), 90)
    self.explodeSheet:SetAngles(ang)
    
    if not self.snd or not self.snd:IsValid() then return end
    self.snd:SetPos(self:GetPos())

    -- Don't play the sound if the player is past the fade distance
    --
    if LocalPlayer():GetPos():Distance(self:GetPos()) > 512 then
        self.snd:SetVolume(0)
    else
        self.snd:SetVolume(1)
    end
end

-- when pressed too many times
--
net.Receive('fumo_ren.explode', function()
    local self = net.ReadEntity()
    
    self:SetNoDraw(true)
    self.explodeSheet:SetNoDraw(false)
    if self.snd:IsValid() then self.snd:Stop() end 
    self:EmitSound("explosion.mp3", 75, 100, 1, CHAN_ITEM)
end)
