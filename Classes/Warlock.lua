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
    DrainSoul = "Drain Soul",
    Haunt = "Haunt",
    SeedOfCorruption = "Seed of Corruption",
    ShadowBolt = "Shadow Bolt",
    SiphonLife = "Siphon Life",
    UnstableAffliction = "Unstable Affliction",
    
    -- ========== DEMONOLOGY SPELLS ==========
    DemonArmor = "Demon Armor",
    DemonSkin = "Demon Skin",
    DemonicEmpowerment = "Demonic Empowerment",
    FelArmor = "Fel Armor",
    ImmolationAura = "Immolation Aura",
    Metamorphosis = "Metamorphosis",
    ShadowCleave = "Shadow Cleave", -- Metamorphosis ability
    SoulLink = "Soul Link",
    SummonFelguard = "Summon Felguard",
    SummonFelhunter = "Summon Felhunter",
    SummonImp = "Summon Imp",
    SummonSuccubus = "Summon Succubus",
    SummonVoidwalker = "Summon Voidwalker",
    
    -- ========== DESTRUCTION SPELLS ==========
    ChaosBolt = "Chaos Bolt",
    Conflagrate = "Conflagrate",
    Immolate = "Immolate",
    Incinerate = "Incinerate",
    RainOfFire = "Rain of Fire",
    SearingPain = "Searing Pain",
    ShadowBurn = "Shadowburn",
    Shadowflame = "Shadowflame",
    SoulFire = "Soul Fire",
    
    -- ========== UNIVERSAL SPELLS ==========
    DarkPact = "Dark Pact",
    LifeTap = "Life Tap",
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
    
    -- ========== PET ABILITIES ==========
    -- Imp
    FireBolt = "Firebolt",
    FireShield = "Fire Shield",
    
    -- Succubus
    LashOfPain = "Lash of Pain",
    Seduction = "Seduction",
    
    -- Felhunter
    ShadowBite = "Shadow Bite",
    SpellLock = "Spell Lock",
    DevourMagic = "Devour Magic",
    
    -- Felguard
    Cleave = "Cleave",
    Felstorm = "Felstorm",
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
    [41191] = true, [41192] = true, [41193] = true, [41194] = true, [41195] = true, [41196] = true,
    [41190] = true, [41189] = true,
    [22046] = true, [22045] = true, [22044] = true, -- Firestones
    [41169] = true, [41170] = true, [41171] = true, [41172] = true, [41173] = true, [41174] = true,
    [1254] = true, [13699] = true, [13700] = true
}

