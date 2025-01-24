if SERVER then
    AddCSLuaFile()
	resource.AddWorkshop("3264814948")
end

DEFINE_BASECLASS("weapon_tttbase")

SWEP.HoldType = "normal"

if CLIENT then
    SWEP.PrintName = "packapunch machine"
    SWEP.Slot = 6

    SWEP.ShowDefaultViewModel = false

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "pack a punch your guns",
    }

    SWEP.Icon = "vgui/ttt/icon_packapunch"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props/cs_office/microwave.mdl"

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

SWEP.drawColor = Color(180, 180, 250, 255)

---
-- @ignore
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if SERVER then
        local machine = ents.Create("ttt2_packapunch")

        if machine:ThrowEntity(self:GetOwner(), Angle(90, -90, 0)) then
            self:Remove()
        end
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
        self:AddTTT2HUDHelp("drop it with mouse 1")
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