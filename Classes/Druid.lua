-- AzeroCombat: Druid Rotations (IMPROVED - Research-Based WotLK 3.3.5a)
-- Optimized based on actual WotLK 3.3.5a guide research for AzerothCore
local AddonName, AC = ...

local S = { -- Spells
    -- Balance (Research-Based Priorities)
    Moonfire = "Moonfire", 
    Starfire = "Starfire", 
    Wrath = "Wrath", 
    InsectSwarm = "Insect Swarm",
    Starfall = "Starfall", 
    ForceOfNature = "Force of Nature", 
    Typhoon = "Typhoon",
    MoonkinForm = "Moonkin Form", 
    Hurricane = "Hurricane", 
    FaerieFireBalance = "Faerie Fire",

    -- Feral DPS (Cat) - Research Priority Order
    CatForm = "Cat Form", 
    FerociousBite = "Ferocious Bite", 
    Shred = "Shred", 
    Rake = "Rake", 
    Rip = "Rip",
    MangleCat = "Mangle (Cat)", 
    Cower = "Cower", 
    TigersFury = "Tiger's Fury", 
    Prowl = "Prowl",
    SavageRoar = "Savage Roar", 
    Berserk = "Berserk", 
    Claw = "Claw", 
    Pounce = "Pounce", 
    Ravage = "Ravage",
    SwipeCat = "Swipe (Cat)",
    FeralChargeCat = "Feral Charge - Cat",

    -- Feral Tank (Bear)
    BearForm = "Bear Form", 
    DireBearForm = "Dire Bear Form", 
    Maul = "Maul", 
    SwipeBear = "Swipe (Bear)",
    FaerieFireFeral = "Faerie Fire (Feral)", 
    Growl = "Growl", 
    DemoralizingRoar = "Demoralizing Roar",
    ChallengingRoar = "Challenging Roar", 
    Enrage = "Enrage", 
    Bash = "Bash",
    FrenziedRegeneration = "Frenzied Regeneration", 
    SurvivalInstincts = "Survival Instincts",
    Lacerate = "Lacerate", 
    MangleBear = "Mangle (Bear)",

    -- Restoration
    TreeOfLife = "Tree of Life", 
    Rejuvenation = "Rejuvenation", 
    Regrowth = "Regrowth",
    Lifebloom = "Lifebloom", 
    HealingTouch = "Healing Touch", 
    Nourish = "Nourish",
    Tranquility = "Tranquility", 
    Swiftmend = "Swiftmend", 
    WildGrowth = "Wild Growth",
    NaturesSwiftness = "Nature's Swiftness",

    -- Utility & Misc
    RemoveCurse = "Remove Curse", 
    AbolishPoison = "Abolish Poison", 
    Innervate = "Innervate",
    Barkskin = "Barkskin", 
    Hibernate = "Hibernate", 
    Rebirth = "Rebirth", 
    Cyclone = "Cyclone",
    EntanglingRoots = "Entangling Roots", 
    Dash = "Dash",
    NaturesGrasp = "Nature's Grasp",

    -- Buffs
    MarkOfTheWild = "Mark of the Wild", 
    Thorns = "Thorns", 
    GiftOfTheWild = "Gift of the Wild",

    -- Travel Forms
    TravelForm = "Travel Form", 
    AquaticForm = "Aquatic Form", 
    FlightForm = "Flight Form", 
    SwiftFlightForm = "Swift Flight Form",

    -- Procs / Special States (Research-Based)
    OmenOfClarityBuff = "Clearcasting",
    EclipseLunarBuff = "Eclipse (Lunar)",
    EclipseSolarBuff = "Eclipse (Solar)",
    PredatorsSwiftnessBuff = "Predator's Swiftness",
    
    -- Racial Abilities
    WarStomp = "War Stomp",
    Shadowmeld = "Shadowmeld",
    Berserking = "Berserking",
    WillOfTheForsaken = "Will of the Forsaken",
    BloodFury = "Blood Fury",
    Stoneform = "Stoneform",
    EscapeArtist = "Escape Artist",
    GiftOfTheNaaru = "Gift of the Naaru",
    ArcaneTorrent = "Arcane Torrent",
    EveryManForHimself = "Every Man for Himself",
    
    -- Additional important procs
    NaturesGrace = "Nature's Grace",
    PredatorsSwiftness = "Predator's Swiftness",
    
    -- Group buffs
    PowerWordFortitude = "Power Word: Fortitude",
    ArcaneIntellect = "Arcane Intellect",
    BlessingOfKings = "Blessing of Kings",
    BlessingOfMight = "Blessing of Might",
}

-- Debug function
local function DruidDebug(msg)
    if AC.debugMode then
        AC:Debug("|cFFFF7D0ADruid:|r " .. tostring(msg))
    end
end

-- Bear Swipe starts with a strict melee/nameplate count, then falls back to the
-- broader enemy counter only when it clearly sees a larger engaged pack.
-- This keeps small pulls conservative while fixing missing 3+ dungeon packs.
function AC:GetBearThreatEnemyCount()
    if not self:Throttle("BearThreatEnemyCountMain", 0.5) then
        return self.lastBearThreatEnemyCount or 1
    end

    local count = 0
    local processedGUIDs = {}
    local detailedDebug = self.debugMode and self:Throttle("BearThreatEnemyCountDebug", 3.0)

    if detailedDebug then
        self:Debug("=== BEAR ENEMY COUNT START ===")
    end

    local function countUnit(unit, label)
        if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDead(unit) then
            return
        end

        local guid = UnitGUID(unit)
        if not guid or processedGUIDs[guid] then
            return
        end

        count = count + 1
        processedGUIDs[guid] = true
        if detailedDebug then
            self:Debug(label .. ": " .. (UnitName(unit) or "Unknown"))
        end
    end

    countUnit("target", "Target")
    countUnit("focus", "Focus")
    countUnit("targettarget", "TargetTarget")
    countUnit("mouseover", "Mouseover")

    if UnitExists("pet") then
        countUnit("pettarget", "Pet target")
    end

    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            local guid = UnitGUID(unit)
            if guid and not processedGUIDs[guid] and CheckInteractDistance(unit, 3) then
                count = count + 1
                processedGUIDs[guid] = true
                if detailedDebug then
                    self:Debug("Nearby nameplate: " .. (UnitName(unit) or "Unknown"))
                end
            end
        end
    end

    -- If the strict melee/nameplate count misses a clearly engaged 3+ pack,
    -- fall back to the broader shared enemy counter so missing nameplates do
    -- not suppress Swipe in dungeons.
    if count < 3 and UnitAffectingCombat("player") and self.GetEnemyCount then
        local broadCount = self:GetEnemyCount(nil, true) or 0
        if broadCount >= 3 and broadCount > count then
            count = broadCount
        end
    end

    -- Combat-log entries do not expose range by GUID, so do not use them for
    -- Bear Swipe decisions unless the broader fallback above is already seeing
    -- a larger engaged pack.
    local combatLogCount = 0

    count = math.min(count, 10)
    self.lastBearThreatEnemyCount = count

    if detailedDebug then
        self:Debug("=== BEAR ENEMY COUNT SUMMARY ===")
        self:Debug("Total enemies: " .. count)
        self:Debug("Combat log enemies: " .. combatLogCount)
        self:Debug("Should use AoE: " .. (count >= 3 and "YES" or "NO"))
        self:Debug("===============================")
    end

    return count
end

local function NormalizeFeralRole(role)
    if not role then return "auto" end
    role = string.lower(tostring(role))
    if role == "bear" or role == "cat" or role == "auto" then
        return role
    end
    return "auto"
end

function AC:HasTalentByName(talentName, cacheKey)
    if not talentName then return false end

    self.druidTalentCache = self.druidTalentCache or {}
    local key = cacheKey or talentName
    local now = GetTime()
    local cached = self.druidTalentCache[key]
    if cached and (now - cached.time) < 5 then
        return cached.value
    end

    local success, numTabs = pcall(GetNumTalentTabs)
    local found = false
    if success then
        for tab = 1, numTabs do
            local tabSuccess, numTalents = pcall(GetNumTalents, tab)
            if tabSuccess then
                for talent = 1, numTalents do
                    local talentSuccess, name, _, _, _, currRank = pcall(GetTalentInfo, tab, talent)
                    if talentSuccess and name and name:find(talentName, 1, true) and currRank > 0 then
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end
    end

    self.druidTalentCache[key] = {
        time = now,
        value = found
    }
    return found
end

AC.DruidHasTalentByName = AC.HasTalentByName

function AC:GetFeralTalentPoints()
    local success, numTabs = pcall(GetNumTalentTabs)
    if not success then return 0 end

    for tab = 1, numTabs do
        local tabSuccess, tabName, _, points = pcall(GetTalentTabInfo, tab)
        if tabSuccess and tabName and tabName:find("Feral", 1, true) then
            return points or 0
        end
    end

    return 0
end

function AC:IsFeralBuild()
    local spec = self:GetPlayerSpec()
    return spec == "Feral" or self:GetFeralTalentPoints() > 0
end

function AC:GetFeralRolePreference()
    if not self.db or not self.db.profile then
        return "auto"
    end
    return NormalizeFeralRole(self.db.profile.feralRoleMode)
end

function AC:SetFeralRolePreference(role)
    role = NormalizeFeralRole(role)
    if self.db and self.db.profile then
        self.db.profile.feralRoleMode = role
    end
    if self.druidFeralCombatRole then
        self.druidFeralCombatRole = nil
    end
    return role
end

function AC:DetermineFeralRole()
    local preferred = self:GetFeralRolePreference()
    if preferred ~= "auto" then
        if preferred == "cat" and not self:KnowsSpell(S.CatForm) then
            return "bear"
        end
        return preferred
    end

    -- Leveling safety: if Cat Form is not learned yet, the feral build must play as bear.
    if not self:KnowsSpell(S.CatForm) then
        return "bear"
    end

    if UnitAffectingCombat("player") and self.druidFeralCombatRole then
        return self.druidFeralCombatRole
    end

    local bearScore = 0
    local catScore = 0

    -- Bear-leaning talents
    if self:DruidHasTalentByName("Feral Instinct", "Druid_FeralInstinct") then bearScore = bearScore + 4 end
    if self:DruidHasTalentByName("Thick Hide", "Druid_ThickHide") then bearScore = bearScore + 4 end
    if self:DruidHasTalentByName("Survival of the Fittest", "Druid_SOTF") then bearScore = bearScore + 5 end
    if self:DruidHasTalentByName("Protector of the Pack", "Druid_POTP") then bearScore = bearScore + 5 end
    if self:DruidHasTalentByName("Natural Reaction", "Druid_NaturalReaction") then bearScore = bearScore + 3 end
    if self:DruidHasTalentByName("Infected Wounds", "Druid_InfectedWounds") then bearScore = bearScore + 2 end
    if self:DruidHasTalentByName("Survival Instincts", "Druid_SurvivalInstincts") then bearScore = bearScore + 2 end

    -- Cat-leaning talents
    if self:DruidHasTalentByName("Ferocity", "Druid_Ferocity") then catScore = catScore + 4 end
    if self:DruidHasTalentByName("Feral Aggression", "Druid_FeralAggression") then catScore = catScore + 3 end
    if self:DruidHasTalentByName("Predatory Strikes", "Druid_PredatoryStrikes") then catScore = catScore + 4 end
    if self:DruidHasTalentByName("King of the Jungle", "Druid_KingOfTheJungle") then catScore = catScore + 5 end
    if self:DruidHasTalentByName("Improved Mangle", "Druid_ImprovedMangle") then catScore = catScore + 3 end
    if self:DruidHasTalentByName("Primal Precision", "Druid_PrimalPrecision") then catScore = catScore + 3 end
    if self:DruidHasTalentByName("Master Shapeshifter", "Druid_MasterShapeshifter") then catScore = catScore + 2 end
    if self:DruidHasTalentByName("Predatory Instincts", "Druid_PredatoryInstincts") then catScore = catScore + 2 end
    if self:DruidHasTalentByName("Shredding Attacks", "Druid_ShreddingAttacks") then catScore = catScore + 1 end

    local currentForm = self:GetCurrentDruidForm()
    if currentForm == AC.DruidForms.BEAR then
        bearScore = bearScore + 1
    elseif currentForm == AC.DruidForms.CAT then
        catScore = catScore + 1
    end

    if bearScore > catScore then
        return "bear"
    elseif catScore > bearScore then
        return "cat"
    end

    if self:IsTank("player") then
        return "bear"
    end

    return currentForm == AC.DruidForms.BEAR and "bear" or "cat"
