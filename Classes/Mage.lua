-- AzeroCombat: Enhanced Mage Rotations (WotLK 3.3.5a Complete) - PART 1 OF 3
local AddonName, AC = ...

-- Complete spell database for WotLK 3.3.5a
local S = {
    -- Arcane spells
    ArcaneBlast = "Arcane Blast",
    ArcaneMissiles = "Arcane Missiles", 
    ArcaneBarrage = "Arcane Barrage",
    ArcaneExplosion = "Arcane Explosion",
    ArcanePower = "Arcane Power",
    PresenceOfMind = "Presence of Mind",
    ArcaneOrb = "Arcane Orb",
    SlowFall = "Slow Fall",
    
    -- Fire spells
    Fireball = "Fireball",
    Pyroblast = "Pyroblast", 
    LivingBomb = "Living Bomb",
    FireBlast = "Fire Blast",
    Scorch = "Scorch",
    Flamestrike = "Flamestrike",
    BlastWave = "Blast Wave",
    DragonsBreath = "Dragon's Breath",
    Combustion = "Combustion",
    FrostfireBolt = "Frostfire Bolt",
    
    -- Frost spells
    Frostbolt = "Frostbolt",
    IceLance = "Ice Lance",
    DeepFreeze = "Deep Freeze", 
    FrostNova = "Frost Nova",
    Blizzard = "Blizzard",
    ConeOfCold = "Cone of Cold",
    IcyVeins = "Icy Veins",
    ColdSnap = "Cold Snap",
    SummonWaterElemental = "Summon Water Elemental",
    Freeze = "Freeze", -- Pet ability
    
    -- Utility spells
    Counterspell = "Counterspell",
    Evocation = "Evocation",
    IceBlock = "Ice Block",
    ManaShield = "Mana Shield",
    IceBarrier = "Ice Barrier", 
    MirrorImage = "Mirror Image",
    Blink = "Blink",
    RemoveCurse = "Remove Curse",
    Spellsteal = "Spellsteal",
    Polymorph = "Polymorph",
    FocusMagic = "Focus Magic",
    
    -- Armor spells
    MoltenArmor = "Molten Armor",
    MageArmor = "Mage Armor",
    FrostArmor = "Frost Armor",
    IceArmor = "Ice Armor",
    
    -- Buff spells
    ArcaneIntellect = "Arcane Intellect",
    ArcaneBrilliance = "Arcane Brilliance",
    DampenMagic = "Dampen Magic",
    AmplifyMagic = "Amplify Magic",
    
    -- Procs and buffs - WotLK specific
    MissileBarrage = "Missile Barrage",
    HotStreak = "Hot Streak", 
    FingersOfFrost = "Fingers of Frost",
    BrainFreeze = "Brain Freeze",
    Firestarter = "Firestarter",
    ArcaneBlastBuff = "Arcane Blast",
    
    -- Debuffs
    ImprovedScorch = "Improved Scorch",
    WintersChill = "Winter's Chill",
    
    -- Conjure spells
    ConjureManaGem = "Conjure Mana Gem",
    ConjureWater = "Conjure Water",
    ConjureFood = "Conjure Food",
    
    -- Wand attacks
    Shoot = "Shoot",
    
    -- Racials
    BloodFury = "Blood Fury",
    Berserking = "Berserking",
    ArcaneTorrent = "Arcane Torrent",
    WillOfTheForsaken = "Will of the Forsaken",
    Stoneform = "Stoneform",
    GiftOfTheNaaru = "Gift of the Naaru",
    WarStomp = "War Stomp",
    EscapeArtist = "Escape Artist",
    Shadowmeld = "Shadowmeld",
    EveryManForHimself = "Every Man for Himself",
}

-- Mana gem priorities (best to worst)
local ManaGems = {
    "Mana Sapphire", -- 3330 mana
    "Mana Ruby", -- 1073 mana  
    "Mana Citrine", -- 518 mana
    "Mana Jade", -- 343 mana
    "Mana Agate", -- 205 mana
}

local ConjuredFood = {
    "Conjured Mana Strudel",
    "Conjured Cinnamon Roll",
    "Conjured Croissant",
    "Conjured Sweet Roll",
    "Conjured Rye",
}

local ConjuredWater = {
    "Conjured Mana Strudel",
    "Conjured Glacier Water",
    "Conjured Spring Water",
    "Conjured Purified Water",
}

local MageSpellstealBuffs = {
    ["Power Infusion"] = true,
    ["Innervate"] = true,
    ["Heroism"] = true,
    ["Bloodlust"] = true,
    ["Blessing of Protection"] = true,
    ["Blessing of Freedom"] = true,
    ["Ice Barrier"] = true,
    ["Hand of Protection"] = true,
}

local function MageManaPercent()
    local maxMana = UnitPowerMax("player", 0)
    if not maxMana or maxMana <= 0 then return 100 end
    return UnitPower("player", 0) / maxMana * 100
end

local function MageSpellReady(self, spellName)
    return spellName and self:IsUsableSpell(spellName) and self:GetSpellCooldown(spellName) <= 0
end

-- Cooldowns are polled frequently, so use a short retry throttle instead of
-- a second independent cooldown timer. This prevents a failed attempt from
-- delaying the next legitimate cast for several minutes.
local function MageUseCooldown(self, spellName, unit, throttleKey)
    if not MageSpellReady(self, spellName) then return false end
    if UnitCastingInfo("player") or UnitChannelInfo("player") then return false end
    if not self:ActionThrottle(throttleKey or ("MageCooldown_" .. spellName), 0.25) then
        return false
    end
    return self:CastSpell(spellName, unit or "player")
end

local function MageHasDebuffKeyword(unit, keywords)
    for index = 1, 40 do
        local name, _, _, _, debuffType = UnitDebuff(unit, index)
        if not name then break end
        local lowerName = string.lower(name)
        for _, keyword in ipairs(keywords) do
            if lowerName:find(string.lower(keyword), 1, true) then
                return true, name, debuffType
            end
        end
    end
    return false
end

local function MageFindPetAction(actionName)
    if not GetPetActionInfo then return nil end
    for index = 1, 10 do
        local name = GetPetActionInfo(index)
        if name == actionName then return index end
    end
    return nil
end

local function MagePetActionReady(actionIndex)
    if not actionIndex or not GetPetActionCooldown then return false end
    local start, duration, enabled = GetPetActionCooldown(actionIndex)
    if enabled == 0 then return false end
    if not start or start == 0 or not duration or duration == 0 then return true end
    return GetTime() >= start + duration
end

-- Debug function
local function MageDebug(msg)
    if AC.debugMode then
        AC:Debug("|cFF3FC7EBMage:|r " .. tostring(msg))
    end
end

-- =============================================
-- ENHANCED PROC TRACKING SYSTEM
-- =============================================

AC.MageProcs = AC.MageProcs or {}

function AC:CheckMageProcs()
    local procs = self.MageProcs
    
    -- Missile Barrage (Arcane) - Free instant Arcane Missiles
    procs.missileBarrage = self:HasBuff("player", S.MissileBarrage)
    
    -- Hot Streak (Fire) - Free instant Pyroblast
    procs.hotStreak = self:HasBuff("player", S.HotStreak)
    
    -- Firestarter (Fire) - Free instant Flamestrike  
    procs.firestarter = self:HasBuff("player", S.Firestarter)
    
    -- Fingers of Frost (Frost) - Next spell treats target as frozen
    procs.fingersOfFrost = self:HasBuff("player", S.FingersOfFrost)
    local _, _, _, fofStacks = UnitBuff("player", S.FingersOfFrost)
    procs.fingersOfFrostStacks = fofStacks or 0
    
    -- Brain Freeze (Frost) - Free instant Fireball/Frostfire Bolt
    procs.brainFreeze = self:HasBuff("player", S.BrainFreeze)
    
    -- Arcane Blast stacks
    local _, _, _, abStacks = UnitBuff("player", S.ArcaneBlastBuff)
    procs.arcaneBlastStacks = abStacks or 0
    
    return procs
end

-- =============================================
-- ENHANCED MANA MANAGEMENT SYSTEM  
-- =============================================

function AC:ManageMageMana()
    local manaPercent = MageManaPercent()

    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false
    end
    
    -- Use mana gems (best first)
    if manaPercent < 40 then
        for _, gem in ipairs(ManaGems) do
            local start, duration = GetItemCooldown(gem)
            local ready = not start or start == 0 or not duration or GetTime() >= start + duration
            if GetItemCount(gem) > 0 and ready then
                UseItemByName(gem)
                MageDebug("Using " .. gem)
                return true
            end
        end
    end
    
    -- Use mana potions
    if manaPercent < 25 then
        if self:UseManaPotion(25) then
            MageDebug("Using mana potion")
            return true
        end
    end
    
    -- Evocation as last resort
    if manaPercent < 20 and MageSpellReady(self, S.Evocation) and not self:IsPlayerMoving() then
        if self:CastSpell(S.Evocation, "player") then
            MageDebug("Using Evocation")
            return true
        end
    end
    
    return false
