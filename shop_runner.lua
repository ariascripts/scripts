--[[
    @name Shop runner
    @description A demonstration of the shop library that purchases runes from three shops
    @author Aria
    @version 1.0

    @note Set the buy warning value to a high number (found in Settings -> Gameplay -> Interfaces -> Warning Screens), or the script will get stuck on the warning screen
]]

local API = require("api")
local SHOP = require("shop")
local LODESTONES = require("lodestones")

--Elemental runes, body, chaos, soul, nature, earth, astral
local desiredItemIds = { 556, 555, 557, 554, 559, 562, 561, 566, 9075 }
local desiredItemTable = {} 
for _, id in ipairs(desiredItemIds) do
    desiredItemTable[id] = true
end

local NPCS = {
    BABA_YAGA = 4513,
    BABA_YAGA_HOUSE = 4512,
    CLARA = 14906,
    ANACHRONIA_RUNE_SELLER = 26413
}

local SHOP_STATUS = {
    BABA_YAGA = false,
    CLARA = false,
    ANACHRONIA = true
}

local minQuantityToBuy = 1

local function waitUntil(x, timeout)
    start = os.time()
    while not x() and start + timeout > os.time() do
        API.RandomSleep2(600, 200, 200)
    end
    return start + timeout > os.time()
end

--Buys all the items in a shop that we want if they have at least `minQuantityToBuy` in stock
--Returns whether we've finished buying items
local function buyItems() 
    shop_items = SHOP.getItems()
    local finishedBuying = true
    local lastItemIndex = -1

    for i, item in ipairs(shop_items) do
        if desiredItemTable[item.itemid1] and item.itemid1_size >= minQuantityToBuy then
            --LUA arrays start at 1, while Java arrays start at 0, so subtract 1 to get the item's index in the shop
            print("Buying item: ", item.itemid1)
            SHOP.buyItem(i - 1, SHOP.BUY_OPTIONS.ALL)
            finishedBuying = false
            lastItemIndex = i - 1
        end
    end

    --Wait for the stock to update
    if lastItemIndex ~= -1 then
        local f = function()
            return SHOP.getStackSize(lastItemIndex) == 0
        end
        waitUntil(f, 5)
    end

    return finishedBuying
end

--Teleport to Lunar Isle lodestone (ALT + L) and run north to Baba Yaga's Magic Shop, buy all runes except Law and Chaos runes
local function buyBabaYaga() 
    local inBabaYagaHouse = function()
        return #API.GetAllObjArrayInteract({ NPCS.BABA_YAGA }, 10, 1) > 0
    end

    if inBabaYagaHouse() then
        if not SHOP.isOpen() then
            print("Interacting with Baba Yaga")
            if API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ NPCS.BABA_YAGA }, 100) then
                waitUntil(SHOP.isOpen, 5)
            end
        else
            if buyItems() then
                print("Finished buying from Baba Yaga")
                SHOP_STATUS.BABA_YAGA = false
            end
        end
    elseif #API.GetAllObjArrayInteract({ NPCS.BABA_YAGA_HOUSE }, 100, 1) > 0 then
        print("Entering Baba Yaga's house")
        if API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,{ NPCS.BABA_YAGA_HOUSE }, 100) then
            waitUntil(inBabaYagaHouse, 30)
        end
    else 
        LODESTONES.LunarIsle()
    end
end

local function buyClara()
    if #API.GetAllObjArrayInteract({ NPCS.CLARA }, 100, 1) > 0 then
        if not SHOP.isOpen() then
            print("Interacting with Clara")
            if API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ NPCS.CLARA }, 100) then
                waitUntil(SHOP.isOpen, 30)
            end
        else
            if buyItems() then
                print("Finished buying from Clara")
                SHOP_STATUS.CLARA = false
            end
        end
    else 
        LODESTONES.Burthope()
    end
end

local function buyAnachronia()
    if #API.GetAllObjArrayInteract({ NPCS.ANACHRONIA_RUNE_SELLER }, 100, 1) > 0 then
        if not SHOP.isOpen() then
            print("Interacting with Anachronia rune seller")
            if API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,{ NPCS.ANACHRONIA_RUNE_SELLER }, 100) then
                waitUntil(SHOP.isOpen, 30)
            end
        else
            if buyItems() then
                print("Finished buying from Anachronia")
                SHOP_STATUS.ANACHRONIA = false
            end
        end
    else 
        LODESTONES.Anachronia()
    end
end

API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    API.DoRandomEvents()

    --Note that the shop status will reset if this script is terminated, which will cause the script to go back to shops it previously visited
    if SHOP_STATUS.BABA_YAGA then
        buyBabaYaga()
    elseif SHOP_STATUS.CLARA then
        buyClara()
    elseif SHOP_STATUS.ANACHRONIA then
        buyAnachronia()
    else
        print("Finished buying from all supported shops")
        API.Write_LoopyLoop(false)
    end

    API.RandomSleep2(100, 100, 100)
end
