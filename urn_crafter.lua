--[[
    @name Urn Crafter
    @description Crafts Decorated Urns
    @author Aria
    @version 1.0
]]

local API = require("api")
local CreationInterface = require("libraries.CreationInterface")
local Bank = require("libraries.bank")

--change the ids and category to any of the urns below if you want to skip selecting the urn each time you start the script
local unfiredUrnId, finishedUrnId = -1, -1
local urnCategory = ""
local clayPresetNum = 2 --preset loaded to withdraw soft clay, must have 28 soft clay
--Example:
--local unfiredUrnId, finishedUrnId = 20343, 20344
--local urnCategory = "Fishing Urns"

--don't modify anything below this line unless you know what you're doing
local BANK_CHEST_ID = 125115
local bankingTries = 0

local URNS = {
    { name = "Decorated Fishing",      category = "Fishing Urns",      unfired = 20343, fired = 20344 },
    { name = "Decorated Cooking",      category = "Cooking Urns",      unfired = 20373, fired = 20374 },
    { name = "Decorated Mining",       category = "Mining Urns",       unfired = 20403, fired = 20404 },
    { name = "Decorated Woodcutting",  category = "Woodcutting Urns",  unfired = 39008, fired = 39010 },
    { name = "Decorated Divination",   category = "Divination Urns",   unfired = 40796, fired = 40798 },
    { name = "Decorated Farming",      category = "Farming Urns",      unfired = 40836, fired = 40838 },
    { name = "Decorated Hunter",       category = "Hunter Urns",       unfired = 40876, fired = 40878 },
    { name = "Decorated Runecrafting", category = "Runecrafting Urns", unfired = 40916, fired = 40918 },
    { name = "Decorated Smelting",     category = "Smelting Urns",     unfired = 44766, fired = 44768 },
    { name = "Infernal",               category = "Prayer Urns",       unfired = 20421, fired = 20422 },
}

local startXp = API.GetSkillXP("CRAFTING")
local lastXp = startXp
local lastTimeGainedXp = os.time()

local function resetStats()
    startXp = API.GetSkillXP("CRAFTING")
    lastXp = startXp
    lastTimeGainedXp = os.time()
end

local function checkExpGain()
    local currentXp = API.GetSkillXP("CRAFTING")
    if currentXp > lastXp then
        lastXp = currentXp
        lastTimeGainedXp = os.time()
    end
end

local function waitUntil(x, timeout)
    local start = os.time()
    while not x() and start + timeout > os.time() do
        API.RandomSleep2(300, 100, 200)
    end
    return start + timeout > os.time()
end

local comboBoxSelect = API.CreateIG_answer()

local function setupOptions()
    comboBoxSelect.box_name = "Urns"
    comboBoxSelect.box_start = FFPOINT.new(1, 60, 0)
    comboBoxSelect.stringsArr = {}
    comboBoxSelect.box_size = FFPOINT.new(440, 0, 0)

    table.insert(comboBoxSelect.stringsArr, "Select an urn")

    for i, option in ipairs(URNS) do
        table.insert(comboBoxSelect.stringsArr, option.name)
    end

    API.DrawComboBox(comboBoxSelect, false)
end

if unfiredUrnId == -1 then
    setupOptions()
end

local function interactCrafter()
    local crafterConfig = (API.VB_FindPSettinOrder(6451).state & 3072) >> 10
    --print("[Debug] Curr crafter configuration: " .. crafterConfig)
    local offset = API.OFF_ACT_GeneralObject_route0
    if crafterConfig == 0 or crafterConfig == 1 then --left click = craft/gems
        offset = API.OFF_ACT_GeneralObject_route2
    elseif crafterConfig == 3 then --left click = leather
        offset = API.OFF_ACT_GeneralObject_route3
    end

    print("Interacting with crafter")
    API.DoAction_Object1(0x29, offset, { 106594, 106595, 106596, 106597 }, 5)
    waitUntil(API.Check_Dialog_Open, 5)
end

API.SetDrawTrackedSkills(true)
API.Write_LoopyLoop(true)
while (API.Read_LoopyLoop()) do
    if (comboBoxSelect.return_click) then
        comboBoxSelect.return_click = false

        for i, urn in ipairs(URNS) do
            if (comboBoxSelect.string_value == urn.name) then
                print("Chose urn: ", urn.name, "index: ", i)
                urnCategory = urn.category
                unfiredUrnId = urn.unfired
                finishedUrnId = urn.fired
                resetStats()
            end
        end
    end

    checkExpGain()
    API.DoRandomEvents()

    if (os.time() - lastTimeGainedXp) > 60 then
        print("No experience gained in the last 60 seconds, stopping script")
        API.Write_LoopyLoop(false)
    elseif API.isProcessing() then
        API.RandomSleep2(600, 50, 100)
        bankingTries = 0
    elseif unfiredUrnId == -1 then
        print("Waiting for user to select urn")
        API.RandomSleep2(600, 50, 100)
    elseif Inventory:GetItemAmount(unfiredUrnId) >= 28 then
        if CreationInterface.isOpen() then
            if CreationInterface.selectAndProcess(finishedUrnId, urnCategory) then
                waitUntil(API.isProcessing, 5)
            end
        elseif API.Check_Dialog_Open() then
            API.KeyboardPress32(0x32, 0) --select fire urns
            waitUntil(CreationInterface.isOpen, 5)
        else
            interactCrafter()
        end
    elseif Inventory:GetItemAmount(1761) >= 28 then
        if CreationInterface.isOpen() then
            if CreationInterface.selectAndProcess(unfiredUrnId, urnCategory) then
                waitUntil(API.isProcessing, 5)
            end
        elseif API.Check_Dialog_Open() then
            API.KeyboardPress32(0x31, 0) --select mold urns
            waitUntil(CreationInterface.isOpen, 5)
        else
            interactCrafter()
        end
    elseif API.BankOpen2() then
        if Bank.getCount(unfiredUrnId) >= 28 then
            print("Withdrawing unfired urn")
            Bank.depositInventory()
            API.RandomSleep2(600, 100, 600)
            Bank.withdrawAll(unfiredUrnId)
            API.RandomSleep2(1800, 100, 2000)
        elseif Bank.getCount("Soft clay") >= 28 then
            print("Loading preset to withdraw soft clay: " .. clayPresetNum)
            Bank.loadPreset(clayPresetNum)
            API.RandomSleep2(1800, 100, 2000)
        else
            print("Failed to find soft clay, closing and reopening bank")
            bankingTries = bankingTries + 1
            Bank.close()
            API.RandomSleep2(1800, 100, 2000)
            if bankingTries >= 3 then
                print("Failed to find soft clay 3 times, stopping script")
                API.Write_LoopyLoop(false)
            end
        end
    else
        print("Opening bank")
        if API.DoAction_Object1(0x2e, API.OFF_ACT_GeneralObject_route1, { BANK_CHEST_ID }, 5) then
            print("Waiting for bank open")
            waitUntil(API.BankOpen2, 5)
        end
    end

    API.RandomSleep2(100, 10, 20)
end

