-- ================================================================
-- AzeroCombat: Professional WotLK 3.3.5a Warlock Module v2
-- Complete rewrite with top-tier rotations for all three specs
-- Research-based: Affliction, Demonology, Destruction
-- ENHANCED: Shadow Embrace optimization, intelligent proc timing,
-- dynamic resource management, level-aware AoE, spec-specific racials
-- ================================================================
local AddonName, AC = ...

-- ================================================================
-- SPELL CONSTANTS (WotLK 3.3.5a)
-- ================================================================
local S = {
    -- ========== AFFLICTION SPELLS ==========
    Corruption = "Corruption",
    CurseOfAgony = "Curse of Agony",
    CurseOfDoom = "Curse of Doom",
    CurseOfTheElements = "Curse of the Elements",
    CurseOfTongues = "Curse of Tongues",
    CurseOfWeakness = "Curse of Weakness",
    DrainLife = "Drain Life",
    DrainMana = "Drain Mana",
    DrainSoul = "Drain Soul",
    Haunt = "Haunt",
    HowlOfTerror = "Howl of Terror",
    SeedOfCorruption = "Seed of Corruption",
    ShadowBolt = "Shadow Bolt",
    SiphonLife = "Siphon Life",
    UnstableAffliction = "Unstable Affliction",
    
    -- ========== DEMONOLOGY SPELLS ==========
    BanishExile = "Banish",
    DemonArmor = "Demon Armor",
    DemonSkin = "Demon Skin",
    DemonicEmpowerment = "Demonic Empowerment",
    EnslaveDemon = "Enslave Demon",
    FelArmor = "Fel Armor",
    FelDomination = "Fel Domination",
    ImmolationAura = "Immolation Aura",
    Metamorphosis = "Metamorphosis",
    ShadowCleave = "Shadow Cleave", -- Metamorphosis ability
    SoulLink = "Soul Link",
    SoulShatter = "Soulshatter",
    SummonFelguard = "Summon Felguard",
    SummonFelhunter = "Summon Felhunter",
    SummonImp = "Summon Imp",
    SummonSuccubus = "Summon Succubus",
    SummonVoidwalker = "Summon Voidwalker",
    
    -- ========== DESTRUCTION SPELLS ==========
    ChaosBolt = "Chaos Bolt",
    Conflagrate = "Conflagrate",
    Hellfire = "Hellfire",
    Immolate = "Immolate",
    Incinerate = "Incinerate",
    RainOfFire = "Rain of Fire",
    SearingPain = "Searing Pain",
    ShadowBurn = "Shadowburn",
    Shadowflame = "Shadowflame",
    SoulFire = "Soul Fire",
    
    -- ========== UNIVERSAL SPELLS ==========
    DarkPact = "Dark Pact",
    DeathCoil = "Death Coil",
    Fear = "Fear",
    LifeTap = "Life Tap",
    RitualOfSouls = "Ritual of Souls",
    RitualOfSummoning = "Ritual of Summoning",
    ShadowWard = "Shadow Ward",
    UnendingBreath = "Unending Breath",
    
    -- ========== ITEM CREATION ==========
    CreateHealthstone = "Create Healthstone",
    CreateSoulstone = "Create Soulstone",
    CreateFirestone = "Create Firestone",
    CreateSpellstone = "Create Spellstone",
    
    -- ========== IMPORTANT BUFFS/DEBUFFS ==========
    Backdraft = "Backdraft",
    Decimation = "Decimation",
    MoltenCore = "Molten Core",
    ShadowEmbrace = "Shadow Embrace",
    MetamorphosisForm = "Metamorphosis",
    ShadowTrance = "Shadow Trance",
    DevicousMinds = "Devious Minds",
    Eradication = "Eradication",
    
    -- ========== PET ABILITIES ==========
    -- Imp
    FireBolt = "Firebolt",
    PhaseShift = "Phase Shift",
    
    -- Voidwalker
    Torment = "Torment",
    Sacrifice = "Sacrifice",
    Consume = "Consume Shadows",
    
    -- Succubus
    LashOfPain = "Lash of Pain",
    Seduction = "Seduction",
    
    -- Felhunter
    SpellLock = "Spell Lock",
    DevourMagic = "Devour Magic",
    
    -- Felguard
    Cleave = "Cleave",
    Intercept = "Intercept",
    Anguish = "Anguish"
}

-- ================================================================
-- RACIAL ABILITIES
-- ================================================================
local R = {
    BloodFury = "Blood Fury",                -- Orc
    Berserking = "Berserking",               -- Troll  
    WillOfForsaken = "Will of the Forsaken", -- Undead
    EveryMan = "Every Man for Himself",      -- Human
    Stoneform = "Stoneform",                 -- Dwarf
    EscapeArtist = "Escape Artist",          -- Gnome
    GiftOfNaaru = "Gift of the Naaru",       -- Draenei
    ArcaneTorrent = "Arcane Torrent"         -- Blood Elf
}

local WARLOCK_WEAPON_STONE_IDS = {
    [22049] = true, [22047] = true, [22048] = true, -- Spellstones
    [5522] = true, [5521] = true, [5520] = true,
    [41191] = true, [41190] = true, [41189] = true,
    [22046] = true, [22045] = true, [22044] = true, -- Firestones
    [1254] = true, [13699] = true, [13700] = true
}

local WARLOCK_WEAPON_STONE_NAMES = {
    ["spellstone"] = true,
    ["minor spellstone"] = true,
    ["lesser spellstone"] = true,
    ["greater spellstone"] = true,
    ["major spellstone"] = true,
    ["grand spellstone"] = true,
    ["firestone"] = true,
    ["minor firestone"] = true,
    ["lesser firestone"] = true,
    ["greater firestone"] = true,
    ["major firestone"] = true
}

local function IsWarlockWeaponStoneIdentifier(itemIdentifier)
    if type(itemIdentifier) == "number" then
        return WARLOCK_WEAPON_STONE_IDS[itemIdentifier] and true or false
    end
    if type(itemIdentifier) == "string" then
        local normalized = string.lower(itemIdentifier)
        return WARLOCK_WEAPON_STONE_NAMES[normalized] and true or false
    end
    return false
end

-- ================================================================
-- DEBUG SYSTEM
-- ================================================================
local function WarlockDebug(msg)
    if AC.debugMode then
        local _, playerClass = UnitClass("player")
        if playerClass == "WARLOCK" then
            AC:Debug("|cFF9482C9Warlock:|r " .. tostring(msg))
        end
    end
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================
function AC:IsSpellKnown(spellName)
    if not spellName then return false end

    -- If native usability reports usable or insufficient mana, the spell is
    -- known and present in the current context.
    local usable, noMana = IsUsableSpell(spellName)
    if usable or noMana then
        return true
    end

    -- Primary lookup by spellID when available.
    local spellID = select(7, GetSpellInfo(spellName))
    if spellID and spellID > 0 and IsSpellKnown(spellID) then
        return true
    end

    -- Core spellbook helper can be wrong on some private-server edge cases;
    -- only accept positive results and keep fallback scan for negatives.
    if self.KnowsSpell then
        local ok, known = pcall(self.KnowsSpell, self, spellName)
        if ok and known then
            return true
        end
    end

    -- Final direct scan of the spellbook (3.3.5a compatible API).
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for i = offset + 1, offset + numSpells do
            local name = GetSpellName(i, BOOKTYPE_SPELL)
            if name == spellName then
                return true
            end
        end
    end

    return false
end

function AC:CanCast(spellName)
    if not spellName then
        return false
    end

    -- Briefly back off spells that just failed to start to avoid hard lock loops.
    if self.WarlockCastFailures and self.WarlockCastFailures[spellName] then
        if (GetTime() - self.WarlockCastFailures[spellName]) < 0.8 then
            return false
        end
    end

    local spellInfo = GetSpellInfo(spellName)
    if not spellInfo then
        return false
    end

    local isUsable, noMana = IsUsableSpell(spellName)
    if not isUsable or noMana then
        return false
    end

    local cooldown = self:GetSpellCooldown(spellName)
    if cooldown > 0.1 then
        return false
    end

    return true
end

function AC:IsGlobalCooldownActive()
    local start, duration = GetSpellCooldown(61304)
    if not start or not duration or start <= 0 or duration <= 0 then
        return false
    end
    return (start + duration - GetTime()) > 0.1
end

-- Enhanced CastSpell function for Warlock
-- REMOVED: Duplicate CastWarlockSpell function - using enhanced version with analytics below

-- Apply spellstone/firestone to weapon (based on Rogue poison application)
function AC:ApplyWarlockStoneToWeapon(itemIdentifier, weaponSlot)
    -- Find the item in bags
    local bag, slot = self:FindWarlockStoneInBags(itemIdentifier)
    if not bag or not slot then
        WarlockDebug("Item " .. tostring(itemIdentifier) .. " not found in bags")
        return false
    end
    
    -- Verify the item still exists
    local itemName = GetContainerItemInfo(bag, slot)
    if not itemName then
        WarlockDebug("Item no longer exists in bag " .. bag .. " slot " .. slot)
        return false
    end
    
    WarlockDebug("Attempting to apply " .. itemName .. " to weapon slot " .. weaponSlot)
    
    -- Method 1: Use container item directly on weapon slot (like Rogue)
    local success1 = pcall(function()
        UseContainerItem(bag, slot)
        PickupInventoryItem(weaponSlot)
    end)
    
    if success1 then
        WarlockDebug("Successfully applied " .. itemName .. " (Method 1)")
        return true
    end
    
    -- Method 2: Clear cursor and try again (like Rogue)
    local success2 = pcall(function()
        ClearCursor()
        UseContainerItem(bag, slot)
        if CursorHasItem() then
            PickupInventoryItem(weaponSlot)
            ClearCursor()
        end
    end)
    
    if success2 then
        WarlockDebug("Successfully applied " .. itemName .. " (Method 2)")
        return true
    end
    
    WarlockDebug("Failed to apply " .. itemName .. " to weapon")
    return false
end

-- Find spellstone/firestone in bags
function AC:FindWarlockStoneInBags(itemIdentifier)
    WarlockDebug("FindWarlockStoneInBags: Searching for " .. tostring(itemIdentifier) .. " (type: " .. type(itemIdentifier) .. ")")
    
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                -- Check if itemIdentifier is a number (itemID) or string (item name)
                if type(itemIdentifier) == "number" then
                    local bagItemID = tonumber(itemLink:match("item:(%d+)"))
                    WarlockDebug("FindWarlockStoneInBags: Found item ID " .. tostring(bagItemID) .. " in bag " .. bag .. " slot " .. slot)
                    if bagItemID == itemIdentifier then
                        WarlockDebug("FindWarlockStoneInBags: Match found!")
                        return bag, slot
                    end
                else
                    -- Check by item name - extract from item link
                    local itemName = itemLink:match("|h%[(.-)%]|h")
                    if itemName then
                        WarlockDebug("FindWarlockStoneInBags: Found item name '" .. itemName .. "' in bag " .. bag .. " slot " .. slot)
                        if itemName == itemIdentifier then
                            WarlockDebug("FindWarlockStoneInBags: Match found!")
                            return bag, slot
                        end
                    end
                end
            end
        end
    end
    WarlockDebug("FindWarlockStoneInBags: No match found")
    return nil, nil
end

-- Warlock-specific HasDebuff function (local to avoid contaminating other classes)
local function WarlockHasDebuff(unit, spellName)
    unit = unit or "target"
    if not UnitExists(unit) then return false end
    
    -- Method 1: Try Core.lua method first
    local name, _, _, count, _, duration, expires = UnitDebuff(unit, spellName)
    if name then
        WarlockDebug("HasDebuff (Core method): Found " .. spellName .. " on " .. unit)
        return true, count, duration, expires
    end
    
    -- Method 2: Try scanning all debuff slots (fallback)
    for i = 1, 40 do
        local debuffName = UnitDebuff(unit, i)
        if not debuffName then break end
        if debuffName == spellName then
            WarlockDebug("HasDebuff (Scan method): Found " .. spellName .. " on " .. unit .. " at slot " .. i)
            return true
        end
    end
    
    WarlockDebug("HasDebuff: " .. spellName .. " NOT found on " .. unit)
    return false
end

-- Warlock-specific HasBuff function (local to avoid contaminating other classes)
local function WarlockHasBuff(unit, spellName)
    unit = unit or "player"
    if not UnitExists(unit) then return false end
    
    -- Method 1: Try Core.lua method first
    local name, _, _, count, _, duration, expires = UnitBuff(unit, spellName)
    if name then
        WarlockDebug("HasBuff (Core method): Found " .. spellName .. " on " .. unit)
        return true, count, duration, expires
    end
    
    -- Method 2: Try scanning all buff slots (fallback)
    for i = 1, 40 do
        local buffName = UnitBuff(unit, i)
        if not buffName then break end
        if buffName == spellName then
            WarlockDebug("HasBuff (Scan method): Found " .. spellName .. " on " .. unit .. " at slot " .. i)
            return true
        end
    end
    
    WarlockDebug("HasBuff: " .. spellName .. " NOT found on " .. unit)
    return false
end

-- Debug function to show all debuffs on target
function AC:ShowTargetDebuffs()
    if not UnitExists("target") then return end
    
    WarlockDebug("=== TARGET DEBUFFS ===")
    for i = 1, 40 do
        local name, icon, count, debuffType, duration, expires = UnitDebuff("target", i)
        if not name then break end
        local timeLeft = expires and (expires - GetTime()) or 0
        WarlockDebug("Slot " .. i .. ": " .. name .. " (Type: " .. (debuffType or "None") .. ", Time: " .. string.format("%.1f", timeLeft) .. "s)")
    end
    WarlockDebug("=== END DEBUFFS ===")
end

function AC:CanUseItem(itemID)
    return GetItemCooldown(itemID) == 0
end

function AC:GetDistanceToUnit(unit)
    if not UnitExists(unit) then return 999 end
    
    -- Use range checking functions to estimate distance
    if CheckInteractDistance(unit, 1) then
        return 28
    elseif CheckInteractDistance(unit, 2) then
        return 11
    elseif CheckInteractDistance(unit, 3) then
        return 10
    elseif CheckInteractDistance(unit, 4) then
        return 28
    end
    
    return 999
end

