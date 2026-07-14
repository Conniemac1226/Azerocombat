-- AzeroCombat: Utility Functions
local AddonName, AC = ...

-- Distance calculation
function AC:GetDistance(unit1, unit2)
    unit1 = unit1 or "player"
    unit2 = unit2 or "target"
    
    -- Use range checking functions to estimate distance
    if CheckInteractDistance(unit2, 1) then -- 1: Inspect (28 yards)
        return 28
    elseif CheckInteractDistance(unit2, 2) then -- 2: Trade (11.11 yards)
        return 11
    elseif CheckInteractDistance(unit2, 3) then -- 3: Duel (9.9 yards)
        return 10
    elseif CheckInteractDistance(unit2, 4) then -- 4: Follow (28 yards)
        return 28
    elseif IsItemInRange(31463, unit2) then -- Prismatic Bauble: 6 yards
        return 6
    elseif IsItemInRange(1180, unit2) then -- Scroll of Stamina: 8 yards
        return 8
    elseif IsItemInRange(1251, unit2) then -- Linen Bandage: 15 yards
        return 15
    elseif IsItemInRange(21519, unit2) then -- Mistletoe: 20 yards
        return 20
    elseif IsItemInRange(6450, unit2) then -- Silk Bandage: 30 yards
        return 30
    elseif IsItemInRange(32321, unit2) then -- Sparrowhawk Net: 40 yards
        return 40
    end
    
    return 100 -- Far away
end

