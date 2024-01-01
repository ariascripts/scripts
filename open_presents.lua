local API = require("api")

local supportedLamps = {[36073]=true, [36074]=true, [36075]=true, [36076]=true, [35450]=true, [35451]=true, [35452]=true, [35453]=true}

local function isUseAllMenuVisible()
    local ic = API.ScanForInterfaceTest2Get(false, {
        InterfaceComp5.new(678,3,-1,-1,0), 
        InterfaceComp5.new(678,1,-1,3,0), 
        InterfaceComp5.new(678,19,-1,1,0), 
        InterfaceComp5.new(678,29,-1,19,0), 
        InterfaceComp5.new(678,30,-1,29,0)
    })
    if (#ic > 0) then
        local s = string.sub(API.ReadCharsPointer(ic[1].memloc + API.I_itemids3), 1, 18)
        return string.len(s) > 1
    end   
end

function waitUntil(x, timeout)
    start = os.time()
    while not x() and start + timeout > os.time() do
        API.RandomSleep2(300, 100, 100)
    end
    return start + timeout > os.time()
end

local function interact(itemName, action, o1, o2, route)
    local vec = API.ReadInvArrays33()   
    for i = 1, #vec do
        if vec[i].itemid1 > 0 and string.find(vec[i].textitem, itemName) then
            return API.DoAction_Interface(action,vec[i].itemid1,o1,1473,o2,vec[i].index,route)
        end
    end
end

--62 = dungeoneering
--68 = archaeology
--this is for the skill that is clicked in the lamp interface, users can ignore this because it doesn't actually matter
local ignore = 68

--25 = dungeoneering
--28 = archaeology
--14 = smithing
--this is for the skill that you want to gain exp in, as stated above, the skill that is clicked in the lamp interface doesn't actually matter

--Turn on DO:Action debug and click the "Confirm" button to find this value, you should see something like this
--Possible interface:1263:74:14 item:-1
--Needed for: DO::DoAction_Interface(0xffffffff,0xffffffff,0,1263,74,14,4496);
--Matching action: OFF_ACT::GeneralInterface_Choose_option
local skill_index = 14

API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    local count = API.Invfreecount_()
    local vec = API.ReadInvArrays33()
    local lamp = nil
        
    for i = 1, #vec do
        if vec[i].itemid1 > 0 and supportedLamps[vec[i].itemid1] then
            lamp = vec[i]
            break
        end
    end

    if API.BankOpen2() then
        print("Banking inventory")
        API.KeyboardPress32(0x33,0) --press 3 to deposit inventory
        API.RandomSleep2(600, 100, 100)
        interact("Christmas Present", 0x31, 1, 5,API.OFF_ACT_GeneralInterface_route)
    elseif API.VB_FindPSett(2874).SumOfstate == 18 then
        --make sure no login announcements, random menus, etc are visible
        if isUseAllMenuVisible() then
            API.DoAction_Interface(0xffffffff,0xffffffff,0,678,19,-1,API.OFF_ACT_GeneralInterface_Choose_option) --select use all, this will cause me to get stuck if I don't have multiple lamps/stars
            API.RandomSleep2(600, 100, 200)
            API.DoAction_Interface(0xffffffff,0xffffffff,1,1263,ignore,-1,API.OFF_ACT_GeneralInterface_route) --select skill
            API.RandomSleep2(600, 100, 200)
            API.DoAction_Interface(0xffffffff,0xffffffff,0,1263,74,skill_index,API.OFF_ACT_GeneralInterface_Choose_option) --Confirm
        else     
            API.DoAction_Interface(0xffffffff,0xffffffff,0,1263,74,skill_index,API.OFF_ACT_GeneralInterface_Choose_option) --Confirm
            API.DoAction_Interface(0xffffffff,0xffffffff,1,1263,ignore,-1,API.OFF_ACT_GeneralInterface_route) --select skill
        end
    elseif lamp ~= nil then
        print("Interacting with lamp")
        if API.DoAction_Interface(0x2e,lamp.itemid1,1,1473,5,lamp.index,API.OFF_ACT_GeneralInterface_route) then
            local f = function()
                return API.VB_FindPSett(2874).SumOfstate == 18 or count ~= API.Invfreecount_()
            end
            waitUntil(f, 5)
        end
    elseif count <= 3 then
        --script could get stuck here if the user started it with an inventory of lamps/stars that can't be deposited
        if API.InvStackSize(40932) > 0 then
            interact("Oddments", 0x24, 3, 5,API.OFF_ACT_GeneralInterface_route)
        end

        print("Opening bank")
        if API.DoAction_Object1(0x2e,80,{ 118606 },50) then
            waitUntil(API.BankOpen2, 5)
        end
    elseif API.InvItemcountStack_String("Present") > 0 then
        print("Using presents")
        for i = 0, 30 do
            interact("Christmas Present", 0x31, 1, 5,API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 50, 50)
        end
    else
        print("Stopping script, no presents found")
        API.Write_LoopyLoop(false)
    end
    
    API.RandomSleep2(100, 100, 100)
end
