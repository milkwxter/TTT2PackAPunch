if SERVER then
    AddCSLuaFile()
	util.AddNetworkString("ttt2_update_viewmodel_packapunch")
end

DEFINE_BASECLASS("ttt_base_placeable")

if CLIENT then
    ENT.Icon = "packapunch"
    ENT.PrintName = "packapunch machine"
end

ENT.Base = "ttt_base_placeable"
ENT.Model = "models/props_c17/tv_monitor01.mdl"

ENT.CanHavePrints = true
ENT.NextUse = 0

local myMat = "customtextures/packapunch"

function ENT:Initialize()
    self:SetModel(self.Model)

    BaseClass.Initialize(self)

    local b = 32

    self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b, b, b))

    if SERVER then
        self:SetMaxHealth(100)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(200)
        end

        self:SetUseType(SIMPLE_USE)
    end

    self:SetHealth(100)
    self:SetColor(Color(250, 250, 250, 255))

    self.NextUse = 0
    self.fingerprints = {}
end

if CLIENT then
	function PAPViewmodel(mat)
		local viewModel = LocalPlayer():GetViewModel()
		local weapon = LocalPlayer():GetActiveWeapon()
		local materials = viewModel:GetMaterials()
		for index, material in ipairs(materials) do
			if material == "models/weapons/v_models/hands/v_hands" then
				-- make sure hands are always clean
				viewModel:SetSubMaterial(index - 1, "")
				continue
			end
			viewModel:SetSubMaterial(index - 1, mat)
		end
	end
	
	hook.Add("Think", "CheckPAPChange", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end -- Ensure the player is valid
		
		local weapon = ply:GetActiveWeapon()
		if not IsValid(weapon) then return end -- Ensure the weapon is valid
		
		if weapon:GetNWBool( "IsPackAPunched" ) then
			PAPViewmodel(myMat)
		else
			PAPViewmodel("")
		end
    end)
end

-- Hook to apply the tracer effect during bullet firing
hook.Add("EntityFireBullets", "ApplyCustomPAPTracerEffect", function(ent, data)
    if ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) then
        local weapon = ent:GetActiveWeapon()
		if not weapon:GetNWBool( "IsPackAPunched" ) then return end
        data.TracerName = "pap_lasertracer"
    end
end)

function ENT:PackAPunchWeapon(ply)
	-- store the weapon that just got packapunched
	local wepToPack = ply:GetActiveWeapon()
	
	-- update the networked variable (which updates the viewmodel)
	wepToPack:SetNWBool( "IsPackAPunched", true )
	
	-- update the whole world model
	wepToPack:SetMaterial(myMat)
	
	-- tell him he packapunched
	ply:PrintMessage(HUD_PRINTTALK, "You just used the packapunch")
	
	-- update weapon stats
	wepToPack.Primary.Delay = wepToPack.Primary.Delay * 0.75
	wepToPack.Primary.Sound = Sound("custom_sounds/pap_shot.wav")
	wepToPack.Tracer = "pap_lasertracer" -- DOES NOT WORK YET
	
	-- leave function
	return true
end

if SERVER then
    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() or not ply:IsActive() then
            return
        end

        local t = CurTime()
        if t < self.NextUse then
            return
        end

        local user = self:PackAPunchWeapon(ply)

        self.NextUse = t + 1
    end
else
    local TryT = LANG.TryTranslation
    local ParT = LANG.GetParamTranslation

    local key_params = {
        usekey = Key("+use", "USE"),
        walkkey = Key("+walk", "WALK"),
    }
	
    function ENT:ClientUse()
        local client = LocalPlayer()

        if not IsValid(client) or not client:IsPlayer() or not client:IsActive() then
            return true
        end
    end

    -- handle looking at armor bag
    hook.Add("TTTRenderEntityInfo", "HUDDrawTargetIDArmorBag", function(tData)
        local client = LocalPlayer()
        local ent = tData:GetEntity()

        if
            not IsValid(client)
            or not client:IsTerror()
            or not client:Alive()
            or not IsValid(ent)
            or tData:GetEntityDistance() > 100
            or ent:GetClass() ~= "ttt2_packapunch"
        then
            return
        end

        -- enable targetID rendering
        tData:EnableText()
        tData:EnableOutline()
        tData:SetOutlineColor(client:GetRoleColor())

        tData:SetTitle(TryT(ent.PrintName))
        tData:SetSubtitle(TryT("press [e]"))

        tData:AddDescriptionLine("Use me to packapunch your gun")
    end)
end