end

local function IsHealingSpellInRange(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsUnit(unit, "player") then return true end

    local rangeSpells = {
        S.Nourish,
        S.Rejuvenation,
        S.Regrowth,
        S.HealingTouch,
        S.Lifebloom,
    }

    for _, spellName in ipairs(rangeSpells) do
        if AC:KnowsSpell(spellName) then
            local inRange = IsSpellInRange(spellName, unit)
            if inRange == 1 then
                return true
            elseif inRange == 0 then
                return false
            end
        end
    end

    -- Fall back to interaction distance if spell range cannot be queried.
    return CheckInteractDistance(unit, 4)
end

-- Throttle helper
local throttleTimes = {}
local function Throttle(key, interval)
    if not throttleTimes[key] or (GetTime() - throttleTimes[key] > interval) then
        throttleTimes[key] = GetTime()
        return true
    end
    return false
end

-- WotLK 3.3.5a-compatible group check (IsInParty is not available in WotLK)
local function IsDruidInGroup()
    return (GetNumRaidMembers and GetNumRaidMembers() > 0) or
           (GetNumPartyMembers and GetNumPartyMembers() > 0)
end

-- =============================================
-- RESEARCH-BASED FORM MANAGEMENT
-- =============================================

AC.DruidForms = {
    CASTER = 0, BEAR = 1, AQUATIC = 2, CAT = 3, TRAVEL = 4, 
    MOONKIN = 5, FLIGHT = 6, TREE = 7, SWIFT_FLIGHT = 8
}

function AC:GetCurrentDruidForm()
    if self:HasBuff("player", S.MoonkinForm) then return AC.DruidForms.MOONKIN end
    if self:HasBuff("player", S.TreeOfLife) then return AC.DruidForms.TREE end
    if self:HasBuff("player", S.CatForm) then return AC.DruidForms.CAT end
    if self:HasBuff("player", S.BearForm) or self:HasBuff("player", S.DireBearForm) then return AC.DruidForms.BEAR end
    if self:HasBuff("player", S.TravelForm) then return AC.DruidForms.TRAVEL end
    if self:HasBuff("player", S.AquaticForm) then return AC.DruidForms.AQUATIC end
    if self:HasBuff("player", S.FlightForm) then return AC.DruidForms.FLIGHT end
    if self:HasBuff("player", S.SwiftFlightForm) then return AC.DruidForms.SWIFT_FLIGHT end
    return AC.DruidForms.CASTER
end

function AC:ShiftToForm(targetFormSpell)
    if not targetFormSpell then return false end
    
    -- Special handling for shifting to caster form
    if targetFormSpell == "Caster" then
        local currentForm = GetShapeshiftForm()
        if currentForm ~= 0 then
            CancelShapeshiftForm()
            DruidDebug("Shifting to Caster form")
            return true
        end
        return false
    end

    if not self:KnowsSpell(targetFormSpell) then return false end
    
    -- Check if already in the target form
    if self:HasBuff("player", targetFormSpell) then return false end
    
    -- Use the spell if it's usable
    if self:IsUsableSpell(targetFormSpell) and self:GetSpellCooldown(targetFormSpell) == 0 then
        if not self:CastSpell(targetFormSpell, "player") then return false end
        DruidDebug("Shifting to " .. targetFormSpell)
        return true
    end

    return false
end

-- =============================================
-- RESEARCH-BASED RESOURCE HELPERS
-- =============================================

function AC:HasOmenOfClarity() 
    return self:HasBuff("player", S.OmenOfClarityBuff) 
end

function AC:GetComboPoints() 
    return GetComboPoints("player", "target") 
end

-- RESEARCH-BASED: Check if we're behind target (for Shred priority)
function AC:IsBehindTarget()
    if not UnitExists("target") then return false end
    -- There is no reliable stock 3.3.5 API for behind checks.
    -- Use Shred usability as a practical WotLK-safe proxy for "behind enough".
    if not self:IsInMeleeRange("target") then return false end
    return self:IsUsableSpell(S.Shred)
end

AC.DruidIsBehindTarget = AC.IsBehindTarget

-- RESEARCH-BASED: Fast dying mob check (affects DoT application)
function AC:IsFastDyingMob(unit)
    if not unit or not UnitExists(unit) then return false end
    local hp = UnitHealth(unit)
    local maxHp = UnitHealthMax(unit)
    local hpPercent = (hp / maxHp) * 100
    
    -- Research shows: Don't apply DoTs to targets below 25% or very low HP
    return hpPercent < 25 or hp < 10000
end

AC.DruidIsFastDyingMob = AC.IsFastDyingMob

-- RESEARCH-BASED: In melee range check
function AC:IsInMeleeRange(unit)
    if not unit or not UnitExists(unit) then return false end
    return CheckInteractDistance(unit, 3)
end

function AC:IsEatingOrDrinking()
    local channel = UnitChannelInfo("player")
    local cast = UnitCastingInfo("player")
    local action = channel or cast
    if not action then return false end

    local lowerAction = string.lower(action)
    return lowerAction:find("drink", 1, true) or
           lowerAction:find("eat", 1, true) or
           lowerAction:find("food", 1, true) or
           lowerAction:find("refreshment", 1, true) or
           lowerAction:find("well fed", 1, true)
end

-- =============================================
-- RESEARCH-BASED DEFENSIVE COOLDOWNS
-- =============================================

local CanRetryDruidConsumable
local MarkDruidConsumableAttempt
local ShouldDelayDruidConsumableRetry

function AC:UseDruidDefensives(form)
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    local enemies = self:GetEnemyCount()
    
    if not inCombat then return false end

    if not Throttle("DruidDefensives", 1.0) then return false end

    -- Emergency health potion first
    if health < 50 and self.UseHealthPotion then
        if CanRetryDruidConsumable(self, "healthPotion", 20) then
            local usedPotion, reason = self:UseHealthPotion(50)
            if usedPotion then
                MarkDruidConsumableAttempt(self, "healthPotion")
                DruidDebug("Used health potion at " .. string.format("%.0f", health) .. "% health")
                return true
            end
            if ShouldDelayDruidConsumableRetry(reason) then
                MarkDruidConsumableAttempt(self, "healthPotion")
            end
            if self.debugMode then
                DruidDebug("Druid health potion unavailable: " .. tostring(reason or "none"))
            end
        end
    end

    -- Bear-specific emergency racials act as an extra defensive layer on any-race servers.
    if form == AC.DruidForms.BEAR and self:UseRacialsDruid(false, true) then
        DruidDebug("Bear: emergency racial")
        return true
    end

    -- Barkskin (usable in all forms)
    if health < 50 and self:IsUsableSpell(S.Barkskin) then
        if not self:CastSpell(S.Barkskin, "player") then return false end
        DruidDebug("Barkskin at low health")
        return true
    end
    
    -- Bear Form specific
    if form == AC.DruidForms.BEAR then
        -- Survival Instincts
        if health < 30 and self:KnowsSpell(S.SurvivalInstincts) and self:IsUsableSpell(S.SurvivalInstincts) and self:GetSpellCooldown(S.SurvivalInstincts) == 0 then
            if not self:CastSpell(S.SurvivalInstincts, "player") then return false end
            DruidDebug("Survival Instincts")
            return true
        end
        
        -- Frenzied Regeneration
        if health < 40 and UnitPower("player", 1) > 10 and self:KnowsSpell(S.FrenziedRegeneration) and self:IsUsableSpell(S.FrenziedRegeneration) and self:GetSpellCooldown(S.FrenziedRegeneration) == 0 then
            if not self:CastSpell(S.FrenziedRegeneration, "player") then return false end
            DruidDebug("Frenzied Regeneration")
            return true
        end
    end
    
    -- Nature's Grasp if being attacked in caster
    if form == AC.DruidForms.CASTER and enemies > 0 and self:IsUsableSpell(S.NaturesGrasp) then
        if not self:CastSpell(S.NaturesGrasp, "player") then return false end
        DruidDebug("Nature's Grasp")
        return true
    end
    
    return false
end

-- =============================================
-- RESEARCH-BASED OFFENSIVE COOLDOWNS
-- =============================================

function AC:UseDruidOffensives(spec, form)
    local targetHP = self:GetTargetHealthPercent("target")
    local targetClass = UnitClassification("target")
    
    -- Don't blow CDs on trivial mobs
    if targetClass == "trivial" or targetHP < 30 then
        return false
    end
    
    -- Check if it's worth using offensive CDs
    local worthIt = targetClass == "elite" or targetClass == "rareelite" or 
                   targetClass == "worldboss" or targetHP > 70 or
                   (IsInGroup() and targetHP > 50)
    
    if not worthIt then return false end
    
    -- Balance
    if spec == "Balance" and form == AC.DruidForms.MOONKIN then
        -- RESEARCH: Force of Nature is major DPS cooldown
        if not self:IsChanneling() and not self:IsPlayerMoving() and
           self:IsUsableSpell(S.ForceOfNature) and self:GetSpellCooldown(S.ForceOfNature) == 0 and
           Throttle("ForceOfNature", 3) then
            if not self:SafeCastGroundAOE(S.ForceOfNature) then return false end
            DruidDebug("Force of Nature - burst")
            if self.UseTrinkets then self:UseTrinkets() end
            return true
        end
        
        -- RESEARCH: Starfall on cooldown outside of eclipse
        if self:IsUsableSpell(S.Starfall) and self:GetSpellCooldown(S.Starfall) == 0 and Throttle("Starfall", 90) then
            if not self:CastSpell(S.Starfall, "player") then return false end
            DruidDebug("Starfall - burst")
            return true
        end
    end
    
    -- Feral Cat
    if form == AC.DruidForms.CAT then
        -- RESEARCH: Berserk is the most powerful cooldown (15 seconds, 50% energy cost reduction)
        if self:IsUsableSpell(S.Berserk) and self:GetSpellCooldown(S.Berserk) == 0 then
            local tigersFuryCD = self:GetSpellCooldown(S.TigersFury)
            -- Use when Tiger's Fury has >15s cooldown remaining.
            if (not self:KnowsSpell(S.TigersFury) or tigersFuryCD > 15) and Throttle("Berserk", 3) then
                if not self:CastSpell(S.Berserk, "player") then return false end
                DruidDebug("Berserk - burst")
                if self.UseTrinkets then self:UseTrinkets() end
                return true
            end
        end
        
        -- RESEARCH: Tiger's Fury as controlled energy injection (avoid low-value spam attempts).
        local catEnergy = UnitPower("player", 3)
        local catCP = self:GetComboPoints()
        if catEnergy <= 30 and self:IsUsableSpell(S.TigersFury)
           and self:GetSpellCooldown(S.TigersFury) == 0 and Throttle("TigersFury", 8.0) then
            if not self:CastSpell(S.TigersFury, "player") then return false end
            DruidDebug("Tiger's Fury (energy regen)")
            return true
        end
    end
    
    return false
end

-- Dedicated low-level druid handling for characters with no talent points yet.
function AC:LevelingDruidRotation()
    local level = UnitLevel("player")
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana / maxMana * 100) or 100
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    if Throttle("LevelingDebug", 2.5) then
        DruidDebug(string.format(
            "Leveling mode: L:%d Mana:%.0f%% HP:%.0f Combat:%s Target:%s",
            level,
            manaPercent,
            health,
            inCombat and "Y" or "N",
            hasTarget and "Y" or "N"
        ))
    end

    -- Emergency self-healing always takes priority.
    if not UnitCastingInfo("player") then
        if health < 35 and self:IsUsableSpell(S.HealingTouch) then
            if not self:CastSpell(S.HealingTouch, "player") then return false end
            DruidDebug("Leveling: Healing Touch (emergency self-heal)")
            return true
        end

        if health < 70 and self:IsUsableSpell(S.Rejuvenation) and not self:HasBuff("player", S.Rejuvenation) then
            if not self:CastSpell(S.Rejuvenation, "player") then return false end
            DruidDebug("Leveling: Rejuvenation (self sustain)")
            return true
        end
    end

    if not inCombat then
        if self:CheckDruidBuffs() then return true end

        if hasTarget then
            if self:KnowsSpell(S.Moonfire) and self:IsUsableSpell(S.Moonfire) and
               self:DebuffTimeRemaining("target", S.Moonfire) < 1 and not UnitCastingInfo("player") then
                if not self:CastSpell(S.Moonfire, "target") then return false end
                DruidDebug("Leveling: Moonfire (pre-pull)")
                return true
            end

            if self:IsUsableSpell(S.Wrath) and not UnitCastingInfo("player") then
                if not self:CastSpell(S.Wrath, "target") then return false end
                DruidDebug("Leveling: Wrath (pre-pull)")
                return true
            end
        end

        if Throttle("LevelingIdle", 3.0) then
            DruidDebug("Leveling: out of combat, waiting for target or mana")
        end
        return false
    end

    if not hasTarget then
        if Throttle("LevelingNoTarget", 3.0) then
            DruidDebug("Leveling: no hostile target available")
        end
        return false
    end

    if self:KnowsSpell(S.Moonfire) and self:IsUsableSpell(S.Moonfire) and
       self:DebuffTimeRemaining("target", S.Moonfire) < 1 and not UnitCastingInfo("player") then
        if not self:CastSpell(S.Moonfire, "target") then return false end
        DruidDebug("Leveling: Moonfire")
        return true
    end

    if self:IsUsableSpell(S.Wrath) and not UnitCastingInfo("player") then
        if not self:CastSpell(S.Wrath, "target") then return false end
        DruidDebug("Leveling: Wrath")
        return true
    end

    if self:KnowsSpell(S.EntanglingRoots) and self:IsUsableSpell(S.EntanglingRoots) and
       self:GetSpellCooldown(S.EntanglingRoots) == 0 and health < 60 then
        if not self:CastSpell(S.EntanglingRoots, "target") then return false end
        DruidDebug("Leveling: Entangling Roots (peel)")
        return true
    end

    if Throttle("LevelingNoAction", 2.5) then
        DruidDebug("Leveling: no usable action this tick")
    end

    return false
