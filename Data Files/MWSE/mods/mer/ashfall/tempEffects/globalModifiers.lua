local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier{ id = "globalColdEffect", coldOnly = true }
temperatureController.registerBaseTempMultiplier{ id = "globalWarmEffect", warmOnly = true }