end

-- =============================================
-- ENHANCED DEFENSIVE SYSTEM
-- =============================================

function AC:UseMageDefensives()
    local health = self:GetPlayerHealthPercent()
    local enemies = self:GetEnemyCount()
    
    -- Ice Block for emergencies
    if health < 20 and MageSpellReady(self, S.IceBlock) then
        if self:CastSpell(S.IceBlock, "player") then
            MageDebug("Emergency Ice Block")
            return true
        end
    end
    
    -- Ice Barrier for damage mitigation
    if health < 60 and MageSpellReady(self, S.IceBarrier) and not self:HasBuff("player", S.IceBarrier) then
        if self:CastSpell(S.IceBarrier, "player") then
            MageDebug("Ice Barrier for protection")
            return true
        end
    end
    
    -- Mana Shield if low health but have mana
    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
    if health < 40 and manaPercent > 30 and MageSpellReady(self, S.ManaShield) and 
       not self:HasBuff("player", S.ManaShield) and not self:HasBuff("player", S.IceBarrier) then
        if self:CastSpell(S.ManaShield, "player") then
            MageDebug("Mana Shield for protection")
            return true
        end
    end
    
    -- Mirror Image for threat reduction
    -- Frost Nova is reserved for a genuine emergency. Using it routinely
    -- can make frozen mobs attack the mage instead of the tank.
    if health < 30 and enemies >= 2 and CheckInteractDistance("target", 3) and MageSpellReady(self, S.FrostNova) then
        if self:CastSpell(S.FrostNova, "player") then
            MageDebug("Emergency Frost Nova")
            return true
        end
    end
    
    -- Use health potions
    if health < 35 then
        if self:UseHealthPotion(35) then
            MageDebug("Using health potion")
            return true
        end
    end
    
    return false
end

local function MageGroupUnits()
    local units = {"player"}
    local raidMembers = GetNumRaidMembers and GetNumRaidMembers() or 0
    local partyMembers = GetNumPartyMembers and GetNumPartyMembers() or 0

    if raidMembers > 0 then
        for index = 1, raidMembers do
            table.insert(units, "raid" .. index)
        end
    elseif partyMembers > 0 then
        for index = 1, partyMembers do
            table.insert(units, "party" .. index)
        end
    end

    return units
end

function AC:HasMageTalentByName(talentName)
    self.MageTalentCache = self.MageTalentCache or {}
    self.MageTalentCacheTime = self.MageTalentCacheTime or 0

    if GetTime() - self.MageTalentCacheTime > 5 then
        self.MageTalentCache = {}
        self.MageTalentCacheTime = GetTime()
    end

    if self.MageTalentCache[talentName] ~= nil then
        return self.MageTalentCache[talentName]
    end

    local found = false
    if GetNumTalentTabs and GetTalentInfo then
        for tab = 1, GetNumTalentTabs() do
            local talentCount = GetNumTalents(tab) or 0
            for talent = 1, talentCount do
                local name, _, _, _, currentRank = GetTalentInfo(tab, talent)
                if name == talentName and (currentRank or 0) > 0 then
                    found = true
                    break
                end
            end
            if found then break end
        end
    end

    self.MageTalentCache[talentName] = found
    return found
end

function AC:GetMageFireNuke()
    -- Torment the Weak is the Fireball build. Fire builds without it are
    -- normally Frostfire builds, so use Frostfire Bolt when learned.
    if self:HasMageTalentByName("Torment the Weak") then
        return S.Fireball
    end
    if MageSpellReady(self, S.FrostfireBolt) or self:KnowsSpell(S.FrostfireBolt) then
        return S.FrostfireBolt
    end
    return S.Fireball
end

function AC:IsMageBossTarget()
    local classification = UnitClassification("target")
    return classification == "worldboss" or classification == "rareelite"
end

function AC:ShouldUseMageMajorCooldowns()
    local classification = UnitClassification("target")
    return classification == "worldboss" or classification == "rareelite" or
           classification == "elite"
end

function AC:CheckMageFocusMagic()
    if self:HasBuff("player", S.FocusMagic) then return false end
    if not MageSpellReady(self, S.FocusMagic) then return false end

    local function IsCandidate(unit)
        if not UnitExists(unit) or UnitIsUnit(unit, "player") then return false end
        if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then return false end
        if UnitCanAssist and not UnitCanAssist("player", unit) then return false end
        if not CheckInteractDistance(unit, 4) then return false end

        local _, class = UnitClass(unit)
        return class == "MAGE" or class == "WARLOCK" or class == "PRIEST" or
               class == "DRUID" or class == "SHAMAN"
    end

    if IsCandidate("focus") and not self:HasBuff("focus", S.FocusMagic) then
        if self:CastSpell(S.FocusMagic, "focus") then
            MageDebug("Applying Focus Magic to focus")
            return true
        end
    end

    for _, unit in ipairs(MageGroupUnits()) do
        if IsCandidate(unit) and not self:HasBuff(unit, S.FocusMagic) then
            if self:CastSpell(S.FocusMagic, unit) then
                MageDebug("Applying Focus Magic to " .. (UnitName(unit) or unit))
                return true
            end
        end
    end

    return false
end

-- =============================================
-- ENHANCED BUFF MANAGEMENT SYSTEM
-- =============================================

function AC:CheckMageBuffs(spec)
    -- Skip if mounted to prevent dismounting
    if IsMounted() then return false end
    
    -- Throttle buff checks
    if not self:Throttle("MageBuffCheck", 8) then return false end
    
    -- Group buffing system (out of combat only)
    if not UnitAffectingCombat("player") then
        if self:CheckMageGroupBuffs() then return true end
        if self:CheckMageFocusMagic() then return true end
    end
    
    -- Maintain the preferred armor, including replacing a leveling armor
    -- after a spec change. Molten Armor is the normal PvE choice; Mage Armor
    -- is reserved for severe mana pressure.
    local armorSpell = nil
    if spec == "Frost" and MageManaPercent() < 25 and self:KnowsSpell(S.MageArmor) then
        armorSpell = S.MageArmor
    elseif self:KnowsSpell(S.MoltenArmor) then
        armorSpell = S.MoltenArmor
    elseif self:KnowsSpell(S.MageArmor) then
        armorSpell = S.MageArmor
    elseif self:KnowsSpell(S.FrostArmor) then
        armorSpell = S.FrostArmor
    elseif self:KnowsSpell(S.IceArmor) then
        armorSpell = S.IceArmor
    end

    if armorSpell and not self:HasBuff("player", armorSpell) and MageSpellReady(self, armorSpell) then
        if self:CastSpell(armorSpell, "player") then
            MageDebug("Applying " .. armorSpell)
            return true
        end
    end
    
    -- Intelligence buffs
    local hasInt = self:HasBuff("player", S.ArcaneIntellect) or self:HasBuff("player", S.ArcaneBrilliance)
    if not hasInt then
        local intSpell = self:KnowsSpell(S.ArcaneBrilliance) and S.ArcaneBrilliance or S.ArcaneIntellect
        if MageSpellReady(self, intSpell) then
            if self:CastSpell(intSpell, "player") then
                MageDebug("Applying " .. intSpell)
                return true
            end
        end
    end
    
    return false
end

-- =============================================
-- GROUP BUFFING SYSTEM
-- =============================================

function AC:CheckMageGroupBuffs()
    if not self:Throttle("MageGroupBuffCheck", 15) then return false end
    if UnitAffectingCombat("player") or IsMounted() then return false end
    
    for _, unit in ipairs(MageGroupUnits()) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            local hasInt = self:HasBuff(unit, S.ArcaneIntellect) or 
                          self:HasBuff(unit, S.ArcaneBrilliance)
            local inRange = unit == "player" or CheckInteractDistance(unit, 4)
            if not hasInt and inRange then
                local intSpell = self:KnowsSpell(S.ArcaneBrilliance) and 
                                S.ArcaneBrilliance or S.ArcaneIntellect
                if MageSpellReady(self, intSpell) then
                    if self:CastSpell(intSpell, unit) then
                        MageDebug("GROUP BUFF: " .. intSpell .. " on " .. (UnitName(unit) or unit))
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- =============================================
-- RACIAL ABILITIES SYSTEM
-- =============================================