end

-- =============================================
-- RESEARCH-BASED BUFF MANAGEMENT
-- =============================================

local function BuildDruidGroupUnitList()
    local units = {}
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            units[#units + 1] = "raid" .. i
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            units[#units + 1] = "party" .. i
        end
    end
    return units
end

function AC:CheckDruidBuffs()
    if not Throttle("DruidBuffsOOC", 1.5) then return false end
    local inCombat = UnitAffectingCombat("player")
    if inCombat then return false end
    if self:IsEatingOrDrinking() then return false end
    local isFeralBuild = self:IsFeralBuild()
    
    -- Group buffing first (out of combat)
    if self:CheckDruidGroupBuffs() then return true end
    
    -- Mark of the Wild (self)
    local motwSpell = self:KnowsSpell(S.GiftOfTheWild) and S.GiftOfTheWild or S.MarkOfTheWild
    if self:IsUsableSpell(motwSpell) then
        if not self:HasBuff("player", S.MarkOfTheWild) and not self:HasBuff("player", S.GiftOfTheWild) then
            if self:CastSpell(motwSpell, "player") then
                DruidDebug("Buffing: " .. motwSpell)
                return true
            elseif motwSpell == S.GiftOfTheWild and self:IsUsableSpell(S.MarkOfTheWild) and
                   self:CastSpell(S.MarkOfTheWild, "player") then
                DruidDebug("Buffing: Mark of the Wild (Gift reagent fallback)")
                return true
            end
        end
    end
    
    -- Thorns: feral build keeps this self-only; non-feral can still support the tank.
    if self:IsUsableSpell(S.Thorns) then
        if IsDruidInGroup() and not isFeralBuild then
            local groupUnits = {}
            if GetNumRaidMembers() > 0 then
                for i = 1, GetNumRaidMembers() do
                    table.insert(groupUnits, "raid" .. i)
                end
            elseif GetNumPartyMembers() > 0 then
                for i = 1, GetNumPartyMembers() do
                    table.insert(groupUnits, "party" .. i)
                end
            end
            
            -- Find tanks without thorns
            for _, unit in ipairs(groupUnits) do
                if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) and
                   CheckInteractDistance(unit, 4) and not self:HasBuff(unit, S.Thorns) and self:IsTank(unit) then
                    if not self:CastSpell(S.Thorns, unit) then return false end
                    DruidDebug("EPIC THORNS: " .. (UnitName(unit) or unit) .. " (TANK PRIORITY)")
                    return true
                end
            end
        end
        
        -- No tanks need thorns, or we are feral and only want self-buffing.
        if not self:HasBuff("player", S.Thorns) then
            if not self:CastSpell(S.Thorns, "player") then return false end
            DruidDebug(isFeralBuild and "Buffing: Thorns (self, feral only)" or "Buffing: Thorns (self)")
            return true
        end
    end
    
    return false
end

-- =============================================
-- RESEARCH-BASED BALANCE ROTATION
-- =============================================

function AC:BalanceDruidRotation()
    local currentForm = self:GetCurrentDruidForm()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local enemies = self:GetEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- RESEARCH: Moonkin form required for Balance
    if self:KnowsSpell(S.MoonkinForm) and currentForm ~= AC.DruidForms.MOONKIN then
        if self:ShiftToForm(S.MoonkinForm) then
            return true
        end
    end
    
    self.druidRotationState = self.druidRotationState or {}
    
    if not hasTarget then
        return false
    end
    
    -- Defensive cooldowns
    if self:UseDruidDefensives(currentForm) then
        return true
    end

    -- Preserve consumables by using the class mana cooldown first.
    if manaPercent < 35 and self:IsUsableSpell(S.Innervate) and
       self:GetSpellCooldown(S.Innervate) == 0 then
        if self:CastSpell(S.Innervate, "player") then
            DruidDebug("Balance: Innervate")
            return true
        end
    end
    
    -- Mana management
    if manaPercent < 30 and self.UseManaPotion and CanRetryDruidConsumable(self, "manaPotion", 15) then
        local usedPotion, reason = self:UseManaPotion(30)
        if usedPotion then
            MarkDruidConsumableAttempt(self, "manaPotion")
            DruidDebug("Used mana potion")
            return true
        end
        if ShouldDelayDruidConsumableRetry(reason) then
            MarkDruidConsumableAttempt(self, "manaPotion")
        end
        if self.debugMode then
            DruidDebug("Druid mana potion unavailable: " .. tostring(reason or "none"))
        end
    end
    
    local isFastDying = self:IsFastDyingMob("target")
    
    -- RESEARCH PRIORITY 1: Faerie Fire (Improved Faerie Fire debuff)
    if not isFastDying and self:DebuffTimeRemaining("target", S.FaerieFireBalance) < 3 and
       self:IsUsableSpell(S.FaerieFireBalance) and self:GetSpellCooldown(S.FaerieFireBalance) == 0 then
        if not self:CastSpell(S.FaerieFireBalance, "target") then return false end
        DruidDebug("Balance: Faerie Fire (Improved Faerie Fire)")
        return true
    end

    -- Offensive cooldowns after raid debuff setup.
    if self:UseDruidOffensives("Balance", currentForm) then
        return true
    end

    -- AoE rotation (3+ enemies)
    if enemies >= 3 then
        -- RESEARCH: Starfall on cooldown for AoE
        if self:IsUsableSpell(S.Starfall) and self:GetSpellCooldown(S.Starfall) == 0 and Throttle("StarfallAoe", 3) then
            if not self:CastSpell(S.Starfall, "player") then return false end
            DruidDebug("Balance: Starfall (AoE)")
            return true
        end

        -- Typhoon before committing to Hurricane's channel.
        if self:IsUsableSpell(S.Typhoon) and self:GetSpellCooldown(S.Typhoon) == 0 and self:IsInMeleeRange("target") then
            if not self:CastSpell(S.Typhoon, "player") then return false end
            DruidDebug("Balance: Typhoon")
            return true
        end

        -- Hurricane is ground-targeted; use Core.lua's standardized placement helper.
        if self:IsUsableSpell(S.Hurricane) and manaPercent > 30 and not self:IsChanneling() and not self:IsPlayerMoving() then
            if self:SafeCastGroundAOE(S.Hurricane) then
                DruidDebug("Balance: Hurricane (ground AoE)")
                return true
            end
        end
    end

    -- ENHANCED ECLIPSE MANAGEMENT WITH COMPLEXITY AWARENESS
    local complexity = self:GetRotationComplexity()
    local hasLunarEclipse = self:HasBuff("player", S.EclipseLunarBuff)
    local hasSolarEclipse = self:HasBuff("player", S.EclipseSolarBuff)

    if hasLunarEclipse then
        self.druidRotationState.lastBalanceEclipse = "lunar"
    elseif hasSolarEclipse then
        self.druidRotationState.lastBalanceEclipse = "solar"
    end

    if UnitCastingInfo("player") then
        return false
    end

    local lunarTime = hasLunarEclipse and self:BuffTimeRemaining("player", S.EclipseLunarBuff) or 0
    local solarTime = hasSolarEclipse and self:BuffTimeRemaining("player", S.EclipseSolarBuff) or 0

    -- Eclipse-buffed nukes outrank DoT refreshes in WotLK.
    if hasLunarEclipse and lunarTime > 1.5 and self:IsUsableSpell(S.Starfire) and self:GetSpellCooldown(S.Starfire) == 0 and manaPercent > 15 then
        if not self:CastSpell(S.Starfire, "target") then return false end
        DruidDebug("Balance: Starfire (Lunar Eclipse - " .. string.format("%.1f", lunarTime) .. "s left)")
        return true
    end

    if hasSolarEclipse and solarTime > 1.5 and self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 and manaPercent > 10 then
        if not self:CastSpell(S.Wrath, "target") then return false end
        DruidDebug("Balance: Wrath (Solar Eclipse - " .. string.format("%.1f", solarTime) .. "s left)")
        return true
    end
    
    local function shouldRefreshBalanceDot(debuffName)
        if not self:HasDebuff("target", debuffName) then
            return true -- Missing DoT
        end

        -- WotLK DoTs do not have Pandemic; avoid clipping active ticks.
        return self:DebuffTimeRemaining("target", debuffName) < 0.5
    end

    if not isFastDying then
        -- Maintain Moonfire between Eclipse windows; it also remains the movement filler.
        if (self:IsPlayerMoving() or (not hasLunarEclipse and not hasSolarEclipse)) and
           shouldRefreshBalanceDot(S.Moonfire) and self:IsUsableSpell(S.Moonfire) and
           self:GetSpellCooldown(S.Moonfire) == 0 then
            if not self:CastSpell(S.Moonfire, "target") then return false end
            DruidDebug("Balance: Moonfire")
            return true
        end

        -- RESEARCH: Insect Swarm unless Lunar Eclipse is active.
        if not hasLunarEclipse and shouldRefreshBalanceDot(S.InsectSwarm) and self:IsUsableSpell(S.InsectSwarm) and self:GetSpellCooldown(S.InsectSwarm) == 0 then
            if not self:CastSpell(S.InsectSwarm, "target") then return false end
            DruidDebug("Balance: Insect Swarm")
            return true
        end
    end

    -- Advanced Eclipse tracking with duration awareness
    if complexity == "ADVANCED" or complexity == "MODERATE" then
        -- Alternate builders based on the last Eclipse we consumed.
        local preferWrath = self.druidRotationState.lastBalanceEclipse ~= "lunar"

        if preferWrath and self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 and manaPercent > 10 then
            if not self:CastSpell(S.Wrath, "target") then return false end
            DruidDebug("Balance: Wrath (building to Lunar Eclipse)")
            return true
        elseif self:IsUsableSpell(S.Starfire) and self:GetSpellCooldown(S.Starfire) == 0 and manaPercent > 20 then
            if not self:CastSpell(S.Starfire, "target") then return false end
            DruidDebug("Balance: Starfire (building to Solar Eclipse)")
            return true
        end
    else
        -- Simple Eclipse handling for basic rotations
        if hasLunarEclipse and self:IsUsableSpell(S.Starfire) and self:GetSpellCooldown(S.Starfire) == 0 and manaPercent > 15 then
            if not self:CastSpell(S.Starfire, "target") then return false end
            DruidDebug("Balance: Starfire (Lunar Eclipse)")
            return true
        end
        
        if hasSolarEclipse and self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 and manaPercent > 10 then
            if not self:CastSpell(S.Wrath, "target") then return false end
            DruidDebug("Balance: Wrath (Solar Eclipse)")
            return true
        end
        
        -- Default to Wrath for building
        if self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 and manaPercent > 10 then
            if not self:CastSpell(S.Wrath, "target") then return false end
            DruidDebug("Balance: Wrath (building)")
            return true
        end
    end
    return false
end

-- =============================================
-- RESEARCH-BASED FERAL CAT DPS ROTATION
-- =============================================

function AC:FeralCatDpsRotation()
    local currentForm = self:GetCurrentDruidForm()
    local energy = UnitPower("player", 3)
    local cp = self:GetComboPoints()
    local enemies = self:GetEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- Shift to Cat if not already
    if currentForm ~= AC.DruidForms.CAT then
        if self:ShiftToForm(S.CatForm) then return true end
        if not self:KnowsSpell(S.CatForm) then return self:LevelingDruidRotation() end
    end
    
    if not hasTarget then return false end
    
    -- Start auto-attack
    StartAttack()
    
    -- Defensive cooldowns
    if self:UseDruidDefensives(currentForm) then return true end
    
    local targetHP = self:GetTargetHealthPercent("target")
    local isFastDying = self:IsFastDyingMob("target")
    local hasOOC = self:HasOmenOfClarity()

    -- Offensive cooldowns are top priority for Cat when the target is worth it.
    if self:UseDruidOffensives("Feral", currentForm) then return true end

    -- Omen of Clarity should be spent on Shred when position allows.
    if hasOOC and cp < 5 and self:IsUsableSpell(S.Shred) then
        if not self:CastSpell(S.Shred, "target") then return false end
        DruidDebug("Cat: Shred (Clearcasting)")
        return true
    end
    
    -- RESEARCH PRIORITY 1: Faerie Fire (Feral) - armor reduction
    if not isFastDying and self:DebuffTimeRemaining("target", S.FaerieFireFeral) < 5 and
       self:IsUsableSpell(S.FaerieFireFeral)
       and self:GetSpellCooldown(S.FaerieFireFeral) == 0 and not hasOOC and Throttle("CatFaerieFire", 0.8) then
        if not self:CastSpell(S.FaerieFireFeral, "target") then return false end
        DruidDebug("Cat: Faerie Fire (armor reduction)")
        return true
    end

    -- Savage Roar should be refreshed only as it falls off.
    local srTime = self:BuffTimeRemaining("player", S.SavageRoar)

    if srTime < 1.0 and cp >= 1 and energy >= 25 and self:IsUsableSpell(S.SavageRoar)
       and self:GetSpellCooldown(S.SavageRoar) == 0 and Throttle("CatSavageRoar", 0.8) then
        if not self:CastSpell(S.SavageRoar, "player") then return false end
        DruidDebug("Cat: Savage Roar (" .. cp .. "CP)")
        return true
    end

    -- Mangle/Trauma must be present before applying or refreshing bleeds.
    local mangleTime = math.max(
        self:DebuffTimeRemaining("target", "Mangle"),
        self:DebuffTimeRemaining("target", S.MangleCat),
        self:DebuffTimeRemaining("target", S.MangleBear),
        self:DebuffTimeRemaining("target", "Trauma")
    )
    if enemies < 3 and mangleTime < 3 and self:IsUsableSpell(S.MangleCat) and
       Throttle("CatMangleDebuff", 0.5) then
        if self:CastSpell(S.MangleCat, "target") then
            DruidDebug("Cat: Mangle (bleed amplification)")
            return true
        end
    end

    -- AoE rotation: keep Savage Roar first, then Swipe.
    if enemies >= 3 and srTime > 1.0 then
        if self:IsUsableSpell(S.SwipeCat) and energy >= (hasOOC and 0 or 45) then
            if not self:CastSpell(S.SwipeCat, "target") then return false end
            DruidDebug("Cat: Swipe (AoE)")
            return true
        end
    end

    -- 2-target cleave: keep ST maintenance, then use Swipe as filler.
    if enemies == 2 and cp < 5 and self:IsUsableSpell(S.SwipeCat) and energy >= (hasOOC and 0 or 45) then
        local rakeTimeCleave = self:DebuffTimeRemaining("target", S.Rake)
        if srTime > 6 and rakeTimeCleave > 1 then
            if not self:CastSpell(S.SwipeCat, "target") then return false end
            DruidDebug("Cat: Swipe (2-target cleave filler)")
            return true
        end
    end
    
    -- Rip: WotLK has no Pandemic, so do not clip active ticks.
    if cp >= 5 and not isFastDying and targetHP > 25 then
        local ripTime = self:DebuffTimeRemaining("target", S.Rip)
        local ripCost = hasOOC and 0 or 30

        if ripTime < 0.5 and energy >= ripCost and self:IsUsableSpell(S.Rip) then
            if not self:CastSpell(S.Rip, "target") then return false end
            DruidDebug("Cat: Rip (5CP)")
            return true
        end
    end
    
    -- RESEARCH PRIORITY 4: Ferocious Bite (5 CP, when DoTs/SR are maintained)
    if cp >= 5 and energy >= 35 and self:IsUsableSpell(S.FerociousBite) then
        local srTime = self:BuffTimeRemaining("player", S.SavageRoar)
        local ripTime = self:DebuffTimeRemaining("target", S.Rip)
        
        -- Use FB if target is dying OR only with very healthy SR/Rip windows.
        if isFastDying or targetHP < 25 or (energy >= 55 and srTime > 10 and ripTime > 10) then
            if not self:CastSpell(S.FerociousBite, "target") then return false end
            DruidDebug("Cat: Ferocious Bite (5CP)")
            return true
        end
    end
    
    -- Rake: WotLK has no Pandemic, so do not clip active ticks.
    local rakeTime = self:DebuffTimeRemaining("target", S.Rake)
    local rakeCost = hasOOC and 0 or 35
    
    if not isFastDying and energy >= rakeCost then
        if rakeTime < 0.5 and self:IsUsableSpell(S.Rake) then
            if not self:CastSpell(S.Rake, "target") then return false end
            DruidDebug("Cat: Rake")
            return true
        end
    end
    
    -- RESEARCH PRIORITY 7: Build combo points (CP generation)
    if cp < 5 then
        -- RESEARCH: Shred if available (usability handles positional constraints in WotLK).
        if self:IsUsableSpell(S.Shred) then
            if not self:CastSpell(S.Shred, "target") then return false end
            DruidDebug("Cat: Shred (CP builder)")
            return true
        end
        
        -- RESEARCH: Mangle if not behind (positioning-independent)
        if self:IsUsableSpell(S.MangleCat) then
            if not self:CastSpell(S.MangleCat, "target") then return false end
            DruidDebug("Cat: Mangle (CP builder)")
            return true
        elseif self:IsUsableSpell(S.Claw) then
            if not self:CastSpell(S.Claw, "target") then return false end
            DruidDebug("Cat: Claw (CP builder fallback)")
            return true
        end
    end
    
    -- Final 5CP anti-idle fallback: only bite when finishers are healthy.
    if cp == 5 and energy >= 60 and self:IsUsableSpell(S.FerociousBite) then
        local srTimeFinal = self:BuffTimeRemaining("player", S.SavageRoar)
        local ripTimeFinal = self:DebuffTimeRemaining("target", S.Rip)
        if srTimeFinal > 12 and ripTimeFinal > 12 then
            if not self:CastSpell(S.FerociousBite, "target") then return false end
            DruidDebug("Cat: Ferocious Bite (5CP final fallback)")
            return true
        end
    end

    return false
end

-- =============================================
-- RESEARCH-BASED FERAL BEAR TANK ROTATION
-- =============================================

local function GetBearMaulThreshold(level, enemies)
    if enemies >= 3 then
        return 45
    end

    if level < 20 then
        return 14
    end

    -- Low-level bear has very few rage spenders, so let Maul come online as soon
    -- as it is available and only ramp the threshold slowly with level.
    return math.min(35, 10 + math.floor((level - 20) / 2))
end

local function GetBearSwipeThreshold(level)
    return 15
end

local function GetDemoralizingDebuffTimeRemaining(ac, unit)
    if not ac then return 0 end

    local roarTime = ac:DebuffTimeRemaining(unit, S.DemoralizingRoar)
    local shoutTime = ac:DebuffTimeRemaining(unit, "Demoralizing Shout")

    if roarTime > 0 then
        return roarTime
    end

    if shoutTime > 0 then
        return shoutTime
    end

    return 0
end

CanRetryDruidConsumable = function(ac, key, retryAfter)
    if not ac then return false end

    ac.druidConsumableAttempts = ac.druidConsumableAttempts or {}
    local lastAttempt = ac.druidConsumableAttempts[key]
    if not lastAttempt then
        return true
    end

    return (GetTime() - lastAttempt) >= (retryAfter or 10)
end

MarkDruidConsumableAttempt = function(ac, key)
    if not ac then return end

    ac.druidConsumableAttempts = ac.druidConsumableAttempts or {}
    ac.druidConsumableAttempts[key] = GetTime()
end

ShouldDelayDruidConsumableRetry = function(reason)
    return reason == "attempted" or reason == "gcd" or reason == "locked" or
           reason == "blocked" or reason == "cooldown"
end

function AC:FeralBearTankRotation()
    -- Initialize threat tracking variables
    self.expectedThreatTargets = self.expectedThreatTargets or {}
    self.lastTauntTime = self.lastTauntTime or 0
    self.lastTauntTarget = self.lastTauntTarget or ""
    
    local currentForm = self:GetCurrentDruidForm()
    local level = UnitLevel("player")
    local rage = UnitPower("player", 1)
    local health = self:GetPlayerHealthPercent()
    local enemies = self:GetBearThreatEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local autoTauntAllowed = self:IsAutoTauntAllowed()
    local now = GetTime()
    local inCombat = UnitAffectingCombat("player")

    if inCombat and not self.druidBearWasInCombat then
        self.druidBearCombatStart = now
    elseif not inCombat then
        self.druidBearCombatStart = nil
    end
    self.druidBearWasInCombat = inCombat
    local bearCombatElapsed = self.druidBearCombatStart and (now - self.druidBearCombatStart) or 0
    
    -- Shift to Bear if not already
    local bearForm = self:KnowsSpell(S.DireBearForm) and S.DireBearForm or S.BearForm
    if currentForm ~= AC.DruidForms.BEAR then
        if self:ShiftToForm(bearForm) then return true end
    end
    
    -- Defensive cooldowns
    if self:UseDruidDefensives(currentForm) then return true end

    if self:HandleTankTargeting() then return true end

    hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    if hasTarget and not IsCurrentSpell("Attack") then
        StartAttack()
    end

    if not hasTarget then return false end

    -- Queue Maul proactively since it is an on-next-swing attack, not a normal GCD spender.
    if self:IsUsableSpell(S.Maul) and not IsCurrentSpell(S.Maul) then
        local shouldQueueMaul = rage >= GetBearMaulThreshold(level, enemies)
        if shouldQueueMaul then
            if self:CastSpell(S.Maul, "target") then
                DruidDebug("Bear: Queued Maul")
            end
        end
    end
    
    -- Combat rebuffs are disabled to avoid dropping out of Bear Form.
    
    -- Interrupt with Bash
    if (UnitCastingInfo("target") or UnitChannelInfo("target")) and
       self:IsUsableSpell(S.Bash) and self:GetSpellCooldown(S.Bash) == 0 and rage >= 10 then
        if not self:CastSpell(S.Bash, "target") then return false end
        DruidDebug("Bear: Bash interrupt")
        return true
    end
    
    -- Enrage is best as opener rage; avoid repeated in-fight armor-penalty usage.
    if bearCombatElapsed < 3 and rage < 20 and health > 80 and self:IsUsableSpell(S.Enrage)
       and self:GetSpellCooldown(S.Enrage) == 0 then
        if not self:CastSpell(S.Enrage, "player") then return false end
        DruidDebug("Bear: Enrage (opener rage)")
        return true
    end
    
    -- EPIC THREAT: Berserk with trinkets for maximum threat
    if self:IsUsableSpell(S.Berserk) and self:GetSpellCooldown(S.Berserk) == 0 then
        local targetClass = UnitClassification("target")
        local targetHealth = UnitHealth("target") or 0
        
        -- EPIC CONDITIONS: Use on elite/boss targets or AoE situations
        if targetClass == "elite" or targetClass == "rareelite" or targetClass == "worldboss" or 
           enemies >= 3 or (targetHealth > 100000 and IsInGroup()) then
            if Throttle("BerserkBear", 3) then
                if not self:CastSpell(S.Berserk, "player") then return false end
                DruidDebug("EPIC BERSERK: Maximum threat mode")

                -- Use trinkets with Berserk for maximum threat
                if self.UseTrinkets then self:UseTrinkets() end

                -- Use offensive racials
                if self:UseRacialsDruid(true, false) then
                    DruidDebug("EPIC BERSERK: Used racial with Berserk")
                end

                return true
            end
        end
    end

    local hasBerserk = self:HasBuff("player", S.Berserk)

    -- During Berserk, Mangle is the highest-value AoE threat button.
    if hasBerserk and self:IsUsableSpell(S.MangleBear) and self:GetSpellCooldown(S.MangleBear) == 0 and rage >= 15 then
        if not self:CastSpell(S.MangleBear, "target") then return false end
        DruidDebug("EPIC BERSERK THREAT: Mangle spam")
        return true
    end

    -- Single-target priority starts with Mangle for snap threat.
    if enemies < 3 and self:IsUsableSpell(S.MangleBear) and self:GetSpellCooldown(S.MangleBear) == 0 and rage >= 20 then
        if not self:CastSpell(S.MangleBear, "target") then return false end
        DruidDebug("EPIC THREAT: Mangle (massive threat + bleed debuff)")
        return true
    end
    
    -- EPIC PRIORITY 1: Faerie Fire (Feral) - single-target snap threat and armor reduction
    if enemies < 3 and self:DebuffTimeRemaining("target", S.FaerieFireFeral) < 5 and
       self:IsUsableSpell(S.FaerieFireFeral) and self:GetSpellCooldown(S.FaerieFireFeral) == 0 then
        if not self:CastSpell(S.FaerieFireFeral, "target") then return false end
        DruidDebug("EPIC THREAT: Faerie Fire (snap threat + armor reduction)")
        return true
    end
    
    -- REMOVED: Challenging Roar AoE taunt - handled by universal system

    -- EPIC PRIORITY 2: Demoralizing Roar - survivability and threat
    local roarGuid = UnitGUID("target") or "no-target"
    local roarThrottleKey = "BearDemoralizingRoar_" .. roarGuid
    if enemies >= 1 and GetDemoralizingDebuffTimeRemaining(self, "target") < 5 and
       self:IsUsableSpell(S.DemoralizingRoar) and rage >= 10 and Throttle(roarThrottleKey, 8) then
        if not self:CastSpell(S.DemoralizingRoar, "player") then return false end
        DruidDebug("EPIC SURVIVABILITY: Demoralizing Roar (damage reduction + threat)")
        return true
    end
    
    -- EPIC PRIORITY 2.5: Growl for single target threat emergency
    if autoTauntAllowed and enemies == 1 and self:IsUsableSpell(S.Growl) and self:GetSpellCooldown(S.Growl) == 0 then
        if UnitExists("targettarget") and not UnitIsUnit("targettarget", "player") and UnitIsFriend("player", "targettarget") then
            if self:GetGroupSize() > 5 and not self:IsRaidTauntSafeVictim("targettarget") then
                DruidDebug("BLOCKED raid Growl - target is on confirmed tank victim: " .. (UnitName("targettarget") or "Unknown"))
            else
                local targetGUID = UnitGUID("target")
                local hadThreatBefore = (self.expectedThreatTargets and self.expectedThreatTargets[targetGUID]) or
                                      (self.lastTauntTarget == targetGUID and (GetTime() - self.lastTauntTime) < 15)
                local canGrowl = self:GetGroupSize() <= 5 or hadThreatBefore

                if canGrowl and Throttle("Growl", 8) then
                    if not self:CastSpell(S.Growl, "target") then return false end
                    self.lastTauntTime = GetTime()
                    self.lastTauntTarget = UnitGUID("target")
                    DruidDebug(self:GetGroupSize() <= 5 and "EPIC THREAT: Growl (5-man snap threat)" or "EPIC THREAT: Growl (threat recovery)")
                    return true
                else
                    DruidDebug("BLOCKED wasteful Growl - we never had threat on this target")
                end
            end
        end
    end
    
    -- EPIC PRIORITY 3: Advanced AoE threat management
    -- Swipe is the primary AoE rage dump on 3+ targets, especially while leveling.
    if enemies >= 3 and self:IsUsableSpell(S.SwipeBear) and rage >= GetBearSwipeThreshold(level) then
        if not self:CastSpell(S.SwipeBear, "player") then return false end
        DruidDebug("EPIC AoE THREAT: Swipe (" .. enemies .. " enemies)")
        return true
    end
    
    -- REMOVED: Tab-target threat management - handled by universal system
    
    -- EPIC PRIORITY 5: Advanced Lacerate stacking with safe refresh timing
    if self:IsUsableSpell(S.Lacerate) and rage >= 13 then
        local _, lacStacks = self:HasDebuff("target", S.Lacerate)
        local lacTimeRemaining = self:DebuffTimeRemaining("target", S.Lacerate)
        
        -- EPIC LACERATE LOGIC:
        -- 1. Build to 5 stacks for maximum DoT damage
        -- 2. Refresh before the stack falls off
        -- 3. Each stack increases threat and damage
        if (lacStacks or 0) < 5 or lacTimeRemaining < 4.5 then
            if not self:CastSpell(S.Lacerate, "target") then return false end
            DruidDebug("EPIC LACERATE: Stack " .. ((lacStacks or 0) + 1) .. "/5 (time: "..string.format("%.1f", lacTimeRemaining)..")")
            return true
        end
    end
    
    return false
end

-- =============================================
-- EPIC RESTORATION HEALING ROTATION
-- =============================================

function AC:RestorationDruidRotation()
    local currentForm = self:GetCurrentDruidForm()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- SMART HEALING PRIORITY 1: EMERGENCY TRIAGE OVERRIDE
    -- If anyone is critically injured, emergency triage takes absolute priority
    if self:DruidEmergencyTriage() then return true end
    
    -- EPIC PRIORITY 0: Handle dispels first
    if self:HandleDispels() then return true end
    
    -- Combat rebuffs are disabled to avoid shapeshift loss during combat.
    
    -- RESEARCH: Tree of Life form for healing (optional but beneficial)
    if self:KnowsSpell(S.TreeOfLife) then
        if currentForm ~= AC.DruidForms.TREE then
            if self:ShiftToForm(S.TreeOfLife) then return true end
        end
    end
    
    -- Defensive cooldowns
    if self:UseDruidDefensives(currentForm) then return true end
    
    -- EPIC PRIORITY 1: Emergency healing protocols
    local emergencyTarget, emergencyHP = self:FindHealingTarget(40, 0.25)
    if emergencyTarget then
        -- EPIC PROTOCOL: Nature's Swiftness + Healing Touch for <25% HP
        if emergencyHP < 0.25 and self:IsUsableSpell(S.NaturesSwiftness)
           and self:GetSpellCooldown(S.NaturesSwiftness) == 0 then
            if not self:CastSpell(S.NaturesSwiftness, "player") then return false end
            DruidDebug("EPIC EMERGENCY: Nature's Swiftness for " .. (UnitName(emergencyTarget) or emergencyTarget))
            return true
        end
        
        -- Use NS + HT combo immediately
        if self:HasBuff("player", S.NaturesSwiftness) and self:IsUsableSpell(S.HealingTouch)
           and not UnitCastingInfo("player") then
            if not self:CastSpell(S.HealingTouch, emergencyTarget) then return false end
            DruidDebug("EPIC EMERGENCY: NS + Healing Touch on " .. (UnitName(emergencyTarget) or emergencyTarget))
            return true
        end
        
        -- EPIC PROTOCOL: Swiftmend for emergency <30% HP
        if emergencyHP < 0.30 and self:IsUsableSpell(S.Swiftmend)
           and self:GetSpellCooldown(S.Swiftmend) == 0 then
            if self:HasBuff(emergencyTarget, S.Rejuvenation) or self:HasBuff(emergencyTarget, S.Regrowth) then
                if not self:CastSpell(S.Swiftmend, emergencyTarget) then return false end
                DruidDebug("EPIC EMERGENCY: Swiftmend on " .. (UnitName(emergencyTarget) or emergencyTarget))
                return true
            end
        end
    end
    
    -- EPIC PRIORITY 2: Mana management with Innervate on others
    if self:IsUsableSpell(S.Innervate) and self:GetSpellCooldown(S.Innervate) == 0 then
        -- Try to innervate other healers first if they need it more
        local healerNeedingMana = nil
        local groupUnits = {}
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                table.insert(groupUnits, "raid" .. i)
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                table.insert(groupUnits, "party" .. i)
            end
        end
        
        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and self:IsHealer(unit) and not UnitIsUnit(unit, "player") then
                local unitMaxMana = UnitPowerMax(unit, 0)
                local unitMana = unitMaxMana > 0 and (UnitPower(unit, 0) / unitMaxMana * 100) or 100
                if unitMana < 20 and IsHealingSpellInRange(unit) then
                    healerNeedingMana = unit
                    break
                end
            end
        end
        
        if healerNeedingMana or manaPercent < 30 then
            local innervateTarget = healerNeedingMana or "player"
            if not self:CastSpell(S.Innervate, innervateTarget) then return false end
            DruidDebug("EPIC MANA: Innervate on " .. (UnitName(innervateTarget) or innervateTarget))
            return true
        end
    end
    
    -- Mana potion
    if manaPercent < 20 and self.UseManaPotion and CanRetryDruidConsumable(self, "manaPotion", 15) then
        local usedPotion, reason = self:UseManaPotion(20)
        if usedPotion then
            MarkDruidConsumableAttempt(self, "manaPotion")
            DruidDebug("Used mana potion")
            return true
        end
        if ShouldDelayDruidConsumableRetry(reason) then
            MarkDruidConsumableAttempt(self, "manaPotion")
        end
        if self.debugMode then
            DruidDebug("Druid mana potion unavailable: " .. tostring(reason or "none"))
        end
    end
    
    -- SMART HEALING PRIORITY 2: INTELLIGENT HEALING ALGORITHM
    -- Use advanced smart healing system for optimal spell selection and overhealing minimization
    if self:DruidSmartHeal() then return true end
    
    -- RESEARCH: Nature's Swiftness emergency healing
    if self:IsUsableSpell(S.NaturesSwiftness) and self:GetSpellCooldown(S.NaturesSwiftness) == 0 then
        local emergTarget, emergHP = self:FindHealingTarget(40, 0.30)
        if emergTarget then
            if not self:CastSpell(S.NaturesSwiftness, "player") then return false end
            DruidDebug("Resto: Nature's Swiftness (emergency)")
            return true
        end
    end
    
    -- Use NS + Healing Touch
    if self:HasBuff("player", S.NaturesSwiftness) and self:IsUsableSpell(S.HealingTouch) then
        local emergTarget, emergHP = self:FindHealingTarget(40, 0.40)
        if emergTarget then
            if not self:CastSpell(S.HealingTouch, emergTarget) then return false end
            DruidDebug("Resto: NS + Healing Touch on " .. UnitName(emergTarget))
            return true
        end
    end
    
    -- Find healing target
    local healTarget, healTargetHealth = self:FindHealingTarget(40, 0.95)
    
    -- No healing needed - DPS if safe
    if not healTarget then
        if hasTarget and manaPercent > 70 and not self:IsChanneling() then
            -- Maintain DoTs for DPS
            if self:DebuffTimeRemaining("target", S.Moonfire) < 3 and self:IsUsableSpell(S.Moonfire) then
                if not self:CastSpell(S.Moonfire, "target") then return false end
                DruidDebug("Resto: Moonfire (DPS)")
                return true
            end
            
            if self:DebuffTimeRemaining("target", S.InsectSwarm) < 3 and self:IsUsableSpell(S.InsectSwarm) then
                if not self:CastSpell(S.InsectSwarm, "target") then return false end
                DruidDebug("Resto: Insect Swarm (DPS)")
                return true
            end
            
            -- Wrath spam
            if self:IsUsableSpell(S.Wrath) and not UnitCastingInfo("player") then
                if not self:CastSpell(S.Wrath, "target") then return false end
                DruidDebug("Resto: Wrath (DPS)")
                return true
            end
        end
        return false
    end
    
    -- RESEARCH PRIORITY 1: Swiftmend emergency heal (instant)
    if healTargetHealth < 0.50 and self:IsUsableSpell(S.Swiftmend)
       and self:GetSpellCooldown(S.Swiftmend) == 0 then
        if self:HasBuff(healTarget, S.Rejuvenation) or self:HasBuff(healTarget, S.Regrowth) then
            if not self:CastSpell(S.Swiftmend, healTarget) then return false end
            DruidDebug("Resto: Swiftmend on " .. UnitName(healTarget))
            return true
        end
    end
    
    -- EPIC PRIORITY 3: Advanced group healing with Wild Growth
    if self:IsUsableSpell(S.WildGrowth) and self:GetSpellCooldown(S.WildGrowth) == 0 and healTargetHealth < 0.80 then
        -- Enhanced group damage detection
        local groupUnits = {}
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                table.insert(groupUnits, "raid" .. i)
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                table.insert(groupUnits, "party" .. i)
            end
        end
        
        local lowHealthCount = 0
        local tanksDamaged = 0
        
        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and IsHealingSpellInRange(unit) then
                local maxHP = UnitHealthMax(unit)
                local hp = maxHP > 0 and (UnitHealth(unit) / maxHP) or 1
                if hp < 0.85 then
                    lowHealthCount = lowHealthCount + 1
                    if self:IsTank(unit) then
                        tanksDamaged = tanksDamaged + 1
                    end
                end
            end
        end
        
        -- Use Wild Growth if:
        -- 1. 3+ people need healing, OR
        -- 2. 2+ people including tank(s) need healing
        if lowHealthCount >= 3 or (lowHealthCount >= 2 and tanksDamaged >= 1) then
            if not self:CastSpell(S.WildGrowth, healTarget) then return false end
            DruidDebug("EPIC GROUP HEAL: Wild Growth (" .. lowHealthCount .. " targets, " .. tanksDamaged .. " tanks)")
            return true
        end
    end
    
    -- EPIC PRIORITY 4: Advanced Lifebloom management on all tanks
    local tankUnits = {}
    if IsDruidInGroup() then
        local groupUnits = {}
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                table.insert(groupUnits, "raid" .. i)
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                table.insert(groupUnits, "party" .. i)
            end
        end
        
        -- Find all tanks
        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and self:IsTank(unit) then
                table.insert(tankUnits, unit)
            end
        end
    end
    
    -- Maintain Lifebloom only when tank damage or Clearcasting justifies the mana.
    for _, tankUnit in ipairs(tankUnits) do
        local _, lbStacks = self:HasBuff(tankUnit, S.Lifebloom)
        local lbTimeRemaining = self:BuffTimeRemaining(tankUnit, S.Lifebloom)
        local maxTankHP = UnitHealthMax(tankUnit)
        local tankHP = maxTankHP > 0 and (UnitHealth(tankUnit) / maxTankHP) or 1
        local hasClearcasting = self:HasOmenOfClarity()

        if self:IsUsableSpell(S.Lifebloom) and (hasClearcasting or manaPercent > 35) and
           (tankHP < 0.75 or hasClearcasting) and
           ((lbStacks or 0) < 3 or (lbTimeRemaining < 1.0 and tankHP < 0.85)) then
            if not self:CastSpell(S.Lifebloom, tankUnit) then return false end
            DruidDebug("EPIC LIFEBLOOM: " .. (UnitName(tankUnit) or tankUnit) .. " (stack: "..(lbStacks or 0).."/3, time: "..string.format("%.1f", lbTimeRemaining)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 5: Rejuvenation blanket with smart application
    if healTargetHealth < 0.95 then
        local rejuvTime = self:BuffTimeRemaining(healTarget, S.Rejuvenation)
        
        local refreshWindow = self:IsTank(healTarget) and 2.0 or 1.0

        if rejuvTime < refreshWindow and self:IsUsableSpell(S.Rejuvenation) then
            if not self:CastSpell(S.Rejuvenation, healTarget) then return false end
            DruidDebug("EPIC REJUVENATION: " .. (UnitName(healTarget) or healTarget) .. " (time: "..string.format("%.1f", rejuvTime)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 6: Smart Regrowth usage
    if healTargetHealth < 0.70 and manaPercent > 30 and not UnitCastingInfo("player") and
       self:IsUsableSpell(S.Regrowth) then
        -- EPIC REGROWTH LOGIC:
        -- 1. Use on targets that need immediate healing
        -- 2. Prefer tanks and healers
        -- 3. Use when we have Nature's Grace proc for faster cast
        local shouldRegrowth = false
        
        if healTargetHealth < 0.50 then
            shouldRegrowth = true -- Always regrowth <50% HP
        elseif (self:IsTank(healTarget) or self:IsHealer(healTarget)) and healTargetHealth < 0.70 then
            shouldRegrowth = true -- Regrowth important targets <70% HP
        elseif self:HasBuff("player", S.NaturesGrace) then
            shouldRegrowth = true -- Use proc for faster cast
        end
        
        if shouldRegrowth then
            if not self:CastSpell(S.Regrowth, healTarget) then return false end
            DruidDebug("EPIC REGROWTH: " .. (UnitName(healTarget) or healTarget) .. " (HP: "..string.format("%.1f%%", healTargetHealth*100)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 7: Advanced Nourish with HoT synergy
    if healTargetHealth < 0.85 and self:IsUsableSpell(S.Nourish) and not UnitCastingInfo("player") then
        -- EPIC NOURISH LOGIC:
        -- 1. Only use when target has HoTs (for synergy bonus)
        -- 2. Count the number of HoTs for efficiency calculation
        -- 3. Prefer high-priority targets with multiple HoTs
        
        local hotCount = 0
        if self:HasBuff(healTarget, S.Rejuvenation) then hotCount = hotCount + 1 end
        if self:HasBuff(healTarget, S.Regrowth) then hotCount = hotCount + 1 end
        if self:HasBuff(healTarget, S.Lifebloom) then hotCount = hotCount + 1 end
        if self:HasBuff(healTarget, S.WildGrowth) then hotCount = hotCount + 1 end
        
        if hotCount >= 2 or (hotCount >= 1 and (self:IsTank(healTarget) or healTargetHealth < 0.70)) then
            if not self:CastSpell(S.Nourish, healTarget) then return false end
            DruidDebug("EPIC NOURISH: " .. (UnitName(healTarget) or healTarget) .. " (" .. hotCount .. " HoTs, HP: "..string.format("%.1f%%", healTargetHealth*100)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 8: Strategic Healing Touch usage
    if healTargetHealth < 0.60 and manaPercent > 20 and not UnitCastingInfo("player") and
       self:IsUsableSpell(S.HealingTouch) then
        -- EPIC HEALING TOUCH LOGIC:
        -- 1. Use on tanks that need big heals
        -- 2. Use when we have Nature's Grace for faster cast
        -- 3. Use for emergency healing when other spells are on cooldown
        
        local shouldHealingTouch = false
        
        if self:IsTank(healTarget) and healTargetHealth < 0.60 then
            shouldHealingTouch = true -- Always big heal tanks
        elseif healTargetHealth < 0.40 then
            shouldHealingTouch = true -- Emergency big heal
        elseif self:HasBuff("player", S.NaturesGrace) and healTargetHealth < 0.60 then
            shouldHealingTouch = true -- Use proc for faster cast
        end
        
        if shouldHealingTouch then
            if not self:CastSpell(S.HealingTouch, healTarget) then return false end
            DruidDebug("EPIC HEALING TOUCH: " .. (UnitName(healTarget) or healTarget) .. " (HP: "..string.format("%.1f%%", healTargetHealth*100)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 9: Advanced Tranquility panic protocol
    if self:IsUsableSpell(S.Tranquility) and self:GetSpellCooldown(S.Tranquility) == 0 then
        local groupUnits = {"player"}
        for _, unit in ipairs(BuildDruidGroupUnitList()) do
            groupUnits[#groupUnits + 1] = unit
        end
        
        local criticalHealthCount = 0
        local lowHealthCount = 0
        local tanksCritical = 0
        
        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and IsHealingSpellInRange(unit) then
                local maxHP = UnitHealthMax(unit)
                local hp = maxHP > 0 and (UnitHealth(unit) / maxHP) or 1
                if hp < 0.30 then
                    criticalHealthCount = criticalHealthCount + 1
                    if self:IsTank(unit) then
                        tanksCritical = tanksCritical + 1
                    end
                elseif hp < 0.50 then
                    lowHealthCount = lowHealthCount + 1
                end
            end
        end
        
        -- EPIC TRANQUILITY CONDITIONS:
        -- 1. 3+ people critical (<30% HP), OR
        -- 2. 1+ tanks critical, OR
        -- 3. 5+ people low health (<50% HP)
        if (criticalHealthCount >= 3 or tanksCritical >= 1 or lowHealthCount >= 5) and Throttle("Tranquility", 5) then
            if not self:CastSpell(S.Tranquility, "player") then return false end
            DruidDebug("EPIC TRANQUILITY: PANIC MODE (Critical: " .. criticalHealthCount .. ", Tanks: " .. tanksCritical .. ", Low: " .. lowHealthCount .. ")")
            return true
        end
    end
    
    return false
end

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- =============================================
-- EPIC HEALING TARGET SYSTEM
-- =============================================

-- Enhanced healing target finder with priority system
function AC:FindHealingTarget(range, threshold)
    local healingTargets = {}
    
    -- Get group units
    local groupUnits = {"player"}
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            table.insert(groupUnits, "raid" .. i)
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            table.insert(groupUnits, "party" .. i)
        end
    end
    
    -- Analyze each group member
    for _, unit in ipairs(groupUnits) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            local maxHealth = UnitHealthMax(unit)
            local hp = maxHealth > 0 and (UnitHealth(unit) / maxHealth) or 1
            if hp < threshold then
                local priority = 0
                local role = "dps"
                
                -- Role matters, but critical health must outrank a lightly injured tank.
                if self:IsTank(unit) then
                    priority = priority + 4
                    role = "tank"
                elseif self:IsHealer(unit) then
                    priority = priority + 2
                    role = "healer"
                end

                if hp < 0.30 then
                    priority = priority + 10
                elseif hp < 0.50 then
                    priority = priority + 5
                elseif hp < 0.70 then
                    priority = priority + 2
                end

                if UnitIsUnit(unit, "player") then priority = priority + 1 end
                
                -- Healing requires actual spell range, not interact distance.
                local inRange = IsHealingSpellInRange(unit)
                
                if inRange then
                    table.insert(healingTargets, {
                        unit = unit,
                        health = hp,
                        priority = priority,
                        role = role
                    })
                end
            end
        end
    end
    
    -- Sort by priority (highest first), then by health (lowest first)
    table.sort(healingTargets, function(a, b)
        if a.priority == b.priority then
            return a.health < b.health
        end
        return a.priority > b.priority
    end)
    
    -- Return the highest priority target
    if #healingTargets > 0 then
        local target = healingTargets[1]
        DruidDebug("EPIC HEAL TARGET: " .. target.role .. " (" .. (UnitName(target.unit) or target.unit) .. 
                  ") HP: " .. string.format("%.1f%%", target.health * 100) .. " Priority: " .. target.priority)
        return target.unit, target.health
    end
    
    return nil, 1.0
end

function AC:DruidEmergencyTriage()
    if not Throttle("DruidEmergencyTriage", 0.2) then return false end

    local target, hp = self:FindHealingTarget(40, 0.30)
    if not target then return false end

    if self:HasBuff("player", S.NaturesSwiftness) and self:IsUsableSpell(S.HealingTouch)
       and not UnitCastingInfo("player") then
        if not self:CastSpell(S.HealingTouch, target) then return false end
        DruidDebug("Resto triage: NS + Healing Touch on " .. (UnitName(target) or target))
        return true
    end

    if hp < 0.25 and self:IsUsableSpell(S.NaturesSwiftness)
       and self:GetSpellCooldown(S.NaturesSwiftness) == 0 and self:IsUsableSpell(S.HealingTouch) then
        if not self:CastSpell(S.NaturesSwiftness, "player") then return false end
        DruidDebug("Resto triage: Nature's Swiftness")
        return true
    end

    if hp < 0.30 and self:IsUsableSpell(S.Swiftmend) and self:GetSpellCooldown(S.Swiftmend) == 0 and
       (self:HasBuff(target, S.Rejuvenation) or self:HasBuff(target, S.Regrowth)) then
        if not self:CastSpell(S.Swiftmend, target) then return false end
        DruidDebug("Resto triage: Swiftmend on " .. (UnitName(target) or target))
        return true
    end

    if hp < 0.30 and self:IsUsableSpell(S.Rejuvenation) and self:BuffTimeRemaining(target, S.Rejuvenation) < 1 then
        if not self:CastSpell(S.Rejuvenation, target) then return false end
        DruidDebug("Resto triage: Rejuvenation on " .. (UnitName(target) or target))
        return true
    end

    if hp < 0.25 and self:IsUsableSpell(S.Regrowth) and not UnitCastingInfo("player") then
        if not self:CastSpell(S.Regrowth, target) then return false end
        DruidDebug("Resto triage: Regrowth on " .. (UnitName(target) or target))
        return true
    end

    return false
end

function AC:DruidSmartHeal()
    if not Throttle("DruidSmartHeal", 0.3) then return false end

    local target, hp = self:FindHealingTarget(40, 0.85)
    if not target then return false end

    if hp < 0.50 and self:IsUsableSpell(S.Swiftmend) and self:GetSpellCooldown(S.Swiftmend) == 0 and
       (self:HasBuff(target, S.Rejuvenation) or self:HasBuff(target, S.Regrowth)) then
        if not self:CastSpell(S.Swiftmend, target) then return false end
        DruidDebug("Resto smart heal: Swiftmend on " .. (UnitName(target) or target))
        return true
    end

    if hp < 0.80 and self:IsUsableSpell(S.WildGrowth) and self:GetSpellCooldown(S.WildGrowth) == 0 then
        local damaged = 0
        local tanksDamaged = 0
        local groupUnits = {"player"}
        for _, unit in ipairs(BuildDruidGroupUnitList()) do
            groupUnits[#groupUnits + 1] = unit
        end

        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) and IsHealingSpellInRange(unit) then
                local maxHP = UnitHealthMax(unit)
                local unitHP = maxHP > 0 and (UnitHealth(unit) / maxHP) or 1
                if unitHP < 0.85 then
                    damaged = damaged + 1
                    if self:IsTank(unit) then
                        tanksDamaged = tanksDamaged + 1
                    end
                end
            end
        end

        if damaged >= 3 or (damaged >= 2 and tanksDamaged >= 1) then
            if not self:CastSpell(S.WildGrowth, target) then return false end
            DruidDebug("Resto smart heal: Wild Growth (" .. damaged .. " damaged)")
            return true
        end
    end

    if hp < 0.75 and self:IsUsableSpell(S.Nourish) and not UnitCastingInfo("player") then
        local hotCount = 0
        if self:HasBuff(target, S.Rejuvenation) then hotCount = hotCount + 1 end
        if self:HasBuff(target, S.Regrowth) then hotCount = hotCount + 1 end
        if self:HasBuff(target, S.Lifebloom) then hotCount = hotCount + 1 end
        if self:HasBuff(target, S.WildGrowth) then hotCount = hotCount + 1 end

        if hotCount > 0 then
            if not self:CastSpell(S.Nourish, target) then return false end
            DruidDebug("Resto smart heal: Nourish on " .. (UnitName(target) or target))
            return true
        end
    end

    return false
end

-- Enhanced role detection
function AC:IsHealer(unit)
    if not UnitExists(unit) then return false end
    if UnitGroupRolesAssigned then
        local role = UnitGroupRolesAssigned(unit)
        if role and role ~= "NONE" then return role == "HEALER" end
    end

    if UnitIsUnit(unit, "player") then
        return self:GetPlayerSpec() == "Restoration"
    end

    -- WotLK exposes no dependable remote talent inspection. Tree Form is a
    -- safe healer signal; otherwise avoid classifying every hybrid as a healer.
    return self:HasBuff(unit, S.TreeOfLife)
end

-- REDIRECT: Tank detection now handled by Core.lua universal system
function AC:IsTank(unit)
    return self:IsTankSpec(unit)
end

-- =============================================
-- EPIC DISPEL SYSTEM
-- =============================================

function AC:HandleDispels()
    if not Throttle("DruidDispels", 1) then return false end
    
    -- Get group units
    local groupUnits = {"player"}
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            table.insert(groupUnits, "raid" .. i)
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            table.insert(groupUnits, "party" .. i)
        end
    end
    
    -- Check for curses first (higher priority)
    for _, unit in ipairs(groupUnits) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            -- Check for curse
            for i = 1, 40 do
                local name, _, _, _, debuffType = UnitDebuff(unit, i)
                if not name then break end
                
                if debuffType == "Curse" and self:IsUsableSpell(S.RemoveCurse) then
                    if not self:CastSpell(S.RemoveCurse, unit) then return false end
                    DruidDebug("EPIC DISPEL: Removed curse from " .. (UnitName(unit) or unit))
                    return true
                end
            end
        end
    end
    
    -- Check for poisons
    for _, unit in ipairs(groupUnits) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            -- Check for poison
            for i = 1, 40 do
                local name, _, _, _, debuffType = UnitDebuff(unit, i)
                if not name then break end
                
                if debuffType == "Poison" and self:IsUsableSpell(S.AbolishPoison) then
                    if not self:CastSpell(S.AbolishPoison, unit) then return false end
                    DruidDebug("EPIC DISPEL: Removed poison from " .. (UnitName(unit) or unit))
                    return true
                end
            end
        end
    end
    
    return false
end

-- =============================================
-- EPIC GROUP BUFFING SYSTEM
-- =============================================

function AC:CheckDruidGroupBuffs()
    if not Throttle("DruidGroupBuffs", 1.5) then return false end
    if UnitAffectingCombat("player") or IsMounted() then return false end
    if self:IsEatingOrDrinking() then return false end
    local isFeralBuild = self:IsFeralBuild()

    self.druidBuffScanState = self.druidBuffScanState or {}
    local groupUnits = BuildDruidGroupUnitList()
    local groupCount = #groupUnits
    if groupCount == 0 then
        self.druidBuffScanState.groupCursor = 1
        return false
    end

    local cursor = self.druidBuffScanState.groupCursor or 1
    if cursor > groupCount then
        cursor = 1
    end

    local scanBudget = math.min(2, groupCount)

    -- EPIC PRIORITY 1: Mark of the Wild / Gift of the Wild
    local motwSpell = self:KnowsSpell(S.GiftOfTheWild) and S.GiftOfTheWild or S.MarkOfTheWild
    for offset = 0, scanBudget - 1 do
        local index = cursor + offset
        if index > groupCount then
            index = index - groupCount
        end

        local unit = groupUnits[index]
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            local hasMotW = self:HasBuff(unit, S.MarkOfTheWild) or self:HasBuff(unit, S.GiftOfTheWild) or
                           self:HasBuff(unit, "Blessing of Kings") -- Don't overwrite Kings
            if not hasMotW and CheckInteractDistance(unit, 4) and self:IsUsableSpell(motwSpell) then
                local castSpell = motwSpell
                local castSucceeded = self:CastSpell(castSpell, unit)
                if not castSucceeded and motwSpell == S.GiftOfTheWild and self:IsUsableSpell(S.MarkOfTheWild) then
                    castSpell = S.MarkOfTheWild
                    castSucceeded = self:CastSpell(castSpell, unit)
                end
                if castSucceeded then
                    DruidDebug("EPIC GROUP BUFF: " .. castSpell .. " on " .. (UnitName(unit) or unit))
                    self.druidBuffScanState.groupCursor = index % groupCount + 1
                    return true
                end
            end
        end
    end

    self.druidBuffScanState.groupCursor = (cursor + scanBudget - 1) % groupCount + 1
    
    -- Thorns: feral build keeps this self-only; non-feral can still support the tank.
    if self:IsUsableSpell(S.Thorns) and self:KnowsSpell(S.Thorns) then
        if not isFeralBuild then
            local mainTankUnit = self:GetMainTankUnit()
            if mainTankUnit and not UnitIsUnit(mainTankUnit, "player") and
               CheckInteractDistance(mainTankUnit, 4) and not self:HasBuff(mainTankUnit, S.Thorns) then
                if not self:CastSpell(S.Thorns, mainTankUnit) then return false end
                DruidDebug("EPIC THORNS: " .. (UnitName(mainTankUnit) or mainTankUnit) .. " (MAIN TANK)")
                return true
            end
        end
    end
    
    if self:IsUsableSpell(S.Thorns) and self:KnowsSpell(S.Thorns) and not self:HasBuff("player", S.Thorns) then
        if not self:CastSpell(S.Thorns, "player") then return false end
        DruidDebug("EPIC THORNS: self")
        return true
    end

    return false
end

function AC:GetMainTankUnit()
    for i = 1, 5 do
        local unit = "maintank" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            return unit
        end
    end

    return nil
end

-- =============================================
-- EPIC RACIAL SYSTEM
-- =============================================

function AC:UseRacialsDruid(burst, emergency)
    local throttleKey = emergency and "DruidRacialsEmergency" or "DruidRacials"
    local throttleInterval = emergency and 1.0 or 3.0
    if not Throttle(throttleKey, throttleInterval) then return false end
    local _, race = UnitRace("player")
    race = string.upper(race)
    local health = self:GetPlayerHealthPercent()
    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
    local inCombat = UnitAffectingCombat("player")

    local function getPlayerDebuffState()
        local state = {
            poison = false,
            disease = false,
            bleed = false,
            fear = false,
            charm = false,
            sleep = false,
            stun = false,
            root = false,
            snare = false,
            slow = false,
        }

        for i = 1, 16 do
            local debuffName, _, _, _, debuffType = UnitDebuff("player", i)
            if not debuffName then break end

            local lowerName = string.lower(debuffName)
            if debuffType == "Poison" then state.poison = true end
            if debuffType == "Disease" then state.disease = true end

            if lowerName:find("bleed") or lowerName:find("rend") or lowerName:find("rake") or
               lowerName:find("rip") or lowerName:find("lacerate") then
                state.bleed = true
            end

            if lowerName:find("fear") or lowerName:find("charm") or lowerName:find("sleep") then
                state.fear = true
                state.charm = true
                state.sleep = true
            end

            if lowerName:find("stun") or lowerName:find("polymorph") or lowerName:find("incapacitate") then
                state.stun = true
            end

            if lowerName:find("root") then
                state.root = true
            end

            if lowerName:find("snare") or lowerName:find("slow") or lowerName:find("cripple") then
                state.snare = true
                state.slow = true
            end
        end

        return state
    end

    local debuffs = emergency and getPlayerDebuffState() or nil
    
    -- Offensive racials
    if burst and inCombat then
        if race == "TROLL" and self:IsUsableSpell(S.Berserking) then
            if not self:CastSpell(S.Berserking, "player") then return false end
            DruidDebug("Racial: Berserking")
            return true
        end
        if race == "ORC" and self:IsUsableSpell(S.BloodFury) then
            if not self:CastSpell(S.BloodFury, "player") then return false end
            DruidDebug("Racial: Blood Fury")
            return true
        end
    end
    
    -- Defensive/Emergency racials
    if emergency or health < 50 then
        if race == "TAUREN" and self:GetEnemyCount() >= 2 and self:IsInMeleeRange("target") and 
           self:IsUsableSpell(S.WarStomp) then
            if not self:CastSpell(S.WarStomp, "player") then return false end
            DruidDebug("Racial: War Stomp")
            return true
        end

        if race == "DWARF" and self:IsUsableSpell(S.Stoneform) and self:GetSpellCooldown(S.Stoneform) == 0 then
            if debuffs and (debuffs.poison or debuffs.disease or debuffs.bleed or health < 35) then
                if not self:CastSpell(S.Stoneform, "player") then return false end
                DruidDebug("Racial: Stoneform")
                return true
            end
        end

        if (race == "SCOURGE" or race == "UNDEAD") and self:IsUsableSpell(S.WillOfTheForsaken) then
            if debuffs and (debuffs.fear or debuffs.charm or debuffs.sleep) then
                if not self:CastSpell(S.WillOfTheForsaken, "player") then return false end
                DruidDebug("Racial: Will of the Forsaken")
                return true
            end
        end

        if race == "GNOME" and self:IsUsableSpell(S.EscapeArtist) then
            if debuffs and (debuffs.root or debuffs.snare or debuffs.slow) then
                if not self:CastSpell(S.EscapeArtist, "player") then return false end
                DruidDebug("Racial: Escape Artist")
                return true
            end
        end

        if race == "HUMAN" and self:IsUsableSpell(S.EveryManForHimself) then
            if debuffs and (debuffs.stun or debuffs.fear or debuffs.charm or debuffs.sleep) then
                if not self:CastSpell(S.EveryManForHimself, "player") then return false end
                DruidDebug("Racial: Every Man for Himself")
                return true
            end
        end

        if race == "DRAENEI" and health < 70 and self:IsUsableSpell(S.GiftOfTheNaaru) then
            if not self:CastSpell(S.GiftOfTheNaaru, "player") then return false end
            DruidDebug("Racial: Gift of the Naaru")
            return true
        end

    end
    
    return false
end

-- =============================================
-- MAIN DRUID ROTATION CONTROLLER
-- =============================================

function AC:DruidRotation()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local currentForm = self:GetCurrentDruidForm()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local isFeralBuild = self:IsFeralBuild()
    local feralRole = nil

    if level < 10 then
        return self:LevelingDruidRotation()
    end

    if level < 20 and not isFeralBuild and (spec == "None" or spec == "Unknown" or not spec) then
        return self:LevelingDruidRotation()
    end

    if isFeralBuild then
        feralRole = self:DetermineFeralRole()
        if not self:KnowsSpell(S.CatForm) then
            feralRole = "bear"
        end
        if inCombat then
            if not self.druidFeralCombatRole then
                self.druidFeralCombatRole = feralRole
                DruidDebug("Feral combat role locked: " .. tostring(feralRole))
            end
            feralRole = self.druidFeralCombatRole or feralRole
        else
            self.druidFeralCombatRole = nil
        end
    end
    
    -- Emergency Lifeblood (Herbalism profession ability) at 50% health
    if inCombat and self:UseLifeblood() then return true end
    
    -- Out of combat actions
    if not inCombat then
        if self:IsEatingOrDrinking() then return false end

        -- Balance pre-pull: keep this minimal for stable combat entry.
        if spec == "Balance" and hasTarget then
            if self:KnowsSpell(S.MoonkinForm) and currentForm ~= AC.DruidForms.MOONKIN then
                if self:ShiftToForm(S.MoonkinForm) then return true end
            end
            if not self:DruidIsFastDyingMob("target") and
               self:DebuffTimeRemaining("target", S.FaerieFireBalance) < 3 and
               self:IsUsableSpell(S.FaerieFireBalance) and self:GetSpellCooldown(S.FaerieFireBalance) == 0 then
                if not self:CastSpell(S.FaerieFireBalance, "target") then return false end
                DruidDebug("Balance: Faerie Fire pre-pull")
                return true
            end
            if self:IsUsableSpell(S.Wrath) and manaPercent > 10 and not UnitCastingInfo("player") then
                if not self:CastSpell(S.Wrath, "target") then return false end
                DruidDebug("Balance: Wrath pre-pull")
                return true
            end
            return false
        end

        local pulledTarget = isFeralBuild and hasTarget and UnitAffectingCombat("target")

        -- Buffs
        if not pulledTarget and self:CheckDruidBuffs() then return true end
        
        -- Travel forms management
        if not hasTarget then
            local moving = self:IsPlayerMoving()
            if IsSwimming() and currentForm ~= AC.DruidForms.AQUATIC then
                if self:ShiftToForm(S.AquaticForm) then return true end
            elseif IsFlyableArea() and moving and currentForm ~= AC.DruidForms.FLIGHT and 
                   currentForm ~= AC.DruidForms.SWIFT_FLIGHT then
                local flightForm = self:KnowsSpell(S.SwiftFlightForm) and S.SwiftFlightForm or S.FlightForm
                if self:ShiftToForm(flightForm) then return true end
            elseif moving and currentForm ~= AC.DruidForms.TRAVEL and not IsFlyableArea() and not IsSwimming() then
                if self:ShiftToForm(S.TravelForm) then return true end
            elseif not moving and (currentForm == AC.DruidForms.TRAVEL or currentForm == AC.DruidForms.FLIGHT or 
                                  currentForm == AC.DruidForms.SWIFT_FLIGHT or currentForm == AC.DruidForms.AQUATIC) then
                -- Cancel travel form when stopped
                if self:ShiftToForm("Caster") then return true end
            end
        end

        -- If a group member already pulled the target, feral should engage immediately instead of idling out of combat.
        if pulledTarget then
            if feralRole == "bear" or not self:KnowsSpell(S.CatForm) then
                local desiredBearForm = self:KnowsSpell(S.DireBearForm) and S.DireBearForm or S.BearForm
                if currentForm ~= AC.DruidForms.BEAR then
                    if self:ShiftToForm(desiredBearForm) then return true end
                end

                if self:HandleTankTargeting() then return true end
            elseif feralRole == "cat" then
                if currentForm ~= AC.DruidForms.CAT then
                    if self:ShiftToForm(S.CatForm) then return true end
                end
            end

            if self:IsInMeleeRange("target") then
                StartAttack()
                DruidDebug("Feral: engaging already-pulled target")
                return true
            end
        end
        
        -- RESEARCH: Feral stealth opener
        if hasTarget and not UnitAffectingCombat("target") then
            if isFeralBuild and feralRole == "bear" then
                local desiredBearForm = self:KnowsSpell(S.DireBearForm) and S.DireBearForm or S.BearForm
                if currentForm ~= AC.DruidForms.BEAR then
                    if self:ShiftToForm(desiredBearForm) then return true end
                end
            elseif isFeralBuild and feralRole == "cat" then
                if currentForm ~= AC.DruidForms.CAT then
                    if self:ShiftToForm(S.CatForm) then return true end
                end
                if currentForm == AC.DruidForms.CAT then
                    if not self:HasBuff("player", S.Prowl) and self:IsUsableSpell(S.Prowl) then
                        if not self:CastSpell(S.Prowl, "player") then return false end
                        DruidDebug("Prowl for stealth opener")
                        return true
                    end
                    if self:HasBuff("player", S.Prowl) and self:IsInMeleeRange("target") then
                        local classification = UnitClassification("target")
                        local toughTarget = classification == "elite" or classification == "rareelite" or
                                            classification == "worldboss"
                        if not toughTarget and self:IsUsableSpell(S.Ravage) then
                            if self:CastSpell(S.Ravage, "target") then
                                DruidDebug("Ravage opener")
                                return true
                            end
                        end
                        if self:IsUsableSpell(S.Pounce) then
                            if self:CastSpell(S.Pounce, "target") then
                                DruidDebug("Pounce opener")
                                return true
                            end
                        end
                        if toughTarget and self:IsUsableSpell(S.Ravage) then
                            if self:CastSpell(S.Ravage, "target") then
                                DruidDebug("Ravage opener fallback")
                                return true
                            end
                        end

                        -- If positional openers are rejected, break stealth and engage
                        -- instead of retrying the same unusable opener forever.
                        StartAttack()
                        DruidDebug("Feral opener unavailable - starting normal combat")
                        return true
                    end
                end
            else
                -- Balance: shift to Moonkin Form before pull Wrath
                if spec == "Balance" and self:KnowsSpell(S.MoonkinForm) and currentForm ~= AC.DruidForms.MOONKIN then
                    if self:ShiftToForm(S.MoonkinForm) then return true end
                end
                
                -- Ranged pull for casters (Balance uses in-combat opener instead)
                if spec ~= "Balance" and self:IsUsableSpell(S.Wrath) then
                    if not self:CastSpell(S.Wrath, "target") then return false end
                    DruidDebug("Wrath pull")
                    return true
                end
            end
        end
        
        return false
    end
    
    -- In combat rotation dispatch based on spec
    if spec == "Balance" then
        return self:BalanceDruidRotation()
    elseif isFeralBuild then
        if feralRole == "bear" or not self:KnowsSpell(S.CatForm) then
            return self:FeralBearTankRotation()
        else
            return self:FeralCatDpsRotation()
        end
    elseif spec == "Restoration" then
        return self:RestorationDruidRotation()
    else
        if level < 20 then
            -- Bear form tanking
            return self:FeralBearTankRotation()
        else
            -- Cat form DPS
            return self:FeralCatDpsRotation()
        end
    end
    
    return false
end

-- =============================================
-- INITIALIZATION
-- =============================================

function AC:InitDruidRotations()
    self.rotations = self.rotations or {}
    self.rotations["DRUID"] = {}
    self.druidFeralCombatRole = nil
    self.druidConsumableAttempts = self.druidConsumableAttempts or {}
    
    self.rotations["DRUID"]["Balance"] = function(s) return s:DruidRotation() end
    self.rotations["DRUID"]["Feral"] = function(s) return s:DruidRotation() end
    self.rotations["DRUID"]["Restoration"] = function(s) return s:DruidRotation() end
    self.rotations["DRUID"]["None"] = function(s) return s:DruidRotation() end
    
    self.CheckDruidBuffs = AC.CheckDruidBuffs
    
    self:Print("|cFFFF7D0A Druid|r rotations initialized - |cFFFFD700RESEARCH-BASED WotLK 3.3.5a|r")
    DruidDebug("|cFFFF7D0A=== DRUID IMPROVEMENTS ===|r")
    DruidDebug("|cFF0070DDBalance:|r Eclipse management + research-based DoT priorities")
    DruidDebug("|cFFFF6347Feral Cat:|r Priority system: Savage Roar > Rip > Rake > Shred/Mangle")
    DruidDebug("|cFF8B4513Feral Bear:|r Proper threat rotation with rage management")
    DruidDebug("|cFF32CD32Restoration:|r HoT optimization + emergency healing priorities")
    DruidDebug("|cFFFFD700Research:|r Based on WotLK 3.3.5a guides from Icy Veins, Warcraft Tavern")
    DruidDebug("|cFFDDA0DDFeatures:|r Stealth openers, travel forms, defensive cooldowns")

    if self.RegisterEvent then
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
            if self.druidFeralCombatRole then
                self.druidFeralCombatRole = nil
                DruidDebug("Feral combat role unlocked")
            end
            self.druidConsumableAttempts = {}
        end)
    end

    if self.RegisterEvent then
        self:RegisterEvent("PLAYER_TALENT_UPDATE", function()
            self.druidTalentCache = nil
            self.druidFeralCombatRole = nil
            self.druidConsumableAttempts = {}
        end)
    end
end
