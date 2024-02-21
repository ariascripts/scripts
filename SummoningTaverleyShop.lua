--[[IMPORTANT: If you are using a portable deposit box, make sure your bank is full and:
    -contains the pouch you are making
    -does not contain any items that you don't want to deposit (i.e. spirit shards, the familiar's charm/secondary)
]]
--local API = require("libraries.api")
--local Shop = require("libraries.interfaces.Shop")
local API = require("api")
local Shop = require("Shop")

local SUMMONING_SHOP = WPOINT.new(2931, 3448, 0)

local familiars = {
    {
        name = "Geyser titan",
        level = 89,
        pouch_id = 12786,
        charm = "Blue charm",
        secondary = "Water talisman",
        secondary_unnoted = 1444,
        secondary_noted = 1445,
        sellMethod = true
    },
    {
        name = "Fire titan",
        level = 79,
        pouch_id = 12802,
        charm = "Blue charm",
        secondary = "Fire talisman",
        secondary_unnoted = 1442,
        secondary_noted = 1443,
        sellMethod = true
    },
    {
        name = "Spirit jelly",
        level = 55,
        pouch_id = 12027,
        charm = "Blue charm",
        secondary = "Jug of water",
        secondary_unnoted = 1937,
        secondary_noted = 1938,
        sellMethod = true
    },
}

local curr = familiars[1]

local function waitUntil(x, timeout)
    local start = os.time()
    while not x() and start + timeout > os.time() do
        API.RandomSleep2(300, 100, 100)
    end
    return start + timeout > os.time()
end

local function getDepositBoxes()
    return API.GetAllObjArrayInteract({ 10441, 75932, 2428 }, 10, 0)
end

local function getSelectedTab()
    return API.VB_FindPSettinOrder(303, 0).state
end

local function getCreationInterfaceSelectedItemID()
    return API.VB_FindPSettinOrder(1170, 0).state
end

local function getSelectedItemIndex()
    return API.VB_FindPSettinOrder(1031, 1).state
end

local function isCreationInterfaceOpen()
    return getCreationInterfaceSelectedItemID() ~= -1 and getCreationInterfaceSelectedItemID() ~= 2 ^ 31 - 1
end

local function distance(tile)
    if tile == nil then
        print("Distance called on nil tile")
        return 1000000007
    end

    local player = API.PlayerCoord()
    local x = player.x - tile.x
    local y = player.y - tile.y
    return math.sqrt(x * x + y * y)
end

API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    if API.InvItemcount_1(curr.pouch_id) > 0 then
        --[[local boxes = getDepositBoxes()
        if #boxes > 0 then
            if API.Compare2874Status(69, false) then
                API.DoAction_Interface(0x24,0xffffffff,1,11,5,-1,API.OFF_ACT_GeneralInterface_route) --deposit inventory button in portable deposit box
            else
                API.DoAction_Object1(0x29,0,{ boxes[1].Id },50)
            end
            API.RandomSleep2(300, 50, 50)
        else
            print("No boxes detected")
            API.RandomSleep2(600, 100, 100)
        end]]
        local vec = API.ReadInvArrays33()
        if getSelectedItemIndex() > 0 then
            print("Using notepaper on pouch")
            for i = 1, #vec do
                if vec[i].itemid1 == curr.pouch_id then
                    API.DoAction_Interface(0x24, vec[i].itemid1, 0, 1473, 5, vec[i].index,
                        API.OFF_ACT_GeneralInterface_route1)
                    API.RandomSleep2(600, 100, 100)
                    break
                end
            end
        else
            for i = 1, #vec do
                if vec[i].itemid1 > 0 and string.find(vec[i].textitem, "Magic notepaper") then
                    API.DoAction_Interface(0x24, vec[i].itemid1, 0, 1473, 5, vec[i].index,
                        API.OFF_ACT_Bladed_interface_route)
                    break
                end
            end
        end
    elseif distance(SUMMONING_SHOP) >= 1 then
        print("Walking next to obelisk")
        API.DoAction_Tile(SUMMONING_SHOP)
        API.RandomSleep2(600, 100, 100)
    elseif API.InvItemcount_1(curr.secondary_unnoted) >= 20 then
        if isCreationInterfaceOpen() then
            API.KeyboardPress32(0x20, 0) --press Space
            API.RandomSleep2(300, 300, 300)
        else
            print("Interacting with obelisk")
            if API.DoAction_Object1(0x29, 0, { 67036 }, 50) then
                API.RandomSleep2(600, 100, 100)
            end
        end
    elseif Shop.isOpen() then
        if getSelectedTab() == 0 then
            if Shop.contains(curr.secondary_unnoted) then
                print("Buying " .. curr.secondary)
                Shop.buyId(curr.secondary_unnoted, Shop.BUY_OPTIONS.ALL)
            else
                API.DoAction_Interface(0x24, 0xffffffff, 1, 1265, 32, -1, API.OFF_ACT_GeneralInterface_route) --switch to sell tab
            end
        else
            print("Selling " .. curr.secondary)
            if getSelectedTab() == 0 then
                API.DoAction_Interface(0x24, 0xffffffff, 1, 1265, 32, -1, API.OFF_ACT_GeneralInterface_route) --switch to sell tab
            else
                local items = API.ReadInvArrays33()
                local index = -2
                for i, item in ipairs(items) do
                    if item.itemid1 == curr.secondary_noted then
                        index = i - 1
                        break
                    end
                end
                if index == -2 then
                    return
                end

                API.DoAction_Interface(0xffffffff, 0xffffffff, 6, 1265, 20, index, API.OFF_ACT_GeneralInterface_route) --Sell 500
                API.RandomSleep2(300, 300, 300)
                API.DoAction_Interface(0x24, 0xffffffff, 1, 1265, 41, -1, API.OFF_ACT_GeneralInterface_route)    --switch to buy tab
                local f = function()
                    return getSelectedTab() == 0
                end
                waitUntil(f, 2)
            end
        end
    else
        if API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, { 14866 }, 50) then
            API.RandomSleep2(600, 100, 100)
        end
    end

    API.RandomSleep2(100, 100, 100)
end