-- Check if mob is dying too fast to apply DoTs (like Hunter/Warrior)
function AC:IsFastDyingMob(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end
    
    local healthPercent = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
    local level = UnitLevel(unit)
    local playerLevel = UnitLevel("player")
    
    -- Don't waste DoTs on low health targets
    if healthPercent <= 25 then
        return true
    end
    
    -- Don't waste DoTs on low level mobs relative to player
    if level > 0 and playerLevel > 0 and (playerLevel - level) >= 5 then
        return true
    end
    
    return false
end

-- ================================================================
-- ADVANCED PROC TRACKING SYSTEM (WotLK 3.3.5a Meta-Optimized)
-- ================================================================
AC.WarlockProcs = AC.WarlockProcs or {}
AC.DemonologyProcs = AC.DemonologyProcs or {}

-- Initialize advanced Demonology proc tracking
function AC:InitializeDemonologyProcs()
    self.DemonologyProcs = {
        -- CRITICAL: Molten Core (12% from Corruption, 3 charges, 15 seconds)
        moltenCore = {
            active = false,
            charges = 0,
            expires = 0,
            lastUsed = 0,
            totalProcs = 0,
            wastedCharges = 0
        },
        
        -- CRITICAL: Decimation (<35% health, 10 seconds, instant Soul Fire)
        decimation = {
            active = false,
            expires = 0,
            lastTriggered = 0,
            totalProcs = 0,
            totalUsed = 0
        },
        
        -- IMPORTANT: Improved Shadow Bolt debuff (5% shadow damage increase)
        improvedShadowBolt = {
            active = false,
            expires = 0,
            lastApplied = 0,
            totalApplications = 0
        },
        
        -- TRANSFORMATION: Metamorphosis state tracking
        metamorphosis = {
            active = false,
            expires = 0,
            lastUsed = 0,
            cooldownReady = true,
            optimalUseWindows = 0
        },
        
        -- COMBAT PHASES: Dynamic state tracking
        combatPhase = {
            current = "none", -- none, opener, sustained, burst, execute, defensive
            timeInPhase = 0,
            lastPhaseChange = 0,
            targetHealthPercent = 100
        }
    }
end

-- Ensure proc tracking tables exist before any read/write access.
function AC:EnsureDemonologyProcState()
    if type(self.DemonologyProcs) ~= "table" then
        self.DemonologyProcs = {}
    end

    local demoProcs = self.DemonologyProcs
    if type(demoProcs.moltenCore) ~= "table" or
       type(demoProcs.decimation) ~= "table" or
       type(demoProcs.improvedShadowBolt) ~= "table" or
       type(demoProcs.metamorphosis) ~= "table" or
       type(demoProcs.combatPhase) ~= "table" then
        self:InitializeDemonologyProcs()
        demoProcs = self.DemonologyProcs
    end

    return demoProcs
end

-- Enhanced proc tracking with detailed analytics
function AC:UpdateWarlockProcs()
    local procs = self.WarlockProcs
    local demoProcs = self:EnsureDemonologyProcState()
    
    local currentTime = GetTime()
    
    -- ========== MOLTEN CORE TRACKING ==========
    local hasMoltenCore, _, _, moltenStacks, _, moltenDuration, moltenExpires = UnitBuff("player", S.MoltenCore)
    if hasMoltenCore then
        -- New proc detected
        if not demoProcs.moltenCore.active then
            demoProcs.moltenCore.totalProcs = demoProcs.moltenCore.totalProcs + 1
            WarlockDebug("MOLTEN CORE PROC! Stack count: " .. (moltenStacks or 0))
        end
        
        demoProcs.moltenCore.active = true
        demoProcs.moltenCore.charges = moltenStacks or 0
        demoProcs.moltenCore.expires = moltenExpires or (currentTime + (moltenDuration or 15))
        
        -- Waste detection
        if demoProcs.moltenCore.charges == 0 and demoProcs.moltenCore.expires < currentTime then
            demoProcs.moltenCore.wastedCharges = demoProcs.moltenCore.wastedCharges + 1
            WarlockDebug("WARNING: Molten Core charges wasted!")
        end
    else
        demoProcs.moltenCore.active = false
        demoProcs.moltenCore.charges = 0
        demoProcs.moltenCore.expires = 0
    end
    
    -- ========== DECIMATION TRACKING ==========
    local hasDecimation, _, _, _, _, decimationDuration, decimationExpires = UnitBuff("player", S.Decimation)
    if hasDecimation then
        if not demoProcs.decimation.active then
            demoProcs.decimation.totalProcs = demoProcs.decimation.totalProcs + 1
            demoProcs.decimation.lastTriggered = currentTime
            WarlockDebug("DECIMATION PROC! Instant Soul Fire available")
        end
        
        demoProcs.decimation.active = true
        demoProcs.decimation.expires = decimationExpires or (currentTime + (decimationDuration or 10))
    else
        demoProcs.decimation.active = false
        demoProcs.decimation.expires = 0
    end
    
    -- ========== IMPROVED SHADOW BOLT DEBUFF ==========
    local hasISB, _, _, _, _, isbDuration, isbExpires = UnitDebuff("target", "Shadow Mastery")
    if not hasISB then
        -- Try alternative names for the debuff
        hasISB, _, _, _, _, isbDuration, isbExpires = UnitDebuff("target", "Improved Shadow Bolt")
    end
    
    if hasISB then
        if not demoProcs.improvedShadowBolt.active then
            demoProcs.improvedShadowBolt.totalApplications = demoProcs.improvedShadowBolt.totalApplications + 1
        end
        demoProcs.improvedShadowBolt.active = true
        demoProcs.improvedShadowBolt.expires = isbExpires or (currentTime + (isbDuration or 30))
        demoProcs.improvedShadowBolt.lastApplied = currentTime
    else
        demoProcs.improvedShadowBolt.active = false
        demoProcs.improvedShadowBolt.expires = 0
    end
    
    -- ========== METAMORPHOSIS TRACKING ==========
    local hasMetamorphosis, _, _, _, _, metaDuration, metaExpires = UnitBuff("player", S.MetamorphosisForm)
    if hasMetamorphosis then
        if not demoProcs.metamorphosis.active then
            demoProcs.metamorphosis.lastUsed = currentTime
            WarlockDebug("METAMORPHOSIS ACTIVATED! Demon form for 30 seconds")
        end
        demoProcs.metamorphosis.active = true
        demoProcs.metamorphosis.expires = metaExpires or (currentTime + (metaDuration or 30))
    else
        demoProcs.metamorphosis.active = false
        demoProcs.metamorphosis.expires = 0
    end
    
    -- Check Metamorphosis cooldown
    local metaCooldown = self:GetSpellCooldown(S.Metamorphosis)
    demoProcs.metamorphosis.cooldownReady = (metaCooldown == 0)
    
    -- ========== COMBAT PHASE DETECTION ==========
    local targetHealthPercent = UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target") * 100) or 100
    local playerHealthPercent = (UnitHealth("player") / UnitHealthMax("player")) * 100
    local inCombat = UnitAffectingCombat("player")
    local combatTime = inCombat and (currentTime - (self.combatStartTime or currentTime)) or 0
    
    -- Store combat start time
    if inCombat and not self.combatStartTime then
        self.combatStartTime = currentTime
    elseif not inCombat then
        self.combatStartTime = nil
    end
    
    local oldPhase = demoProcs.combatPhase.current
    local newPhase = "none"
    
    if not inCombat then
        newPhase = "none"
    elseif playerHealthPercent < 30 then
        newPhase = "defensive"
    elseif combatTime < 6 then
        newPhase = "opener"
    elseif targetHealthPercent <= 35 then
        newPhase = "execute"
    elseif targetHealthPercent > 80 and (demoProcs.moltenCore.active or demoProcs.metamorphosis.cooldownReady) then
        newPhase = "burst"
    else
        newPhase = "sustained"
    end
    
    -- Phase change detection
    if oldPhase ~= newPhase then
        demoProcs.combatPhase.lastPhaseChange = currentTime
        demoProcs.combatPhase.timeInPhase = 0
        WarlockDebug("COMBAT PHASE CHANGE: " .. oldPhase .. " → " .. newPhase)
    else
        demoProcs.combatPhase.timeInPhase = currentTime - demoProcs.combatPhase.lastPhaseChange
    end
    
    demoProcs.combatPhase.current = newPhase
    demoProcs.combatPhase.targetHealthPercent = targetHealthPercent
    
    -- ========== LEGACY PROC TRACKING (for other specs) ==========
    -- Destruction procs
    procs.backdraft = self:HasBuff("player", S.Backdraft)
    local _, _, _, backdraftStacks = UnitBuff("player", S.Backdraft)
    procs.backdraftStacks = backdraftStacks or 0
    procs.backdraftTimeRemaining = self:BuffTimeRemaining("player", S.Backdraft) or 0
    
    -- Universal procs
    procs.moltenCore = demoProcs.moltenCore.active
    procs.moltenCoreTimeRemaining = math.max(0, demoProcs.moltenCore.expires - currentTime)
    procs.shadowTrance = self:HasBuff("player", S.ShadowTrance)
    procs.shadowTranceTimeRemaining = self:BuffTimeRemaining("player", S.ShadowTrance) or 0
    
    -- Demonology procs (legacy compatibility)
    procs.decimation = demoProcs.decimation.active
    procs.decimationTimeRemaining = math.max(0, demoProcs.decimation.expires - currentTime)
    procs.metamorphosis = demoProcs.metamorphosis.active
    procs.metamorphosisTimeRemaining = math.max(0, demoProcs.metamorphosis.expires - currentTime)
    
    -- Affliction procs
    procs.deviciousMinds = self:HasBuff("player", S.DevicousMinds)
    procs.eradication = self:HasBuff("player", S.Eradication)
    
    -- Shadow Embrace tracking
    local _, _, _, shadowEmbraceStacks = UnitDebuff("target", S.ShadowEmbrace)
    procs.shadowEmbraceStacks = shadowEmbraceStacks or 0
    procs.shadowEmbraceTimeRemaining = self:DebuffTimeRemaining("target", S.ShadowEmbrace) or 0
    
    -- Haunt tracking
    procs.haunt = self:HasDebuff("target", S.Haunt)
    procs.hauntTimeRemaining = self:DebuffTimeRemaining("target", S.Haunt) or 0
    
    -- Combat phases (legacy compatibility)
    procs.executePhase = (newPhase == "execute")
    procs.burstPhase = (newPhase == "burst" or newPhase == "opener")
    
    return procs
end

-- ================================================================
-- MOLTEN CORE MANAGEMENT SYSTEM (15-20% DPS Gain)
-- ================================================================

-- Determine if Molten Core should be consumed immediately
function AC:ShouldConsumeMoltenCore()
    local demoProcs = self.DemonologyProcs
    if not demoProcs or not demoProcs.moltenCore then return false end
    
    local mc = demoProcs.moltenCore
    if not mc.active or mc.charges <= 0 then return false end
    
    local currentTime = GetTime()
    local timeRemaining = mc.expires - currentTime
    
    -- URGENT: Use immediately if about to expire
    if timeRemaining <= 3 then
        WarlockDebug("URGENT: Molten Core expiring in " .. string.format("%.1f", timeRemaining) .. "s - USE NOW!")
        return true
    end
    
    -- HIGH PRIORITY: Use if we have 3 charges (maximum)
    if mc.charges >= 3 then
        WarlockDebug("HIGH PRIORITY: Molten Core at max charges (" .. mc.charges .. ") - consume to avoid waste")
        return true
    end
    
    -- MEDIUM PRIORITY: Use if we're in execute phase (Decimation synergy)
    if demoProcs.combatPhase.current == "execute" and timeRemaining <= 8 then
        WarlockDebug("EXECUTE PHASE: Using Molten Core for burst damage")
        return true
    end
    
    -- STANDARD: Use if available and no higher priority spells
    if mc.charges > 0 and self:IsSpellKnown(S.Incinerate) then
        return true
    end
    
    return false
end

-- Get optimal spell to cast with Molten Core proc
function AC:GetMoltenCoreSpell()
    local demoProcs = self.DemonologyProcs
    if not demoProcs or not demoProcs.moltenCore.active then return nil end
    
    local playerLevel = UnitLevel("player")
    
    -- WotLK Meta: Molten Core benefits both Incinerate and Soul Fire
    -- Priority: Incinerate (faster cast, more casts per proc) > Soul Fire (higher damage)
    
    if playerLevel >= 64 and self:IsSpellKnown(S.Incinerate) then
        -- Incinerate with Molten Core: 30% faster cast + 18% damage
        WarlockDebug("Using Molten Core for Incinerate (30% faster, +18% damage)")
        return S.Incinerate
    elseif playerLevel >= 48 and self:IsSpellKnown(S.SoulFire) then
        -- Soul Fire with Molten Core: +18% damage + 15% crit
        WarlockDebug("Using Molten Core for Soul Fire (+18% damage, +15% crit)")
        return S.SoulFire
    end
    
    -- Fallback: Should not happen with proper level checking
    WarlockDebug("WARNING: Molten Core active but no compatible spells available")
    return nil
end

-- Track Molten Core usage for analytics
function AC:ConsumeMoltenCoreCharge()
    local demoProcs = self.DemonologyProcs
    if not demoProcs or not demoProcs.moltenCore then return end
    
    demoProcs.moltenCore.lastUsed = GetTime()
    demoProcs.moltenCore.totalUsed = (demoProcs.moltenCore.totalUsed or 0) + 1
    
    -- The buff system will automatically reduce charges when spell is cast
    -- We just track usage for analytics
    local charges = demoProcs.moltenCore.charges or 0
    WarlockDebug("Molten Core charge consumed - ~" .. math.max(0, charges - 1) .. " charges remaining")
end

-- ================================================================
-- DECIMATION MANAGEMENT SYSTEM (Execute Phase Optimization)
-- ================================================================

-- Check if Decimation should be used immediately
function AC:ShouldUseDecimation()
    local demoProcs = self.DemonologyProcs
    if not demoProcs or not demoProcs.decimation.active then return false end
    
    local currentTime = GetTime()
    local timeRemaining = demoProcs.decimation.expires - currentTime
    
    -- ALWAYS use Decimation immediately - it's a massive DPS gain
    -- 40% faster Soul Fire cast + no Soul Shard cost + 15% crit
    if timeRemaining > 0 then
        WarlockDebug("DECIMATION ACTIVE: Instant Soul Fire available (40% faster, no shard cost)")
        return true
    end
    
    return false
end

-- Track Decimation usage
function AC:UseDecimationProc()
    local demoProcs = self.DemonologyProcs
    if not demoProcs or not demoProcs.decimation then return end
    
    demoProcs.decimation.totalUsed = demoProcs.decimation.totalUsed + 1
    WarlockDebug("Decimation proc used - Total used: " .. demoProcs.decimation.totalUsed)
end

-- ================================================================
-- SHADOW BOLT DEBUFF MANAGEMENT SYSTEM (5% DPS Increase)
-- ================================================================

-- Check if Improved Shadow Bolt debuff needs refreshing
function AC:ShouldRefreshShadowBoltDebuff()
    local demoProcs = self.DemonologyProcs
    if not demoProcs or not demoProcs.improvedShadowBolt then return false end
    
    local isb = demoProcs.improvedShadowBolt
    local currentTime = GetTime()
    
    -- No debuff active - apply it
    if not isb.active then
        WarlockDebug("No Shadow Bolt debuff active - applying for 5% shadow damage increase")
        return true
    end
    
    -- Debuff expiring soon - refresh it
    local timeRemaining = isb.expires - currentTime
    if timeRemaining <= 5 then
        WarlockDebug("Shadow Bolt debuff expiring in " .. string.format("%.1f", timeRemaining) .. "s - refreshing")
        return true
    end
    
    -- Don't refresh if debuff is still strong
    return false
end

-- Track Shadow Bolt debuff applications
function AC:ApplyShadowBoltDebuff()
    local demoProcs = self.DemonologyProcs
    if not demoProcs or not demoProcs.improvedShadowBolt then return end
    
    WarlockDebug("Applied Improved Shadow Bolt debuff (+5% shadow damage to target)")
end

-- ================================================================
-- METAMORPHOSIS DECISION SYSTEM (Burst Window Optimization)
-- ================================================================

-- Determine if Metamorphosis should be used now
function AC:ShouldUseMetamorphosis()
    local demoProcs = self.DemonologyProcs
    if not demoProcs or not demoProcs.metamorphosis then return false end
    
    local meta = demoProcs.metamorphosis
    local phase = demoProcs.combatPhase
    
    -- Already in Metamorphosis
    if meta.active then return false end
    
    -- Metamorphosis not available
    if not meta.cooldownReady then return false end
    
    -- Check if we should use Metamorphosis based on situation
    local currentTime = GetTime()
    local playerLevel = UnitLevel("player")
    local enemyCount = self:GetNearbyEnemyCount(10) or 1
    
    -- PRIORITY 1: AoE situations (3+ enemies)
    if enemyCount >= 3 then
        WarlockDebug("METAMORPHOSIS: AoE situation detected (" .. enemyCount .. " enemies)")
        return true
    end
    
    -- PRIORITY 2: Execute phase for burst damage
    if phase.current == "execute" then
        WarlockDebug("METAMORPHOSIS: Execute phase - using for burst damage")
        return true
    end
    
    -- PRIORITY 3: Opener on high-health targets (long fights)
    if phase.current == "opener" and phase.targetHealthPercent > 90 then
        WarlockDebug("METAMORPHOSIS: Opener on fresh target")
        return true
    end
    
    -- PRIORITY 4: Burst window with procs
    if phase.current == "burst" and (demoProcs.moltenCore.active or demoProcs.decimation.active) then
        WarlockDebug("METAMORPHOSIS: Burst window with active procs")
        return true
    end
    
    -- EMERGENCY: Low health for survivability
    local playerHealthPercent = (UnitHealth("player") / UnitHealthMax("player")) * 100
    if playerHealthPercent < 25 and UnitAffectingCombat("player") then
        WarlockDebug("METAMORPHOSIS: Emergency use for survivability")
        return true
    end
    
    return false
end

-- Track Metamorphosis usage
function AC:UseMetamorphosis()
    local demoProcs = self.DemonologyProcs
    if not demoProcs or not demoProcs.metamorphosis then return end
    
    demoProcs.metamorphosis.optimalUseWindows = demoProcs.metamorphosis.optimalUseWindows + 1
    WarlockDebug("Metamorphosis activated - Total optimal uses: " .. demoProcs.metamorphosis.optimalUseWindows)
end

-- Enhanced function to check if we should consume procs immediately or save them
function AC:ShouldConsumeProcImmediately(procName, procTimeRemaining)
    local urgency = "normal"
    
    -- Time-sensitive procs should be consumed quickly
    if procTimeRemaining <= 3 then
        urgency = "urgent"
    elseif procTimeRemaining <= 6 then
        urgency = "soon"
    end
    
    -- Special cases for specific procs
    if procName == "backdraft" then
        -- Backdraft should be consumed with Incinerate/Shadow Bolt, but save 1 stack for Chaos Bolt if available
        return urgency ~= "normal" or self:GetSpellCooldown(S.ChaosBolt) > 5
    elseif procName == "decimation" then
        -- Decimation should always be consumed immediately for Soul Fire
        return true
    elseif procName == "moltenCore" then
        -- Use new Molten Core management system
        return self:ShouldConsumeMoltenCore()
    end
    
    return urgency == "urgent"
end

-- ================================================================
-- DEMONIC EMPOWERMENT MACRO INTEGRATION (Automatic Pet Buffing)
-- ================================================================

-- Handle Demonic Empowerment with smart timing
function AC:HandleDemonicEmpowerment()
    if not self:IsSpellKnown(S.DemonicEmpowerment) then return false end
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then return false end
    
    -- Throttle to prevent spam but allow reasonable frequency
    if not self:ActionThrottle("DemonicEmpowerment", 2) then return false end
    
    local demoProcs = self:EnsureDemonologyProcState()
    local meta = demoProcs and demoProcs.metamorphosis
    local phase = demoProcs and demoProcs.combatPhase
    local inCombat = UnitAffectingCombat("player")
    local petInCombat = UnitExists("pettarget") and UnitCanAttack("pet", "pettarget")
    
    -- Check if Demonic Empowerment is on cooldown
    local cooldown = self:GetSpellCooldown(S.DemonicEmpowerment)
    if cooldown > 0 then
        WarlockDebug("Demonic Empowerment on cooldown (" .. string.format("%.1f", cooldown) .. "s)")
        return false
    end
    
    -- PRIORITY 1: Use during combat when pet is engaged
    if inCombat and petInCombat then
        if self:CanCast(S.DemonicEmpowerment) then
            WarlockDebug("DEMONIC EMPOWERMENT: Combat buff (+20% pet attack speed)")
            return S.DemonicEmpowerment
        end
    end
    
    -- PRIORITY 2: Use during Metamorphosis for synergy
    if meta and meta.active then
        if self:CanCast(S.DemonicEmpowerment) then
            WarlockDebug("DEMONIC EMPOWERMENT: Metamorphosis synergy")
            return S.DemonicEmpowerment
        end
    end
    
    -- PRIORITY 3: Use during execute phase for maximum DPS
    if phase and phase.current == "execute" then
        if self:CanCast(S.DemonicEmpowerment) then
            WarlockDebug("DEMONIC EMPOWERMENT: Execute phase boost")
            return S.DemonicEmpowerment
        end
    end
    
    -- PRIORITY 4: Use at start of combat for immediate benefit
    if inCombat and phase and phase.current == "opener" then
        if self:CanCast(S.DemonicEmpowerment) then
            WarlockDebug("DEMONIC EMPOWERMENT: Combat opener")
            return S.DemonicEmpowerment
        end
    end
    
    return false
end

-- Macro-style integration for Demonic Empowerment
function AC:TryDemonicEmpowermentMacro(primarySpell)
    if not primarySpell then return false end
    
    local spec = self:GetWarlockSpec()
    if spec ~= "Demonology" then return false end
    
    -- Only try to cast DE if it would be beneficial
    local deSpell = self:HandleDemonicEmpowerment()
    if deSpell then
        -- Try to cast Demonic Empowerment first, then the primary spell
        if self:CastWarlockSpell(deSpell, "pet") then
            WarlockDebug("MACRO: Cast Demonic Empowerment before " .. primarySpell)
            -- Don't return the primary spell this time, let it be cast next cycle
            return true
        end
    end
    
    return false
end

-- ================================================================
-- ENHANCED RESOURCE MANAGEMENT (Life Tap Optimization)
-- ================================================================

-- Smart Life Tap usage based on combat phase and procs
function AC:GetOptimalLifeTapTiming(spec, inCombat, procs, demoProcs)
    local manaPercent = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100
    local healthPercent = (UnitHealth("player") / UnitHealthMax("player")) * 100
    
    -- Base thresholds
    local manaThreshold = 70
    local healthThreshold = 60
    
    -- Demonology-specific adjustments
    if spec == "Demonology" and demoProcs then
        local phase = demoProcs.combatPhase.current
        
        -- Execute phase: prioritize mana for Soul Fire spam
        if phase == "execute" then
            manaThreshold = 80
            healthThreshold = 50 -- More aggressive
        end
        
        -- Burst phase: ensure mana for proc usage
        if phase == "burst" or demoProcs.moltenCore.active then
            manaThreshold = 75
            healthThreshold = 55
        end
        
        -- Metamorphosis: can be more aggressive due to survivability boost
        if demoProcs.metamorphosis.active then
            healthThreshold = 40 -- Very aggressive
        end
    end
    
    -- Combat adjustments
    if inCombat then
        healthThreshold = healthThreshold + 15 -- More conservative in combat
    else
        healthThreshold = healthThreshold - 10 -- More aggressive out of combat
    end
    
    -- Check if we should Life Tap
    local shouldLifeTap = manaPercent < manaThreshold and healthPercent > healthThreshold
    
    if shouldLifeTap then
        WarlockDebug("LIFE TAP: Mana " .. string.format("%.1f", manaPercent) .. "% < " .. manaThreshold .. "%, Health " .. string.format("%.1f", healthPercent) .. "% > " .. healthThreshold .. "%")
        return true
    end
    
    return false
end

-- Enhanced Life Tap integration with Demonology rotation
function AC:ManageWarlockLifeTap()
    local spec = self:GetWarlockSpec()
    local inCombat = UnitAffectingCombat("player")
    local procs = self.WarlockProcs
    local demoProcs = self:EnsureDemonologyProcState()
    
    if self:GetOptimalLifeTapTiming(spec, inCombat, procs, demoProcs) then
        if self:CanCast(S.LifeTap) then
            WarlockDebug("ENHANCED LIFE TAP: Phase-optimized mana conversion")
            return S.LifeTap
        end
    end
    
    return nil
end

-- ================================================================
-- ENHANCED PET STATUS AND MANAGEMENT SYSTEM
-- ================================================================
function AC:GetWarlockPetStatus()
    if not UnitExists("pet") then 
        return "nopet" 
    elseif UnitIsDeadOrGhost("pet") then 
        return "dead" 
    elseif UnitChannelInfo("player") == "Summon Imp" or 
           UnitChannelInfo("player") == "Summon Voidwalker" or
           UnitChannelInfo("player") == "Summon Succubus" or
           UnitChannelInfo("player") == "Summon Felhunter" or
           UnitChannelInfo("player") == "Summon Felguard" then
        return "summoning"
    else 
        return "alive" 
    end
end

-- Get current pet stance (adapted from Hunter system)
function AC:GetWarlockPetStance()
    if not UnitExists("pet") then return "No Pet" end
    
    -- Check pet action bar for stance indicators
    for i = 1, 12 do
        local name, _, _, _, isActive = GetPetActionInfo(i)
        if name and isActive then
            local nameLower = string.lower(name)
            if string.find(nameLower, "passive") then 
                return "Passive"
            elseif string.find(nameLower, "defensive") then 
                return "Defensive" 
            elseif string.find(nameLower, "aggressive") then 
                return "Aggressive"
            end
        end
    end
    return "Unknown"
end

-- Set pet stance by name (adapted from Hunter system)
function AC:SetWarlockPetStance(stanceName)
    if not UnitExists("pet") then return false end
    if not stanceName then return false end
    
    local currentStance = self:GetWarlockPetStance()
    if currentStance == stanceName then
        WarlockDebug("Pet already in " .. stanceName .. " stance")
        return true
    end
    
    -- Find and activate the stance
    local targetName = string.lower(stanceName)
    for i = 1, 12 do
        local name = GetPetActionInfo(i)
        if name then
            local nameLower = string.lower(name)
            if string.find(nameLower, targetName) then
                CastPetAction(i)
                WarlockDebug("Set pet stance to: " .. name .. " (requested: " .. stanceName .. ")")
                return true
            end
        end
    end
    return false
end

-- Determine optimal pet stance based on situation (adapted from Hunter logic)
function AC:GetOptimalWarlockPetStance()
    if not UnitExists("pet") then return nil end
    
    local inCombat = UnitAffectingCombat("player")
    local isInGroup = IsInGroup()
    local playerHealth = (UnitHealth("player") / UnitHealthMax("player")) * 100
    local hasHostileTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- Passive stance conditions (highest priority)
    if playerHealth < 15 then
        WarlockDebug("Pet stance logic: Passive (emergency - low health)")
        return "Passive"
    end
    
    if not inCombat and isInGroup then
        WarlockDebug("Pet stance logic: Passive (out of combat in group)")
        return "Passive" 
    end
    
    -- Defensive stance conditions (group play and general combat)
    if inCombat and isInGroup then
        WarlockDebug("Pet stance logic: Defensive (in group)")
        return "Defensive"
    end
    
    if inCombat and hasHostileTarget and playerHealth > 50 then
        WarlockDebug("Pet stance logic: Defensive (in combat with target)")
        return "Defensive"
    end
    
    -- Aggressive stance conditions (solo play)
    if not isInGroup and inCombat and playerHealth > 30 then
        WarlockDebug("Pet stance logic: Aggressive (solo combat)")
        return "Aggressive"
    end
    
    -- Default to Defensive for safety
    WarlockDebug("Pet stance logic: Defensive (default)")
    return "Defensive"
end

-- Smart pet stance management (adapted from Hunter system)
function AC:ManageWarlockPetStance()
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then return false end
    if not self:ActionThrottle("WarlockPetStanceManagement", 3) then return false end
    
    local optimalStance = self:GetOptimalWarlockPetStance()
    local currentStance = self:GetWarlockPetStance()
    
    if not optimalStance then return false end
    
    if currentStance ~= optimalStance then
        WarlockDebug(string.format("Pet stance change: %s -> %s", 
            currentStance or "Unknown", optimalStance))
        return self:SetWarlockPetStance(optimalStance)
    end
    
    return false
end

-- Emergency pet passive for dangerous situations
function AC:EmergencyWarlockPetPassive()
    if not UnitExists("pet") then return false end
    
    local playerHealth = (UnitHealth("player") / UnitHealthMax("player")) * 100
    local inInstance = IsInInstance()
    local _, instanceType = IsInInstance()
    
    -- Force passive in dangerous situations
    if playerHealth < 20 then
        WarlockDebug("Emergency: Setting pet to Passive (low health)")
        return self:SetWarlockPetStance("Passive")
    end
    
    if inInstance and (instanceType == "party" or instanceType == "raid") then
        local currentStance = self:GetWarlockPetStance()
        if currentStance == "Aggressive" then
            WarlockDebug("Emergency: Setting pet to Defensive (in instance)")
            return self:SetWarlockPetStance("Defensive")
        end
    end
    
    return false
end

-- Pet ability management (toggle autocast for key abilities)
function AC:ManageWarlockPetAbilities()
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then return false end
    if not self:ActionThrottle("WarlockPetAbilities", 5) then return false end
    
    local petType = self:GetWarlockPetType()
    local isInGroup = IsInGroup()
    
    if petType == "Voidwalker" then
        -- Manage Torment/Suffering autocast based on group status
        local shouldTaunt = not isInGroup
        self:ToggleWarlockPetSpell("Torment", shouldTaunt)
        self:ToggleWarlockPetSpell("Suffering", shouldTaunt)
        WarlockDebug("Voidwalker taunting: " .. tostring(shouldTaunt))
        
    elseif petType == "Felhunter" then
        -- Always enable Spell Lock for interrupts
        self:ToggleWarlockPetSpell("Spell Lock", true)
        -- Enable Devour Magic for dispelling
        self:ToggleWarlockPetSpell("Devour Magic", true)
        
    elseif petType == "Succubus" then
        -- Enable Lash of Pain for DPS
        self:ToggleWarlockPetSpell("Lash of Pain", true)
        -- Disable Seduction in groups (avoid unwanted CC)
        self:ToggleWarlockPetSpell("Seduction", not isInGroup)
        
    elseif petType == "Felguard" then
        -- Keep Cleave enabled for consistent DPS.
        self:ToggleWarlockPetSpell("Cleave", true)
        -- Manage Anguish taunt like Voidwalker
        self:ToggleWarlockPetSpell("Anguish", not isInGroup)
        
    elseif petType == "Imp" then
        -- Enable Fire Shield on master for protection
        self:ToggleWarlockPetSpell("Fire Shield", true)
    end
    
    return false
end

-- Toggle pet spell autocast (similar to Hunter TogglePetSpell)
function AC:ToggleWarlockPetSpell(spellName, enable)
    if not spellName then return false end

    for i = 1, 12 do
        local name, _, _, _, _, currentIsAutocast = GetPetActionInfo(i)

        if name and name == spellName then
            if enable and not currentIsAutocast then
                WarlockDebug("Enabling autocast for " .. spellName)
                TogglePetAutocast(i)
                return true
            elseif not enable and currentIsAutocast then
                WarlockDebug("Disabling autocast for " .. spellName)
                TogglePetAutocast(i)
                return true
            end
            return true
        end
    end
    return false
end

-- Pet health monitoring and emergency healing
function AC:WarlockPetNeedsHealing()
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then return false end
    
    local petHealthPct = (UnitHealth("pet") / UnitHealthMax("pet")) * 100
    local playerHealthPct = (UnitHealth("player") / UnitHealthMax("player")) * 100
    
    -- Need healing if pet is below 50% and player is above 60%
    return petHealthPct < 50 and playerHealthPct > 60
end

-- Enhanced pet management function replacing the old one
function AC:ManageWarlockPetAdvanced()
    -- Don't manage pets while mounted
    if IsMounted() then return nil end
    
    -- Throttle pet management to prevent spam
    if not self:ActionThrottle("WarlockPetManagement", 0.5) then return nil end
    
    local petStatus = self:GetWarlockPetStatus()
    local inCombat = UnitAffectingCombat("player")
    local isCasting = UnitCastingInfo("player") ~= nil or UnitChannelInfo("player") ~= nil
    
    -- Don't interrupt existing summoning
    if petStatus == "summoning" then
        WarlockDebug("Currently summoning pet...")
        return nil
    end
    
    -- Priority 1: Summon missing pet
    if petStatus == "nopet" then
        -- Avoid failed summon loops while moving/casting/in combat.
        if inCombat or self:IsPlayerMoving() or isCasting then
            return nil
        end

        local spec = self:GetWarlockSpec()
        local playerLevel = UnitLevel("player")
        
        -- Choose optimal pet based on spec and situation
        local petToSummon = self:GetOptimalWarlockPet(spec, playerLevel, inCombat)
        if petToSummon and self:CanCast(petToSummon) then
            WarlockDebug("Summoning " .. petToSummon .. " (no pet active)")
            return petToSummon
        end
    end
    
    -- Priority 2: Resurrect dead pet (Warlocks need to resummon)
    if petStatus == "dead" then
        if inCombat or self:IsPlayerMoving() or isCasting then
            return nil
        end

        WarlockDebug("Pet is dead - need to resummon")
        local spec = self:GetWarlockSpec()
        local playerLevel = UnitLevel("player")
        local petToSummon = self:GetOptimalWarlockPet(spec, playerLevel, inCombat)
        if petToSummon and self:CanCast(petToSummon) then
            return petToSummon
        end
    end
    
    -- Priority 3: Manage living pet
    if petStatus == "alive" then
        local spec = self:GetWarlockSpec()
        local playerLevel = UnitLevel("player")

        -- Keep demon aligned to current spec while out of combat.
        if not inCombat and not self:IsPlayerMoving() and not isCasting then
            local optimalPet = self:GetOptimalWarlockPet(spec, playerLevel, inCombat)
            if optimalPet and not self:IsCurrentPetMatchingSummonSpell(optimalPet) then
                if self:ActionThrottle("WarlockPetSwapBySpec", 15) and self:CanCast(optimalPet) then
                    WarlockDebug("Swapping pet for spec optimization: " .. tostring(optimalPet))
                    return optimalPet
                end
            end
        end

        -- Emergency stance management (highest priority)
        if self:EmergencyWarlockPetPassive() then return nil end
        
        -- Pet healing with Health Funnel
        if self:WarlockPetNeedsHealing() and not inCombat then
            if self:IsSpellKnown("Health Funnel") and self:CanCast("Health Funnel") then
                WarlockDebug("Using Health Funnel to heal pet")
                return "Health Funnel"
            end
        end
        
        -- Manage pet stance intelligently
        if self:ManageWarlockPetStance() then return nil end
        
        -- Manage pet abilities/autocast
        self:ManageWarlockPetAbilities()
        
        -- Pet attack targeting (establish aggro while warlock casts)
        self:ManageWarlockPetTargeting()
        
        -- Demonic Empowerment for Demonology (macro integration)
        if spec == "Demonology" and UnitExists("pet") then
            self:HandleDemonicEmpowerment()
        end
    end
    
    return nil
end

-- Choose optimal pet based on spec, level, and situation
function AC:GetOptimalWarlockPet(spec, playerLevel, inCombat)
    -- Demonology always uses Felguard if available
    if spec == "Demonology" and playerLevel >= 50 and self:IsSpellKnown(S.SummonFelguard) then
        return S.SummonFelguard
    end
    
    -- Affliction prefers Felhunter for Shadow Bite scaling with DoTs
    if spec == "Affliction" and playerLevel >= 30 and self:IsSpellKnown(S.SummonFelhunter) then
        return S.SummonFelhunter
    end
    
    -- Destruction prefers Imp for ranged safety and buffs
    if spec == "Destruction" and self:IsSpellKnown(S.SummonImp) then
        return S.SummonImp
    end
    
    -- Leveling priority: Voidwalker for tanking, then Felhunter for utility
    if playerLevel >= 30 and self:IsSpellKnown(S.SummonFelhunter) then
        return S.SummonFelhunter
    elseif playerLevel >= 10 and self:IsSpellKnown(S.SummonVoidwalker) then
        return S.SummonVoidwalker
    elseif self:IsSpellKnown(S.SummonImp) then
        return S.SummonImp
    end
    
    return nil
end

-- Send pet to attack target (adapted from Hunter system)
function AC:SendWarlockPetToAttack(targetUnit)
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then
        return false
    end
    
    if not UnitExists(targetUnit) or UnitIsDeadOrGhost(targetUnit) then
        return false
    end
    
    -- Don't send pet to attack friendly targets
    if not UnitCanAttack("player", targetUnit) then
        return false
    end
    
    -- Use PetAttack() API to send pet to target
    PetAttack(targetUnit)
    WarlockDebug("Pet sent to attack: " .. (UnitName(targetUnit) or "Unknown"))
    return true
end

-- Smart pet targeting for Warlocks (simpler than Hunter version)
function AC:ManageWarlockPetTargeting()
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then return false end
    if not self:ActionThrottle("WarlockPetTargeting", 1) then return false end
    
    local playerTarget = UnitExists("target") and "target" or nil
    local currentPetTarget = UnitExists("pettarget") and "pettarget" or nil
    local inCombat = UnitAffectingCombat("player")
    
    -- Priority 1: Attack player's target if it's hostile and pet isn't already attacking it
    if playerTarget and UnitCanAttack("player", playerTarget) and not UnitIsDeadOrGhost(playerTarget) then
        -- Check if pet is already attacking the player's target
        if not currentPetTarget or not UnitIsUnit(currentPetTarget, playerTarget) then
            WarlockDebug("Sending pet to attack player's target: " .. (UnitName(playerTarget) or "Unknown"))
            return self:SendWarlockPetToAttack(playerTarget)
        end
    end
    
    -- Priority 2: In combat, if pet has no target but there are nearby enemies
    if inCombat and not currentPetTarget then
        -- Simple fallback: attack player's target if available
        if playerTarget and UnitCanAttack("player", playerTarget) and not UnitIsDeadOrGhost(playerTarget) then
            WarlockDebug("Pet has no target in combat - attacking player's target")
            return self:SendWarlockPetToAttack(playerTarget)
        end
    end
    
    -- Priority 3: Keep pet attacking current target if it's still valid
    if currentPetTarget then
        if UnitIsDeadOrGhost(currentPetTarget) or not UnitCanAttack("player", currentPetTarget) then
            -- Current pet target is invalid, clear it by attacking player's target
            if playerTarget and UnitCanAttack("player", playerTarget) and not UnitIsDeadOrGhost(playerTarget) then
                WarlockDebug("Pet's current target is invalid - switching to player's target")
                return self:SendWarlockPetToAttack(playerTarget)
            end
        end
    end
    
    return false
end

-- Enhanced pet target management for different combat scenarios
function AC:WarlockPetCombatAssistance()
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then return false end
    
    local petType = self:GetWarlockPetType()
    local playerTarget = UnitExists("target") and "target" or nil
    local inCombat = UnitAffectingCombat("player") 
    local isInGroup = IsInGroup()
    
    -- Only drive attack assistance during combat to avoid accidental pre-pulls.
    if not inCombat then
        return false
    end

    -- Voidwalker specific: Establish threat quickly
    if petType == "Voidwalker" and not isInGroup then
        if playerTarget and UnitCanAttack("player", playerTarget) then
            local currentPetTarget = UnitExists("pettarget") and "pettarget" or nil
            
            -- Send Voidwalker to attack immediately when Warlock targets new enemy
            if not currentPetTarget or not UnitIsUnit(currentPetTarget, playerTarget) then
                WarlockDebug("Voidwalker establishing threat on: " .. (UnitName(playerTarget) or "Unknown"))
                return self:SendWarlockPetToAttack(playerTarget)
            end
        end
    end
    
    -- Felguard specific: Aggressive targeting for Demonology
    if petType == "Felguard" then
        if playerTarget and UnitCanAttack("player", playerTarget) then
            local currentPetTarget = UnitExists("pettarget") and "pettarget" or nil
            
            -- Felguard should always match player's target for maximum DPS
            if not currentPetTarget or not UnitIsUnit(currentPetTarget, playerTarget) then
                WarlockDebug("Felguard matching player target: " .. (UnitName(playerTarget) or "Unknown"))
                return self:SendWarlockPetToAttack(playerTarget)
            end
        end
    end
    
    -- Other pets: Standard targeting
    if petType == "Felhunter" or petType == "Succubus" or petType == "Imp" then
        if inCombat and playerTarget and UnitCanAttack("player", playerTarget) then
            local currentPetTarget = UnitExists("pettarget") and "pettarget" or nil
            
            -- Send pet to attack if no current target or different target
            if not currentPetTarget or not UnitIsUnit(currentPetTarget, playerTarget) then
                WarlockDebug(petType .. " attacking player target: " .. (UnitName(playerTarget) or "Unknown"))
                return self:SendWarlockPetToAttack(playerTarget)
            end
        end
    end
    
    return false
end

-- ================================================================
-- SOUL SHARD MANAGEMENT
-- ================================================================
function AC:GetSoulShardCount()
    local shardCount = 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local itemID = tonumber(itemLink:match("item:(%d+)"))
                if itemID == 6265 then -- Soul Shard ID
                    local _, stackCount = GetContainerItemInfo(bag, slot)
                    shardCount = shardCount + (stackCount or 1)
                end
            end
        end
    end
    return shardCount
end

function AC:ShouldGatherSoulShards()
    local currentShards = self:GetSoulShardCount()
    local complexity = self:GetRotationComplexity()
    
    -- ENHANCED: Smart shard thresholds based on player level and complexity
    local targetShards = 20 -- Default WotLK target
    if complexity == "BASIC" then
        targetShards = 10 -- Lower requirement for leveling
    elseif complexity == "SIMPLE" then
        targetShards = 15 -- Moderate requirement
    end
    
    -- Don't gather if we have enough or are in a group (etiquette)
    if IsInGroup() or currentShards >= targetShards then
        return false
    end
    
    -- Only gather from appropriate level targets that give XP
    if not UnitExists("target") then return false end
    local targetLevel = UnitLevel("target")
    local playerLevel = UnitLevel("player")
    
    -- Don't gather from trivial targets
    if targetLevel <= (playerLevel - 8) then return false end
    if UnitClassification("target") == "trivial" then return false end
    
    return true
end

-- ================================================================
-- PET MANAGEMENT SYSTEM
-- ================================================================
function AC:GetWarlockPetType()
    if not UnitExists("pet") then return nil end
    local petName = UnitName("pet")

    local byName = self:NormalizeWarlockPetType(petName)
    if byName then
        return byName
    end

    -- Alternative detection by creature family
    local creatureFamily = UnitCreatureFamily("pet")
    local byFamily = self:NormalizeWarlockPetType(creatureFamily)
    if byFamily then
        return byFamily
    end

    -- Fallback by pet action bar (works if names are localized/customized).
    local byAction = self:InferWarlockPetTypeFromActions()
    if byAction then
        return byAction
    end

    return "Unknown"
end

-- OLD PET MANAGEMENT FUNCTION - REPLACED BY ManageWarlockPetAdvanced()
-- REMOVED: Dead code - replaced by ManageWarlockPetAdvanced() and related functions

-- ================================================================
-- SPEC DETECTION 
-- ================================================================
function AC:GetWarlockSpec()
    -- Prefer core talent-based spec detection when available.
    if self.GetPlayerSpec then
        local coreSpec = self:GetPlayerSpec()
        if coreSpec == "Affliction" or coreSpec == "Demonology" or coreSpec == "Destruction" then
            return coreSpec
        end
    end
    
    -- Spell-based fallback for very low-level/edge cases.
    if self:IsSpellKnown(S.Haunt) then
        return "Affliction"
    elseif self:IsSpellKnown(S.Metamorphosis) then
        return "Demonology"
    elseif self:IsSpellKnown(S.ChaosBolt) then
        return "Destruction"
    end

    -- Additional fallback detection based on available spells
    if self:IsSpellKnown(S.UnstableAffliction) then
        return "Affliction"
    elseif self:IsSpellKnown(S.SummonFelguard) then
        return "Demonology"
    elseif self:IsSpellKnown(S.Incinerate) then
        return "Destruction"
    end
    
    -- No reliable spec information yet. Let the rotation use the leveling
    -- fallback instead of pretending to be a full endgame spec.
    return "None"
end

-- ================================================================
-- BUFF MANAGEMENT
-- ================================================================
function AC:ManageWarlockBuffs()
    -- Armor selection based on spec and level
    local spec = self:GetWarlockSpec()
    local playerLevel = UnitLevel("player")
    
    -- Fel Armor for DPS (level 28+)
    if playerLevel >= 28 and self:IsSpellKnown(S.FelArmor) then
        if not self:HasBuff("player", S.FelArmor) and self:CanCast(S.FelArmor) then
            WarlockDebug("Casting Fel Armor for DPS")
            return S.FelArmor
        end
    -- Demon Armor for survivability (level 20+)
    elseif playerLevel >= 20 and self:IsSpellKnown(S.DemonArmor) then
        if not self:HasBuff("player", S.DemonArmor) and self:CanCast(S.DemonArmor) then
            WarlockDebug("Casting Demon Armor for survivability")
            return S.DemonArmor
        end
    -- Demon Skin for early levels
    elseif self:IsSpellKnown(S.DemonSkin) then
        if not self:HasBuff("player", S.DemonSkin) and self:CanCast(S.DemonSkin) then
            WarlockDebug("Casting Demon Skin")
            return S.DemonSkin
        end
    end
    
    -- Soul Link for Demonology (level 20+)
    if spec == "Demonology" and UnitExists("pet") and playerLevel >= 20 then
        if self:IsSpellKnown(S.SoulLink) and not self:HasBuff("player", S.SoulLink) then
            if self:CanCast(S.SoulLink) then
                WarlockDebug("Casting Soul Link for damage sharing")
                return S.SoulLink
            end
        end
    end
    
    -- Shadow Ward for defensive magic protection
    if playerLevel >= 32 and self:IsSpellKnown(S.ShadowWard) then
        if not self:HasBuff("player", S.ShadowWard) and self:CanCast(S.ShadowWard) then
            -- Only cast if we're taking magic damage or about to
            if InCombatLockdown() or UnitExists("target") then
                WarlockDebug("Casting Shadow Ward for magic protection")
                return S.ShadowWard
            end
        end
    end
    
    -- Unending Breath (not just for swimming)
    if not self:HasBuff("player", S.UnendingBreath) then
        if self:IsSpellKnown(S.UnendingBreath) and self:CanCast(S.UnendingBreath) then
            WarlockDebug("Casting Unending Breath")
            return S.UnendingBreath
        end
    end
    
    return nil
end

-- ================================================================
-- ENHANCED CONSUMABLE AND RESOURCE MANAGEMENT (WotLK Meta)
-- ================================================================
function AC:ManageWarlockConsumables(procs)
    local manaPercent = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100
    local healthPercent = (UnitHealth("player") / UnitHealthMax("player")) * 100
    local spec = self:GetWarlockSpec()
    local inCombat = UnitAffectingCombat("player")
    procs = procs or self.WarlockProcs or self:UpdateWarlockProcs()
    
    -- Emergency mana potions (use before Life Tap when critically low)
    if manaPercent < 20 then
        if self.UseManaPotion and self:UseManaPotion(20) then
            WarlockDebug("Used mana potion at " .. string.format("%.0f", manaPercent) .. "% mana")
            return nil -- Let potion take effect
        end
    end
    
    -- ENHANCED: Smart Life Tap with phase-aware optimization
    local enhancedLifeTap = self:ManageWarlockLifeTap()
    if enhancedLifeTap then
        return enhancedLifeTap
    end
    
    -- ENHANCED: Smart Dark Pact usage considering pet type and situation
    if manaPercent < 25 and UnitExists("pet") and (UnitPowerType("pet") or -1) == 0 then
        local petManaPercent = (UnitPower("pet", 0) / UnitPowerMax("pet", 0)) * 100
        local petType = self:GetWarlockPetType()
        
        -- Different thresholds based on pet importance
        local petManaThreshold = 50
        if petType == "Felhunter" then
            petManaThreshold = 60 -- Keep more mana for interrupts
        elseif petType == "Felguard" then
            petManaThreshold = 40 -- Less mana-dependent
        end
        
        if petManaPercent > petManaThreshold and self:IsSpellKnown(S.DarkPact) and self:CanCast(S.DarkPact) then
            WarlockDebug("Using Dark Pact (" .. petType .. " has " .. string.format("%.1f", petManaPercent) .. "% mana)")
            return S.DarkPact
        end
    end
    
    -- ENHANCED: Dynamic health thresholds based on combat situation
    local healthstoneThreshold = self:GetOptimalHealthstoneThreshold(inCombat)
    
    if healthPercent < healthstoneThreshold then
        local healthstone = self:GetHealthstone()
        if healthstone and self:CanUseItem(healthstone) then
            WarlockDebug("Using Healthstone (threshold: " .. healthstoneThreshold .. "%)")
            return "item:" .. healthstone
        end
    end
    
    return nil
end

-- Calculate optimal Life Tap thresholds based on spec and combat state
function AC:GetOptimalLifeTapThreshold(spec, inCombat, procs)
    local threshold = {mana = 70, health = 60}
    
    -- Spec-specific adjustments
    if spec == "Affliction" then
        -- Affliction needs more mana for DoT maintenance
        threshold.mana = 75
        threshold.health = 65
        
        -- During DoT application phase, be more aggressive
        if procs.shadowEmbraceStacks < 3 or procs.hauntTimeRemaining < 5 then
            threshold.mana = 80
            threshold.health = 70
        end
    elseif spec == "Destruction" then
        -- Destruction has burst windows, save health for those
        threshold.mana = 65
        threshold.health = 55
        
        -- During proc windows, prioritize mana
        if procs.backdraftStacks > 0 or procs.moltenCore then
            threshold.mana = 75
            threshold.health = 70
        end
    elseif spec == "Demonology" then
        -- Demonology can be more conservative due to pet tanking
        threshold.mana = 70
        threshold.health = 50
        
        -- During Metamorphosis, prioritize mana
        if procs.metamorphosis then
            threshold.mana = 80
            threshold.health = 65
        end
    end
    
    -- Combat adjustments
    if inCombat then
        -- Be more conservative with health in combat
        threshold.health = threshold.health + 10
    else
        -- Out of combat, can be more aggressive
        threshold.health = threshold.health - 10
    end
    
    -- Execute phase adjustments
    if procs.executePhase then
        threshold.mana = 60 -- Less mana needed for execute spells
        threshold.health = threshold.health + 15 -- Preserve health for survival
    end
    
    return threshold
end

-- Calculate optimal Healthstone usage threshold
function AC:GetOptimalHealthstoneThreshold(inCombat)
    local baseThreshold = 35
    
    if inCombat then
        -- Use earlier in combat for safety
        baseThreshold = 45
        
        -- Check if taking heavy damage
        local recentDamage = self:GetRecentDamageTaken(3) -- Last 3 seconds
        if recentDamage and recentDamage > (UnitHealthMax("player") * 0.3) then
            baseThreshold = 55 -- Very aggressive if taking heavy damage
        end
    end
    
    -- Group play adjustments
    if IsInGroup() then
        local hasHealer = false
        local numMembers = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
        
        for i = 1, numMembers do
            local unit = GetNumRaidMembers() > 0 and "raid"..i or "party"..i
            if UnitExists(unit) then
                local _, class = UnitClass(unit)
                if class == "PRIEST" or class == "PALADIN" or class == "SHAMAN" or class == "DRUID" then
                    hasHealer = true
                    break
                end
            end
        end
        
        if hasHealer then
            baseThreshold = baseThreshold - 10 -- Can rely on healer more
        else
            baseThreshold = baseThreshold + 10 -- No healer, be more careful
        end
    end
    
    return math.max(baseThreshold, 20) -- Never go below 20%
end

-- Normalize pet type strings to stable internal labels.
function AC:NormalizeWarlockPetType(rawType)
    if not rawType or type(rawType) ~= "string" then
        return nil
    end

    local t = string.lower(rawType)
    if string.find(t, "felguard") then return "Felguard" end
    if string.find(t, "felhunter") then return "Felhunter" end
    if string.find(t, "voidwalker") then return "Voidwalker" end
    if string.find(t, "succubus") or string.find(t, "sayaad") then return "Succubus" end
    if string.find(t, "imp") then return "Imp" end

    return nil
end

-- Infer pet type from pet bar abilities (localization-friendly fallback).
function AC:InferWarlockPetTypeFromActions()
    for i = 1, 12 do
        local actionName = GetPetActionInfo(i)
        if actionName and type(actionName) == "string" then
            local lower = string.lower(actionName)
            if lower == "torment" or lower == "suffering" or lower == "consume shadows" then
                return "Voidwalker"
            elseif lower == "spell lock" or lower == "devour magic" or lower == "shadow bite" then
                return "Felhunter"
            elseif lower == "lash of pain" or lower == "seduction" or lower == "lesser invisibility" then
                return "Succubus"
            elseif lower == "cleave" or lower == "intercept" or lower == "anguish" then
                return "Felguard"
            elseif lower == "firebolt" or lower == "fire shield" or lower == "phase shift" then
                return "Imp"
            end
        end
    end
    return nil
end

function AC:GetExpectedPetTypeForSummonSpell(summonSpell)
    if summonSpell == S.SummonFelguard then return "Felguard" end
    if summonSpell == S.SummonFelhunter then return "Felhunter" end
    if summonSpell == S.SummonVoidwalker then return "Voidwalker" end
    if summonSpell == S.SummonSuccubus then return "Succubus" end
    if summonSpell == S.SummonImp then return "Imp" end
    return nil
end

function AC:IsCurrentPetMatchingSummonSpell(summonSpell)
    local expected = self:GetExpectedPetTypeForSummonSpell(summonSpell)
    if not expected then return true end
    local current = self:GetWarlockPetType()
    return current == expected
end

-- Helper function to estimate recent damage taken (placeholder)
function AC:GetRecentDamageTaken(seconds)
    -- This would need combat log tracking to be fully implemented
    -- For now, return nil (no recent damage tracking)
    return nil
end

-- Check if target already has the 13% magic damage taken debuff from any source.
function AC:TargetHasMagicVulnerabilityDebuff(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end

    -- WotLK-equivalent providers:
    -- Curse of the Elements (Warlock), Earth and Moon (Druid), Ebon Plague (DK).
    return self:HasDebuff(unit, S.CurseOfTheElements) or
           self:HasDebuff(unit, "Earth and Moon") or
           self:HasDebuff(unit, "Ebon Plague") or
           self:HasDebuff(unit, "Ebon Plaguebringer")
end

-- Conservative Doom suitability check (avoid losing curse value on short-lived targets).
function AC:CanUseCurseOfDoom(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end
    if self:IsFastDyingMob(unit) then return false end

    local maxHealth = UnitHealthMax(unit) or 0
    local currentHealth = UnitHealth(unit) or 0
    local targetHealthPercent = (maxHealth > 0) and ((currentHealth / maxHealth) * 100) or 0
    if targetHealthPercent < 70 then
        return false
    end

    local classification = UnitClassification(unit)
    if classification == "worldboss" then
        return true
    end

    local playerMaxHealth = UnitHealthMax("player") or 1
    -- Require a clearly long-lived target for non-worldbosses.
    if maxHealth >= (playerMaxHealth * 12) and targetHealthPercent >= 85 then
        return true
    end

    return false
end

-- ================================================================
-- WEAPON ENCHANT MANAGEMENT (SPELLSTONES & FIRESTONES)
-- ================================================================
function AC:ManageWarlockWeaponEnchants()
    if InCombatLockdown() then return nil end -- Don't manage enchants in combat
    
    local playerLevel = UnitLevel("player")
    local spec = self:GetWarlockSpec()
    
    -- Check if main hand weapon needs enchant
    local mainHandSlot = GetInventorySlotInfo("MainHandSlot")
    local mainHandLink = GetInventoryItemLink("player", mainHandSlot)
    
    if not mainHandLink then return nil end -- No weapon equipped
    
    -- Check current enchant on main hand
    local hasEnchant = self:WeaponHasEnchant(mainHandSlot)
    
    if not hasEnchant then
        -- Choose appropriate enchant based on spec and level
        local enchantSpell = nil
        
        -- Spellstone for casters (preferred for most warlock specs)
        if playerLevel >= 36 and self:IsSpellKnown(S.CreateSpellstone) then
            local spellstone = self:GetSpellstone()
            if spellstone then
                WarlockDebug("Applying Spellstone enchant to weapon")
                -- Only prepend "item:" if it's a numeric itemID
                if type(spellstone) == "number" then
                    return "item:" .. spellstone
                else
                    return "item:" .. spellstone -- Item name, will be handled differently
                end
            elseif self:CanCast(S.CreateSpellstone) then
                WarlockDebug("Creating Spellstone")
                return S.CreateSpellstone
            end
        end
        
        -- Firestone for melee enhancement (lower priority)
        if playerLevel >= 28 and self:IsSpellKnown(S.CreateFirestone) then
            local firestone = self:GetFirestone()
            if firestone then
                WarlockDebug("Applying Firestone enchant to weapon")
                return "item:" .. firestone
            elseif self:CanCast(S.CreateFirestone) then
                WarlockDebug("Creating Firestone")
                return S.CreateFirestone
            end
        end
    end
    
    return nil
end

function AC:WeaponHasEnchant(slot)
    -- Check if weapon has temporary enchant
    local hasMainHandEnchant, mainHandExpiration = GetWeaponEnchantInfo()
    if slot == GetInventorySlotInfo("MainHandSlot") then
        return hasMainHandEnchant and mainHandExpiration > 0
    end
    return false
end

function AC:GetSpellstone()
    -- Extended spellstone item IDs for all ranks/versions in WotLK
    local spellstones = {
        22049, 22047, 22048, -- WotLK/TBC versions
        5522, 5521, 5520,    -- Classic versions
        41191, 41190, 41189  -- Additional variants
    }
    
    -- Method 1: Try item ID matching
    for _, itemID in ipairs(spellstones) do
        local count = GetItemCount(itemID, true) -- Check all bags
        if count > 0 then
            WarlockDebug("Found spellstone ID " .. itemID .. " (count: " .. count .. ")")
            return itemID
        end
    end
    
    -- Method 2: Try by item name (fallback)
    local spellstoneNames = {
        "Grand Spellstone", "Major Spellstone", "Spellstone", 
        "Greater Spellstone", "Lesser Spellstone", "Minor Spellstone"
    }
    
    for _, name in ipairs(spellstoneNames) do
        local count = GetItemCount(name, true)
        if count > 0 then
            WarlockDebug("Found spellstone by name: " .. name .. " (count: " .. count .. ")")
            return name
        end
    end
    
    WarlockDebug("No spellstone found in inventory")
    return nil
end

function AC:GetFirestone()
    -- Firestone item IDs (various ranks)
    local firestones = {22046, 22045, 22044, 1254, 13699, 13700}
    
    for _, itemID in ipairs(firestones) do
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink then
                    local bagItemID = tonumber(itemLink:match("item:(%d+)"))
                    if bagItemID == itemID then
                        return itemID
                    end
                end
            end
        end
    end
    return nil
end

-- ================================================================
-- ITEM CREATION MANAGEMENT
-- ================================================================
function AC:ManageWarlockItemCreation()
    if InCombatLockdown() then return nil end
    
    -- Throttle item creation checks to prevent spam
    if not self.lastItemCheck or (GetTime() - self.lastItemCheck) > 5 then
        self.lastItemCheck = GetTime()
    else
        return nil -- Don't check items too frequently
    end
    
    local playerLevel = UnitLevel("player")
    local shardCount = self:GetSoulShardCount()
    
    WarlockDebug("=== ITEM CREATION CHECK ===")
    WarlockDebug("Level: " .. playerLevel .. ", Soul Shards: " .. shardCount)
    
    -- Check Healthstone (level 14+)
    if playerLevel >= 14 and self:IsSpellKnown(S.CreateHealthstone) then
        local hasHealthstone = self:GetHealthstone()
        WarlockDebug("Healthstone: Has=" .. tostring(hasHealthstone ~= nil))
        if not hasHealthstone and shardCount >= 1 then
            WarlockDebug("NEED TO CREATE: Healthstone")
            return S.CreateHealthstone
        end
    end
    
    -- Check Spellstone (level 36+)
    if playerLevel >= 36 and self:IsSpellKnown(S.CreateSpellstone) then
        local hasSpellstone = self:GetSpellstone()
        WarlockDebug("Spellstone: Has=" .. tostring(hasSpellstone ~= nil))
        if not hasSpellstone and shardCount >= 1 then
            WarlockDebug("NEED TO CREATE: Spellstone")
            return S.CreateSpellstone
        end
    end
    
    -- Check Soulstone (level 18+)
    if playerLevel >= 18 and self:IsSpellKnown(S.CreateSoulstone) then
        local hasSoulstone = self:HasSoulstone()
        WarlockDebug("Soulstone: Has=" .. tostring(hasSoulstone))
        if not hasSoulstone and shardCount >= 1 then
            WarlockDebug("NEED TO CREATE: Soulstone")
            return S.CreateSoulstone
        end
    end
    
    WarlockDebug("All items present - no creation needed")
    return nil
end

function AC:HasSoulstone()
    -- Soulstone item IDs for different ranks
    local soulstones = {22116, 22115, 22114, 5232, 16893, 16895, 16896}
    
    for _, itemID in ipairs(soulstones) do
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink then
                    local bagItemID = tonumber(itemLink:match("item:(%d+)"))
                    if bagItemID == itemID then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function AC:GetHealthstone()
    -- Test every possible healthstone name and ID
    local healthstoneNames = {
        "Healthstone", "Minor Healthstone", "Lesser Healthstone", 
        "Healthstone", "Greater Healthstone", "Major Healthstone", 
        "Master Healthstone", "Demonic Healthstone", "Fel Healthstone"
    }
    
    local healthstoneIDs = {5512, 5511, 5509, 5510, 5508, 19004, 19005, 19006, 22103, 22104, 22105}
    
    WarlockDebug("=== HEALTHSTONE DETECTION TEST ===")
    
    -- Method 1: Check by name
    for _, name in ipairs(healthstoneNames) do
        local count = GetItemCount(name, true)
        if count > 0 then
            WarlockDebug("FOUND by name: " .. name .. " (count: " .. count .. ")")
            return name
        else
            WarlockDebug("NOT FOUND by name: " .. name)
        end
    end
    
    -- Method 2: Check by ID
    for _, itemID in ipairs(healthstoneIDs) do
        local count = GetItemCount(itemID, true)
        if count > 0 then
            WarlockDebug("FOUND by ID: " .. itemID .. " (count: " .. count .. ")")
            return itemID
        else
            WarlockDebug("NOT FOUND by ID: " .. itemID)
        end
    end
    
    WarlockDebug("NO HEALTHSTONE FOUND ANYWHERE")
    return nil
end

-- ================================================================
-- ENHANCED RACIAL ABILITIES SYSTEM (Spec-Optimized)
-- ================================================================
-- Enhanced racial usage with spec-specific timing
function AC:UseWarlockRacials(spec, procs, targetHealthPercent)
    local race = select(2, UnitRace("player"))
    local playerHealthPercent = (UnitHealth("player") / UnitHealthMax("player")) * 100
    
    -- Emergency health potions
    if playerHealthPercent < 30 then
        if self.UseHealthPotion and self:UseHealthPotion(30) then
            WarlockDebug("Used health potion at " .. string.format("%.0f", playerHealthPercent) .. "% health")
            return nil -- Let potion take effect
        end
    end
    
    -- Emergency defensive racials
    if playerHealthPercent < 30 then
        if race == "Undead" and self:CanCast(R.WillOfForsaken) then
            WarlockDebug("Emergency Will of the Forsaken")
            return R.WillOfForsaken
        elseif race == "Human" and self:CanCast(R.EveryMan) then
            WarlockDebug("Emergency Every Man for Himself")
            return R.EveryMan
        elseif race == "Dwarf" and self:CanCast(R.Stoneform) then
            WarlockDebug("Emergency Stoneform")
            return R.Stoneform
        elseif race == "Gnome" and self:CanCast(R.EscapeArtist) then
            WarlockDebug("Emergency Escape Artist")
            return R.EscapeArtist
        end
    end
    
    -- Offensive racials with spec-specific timing
    local shouldUseBurst = false
    
    -- Spec-specific burst windows
    if spec == "Affliction" then
        -- Use with fresh DoT application or Shadow Embrace stacking
        shouldUseBurst = (procs.shadowEmbraceStacks < 3) or (targetHealthPercent > 80)
    elseif spec == "Destruction" then
        -- Use with Chaos Bolt or when Backdraft stacks are available
        shouldUseBurst = (procs.backdraftStacks > 0) or (self:GetSpellCooldown(S.ChaosBolt) == 0)
    elseif spec == "Demonology" then
        -- Use with Metamorphosis or Decimation procs
        shouldUseBurst = procs.metamorphosis or procs.decimation or (targetHealthPercent > 80)
    end
    
    if shouldUseBurst then
        if race == "Orc" and self:CanCast(R.BloodFury) then
            WarlockDebug("Using Blood Fury (" .. spec .. " burst window)")
            return R.BloodFury
        elseif race == "Troll" and self:CanCast(R.Berserking) then
            WarlockDebug("Using Berserking (" .. spec .. " burst window)")
            return R.Berserking
        elseif race == "Draenei" and self:CanCast(R.GiftOfNaaru) and playerHealthPercent < 70 then
            WarlockDebug("Using Gift of the Naaru (healing)")
            return R.GiftOfNaaru
        elseif race == "BloodElf" and self:CanCast(R.ArcaneTorrent) then
            local manaPercent = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100
            if manaPercent < 80 then
                WarlockDebug("Using Arcane Torrent (mana restore)")
                return R.ArcaneTorrent
            end
        end
    end
    
    return nil
end

-- ================================================================
-- CURSE MANAGEMENT - LEVELING FRIENDLY
-- ================================================================
function AC:SelectOptimalCurse()
    local spec = self:GetWarlockSpec()
    local playerLevel = UnitLevel("player")
    local targetHealthMax = UnitHealthMax("target") or 0
    local targetHealthCurrent = UnitHealth("target") or 0
    local targetHealthPercent = (targetHealthMax > 0) and ((targetHealthCurrent / targetHealthMax) * 100) or 100
    
    -- Check if ANY curse is already applied
    local hasCurse = self:HasDebuff("target", S.CurseOfTheElements) or 
                     self:HasDebuff("target", S.CurseOfAgony) or
                     self:HasDebuff("target", S.CurseOfDoom) or
                     self:HasDebuff("target", S.CurseOfWeakness) or
                     self:HasDebuff("target", S.CurseOfTongues) or
                     self:HasDebuff("target", "Curse of Shadow") or
                     self:HasDebuff("target", "Curse of Vulnerability")
    
    -- Don't apply a curse if one is already active
    if hasCurse then
        WarlockDebug("A curse is already active, skipping curse selection")
        return nil
    end
    
    -- Don't apply curses to fast dying mobs
    if self:IsFastDyingMob("target") then
        WarlockDebug("Target is fast dying, skipping curse application")
        return nil
    end
    
    -- Keep 13% magic vulnerability up only when the raid/group actually needs it.
    if playerLevel >= 32 and self:IsSpellKnown(S.CurseOfTheElements) and not self:TargetHasMagicVulnerabilityDebuff("target") then
        WarlockDebug("Selected Curse of the Elements (debuff coverage needed)")
        return S.CurseOfTheElements
    end

    -- Spec-aware damage curse selection.
    if spec == "Affliction" then
        -- Wowhead/WotLK guidance: Affliction generally favors Agony if CoE is covered.
        if playerLevel >= 8 and self:IsSpellKnown(S.CurseOfAgony) and targetHealthPercent > 35 then
            WarlockDebug("Selected Curse of Agony (Affliction default)")
            return S.CurseOfAgony
        end
    else
        -- Demonology/Destruction: Doom is preferred on long-lived targets.
        if playerLevel >= 60 and self:IsSpellKnown(S.CurseOfDoom) and self:CanUseCurseOfDoom("target") then
            WarlockDebug("Selected Curse of Doom (long-lived target)")
            return S.CurseOfDoom
        end
        if playerLevel >= 8 and self:IsSpellKnown(S.CurseOfAgony) and targetHealthPercent > 35 then
            WarlockDebug("Selected Curse of Agony (shorter target fallback)")
            return S.CurseOfAgony
        end
    end
    
    -- Curse of Weakness - very early level fallback (Level 4+)
    if playerLevel >= 4 and self:IsSpellKnown(S.CurseOfWeakness) then
        WarlockDebug("Selected Curse of Weakness (early level)")
        return S.CurseOfWeakness
    end
    
    WarlockDebug("No curse available for level " .. playerLevel)
    return nil
end

-- ================================================================
-- ENHANCED AOE DETECTION AND MANAGEMENT (Level-Aware)
-- ================================================================
function AC:GetNearbyEnemyCount(range)
    -- Use Core.lua enemy detection if available (more accurate)
    if self.GetEnemyCount then
        return self:GetEnemyCount(range)
    end
    
    local count = 0
    range = range or 10
    
    -- Count nearby hostile units
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            if UnitIsVisible(unit) and not UnitIsDead(unit) then
                -- Approximate distance check (not perfect but functional)
                local distance = self:GetDistanceToUnit(unit) or 999
                if distance <= range then
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

-- ENHANCED: Level and gear-aware AoE thresholds
function AC:GetOptimalAoEThreshold()
    local playerLevel = UnitLevel("player")
    local spellPower = GetSpellBonusDamage(3) or 0 -- Shadow spell power
    local complexity = self:GetRotationComplexity()
    
    -- Base threshold
    local threshold = 3
    
    -- Level adjustments
    if playerLevel < 30 then
        threshold = 4 -- Less efficient AoE at low levels
    elseif playerLevel < 50 then
        threshold = 3 -- Moderate efficiency
    elseif playerLevel >= 70 then
        threshold = 2 -- High efficiency at endgame
    end
    
    -- Gear adjustments (spell power indicates gear quality)
    if spellPower > 2000 then
        threshold = math.max(threshold - 1, 2) -- High-end gear
    elseif spellPower < 500 and playerLevel > 60 then
        threshold = threshold + 1 -- Poor gear for level
    end
    
    -- Complexity adjustments
    if complexity == "BASIC" then
        threshold = threshold + 1 -- Conservative for basic rotations
    end
    
    WarlockDebug("AoE Threshold: " .. threshold .. " (Level: " .. playerLevel .. ", SP: " .. spellPower .. ", Complexity: " .. complexity .. ")")
    return threshold
end

function AC:ShouldUseAOEWarlock()
    local nearbyEnemies = self:GetNearbyEnemyCount(10)
    local threshold = self:GetOptimalAoEThreshold()
    
    return nearbyEnemies >= threshold
end

-- Enhanced AoE spell selection based on situation
function AC:GetBestAoESpell(spec, enemies, procs)
    local playerLevel = UnitLevel("player")
    
    if spec == "Affliction" then
        -- Seed of Corruption is king for Affliction AoE
        if self:IsSpellKnown(S.SeedOfCorruption) and enemies >= 3 then
            return S.SeedOfCorruption
        end
    elseif spec == "Destruction" then
        -- Rain of Fire for stationary AoE, Seed for mobile
        if self:IsSpellKnown(S.RainOfFire) and not self:IsPlayerMoving() and enemies >= 4 then
            return S.RainOfFire
        elseif self:IsSpellKnown(S.SeedOfCorruption) and enemies >= 3 then
            return S.SeedOfCorruption
        end
    elseif spec == "Demonology" then
        -- Metamorphosis form has different AoE priorities
        if procs.metamorphosis then
            if self:IsSpellKnown(S.ImmolationAura) and enemies >= 3 then
                return S.ImmolationAura
            elseif self:IsSpellKnown(S.ShadowCleave) and enemies >= 2 then
                return S.ShadowCleave
            end
        else
            -- Regular form - prefer Seed
            if self:IsSpellKnown(S.SeedOfCorruption) and enemies >= 3 then
                return S.SeedOfCorruption
            end
        end
    end
    
    return nil
end

-- ================================================================
-- AFFLICTION ROTATION (DoT Management Focus)
-- ================================================================
function AC:AfflictionRotation(procs)
    procs = procs or self:UpdateWarlockProcs()
    local targetHealthPercent = (UnitHealth("target") / UnitHealthMax("target")) * 100
    local shouldAOE = self:ShouldUseAOEWarlock()
    local complexity = self:GetRotationComplexity()
    
    WarlockDebug("Affliction rotation - Health: " .. string.format("%.1f", targetHealthPercent) .. "%, Complexity: " .. complexity)
    
    -- AOE Rotation
    if shouldAOE then
        -- Seed of Corruption - primary AoE for Affliction
        if self:IsSpellKnown(S.SeedOfCorruption) and self:CanCast(S.SeedOfCorruption) then
            -- Cast on target without Seed of Corruption
            if not self:HasDebuff("target", S.SeedOfCorruption) then
                WarlockDebug("Using Seed of Corruption for AOE")
                return S.SeedOfCorruption
            end
        end
        
        -- Skip ground targeting as per user request - server handles Rain of Fire
    end
    
    -- ENHANCED DOT MANAGEMENT WITH PANDEMIC TIMING
    local function shouldRefreshDot(debuffName, baseDuration)
        if not self:HasDebuff("target", debuffName) then
            return true -- Missing DoT
        end
        
        -- Only use pandemic for advanced rotations
        if complexity == "ADVANCED" or complexity == "MODERATE" then
            local timeRemaining = self:DebuffTimeRemaining("target", debuffName)
            local pandemicThreshold = baseDuration * 0.3 -- 30% rule
            return timeRemaining <= pandemicThreshold
        end
        
        -- Basic mode still needs uptime; use a simple safe clip window.
        local timeRemaining = self:DebuffTimeRemaining("target", debuffName) or 0
        return timeRemaining <= 2.5
    end
    
    -- Single Target Priority
    
    -- RESEARCH-BASED: Optimal Affliction DoT Priority with Pandemic Timing
    
    -- 1. ENHANCED: Haunt - Highest priority for Shadow Embrace stacks and debuff
    if self:IsSpellKnown(S.Haunt) and not self:IsFastDyingMob("target") then
        -- CRITICAL: Shadow Embrace stack maintenance (WotLK 3.3.5a meta)
        local needsHaunt = false
        
        -- Missing Haunt entirely
        if not procs.haunt then
            needsHaunt = true
            WarlockDebug("Haunt missing - applying for Shadow Embrace")
        -- Shadow Embrace stacks too low (need 3 stacks for optimal damage)
        elseif procs.shadowEmbraceStacks < 3 then
            needsHaunt = true
            WarlockDebug("Shadow Embrace stacks low (" .. procs.shadowEmbraceStacks .. "/3) - refreshing Haunt")
        -- Haunt expiring soon
        elseif procs.hauntTimeRemaining <= 3 then
            needsHaunt = true
            WarlockDebug("Haunt expiring in " .. string.format("%.1f", procs.hauntTimeRemaining) .. "s - refreshing")
        -- Shadow Embrace expiring soon (backup check)
        elseif procs.shadowEmbraceTimeRemaining <= 2 then
            needsHaunt = true
            WarlockDebug("Shadow Embrace expiring in " .. string.format("%.1f", procs.shadowEmbraceTimeRemaining) .. "s - emergency Haunt")
        end
        
        if needsHaunt and self:CanCast(S.Haunt) then
            WarlockDebug("Casting Haunt (Shadow Embrace optimization)")
            return S.Haunt
        end
    end
    
    -- 2. Corruption - keep up, but avoid unnecessary recasts when Everlasting Affliction is active.
    local hasCorruption = self:HasDebuff("target", S.Corruption)
    if not hasCorruption and self:CanCast(S.Corruption) then
        WarlockDebug("Applying Corruption")
        return S.Corruption
    end
    if not self:IsSpellKnown(S.Haunt) and shouldRefreshDot(S.Corruption, 18) then
        if self:CanCast(S.Corruption) then
            WarlockDebug("Refreshing Corruption (no Haunt/Everlasting support)")
            return S.Corruption
        end
    end
    
    -- 3. Unstable Affliction - High damage DoT with silence protection
    if self:IsSpellKnown(S.UnstableAffliction) and not self:IsFastDyingMob("target") then
        if shouldRefreshDot(S.UnstableAffliction, 15) then -- 15 second base duration
            if self:CanCast(S.UnstableAffliction) then
                WarlockDebug("Casting Unstable Affliction (pandemic-aware)")
                return S.UnstableAffliction
            end
        end
    end
    
    -- 4. Curse selection
    local curse = self:SelectOptimalCurse()
    if curse and self:CanCast(curse) then
        WarlockDebug("Applying curse: " .. curse)
        return curse
    end
    
    -- 5. Siphon Life if available (older talent)
    if self:IsSpellKnown(S.SiphonLife) and not self:HasDebuff("target", S.SiphonLife) and not self:IsFastDyingMob("target") then
        if self:CanCast(S.SiphonLife) then
            WarlockDebug("Casting Siphon Life")
            return S.SiphonLife
        end
    end
    
    -- 6. Execute phase - Drain Soul below 25%
    if targetHealthPercent <= 25 and self:IsSpellKnown(S.DrainSoul) then
        if self:CanCast(S.DrainSoul) then
            WarlockDebug("Execute phase - Drain Soul")
            return S.DrainSoul
        end
    end
    
    -- 7. Shadow Trance proc - instant Shadow Bolt
    if procs.shadowTrance and self:CanCast(S.ShadowBolt) then
        WarlockDebug("Using Shadow Trance proc")
        return S.ShadowBolt
    end
    
    -- 8. Shadow Bolt filler
    if self:CanCast(S.ShadowBolt) then
        WarlockDebug("Shadow Bolt filler")
        return S.ShadowBolt
    end
    
    return nil
end

-- ================================================================
-- ADVANCED DEMONOLOGY ROTATION (Meta-Optimized WotLK 3.3.5a)
-- ================================================================
function AC:DemonologyRotation(procs)
    WarlockDebug("=== ADVANCED DEMONOLOGY ROTATION START ===")
    
    procs = procs or self:UpdateWarlockProcs()
    local demoProcs = self:EnsureDemonologyProcState()
    local targetHealthPercent = (UnitHealth("target") / UnitHealthMax("target")) * 100
    local shouldAOE = self:ShouldUseAOEWarlock()
    local playerLevel = UnitLevel("player")
    local combatPhase = demoProcs and demoProcs.combatPhase.current or "sustained"
    
    WarlockDebug("Demo rotation - Level: " .. playerLevel .. ", HP: " .. string.format("%.1f", targetHealthPercent) .. "%, Phase: " .. combatPhase)
    
    -- ========== METAMORPHOSIS MANAGEMENT ==========
    if playerLevel >= 60 and self:IsSpellKnown(S.Metamorphosis) then
        if self:ShouldUseMetamorphosis() and self:CanCast(S.Metamorphosis) then
            WarlockDebug("CASTING METAMORPHOSIS - Demon form activated!")
            return S.Metamorphosis
        end
    end
    
    -- ========== AOE ROTATION ==========
    if shouldAOE then
        return self:DemonologyAoERotation(procs, demoProcs)
    end
    
    -- ========== SINGLE TARGET PRIORITY SYSTEM ==========
    
    -- HIGHEST PRIORITY: Active proc management
    local procSpell = self:HandleDemonologyProcs(demoProcs, playerLevel)
    if procSpell then return procSpell end
    
    -- HIGH PRIORITY: Debuff management (raid debuffs / curse coverage before fillers)
    local debuffSpell = self:HandleDemonologyDebuffs(demoProcs, playerLevel)
    if debuffSpell then return debuffSpell end

    -- MEDIUM PRIORITY: DoT application and maintenance
    local dotSpell = self:HandleDemonologyDoTs(playerLevel, combatPhase)
    if dotSpell then return dotSpell end
    
    -- LOW PRIORITY: Filler spells
    local fillerSpell = self:HandleDemonologyFillers(playerLevel, combatPhase, demoProcs)
    if fillerSpell then return fillerSpell end
    
    -- FALLBACK: Emergency spell selection
    if self:Throttle("WarlockDemoFallback", 1.0) then
        WarlockDebug("FALLBACK: No optimal spell found, using emergency rotation")
    end
    return self:DemonologyFallbackRotation(playerLevel)
end

-- Handle all Demonology procs with optimal timing
function AC:HandleDemonologyProcs(demoProcs, playerLevel)
    if not demoProcs then return nil end
    
    -- PRIORITY 1: Decimation (execute phase, massive DPS gain)
    if self:ShouldUseDecimation() and self:IsSpellKnown(S.SoulFire) and self:CanCast(S.SoulFire) then
        self:UseDecimationProc()
        WarlockDebug("DECIMATION: Instant Soul Fire (40% faster, no shard cost)")
        return S.SoulFire
    end
    
    -- PRIORITY 2: Molten Core (3 charges, 15-second window)
    if self:ShouldConsumeMoltenCore() then
        local moltenSpell = self:GetMoltenCoreSpell()
        if moltenSpell and self:CanCast(moltenSpell) then
            WarlockDebug("MOLTEN CORE: Using " .. moltenSpell .. " (30% faster, +18% damage)")
            return moltenSpell
        end
    end
    
    return nil
end

-- Handle DoT application and maintenance
function AC:HandleDemonologyDoTs(playerLevel, combatPhase)
    -- PRIORITY 1: Corruption (Molten Core proc generator - 12% chance)
    if playerLevel >= 4 and self:IsSpellKnown(S.Corruption) then
        local corruptionRemain = self:DebuffTimeRemaining("target", S.Corruption) or 0
        if (not self:HasDebuff("target", S.Corruption) or corruptionRemain <= 3) and self:CanCast(S.Corruption) then
            WarlockDebug("CORRUPTION: Applying for Molten Core procs (12% chance)")
            return S.Corruption
        end
    end
    
    -- PRIORITY 2: Immolate (major DoT value for Demo)
    if playerLevel >= 2 and self:IsSpellKnown(S.Immolate) then
        -- Keep this up even in execute if target can live for meaningful ticks.
        if not self:IsFastDyingMob("target") then
            local targetHealthPct = (UnitHealth("target") / UnitHealthMax("target")) * 100
            local allowExecuteRefresh = (combatPhase ~= "execute") or targetHealthPct > 20
            local immolateRemain = self:DebuffTimeRemaining("target", S.Immolate) or 0
            if allowExecuteRefresh and (not self:HasDebuff("target", S.Immolate) or immolateRemain <= 2) and self:CanCast(S.Immolate) then
                WarlockDebug("IMMOLATE: Applying for additional DoT damage")
                return S.Immolate
            end
        end
    end
    
    return nil
end

-- Handle debuff application and maintenance
function AC:HandleDemonologyDebuffs(demoProcs, playerLevel)
    -- PRIORITY 1: Improved Shadow Bolt debuff (5% shadow damage increase)
    if playerLevel >= 1 and self:IsSpellKnown(S.ShadowBolt) then
        -- Do not force hard-cast debuff maintenance while moving.
        if not self:IsPlayerMoving() and self:ShouldRefreshShadowBoltDebuff() and self:CanCast(S.ShadowBolt) then
            WarlockDebug("SHADOW BOLT: Applying/refreshing debuff (+5% shadow damage)")
            return S.ShadowBolt
        end
    end
    
    -- PRIORITY 2: Curse application (situational)
    if playerLevel >= 8 then
        local curse = self:SelectOptimalCurse()
        if curse and self:CanCast(curse) then
            WarlockDebug("CURSE: Applying " .. curse)
            return curse
        end
    end
    
    return nil
end

-- Handle filler spells based on level and situation
function AC:HandleDemonologyFillers(playerLevel, combatPhase, demoProcs)
    local isMoving = self:IsPlayerMoving()

    -- PRIORITY 1: Execute phase - Soul Fire spam
    if combatPhase == "execute" and demoProcs and demoProcs.decimation and demoProcs.decimation.active and
       playerLevel >= 48 and self:IsSpellKnown(S.SoulFire) and not isMoving then
        if self:CanCast(S.SoulFire) then
            WarlockDebug("EXECUTE FILLER: Soul Fire (Decimation)")
            return S.SoulFire
        end
    end
    
    -- PRIORITY 2: Standard filler - Shadow Bolt
    if not isMoving and self:IsSpellKnown(S.ShadowBolt) and self:CanCast(S.ShadowBolt) then
        WarlockDebug("STANDARD FILLER: Shadow Bolt")
        return S.ShadowBolt
    end

    -- PRIORITY 3: Incinerate fallback (prefer when Molten Core is active)
    if not isMoving and playerLevel >= 64 and self:IsSpellKnown(S.Incinerate) and self:CanCast(S.Incinerate) then
        if self:HasBuff("player", S.MoltenCore) then
            WarlockDebug("MOLTEN CORE FILLER: Incinerate")
        else
            WarlockDebug("INCINERATE FALLBACK")
        end
        return S.Incinerate
    end

    -- PRIORITY 4: Always keep a cheap instant fallback to avoid idle dead-zones.
    if playerLevel >= 18 and self:IsSpellKnown(S.SearingPain) and self:CanCast(S.SearingPain) then
        WarlockDebug("SEARING PAIN FALLBACK")
        return S.SearingPain
    end
    
    return nil
end

-- AoE rotation for Demonology
function AC:DemonologyAoERotation(procs, demoProcs)
    local playerLevel = UnitLevel("player")
    
    WarlockDebug("AOE ROTATION: Multiple enemies detected")
    
    -- PRIORITY 1: Metamorphosis AoE abilities
    if procs.metamorphosis then
        if self:IsSpellKnown(S.ImmolationAura) and self:CanCast(S.ImmolationAura) then
            WarlockDebug("META AOE: Immolation Aura")
            return S.ImmolationAura
        end
        if self:IsSpellKnown(S.ShadowCleave) and self:CanCast(S.ShadowCleave) then
            WarlockDebug("META AOE: Shadow Cleave")
            return S.ShadowCleave
        end
    end
    
    -- PRIORITY 2: Seed of Corruption (primary AoE spell)
    if self:IsSpellKnown(S.SeedOfCorruption) and self:CanCast(S.SeedOfCorruption) then
        if not self:HasDebuff("target", S.SeedOfCorruption) then
            WarlockDebug("AOE: Seed of Corruption")
            return S.SeedOfCorruption
        end
    end
    
    -- PRIORITY 3: Rain of Fire (stationary AoE)
    if self:IsSpellKnown(S.RainOfFire) and self:CanCast(S.RainOfFire) then
        if not self:IsChanneling() and not self:IsPlayerMoving() then
            WarlockDebug("AOE: Rain of Fire (stationary)")
            -- Use the Core.lua SafeCastGroundAOE system
            if self.SafeCastGroundAOE then
                return self:SafeCastGroundAOE(S.RainOfFire)
            else
                -- Fallback to manual targeting
                CastSpellByName(S.RainOfFire)
                CameraOrSelectOrMoveStart()
                CameraOrSelectOrMoveStop()
                return true
            end
        end
    end
    
    -- PRIORITY 4: Continue single-target rotation on primary target
    WarlockDebug("AOE: Falling back to single-target rotation")
    return nil
end

-- Fallback rotation for emergency situations
function AC:DemonologyFallbackRotation(playerLevel)
    WarlockDebug("EMERGENCY FALLBACK ROTATION")

    -- Avoid false "no spell" stalls while we are already busy.
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return nil
    end

    local isMoving = self:IsPlayerMoving()

    -- Prefer direct-damage fillers first so fallback keeps throughput.
    if not isMoving and self:IsSpellKnown(S.ShadowBolt) and self:CanCast(S.ShadowBolt) then
        WarlockDebug("EMERGENCY: Using Shadow Bolt filler")
        return S.ShadowBolt
    end
    if not isMoving and playerLevel >= 64 and self:IsSpellKnown(S.Incinerate) and self:CanCast(S.Incinerate) then
        WarlockDebug("EMERGENCY: Using Incinerate filler")
        return S.Incinerate
    end
    if not isMoving and playerLevel >= 18 and self:IsSpellKnown(S.SearingPain) and self:CanCast(S.SearingPain) then
        WarlockDebug("EMERGENCY: Using Searing Pain filler")
        return S.SearingPain
    end
    if not isMoving and playerLevel >= 48 and self:IsSpellKnown(S.SoulFire) and self:CanCast(S.SoulFire) then
        WarlockDebug("EMERGENCY: Using Soul Fire filler")
        return S.SoulFire
    end

    -- If mana is too low for fillers, tap before trying low-value upkeep spells.
    if self:CanCast(S.LifeTap) then
        local manaPct = (UnitPower("player", 0) / math.max(UnitPowerMax("player", 0), 1)) * 100
        local hpPct = (UnitHealth("player") / math.max(UnitHealthMax("player"), 1)) * 100
        if manaPct < 45 and hpPct > 60 then
            WarlockDebug("EMERGENCY: Life Tap to recover filler throughput")
            return S.LifeTap
        end
    end

    -- Movement-safe instants and DoTs only when absent/expiring.
    if playerLevel >= 4 and self:IsSpellKnown(S.Corruption) and self:CanCast(S.Corruption) then
        local corruptionRemain = self:DebuffTimeRemaining("target", S.Corruption) or 0
        if not self:HasDebuff("target", S.Corruption) or corruptionRemain <= 3 then
            WarlockDebug("EMERGENCY: Using Corruption (DoT + proc chance)")
            return S.Corruption
        end
    end
    if playerLevel >= 2 and self:IsSpellKnown(S.Immolate) and self:CanCast(S.Immolate) then
        local immolateRemain = self:DebuffTimeRemaining("target", S.Immolate) or 0
        if not self:HasDebuff("target", S.Immolate) or immolateRemain <= 2 then
            WarlockDebug("EMERGENCY: Using Immolate")
            return S.Immolate
        end
    end
    if playerLevel >= 8 and self:IsSpellKnown(S.CurseOfAgony) and self:CanCast(S.CurseOfAgony) then
        local hasAnyCurse = self:HasDebuff("target", S.CurseOfTheElements) or
                            self:HasDebuff("target", S.CurseOfAgony) or
                            self:HasDebuff("target", S.CurseOfDoom) or
                            self:HasDebuff("target", S.CurseOfWeakness) or
                            self:HasDebuff("target", S.CurseOfTongues) or
                            self:HasDebuff("target", "Curse of Shadow") or
                            self:HasDebuff("target", "Curse of Vulnerability")
        if not hasAnyCurse then
            WarlockDebug("EMERGENCY: Using Curse of Agony")
            return S.CurseOfAgony
        end
    end
    if playerLevel >= 14 and self:IsSpellKnown(S.DrainLife) and self:CanCast(S.DrainLife) and
       (UnitHealth("player") / UnitHealthMax("player")) * 100 < 70 then
        WarlockDebug("EMERGENCY: Using Drain Life sustain")
        return S.DrainLife
    end

    if self:Throttle("WarlockEmergencyNoSpell", 2.0) then
        local manaPct = (UnitPower("player", 0) / math.max(UnitPowerMax("player", 0), 1)) * 100
        WarlockDebug("EMERGENCY: No safe fallback spell available this tick (Mana: " .. string.format("%.0f", manaPct) .. "%)")
    end
    return nil
end

-- ================================================================
-- DESTRUCTION ROTATION (Direct Damage Focus)
-- ================================================================
function AC:DestructionRotation(procs)
    procs = procs or self:UpdateWarlockProcs()
    local targetHealthPercent = (UnitHealth("target") / UnitHealthMax("target")) * 100
    local shouldAOE = self:ShouldUseAOEWarlock()
    
    WarlockDebug("Destruction rotation - Health: " .. string.format("%.1f", targetHealthPercent) .. "%, Backdraft: " .. tostring(procs.backdraftStacks))
    
    -- AOE Rotation
    if shouldAOE then
        -- Rain of Fire - channeled ground AoE (3+ enemies)
        if self:IsSpellKnown(S.RainOfFire) and self:CanCast(S.RainOfFire) then
            if not self:IsChanneling() and not self:IsPlayerMoving() then
                WarlockDebug("Using Rain of Fire for AOE")
                if self:SafeCastGroundAOE(S.RainOfFire) then
                    return true
                end
            end
        end
        
        -- Seed of Corruption - single target that spreads
        if self:IsSpellKnown(S.SeedOfCorruption) and self:CanCast(S.SeedOfCorruption) then
            -- Cast on target without Seed of Corruption
            if not self:HasDebuff("target", S.SeedOfCorruption) then
                WarlockDebug("Using Seed of Corruption for AOE")
                return S.SeedOfCorruption
            end
        end
    end
    
    -- Single Target Priority
    
    -- 1. Immolate - must be maintained for Conflagrate and Incinerate bonus.
    local immolateRemain = self:DebuffTimeRemaining("target", S.Immolate) or 0
    if (not self:HasDebuff("target", S.Immolate) or immolateRemain <= 2) and self:CanCast(S.Immolate) then
        WarlockDebug("Applying/Refreshing Immolate")
        return S.Immolate
    end
    
    -- 2. Conflagrate - highest direct nuke when Immolate is active
    if self:IsSpellKnown(S.Conflagrate) and self:HasDebuff("target", S.Immolate) then
        if self:CanCast(S.Conflagrate) then
            WarlockDebug("Casting Conflagrate")
            return S.Conflagrate
        end
    end

    -- 3. Chaos Bolt - high priority direct damage
    if self:IsSpellKnown(S.ChaosBolt) and self:CanCast(S.ChaosBolt) then
        WarlockDebug("Casting Chaos Bolt")
        return S.ChaosBolt
    end
    
    -- 4. Curse selection
    local curse = self:SelectOptimalCurse()
    if curse and self:CanCast(curse) then
        WarlockDebug("Applying curse: " .. curse)
        return curse
    end
    
    -- 5. Corruption is niche for movement; avoid spending stationary GCDs on it.
    if self:IsPlayerMoving() and not self:HasDebuff("target", S.Corruption) and self:CanCast(S.Corruption) then
        WarlockDebug("Applying Corruption while moving (Destruction niche)")
        return S.Corruption
    end
    
    -- 6. Execute abilities
    if targetHealthPercent <= 25 then
        -- Shadowburn for execute (if available)
        if self:IsSpellKnown(S.ShadowBurn) and self:CanCast(S.ShadowBurn) then
            WarlockDebug("Execute - Shadowburn")
            return S.ShadowBurn
        end
    end
    
    -- 7. Backdraft-enhanced casts
    if procs.backdraftStacks > 0 then
        if self:IsSpellKnown(S.Incinerate) and self:CanCast(S.Incinerate) then
            WarlockDebug("Using Backdraft stacks for Incinerate")
            return S.Incinerate
        end
        if self:CanCast(S.ShadowBolt) then
            WarlockDebug("Using Backdraft stacks for Shadow Bolt")
            return S.ShadowBolt
        end
    end
    
    -- 8. Incinerate filler (preferred with Immolate up)
    if self:IsSpellKnown(S.Incinerate) and self:HasDebuff("target", S.Immolate) then
        if self:CanCast(S.Incinerate) then
            WarlockDebug("Incinerate filler")
            return S.Incinerate
        end
    end
    
    -- 9. Shadow Bolt filler
    if self:CanCast(S.ShadowBolt) then
        WarlockDebug("Shadow Bolt filler")
        return S.ShadowBolt
    end
    
    return nil
end

-- ================================================================
-- MAIN WARLOCK ROTATION CONTROLLER
-- ================================================================
function AC:Warlock()
    -- SIMPLE CHECK: Do we have a target to fight?
    if not UnitExists("target") or UnitIsDead("target") or not UnitCanAttack("player", "target") then
        return nil
    end

    -- Normal busy states are not rotation failures.
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return true
    end
    if self:IsGlobalCooldownActive() then
        return true
    end
    
    local procs = self:UpdateWarlockProcs()
    local spec = self:GetWarlockSpec()

    -- PRIORITY: Send pet to attack player's target (establish aggro while warlock casts)
    if UnitExists("pet") and not UnitIsDeadOrGhost("pet") then
        self:WarlockPetCombatAssistance()
    end
    
    -- Emergency consumables
    local consumable = self:ManageWarlockConsumables(procs)
    if consumable then 
        if self:CastWarlockSpell(consumable, "player") then
            return true
        end
    end
    
    -- ENHANCED: Spec-optimized racial abilities
    local targetHealthPercent = UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target") * 100) or 100
    
    if InCombatLockdown() then
        local racial = self:UseWarlockRacials(spec, procs, targetHealthPercent)
        if racial then
            if self:CastWarlockSpell(racial, "player") then
                return true
            end
        end
    end
    
    -- Soul shard gathering (low priority)
    if self:ShouldGatherSoulShards() then
        local targetHealthPercent = (UnitHealth("target") / UnitHealthMax("target")) * 100
        if targetHealthPercent <= 15 and self:CanCast(S.DrainSoul) then
            WarlockDebug("Gathering soul shard with Drain Soul")
            if self:CastWarlockSpell(S.DrainSoul, "target") then
                return true
            end
        end
    end
    
    -- Main rotation based on specialization
    WarlockDebug("Active spec: " .. spec)
    
    local spellToCast = nil
    
    if spec == "Affliction" then
        spellToCast = self:AfflictionRotation(procs)
    elseif spec == "Demonology" then  
        spellToCast = self:DemonologyRotation(procs)
    elseif spec == "Destruction" or spec == "None" then
        -- Unspecced leveling characters use the safest direct-damage fallback.
        spellToCast = self:DestructionRotation(procs)
    end
    
    -- Cast the selected spell with Demonic Empowerment macro integration
    if spellToCast == true then
        -- Some AoE helpers cast immediately and return true.
        return true
    end

    if type(spellToCast) == "string" and spellToCast ~= "" then
        WarlockDebug("Attempting to cast: " .. spellToCast)
        
        -- Try Demonic Empowerment macro first (for Demonology)
        if self:TryDemonicEmpowermentMacro(spellToCast) then
            -- Demonic Empowerment was cast, primary spell will be cast next cycle
            return true
        end
        
        -- Cast the primary spell
        if self:CastWarlockSpell(spellToCast, "target") then
            WarlockDebug("Successfully cast: " .. spellToCast)
            return true
        else
            WarlockDebug("Failed to cast: " .. spellToCast)
        end
    else
        if UnitCastingInfo("player") or UnitChannelInfo("player") or self:IsGlobalCooldownActive() then
            return true
        end
        if self:Throttle("WarlockNoSpellSelected", 1.5) then
            WarlockDebug("No spell selected from rotation (idle tick)")
        end
    end
    
    -- Fallback
    if self:CanCast(S.ShadowBolt) then
        if self:CastWarlockSpell(S.ShadowBolt, "target") then
            return true
        end
    end
    
    return false
end

-- ================================================================
-- ROTATION REGISTRATION SYSTEM
-- ================================================================
function AC:InitWarlockRotations()
    -- Initialize the rotations table structure
    self.rotations = self.rotations or {}
    self.rotations.WARLOCK = self.rotations.WARLOCK or {}
    
    -- Register all three warlock specs
    self.rotations.WARLOCK["Affliction"] = function() return self:Warlock() end
    self.rotations.WARLOCK["Demonology"] = function() return self:Warlock() end
    self.rotations.WARLOCK["Destruction"] = function() return self:Warlock() end
    -- Allow level 1-10 / no-talents characters to enter the warlock rotation.
    self.rotations.WARLOCK["None"] = function() return self:Warlock() end
    
    -- Debug confirmation
    if self.debugMode then
        self:Debug("Warlock rotations registered:")
        self:Debug("  - Affliction: " .. tostring(self.rotations.WARLOCK["Affliction"] ~= nil))
        self:Debug("  - Demonology: " .. tostring(self.rotations.WARLOCK["Demonology"] ~= nil))
        self:Debug("  - Destruction: " .. tostring(self.rotations.WARLOCK["Destruction"] ~= nil))
        self:Debug("  - None: " .. tostring(self.rotations.WARLOCK["None"] ~= nil))
    end
end

-- ================================================================
-- BUFF CHECKING SYSTEM FOR CORE.LUA INTEGRATION
-- ================================================================
function AC:CheckWarlockBuffs(spec)
    -- Out of combat preparation
    if not InCombatLockdown() then
        -- Priority 1: Manage buffs
        local buff = self:ManageWarlockBuffs()
        if buff then 
            if self:CastWarlockSpell(buff, "player") then
                WarlockDebug("Applied buff: " .. buff)
                return true
            end
        end
        
        -- Priority 2: Advanced pet management
        local pet = self:ManageWarlockPetAdvanced()
        if pet then 
            if self:CastWarlockSpell(pet, "player") then
                WarlockDebug("Pet action: " .. pet)
                return true
            end
        end
        
        -- Priority 3: Item creation
        local itemsCreated = self:ManageWarlockItemCreation()
        if itemsCreated then 
            if self:CastWarlockSpell(itemsCreated, "player") then
                WarlockDebug("Created item: " .. itemsCreated)
                return true
            end
        end
        
        -- Priority 4: Weapon enchant management
        local weaponEnchant = self:ManageWarlockWeaponEnchants()
        if weaponEnchant then 
            if self:CastWarlockSpell(weaponEnchant, "player") then
                WarlockDebug("Applied weapon enchant: " .. weaponEnchant)
                return true
            end
        end
    end
    
    return false
end

-- ================================================================
-- PERFORMANCE ANALYTICS AND MONITORING (Phase 4)
-- ================================================================

-- Track rotation performance metrics
AC.WarlockAnalytics = AC.WarlockAnalytics or {
    combatSessions = 0,
    totalSpellsCast = 0,
    procUtilization = {
        moltenCoreProcs = 0,
        moltenCoreUsed = 0,
        decimationProcs = 0,
        decimationUsed = 0,
        metamorphosisUses = 0
    },
    spellBreakdown = {},
    dpsEstimate = 0,
    lastCombatDPS = 0,
    averageCombatLength = 0,
    rotationEfficiency = 0
}

-- Initialize spell tracking
function AC:InitWarlockAnalytics()
    local analytics = self.WarlockAnalytics
    
    -- Initialize spell breakdown tracking
    analytics.spellBreakdown = {
        [S.ShadowBolt] = {casts = 0, damage = 0},
        [S.Incinerate] = {casts = 0, damage = 0},
        [S.SoulFire] = {casts = 0, damage = 0},
        [S.Corruption] = {casts = 0, damage = 0},
        [S.Immolate] = {casts = 0, damage = 0},
        [S.Metamorphosis] = {casts = 0, damage = 0},
        [S.DemonicEmpowerment] = {casts = 0, damage = 0}
    }
    
    WarlockDebug("Analytics system initialized")
end

-- Track spell casts for performance analysis
function AC:TrackWarlockSpellCast(spellName)
    if not self.WarlockAnalytics then
        self:InitWarlockAnalytics()
    end
    
    local analytics = self.WarlockAnalytics
    analytics.procUtilization = analytics.procUtilization or {
        moltenCoreProcs = 0,
        moltenCoreUsed = 0,
        decimationProcs = 0,
        decimationUsed = 0,
        metamorphosisUses = 0
    }
    analytics.totalSpellsCast = analytics.totalSpellsCast + 1
    
    -- Track individual spell usage
    if analytics.spellBreakdown[spellName] then
        analytics.spellBreakdown[spellName].casts = analytics.spellBreakdown[spellName].casts + 1
    end
    
    -- Track proc usage
    local demoProcs = self:EnsureDemonologyProcState()
    if demoProcs then
        -- Only consume MC after a successful Incinerate/Soul Fire cast.
        if (spellName == S.Incinerate or spellName == S.SoulFire) and demoProcs.moltenCore and demoProcs.moltenCore.active then
            self:ConsumeMoltenCoreCharge()
        end

        -- Update proc utilization stats
        analytics.procUtilization.moltenCoreProcs = demoProcs.moltenCore.totalProcs
        analytics.procUtilization.decimationProcs = demoProcs.decimation.totalProcs
        analytics.procUtilization.metamorphosisUses = demoProcs.metamorphosis.optimalUseWindows
    end
end

-- Calculate rotation efficiency metrics
function AC:CalculateRotationEfficiency()
    if not self.WarlockAnalytics then return 0 end
    
    local analytics = self.WarlockAnalytics
    local demoProcs = self:EnsureDemonologyProcState()
    
    if not demoProcs then return 0 end
    
    local efficiency = 100 -- Start at 100%
    
    -- Proc utilization efficiency
    local moltenCoreEfficiency = 100
    if demoProcs.moltenCore.totalProcs > 0 then
        local wasteRate = (demoProcs.moltenCore.wastedCharges / (demoProcs.moltenCore.totalProcs * 3)) * 100
        moltenCoreEfficiency = 100 - wasteRate
    end
    
    local decimationEfficiency = 100
    if demoProcs.decimation.totalProcs > 0 then
        decimationEfficiency = (demoProcs.decimation.totalUsed / demoProcs.decimation.totalProcs) * 100
    end
    
    -- Weight the efficiency calculation
    efficiency = (moltenCoreEfficiency * 0.4) + (decimationEfficiency * 0.3) + (efficiency * 0.3)
    
    analytics.rotationEfficiency = efficiency
    return efficiency
end

-- Generate performance report
function AC:GetWarlockPerformanceReport()
    if not self.WarlockAnalytics then
        return "No analytics data available"
    end
    
    local analytics = self.WarlockAnalytics
    local demoProcs = self:EnsureDemonologyProcState()
    local efficiency = self:CalculateRotationEfficiency()
    
    local report = "=== DEMONOLOGY WARLOCK PERFORMANCE REPORT ===\n"
    report = report .. string.format("Combat Sessions: %d\n", analytics.combatSessions)
    report = report .. string.format("Total Spells Cast: %d\n", analytics.totalSpellsCast)
    report = report .. string.format("Rotation Efficiency: %.1f%%\n", efficiency)
    
    if demoProcs then
        report = report .. "\n--- PROC UTILIZATION ---\n"
        report = report .. string.format("Molten Core Procs: %d (Wasted: %d)\n", 
            demoProcs.moltenCore.totalProcs, demoProcs.moltenCore.wastedCharges)
        report = report .. string.format("Decimation Procs: %d (Used: %d)\n", 
            demoProcs.decimation.totalProcs, demoProcs.decimation.totalUsed)
        report = report .. string.format("Metamorphosis Uses: %d\n", 
            demoProcs.metamorphosis.optimalUseWindows)
    end
    
    report = report .. "\n--- SPELL BREAKDOWN ---\n"
    for spellName, data in pairs(analytics.spellBreakdown) do
        if data.casts > 0 then
            report = report .. string.format("%s: %d casts\n", spellName, data.casts)
        end
    end
    
    return report
end

-- Debug command to show performance
function AC:ShowWarlockPerformanceDebug()
    if AC.debugMode then
        local report = self:GetWarlockPerformanceReport()
        print(report)
    end
end

-- Enhanced spell casting with analytics tracking
-- REMOVED: CastWarlockSpellWithTracking - redundant as main function now includes tracking

-- Main casting function with integrated analytics tracking
function AC:CastWarlockSpell(spellName, unit)
    unit = unit or "target"

    if type(spellName) ~= "string" or spellName == "" then
        return false
    end
    
    -- Handle item usage.
    if spellName:find("item:") then
        local itemToken = spellName:match("item:(.+)")
        if not itemToken then return false end

        local itemID = tonumber(itemToken)
        local itemIdentifier = itemID or itemToken

        -- Weapon stones should be applied to main-hand enchant slot.
        if IsWarlockWeaponStoneIdentifier(itemIdentifier) then
            if self:ApplyWarlockStoneToWeapon(itemIdentifier, 16) then
                WarlockDebug("Applied weapon stone: " .. tostring(itemIdentifier))
                self:TrackWarlockSpellCast("ItemApply:" .. tostring(itemIdentifier))
                return true
            end
            return false
        end

        -- Other items (e.g., Healthstone) should be consumed/used normally.
        if itemID then
            if GetItemCount(itemID, true) > 0 then
                UseItemByName(itemID)
                WarlockDebug("Used item by ID: " .. tostring(itemID))
                self:TrackWarlockSpellCast("ItemUse:" .. tostring(itemID))
                return true
            end
        else
            if GetItemCount(itemToken, true) > 0 then
                UseItemByName(itemToken)
                WarlockDebug("Used item by name: " .. tostring(itemToken))
                self:TrackWarlockSpellCast("ItemUse:" .. tostring(itemToken))
                return true
            end
        end
        return false
    end
    
    -- Check if spell is usable
    if not self:CanCast(spellName) then
        return false
    end
    
    local preCast = UnitCastingInfo("player")
    local preChannel = UnitChannelInfo("player")

    -- Use core cast path first.
    if self:CastSpell(spellName, unit) then
        WarlockDebug("Cast " .. spellName .. " on " .. unit)
        self.WarlockCastFailures = self.WarlockCastFailures or {}
        self.WarlockCastFailures[spellName] = nil
        self:TrackWarlockSpellCast(spellName) -- Track successful cast
        return true
    end

    -- 3.3.5a safety fallback: some private-server clients reject through the
    -- generic gate even when the spell is otherwise castable.
    CastSpellByName(spellName, unit)

    local postCast = UnitCastingInfo("player")
    local postChannel = UnitChannelInfo("player")
    local postCooldown = self:GetSpellCooldown(spellName)
    local startedNow = ((not preCast and postCast) or (not preChannel and postChannel))
    local likelyQueued = IsCurrentSpell(spellName) and (postCooldown > 0.05 or postCast or postChannel)

    if startedNow or likelyQueued or postCooldown > 0.05 then
        WarlockDebug("Cast " .. spellName .. " on " .. unit .. " (fallback)")
        self.WarlockCastFailures = self.WarlockCastFailures or {}
        self.WarlockCastFailures[spellName] = nil
        self:TrackWarlockSpellCast(spellName)
        return true
    end

    local failKey = "WarlockCastFailReason_" .. string.gsub(spellName, "%s+", "_")
    if self:Throttle(failKey, 1.0) then
        local usable, noMana = IsUsableSpell(spellName)
        local moving = self:IsPlayerMoving() and "Y" or "N"
        local casting = (UnitCastingInfo("player") or UnitChannelInfo("player")) and "Y" or "N"
        WarlockDebug("CAST FAIL REASON [" .. spellName .. "]: usable=" .. tostring(usable) ..
            " noMana=" .. tostring(noMana) ..
            " cd=" .. string.format("%.2f", postCooldown or 0) ..
            " moving=" .. moving ..
            " casting=" .. casting)
    end

    self.WarlockCastFailures = self.WarlockCastFailures or {}
    self.WarlockCastFailures[spellName] = GetTime()
    return false
end

-- ================================================================
-- MODULE COMPLETION MESSAGE
-- ================================================================
WarlockDebug("Professional WotLK 3.3.5a Warlock module loaded successfully!")
WarlockDebug("Supported specs: Affliction (DoT), Demonology (Pet/Burst), Destruction (Direct)")
WarlockDebug("Features: Proc tracking, pet management, leveling-friendly, research-based rotations")
WarlockDebug("Enhanced: Complete buff management, weapon enchants, item creation, soul shard management")
WarlockDebug("Items: Soulstone, Healthstone, Spellstone, Firestone auto-creation and application")
