local this = {}
local config = require("mer.ashfall.config.config")
local conditions = require("mer.ashfall.config.conditionConfig")

this.tooltipColor = { 
    138 / 255, 
    201 / 255, 
    71 / 225
}
this.teaTypes = {}
--West Gash, Ashlands
this.teaTypes["ingred_bittergreen_petals_01"] = {
    teaName = "Bittergreen Tea",
    teaDescription = "The overbearing aroma of Bittergreen tea helps cleanse the mind of distracting thoughts.",
    effectDescription = "Fortify Magicka 15 Points",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_bittergreen",
        effects = {
            {
                id = tes3.effect.fortifyMagicka,
                amount = 20
            }
        }
    }
}

--Ascadian Isles, Azura's Coast
this.teaTypes["ingred_black_anther_01"] = { 
    teaName = "Black Anther Tea",
    teaDescription = "A popular drink among socialites and those who wish to stand out, Black Anther tea gives the skin a healthy, radiant glow.",
    effectDescription = "Light 5 Points on Self",
    priceMultiplier = 5.0,
    duration = 2,
    spell = {
        id = "ashfall_tea_anther",
        effects = {
            {
                id = tes3.effect.light,
                amount = 5
            }
        }
    }
}

--West Gash
this.teaTypes["ingred_chokeweed_01"] = { 
    teaName = "Chokeweed Tea",
    teaDescription = "Drinking Chokeweed tea helps to boost your immune system. Like any good medicine, it taste absolutely terrible.",
    effectDescription = "Resist Common Disease 30 Points",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_chokeweed",
        effects = {
            {
                id = tes3.effect.resistCommonDisease,
                amount = 30
            }
        }
    }
}


--Ascadian Isles, Azura's Coast
this.teaTypes["ingred_gold_kanet_01"] = { 
    teaName = "Gold Kanet Tea",
    teaDescription = "Tea brewed from the Gold Kanet flower is known to enhance one's strength.",
    effectDescription = "Fortify Strength 5 Points",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_goldKanet",
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.strength,
                amount = 5
            }
        }
    }
}


--Ascadian Isles
this.teaTypes["ingred_heather_01"] = {
    teaName = "Heather Tea",
    teaDescription = "Heather tea is a relaxing beverage that helps take the weight off your shoulders.",
    effectDescription = "Feather 20 Points",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_heather",
        effects = {
            {
                id = tes3.effect.feather,
                amount = 20
            }
        }
    }
}

--West Gash, Ascadian Isles, Azura's Coast, Sheogorad
this.teaTypes["ingred_stoneflower_petals_01"] = { 
    teaName = "Stoneflower Tea",
    teaDescription = "The pleasant, floral aroma of Stoneflower tea lingers on the breath longer after it is consumed.",
    effectDescription = "Fortify Speechcraft 10 Points",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_stoneflower",
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.speechcraft,
                amount = 10
            }
        }
    }
}


--Solstheim
this.teaTypes["ingred_belladonna_01"] = {
    teaName = "Belladonna Tea",
    teaDescription = "Belladonna berries make for a slighty bitter tea that provides a mild resistance against magicka.",
    effectDescription = "Resist Magicka 15 Points",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_bella",
        effects = {
            {
                id = tes3.effect.resistMagicka,
                amount = 15
            }
        }
    }
}

--Solstheim
this.teaTypes["ingred_belladonna_02"] = {
    teaName = "Belladonna Tea",
    teaDescription = "Belladonna berries make for a slighty bitter tea that provides a mild resistance against magicka. Unripened berries have a slightly weaker effect.",
    effectDescription = "Resist Magicka 10 Points",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_bella",
        effects = {
            {
                id = tes3.effect.resistMagicka,
                amount = 10
            }
        }
    }
}

--Bitter Coast
this.teaTypes["ingred_bc_coda_flower"] = {
    teaName = "Coda Flower Tea",
    teaDescription = "Tea made from the coda flower has a mild psychotropic effect that allows one to sense nearby lifeforms.",
    effectDescription = "Detect Animal 50 Points",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_coda",
        effects = {
            {
                id = tes3.effect.detectAnimal,
                amount = 50
            }
        }
    }
}

--Survival effects---------------


--Azura's Coast, West Gash, Sheogorad
this.teaTypes["ingred_kresh_fiber_01"] = {
    teaName = "Kreshweed Tea",
    teaDescription = "Kreshweed tea is a powerful laxative, making it an effective cure for food poisoning.",
    effectDescription = "Cures Food Poisoning",
    priceMultiplier = 5.0,
    onCallback = function()
        conditions.foodPoison:setValue(conditions.foodPoison:getValue() - 50)
    end
}

--West Gash - exclusively
this.teaTypes["ingred_roobrush_01"] = {
    teaName = "Roobrush Tea",
    teaDescription = "Roobrush tea has a smooth, slightly nutty flavor, and is used as a cure for dysentery.",
    effectDescription = "Cures Dysentery",
    priceMultiplier = 5.0,
    onCallback = function()
        conditions.dysentery:setValue(conditions.dysentery:getValue() - 50)
    end
}

--Ascadian Isles - exclusively - used for alcohol
this.teaTypes["ingred_comberry_01"] = { 
    teaName = "Comberry Tea",
    teaDescription = "A tea brewed from comberries is a well known home remedy for the flu.",
    effectDescription = "Cures the Flu",
    priceMultiplier = 5.0,
    onCallback = function()
        conditions.flu:setValue(conditions.flu:getValue() - 50)
    end,
}

