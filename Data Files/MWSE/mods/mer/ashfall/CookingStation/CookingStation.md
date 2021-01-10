# Cooking Station Mechanics

Objects such as campfires, ovens, grills etc are considered "cooking stations". 

The cooking station code is the base code which implements the following mechanics:

* Menu and UI
* Visuals management
    * This is the tricky part. Campfires have a bunch of unique visuals
* Adding fuel
* Cooking mechanics
    * Grilling
    * Stewing


Visuals management may have to be station specific

## Modules

* State management
    * Fire events for state change
* Visuals management
    * Consume state change events and update only visuals that need updating
* Confuguration
    * Nif file
    * Placed indoors/outdoors
    * Can Grill/stew
    * Can attach grill/supports/cooking pot
* Heat
* Menu
* Mechanics
    * Base object has only fuel/heat mechanics
    * Instances of an object can add mechanics such as grilling, stewing


Base station functionality:
    * Add fuel
    * Provide warmth
    * Menu 