local this = {}

this.guids = {
    MenuDialog = tes3ui.registerID("MenuDialog"),
    MenuDialog_disposition = tes3ui.registerID("MenuDialog_disposition"),
    MenuDialog_WaterService = tes3ui.registerID("MenuDialog_service_WaterService"),
    MenuDialog_merchant_buttonBlock = tes3ui.registerID("MenuDialog_merchant_buttonBlock"),
    MenuDialog_StewService = tes3ui.registerID("MenuDialog_service_StewService")
}

function this.getDialogMenu()
    return tes3ui.findMenu(this.guids.MenuDialog)
end

function this.getMerchantObject()
    local menuDialog = this.getDialogMenu()
    if not menuDialog then return end

    local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
    if not merchant then return end

    return merchant.object
end

function this.getButtonBlock()
    local menu = tes3ui.findMenu(this.guids.MenuDialog)
    if not menu then return end
    local buttonBlock = menu:findChild(this.guids.MenuDialog_merchant_buttonBlock)
    if not buttonBlock then
        local parent = menu:findChild(this.guids.MenuDialog_disposition).parent
        buttonBlock = parent:createThinBorder{ id = this.guids.MenuDialog_merchant_buttonBlock }
        buttonBlock.autoHeight = true
        buttonBlock.widthProportional = 1
        buttonBlock.paddingAllSides = 4
        buttonBlock.borderAllSides = 4
        buttonBlock.borderBottom = -1
        buttonBlock.flowDirection = "top_to_bottom"
        buttonBlock.parent:reorderChildren(1, -1, 1)
    end
    return buttonBlock
end

return this