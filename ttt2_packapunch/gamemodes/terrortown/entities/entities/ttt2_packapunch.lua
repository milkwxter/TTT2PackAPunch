if SERVER then
    AddCSLuaFile()
	util.AddNetworkString("ttt2_update_client_packapunch")
end

DEFINE_BASECLASS("ttt_base_placeable")

if CLIENT then
    ENT.Icon = "packapunch"
    ENT.PrintName = "Deployable Pack-A-Punch Machine"
end

ENT.Base = "ttt_base_placeable"
ENT.Model = "models/codwaw/other/perkmachine_pack-a-punch.mdl"

ENT.CanHavePrints = true
ENT.NextUse = 0

local myMat = "models/XQM/LightLinesRed_tool"

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
		-- get necessary variables
		local viewModel = LocalPlayer():GetViewModel()
		local weapon = LocalPlayer():GetActiveWeapon()
		local materials = viewModel:GetMaterials()
		
		-- for each material in the viewmodel, do something
		for index, material in ipairs(materials) do
			-- make sure hands are always drawn normally
			if material == "models/weapons/v_models/hands/v_hands" then
				viewModel:SetSubMaterial(index - 1, "")
				continue
			end
			-- make sure materials set not to draw... dont draw
			if Material(material):GetString("$nodraw") == "1" then
				viewModel:SetSubMaterial(index - 1, "")
				continue
			end
			-- otherwise, overwrite the current material
			viewModel:SetSubMaterial(index - 1, mat)
		end
	end
	
	hook.Add("Think", "CheckPAPChange", function()
		-- get thinking player
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		
		-- get his weapon
		local weapon = ply:GetActiveWeapon()
		if not IsValid(weapon) then return end
		
		-- every frame, update his viewmodel... not the best solution i know
		if weapon:GetNWBool( "IsPackAPunched" ) then
			PAPViewmodel(myMat)
		else
			PAPViewmodel("")
		end
    end)
	
	net.Receive("ttt2_update_client_packapunch", function()
		-- get player the message was sent to
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

		-- get his weapon
        local weapon = ply:GetActiveWeapon()
        if not IsValid(weapon) then return end
		
		-- update the automaticness client side
		if not weapon.Primary.Automatic then
			weapon.Primary.Automatic = true
		end
		
		-- update the tracer too for the client
		weapon.Tracer = "pap_lasertracer"
    end)
	
end

function ENT:PackAPunchWeapon(ply)
	-- store the weapon that just got packapunched
	local wepToPack = ply:GetActiveWeapon()
	
	if wepToPack:GetNWBool( "IsPackAPunched" ) then return end
	
	-- update the networked variable (which updates the viewmodel)
	wepToPack:SetNWBool( "IsPackAPunched", true )
	
	-- update the whole world model
	wepToPack:SetMaterial(myMat)
	
	-- tell him he packapunched
	ply:PrintMessage(HUD_PRINTTALK, "You just used the packapunch")
	
	-- update weapon stats
	wepToPack.Primary.Delay = wepToPack.Primary.Delay * 0.75
	wepToPack.Primary.Sound = Sound("custom_sounds/pap_shot.wav")
	wepToPack.Primary.Automatic = true
	wepToPack.Tracer = "pap_lasertracer"
	
	-- tell client to update some stuff on his end with a net message
	net.Start("ttt2_update_client_packapunch")
	net.Send(ply)
	
	-- do a cool shake
	local shake = ents.Create( "env_shake" )
	shake:SetOwner( ply )
	shake:SetPos( ply:GetPos() )
	shake:SetKeyValue( "amplitude", "4" )
	shake:SetKeyValue( "radius", "80" )
	shake:SetKeyValue( "duration", "1.5" )
	shake:SetKeyValue( "frequency", "255" )
	shake:SetKeyValue( "spawnflags", "4" )
	shake:Spawn()
	shake:Activate()
	shake:Fire( "StartShake", "", 0 )
	
	-- play a sound
	ply:EmitSound("custom_sounds/packapunch.wav")
	
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

    -- handle looking at the machine
    hook.Add("TTTRenderEntityInfo", "HUDDrawTargetIDPackAPunchMachine", function(tData)
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
        tData:SetSubtitle(TryT("Press [E] to upgrade your weapon!"))

        tData:AddDescriptionLine("Pack-A-Punching your gun increases its strength by a ton!", COLOR_GREEN)
		tData:AddDescriptionLine("Machine Health: " .. ent:Health())
    end)
end