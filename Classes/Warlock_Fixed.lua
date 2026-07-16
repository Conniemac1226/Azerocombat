-- FIXED BUFF MANAGEMENT FUNCTIONS

-- Simplified buff checker - no more infinite loops
function AC:CheckWarlockBuffs(spec)
    local applied = false
    local level = UnitLevel("player")
    
    -- Skip if mounted to prevent dismounting
    if IsMounted() then return false end
    
    -- Only check buffs with proper throttling (increased to prevent spam)
    if not self:Throttle("WarlockBuffCheck", 15) then
        return false
    end
    
    -- Check armor buff
    local hasFelArmor = self:HasBuff("player", S.FelArmor)
    local hasDemonArmor = self:HasBuff("player", S.DemonArmor)
    local hasDemonSkin = self:HasBuff("player", S.DemonSkin)
    
    if not hasFelArmor and not hasDemonArmor and not hasDemonSkin then
        if level >= 62 and self:IsUsableSpell(S.FelArmor) then
            self:CastSpell(S.FelArmor, "player")
            return true
        elseif level >= 30 and self:IsUsableSpell(S.DemonArmor) then
            self:CastSpell(S.DemonArmor, "player")
            return true
        elseif self:IsUsableSpell(S.DemonSkin) then
            self:CastSpell(S.DemonSkin, "player")
            return true
        end
    end
    
    -- Pet check (only if no pet)
    local currentPet = self:GetCurrentPet()
    if currentPet == "none" and not UnitAffectingCombat("player") then
        if self:EnsureCorrectPet(spec, level) then
            return true
        end
    end
    
    return false
end

-- FIXED: Weapon stone application for WotLK 3.3.5
function AC:ApplyWeaponStone(stoneName)
    -- First, check if we have the stone
    local count = GetItemCount(stoneName)
    if count == 0 then
        return false
    end
    
    -- Get the item slot for the stone
    local bag, slot
    for b = 0, 4 do
        for s = 1, GetContainerNumSlots(b) do
            local itemLink = GetContainerItemLink(b, s)
            if itemLink then
                local itemName = GetItemInfo(itemLink)
                if itemName == stoneName then
                    bag, slot = b, s
                    break
                end
            end
        end
        if bag then break end
    end
    
    if not bag then
        WarlockDebug("Stone found but couldn't locate in bags: " .. stoneName)
        return false
    end
    
    -- Apply to main hand weapon
    ClearCursor()
    PickupContainerItem(bag, slot)
    if CursorHasItem() then
        PickupInventoryItem(16) -- 16 is main hand slot
        WarlockDebug("Applied " .. stoneName .. " to main hand weapon")
        return true
    end
    
    return false
end

-- FIXED: Separate consumable management to avoid loops
function AC:ManageWarlockConsumables(spec, level)
    -- Skip if mounted
    if IsMounted() then return false end
    
    -- Throttle this entire function heavily
    if not self:Throttle("ConsumableManagement", 30) then
        return false
    end
    
    -- Check weapon enchant
    local hasMainHandEnchant = GetWeaponEnchantInfo()
    if not hasMainHandEnchant then
        -- Try to apply a spellstone first
        local spellstoneNames = {"Grand Spellstone", "Major Spellstone", "Greater Spellstone", "Spellstone"}
        for _, stoneName in ipairs(spellstoneNames) do
            if GetItemCount(stoneName) > 0 then
                if self:ApplyWeaponStone(stoneName) then
                    return true
                end
            end
        end
        
        -- Create spellstone if we don't have one
        if self:IsUsableSpell(S.CreateSpellstone) then
            self:CastSpell(S.CreateSpellstone, "player")
            return true
        end
    end
    
    -- Healthstone check
    if level >= 10 and not self:HasHealthstone() and self:IsUsableSpell(S.CreateHealthstone) then
        if self:Throttle("CreateHealthstone", 120) then
            self:CastSpell(S.CreateHealthstone, "player")
            return true
        end
    end
    
    -- Soulstone check
    if level >= 18 and not self:HasSoulstone() and self:IsUsableSpell(S.CreateSoulstone) then
        if self:Throttle("CreateSoulstone", 180) then
            self:CastSpell(S.CreateSoulstone, "player")
            return true
        end
    end
    
    return false
end