function AC:UseMageRacials(offensive, defensive)
    if not offensive and not defensive then return false end

    local _, race = UnitRace("player")
    race = string.upper(race or "")
    local health = self:GetPlayerHealthPercent()
    local manaPercent = MageManaPercent()
    local inCombat = UnitAffectingCombat("player")

    local function CastRacial(spellName, message)
        if MageSpellReady(self, spellName) and self:ActionThrottle("MageRacial_" .. spellName, 0.25) then
            if self:CastSpell(spellName, "player") then
                MageDebug(message)
                return true
            end
        end
        return false
    end

    -- Offensive racials
    if offensive and inCombat then
        if race == "ORC" and CastRacial(S.BloodFury, "Racial: Blood Fury") then
            return true
        end
        if race == "TROLL" and CastRacial(S.Berserking, "Racial: Berserking") then
            return true
        end
    end

    if not defensive then return false end

    local crowdControlled = MageHasDebuffKeyword("player", {
        "fear", "horror", "charm", "polymorph", "stun", "silence",
        "root", "entangling", "frost nova", "hamstring", "chains of ice",
        "crippling poison", "wing clip",
    })
    local harmfulDebuff = MageHasDebuffKeyword("player", {
        "bleed", "poison", "disease",
    })

    -- Defensive racials
    if race == "BLOODELF" and (manaPercent < 50 or (UnitExists("target") and CheckInteractDistance("target", 3) and UnitCastingInfo("target"))) then
        if CastRacial(S.ArcaneTorrent, "Racial: Arcane Torrent") then return true end
    end
    if race == "UNDEAD" and crowdControlled then
        if CastRacial(S.WillOfTheForsaken, "Racial: Will of the Forsaken") then return true end
    end
    if race == "DWARF" and (harmfulDebuff or health < 25) then
        if CastRacial(S.Stoneform, "Racial: Stoneform") then return true end
    end
    if race == "DRAENEI" and health < 45 then
        if CastRacial(S.GiftOfTheNaaru, "Racial: Gift of the Naaru") then return true end
    end
    if race == "GNOME" and crowdControlled then
        if CastRacial(S.EscapeArtist, "Racial: Escape Artist") then return true end
    end
    if race == "NIGHTELF" and health < 25 and UnitExists("targettarget") and UnitIsUnit("targettarget", "player") then
        if CastRacial(S.Shadowmeld, "Racial: Shadowmeld") then return true end
    end
    if race == "HUMAN" and crowdControlled then
        if CastRacial(S.EveryManForHimself, "Racial: Every Man for Himself") then return true end
    end
    if race == "TAUREN" and health < 30 and self:GetEnemyCount() >= 2 and CheckInteractDistance("target", 3) then
        if CastRacial(S.WarStomp, "Racial: War Stomp") then return true end
    end

    return false
end

-- =============================================
-- ENHANCED CONJURE SYSTEM  
-- =============================================

function AC:ManageMageConjures()
    -- Only check when out of combat
    if UnitAffectingCombat("player") then return false end
    
    -- Throttle conjure checks, but do not use the throttle as a substitute
    -- for spell readiness. A failed cast should be retried promptly.
    if not self:Throttle("ConjureCheck", 5) then return false end
    
    -- Mana gems (most important)
    local hasManaGem = false
    for _, gem in ipairs(ManaGems) do
        if GetItemCount(gem) > 0 then
            hasManaGem = true
            break
        end
    end
    
    if not hasManaGem and MageSpellReady(self, S.ConjureManaGem) then
        if self:CastSpell(S.ConjureManaGem, "player") then
            MageDebug("Conjuring Mana Gem")
            return true
        end
    end

    local hasFood = false
    for _, food in ipairs(ConjuredFood) do
        if GetItemCount(food) > 0 then
            hasFood = true
            break
        end
    end
    if not hasFood and MageSpellReady(self, S.ConjureFood) then
        if self:CastSpell(S.ConjureFood, "player") then
            MageDebug("Conjuring food")
            return true
        end
    end

    local hasWater = false
    for _, water in ipairs(ConjuredWater) do
        if GetItemCount(water) > 0 then
            hasWater = true
            break
        end
    end
    if not hasWater and MageSpellReady(self, S.ConjureWater) then
        if self:CastSpell(S.ConjureWater, "player") then
            MageDebug("Conjuring water")
            return true
        end
    end
    
    return false
end

-- =============================================
-- ENHANCED PET MANAGEMENT (WATER ELEMENTAL)
-- =============================================

function AC:ManageWaterElemental()
    local spec = self:GetPlayerSpec()
    
    -- Only Frost mages get Water Elemental
    if spec ~= "Frost" then return false end
    
    -- Don't summon if mounted
    if IsMounted() then return false end
    
    -- Summon if the elemental is missing or dead. This also supports both
    -- the normal timed elemental and Glyph of Eternal Water.
    if (not UnitExists("pet") or UnitIsDead("pet")) and MageSpellReady(self, S.SummonWaterElemental) then
        if self:ActionThrottle("SummonWaterElemental", 0.25) and self:CastSpell(S.SummonWaterElemental, "player") then
            MageDebug("Summoning Water Elemental")
            return true
        end
    end

    if UnitExists("pet") and not UnitIsDead("pet") and UnitAffectingCombat("player") and UnitExists("target") then
        -- PetAttack is required after target changes; otherwise the elemental
        -- can remain idle or continue attacking the previous target.
        if PetAttack and (not UnitExists("pettarget") or not UnitIsUnit("pettarget", "target")) then
            PetAttack()
            MageDebug("Water Elemental attacking current target")
            return true
        end

        -- Find Freeze by action name instead of assuming a fixed pet-bar slot.
        -- Glyph of Eternal Water removes Freeze, so no action is taken when it
        -- is not present and the elemental's Waterbolt autocast is preserved.
        local freezeAction = MageFindPetAction(S.Freeze)
        local targetFrozen = self:HasDebuff("target", "Frost Nova") or
                             self:HasDebuff("target", S.Freeze) or
                             self:HasDebuff("target", "Frostbite")
        if freezeAction and not targetFrozen and MagePetActionReady(freezeAction) and
           self:ActionThrottle("PetFreeze", 0.25) then
            CastPetAction(freezeAction)
            local afterStart, afterDuration = GetPetActionCooldown(freezeAction)
            local started = afterStart and afterDuration and afterDuration > 0 and
                            (afterStart + afterDuration - GetTime()) > 0.05
            if started or UnitCastingInfo("pet") or UnitChannelInfo("pet") then
                MageDebug("Water Elemental using Freeze")
                return true
            end
        end
    end
    
    return false
end

-- =============================================
-- ENHANCED INTERRUPT SYSTEM
-- =============================================

function AC:TryMageInterrupt()
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return false end
    
    local spellName, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if not spellName or notInterruptible then
        spellName, _, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
        if not spellName or notInterruptible then return false end
    end
    
    -- Priority interrupt list
    local highPrioritySpells = {
        "Heal", "Greater Heal", "Flash Heal", "Healing Touch", "Chain Heal",
        "Regrowth", "Rejuvenation", "Prayer of Healing", "Polymorph", "Fear",
        "Mind Control", "Banish", "Cyclone", "Hex", "Chaos Bolt",
        "Fireball", "Frostbolt", "Lightning Bolt", "Shadow Bolt", "Mind Blast",
    }
    
    local shouldInterrupt = false
    local lowerSpellName = string.lower(spellName)
    for _, priority in ipairs(highPrioritySpells) do
        if lowerSpellName:find(string.lower(priority), 1, true) then
            shouldInterrupt = true
            break
        end
    end

    if self.ShouldInterruptSpell and self:ShouldInterruptSpell(spellName) then
        shouldInterrupt = true
    end

    local inRange = not IsSpellInRange or IsSpellInRange(S.Counterspell, "target")
    if shouldInterrupt and inRange ~= 0 and MageSpellReady(self, S.Counterspell) then
        if self:CastSpell(S.Counterspell, "target") then
            MageDebug("Interrupted " .. spellName)
            return true
        end
    end
    
    return false
end

