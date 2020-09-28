local this = {}
this.warmth = { 
    multiplier = 0.40,
    --multiplier = 1.0,
    armor = {
        default = 35,
        enchanted = 40,
        values = {
            ['Adamantium '] = 20,
            ['Bear '] = 100,
            ['Bonemold '] = 35,
            ['Chitin '] = 30,
            ['Cloth '] = 50,
            ['Daedric '] = 70,
            ['Dark B'] = 35,
            ['Dreugh '] = 30,
            ['Dwemer '] = 20,
            ['Ebony '] = 35,
            ['Fire '] = 100,
            ['Frost '] = 0,
            ['Glass '] = 10,
            ['Gondolier'] = 20,
            ['Her Hand'] = 30,
            ['Ice Armor '] = 0,
            ['Imperial Chain'] = 20,
            ['Imperial Silv'] = 25,
            ['Imperial Steel'] = 30,
            ['Imperial Templ '] = 35,
            ['Indoril '] = 40,
            ['Iron '] = 15,
            ['Netch '] = 45,
            ['Fur '] = 80,
            [' Fur'] = 80,
            ['Nordic Mail'] = 70,
            ['Nordic Ring'] = 60,
            ['Nordic Troll'] = 65,
            ['Nordic Iron'] = 75,
            ['Nordic Leather'] = 70,
            ['Nordic Bearskin'] = 80,
            ['Orcich'] = 25,
            ['Redoran'] = 30,
            ['Royal G'] = 35,
            ['Slave'] = 25,
            ['Steel'] = 20,
            ['Telvanni '] = 60,
            ['Wolf '] = 100
        },
    },
    clothing = {
        default = 60,
        enchanted = 80,
        values = {
            ['Common '] = 40,
            ['Expensive '] = 50,
            ['Extravagant '] = 60,
            ['Exquisite '] = 70,
            ['Fire'] = 100,
            ['Flame'] = 100,
            ['Frost'] = 0
        }
    },
}

this.bodyParts = {
    head = 0.10,
    leftArm = 0.05,
    rightArm = 0.05,
    leftWrist = 0.05,
    rightWrist = 0.05,
    leftHand = 0.10,
    rightHand = 0.10,
    chest = 0.20,
    legs = 0.20,
    feet = 0.10,
    back = 0.05
}

this.armorPartMapping = {
    [tes3.armorSlot.helmet] = { "head" },
    [tes3.armorSlot.cuirass] = { "chest" },
    [tes3.armorSlot.leftPauldron] = { "leftArm" },
    [tes3.armorSlot.rightPauldron] = { "rightArm" },
    [tes3.armorSlot.greaves] = { "legs" },
    [tes3.armorSlot.boots] =  { "feet" },
    [tes3.armorSlot.leftGauntlet] =  { "leftHand" },
    [tes3.armorSlot.rightGauntlet] =  { "rightHand" },
    [tes3.armorSlot.leftBracer] =  { "leftWrist" },
    [tes3.armorSlot.rightBracer] =  { "rightWrist" },
    [11] = { "back" }--backpack
}

this.clothingPartMapping = {
    [tes3.clothingSlot.pants] = { "legs" },
    [tes3.clothingSlot.shoes] = { "feet" },
    [tes3.clothingSlot.shirt] = { "chest", "leftArm", "rightArm", "leftWrist", "rightWrist" },
    [tes3.clothingSlot.robe] = { "chest", "legs", "leftArm", "rightArm" },
    [tes3.clothingSlot.rightGlove] = { "leftHand", "leftWrist" },
    [tes3.clothingSlot.leftGlove] = { "rightHand", "rightWrist" },
    [tes3.clothingSlot.skirt] = { "legs" },
}

return this