local WARLOCK_WEAPON_STONE_NAMES = {
    ["spellstone"] = true,
    ["minor spellstone"] = true,
    ["lesser spellstone"] = true,
    ["greater spellstone"] = true,
    ["major spellstone"] = true,
    ["grand spellstone"] = true,
    ["master spellstone"] = true,
    ["demonic spellstone"] = true,
    ["firestone"] = true,
    ["minor firestone"] = true,
    ["lesser firestone"] = true,
    ["greater firestone"] = true,
    ["major firestone"] = true,
    ["master firestone"] = true,
    ["demonic firestone"] = true,
    ["grand firestone"] = true
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

    -- Native usability is not a learned-spell check on every private-server
    -- client.  Prove ownership from the spellbook first.
    local spellID = select(7, GetSpellInfo(spellName))
    if spellID and spellID > 0 and IsSpellKnown and IsSpellKnown(spellID) then
        return true
    end

    -- Core's helper handles rank/name differences in the 3.3.5a spellbook.
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

    if not self:IsSpellKnown(spellName) then
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
    
    -- pcall only tells us that the API call did not throw a Lua error.  It
    -- does not mean that the enchant was applied, so verify the temporary
    -- enchant after each cursor-placement attempt before reporting success.
    local function tryApplyStone()
        ClearCursor()
        UseContainerItem(bag, slot)
        if CursorHasItem() then
            PickupInventoryItem(weaponSlot)
        end
        ClearCursor()
    end

    local success1 = pcall(tryApplyStone)
    if success1 and self:WeaponHasEnchant(weaponSlot) then
        WarlockDebug("Successfully applied " .. itemName .. " (Method 1)")
        return true
    end

    -- Retry once for clients that need the bag item to be placed on the
    -- cursor before the inventory slot is picked up.
    local success2 = pcall(tryApplyStone)
    if success2 and self:WeaponHasEnchant(weaponSlot) then
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
        local debuffName, _, _, count, _, duration, expires = UnitDebuff(unit, i)
        if not debuffName then break end
        if debuffName == spellName then
            WarlockDebug("HasDebuff (Scan method): Found " .. spellName .. " on " .. unit .. " at slot " .. i)
            return true, count, duration, expires
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

local function WarlockHasControlOrUtilityDebuff(unit, wantedTypes)
    unit = unit or "player"
    if not UnitExists(unit) then return false end

    for i = 1, 40 do
        local name, _, _, debuffType = UnitDebuff(unit, i)
        if not name then break end
        local lowerName = string.lower(name)
        if (debuffType and wantedTypes[debuffType]) or
           (wantedTypes.Bleed and lowerName:find("bleed")) then
            return true
        end
    end

    return false
end

function AC:RememberWarlockTargetCast(spellName, unit)
    if type(spellName) ~= "string" or spellName == "" then
        return
    end

    unit = unit or "target"
    if not UnitExists(unit) then
        return
    end
    if unit ~= "player" and not UnitCanAttack("player", unit) then
        return
    end

    local guid = UnitGUID(unit)
    if not guid then
        return
    end

    self.WarlockRecentTargetCasts = self.WarlockRecentTargetCasts or {}
    self.WarlockRecentTargetCasts[spellName] = {
        guid = guid,
        time = GetTime()
    }
end

function AC:WasRecentlyCastOnTarget(spellName, unit, window)
    local recent = self.WarlockRecentTargetCasts
    if type(recent) ~= "table" then
        return false
    end

    local entry = recent[spellName]
    if not entry then
        return false
    end

    unit = unit or "target"
    local guid = UnitGUID(unit)
    if not guid or entry.guid ~= guid then
        return false
    end

    return (GetTime() - (entry.time or 0)) < (window or 2.0)
end

local previousHandleClassCombatLog = AC.HandleClassCombatLog

function AC:HandleClassCombatLog(...)
    if previousHandleClassCombatLog then
        previousHandleClassCombatLog(self, ...)
    end

    local _, subevent, sourceGUID, _, _, destGUID, destName, _, _, spellName = ...

    if sourceGUID ~= UnitGUID("player") then
        return
    end

    if subevent == "SPELL_MISSED" and spellName == S.Immolate then
        local recent = self.WarlockRecentTargetCasts
        if type(recent) == "table" and recent[spellName] and recent[spellName].guid == destGUID then
            recent[spellName] = nil
            WarlockDebug("IMMOLATE missed on " .. tostring(destName) .. " - clearing retry hold")
        end
    end
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
    local classification = UnitClassification(unit)

    -- Do not abandon important boss DoTs merely because the target crossed
    -- the generic 25% execute threshold. Execute rotations still need Haunt,
    -- Unstable Affliction, and other debuffs maintained.
    if classification == "worldboss" or classification == "elite" or classification == "rareelite" or level == -1 then
        return healthPercent <= 8
    end
    
    -- Normal mobs below this point are usually dead before a fresh DoT pays
    -- back its cast time.
    if healthPercent <= 15 then
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
AC.WarlockIsFastDyingMob = AC.IsFastDyingMob
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
        
        -- CRITICAL: Decimation (<35% health, 10 seconds, faster Soul Fire)
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

    -- Count actual combat sessions for /ac performance.  This is kept here
    -- rather than in the rotation so it also works while moving, crowd-
    -- controlled, or temporarily without a valid target.
    if self.WarlockAnalytics then
        if inCombat and not self.warlockAnalyticsInCombat then
            self.WarlockAnalytics.combatSessions = (self.WarlockAnalytics.combatSessions or 0) + 1
            self.warlockAnalyticsInCombat = true
        elseif not inCombat then
            self.warlockAnalyticsInCombat = false
        end
    end
    
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
    if mc.charges > 0 and (self:IsSpellKnown(S.Incinerate) or self:IsSpellKnown(S.SoulFire)) then
        return true
    end
    
    return false
end

-- Get optimal spell to cast with Molten Core proc
function AC:GetMoltenCoreSpell()
    local demoProcs = self.DemonologyProcs
    if not demoProcs or not demoProcs.moltenCore.active then return nil end
    
    local playerLevel = UnitLevel("player")
    local targetMaxHealth = UnitHealthMax("target") or 0
    local targetHealthPercent = targetMaxHealth > 0 and (UnitHealth("target") / targetMaxHealth) * 100 or 100
    
    -- WotLK Meta: Molten Core benefits both Incinerate and Soul Fire
    -- Priority: Incinerate (faster cast, more casts per proc) > Soul Fire (higher damage)
    
    if targetHealthPercent <= 35 and playerLevel >= 48 and self:IsSpellKnown(S.SoulFire) then
        -- Under 35%, Soul Fire is the Demo execute spell even when Molten
        -- Core is active; do not spend those charges on Incinerate.
        WarlockDebug("Using Molten Core for execute Soul Fire")
        return S.SoulFire
    elseif playerLevel >= 64 and self:IsSpellKnown(S.Incinerate) then
        -- WotLK Molten Core: 20% faster cast and 12% damage for Incinerate.
        WarlockDebug("Using Molten Core for Incinerate (20% faster, +12% damage)")
        return S.Incinerate
    elseif playerLevel >= 48 and self:IsSpellKnown(S.SoulFire) then
        -- WotLK Molten Core: +12% damage and +10% crit for Soul Fire.
        WarlockDebug("Using Molten Core for Soul Fire (+12% damage, +10% crit)")
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
    
    -- ALWAYS use Decimation immediately - it is a major DPS gain:
    -- 40% faster Soul Fire cast with no Soul Shard cost.
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

local LIFE_TAP_GLYPH_BUFF_NAMES = {
    "Improved Life Tap",
    "Glyph of Life Tap",
}
local LIFE_TAP_GLYPH_REFRESH_WINDOW = 8.0
local LIFE_TAP_GLYPH_HEALTH_THRESHOLD = 70

function AC:IsLevelingWarlock()
    return UnitLevel("player") <= 10
end

function AC:HasLifeTapGlyph()
    if not GetGlyphSocketInfo then
        return nil
    end

    for glyphSlot = 1, 6 do
        local enabled, _, _, glyphName = GetGlyphSocketInfo(glyphSlot)
        if enabled and glyphName and string.find(string.lower(glyphName), "life tap", 1, true) then
            return true
        end
    end

    return false
end

function AC:GetLifeTapGlyphState()
    if self:IsLevelingWarlock() then
        return false, 0, nil, false
    end

    local glyphEquipped = self:HasLifeTapGlyph()

    for _, buffName in ipairs(LIFE_TAP_GLYPH_BUFF_NAMES) do
        local hasBuff, _, _, expires = WarlockHasBuff("player", buffName)
        if hasBuff then
            local remaining = expires and (expires - GetTime()) or 0
            return true, remaining, buffName, true
        end
    end

    return false, 0, nil, glyphEquipped
end

-- Smart Life Tap usage based on combat phase and procs
function AC:GetOptimalLifeTapTiming(spec, inCombat, procs, demoProcs)
    if self:IsLevelingWarlock() then
        return false
    end

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

    local glyphActive, glyphRemaining, glyphName, glyphEquipped = self:GetLifeTapGlyphState()
    local glyphHealthThreshold = math.max(healthThreshold, LIFE_TAP_GLYPH_HEALTH_THRESHOLD)
    local recentLifeTap = self:WasRecentlyCastOnTarget(S.LifeTap, "player", 2.5)

    -- Keep the Glyph of Life Tap buff rolling if it is missing or about to expire.
    if glyphEquipped ~= false and recentLifeTap and not glyphActive then
        WarlockDebug("LIFE TAP GLYPH: Waiting for aura sync after recent Life Tap")
        return false
    end

    if glyphEquipped ~= false and glyphActive then
        if glyphRemaining <= LIFE_TAP_GLYPH_REFRESH_WINDOW and healthPercent > glyphHealthThreshold then
            WarlockDebug("LIFE TAP GLYPH: Refreshing " .. tostring(glyphName) ..
                " (" .. string.format("%.1f", glyphRemaining) .. "s remaining)")
            return true
        end
    elseif glyphEquipped == true and healthPercent > glyphHealthThreshold then
        WarlockDebug("LIFE TAP GLYPH: Missing buff - refreshing")
        return true
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
    if self:IsLevelingWarlock() then
        return nil
    end

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
        -- Shadow Bite is the Felhunter's primary damage ability and should
        -- remain enabled for Affliction's DoT-amplified pet damage.
        self:ToggleWarlockPetSpell(S.ShadowBite, true)
        -- Always enable Spell Lock for interrupts.
        self:ToggleWarlockPetSpell(S.SpellLock, true)
        -- Enable Devour Magic for dispelling.
        self:ToggleWarlockPetSpell(S.DevourMagic, true)
        
    elseif petType == "Succubus" then
        -- Enable Lash of Pain for DPS.
        self:ToggleWarlockPetSpell(S.LashOfPain, true)
        -- Disable Seduction in groups (avoid unwanted CC).
        self:ToggleWarlockPetSpell(S.Seduction, not isInGroup)
        
    elseif petType == "Felguard" then
        -- Keep Cleave enabled for consistent DPS.
        self:ToggleWarlockPetSpell(S.Cleave, true)
        -- Manage Anguish taunt like Voidwalker.
        self:ToggleWarlockPetSpell(S.Anguish, not isInGroup)
        
    elseif petType == "Imp" then
        self:ToggleWarlockPetSpell(S.FireBolt, true)
        -- Enable Fire Shield on master for protection.
        self:ToggleWarlockPetSpell(S.FireShield, true)
    end
    
    return false
end

-- Toggle pet spell autocast (similar to Hunter TogglePetSpell)
function AC:ToggleWarlockPetSpell(spellName, enable)
    if not spellName then return false end

    for i = 1, 12 do
        -- WotLK's seventh return is autoCastEnabled. The sixth return is
        -- only autoCastAllowed and is true even when autocast is off.
        local name, _, _, _, _, _, currentIsAutocast = GetPetActionInfo(i)

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

-- Use a non-autocast pet ability such as Felstorm when it is actually useful.
function AC:UseWarlockPetAction(spellName, targetUnit)
    if not spellName or not UnitExists("pet") or UnitIsDeadOrGhost("pet") then
        return false
    end

    for i = 1, 12 do
        local name = GetPetActionInfo(i)
        if name == spellName then
            local start, duration = GetPetActionCooldown(i)
            if start and duration and duration > 0 and (start + duration - GetTime()) > 0.1 then
                return false
            end

            CastPetAction(i, targetUnit)
            local afterStart, afterDuration = GetPetActionCooldown(i)
            local started = afterStart and afterDuration and afterDuration > 0 and
                            (afterStart + afterDuration - GetTime()) > 0.05
            if not started and not UnitCastingInfo("pet") and not UnitChannelInfo("pet") then
                WarlockDebug("Pet action did not start: " .. spellName)
                return false
            end
            WarlockDebug("Pet cast: " .. spellName)
            return true
        end
    end

    return false
end

function AC:UseWarlockPetCombatAction()
    if self:GetWarlockPetType() ~= "Felguard" then return false end
    if self:GetEffectiveEnemyCount(self:GetEnemyCount()) < 2 then return false end
    return self:UseWarlockPetAction(S.Felstorm, "target")
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
        
        -- Demonic Empowerment is cast by the combat macro integration only;
        -- do not consume its throttle while still out of combat.
    end
    
    return nil
end

-- Choose optimal pet based on spec, level, and situation
function AC:GetOptimalWarlockPet(spec, playerLevel, inCombat)
    -- Demonology always uses Felguard if available
    if spec == "Demonology" and playerLevel >= 50 and self:IsSpellKnown(S.SummonFelguard) then
        return S.SummonFelguard
    end
    
    -- During solo leveling, a Voidwalker is safer and avoids pet pathing
    -- delays while the player is still gear-constrained. In groups, use the
    -- DPS/utility pet for the active spec.
    if playerLevel < 60 and not IsInGroup() and self:IsSpellKnown(S.SummonVoidwalker) then
        return S.SummonVoidwalker
    end

    -- Affliction prefers Felhunter for Shadow Bite scaling with DoTs.
    if spec == "Affliction" and playerLevel >= 30 and self:IsSpellKnown(S.SummonFelhunter) then
        return S.SummonFelhunter
    end

    -- Destruction prefers Imp for ranged damage and raid utility.
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

function AC:IsWarlockTalentKnown(talentName, minimumRank)
    if not talentName or not GetTalentInfo then return false end
    minimumRank = minimumRank or 1

    for tab = 1, GetNumTalentTabs() do
        for index = 1, GetNumTalents(tab) do
            local name, _, _, _, rank = GetTalentInfo(tab, index)
            if name == talentName then
                return (rank or 0) >= minimumRank
            end
        end
    end

    return false
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

    local targetMaxHealth = UnitHealthMax("target") or 0
    local targetHealthPercent = targetMaxHealth > 0 and (UnitHealth("target") / targetMaxHealth) * 100 or 100
    local targetClassification = UnitClassification("target")
    local targetIsTough = targetClassification == "elite" or targetClassification == "rareelite" or
                          targetClassification == "worldboss" or UnitLevel("target") == -1
    local combatTime = self:GetCombatTime()
    
    -- Emergency mana potions (use before Life Tap when critically low)
    if manaPercent < 20 then
        if self.UseManaPotion and self:UseManaPotion(20) then
            WarlockDebug("Used mana potion at " .. string.format("%.0f", manaPercent) .. "% mana")
            return true
        end
    end

    -- Use offensive trinkets and potions only on durable targets. Demo waits
    -- for Metamorphosis when it has the talent; Affliction/Destruction use
    -- the opening window directly.
    local demoBurstReady = spec == "Demonology" and
        (procs.metamorphosis or not self:IsSpellKnown(S.Metamorphosis))
    local offensiveWindow = inCombat and targetIsTough and
        ((spec == "Demonology" and demoBurstReady) or
         (spec ~= "Demonology" and combatTime <= 8) or
         targetHealthPercent <= 35)
    if offensiveWindow then
        if self.UseTrinkets and self:UseTrinkets() then
            WarlockDebug("Used offensive trinket window")
            return true
        end
        if self.UseOffensivePotion then
            local usedPotion = self:UseOffensivePotion(true)
            if usedPotion then
                WarlockDebug("Used offensive potion window")
                return true
            end
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

-- Calculate optimal Healthstone usage threshold
function AC:GetOptimalHealthstoneThreshold(inCombat)
    local baseThreshold = 35
    
    if inCombat then
        -- Use earlier in combat for safety
        baseThreshold = 45
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
    
    local spec = self:GetWarlockSpec()
    
    -- Check if main hand weapon needs enchant
    local mainHandSlot = GetInventorySlotInfo("MainHandSlot")
    local mainHandLink = GetInventoryItemLink("player", mainHandSlot)
    
    if not mainHandLink then return nil end -- No weapon equipped
    
    -- Check current enchant on main hand
    local hasEnchant = self:WeaponHasEnchant(mainHandSlot)
    
    if not hasEnchant then
        -- In WotLK, Spellstone is the periodic/Affliction stone while
        -- Firestone is the direct-damage Demo/Destruction stone.
        local useSpellstone = spec == "Affliction"
        local createSpell = useSpellstone and S.CreateSpellstone or S.CreateFirestone
        local stone = useSpellstone and self:GetSpellstone() or self:GetFirestone()

        if stone then
            WarlockDebug("Applying " .. (useSpellstone and "Spellstone" or "Firestone") .. " enchant to weapon")
            return "item:" .. stone
        elseif self:IsSpellKnown(createSpell) and self:CanCast(createSpell) then
            WarlockDebug("Creating " .. (useSpellstone and "Spellstone" or "Firestone"))
            return createSpell
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
        41191, 41192, 41193, 41194, 41195, 41196, -- WotLK ranks
        41190, 41189  -- Additional variants
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
        "Grand Spellstone", "Demonic Spellstone", "Master Spellstone",
        "Major Spellstone", "Spellstone", "Greater Spellstone",
        "Lesser Spellstone", "Minor Spellstone"
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
    local firestones = {41169, 41170, 41171, 41172, 41173, 41174,
                        22046, 22045, 22044, 1254, 13699, 13700}
    
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
    local localizedRace, englishRace = UnitRace("player")
    local race = string.upper((englishRace or localizedRace or ""):gsub("%s+", ""))
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
        if (race == "UNDEAD" or race == "SCOURGE") and WarlockHasControlOrUtilityDebuff("player", { Fear = true, Charm = true }) and self:CanCast(R.WillOfForsaken) then
            WarlockDebug("Emergency Will of the Forsaken")
            return R.WillOfForsaken
        elseif race == "HUMAN" and WarlockHasControlOrUtilityDebuff("player", { Fear = true, Stun = true, Charm = true }) and self:CanCast(R.EveryMan) then
            WarlockDebug("Emergency Every Man for Himself")
            return R.EveryMan
        elseif race == "DWARF" and WarlockHasControlOrUtilityDebuff("player", { Poison = true, Disease = true, Bleed = true }) and self:CanCast(R.Stoneform) then
            WarlockDebug("Emergency Stoneform")
            return R.Stoneform
        elseif race == "GNOME" and WarlockHasControlOrUtilityDebuff("player", { Root = true }) and self:CanCast(R.EscapeArtist) then
            WarlockDebug("Emergency Escape Artist")
            return R.EscapeArtist
        elseif race == "DRAENEI" and self:CanCast(R.GiftOfNaaru) then
            WarlockDebug("Emergency Gift of the Naaru")
            return R.GiftOfNaaru
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
        shouldUseBurst = procs.metamorphosis or procs.decimation or
                         (targetHealthPercent > 80 and not self:IsSpellKnown(S.Metamorphosis))
    end
    
    if shouldUseBurst then
        if race == "ORC" and self:CanCast(R.BloodFury) then
            WarlockDebug("Using Blood Fury (" .. spec .. " burst window)")
            return R.BloodFury
        elseif race == "TROLL" and self:CanCast(R.Berserking) then
            WarlockDebug("Using Berserking (" .. spec .. " burst window)")
            return R.Berserking
        elseif race == "BLOODELF" and self:CanCast(R.ArcaneTorrent) then
            local manaPercent = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100
            if manaPercent < 50 then
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
    
    -- WotLK has no modern pandemic refresh window. Refresh periodic effects
    -- close to expiry so their remaining ticks are not clipped.
    local function shouldRefreshDot(debuffName, baseDuration)
        if not self:HasDebuff("target", debuffName) then
            return true -- Missing DoT
        end

        local timeRemaining = self:DebuffTimeRemaining("target", debuffName) or 0
        local refreshWindow = math.min(1.0, (baseDuration or 15) * 0.08)
        return timeRemaining <= refreshWindow
    end
    
    -- Single Target Priority
    
    -- RESEARCH-BASED: Optimal Affliction DoT Priority with Pandemic Timing
    
    -- 1. Open with Shadow Bolt to establish Shadow Embrace/raid debuffs when
    -- the target is fresh. This replaces the old Haunt-first opener.
    if targetHealthPercent > 90 and procs.shadowEmbraceStacks <= 0 and
       self:IsSpellKnown(S.ShadowBolt) and not self:IsPlayerMoving() and self:CanCast(S.ShadowBolt) then
        WarlockDebug("Affliction opener: Shadow Bolt")
        return S.ShadowBolt
    end

    -- 2. Haunt - highest priority for Shadow Embrace stacks and debuff.
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
    
    -- 3. Unstable Affliction - maintain it without clipping its final ticks.
    if self:IsSpellKnown(S.UnstableAffliction) and not self:IsFastDyingMob("target") then
        if shouldRefreshDot(S.UnstableAffliction, 15) and self:CanCast(S.UnstableAffliction) then
            WarlockDebug("Casting Unstable Affliction (no-clipping refresh)")
            return S.UnstableAffliction
        end
    end

    -- 4. Corruption. At endgame, Everlasting Affliction refreshes it through
    -- Haunt/Shadow Bolt/Drain Soul, so manual reapplication would destroy the
    -- original snapshot. Without that talent, refresh it normally.
    local hasCorruption = self:HasDebuff("target", S.Corruption)
    local hasEverlastingAffliction = self:IsWarlockTalentKnown("Everlasting Affliction", 1)
    local unstableReady = not self:IsSpellKnown(S.UnstableAffliction) or self:HasDebuff("target", S.UnstableAffliction)
    if not hasCorruption and unstableReady and self:CanCast(S.Corruption) then
        WarlockDebug("Applying Corruption")
        return S.Corruption
    end
    if not hasEverlastingAffliction and unstableReady and shouldRefreshDot(S.Corruption, 18) then
        if self:CanCast(S.Corruption) then
            WarlockDebug("Refreshing Corruption (Everlasting Affliction unavailable)")
            return S.Corruption
        end
    end

    -- 5. Curse selection
    local curse = self:SelectOptimalCurse()
    if curse and self:CanCast(curse) then
        WarlockDebug("Applying curse: " .. curse)
        return curse
    end
    
    -- 6. Siphon Life maintenance (it is not refreshed by Everlasting
    -- Affliction, so keep uptime without waiting for a long gap).
    if self:IsSpellKnown(S.SiphonLife) and not self:IsFastDyingMob("target") then
        local siphonMissing = not self:HasDebuff("target", S.SiphonLife)
        local siphonExpiring = self:DebuffTimeRemaining("target", S.SiphonLife) <= 1.0
        if (siphonMissing or siphonExpiring) and self:CanCast(S.SiphonLife) then
            WarlockDebug("Maintaining Siphon Life")
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
            WarlockDebug("MOLTEN CORE: Using " .. moltenSpell .. " (WotLK proc bonus)")
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
        if self.IsInMeleeRange and self:IsInMeleeRange("target", true) and
           self:IsSpellKnown(S.Shadowflame) and self:CanCast(S.Shadowflame) then
            WarlockDebug("META AOE: Shadowflame")
            return S.Shadowflame
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
                if self:CastSpell(S.RainOfFire, "player") then
                    CameraOrSelectOrMoveStart()
                    CameraOrSelectOrMoveStop()
                    return true
                end
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
    if not self:IsLevelingWarlock() and self:CanCast(S.LifeTap) then
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
    local playerLevel = UnitLevel("player")
    local targetHealthPercent = (UnitHealth("target") / UnitHealthMax("target")) * 100
    local shouldAOE = self:ShouldUseAOEWarlock()
    local isLevelingWarlock = playerLevel <= 10
    
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
    local hasImmolate, _, _, immolateExpires = WarlockHasDebuff("target", S.Immolate)
    local immolateRemain = immolateExpires and (immolateExpires - GetTime()) or 0
    if hasImmolate then
        if immolateRemain <= 2 and self:CanCast(S.Immolate) then
            WarlockDebug("Refreshing Immolate")
            return S.Immolate
        end
    elseif isLevelingWarlock and self:WasRecentlyCastOnTarget(S.Immolate, "target", 2.5) then
        WarlockDebug("Skipping Immolate re-cast - waiting for aura sync")
    elseif self:CanCast(S.Immolate) then
        WarlockDebug("Applying Immolate")
        return S.Immolate
    end
    
    -- Apply the required curse before the first destructive cooldowns on a
    -- fresh durable target so Conflagrate/Chaos Bolt benefit from the full
    -- encounter debuff window. Immolate was deliberately allowed first so
    -- the next GCD can establish curse coverage before the direct nukes.
    if targetHealthPercent > 80 then
        local openerCurse = self:SelectOptimalCurse()
        if openerCurse and self:CanCast(openerCurse) then
            WarlockDebug("Destruction opener curse: " .. openerCurse)
            return openerCurse
        end
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

    -- Shadowflame is worthwhile when already in melee range; do not force
    -- movement just to use it.
    if self.IsInMeleeRange and self:IsInMeleeRange("target", true) and
       self:IsSpellKnown(S.Shadowflame) and self:CanCast(S.Shadowflame) then
        WarlockDebug("Casting Shadowflame in melee range")
        return S.Shadowflame
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
        if self:UseWarlockPetCombatAction() then
            return true
        end
    end
    
    -- Emergency consumables
    local consumable = self:ManageWarlockConsumables(procs)
    if consumable == true then
        return true
    elseif consumable then
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
        
        -- Priority 2: Life Tap / glyph maintenance
        local lifeTap = self:ManageWarlockLifeTap()
        if lifeTap then
            if self:CastWarlockSpell(lifeTap, "player") then
                WarlockDebug("Life Tap maintenance: " .. lifeTap)
                return true
            end
        end
        
        -- Priority 3: Advanced pet management
        local pet = self:ManageWarlockPetAdvanced()
        if pet then 
            if self:CastWarlockSpell(pet, "player") then
                WarlockDebug("Pet action: " .. pet)
                return true
            end
        end
        
        -- Priority 4: Item creation
        local itemsCreated = self:ManageWarlockItemCreation()
        if itemsCreated then 
            if self:CastWarlockSpell(itemsCreated, "player") then
                WarlockDebug("Created item: " .. itemsCreated)
                return true
            end
        end
        
        -- Priority 5: Weapon enchant management
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
    rotationEfficiency = 0
}

