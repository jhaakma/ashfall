local this = {}
this.warmth = { 
    multiplier = 0.40,
    --multiplier = 1.0,
    armor = {
        default = 35,
        enchanted = 40,
        values = {
            ['adamantium '] = 20,
            ['bear '] = 100,
            ['bonemold '] = 35,
            ['chitin '] = 30,
            ['cloth '] = 50,
            ['daedric '] = 70,
            ['dark b'] = 35,
            ['dreugh '] = 30,
            ['dwemer '] = 20,
            ['ebony '] = 35,
            ['fire '] = 100,
            ['frost '] = 0,
            ['glass '] = 10,
            ['gondolier'] = 20,
            ['her hand'] = 30,
            ['ice armor '] = 0,
            ['imperial chain'] = 20,
            ['imperial silv'] = 25,
            ['imperial steel'] = 30,
            ['imperial templ '] = 35,
            ['indoril '] = 40,
            ['iron '] = 15,
            ['netch '] = 45,
            ['fur '] = 80,
            [' fur'] = 80,
            ['nordic mail'] = 70,
            ['nordic ring'] = 60,
            ['nordic troll'] = 65,
            ['nordic iron'] = 75,
            ['nordic leather'] = 70,
            ['nordic bearskin'] = 80,
            ['orcich'] = 25,
            ['redoran'] = 30,
            ['royal g'] = 35,
            ['slave'] = 25,
            ['steel'] = 20,
            ['telvanni '] = 60,
            ['wolf '] = 100
        },
    },
    clothing = {
        default = 60,
        enchanted = 80,
        values = {
            ['common '] = 40,
            ['expensive '] = 50,
            ['extravagant '] = 60,
            ['exquisite '] = 70,
            ['fire'] = 100,
            ['flame'] = 100,
            ['frost'] = 0
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
    [11] = { "back" }--backpack
}

return this