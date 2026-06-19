--[[
    @name Alpha Portables
    @description Automates tasks at portable skilling stations (ideally at W84 Fort Forinthry)
    @author Aria
    @version 1.31
]]

local API = require("api")

API.SetDrawTrackedSkills(true)
--make sure the left click option is configured to be the one you want for portables with a "Configure" option
local SCENE_OBJECTS = {
    WORKBENCH = 117926,
    FLETCHER = 106599, --might also be 106598?
    RANGE = 89768,
    WELL = 89770,
    CRAFTER = 106595,
    BRAZIER = 106601, --could also be 106602

    BANK_CHEST = 125115, --Fort Forinthry bank chest
    WORKROOM_BANK_CHEST = 125734 --Fort Forinthry workroom bank chest
}
local allSkills = {"ATTACK", "STRENGTH", "RANGED", "DEFENCE", "CONSTITUTION", "PRAYER", "SUMMONING", "DUNGEONEERING", "AGILITY", "MAGIC",
     "THIEVING", "SLAYER", "HUNTER", "SMITHING", "CRAFTING", "FLETCHING", "HERBLORE", "RUNECRAFTING", "COOKING",
    "CONSTRUCTION", "FIREMAKING", "WOODCUTTING", "FARMING", "FISHING", "MINING", "DIVINATION", "INVENTION", "ARCHAEOLOGY", "NECROMANCY"}

local PORTABLES = {
    {id = SCENE_OBJECTS.WORKBENCH, action = 0x29, skill = "CONSTRUCTION"},
    {id = SCENE_OBJECTS.FLETCHER, action = 0x29, skill = "FLETCHING"},
    {id = SCENE_OBJECTS.RANGE, action = 0x40, skill = "COOKING"},
    {id = SCENE_OBJECTS.WELL, action = 0x29, skill = "HERBLORE"},
    {id = SCENE_OBJECTS.CRAFTER, action = 0x29, skill = "CRAFTING"},
    {id = SCENE_OBJECTS.BRAZIER, action = 0x29, skill = "FIREMAKING"}
}

--#region Optional user settings, don't modify this if you don't know what you're doing
local loadPresetKey = 0x32 --The 2 key
--Change this value to 1 = workbench, 2 = fletcher, 3 = range, 4 = well, 5 = crafter, 6 = brazier if you don't want to have to select the portable you're using each time
local chosenPortable = -1

--add the ids of the items you are processing to the table below, click "Inv" in the debug menu to view the ids of the items in the inventory
local ID = {
    RAW_GREEN_JELLYFISH = 42256,

    SUPER_RANGING = 169,
    GRENWALL_SPIKES = 12539,

    UNCUT_DRAGONSTONE = 1631,

    ASCENSION_SHARD = 28436,

    PROTEAN_PLANK = 30037,
}

--Add the items you are processing to the list below
--If the list is empty, the script will stop after 30 seconds without gaining exp or if you run out of any of the items that were in the inventory when starting the script
local itemList = {}
--Example for cooking raw green jellyfish
--itemList[1] = { id = ID.RAW_GREEN_JELLYFISH, amount = 28 }

--#endregion

if chosenPortable == -1 then
    print("Please select the portable station you want to use")
end