-- Initialize spell tracking
function AC:InitWarlockAnalytics()
    local analytics = self.WarlockAnalytics
    
    -- Initialize spell breakdown tracking
    analytics.spellBreakdown = {
        [S.ShadowBolt] = {casts = 0},
        [S.Incinerate] = {casts = 0},
        [S.SoulFire] = {casts = 0},
        [S.Corruption] = {casts = 0},
        [S.Immolate] = {casts = 0},
        [S.Metamorphosis] = {casts = 0},
        [S.DemonicEmpowerment] = {casts = 0},
        [S.Haunt] = {casts = 0},
        [S.UnstableAffliction] = {casts = 0},
        [S.ChaosBolt] = {casts = 0},
        [S.Conflagrate] = {casts = 0},
        [S.Shadowflame] = {casts = 0},
        [S.ShadowBurn] = {casts = 0}
    }
    
    WarlockDebug("Analytics system initialized")
end

-- Track spell casts for performance analysis
function AC:TrackWarlockSpellCast(spellName)
    if not self.WarlockAnalytics or not self.WarlockAnalytics.spellBreakdown or
       not self.WarlockAnalytics.spellBreakdown[S.ShadowBolt] then
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

    if spellName == S.Metamorphosis then
        self:UseMetamorphosis()
    end
    
    -- Track individual spell usage
    if spellName and not spellName:find("item:", 1, true) then
        analytics.spellBreakdown[spellName] = analytics.spellBreakdown[spellName] or {casts = 0}
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
        analytics.procUtilization.moltenCoreUsed = demoProcs.moltenCore.totalUsed or 0
        analytics.procUtilization.decimationProcs = demoProcs.decimation.totalProcs
        analytics.procUtilization.decimationUsed = demoProcs.decimation.totalUsed or 0
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
        self:RememberWarlockTargetCast(spellName, spellName == S.LifeTap and "player" or unit)
        return true
    end

    -- The core path rejects an existing ground-target cursor.  Do not bypass
    -- that safety check in the private-server fallback.
    if SpellIsTargeting and SpellIsTargeting() then
        return false
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
        self:RememberWarlockTargetCast(spellName, spellName == S.LifeTap and "player" or unit)
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