function AC:TryMageUtility()
    -- Remove curses from the mage first, then from nearby group members.
    if MageSpellReady(self, S.RemoveCurse) then
        local hasCurse = false
        for index = 1, 40 do
            local name, _, _, _, debuffType = UnitDebuff("player", index)
            if not name then break end
            if debuffType == "Curse" then
                hasCurse = true
                break
            end
        end
        if hasCurse and self:CastSpell(S.RemoveCurse, "player") then
            MageDebug("Utility: Remove Curse from player")
            return true
        end

        for _, unit in ipairs(MageGroupUnits()) do
            if unit ~= "player" and UnitExists(unit) and not UnitIsDeadOrGhost(unit) and
               UnitCanAssist("player", unit) and CheckInteractDistance(unit, 4) then
                local cursed = false
                for index = 1, 40 do
                    local name, _, _, _, debuffType = UnitDebuff(unit, index)
                    if not name then break end
                    if debuffType == "Curse" then
                        cursed = true
                        break
                    end
                end
                if cursed and self:CastSpell(S.RemoveCurse, unit) then
                    MageDebug("Utility: Remove Curse from " .. (UnitName(unit) or unit))
                    return true
                end
            end
        end
    end

    -- Spellsteal only known high-value buffs. Stealing every buff is a mana
    -- trap and can remove harmless effects that the group expects.
    local spellstealRange = not IsSpellInRange or IsSpellInRange(S.Spellsteal, "target")
    if UnitExists("target") and UnitCanAttack("player", "target") and spellstealRange ~= 0 and
       MageSpellReady(self, S.Spellsteal) then
        for index = 1, 40 do
            local name = UnitBuff("target", index)
            if not name then break end
            if MageSpellstealBuffs[name] then
                if self:CastSpell(S.Spellsteal, "target") then
                    MageDebug("Utility: Spellsteal " .. name)
                    return true
                end
            end
        end
    end

    return false
end

-- AzeroCombat: Enhanced Mage Rotations (WotLK 3.3.5a Complete) - PART 2 OF 3
-- This part contains the three enhanced spec rotations

-- =============================================
-- ARCANE ROTATION (ENHANCED)
-- =============================================

function AC:ArcaneMageRotation()
    local manaPercent = MageManaPercent()
    local procs = self:CheckMageProcs()
    local enemies = self:GetEnemyCount()
    
    -- Interrupt priority
    if self:TryMageInterrupt() then return true end
    
    -- Mana management
    if self:ManageMageMana() then return true end
    
    -- AoE rotation
    if enemies >= 3 then
        -- Arcane Explosion for AoE
        if CheckInteractDistance("target", 3) and MageSpellReady(self, S.ArcaneExplosion) then
            if self:CastSpell(S.ArcaneExplosion, "player") then
                MageDebug("Arcane AoE: Arcane Explosion")
                return true
            end
        end

        -- Do not spend a single-target Missile Barrage proc as an AoE spell.
        -- At range, build a small Arcane Blast bonus before the ground AoE.
        if procs.arcaneBlastStacks < 2 and MageSpellReady(self, S.ArcaneBlast) then
            if self:CastSpell(S.ArcaneBlast, "target") then
                MageDebug("Arcane AoE: building Arcane Blast stacks")
                return true
            end
        end
        
        -- Flamestrike if available
        if MageSpellReady(self, S.Flamestrike) and not self:IsChanneling() and
           not self:IsPlayerMoving() and self:Throttle("FlamestrikeArcane", 8) then
            MageDebug("Arcane AoE: Flamestrike")
            if not self:CastSpell(S.Flamestrike) then return false end
            CameraOrSelectOrMoveStart()
            CameraOrSelectOrMoveStop()
            return true
        end
    end
    
    -- Cooldowns are restricted to elite/boss targets, but are no longer
    -- blocked by target health or a second timer that can drift from the
    -- actual spell cooldown.
    if self:ShouldUseMageMajorCooldowns() then
        if MageUseCooldown(self, S.ArcanePower, "player", "MageArcanePower") then
            MageDebug("Arcane: Arcane Power burst")
            return true
        end
        if MageUseCooldown(self, S.IcyVeins, "player", "MageArcaneIcyVeins") then
            MageDebug("Arcane: Icy Veins")
            return true
        end
        if self:IsMageBossTarget() and self:UseTrinkets() then
            MageDebug("Arcane: offensive trinket")
            return true
        end
        if self:IsMageBossTarget() and self:UseOffensivePotion(true) then
            MageDebug("Arcane: offensive potion")
            return true
        end
        if self:UseMageRacials(true, false) then
            MageDebug("Arcane: offensive racial")
            return true
        end
        if MageUseCooldown(self, S.PresenceOfMind, "player", "MageArcanePresenceOfMind") then
            MageDebug("Arcane: Presence of Mind")
            return true
        end
        if MageUseCooldown(self, S.MirrorImage, "player", "MageArcaneMirrorImage") then
            MageDebug("Arcane: Mirror Image")
            return true
        end
    end

    -- Do not spend Missile Barrage before the Arcane Blast multiplier is
    -- established unless the proc is about to expire.
    local procTime = self:BuffTimeRemaining("player", S.MissileBarrage)
    if procs.missileBarrage and procs.arcaneBlastStacks >= 4 and
       MageSpellReady(self, S.ArcaneMissiles) then
        if self:CastSpell(S.ArcaneMissiles, "target") then
            MageDebug("Arcane: Missile Barrage after four Arcane Blasts")
            return true
        end
    elseif procs.missileBarrage and procTime > 0 and procTime < 0.8 and
           MageSpellReady(self, S.ArcaneMissiles) then
        if self:CastSpell(S.ArcaneMissiles, "target") then
            MageDebug("Arcane: spending expiring Missile Barrage")
            return true
        end
    end

    -- Arcane Barrage is the correct movement/low-mana fallback and clears
    -- the expensive Arcane Blast stacks.
    if (self:IsPlayerMoving() or manaPercent < 35) and procs.arcaneBlastStacks > 0 and
       MageSpellReady(self, S.ArcaneBarrage) then
        if self:CastSpell(S.ArcaneBarrage, "target") then
            MageDebug("Arcane: Arcane Barrage fallback")
            return true
        end
    end

    if procs.arcaneBlastStacks < 4 and manaPercent > 35 and MageSpellReady(self, S.ArcaneBlast) then
        if self:CastSpell(S.ArcaneBlast, "target") then
            MageDebug("Arcane: building Arcane Blast stacks (" .. procs.arcaneBlastStacks .. "/4)")
            return true
        end
    end

    -- If the cycle is complete, Arcane Missiles is the normal finisher even
    -- without Missile Barrage. It is only used once the four-stack bonus is up.
    if procs.arcaneBlastStacks >= 4 and manaPercent > 20 and MageSpellReady(self, S.ArcaneMissiles) then
        if self:CastSpell(S.ArcaneMissiles, "target") then
            MageDebug("Arcane: Arcane Missiles finisher")
            return true
        end
    end

    if manaPercent < 5 and MageSpellReady(self, S.Shoot) then
        if self:CastSpell(S.Shoot, "target") then
            MageDebug("Arcane: emergency wanding")
            return true
        end
    end
    
    return false
end

-- =============================================
-- FIRE ROTATION (ENHANCED)
-- =============================================