--Ashlands, dry regions
this.teaTypes["ingred_scathecraw_01"] = { 
    teaName = "Scathecraw Tea",
    teaDescription = "Scathecraw Tea provides a modest resistance against blight disease.",
    effectDescription = "Resist Blight 40 Points",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_scathecraw",
        effects = {
            {
                id = tes3.effect.resistBlightDisease,
                amount = 40
            }
        }
    }
}


--Ashlands, Molar Amur
this.teaTypes["ingred_fire_petal_01"] = {
    teaName = "Fire Petal Tea",
    teaDescription = "Fire Petal tea is a spicy beverage that helps keep one warm on cold nights.",
    effectDescription = "Reduce Cold Weather Effects by 20%",
    priceMultiplier = 5.0,
    duration = 4,
    onCallback = function()
        tes3.player.data.Ashfall.firePetalTeaEffect = 0.80
    end,
    offCallback = function()
        tes3.player.data.Ashfall.firePetalTeaEffect = nil
    end,
}

--Solstheim
this.teaTypes["ingred_holly_01"] = { 
    teaName = "Holly Tea",
    teaDescription = "A sweet, fragrant tea often served in Solstheim for its ability to stave off the cold.",
    effectDescription = "Reduce Cold Weather Effects by 10%",
    priceMultiplier = 5.0,
    duration = 4,
    onCallback = function()
        tes3.player.data.Ashfall.hollyTeaEffect = 0.9
    end,
    offCallback = function()
        tes3.player.data.Ashfall.hollyTeaEffect = nil
    end,
}



--Grazelands    
this.teaTypes["ingred_hackle-lo_leaf_01"] = {
    teaName = "Hackle-lo Tea",
    teaDescription = "Hackle-lo tea increases energy and alertness, allowing one to stay awake for longer.",
    effectDescription = "Tiredness Gain Reduced by 25%",
    priceMultiplier = 5.0,
    duration = 5,
    onCallback = function()
        tes3.player.data.Ashfall.hackloTeaEffect = 0.75
    end,
    offCallback = function()
        tes3.player.data.Ashfall.hackloTeaEffect = nil
    end
}

--Ashlands, Molag Amur, 
this.teaTypes["ingred_trama_root_01"] = {
    teaName = "Trama Root Tea",
    teaDescription = "Trama Root tea is dark and bitter. The Ashlanders drink this tea for its calming effects.",
    effectDescription = "1.5x Sleep Recovery",
    priceMultiplier = 5.0,
    duration = 8,
    onCallback = function()
        tes3.player.data.Ashfall.tramaRootTeaEffect = 1.5
    end,
    offCallback = function()
        tes3.player.data.Ashfall.tramaRootTeaEffect = nil
    end
}

this.teaTypes["ingred_moon_sugar_01"] = {
    teaName = "Moon Sugar Coffee",
    teaDescription = "While not as potent as Skooma, a coffee made with Moon Sugar will make one feel awake and alert. Be warned however, you may find yourself exhausted once the effect wears off.",
    effectDescription = "Well Rested Effect",
    priceMultiplier = 5.0,
    duration = 4,
    onCallback = function()
        local currentTiredness = conditions.tiredness:getValue()
        tes3.player.data.Ashfall.coffeePrevTiredness = currentTiredness
        conditions.tiredness:setValue(0)
    end,
    offCallback = function()
        local previousTiredness = tes3.player.data.Ashfall.coffeePrevTiredness
        if previousTiredness then
            local sleepLossRate = config.getConfig().loseSleepRate
            local penalty = sleepLossRate * tes3.player.data.Ashfall.teaBuffTimeLeft * 0.8
            conditions.tiredness:setValue( previousTiredness + penalty)
            tes3.player.data.Ashfall.coffeePrevTiredness = nil
        end
    end
}











--Mournhold teas----------------

--Mournhold
this.teaTypes["Ingred_golden_sedge_01"] = {
    teaName = "Golden Sedge Tea",
    teaDescription = "A favourite among fighters, Golden Sedge tea increases attack power.",
    effectDescription = "Fortify Attack Power 10 Points",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_goldSedge",
        effects = {
            {
                id = tes3.effect.fortifyAttack,
                amount = 10
            }
        }
    }
}

--Mournhold
this.teaTypes["Ingred_meadow_rye_01"] = { 
    teaName = "Meadow Rye Tea",
    teaDescription = "Tea brewed from Meadow Rye acts as a powerful stimulant, increasing one's speed.",
    effectDescription = "Fortify Speed 5 Points",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_meadowRye",
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.speed,
                amount = 5
            }
        }
    }
}

--Mournhold
this.teaTypes["Ingred_noble_sedge_01"] = {
    teaName = "Noble Sedge Tea",
    teaDescription = "A rare beverage, prized among Acrobats, the Noble Sedge tea improves one's Agility.",
    effectDescription = "Fortify Agility 10 Points",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_nobleSedge",
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.agility,
                amount = 10
            }
        }
    }
}

--Mournhold
this.teaTypes["Ingred_timsa-come-by_01"] = {
    teaName = "Timsa-come-by Tea",
    teaDescription = "Tea brewed from this rare plant makes one highly resistant to paralysis.",
    effectDescription = "Resist Paralysis 40 Points",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_timsa",
        effects = {
            {
                id = tes3.effect.resistParalysis,
                amount = 40
            }
        }
    }
}


this.validTeas = {}
for ingredId, _ in pairs(this.teaTypes) do
    --if tes3.getObject(ingredId) then
        table.insert(this.validTeas, ingredId)
    --end
end



return this