-- Target HP percentage
function AC:GetTargetHealthPercent(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return 0 end
    return UnitHealth(unit) / UnitHealthMax(unit) * 100
end

-- Player HP percentage
function AC:GetPlayerHealthPercent()
    return UnitHealth("player") / UnitHealthMax("player") * 100
end

-- Calculate time until a debuff expires
function AC:DebuffTimeRemaining(unit, spellName)
    unit = unit or "target"
    local name, _, _, _, _, _, expires = UnitDebuff(unit, spellName)
    if name then
        return expires - GetTime()
    end
    return 0
end

-- Calculate time until a buff expires
function AC:BuffTimeRemaining(unit, spellName)
    unit = unit or "player"
    local name, _, _, _, _, _, expires = UnitBuff(unit, spellName)
    if name then
        return expires - GetTime()
    end
    return 0
end

-- Check if player has a proc or buff
function AC:HasProc(buffName)
    return self:HasBuff("player", buffName)
end

-- Check if unit is casting
function AC:IsCasting(unit)
    unit = unit or "player"
    local name, _, _, _, _, _, _, _, uninterruptible = UnitCastingInfo(unit)
    return name ~= nil
end

-- Check if unit is channeling
function AC:IsChanneling(unit)
    unit = unit or "player"
    local name = UnitChannelInfo(unit)
    return name ~= nil
end

-- Interrupt enemy cast if possible
function AC:TryInterrupt(interruptSpell, unit)
    unit = unit or "target"
    if self:IsCasting(unit) and self:GetSpellCooldown(interruptSpell) == 0 and
       self:IsUsableSpell(interruptSpell) and self:CastSpell(interruptSpell, unit) then
        return true
    end
    return false
end

-- Check if a spell is known
function AC:KnowsSpell(spellName)
    if not spellName then return false end

    local _, rank, _, _, _, _, spellID = GetSpellInfo(spellName)
    if spellID and spellID > 0 and IsSpellKnown then
        return IsSpellKnown(spellID) and true or false
    end

    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for i = offset + 1, offset + numSpells do
            local name, bookRank = GetSpellName(i, BOOKTYPE_SPELL)
            if name == spellName then
                if not rank or rank == "" or bookRank == rank then
                    return true
                end
            end
        end
    end

    return false
end

-- Trinket usage
function AC:UseTrinkets()
    -- Add throttling to prevent spam attempts 
    if not self:ActionThrottle("TrinketUsage", 5) then
        return false
    end
    
    local used = false
    
    -- Check both trinket slots (13 = top, 14 = bottom)
    for slot = 13, 14 do
        -- Check if there's actually an item in the slot
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local itemName = GetItemInfo(itemLink) or "Unknown"
            if self.debugMode then
                self:Debug("Checking trinket in slot " .. slot .. ": " .. itemName)
            end
            -- Check if the trinket is off cooldown
            local start, duration = GetInventoryItemCooldown("player", slot)
            local isUsable = IsUsableItem(itemLink)
            
            -- Trinket is ready if: no cooldown (start == 0) OR cooldown has expired
            local isReady = (start == 0) or (start > 0 and GetTime() >= start + duration)
            
            if isUsable and isReady then
                -- Try to use the trinket
                if self.debugMode then
                    self:Debug("Using trinket in slot " .. slot .. ": " .. (GetItemInfo(itemLink) or "Unknown"))
                end
                UseInventoryItem(slot)
                
                -- Check if this trinket has a cooldown after use (active trinket)
                -- If it has no cooldown, it's likely passive and shouldn't block other abilities
                local newStart, newDuration = GetInventoryItemCooldown("player", slot)
                if newStart > 0 and newDuration > 0 then
                    -- Active trinket with cooldown - count as successful usage
                    used = true
                    if self.debugMode then
                        self:Debug("Active trinket used with " .. newDuration .. "s cooldown")
                    end
                    break
                else
                    -- Passive trinket - don't count as successful usage
                    if self.debugMode then
                        self:Debug("Passive trinket attempted - continuing to check other abilities")
                    end
                end
            else
                if self.debugMode then
                    if not isUsable then
                        self:Debug("Trinket in slot " .. slot .. " not usable (passive or wrong conditions)")
                    elseif start > 0 and GetTime() < start + duration then
                        local remaining = start + duration - GetTime()
                        self:Debug("Trinket in slot " .. slot .. " on cooldown: " .. string.format("%.1fs", remaining))
                    end
                end
            end
        end
    end
    
    return used
end

-- Debug function
function AC:Debug(...)
    if self.debugMode then
        print("|cFF00CCFFAC Debug:|r ", ...)
    end
end

-- Print colored message
function AC:Print(...)
    print("|cFF00FF00AzeroCombat:|r ", ...)
end

-- Get best target from available enemies
function AC:GetBestTarget()
    local lowestHealth = 100
    local bestTarget = nil
    
    for i = 1, 40 do
        if UnitExists("nameplate"..i) and UnitCanAttack("player", "nameplate"..i) then
            local healthPercent = self:GetTargetHealthPercent("nameplate"..i)
            if healthPercent < lowestHealth then
                lowestHealth = healthPercent
                bestTarget = "nameplate"..i
            end
        end
    end
    
    return bestTarget
end

-- Check if player should use defensive cooldowns
function AC:ShouldUseDefensives()
    return self:GetPlayerHealthPercent() < 40
end

-- Check if we can dispel a debuff
function AC:CanDispel(unit, dispelType)
    unit = unit or "player"
    local i = 1
    while i <= 40 do
        local name, _, _, debuffType = UnitDebuff(unit, i)
        if not name then break end
        
        if debuffType == dispelType then
            return true, name
        end
        i = i + 1
    end
    return false
end

-- Check if unit is feared (WotLK 3.3.5a compatible)
function UnitIsFeared(unit)
    unit = unit or "player"
    local i = 1
    while i <= 40 do
        local name, _, _, debuffType = UnitDebuff(unit, i)
        if not name then break end
        
        if debuffType == "Fear" then
            return true
        end
        i = i + 1
    end
    return false
end

-- Check if unit is charmed (WotLK 3.3.5a compatible)  
function UnitIsCharmed(unit)
    unit = unit or "player"
    local i = 1
    while i <= 40 do
        local name, _, _, debuffType = UnitDebuff(unit, i)
        if not name then break end
        
        if debuffType == "Charm" then
            return true
        end
        i = i + 1
    end
    return false
end

-- Check for items in bags
function AC:HasItem(itemName)
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local linkName = itemLink:match("%[(.+)%]")
                if linkName == itemName then
                    return true, bag, slot
                end
            end
        end
    end
    return false
end

-- All healing potions by potency (strongest to weakest)
local healingPotions = {
    -- WotLK (verified 3.3.5)
    "Runic Healing Potion",        -- 2700-4500 HP (best WotLK)
    "Resurgent Healing Potion",    -- 1500-2500 HP
    "Powerful Rejuvenation Potion", -- 2475-4125 HP+MP
    "Endless Healing Potion",     -- 2700-4500 HP (arena usable)
    "Crazy Alchemist's Potion",    -- Random effect (alchemist only)
    -- TBC
    "Mad Alchemist's Potion",      -- 1500-2500 HP
    "Volatile Healing Potion",     -- 2080-2720 HP
    "Super Healing Potion",        -- 1500-2500 HP
    "Whomping Healing Potion",     -- 350-550 HP (instant)
    -- Classic
    "Major Healing Potion",        -- 1050-1750 HP
    "Superior Healing Potion",     -- 700-900 HP
    "Greater Healing Potion",      -- 455-585 HP
    "Healing Potion",              -- 140-180 HP
    "Lesser Healing Potion",       -- 70-90 HP
    "Minor Healing Potion",        -- 70-90 HP
    -- Special/Quest
    "Combat Healing Potion",       -- 350-550 HP (instant)
    "Live Action Potion",          -- 600 HP (instant)
    "Night Dragon's Breath",       -- 394-638 HP (quest reward)
    "Whipper Root Tuber",          -- 300-500 HP (quest reward)
    "Crystal Restore",             -- 500-700 HP (health/mana)
    "Major Rejuvenation Potion"    -- 900-1500 HP (health/mana)
}

-- All mana potions by potency (strongest to weakest) (verified 3.3.5)
local manaPotions = {
    -- WotLK
    "Runic Mana Potion",           -- 4200-4400 MP (best WotLK)
    "Powerful Rejuvenation Potion", -- 2475-4125 HP+MP
    "Icy Mana Potion",             -- 1800-3000 MP (WotLK mid-tier)
    "Endless Mana Potion",         -- 400-600 MP (arena usable)
    "Crazy Alchemist's Potion",    -- Random effect (alchemist only)
    -- TBC
    "Mad Alchemist's Potion",      -- 1500-2500 MP
    "Volatile Mana Potion",        -- 1200-2400 MP
    "Super Mana Potion",           -- 1800-3000 MP
    "Master Mana Potion",          -- 1800-3000 MP
    "Whomping Mana Potion",        -- 650-850 MP (instant)
    -- Classic
    "Major Mana Potion",           -- 1350-2250 MP
    "Superior Mana Potion",        -- 900-1500 MP  
    "Greater Mana Potion",         -- 700-900 MP
    "Mana Potion",                 -- 280-360 MP
    "Lesser Mana Potion",          -- 140-180 MP
    "Minor Mana Potion",           -- 140-180 MP
    -- Special/Quest
    "Combat Mana Potion",          -- 350-550 MP (instant)
    "Live Action Potion",          -- 600 MP (instant)
    "Sagefin Tuber",               -- 300-500 MP (quest reward)
    "Crystal Restore",             -- 500-700 MP (health/mana)
    "Major Rejuvenation Potion"    -- 900-1500 MP (health/mana)
}

local function IsGlobalCooldownActive()
    local ok, gcdStart, gcdDuration = pcall(GetSpellCooldown, 61304)
    if not ok or not gcdStart then
        ok, gcdStart, gcdDuration = pcall(GetSpellCooldown, "61304")
    end

    if gcdStart and gcdDuration and gcdDuration > 0 then
        return (gcdStart + gcdDuration - GetTime()) > 0.1
    end

    return false
end

local potionCooldownUntil = 0
local potionCombatLocked = false
local POTION_COOLDOWN_FALLBACK = 61

local function UsesCombatPotionLockout(itemName)
    return itemName and string.find(string.lower(itemName), "potion", 1, true) ~= nil
end

local function GetPotionLockoutRemaining()
    local now = GetTime()

    if potionCombatLocked and not UnitAffectingCombat("player") then
        potionCombatLocked = false
    end

    if potionCombatLocked and UnitAffectingCombat("player") then
        return 999
    end

    if potionCooldownUntil > now then
        return potionCooldownUntil - now
    end

    return 0
end

local function StartPotionLockout(itemName)
    potionCooldownUntil = math.max(potionCooldownUntil or 0, GetTime() + POTION_COOLDOWN_FALLBACK)

    -- WotLK allows one potion while in combat. Some 3.3.5 servers do not expose
    -- that lockout through bag cooldown APIs, so track it locally to prevent spam.
    if UsesCombatPotionLockout(itemName) and UnitAffectingCombat("player") then
        potionCombatLocked = true
    end
end

local function UsePotionFromBag(itemName, bag, slot)
    if not bag or not slot then
        return false, "missing_slot"
    end

    local function isOnCooldown(start, duration)
        if not start or not duration or duration <= 0 then
            return false
        end

        return (start + duration - GetTime()) > 0.1
    end

    local _, _, locked = GetContainerItemInfo(bag, slot)
    if locked then
        return false, "locked"
    end

    if IsGlobalCooldownActive() then
        return false, "gcd"
    end

    if GetPotionLockoutRemaining() > 0 then
        return false, "cooldown"
    end

    local bagStart, bagDuration = GetContainerItemCooldown and select(1, GetContainerItemCooldown(bag, slot))
    if isOnCooldown(bagStart, bagDuration) then
        potionCooldownUntil = math.max(potionCooldownUntil or 0, bagStart + bagDuration)
        return false, "cooldown"
    end

    local itemStart, itemDuration = GetItemCooldown and select(1, GetItemCooldown(itemName))
    if isOnCooldown(itemStart, itemDuration) then
        potionCooldownUntil = math.max(potionCooldownUntil or 0, itemStart + itemDuration)
        return false, "cooldown"
    end

    local usable = IsUsableItem and IsUsableItem(itemName)
    if usable == false then
        return false, "not_usable"
    end

    local preLink = GetContainerItemLink(bag, slot)
    local preCount = select(2, GetContainerItemInfo(bag, slot)) or 1

    local ok = pcall(UseContainerItem, bag, slot)
    if not ok then
        return false, "blocked"
    end

    StartPotionLockout(itemName)

    local function didUseStartCooldownOrConsume()
        local postLink = GetContainerItemLink(bag, slot)
        local postCount = select(2, GetContainerItemInfo(bag, slot)) or 0
        if preLink and (not postLink or postLink ~= preLink or postCount < preCount) then
            return true
        end

        bagStart, bagDuration = GetContainerItemCooldown and select(1, GetContainerItemCooldown(bag, slot))
        if isOnCooldown(bagStart, bagDuration) then
            return true
        end

        itemStart, itemDuration = GetItemCooldown and select(1, GetItemCooldown(itemName))
        if isOnCooldown(itemStart, itemDuration) then
            return true
        end

        return false
    end

    if didUseStartCooldownOrConsume() then
        return true, "used"
    end

    -- Bag/item cooldown updates can lag or be absent on WotLK private servers.
    -- The protected call succeeded, so assume the client accepted the potion
    -- attempt and rely on the local lockout rather than retrying every tick.
    return true, "used_assumed"
end

-- All offensive potions (damage/stats boosting) (verified 3.3.5)
local offensivePotions = {
    -- WotLK
    "Potion of Wild Magic",        -- 200 spell power + 200 crit (15s)
    "Potion of Speed",             -- 500 haste rating (15s)
    "Destruction Potion",          -- 120 spell power + 2% crit (15s)
    "Mighty Rage Potion",          -- 45-75 rage + 60 str (20s)
    -- TBC/Classic
    "Haste Potion",                -- Haste increase
    "Insane Strength Potion",      -- Strength increase
    "Heroic Potion",               -- All stats increase
    "Bloodlust Brooch",            -- Attack power
}

-- All defensive potions (armor/resistance boosting) (verified 3.3.5)
local defensivePotions = {
    -- WotLK
    "Indestructible Potion",       -- 3500 armor (2 min)
    "Mighty Arcane Protection Potion", -- 4200-6000 arcane absorb
    "Mighty Fire Protection Potion", -- 4200-6000 fire absorb
    "Mighty Frost Protection Potion", -- 4200-6000 frost absorb
    "Mighty Nature Protection Potion", -- 4200-6000 nature absorb
    "Mighty Shadow Protection Potion", -- 4200-6000 shadow absorb
    -- Classic/TBC
    "Limited Invulnerability Potion", -- 120 physical dmg reduction (8s)
    "Ironshield Potion",           -- 2500 armor
    "Mighty Defense Potion",       -- Defense rating
    "Stoneshield Potion",          -- Armor
    "Protection Potion",           -- Physical damage absorption
}

-- All flasks by potency (strongest to weakest) (verified 3.3.5)
local flasks = {
    -- WotLK Flasks (2 hour duration, persist through death)
    "Flask of the Frost Wyrm",     -- 125 spell power (best caster)
    "Flask of Endless Rage",       -- 180 attack power (best melee)
    "Flask of Fortification",      -- 650 health (best tank)
    "Flask of Pure Mojo",          -- 90 mp5 (best mana regen)
    "Flask of Stoneblood",         -- 650 health (alternative tank)
    -- TBC Flasks
    "Flask of Supreme Power",      -- 150 spell power
    "Flask of Relentless Assault", -- 120 attack power
    "Flask of Fortification",      -- 500 health
    "Flask of Blinding Light",     -- 80 spell power (priest/paladin)
    "Flask of Pure Death",         -- 80 spell power + shadow spells
    "Flask of Mighty Restoration", -- 25 mp5
    "Flask of Chromatic Resistance", -- All resistances
    -- Classic Flasks
    "Flask of the Titans",         -- 400 health
    "Flask of Supreme Power",      -- 150 spell power
    "Flask of Distilled Wisdom",   -- 2000 mana
    "Flask of Stamina",            -- 200 stamina
    "Flask of Chromatic Resistance" -- All resistances
}

-- All elixirs by category (verified 3.3.5)
local battleElixirs = {
    -- WotLK Battle Elixirs (30 min, removed on death)
    "Elixir of Mighty Agility",    -- 45 agility + 35 crit (best agi)
    "Elixir of Mighty Strength",   -- 50 strength (best str)  
    "Elixir of Lightning Speed",   -- 45 haste rating (best haste)
    "Elixir of Deadly Strikes",    -- 45 crit rating (best crit)
    "Elixir of Expertise",         -- 45 expertise rating (best expertise)
    "Elixir of Mighty Thoughts",   -- 45 intellect (best int)
    "Elixir of Protection",        -- 800 armor (best armor)
    "Elixir of Spirit",            -- 50 spirit (best spirit)
    "Elixir of Mighty Mageblood",  -- 40 mp5 (best mana regen)
    -- TBC Battle Elixirs
    "Elixir of Major Agility",     -- 35 agility + 20 crit
    "Elixir of Major Strength",    -- 35 strength
    "Elixir of the Mongoose",      -- 25 agility + 2% crit
    "Elixir of Major Fortitude",   -- 250 health
    "Elixir of Major Mageblood",   -- 16 mp5
    "Elixir of Draenic Wisdom",    -- 30 intellect + 30 spirit
    "Elixir of Major Shadow Power", -- 55 shadow spell power
    "Elixir of Major Firepower",   -- 55 fire spell power
    "Elixir of Major Frost Power", -- 55 frost spell power
    -- Classic Battle Elixirs
    "Elixir of the Giants",        -- 25 strength
    "Elixir of Greater Agility",   -- 25 agility
    "Elixir of Shadow Power",      -- 40 shadow spell power
    "Elixir of Firepower",         -- 40 fire spell power
    "Elixir of Frost Power",       -- 40 frost spell power
    "Elixir of the Sages",         -- 18 intellect + 18 spirit
    "Elixir of Brute Force",       -- 18 strength + 18 stamina
}

local guardianElixirs = {
    -- WotLK Guardian Elixirs (30 min, removed on death) 
    "Elixir of Mighty Defense",    -- 550 defense rating (best defense)
    "Elixir of Mighty Fortitude",  -- 350 health + 20 hp5 (best health)
    "Elixir of Mighty Mageblood",  -- 40 mp5 (best mana, same as battle)
    "Elixir of Protection",        -- 800 armor (best armor, same as battle)
    "Gift of Arthas",              -- 140 attack power vs undead
    -- TBC Guardian Elixirs  
    "Elixir of Major Defense",     -- 550 defense rating
    "Elixir of Major Fortitude",   -- 250 health
    "Elixir of Draenic Wisdom",    -- 30 intellect + 30 spirit
    "Elixir of Ironskin",          -- 30 resilience
    -- Classic Guardian Elixirs
    "Elixir of Fortitude",         -- 120 health
    "Elixir of Detect Undead",     -- Detect undead
    "Elixir of Water Walking",     -- Walk on water
}

-- All utility potions (verified 3.3.5)
local utilityPotions = {
    "Free Action Potion",          -- Immune to stun/snare/slow (30s)
    "Speed Potion",                -- 50% speed increase
    "Swim Speed Potion",           -- Water walking
    "Lesser Invisibility Potion",  -- Invisibility
    "Greater Invisibility Potion", -- Invisibility
    "Potion of Invisibility",      -- Invisibility
    "Living Action Potion",        -- Remove stun/snare
    "Dreamless Sleep Potion",      -- Put enemy to sleep
    "Shrinking Violet",            -- Reduce size
    "Growth Potion",               -- Increase size
}

-- Healing potion usage (improved with throttling and cooldown checks)
function AC:UseHealthPotion(threshold)
    threshold = threshold or 30  -- Default to 30% health
    
    local healthPercent = self:GetPlayerHealthPercent()
    if self.debugMode then
        self:Debug(string.format("Health potion check: HP %.0f%% / threshold %d%%", healthPercent, threshold))
    end

    if healthPercent >= threshold then
        return false, "threshold"
    end

    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false, "casting"
    end
    
    -- Throttle potion attempts to prevent spam
    if not self:ActionThrottle("HealthPotionUse", 0.5) then
        return false, "throttle"
    end
    
    for _, potion in ipairs(healingPotions) do
        local hasItem, bag, slot = self:HasItem(potion)
        if hasItem then
            if self.debugMode then
                self:Debug("Health potion candidate found: " .. potion)
            end
            local used, reason = UsePotionFromBag(potion, bag, slot)
            if used then
                self:Print("Using " .. potion)
                return true, potion
            end

            if self.debugMode then
                self:Debug("Health potion " .. potion .. " unavailable: " .. tostring(reason))
            end

            if reason ~= "not_usable" and reason ~= "missing_slot" then
                return false, reason
            end
        end
    end
    
    if self.debugMode then
        self:Debug("No health potions available or all on cooldown")
    end
    return false, "missing_item"
end

-- Mana potion usage (improved with throttling and cooldown checks)
function AC:UseManaPotion(threshold)
    threshold = threshold or 20  -- Default to 20% mana
    
    local maxMana = UnitPowerMax("player", 0)
    if maxMana <= 0 then
        return false, "no_mana"
    end

    local manaPercent = UnitPower("player", 0) / maxMana * 100
    if manaPercent >= threshold then
        return false, "threshold"
    end

    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false, "casting"
    end
    
    -- Throttle potion attempts to prevent spam
    if not self:ActionThrottle("ManaPotionUse", 0.5) then
        return false, "throttle"
    end
    
    for _, potion in ipairs(manaPotions) do
        local hasItem, bag, slot = self:HasItem(potion)
        if hasItem then
            local used, reason = UsePotionFromBag(potion, bag, slot)
            if used then
                self:Print("Using " .. potion)
                return true, potion
            end

            if self.debugMode then
                self:Debug("Mana potion " .. potion .. " unavailable: " .. tostring(reason))
            end

            if reason ~= "not_usable" and reason ~= "missing_slot" then
                return false, reason
            end
        end
    end
    
    if self.debugMode then
        self:Debug("No mana potions available or all on cooldown")
    end
    return false, "missing_item"
end

-- Combo healing/mana potions (improved with throttling and cooldown checks)
function AC:UseComboPotion(healthThreshold, manaThreshold)
    healthThreshold = healthThreshold or 30
    manaThreshold = manaThreshold or 20
    
    local healthPercent = self:GetPlayerHealthPercent()
    local maxMana = UnitPowerMax("player", 0)
    if maxMana <= 0 then
        return false, "no_mana"
    end

    local manaPercent = UnitPower("player", 0) / maxMana * 100
    
    if healthPercent >= healthThreshold or manaPercent >= manaThreshold then
        return false, "threshold"
    end
    
    -- Throttle potion attempts to prevent spam
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false, "casting"
    end

    if not self:ActionThrottle("ComboPotionUse", 0.5) then
        return false, "throttle"
    end
    
    -- Use combo potions that heal both health and mana
    local comboPotions = {
        "Crazy Alchemist's Potion",
        "Mad Alchemist's Potion",
        "Crystal Restore",
        "Major Rejuvenation Potion"
    }
    
    for _, potion in ipairs(comboPotions) do
        local hasItem, bag, slot = self:HasItem(potion)
        if hasItem then
            local used, reason = UsePotionFromBag(potion, bag, slot)
            if used then
                self:Print("Using " .. potion .. " (combo)")
                return true, potion
            end

            if self.debugMode then
                self:Debug("Combo potion " .. potion .. " unavailable: " .. tostring(reason))
            end

            if reason ~= "not_usable" and reason ~= "missing_slot" then
                return false, reason
            end
        end
    end
    
    if self.debugMode then
        self:Debug("No combo potions available or all on cooldown")
    end
    return false, "missing_item"
end

-- Use offensive potions (improved with throttling and cooldown checks)
function AC:UseOffensivePotion(buffsActive)
    if not buffsActive then
        return false, "no_buffs"
    end
    
    -- Throttle offensive potion attempts to prevent spam (longer interval)
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false, "casting"
    end

    if not self:ActionThrottle("OffensivePotionUse", 0.5) then
        return false, "throttle"
    end
    
    for _, potion in ipairs(offensivePotions) do
        local hasItem, bag, slot = self:HasItem(potion)
        if hasItem then
            local used, reason = UsePotionFromBag(potion, bag, slot)
            if used then
                self:Print("Using " .. potion)
                return true, potion
            end

            if self.debugMode then
                self:Debug("Offensive potion " .. potion .. " unavailable: " .. tostring(reason))
            end

            if reason ~= "not_usable" and reason ~= "missing_slot" then
                return false, reason
            end
        end
    end
    
    if self.debugMode then
        self:Debug("No offensive potions available or all on cooldown")
    end
    return false, "missing_item"
end

-- Use defensive potions (improved with throttling and cooldown checks)
function AC:UseDefensivePotion(dangerLevel)
    dangerLevel = dangerLevel or 2  -- 1: low threat, 2: moderate, 3: high
    
    local healthPercent = self:GetPlayerHealthPercent()
    if healthPercent >= (dangerLevel * 15) then
        return false, "threshold"
    end
    
    -- Throttle defensive potion attempts to prevent spam
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false, "casting"
    end

    if not self:ActionThrottle("DefensivePotionUse", 0.5) then
        return false, "throttle"
    end
    
    for _, potion in ipairs(defensivePotions) do
        local hasItem, bag, slot = self:HasItem(potion)
        if hasItem then
            local used, reason = UsePotionFromBag(potion, bag, slot)
            if used then
                self:Print("Using " .. potion)
                return true, potion
            end

            if self.debugMode then
                self:Debug("Defensive potion " .. potion .. " unavailable: " .. tostring(reason))
            end

            if reason ~= "not_usable" and reason ~= "missing_slot" then
                return false, reason
            end
        end
    end
    
    if self.debugMode then
        self:Debug("No defensive potions available or all on cooldown")
    end
    return false, "missing_item"
end

-- Use utility potions
function AC:UseUtilityPotion(situation)
    local potionMap = {
        ["speed"] = "Speed Potion",
        ["freedom"] = "Free Action Potion",
        ["invisibility"] = "Greater Invisibility Potion",
        ["immunity"] = "Limited Invulnerability Potion",
        ["swim"] = "Swim Speed Potion"
    }
    
    local potion = potionMap[situation]
    if potion then
        if UnitCastingInfo("player") or UnitChannelInfo("player") then
            return false, "casting"
        end

        local hasItem, bag, slot = self:HasItem(potion)
        if hasItem then
            local used, reason = UsePotionFromBag(potion, bag, slot)
            if used then
                self:Print("Using " .. potion)
                return true, potion
            end

            if self.debugMode then
                self:Debug("Utility potion " .. potion .. " unavailable: " .. tostring(reason))
            end

            return false, reason
        end
    end
    return false, "missing_item"
end

-- Check if player has any flask buff active
function AC:HasFlaskBuff()
    -- Check for common flask buff patterns
    local flaskPatterns = {
        "Flask of",
        "Distilled Wisdom",
        "Fortification",
        "Pure Mojo",
        "Frost Wyrm",
        "Endless Rage",
        "Supreme Power",
        "Relentless Assault",
        "Stoneblood"
    }
    
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if name then
            for _, pattern in ipairs(flaskPatterns) do
                if name:find(pattern) then
                    return true, name
                end
            end
        end
    end
    return false
end

-- Use flask (improved with buff checking and throttling)
function AC:UseFlask(preferredType)
    -- Check if we already have a flask buff
    local hasFlask, flaskName = self:HasFlaskBuff()
    if hasFlask then
        if self.debugMode then
            self:Debug("Flask already active: " .. (flaskName or "Unknown"))
        end
        return false
    end
    
    -- Throttle flask attempts to prevent spam (longer interval since flasks are expensive)
    if not self:ActionThrottle("FlaskUse", 15.0) then
        return false
    end
    
    local flaskPriority = flasks
    
    -- Reorder based on preferred type for class optimization
    if preferredType == "spell_power" then
        flaskPriority = {
            "Flask of the Frost Wyrm", "Flask of Supreme Power", "Flask of Pure Death", 
            "Flask of Blinding Light", "Flask of Pure Mojo", "Flask of Mighty Restoration"
        }
        -- Add remaining flasks
        for _, flask in ipairs(flasks) do
            local found = false
            for _, priority in ipairs(flaskPriority) do
                if flask == priority then found = true break end
            end
            if not found then table.insert(flaskPriority, flask) end
        end
    elseif preferredType == "attack_power" then
        flaskPriority = {
            "Flask of Endless Rage", "Flask of Relentless Assault", "Flask of Pure Mojo"
        }
        -- Add remaining flasks
        for _, flask in ipairs(flasks) do
            local found = false
            for _, priority in ipairs(flaskPriority) do
                if flask == priority then found = true break end
            end
            if not found then table.insert(flaskPriority, flask) end
        end
    elseif preferredType == "tank" then
        flaskPriority = {
            "Flask of Fortification", "Flask of Stoneblood", "Flask of the Titans", 
            "Flask of Stamina", "Flask of Chromatic Resistance"
        }
        -- Add remaining flasks
        for _, flask in ipairs(flasks) do
            local found = false
            for _, priority in ipairs(flaskPriority) do
                if flask == priority then found = true break end
            end
            if not found then table.insert(flaskPriority, flask) end
        end
    end
    
    for _, flask in ipairs(flaskPriority) do
        if self:HasItem(flask) then
            -- Check if flask is off cooldown with error handling
            local success, start, duration = pcall(GetItemCooldown, flask)
            if success and start == 0 then
                UseItemByName(flask)
                self:Print("Using " .. flask)
                return true
            else
                -- Flask on cooldown, continue checking other flasks
                if self.debugMode then
                    self:Debug("Flask " .. flask .. " on cooldown or error checking")
                end
            end
        end
    end
    
    if self.debugMode then
        self:Debug("No flasks available or all on cooldown")
    end
    return false
end

-- Check if player has any battle elixir buff active
function AC:HasBattleElixirBuff()
    -- Check for common battle elixir buff patterns
    local battlePatterns = {
        "Elixir of.*Agility",
        "Elixir of.*Strength", 
        "Elixir of.*Speed",
        "Elixir of.*Strikes",
        "Elixir of.*Expertise",
        "Elixir of.*Thoughts",
        "Elixir of.*Spirit",
        "Elixir of.*Mageblood",
        "Elixir of.*Giants",
        "Elixir of.*Mongoose",
        "Elixir of.*Shadow Power",
        "Elixir of.*Firepower",
        "Elixir of.*Frost Power",
        "Elixir of.*Sages",
        "Elixir of.*Brute Force"
    }
    
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if name then
            for _, pattern in ipairs(battlePatterns) do
                if name:find(pattern) then
                    return true, name
                end
            end
        end
    end
    return false
end

-- Check if player has any guardian elixir buff active
function AC:HasGuardianElixirBuff()
    -- Check for common guardian elixir buff patterns
    local guardianPatterns = {
        "Elixir of.*Defense",
        "Elixir of.*Fortitude",
        "Elixir of.*Protection", 
        "Elixir of.*Mageblood",
        "Gift of Arthas",
        "Elixir of.*Ironskin",
        "Elixir of.*Detect",
        "Elixir of.*Water Walking"
    }
    
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if name then
            for _, pattern in ipairs(guardianPatterns) do
                if name:find(pattern) then
                    return true, name
                end
            end
        end
    end
    return false
end

-- Get optimal battle elixir based on class and spec
function AC:GetOptimalBattleElixir()
    local class = UnitClass("player")
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    
    -- Prioritize WotLK elixirs for level 80 characters
    local wotlkElixirs = level >= 70
    
    if class == "WARRIOR" then
        if spec == "Arms" or spec == "Fury" then
            return wotlkElixirs and "Elixir of Mighty Strength" or "Elixir of the Giants"
        elseif spec == "Protection" then
            return wotlkElixirs and "Elixir of Expertise" or "Elixir of Major Agility"
        end
    elseif class == "PALADIN" then
        if spec == "Retribution" then
            return wotlkElixirs and "Elixir of Mighty Strength" or "Elixir of the Giants"
        elseif spec == "Protection" then
            return wotlkElixirs and "Elixir of Expertise" or "Elixir of Major Agility"
        elseif spec == "Holy" then
            return wotlkElixirs and "Elixir of Mighty Thoughts" or "Elixir of the Sages"
        end
    elseif class == "HUNTER" then
        return wotlkElixirs and "Elixir of Mighty Agility" or "Elixir of the Mongoose"
    elseif class == "ROGUE" then
        return wotlkElixirs and "Elixir of Mighty Agility" or "Elixir of the Mongoose"
    elseif class == "PRIEST" then
        if spec == "Shadow" then
            return wotlkElixirs and "Elixir of Major Shadow Power" or "Elixir of Shadow Power"
        else
            return wotlkElixirs and "Elixir of Mighty Thoughts" or "Elixir of the Sages"
        end
    elseif class == "SHAMAN" then
        if spec == "Enhancement" then
            return wotlkElixirs and "Elixir of Mighty Agility" or "Elixir of the Mongoose"
        elseif spec == "Elemental" then
            return wotlkElixirs and "Elixir of Mighty Thoughts" or "Elixir of the Sages"
        elseif spec == "Restoration" then
            return wotlkElixirs and "Elixir of Spirit" or "Elixir of the Sages"
        end
    elseif class == "MAGE" then
        if spec == "Fire" then
            return wotlkElixirs and "Elixir of Major Firepower" or "Elixir of Firepower"
        elseif spec == "Frost" then
            return wotlkElixirs and "Elixir of Major Frost Power" or "Elixir of Frost Power"
        else -- Arcane
            return wotlkElixirs and "Elixir of Mighty Thoughts" or "Elixir of the Sages"
        end
    elseif class == "WARLOCK" then
        return wotlkElixirs and "Elixir of Major Shadow Power" or "Elixir of Shadow Power"
    elseif class == "DRUID" then
        if spec == "Feral" then
            return wotlkElixirs and "Elixir of Mighty Agility" or "Elixir of the Mongoose"
        elseif spec == "Balance" then
            return wotlkElixirs and "Elixir of Mighty Thoughts" or "Elixir of the Sages"
        elseif spec == "Restoration" then
            return wotlkElixirs and "Elixir of Spirit" or "Elixir of the Sages"
        end
    elseif class == "DEATHKNIGHT" then
        return wotlkElixirs and "Elixir of Mighty Strength" or "Elixir of the Giants"
    end
    
    -- Fallback to generic strength/agility based on role
    if self:IsTankSpec() then
        return wotlkElixirs and "Elixir of Expertise" or "Elixir of Major Agility"
    else
        return wotlkElixirs and "Elixir of Mighty Agility" or "Elixir of the Mongoose"
    end
end

-- Get optimal guardian elixir based on class and spec
function AC:GetOptimalGuardianElixir()
    local class = UnitClass("player")
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    
    -- Prioritize WotLK elixirs for level 80 characters
    local wotlkElixirs = level >= 70
    
    if self:IsTankSpec() then
        if spec == "Protection" and (class == "WARRIOR" or class == "PALADIN") then
            return wotlkElixirs and "Elixir of Mighty Defense" or "Elixir of Major Defense"
        else
            return wotlkElixirs and "Elixir of Mighty Fortitude" or "Elixir of Major Fortitude"
        end
    elseif self:IsHealingSpec() then
        return wotlkElixirs and "Elixir of Mighty Mageblood" or "Elixir of Major Mageblood"
    else
        -- DPS specs get health
        return wotlkElixirs and "Elixir of Mighty Fortitude" or "Elixir of Major Fortitude"
    end
end

function AC:IsHealingSpec()
    local spec = self:GetPlayerSpec()
    return spec == "Holy" or spec == "Discipline" or
           spec == "Restoration" or spec == "Resto"
end

-- Use battle elixir (improved with buff checking, class optimization, and throttling)
function AC:UseBattleElixir(preferredElixir)
    -- Check if we already have a battle elixir buff
    local hasBattleElixir, elixirName = self:HasBattleElixirBuff()
    if hasBattleElixir then
        if self.debugMode then
            self:Debug("Battle elixir already active: " .. (elixirName or "Unknown"))
        end
        return false
    end
    
    -- Throttle elixir attempts to prevent spam
    if not self:ActionThrottle("BattleElixirUse", 10.0) then
        return false
    end
    
    -- Use preferred elixir if specified, otherwise get optimal for class/spec
    local targetElixir = preferredElixir or self:GetOptimalBattleElixir()
    local elixirPriority = {targetElixir}
    
    -- Add fallback options from battleElixirs list
    for _, elixir in ipairs(battleElixirs) do
        if elixir ~= targetElixir then
            table.insert(elixirPriority, elixir)
        end
    end
    
    for _, elixir in ipairs(elixirPriority) do
        if self:HasItem(elixir) then
            -- Check if elixir is off cooldown with error handling
            local success, start, duration = pcall(GetItemCooldown, elixir)
            if success and start == 0 then
                UseItemByName(elixir)
                self:Print("Using " .. elixir)
                return true
            else
                -- Elixir on cooldown, continue checking other elixirs
                if self.debugMode then
                    self:Debug("Battle elixir " .. elixir .. " on cooldown or error checking")
                end
            end
        end
    end
    
    if self.debugMode then
        self:Debug("No battle elixirs available or all on cooldown")
    end
    return false
end

-- Use guardian elixir (improved with buff checking, class optimization, and throttling)
function AC:UseGuardianElixir(preferredElixir)
    -- Check if we already have a guardian elixir buff
    local hasGuardianElixir, elixirName = self:HasGuardianElixirBuff()
    if hasGuardianElixir then
        if self.debugMode then
            self:Debug("Guardian elixir already active: " .. (elixirName or "Unknown"))
        end
        return false
    end
    
    -- Throttle elixir attempts to prevent spam
    if not self:ActionThrottle("GuardianElixirUse", 10.0) then
        return false
    end
    
    -- Use preferred elixir if specified, otherwise get optimal for class/spec
    local targetElixir = preferredElixir or self:GetOptimalGuardianElixir()
    local elixirPriority = {targetElixir}
    
    -- Add fallback options from guardianElixirs list
    for _, elixir in ipairs(guardianElixirs) do
        if elixir ~= targetElixir then
            table.insert(elixirPriority, elixir)
        end
    end
    
    for _, elixir in ipairs(elixirPriority) do
        if self:HasItem(elixir) then
            -- Check if elixir is off cooldown with error handling
            local success, start, duration = pcall(GetItemCooldown, elixir)
            if success and start == 0 then
                UseItemByName(elixir)
                self:Print("Using " .. elixir)
                return true
            else
                -- Elixir on cooldown, continue checking other elixirs
                if self.debugMode then
                    self:Debug("Guardian elixir " .. elixir .. " on cooldown or error checking")
                end
            end
        end
    end
    
    if self.debugMode then
        self:Debug("No guardian elixirs available or all on cooldown")
    end
    return false
end

-- Use both battle and guardian elixirs as appropriate
function AC:UseElixirs(preferredBattle, preferredGuardian)
    local battleUsed = self:UseBattleElixir(preferredBattle)
    local guardianUsed = self:UseGuardianElixir(preferredGuardian)
    return battleUsed or guardianUsed
end

-- All agility scrolls by potency (strongest to weakest)
local agilityScrolls = {
    "Scroll of Agility VII",        -- +17 Agility (30 min)
    "Scroll of Agility VI",         -- +12 Agility (30 min)
    "Scroll of Agility V",          -- +9 Agility (30 min)
    "Scroll of Agility IV",         -- +7 Agility (30 min)
    "Scroll of Agility III",        -- +5 Agility (30 min)
    "Scroll of Agility II",         -- +4 Agility (30 min)
    "Scroll of Agility",            -- +3 Agility (30 min)
}

-- Use agility scroll if available and not buffed
function AC:UseAgilityScroll()
    -- Check if we already have an agility scroll buff
    local hasAgilityBuff = false
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if name and name:find("Agility") then
            hasAgilityBuff = true
            break
        end
    end
    
    if not hasAgilityBuff then
        for _, scroll in ipairs(agilityScrolls) do
            if self:HasItem(scroll) then
                UseItemByName(scroll)
                self:Print("Using " .. scroll)
                return true
            end
        end
    end
    return false
end

-- All-in-one potion manager
function AC:UseBestPotion(situation)
    -- situation can be: "health", "mana", "combo", "offensive", "defensive", "utility-speed", etc.
    
    if situation == "health" then
        return self:UseHealthPotion()
    elseif situation == "mana" then
        return self:UseManaPotion()
    elseif situation == "combo" then
        return self:UseComboPotion()
    elseif situation == "offensive" then
        return self:UseOffensivePotion(true)
    elseif situation == "defensive" then
        return self:UseDefensivePotion(2)
    elseif situation:find("utility") then
        local utilType = situation:split("-")[2]
        return self:UseUtilityPotion(utilType)
    end
    
    return false
end

-- Universal consumable manager for flasks, elixirs, and class-specific optimization
function AC:UseBestConsumables(options)
    options = options or {}
    local usedAny = false
    
    -- Use flask if requested and not already active
    if options.flask ~= false then -- Default to true unless explicitly false
        local flaskType = options.flask
        if type(flaskType) ~= "string" then
            -- Auto-detect optimal flask type based on class
            local class = UnitClass("player")
            if class == "MAGE" or class == "WARLOCK" or class == "PRIEST" then
                flaskType = "spell_power"
            elseif class == "WARRIOR" or class == "ROGUE" or class == "HUNTER" or class == "DEATHKNIGHT" then
                flaskType = "attack_power"
            elseif self:IsTankSpec() then
                flaskType = "tank"
            else
                flaskType = nil -- Use default priority
            end
        end
        
        if self:UseFlask(flaskType) then
            usedAny = true
        end
    end
    
    -- Use elixirs if requested and not already active
    if options.elixirs ~= false then -- Default to true unless explicitly false
        if self:UseElixirs(options.battleElixir, options.guardianElixir) then
            usedAny = true
        end
    end
    
    -- Use scrolls if requested
    if options.scrolls then
        if self:UseAgilityScroll() then
            usedAny = true
        end
    end
    
    return usedAny
end

-- =============================================
-- ROGUE-SPECIFIC UTILITY FUNCTIONS
-- =============================================

-- Enhanced positioning check for rogues
function AC:IsInOptimalPosition()
    if not UnitExists("target") then return false end
    
    local inMelee = CheckInteractDistance("target", 3)
    local behind = self:IsBehindTarget()
    
    return inMelee and behind
end

-- Check if we should prioritize positioning
function AC:ShouldRepositionForBackstab()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local energy = UnitPower("player", 3)
    
    -- Only worth repositioning for Backstab if we have the energy and it's beneficial
    if spec == "Subtlety" or (level < 50 and energy >= 60) then
        return not self:IsBehindTarget() and CheckInteractDistance("target", 3)
    end
    
    return false
end

-- Calculate effective DPS of different abilities
function AC:GetAbilityDPS(spellName, comboPoints)
    comboPoints = comboPoints or 0
    
    -- Note: You need to define S table or use spell names directly
    local baseDamage = {
        ["Sinister Strike"] = {min = 98, max = 132}, -- Level 80 base
        ["Mutilate"] = {min = 180, max = 220}, -- Both weapons
        ["Backstab"] = {min = 150, max = 190}, -- With positioning bonus
        ["Hemorrhage"] = {min = 110, max = 150}, -- Plus DoT
        ["Eviscerate"] = {min = 380, max = 540}, -- At 5 CP
        ["Envenom"] = {min = 420, max = 580}, -- At 5 CP with poisons
    }
    
    local damage = baseDamage[spellName]
    if damage then
        local avgDamage = (damage.min + damage.max) / 2
        
        -- Scale finishers by combo points
        if spellName == "Eviscerate" or spellName == "Envenom" then
            avgDamage = avgDamage * (comboPoints / 5)
        end
        
        return avgDamage
    end
    
    return 0
end

-- Check if we have enough resources for a full rotation
function AC:CanExecuteFullRotation()
    local energy = UnitPower("player", 3)
    local cp = GetComboPoints("player", "target")
    local spec = self:GetPlayerSpec()
    
    if spec == "Assassination" then
        -- Need enough energy for Mutilate -> Envenom
        return energy >= 120 or (cp >= 4 and energy >= 35)
    elseif spec == "Combat" then
        -- Need enough energy for SS -> Eviscerate
        return energy >= 75 or (cp >= 4 and energy >= 35)
    elseif spec == "Subtlety" then
        -- Need enough energy for Hemorrhage -> Eviscerate
        return energy >= 85 or (cp >= 4 and energy >= 35)
    end
    
    return energy >= 60
end

-- Predict incoming damage for defensive planning
function AC:PredictIncomingDamage()
    if not UnitExists("target") then return 0 end
    
    local targetLevel = UnitLevel("target")
    local playerLevel = UnitLevel("player")
    local levelDiff = targetLevel - playerLevel
    
    -- Estimate based on level difference and mob type
    local baseDamage = 100 -- Base damage per hit
    local classification = UnitClassification("target")
    
    if classification == "elite" then
        baseDamage = baseDamage * 1.5
    elseif classification == "rareelite" then
        baseDamage = baseDamage * 2
    elseif classification == "worldboss" then
        baseDamage = baseDamage * 3
    end
    
    -- Scale by level difference
    baseDamage = baseDamage * (1 + (levelDiff * 0.1))
    
    return math.max(baseDamage, 50) -- Minimum 50 damage
end

-- Enhanced threat management for rogues in groups
function AC:ShouldManageThreat()
    if not IsInGroup() then return false end
    
    -- Check if there's a tank in the group
    local hasTank = false
    local groupSize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or (GetNumPartyMembers() + 1)
    
    for i = 1, groupSize do
        local unit = GetNumRaidMembers() > 0 and "raid"..i or (i == 1 and "player" or "party"..(i-1))
        if UnitExists(unit) and self:IsTank(unit) then
            hasTank = true
            break
        end
    end
    
    -- If we have a tank, we should manage threat
    return hasTank
end

-- Calculate optimal energy threshold for abilities
function AC:GetOptimalEnergyThreshold(spec, ability)
    local thresholds = {
        ["Assassination"] = {
            ["Mutilate"] = 60,
            ["Envenom"] = 35,
            ["Rupture"] = 25,
        },
        ["Combat"] = {
            ["Sinister Strike"] = 40,
            ["Eviscerate"] = 35,
            ["Slice and Dice"] = 25,
        },
        ["Subtlety"] = {
            ["Hemorrhage"] = 50,
            ["Backstab"] = 60,
            ["Eviscerate"] = 35,
        }
    }
    
    if thresholds[spec] and thresholds[spec][ability] then
        return thresholds[spec][ability]
    end
    
    return 40 -- Default threshold
end

-- Check for optimal finishing conditions
function AC:IsOptimalFinishingTime(spec, cp)
    local targetHP = self:GetTargetHealthPercent("target")
    local energy = UnitPower("player", 3)
    
    -- Always finish if target is dying
    if targetHP < 25 then
        return cp >= 1
    end
    
    -- Wait for more CPs on healthy targets unless we're at max
    if targetHP > 75 then
        return cp >= 5
    end
    
    -- Standard finishing at 4+ CPs for medium health targets
    return cp >= 4
end

-- Enhanced stealth value calculation
function AC:CalculateStealthValue()
    if UnitAffectingCombat("player") then return 0 end
    
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target")
    local targetHP = hasTarget and self:GetTargetHealthPercent("target") or 0
    local playerHP = self:GetPlayerHealthPercent()
    local spec = self:GetPlayerSpec()
    
    local value = 0
    
    -- High value if we have a fresh target
    if hasTarget and targetHP > 90 then
        value = value + 50
    end
    
    -- Value increases if we're low on health (escape option)
    if playerHP < 50 then
        value = value + (50 - playerHP)
    end
    
    -- Subtlety gets more value from stealth
    if spec == "Subtlety" then
        value = value + 20
    end
    
    return value
end

-- Check if we should use AoE based on improved enemy detection
function AC:ShouldUseRogueAoE()
    local enemies = self:GetEnemyCount()
    local energy = UnitPower("player", 3)
    local level = UnitLevel("player")
    
    -- Need Fan of Knives
    if level < 66 then return false end
    
    -- Need enough energy
    if energy < 50 then return false end
    
    -- Conservative AoE - only use with 3+ enemies
    if enemies >= 3 then
        return true
    end
    
    -- In dungeons, be slightly more aggressive
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType == "party" and enemies >= 2 then
        return true
    end
    
    return false
end

-- Poison priority system
function AC:GetOptimalPoisonForWeapon(weaponSlot, spec)
    -- Main hand weapon slot = 16, Off hand = 17
    
    if spec == "Assassination" then
        if weaponSlot == 16 then
            return "Deadly Poison" -- Main hand gets deadly for assassination
        else
            return "Instant Poison" -- Off hand gets instant
        end
    else
        return "Instant Poison" -- Other specs prefer instant
    end
end

-- Calculate energy regeneration time
function AC:TimeToEnergy(targetEnergy)
    local currentEnergy = UnitPower("player", 3)
    local maxEnergy = UnitPowerMax("player", 3)
    
    if currentEnergy >= targetEnergy then
        return 0
    end
    
    local energyNeeded = math.min(targetEnergy, maxEnergy) - currentEnergy
    local regenRate = 10 -- Base energy regen per second
    
    -- Factor in any haste or energy regen bonuses
    if self:HasBuff("player", "Adrenaline Rush") then
        regenRate = regenRate * 2 -- Adrenaline Rush doubles energy regen
    end
    
    return energyNeeded / regenRate
end

-- Check if we should pool energy
function AC:ShouldPoolEnergy(spec, nextAbility)
    local energy = UnitPower("player", 3)
    local threshold = self:GetOptimalEnergyThreshold(spec, nextAbility)
    local timeToThreshold = self:TimeToEnergy(threshold)
    
    -- Don't pool if we're at the threshold
    if energy >= threshold then
        return false
    end
    
    -- Don't pool if it will take too long
    if timeToThreshold > 3 then
        return false
    end
    
    -- Pool if we're close to the threshold
    return timeToThreshold <= 1.5
end

-- =============================================
-- PROFESSION ABILITIES
-- =============================================

-- Use Lifeblood (Herbalism profession ability)
function AC:UseLifeblood(threshold)
    threshold = threshold or 50  -- Default to 50% health
    
    if self:GetPlayerHealthPercent() < threshold then
        -- Check if player has herbalism and the Lifeblood ability
        if self:KnowsSpell("Lifeblood") and self:IsUsableSpell("Lifeblood") and
           self:GetSpellCooldown("Lifeblood") == 0 then
            if self:ActionThrottle("Lifeblood", 2) then
                if self:CastSpell("Lifeblood", "player") then
                    if self.debugMode then
                        self:Debug("Using Lifeblood at " .. string.format("%.1f", self:GetPlayerHealthPercent()) .. "% health")
                    end
                    return true
                end
            end
        end
    end
    return false
end

-- =============================================
-- COMBAT STATE ANALYSIS
-- =============================================

-- Analyze current combat situation
function AC:AnalyzeCombatSituation()
    local situation = {
        inCombat = UnitAffectingCombat("player"),
        hasTarget = UnitExists("target") and UnitCanAttack("player", "target"),
        health = self:GetPlayerHealthPercent(),
        energy = UnitPower("player", 3),
        comboPoints = GetComboPoints("player", "target"),
        enemies = self:GetEnemyCount(),
        inGroup = IsInGroup(),
        inStealth = self:HasBuff("player", "Stealth"),
        targetHealth = self:GetTargetHealthPercent("target"),
        inMelee = CheckInteractDistance("target", 3),
        behind = self:IsBehindTarget(),
        spec = self:GetPlayerSpec(),
        level = UnitLevel("player")
    }
    
    -- Add threat assessment
    situation.highThreat = situation.health < 30
    situation.mediumThreat = situation.health < 60
    
    -- Add opportunity assessment
    situation.goodOpener = not situation.inCombat and situation.hasTarget and situation.targetHealth > 80
    situation.shouldFinish = situation.comboPoints >= 4 or (situation.comboPoints >= 1 and situation.targetHealth < 25)
    situation.shouldBuild = situation.energy >= 50 and situation.comboPoints < 5
    
    return situation
end
