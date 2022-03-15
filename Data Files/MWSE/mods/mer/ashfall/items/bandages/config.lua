local config = {}

config.bodyParts = {
    leftWrist = 8,
    rightWrist = 9,
    leftUpper = 13,
    rightUpper = 14,
}

config.bandageParts = {
	[config.bodyParts.leftUpper] = "ashfall_bandage_ua",
	[config.bodyParts.rightUpper] = "ashfall_bandage_ua",
    [config.bodyParts.leftWrist] = "ashfall_bandage_wrist",
    [config.bodyParts.rightWrist] = "ashfall_bandage_wrist",
}

return config