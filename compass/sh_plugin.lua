local PLUGIN = PLUGIN

PLUGIN.name = "Compass"
PLUGIN.author = "DobryshDobrysh"
PLUGIN.description = "Plugin, that adds compass on your server."

if CLIENT then
    local compassEnabled = false
    local compassPanel = nil
    local keyPressed = false
    local hooksRegistered = false
    local compassMat = Material("MilSim/compass.png")
    local northPoint = Vector(16000, 0, 0) 
    local textureOffset = 0 

    local function HasCompass()
        local ply = LocalPlayer()
        if not IsValid(ply) then return false end
        
        local character = ply:GetCharacter()
        if not character then return false end
        
        local inventory = character:GetInventory()
        if not inventory then return false end
        
        return inventory:HasItem("compass") or ply:GetActiveWeapon():GetClass() == "ix_compass"
    end

    local function CreateCompass()
        if IsValid(compassPanel) then return end

        compassPanel = vgui.Create("DPanel")
        compassPanel:SetSize(500, 500)
        compassPanel:SetPos(ScrW() - 500 - 20, ScrH() - 500 - 20)
        compassPanel:SetBackgroundColor(Color(0, 0, 0, 0))
        compassPanel:SetMouseInputEnabled(false)

        compassPanel.Paint = function(self, w, h)
            local ply = LocalPlayer()
            if not IsValid(ply) or not HasCompass() then
                if compassEnabled then
                    compassEnabled = false
                    self:Remove()
                end
                return
            end
            
            local playerPos = ply:GetPos()
            local direction = (northPoint - playerPos):GetNormalized()
            local angle = math.deg(math.atan2(direction.y, direction.x))
            local playerYaw = ply:EyeAngles().y
            local finalAngle = angle - playerYaw + textureOffset
            
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(compassMat)
            
            local centerX, centerY = w/2, h/2
            surface.DrawTexturedRectRotated(centerX, centerY, w, h, finalAngle)
        end
    end

    local function ToggleCompass()
        if not HasCompass() then
            if compassEnabled then
                compassEnabled = false
                if IsValid(compassPanel) then
                    compassPanel:Remove()
                end
            end
            return
        end

        compassEnabled = not compassEnabled
        
        if compassEnabled then
            CreateCompass()
            ix.chat.Send(LocalPlayer(), "me", "Takes compass in his hand. After opening it, - looks at it`s dial.")
        else
            if IsValid(compassPanel) then
                compassPanel:Remove()
            end
            ix.chat.Send(LocalPlayer(), "me", "Puts his compass back in his pocket.")
        end
    end

    local function RegisterHooks()
        if hooksRegistered then return end
        hooksRegistered = true

        hook.Add("Think", "CompassKeyCheck", function()
            if input.IsKeyDown(KEY_K) and not keyPressed then
                keyPressed = true
                ToggleCompass()
            elseif not input.IsKeyDown(KEY_K) then
                keyPressed = false
            end
        end)
    end

    hook.Add("InitPostEntity", "CompassInit", function()
        timer.Simple(1, function()
            if not IsValid(LocalPlayer()) then return end
            RegisterHooks()
        end)
    end)

    hook.Add("OnEntityCreated", "CompassPlayerCheck", function(ent)
        if IsValid(ent) and ent == LocalPlayer() then
            timer.Simple(0.5, RegisterHooks)
        end
    end)
end

function PLUGIN:OnUnloaded()
    if CLIENT then
        if IsValid(compassPanel) then
            compassPanel:Remove()
        end
        hook.Remove("Think", "CompassKeyCheck")
        hook.Remove("InitPostEntity", "CompassInit")
        hook.Remove("OnEntityCreated", "CompassPlayerCheck")
    end
end