-- Helper functions
function AC:HasHealthstone()
    return GetItemCount("Healthstone") > 0 or 
           GetItemCount("Lesser Healthstone") > 0 or 
           GetItemCount("Greater Healthstone") > 0 or 
           GetItemCount("Major Healthstone") > 0 or 
           GetItemCount("Super Healthstone") > 0
end

function AC:HasSoulstone()
    return GetItemCount("Soulstone") > 0 or 
           GetItemCount("Lesser Soulstone") > 0 or 
           GetItemCount("Greater Soulstone") > 0 or 
           GetItemCount("Major Soulstone") > 0
end

-- FIXED MAIN ROTATION - Remove EnsureWarlockBuffs to prevent loops
function AC:WarlockRotation()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local health = UnitHealth("player") / UnitHealthMax("player") * 100
    local mana = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
    local enemies = self:GetEnemyCount()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
    
    -- Debug output
    if self:Throttle("WarlockDebug", 5) then
        WarlockDebug("Running " .. spec .. " rotation, level: " .. level .. ", mana: " .. math.floor(mana) .. "%, health: " .. math.floor(health) .. "%, inCombat: " .. tostring(inCombat))
    end
    
    -- Check if channeling
    if self:IsBusyChanneling() then
        return true
    end
    
    -- Basic buff check (armor and pet only)
    if self:CheckWarlockBuffs(spec) then
        return true
    end
    
    -- Emergency Lifeblood (Herbalism profession ability) at 50% health
    if inCombat and self:UseLifeblood() then return true end
    
    -- Consumable management (OUT OF COMBAT ONLY to prevent combat interruption)
    if not inCombat then
        if self:ManageWarlockConsumables(spec, level) then
            return true
        end
    end
    
    -- Combat-only Life Tap buff maintenance
    if inCombat and self:Throttle("CombatLifeTap", 20) then
        local lifeTapBuff = self:HasBuff("player", "Life Tap")
        if not lifeTapBuff and self:IsUsableSpell(S.LifeTap) and health > 60 and mana < 80 then
            self:CastSpell(S.LifeTap, "player")
            WarlockDebug("Refreshing Life Tap buff (combat)")
            return true
        end
    end
    
    -- Pet management in combat
    if inCombat and hasTarget then
        self:ManagePetAggro()
        self:HandleAutoAttack()
    end
    
    -- Find target if in combat without one
    if inCombat and not hasTarget then
        self:FindAndSetTarget()
    end
    
    -- No target = no offensive actions
    if not hasTarget then
        return false
    end
    
    local targetHP = UnitHealth("target") / UnitHealthMax("target") * 100
    
    -- Emergency defensives
    if health < 35 then
        if self:WarlockDefensives(health) then
            return true
        end
    end
    
    -- Mana management
    if mana < 30 then
        if self:ManageWarlockMana(health, mana) then
            return true
        end
    end
    
    -- Elite/boss detection
    local targetClassification = UnitClassification("target")
    local targetIsElite = targetClassification == "worldboss" or 
                         targetClassification == "rareelite" or 
                         targetClassification == "elite"
    
    -- Use racials and trinkets on elites
    if targetIsElite then
        self:UseWarlockRacials(targetIsElite)
        if self.UseTrinkets then 
            pcall(function() self:UseTrinkets() end)
        end
    end
    
    -- Execute spec-specific rotation
    if spec == "Affliction" then
        return self:AfflictionDpsRotation(level, targetHP, enemies)
    elseif spec == "Demonology" then
        return self:DemonologyDpsRotation(level, targetHP, enemies)
    elseif spec == "Destruction" then
        return self:DestructionDpsRotation(level, targetHP, enemies)
    else
        -- Basic rotation for unknown spec
        if self:IsUsableSpell(S.Corruption) and not self:HasDebuff("target", S.Corruption) then
            self:CastSpell(S.Corruption, "target")
            return true
        end
        
        if level >= 8 and self:ShouldUseCurse() and self:IsUsableSpell(S.CurseOfAgony) and not self:HasDebuff("target", S.CurseOfAgony) then
            self:CastSpell(S.CurseOfAgony, "target")
            return true
        end
        
        if self:IsUsableSpell(S.ShadowBolt) then
            self:CastSpell(S.ShadowBolt, "target")
            return true
        end
    end
    
    return false
end

-- ADDITIONAL FIX: Prevent spam in channeling check
function AC:IsBusyChanneling()
    -- Simple check without complex fallback logic
    local channelName = UnitChannelInfo and UnitChannelInfo("player")
    return channelName ~= nil
end