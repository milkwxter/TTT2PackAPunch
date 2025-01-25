if SERVER then
    AddCSLuaFile()
	resource.AddWorkshop("3264814948")
end

DEFINE_BASECLASS("weapon_tttbase")

SWEP.HoldType = "normal"

if CLIENT then
    SWEP.PrintName = "Pack-A-Punch Machine"
    SWEP.Slot = 6

    SWEP.ShowDefaultViewModel = false

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Deploy this machine to Pack-A-Punch your guns! Be careful though, it will EXPLODE when destroyed!",
    }

    SWEP.Icon = "materials/milkwaters_icons/vgui/ttt/icon_packapunch.png"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/codwaw/other/perkmachine_pack-a-punch.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.0

-- This is special equipment
SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = { ROLE_DETECTIVE } -- only detectives can buy
SWEP.LimitedStock = false -- only buyable once
SWEP.WeaponID = AMMO_HEALTHSTATION

SWEP.AllowDrop = false
SWEP.NoSights = true

SWEP.drawColor = Color(255, 255, 255, 255)

---
-- @ignore
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if SERVER then
		-- create the entity
        local machine = ents.Create("ttt2_packapunch")
		local owner = self:GetOwner()
		local angles = owner:EyeAngles()
		if machine:ThrowEntity(self:GetOwner(), Angle(90, 0, 0)) then
            self:Remove()
			machine:EmitSound("custom_sounds/pack_jingle.wav")
        end
		
		-- remove weapon
		self:Remove()
    end
end

---
-- @ignore
function SWEP:Reload()
    return false
end

---
-- @realm shared
function SWEP:Initialize()
    if CLIENT then
        self:AddTTT2HUDHelp("Deploy the machine")
    end

    self:SetColor(self.drawColor)

    return BaseClass.Initialize(self)
end

if CLIENT then
    function SWEP:DrawWorldModel()
        if IsValid(self:GetOwner()) then
            return
        end

        self:DrawModel()
    end
	
    function SWEP:DrawWorldModelTranslucent() end
end