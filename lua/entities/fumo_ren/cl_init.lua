include("shared.lua")

function ENT:Initialize()

    -- Create the sound the plush will make when used
    --
    self.snd = nil
    sound.PlayFile('sound/ren.mp3', '3d noplay noplay', function(snd, err, errtxt)
        if err then print(err,errtxt,"\nIf you are seeing this, please let ByakuyaKuchiki know!") end

        if snd then
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

    self.dt = FrameTime()
    self.duration = 0.5
    self.maxreps = math.floor(self.duration / self.dt)
    self.currep = self.maxreps --setting it the this in the init so it doesn't play the animation on first spawn
end

function ENT:Draw()
    self:DrawModel()
end

-- Remove the think hook for the audio and remove the clientide model
--
function ENT:OnRemove()
    self.explodeSheet:Remove()
    if self.snd and self.snd:IsValid() then self.snd:Stop() end 
end

-- play the sound and animation
--
net.Receive('fumo_ren.onUse', function()
    local self = net.ReadEntity()
    if not self or not self:IsValid() then return end

    local p = net.ReadFloat()
    if self.snd or self.snd:IsValid() then 
        self.snd:SetPlaybackRate(1+p)
        self.snd:SetTime(0)
        self.snd:Play()
    end
    self.currep = 0
end)

function ENT:Think()
    if not self or not self:IsValid() then return end

    if self.currep <= self.maxreps then
        self.currep = self.currep + 1

        local repsleft = self.maxreps - self.currep
        local elapsedtime = (self.maxreps - repsleft) * self.dt
        local t = 1-(self.duration-elapsedtime) / self.duration

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
    if self.explodeSheet and self.explodeSheet:isValid() then
        local dir = (EyePos() - self:GetPos()):GetNormalized()
        local ang = dir:Angle()
        ang:RotateAroundAxis(ang:Right(), 90)
        self.explodeSheet:SetAngles(ang)
    end
    
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
    if not self or not self:IsValid() then return end
    
    self:SetNoDraw(true)
    self.explodeSheet:SetNoDraw(false)
    if self.snd:IsValid() then self.snd:Stop() end 
    self:EmitSound("explosion.mp3", 75, 100, 1, CHAN_ITEM)
end)