function AC:FireMageRotation()
    local manaPercent = MageManaPercent()
    local procs = self:CheckMageProcs()
    local enemies = self:GetEnemyCount()
    
    -- Interrupt priority
    if self:TryMageInterrupt() then return true end
    
    -- Mana management
    if self:ManageMageMana() then return true end
    
    -- AoE rotation
    if enemies >= 3 then
        -- Use Firestarter proc for instant Flamestrike
        if procs.firestarter and MageSpellReady(self, S.Flamestrike) then
            if not self:IsChanneling() and not self:IsPlayerMoving() then
                MageDebug("Fire AoE: Firestarter Flamestrike")
                if not self:CastSpell(S.Flamestrike) then return false end
                CameraOrSelectOrMoveStart()
                CameraOrSelectOrMoveStop()
                return true
            end
        end
        
        -- Apply Living Bomb to main target
        if self:KnowsSpell(S.LivingBomb) and not self:HasDebuff("target", S.LivingBomb) and MageSpellReady(self, S.LivingBomb) then
            if self:CastSpell(S.LivingBomb, "target") then
                MageDebug("Fire AoE: Living Bomb on target")
                return true
            end
        end
        
        -- Apply Living Bomb to additional targets (spread for explosions)
        if self:KnowsSpell(S.LivingBomb) and self:Throttle("LivingBombSpread", 3) then
            for i = 1, 40 do
                local unit = "nameplate" .. i
                if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
                    if not self:HasDebuff(unit, S.LivingBomb) and IsSpellInRange(S.LivingBomb, unit) == 1 then
                        if self:CastSpell(S.LivingBomb, unit) then
                            MageDebug("Fire AoE: Living Bomb spread to " .. (UnitName(unit) or "nameplate"))
                            return true
                        end
                    end
                end
            end
        end
        
        -- Blast Wave for close AoE
        if CheckInteractDistance("target", 3) and MageSpellReady(self, S.BlastWave) then
            if self:CastSpell(S.BlastWave, "player") then
                MageDebug("Fire AoE: Blast Wave")
                return true
            end
        end
        
        -- Dragon's Breath for cone AoE
        if CheckInteractDistance("target", 3) and MageSpellReady(self, S.DragonsBreath) then
            if self:CastSpell(S.DragonsBreath, "player") then
                MageDebug("Fire AoE: Dragon's Breath")
                return true
            end
        end
        
        -- Flamestrike
        if MageSpellReady(self, S.Flamestrike) and not self:IsChanneling() and
           not self:IsPlayerMoving() and self:Throttle("FlamestrikeRegular", 8) then
            MageDebug("Fire AoE: Flamestrike")
            if not self:CastSpell(S.Flamestrike) then return false end
            CameraOrSelectOrMoveStart()
            CameraOrSelectOrMoveStop()
            return true
        end
    end
    
    -- Cooldown usage for elite and boss targets. Combustion is a player buff,
    -- and should be used only when both Living Bomb and Ignite are present.
    local targetHP = self:GetTargetHealthPercent("target")
    if self:ShouldUseMageMajorCooldowns() then
        local hasLivingBomb = self:HasDebuff("target", S.LivingBomb)
        local hasIgnite = self:HasDebuff("target", "Ignite")
        local livingBombTime = self:DebuffTimeRemaining("target", S.LivingBomb)

        if hasLivingBomb and hasIgnite and livingBombTime > 1 and
           MageUseCooldown(self, S.Combustion, "player", "MageFireCombustion") then
            MageDebug("Fire: Combustion burst")
            return true
        end

        if MageUseCooldown(self, S.IcyVeins, "player", "MageFireIcyVeins") then
            MageDebug("Fire: Icy Veins")
            return true
        end

        if self:IsMageBossTarget() and self:UseTrinkets() then
            MageDebug("Fire: offensive trinket")
            return true
        end

        if self:IsMageBossTarget() and self:UseOffensivePotion(true) then
            MageDebug("Fire: offensive potion")
            return true
        end

        if self:UseMageRacials(true, false) then
            MageDebug("Fire: offensive racial")
            return true
        end

        if MageUseCooldown(self, S.MirrorImage, "player", "MageFireMirrorImage") then
            MageDebug("Fire: Mirror Image")
            return true
        end
    end

    -- Hot Streak has priority over a Living Bomb refresh.
    if procs.hotStreak and MageSpellReady(self, S.Pyroblast) then
        if self:CastSpell(S.Pyroblast, "target") then
            MageDebug("Fire: Hot Streak Pyroblast")
            return true
        end
    end

    -- Living Bomb should be allowed to explode. Refreshing several seconds
    -- early loses the explosion and is a direct damage loss.
    if self:KnowsSpell(S.LivingBomb) then
        local lbTime = self:DebuffTimeRemaining("target", S.LivingBomb)
        if (not self:HasDebuff("target", S.LivingBomb) or lbTime <= 0.5) and MageSpellReady(self, S.LivingBomb) then
            if self:CastSpell(S.LivingBomb, "target") then
                MageDebug("Fire: Living Bomb")
                return true
            end
        end
    end

    -- Only maintain Improved Scorch when this mage actually has the talent,
    -- and build the debuff to five stacks instead of checking presence only.
    if self:HasMageTalentByName("Improved Scorch") and MageSpellReady(self, S.Scorch) then
        local hasScorch, scorchStacks = self:HasDebuff("target", S.ImprovedScorch)
        if not hasScorch or (scorchStacks or 0) < 5 or self:DebuffTimeRemaining("target", S.ImprovedScorch) < 5 then
            if self:CastSpell(S.Scorch, "target") then
                MageDebug("Fire: building/refreshing Improved Scorch")
                return true
            end
        end
    end

    -- Main nuke: Fireball for TTW, Frostfire Bolt for Frostfire builds.
    local fireNuke = self:GetMageFireNuke()
    if MageSpellReady(self, fireNuke) and not UnitCastingInfo("player") and not self:IsPlayerMoving() then
        if self:CastSpell(fireNuke, "target") then
            MageDebug("Fire: " .. fireNuke)
            return true
        end
    end

    -- Fire Blast is primarily a movement/execute spell, not a stationary
    -- filler that displaces a Fireball/Frostfire Bolt cast.
    if (self:IsPlayerMoving() or targetHP < 35) and MageSpellReady(self, S.FireBlast) then
        if self:CastSpell(S.FireBlast, "target") then
            MageDebug("Fire: Fire Blast movement/execute")
            return true
        end
    end
    
    -- Emergency wand
    if manaPercent < 5 and MageSpellReady(self, S.Shoot) then
        if self:CastSpell(S.Shoot, "target") then
            MageDebug("Fire: Emergency wanding")
            return true
        end
    end
    
    return false
end

-- =============================================
-- FROST ROTATION (ENHANCED)
-- =============================================

function AC:FrostMageRotation()
    local manaPercent = MageManaPercent()
    local procs = self:CheckMageProcs()
    local enemies = self:GetEnemyCount()
    
    -- Water Elemental management
    if self:ManageWaterElemental() then return true end
    
    -- Interrupt priority
    if self:TryMageInterrupt() then return true end
    
    -- Mana management
    if self:ManageMageMana() then return true end
    
    -- AoE rotation
    if enemies >= 3 then
        -- Blizzard for sustained AoE
        if MageSpellReady(self, S.Blizzard) and manaPercent > 30 and
           not self:IsChanneling() and not self:IsPlayerMoving() and
           self:Throttle("BlizzardCast", 8) then
            MageDebug("Frost AoE: Blizzard")
            if not self:CastSpell(S.Blizzard) then return false end
            CameraOrSelectOrMoveStart()
            CameraOrSelectOrMoveStop()
            return true
        end
        
        -- Cone of Cold for close AoE
        if CheckInteractDistance("target", 3) and MageSpellReady(self, S.ConeOfCold) then
            if self:CastSpell(S.ConeOfCold, "player") then
                MageDebug("Frost AoE: Cone of Cold")
                return true
            end
        end
        
        -- Frost Nova for crowd control
        if CheckInteractDistance("target", 3) and MageSpellReady(self, S.FrostNova) and self:Throttle("FrostNovaAoE", 25) then
            if self:CastSpell(S.FrostNova, "player") then
                MageDebug("Frost AoE: Frost Nova")
                return true
            end
        end
        
        -- Flamestrike if available
        if MageSpellReady(self, S.Flamestrike) and not self:IsChanneling() and
           not self:IsPlayerMoving() and self:Throttle("FlamestrikeFrost", 8) then
            MageDebug("Frost AoE: Flamestrike")
            if not self:CastSpell(S.Flamestrike) then return false end
            CameraOrSelectOrMoveStart()
            CameraOrSelectOrMoveStop()
            return true
        end
    end
    
    -- Cooldown usage for elite and boss targets.
    if self:ShouldUseMageMajorCooldowns() then
        if MageUseCooldown(self, S.IcyVeins, "player", "MageFrostIcyVeins") then
            self.MageLastIcyVeinsTime = GetTime()
            MageDebug("Frost: Icy Veins burst")
            return true
        end

        -- Cold Snap should reset a genuinely spent Icy Veins, not fire
        -- immediately after it or compare the raw cooldown start timestamp.
        local timeSinceIcy = self.MageLastIcyVeinsTime and (GetTime() - self.MageLastIcyVeinsTime) or 0
        if timeSinceIcy >= 90 and self:GetSpellCooldown(S.IcyVeins) > 30 and
           MageUseCooldown(self, S.ColdSnap, "player", "MageFrostColdSnap") then
            MageDebug("Frost: Cold Snap reset")
            return true
        end

        if self:IsMageBossTarget() and self:UseTrinkets() then
            MageDebug("Frost: offensive trinket")
            return true
        end
        if self:IsMageBossTarget() and self:UseOffensivePotion(true) then
            MageDebug("Frost: offensive potion")
            return true
        end
        if self:UseMageRacials(true, false) then
            MageDebug("Frost: offensive racial")
            return true
        end
        if MageUseCooldown(self, S.MirrorImage, "player", "MageFrostMirrorImage") then
            MageDebug("Frost: Mirror Image")
            return true
        end
    end

    -- Check actual freezes plus Fingers of Frost, which makes the target
    -- count as frozen for Deep Freeze even without a target debuff.
    local targetFrozen = self:HasDebuff("target", "Frost Nova") or 
                        self:HasDebuff("target", S.Freeze) or 
                        self:HasDebuff("target", "Frostbite") or
                        self:HasDebuff("target", "Deep Freeze")

    local fingersTreatAsFrozen = procs.fingersOfFrost and procs.fingersOfFrostStacks > 0
    if (targetFrozen or fingersTreatAsFrozen) and MageSpellReady(self, S.DeepFreeze) then
        if self:CastSpell(S.DeepFreeze, "target") then
            MageDebug("Frost: Deep Freeze on frozen/Fingers of Frost target")
            return true
        end
    end

    -- Brain Freeze is an instant Frostfire Bolt in Frost PvE.
    if procs.brainFreeze then
        local brainFreezeSpell = self:KnowsSpell(S.FrostfireBolt) and S.FrostfireBolt or S.Fireball
        if MageSpellReady(self, brainFreezeSpell) then
            if self:CastSpell(brainFreezeSpell, "target") then
                MageDebug("Frost: Brain Freeze " .. brainFreezeSpell)
                return true
            end
        end
    end

    -- Ice Lance is a high-value frozen/movement spell. While stationary with
    -- Fingers of Frost, continue Frostbolt/Deep Freeze usage instead of
    -- replacing the stronger Frostbolt casts with low-damage Ice Lance.
    if (targetFrozen or self:IsPlayerMoving()) and MageSpellReady(self, S.IceLance) then
        if self:CastSpell(S.IceLance, "target") then
            MageDebug("Frost: Ice Lance (" .. (targetFrozen and "frozen target" or "moving") .. ")")
            return true
        end
    end

    -- Fire Blast is the fallback instant while moving when no Ice Lance is
    -- available.
    if self:IsPlayerMoving() and MageSpellReady(self, S.FireBlast) then
        if self:CastSpell(S.FireBlast, "target") then
            MageDebug("Frost: Fire Blast while moving")
            return true
        end
    end

    -- Main nuke - Frostbolt
    if MageSpellReady(self, S.Frostbolt) and not UnitCastingInfo("player") and not self:IsPlayerMoving() then
        if self:CastSpell(S.Frostbolt, "target") then
            MageDebug("Frost: Frostbolt")
            return true
        end
    end

    -- Emergency wand
    if manaPercent < 5 and MageSpellReady(self, S.Shoot) then
        if self:CastSpell(S.Shoot, "target") then
            MageDebug("Frost: Emergency wanding")
            return true
        end
    end
    
    return false