if not itemList[1] then
    print("Empty item list detected, attempting to get the items being processed from your inventory")

    local added = {}
    local vec = API.ReadInvArrays33()
    for i = 1, #vec do
      if vec[i].itemid1 and not added[vec[i].itemid1] and vec[i].itemid1 > 0 and vec[i].itemid1_size > 0 then
        --local amt = vec[i].itemid1_size
        --itemList[#itemList + 1] = { id = vec[i].itemid1, amount = amt }
        --print("Added item: " .. vec[i].textitem .. " (" .. vec[i].itemid1 .. ") with amount " .. amt)
        itemList[#itemList + 1] = { id = vec[i].itemid1, amount = 1 }
        print("Added item: " .. vec[i].textitem .. " (" .. vec[i].itemid1 .. ") with default amount of 1")
        added[vec[i].itemid1] = true
      end
    end
end

--old inventory item loading logic
local function initInvItems()
    print("Clearing itemList before initializing items")
    itemList = {}
    print("itemList cleared")

    local added = {}
    local vec = API.ReadInvArrays33()
    for i = 1, #vec do
      if vec[i].itemid1 and not added[vec[i].itemid1] and vec[i].itemid1 > 0 and vec[i].itemid1_size > 0 then
        local amt = vec[i].itemid1_size
        itemList[#itemList + 1] = { id = vec[i].itemid1, amount = amt }
        print("Added item: " .. vec[i].textitem .. " (" .. vec[i].itemid1 .. ") with amount " .. amt)
        added[vec[i].itemid1] = true
      end
    end
end

local portableOptions = { "Workbench", "Fletcher", "Range", "Well", "Crafter", "Brazier" }

local MAX_IDLE_TIME_MINUTES = 5
local MAX_TIME_WITHOUT_EXP = 30 --stop script if more than X seconds have elapsed without gaining exp while a portable exists
local MAX_TIME_WITHOUT_PORTABLE = 300 --stop script if more than Y seconds have elapsed without a portable existing
local startXp = 0
local lastXp = startXp
local afk = os.time()
local lastTimeGainedXp = os.time()
local lastTimePortableExisted = os.time()

local function getTotalExp()
    local xp = 0
    for _, skill in ipairs(allSkills) do
        xp = xp + API.GetSkillXP(skill)
    end
    return xp
end

local function resetStats()
    startXp = getTotalExp()
    lastXp = startXp
    afk = os.time()
    lastTimeGainedXp = os.time()
end

--credit Higgins
local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function updateExp()
    local currentXp = getTotalExp()
    if currentXp > lastXp then
        lastXp = currentXp
        lastTimeGainedXp = os.time()
    end
end

local initItemListButton = API.CreateIG_answer();
initItemListButton.box_name = "Init Inventory Items";
initItemListButton.box_start = FFPOINT.new(1, 60, 0);
initItemListButton.box_size = FFPOINT.new(200, 30, 0);
API.DrawBox(initItemListButton)

local comboBoxSelect = API.CreateIG_answer()

local function setupOptions()
    comboBoxSelect.box_name = "Portables"
    comboBoxSelect.box_start = FFPOINT.new(1,80,0)
    comboBoxSelect.stringsArr = {}
    comboBoxSelect.box_size = FFPOINT.new(440, 0, 0)

    table.insert(comboBoxSelect.stringsArr, "Select an option")

    for i, option in ipairs(portableOptions) do
        table.insert(comboBoxSelect.stringsArr, option)
    end

    API.DrawComboBox(comboBoxSelect, false)
end

if chosenPortable == -1 then
    setupOptions()
else
    resetStats()
end

local function waitUntil(x, timeout)
    local start = os.time()
    while not x() and start + timeout > os.time() do
        API.RandomSleep2(300, 50, 50)
    end
    return start + timeout > os.time()
end

local function getCreationInterfaceSelectedItemID()
    return API.VB_FindPSett(1170).state
end

local function creationInterfaceOpen()
    return getCreationInterfaceSelectedItemID() ~= -1
end

local function notInBank()
    return not API.BankOpen2()
end

local function loadPreset()
    print("Loading preset")
    API.KeyboardPress32(loadPresetKey, 0)
    waitUntil(notInBank, 5)
end

--Checks whether we have at least `amount` of each item
local function hasAllItems()
    for i = 1, #itemList do
        if itemList[i].id == nil then
            print("Error: undefined item id: probably didn't add the item's id to the ID table, stopping script")
            API.Write_LoopyLoop(false)
            return false
        end
        if Inventory:GetItemAmount(itemList[i].id) < itemList[i].amount and Inventory:InvStackSize(itemList[i].id) < itemList[i].amount then
            print("Not enough of item:", itemList[i].id)
            return false
        end
    end
    return true
end

API.Write_LoopyLoop(true)
while (API.Read_LoopyLoop()) do
    idleCheck()

    if (comboBoxSelect.return_click) then
        comboBoxSelect.return_click = false

        for i, option in ipairs(portableOptions) do
            if (comboBoxSelect.string_value == option and chosenPortable ~= i) then
                print("Chose portable: ", option, "index: ", i)
                chosenPortable = i
                resetStats()
            end
        end
    end

    if initItemListButton.return_click then
        initInvItems()
        initItemListButton.return_click = false
    end

    if chosenPortable ~= -1 then
        updateExp()
        API.DoRandomEvents()

        --stop script if no exp gained in the past 30s
        if (os.time() - lastTimeGainedXp) > MAX_TIME_WITHOUT_EXP then
            print("No exp gained in the last " .. MAX_TIME_WITHOUT_EXP .. " seconds")
            API.Write_LoopyLoop(false)
        elseif API.isProcessing() or (PORTABLES[chosenPortable].id == SCENE_OBJECTS.BRAZIER and API.CheckAnim(200)) then
            API.RandomSleep2(600, 50, 100)
        elseif hasAllItems() then
            if API.BankOpen2() then
                loadPreset()
            else
                --The script currently doesn't validate whether the selected item in the creation interface is the correct item
                --which could be a problem if there are multiple items that use the same ingredients i.e. urns
                print("Interacting with portable")
                if API.DoAction_Object1(PORTABLES[chosenPortable].action, API.OFF_ACT_GeneralObject_route0, { PORTABLES[chosenPortable].id }, 5) then
                    lastTimePortableExisted = os.time()
                    if PORTABLES[chosenPortable].id == SCENE_OBJECTS.BRAZIER then
                        print("Waiting for animation")
		                API.RandomSleep2(1000, 50, 100)
                    else
                        print("Waiting for creation interface")
                        if waitUntil(creationInterfaceOpen, 5) then
                            API.KeyboardPress32(0x20,0) --press Space
                            print("Waiting for processing to begin")
                            waitUntil(API.isProcessing, 5)
                        end
                    end
                else
                    print("Unable to find portable")
                    API.RandomSleep2(1000, 100, 200)
                    lastTimeGainedXp = os.time() --reset last time gained xp so I don't time out if no portable is currently deployed
                    if os.time() - lastTimePortableExisted > MAX_TIME_WITHOUT_PORTABLE then
                        print("No portable found after " .. MAX_TIME_WITHOUT_PORTABLE .. " seconds")
                        API.Write_LoopyLoop(false)
                    end
                end
            end
        elseif API.BankOpen2() then
            loadPreset()
        elseif API.VB_FindPSett(9932).state > 0 then
            print("Loading last preset")
            if API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, { SCENE_OBJECTS.BANK_CHEST }, 5) then
                waitUntil(hasAllItems, 2)
            end
        else
            print("Opening bank")
            if API.DoAction_Object1(0x2e, API.OFF_ACT_GeneralObject_route1, { SCENE_OBJECTS.BANK_CHEST }, 5) then
                print("Waiting for bank open")
                waitUntil(API.BankOpen2, 5)
            end
        end
    end

    API.RandomSleep2(100, 10, 20)
end