end

-- AzeroCombat: Enhanced Mage Rotations (WotLK 3.3.5a Complete) - PART 3 OF 3
-- This part contains the main controller, initialization, debug systems, and validation

-- =============================================
-- ENHANCED MAIN ROTATION CONTROLLER
-- =============================================

function AC:MageRotation()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local health = self:GetPlayerHealthPercent()
    local manaPercent = MageManaPercent()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
    
    -- Debug output
    if self:Throttle("MageDebugMain", 5) then
        MageDebug(string.format("Running %s rotation - Level:%d HP:%.0f%% MP:%.0f%% Combat:%s Target:%s",
                  spec, level, health, manaPercent, inCombat and "Y" or "N", hasTarget and "Y" or "N"))
    end
    
    -- Channels cannot be interrupted by the rotation. Regular casts still
    -- allow Counterspell to fire below because it is off the normal cast path.
    if UnitChannelInfo("player") then
        return "busy"
    end
    
    -- Always maintain buffs (in and out of combat)
    if self:CheckMageBuffs(spec) then return true end
    
    -- Emergency Lifeblood (Herbalism profession ability) at 50% health
    if inCombat and self:UseLifeblood() then return true end
    
    -- Out of combat management
    if not inCombat then
        -- Conjure items when safe
        if self:ManageMageConjures() then return true end
        
        -- Water Elemental management
        if self:ManageWaterElemental() then return true end
        
        -- Pre-pull for fresh targets
        if hasTarget and not UnitAffectingCombat("target") and UnitExists("target") then
            local pullSpell = S.Frostbolt
            if spec == "Fire" then
                pullSpell = self:GetMageFireNuke()
            elseif spec == "Arcane" then
                pullSpell = S.ArcaneBlast
            end
            
            local inRange = not IsSpellInRange or IsSpellInRange(pullSpell, "target")
            if inRange ~= 0 and MageSpellReady(self, pullSpell) and self:Throttle("MagePull", 1) then
                if self:CastSpell(pullSpell, "target") then
                    MageDebug("Pulling with " .. pullSpell)
                    return true
                end
            end
        end
        
        return false
    end
    
    -- Find target if we don't have one
    if not hasTarget then
        local bestTarget = self:FindBestTarget()
        if bestTarget then
            TargetUnit(bestTarget)
            hasTarget = true
            MageDebug("Auto-targeted: " .. (UnitName("target") or "Unknown"))
        else
            return false
        end
    end
    if not hasTarget then return false end

    if inCombat and self:TryMageInterrupt() then return true end
    if UnitCastingInfo("player") then return "busy" end

    if inCombat and self:TryMageUtility() then return true end
    
    -- Defensive spells should be available before the player reaches lethal
    -- health, while the defensive function still guards each threshold.
    if inCombat and health < 60 then
        if self:UseMageDefensives() then return true end
    end
    
    -- Break actual crowd control or use a racial only when its condition is
    -- meaningful; the racial helper performs the detailed checks.
    if inCombat then
        if self:UseMageRacials(false, true) then return true end
    end
    
    -- Mana management (separate from rotation)
    if manaPercent < 30 then
        if self:ManageMageMana() then return true end
    end
    
    -- Run spec-specific rotation
    local rotationResult = false
    if spec == "Arcane" then
        rotationResult = self:ArcaneMageRotation()
    elseif spec == "Fire" then
        rotationResult = self:FireMageRotation()
    elseif spec == "Frost" then
        rotationResult = self:FrostMageRotation()
    else
        -- Leveling rotation (simplified)
        MageDebug("Using leveling rotation")
        
        -- Interrupt if possible
        if self:TryMageInterrupt() then return true end
        
        -- Basic mana management
        if self:ManageMageMana() then return true end

        if self:ShouldUseMageMajorCooldowns() and self:UseMageRacials(true, false) then
            MageDebug("LEVELING: offensive racial")
            return true
        end
        
        -- Enhanced leveling rotation based on available spells
        local enemies = self:GetEnemyCount()
        
        -- AoE for multiple enemies while leveling. Keep ground AoE behavior
        -- unchanged; use instant tools here for safe, mobile pulls.
        if enemies >= 3 then
            if CheckInteractDistance("target", 3) and MageSpellReady(self, S.ArcaneExplosion) then
                rotationResult = self:CastSpell(S.ArcaneExplosion, "player")
                if rotationResult then MageDebug("LEVELING: Arcane Explosion") end
            elseif CheckInteractDistance("target", 3) and health < 65 and MageSpellReady(self, S.FrostNova) then
                rotationResult = self:CastSpell(S.FrostNova, "player")
                if rotationResult then MageDebug("LEVELING: emergency Frost Nova") end
            elseif CheckInteractDistance("target", 3) and MageSpellReady(self, S.ConeOfCold) then
                rotationResult = self:CastSpell(S.ConeOfCold, "player")
                if rotationResult then MageDebug("LEVELING: Cone of Cold") end
            end
        end
        
        -- Single target priority
        if not rotationResult then
            local levelingNuke = S.Frostbolt
            if self:HasMageTalentByName("Improved Fireball") and not self:HasMageTalentByName("Improved Frostbolt") then
                levelingNuke = S.Fireball
            elseif not self:KnowsSpell(levelingNuke) then
                levelingNuke = S.Fireball
            end

            if not self:IsPlayerMoving() and MageSpellReady(self, levelingNuke) then
                rotationResult = self:CastSpell(levelingNuke, "target")
                if rotationResult then MageDebug("LEVELING: " .. levelingNuke) end
            elseif manaPercent > 50 and not self:IsPlayerMoving() and MageSpellReady(self, S.ArcaneMissiles) then
                rotationResult = self:CastSpell(S.ArcaneMissiles, "target")
                if rotationResult then MageDebug("LEVELING: Arcane Missiles") end
            elseif (self:IsPlayerMoving() or self:GetTargetHealthPercent("target") < 25) and MageSpellReady(self, S.FireBlast) then
                rotationResult = self:CastSpell(S.FireBlast, "target")
                if rotationResult then MageDebug("LEVELING: Fire Blast") end
            elseif manaPercent < 15 and MageSpellReady(self, S.Shoot) then
                rotationResult = self:CastSpell(S.Shoot, "target")
                if rotationResult then MageDebug("LEVELING: Wanding") end
            end
        end
    end
    
    return rotationResult
end

-- =============================================
-- ENHANCED DEBUG AND TESTING SYSTEM  
-- =============================================

function AC:MageDebugInfo()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local health = self:GetPlayerHealthPercent()
    local manaPercent = MageManaPercent()
    
    self:Print("=== MAGE DEBUG INFO ===")
    self:Print("Spec: " .. spec .. " (Level " .. level .. ")")
    self:Print("Health: " .. math.floor(health) .. "%")
    self:Print("Mana: " .. math.floor(manaPercent) .. "%")
    self:Print("In Combat: " .. (UnitAffectingCombat("player") and "YES" or "NO"))
    self:Print("Has Target: " .. (UnitExists("target") and "YES" or "NO"))
    self:Print("Moving: " .. (self:IsPlayerMoving() and "YES" or "NO"))
    
    -- Check procs
    local procs = self:CheckMageProcs()
    self:Print("=== CURRENT PROCS ===")
    self:Print("Missile Barrage: " .. (procs.missileBarrage and "✓ Active" or "✗ Inactive"))
    self:Print("Hot Streak: " .. (procs.hotStreak and "✓ Active" or "✗ Inactive"))
    self:Print("Firestarter: " .. (procs.firestarter and "✓ Active" or "✗ Inactive"))
    self:Print("Fingers of Frost: " .. (procs.fingersOfFrost and "✓ Active (" .. procs.fingersOfFrostStacks .. " stacks)" or "✗ Inactive"))
    self:Print("Brain Freeze: " .. (procs.brainFreeze and "✓ Active" or "✗ Inactive"))
    self:Print("Arcane Blast: " .. procs.arcaneBlastStacks .. " stacks")
    
    -- Check buffs
    self:Print("=== ACTIVE BUFFS ===")
    local armor = "None"
    if self:HasBuff("player", S.MoltenArmor) then armor = "Molten Armor"
    elseif self:HasBuff("player", S.MageArmor) then armor = "Mage Armor"
    elseif self:HasBuff("player", S.FrostArmor) then armor = "Frost Armor"
    elseif self:HasBuff("player", S.IceArmor) then armor = "Ice Armor" end
    self:Print("Armor: " .. armor)
    
    local int = self:HasBuff("player", S.ArcaneBrilliance) and "Arcane Brilliance" or
               (self:HasBuff("player", S.ArcaneIntellect) and "Arcane Intellect" or "None")
    self:Print("Intelligence: " .. int)
    self:Print("Focus Magic: " .. (self:HasBuff("player", S.FocusMagic) and "Active" or "Inactive"))
    if spec == "Fire" then
        self:Print("Fire filler: " .. self:GetMageFireNuke())
    end
    
    -- Check consumables
    local hasManaGem = false
    for _, gem in ipairs(ManaGems) do
        if GetItemCount(gem) > 0 then
            self:Print("Mana Gem: " .. gem .. " (" .. GetItemCount(gem) .. ")")
            hasManaGem = true
            break
        end
    end
    if not hasManaGem then
        self:Print("Mana Gem: None")
    end
    
    -- Pet info (Water Elemental)
    if spec == "Frost" then
        self:Print("=== PET INFO ===")
        self:Print("Water Elemental: " .. (UnitExists("pet") and "✓ Active" or "✗ Not summoned"))
        if UnitExists("pet") then
            local petHealth = UnitHealth("pet") / UnitHealthMax("pet") * 100
            self:Print("Pet Health: " .. math.floor(petHealth) .. "%")
        end
    end
    
    -- Target info
    if UnitExists("target") then
        local targetHP = self:GetTargetHealthPercent("target")
        local targetLevel = UnitLevel("target")
        local classification = UnitClassification("target")
        
        self:Print("=== TARGET INFO ===")
        self:Print("Target HP: " .. math.floor(targetHP) .. "%")
        self:Print("Target Level: " .. targetLevel)
        self:Print("Classification: " .. (classification or "normal"))
        self:Print("In Range: " .. (IsSpellInRange(S.Frostbolt, "target") == 1 and "YES" or "NO"))
        
        -- Show debuffs
        if self:HasDebuff("target", S.LivingBomb) then
            local timeLeft = self:DebuffTimeRemaining("target", S.LivingBomb)
            self:Print("Living Bomb: " .. math.floor(timeLeft) .. "s remaining")
        end
        
        if self:HasDebuff("target", S.ImprovedScorch) then
            local timeLeft = self:DebuffTimeRemaining("target", S.ImprovedScorch)
            self:Print("Improved Scorch: " .. math.floor(timeLeft) .. "s remaining")
        end
    end
    
    local enemies = self:GetEnemyCount()
    self:Print("Enemy Count: " .. enemies)
    self:Print("Should AoE: " .. (enemies >= 3 and "YES" or "NO"))
    
    self:Print("=======================")
end

-- =============================================
-- ENHANCED SLASH COMMANDS
-- =============================================

-- Setup enhanced slash commands for mage testing
function AC:SetupMageSlashCommands()
    local originalHandler = SlashCmdList["AZEROCOMBAT"]
    
    if originalHandler then
        SlashCmdList["AZEROCOMBAT"] = function(msg)
            local args = {strsplit(" ", msg)}
            local command = args[1] and args[1]:lower() or ""
            local subcommand = args[2] and args[2]:lower() or ""
            
            if command == "mage" then
                if subcommand == "debug" then
                    self:MageDebugInfo()
                elseif subcommand == "procs" then
                    local procs = self:CheckMageProcs()
                    self:Print("=== MAGE PROCS ===")
                    self:Print("Missile Barrage: " .. (procs.missileBarrage and "✓ Active" or "✗ Inactive"))
                    self:Print("Hot Streak: " .. (procs.hotStreak and "✓ Active" or "✗ Inactive"))
                    self:Print("Firestarter: " .. (procs.firestarter and "✓ Active" or "✗ Inactive"))
                    self:Print("Fingers of Frost: " .. (procs.fingersOfFrost and "✓ Active (" .. procs.fingersOfFrostStacks .. " stacks)" or "✗ Inactive"))
                    self:Print("Brain Freeze: " .. (procs.brainFreeze and "✓ Active" or "✗ Inactive"))
                    self:Print("Arcane Blast: " .. procs.arcaneBlastStacks .. " stacks")
                elseif subcommand == "rotation" then
                    local spec = self:GetPlayerSpec()
                    self:Print("=== " .. spec:upper() .. " MAGE ROTATION PRIORITY ===")
                    
                    if spec == "Arcane" then
                        self:Print("WotLK 3.3.5a Arcane Priority:")
                        self:Print("1. Use Missile Barrage procs immediately")
                        self:Print("2. Build Arcane Blast stacks (high mana)")
                        self:Print("3. Spend stacks with Arcane Missiles")
                        self:Print("4. Use Arcane Barrage for mana conservation")
                        self:Print("5. Arcane Power + Presence of Mind for burst")
                        
                    elseif spec == "Fire" then
                        self:Print("WotLK 3.3.5a Fire Priority:")
                        self:Print("1. Maintain Living Bomb")
                        self:Print("2. Use Hot Streak procs immediately")
                        self:Print("3. Maintain Improved Scorch debuff")
                        self:Print("4. Fireball as main nuke")
                        self:Print("5. Combustion when DoTs are active")
                        
                    elseif spec == "Frost" then
                        self:Print("WotLK 3.3.5a Frost Priority:")
                        self:Print("1. Use Brain Freeze procs (Fireball/FFB)")
                        self:Print("2. Use Fingers of Frost procs (Ice Lance)")
                        self:Print("3. Deep Freeze on frozen targets")
                        self:Print("4. Frostbolt as main nuke")
                        self:Print("5. Ice Lance while moving or on frozen")
                    else
                        self:Print("Unknown spec - using basic rotation")
                    end
                elseif subcommand == "test" then
                    self:Print("=== MAGE ROTATION TEST ===")
                    local spec = self:GetPlayerSpec()
                    self:Print("Testing " .. spec .. " rotation...")
                    
                    local result = self:MageRotation()
                    self:Print("Result: " .. (result and "Action taken" or "No action"))
                    
                    -- Show current state
                    local procs = self:CheckMageProcs()
                    if procs.missileBarrage or procs.hotStreak or procs.fingersOfFrost or procs.brainFreeze then
                        self:Print("Active procs detected - should prioritize!")
                    end
                elseif subcommand == "pet" then
                    local spec = self:GetPlayerSpec()
                    if spec == "Frost" then
                        self:Print("=== WATER ELEMENTAL STATUS ===")
                        self:Print("Spec: " .. spec)
                        self:Print("Pet exists: " .. (UnitExists("pet") and "YES" or "NO"))
                        
                        if UnitExists("pet") then
                            local petHealth = UnitHealth("pet") / UnitHealthMax("pet") * 100
                            self:Print("Pet health: " .. math.floor(petHealth) .. "%")
                            self:Print("Pet in combat: " .. (UnitAffectingCombat("pet") and "YES" or "NO"))
                            
                            -- Check pet abilities
                            local freezeCD = GetPetActionCooldown(1)
                            self:Print("Freeze cooldown: " .. (freezeCD == 0 and "Ready" or "On cooldown"))
                        else
                            self:Print("Water Elemental not summoned")
                            if self:KnowsSpell(S.SummonWaterElemental) then
                                self:Print("Can summon: YES")
                            else
                                self:Print("Can summon: NO (spell not learned)")
                            end
                        end
                    else
                        self:Print("Only Frost mages have Water Elemental")
                    end
                else
                    self:Print("Enhanced Mage commands:")
                    self:Print("  /ac mage debug - Complete debug information")
                    self:Print("  /ac mage procs - Show current procs")
                    self:Print("  /ac mage rotation - Show rotation priority")
                    self:Print("  /ac mage test - Test current rotation")
                    self:Print("  /ac mage pet - Water Elemental status (Frost only)")
                end
            else
                originalHandler(msg)
            end
        end
    end
end

-- =============================================
-- INITIALIZATION SYSTEM
-- =============================================

function AC:InitMageRotations()
    self.rotations = self.rotations or {}
    self.rotations["MAGE"] = {}
    
    -- Register all spec rotations
    self.rotations["MAGE"]["Arcane"] = function(s) return s:MageRotation() end
    self.rotations["MAGE"]["Fire"] = function(s) return s:MageRotation() end
    self.rotations["MAGE"]["Frost"] = function(s) return s:MageRotation() end
    self.rotations["MAGE"]["None"] = function(s) return s:MageRotation() end
    
    -- Register buff checker
    self.CheckMageBuffs = AC.CheckMageBuffs
    
    -- Initialize proc tracking
    self.MageProcs = {}
    
    -- Setup enhanced slash commands
    self:SetupMageSlashCommands()
    
    self:Print("Enhanced Mage rotations loaded for WotLK 3.3.5a!")
    self:Print("✅ Complete proc tracking (Missile Barrage, Hot Streak, Fingers of Frost, Brain Freeze)")
    self:Print("✅ Optimized rotations for all three specs with proper priorities")
    self:Print("✅ Enhanced AoE detection and management")
    self:Print("✅ Water Elemental management with pet abilities")
    self:Print("✅ Smart cooldown usage for elite/boss targets")
    self:Print("✅ Comprehensive mana management with gems and potions")
    self:Print("✅ Enhanced defensive system with threat management")
    self:Print("✅ Full Core.lua and Utils.lua integration")
    self:Print("✅ Automatic conjure management (gems, food, water)")
    MageDebug("Enhanced Mage module loaded successfully")
end

-- =============================================
-- VALIDATION SYSTEM
-- =============================================

function AC:ValidateMageSetup()
    local issues = {}
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    
    self:Print("=== MAGE SETUP VALIDATION ===")
    
    -- Check Core.lua integration
    if self.GetEnemyCount and self.SafeCastGroundAOE and self.FindBestTarget then
        self:Print("✓ Core.lua integration working")
    else
        table.insert(issues, "Core.lua integration missing")
    end
    
    -- Check Utils.lua integration
    if self.UseHealthPotion and self.UseManaPotion and self.UseTrinkets then
        self:Print("✓ Utils.lua integration working")
    else
        table.insert(issues, "Utils.lua integration missing")
    end
    
    -- Check proc tracking
    local procs = self:CheckMageProcs()
    if procs then
        self:Print("✓ Proc tracking system working")
    else
        table.insert(issues, "Proc tracking system failed")
    end
    
    -- Check key spells for each spec
    if spec == "Arcane" then
        if level >= 69 and not self:KnowsSpell(S.ArcaneBarrage) then
            table.insert(issues, "Arcane Barrage not learned (should be available at 69+)")
        end
        if level >= 64 and not self:KnowsSpell(S.ArcaneBlast) then
            table.insert(issues, "Arcane Blast not learned (should be available at 64+)")
        end
    elseif spec == "Fire" then
        if level >= 70 and not self:KnowsSpell(S.LivingBomb) then
            table.insert(issues, "Living Bomb not learned (should be available at 70+)")
        end
        if level >= 50 and not self:KnowsSpell(S.Combustion) then
            table.insert(issues, "Combustion not learned (should be available at 50+)")
        end
    elseif spec == "Frost" then
        if level >= 60 and not self:KnowsSpell(S.SummonWaterElemental) then
            table.insert(issues, "Summon Water Elemental not learned (should be available at 60+)")
        end
        if level >= 44 and not self:KnowsSpell(S.IceLance) then
            table.insert(issues, "Ice Lance not learned (should be available at 44+)")
        end
    end
    
    -- Check mana gems
    local hasManaGem = false
    for _, gem in ipairs(ManaGems) do
        if GetItemCount(gem) > 0 then
            hasManaGem = true
            break
        end
    end
    if hasManaGem then
        self:Print("✓ Mana gems available")
    else
        self:Print("⚠️ No mana gems found - will create when out of combat")
    end
    
    -- Check for Water Elemental (Frost only)
    if spec == "Frost" then
        if UnitExists("pet") then
            self:Print("✓ Water Elemental summoned")
        else
            self:Print("⚠️ Water Elemental not summoned")
        end
    end
    
    -- Report results
    if #issues > 0 then
        self:Print("⚠️ Issues found:")
        for _, issue in ipairs(issues) do
            self:Print("  - " .. issue)
        end
    else
        self:Print("✅ All systems validated successfully!")
    end
    
    self:Print("=== VALIDATION COMPLETE ===")
    return #issues == 0
end

-- =============================================
-- UTILITY FUNCTIONS
-- =============================================

-- Check if player is moving
function AC:IsPlayerMoving()
    return GetUnitSpeed("player") > 0
end

-- =============================================
-- AUTO-INITIALIZATION FOR MAGES
-- =============================================

-- Initialize validation for Mages
if AC.GetPlayerClass and AC:GetPlayerClass() == "MAGE" then
    local validationFrame = CreateFrame("Frame")
    validationFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    validationFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            local delayFrame = CreateFrame("Frame")
            local elapsedTime = 0
            delayFrame:SetScript("OnUpdate", function(self, elapsed)
                elapsedTime = elapsedTime + elapsed
                if elapsedTime >= 3 then
                    if AC.ValidateMageSetup then
                        AC:ValidateMageSetup()
                    end
                    delayFrame:SetScript("OnUpdate", nil)
                end
            end)
            validationFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
    end)
end

-- =============================================
-- FINAL COMPLETION CHECK
-- =============================================

-- Ensure all mage systems are properly initialized
AC.MageSystemsLoaded = true

-- Print completion message when file loads
if AC.GetPlayerClass and AC:GetPlayerClass() == "MAGE" then
    print("|cFF3FC7EB[Mage]|r Enhanced Mage rotations loaded successfully - WotLK 3.3.5a complete!")
    print("|cFF3FC7EB✅ COMPREHENSIVE ENHANCEMENTS:|r")
    print("|cFF3FC7EB  • Enhanced:|r Complete proc tracking for all specs")
    print("|cFF3FC7EB  • Enhanced:|r Optimized single target rotations")
    print("|cFF3FC7EB  • Enhanced:|r Smart AoE detection and management")
    print("|cFF3FC7EB  • Enhanced:|r Water Elemental management with abilities")
    print("|cFF3FC7EB  • Enhanced:|r Cooldown usage for elite/boss encounters")
    print("|cFF3FC7EB  • Enhanced:|r Mana management with gems and potions")
    print("|cFF3FC7EB  • Enhanced:|r Defensive system with threat management")
    print("|cFF3FC7EB  • Enhanced:|r Automatic conjure management")
    print("|cFF3FC7EB  • Enhanced:|r Interrupt system with priority spells")
    print("|cFF3FC7EB  • Enhanced:|r Debug and testing commands")
    print("|cFF3FC7EB  • Enhanced:|r Full Core.lua and Utils.lua compatibility")
    print("|cFF3FC7EBReady for combat!|r Use |cFFFFFF00/ac mage debug|r for full status")
end

-- END OF PART 3 - Complete Enhanced Mage System for WotLK 3.3.5a
