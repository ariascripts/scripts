local API = require("api")

LoginTask = {}

local USERNAME_BOX_VARBIT_STR = "00000000000000000000000001100100"
local PASSWORD_BOX_VARBIT_STR = "00000000000000000000000001100101"
local INVALID_BOX_VARBIT_STR = "00000000000000000000000001100110"
local CURSOR_LOCATION_VARBIT_ID = 174
local BACKSPACE_KEY = 8
local TAB_KEY = 9
local ENTER_KEY = 13
local ESCAPE_KEY = 27
local SPACE_KEY = 0x20
local USERNAME = false
local PASSWORD = false
local accountusername = "YOUR_USERNAME_HERE" -- Replace with your actual username/email
local passwordstring = "YOUR_PASSWORD_HERE" -- Replace with your actual password

----------------------------------------LOGIN SHIT-------------------------------------

local specialChars = {
    ["!"] = true, ["@"] = true, ["#"] = true, ["$"] = true, ["%"] = true, ["^"] = true,
    ["&"] = true, ["*"] = true, ["("] = true, [")"] = true, ["_"] = true, ["-"] = true,
    ["+"] = true, ["="] = true, ["{"] = true, ["}"] = true, ["["] = true, ["]"] = true,
    ["|"] = true, ["\\"] = true, [":"] = true, [";"] = true, ['"'] = true, ["'"] = true,
    ["<"] = true, [">"] = true, [","] = true, ["."] = true, ["/"] = true, ["?"] = true, ["~"] = true
}

local function getCursorState()
    local cursor_box = tostring(API.VB_GetBits(CURSOR_LOCATION_VARBIT_ID))
    if cursor_box == USERNAME_BOX_VARBIT_STR then
        print("USERNAME_BOX")
        USERNAME = true
        PASSWORD = false
    end
    if cursor_box == PASSWORD_BOX_VARBIT_STR then
        print("PASSWORD_BOX")
        USERNAME = false
        PASSWORD = true
    end
end

local function TypeStringOnKeyboard(inputString)
    for i = 1, #inputString do
        local char = inputString:sub(i, i)
        API.KeyboardPress(char, 50, 100)

        if specialChars[char] or char:match("%u") then
            API.RandomSleep2(200, 0, 0)
        end
    end
end

local function getUsernameInterfaceText()
    return API.ScanForInterfaceTest2Get(false,
        {{744, 0, -1, -1, 0}, {744, 26, -1, 0, 0}, {744, 39, -1, 26, 0}, {744, 52, -1, 39, 0},
            {744, 93, -1, 52, 0}, {744, 94, -1, 93, 0}, {744, 96, -1, 94, 0}, {744, 110, -1, 96, 0},
            {744, 111, -1, 110, 0}})[1].textids
end

local function getPasswordInterfaceText()
    return API.ScanForInterfaceTest2Get(false,
        {{744, 0, -1, -1, 0},
        {744, 26, -1, 0, 0},
        {744, 39, -1, 26, 0},
        {744, 52, -1, 39, 0},
            {744, 93, -1, 52, 0},
             {744, 117, -1, 93, 0},
             {744, 119, -1, 117, 0},
             {744, 133, -1, 119, 0},
            {744, 134, -1, 133, 0}})[1].textids
end

local function isInvalidDetailsInterfaceVisible()
    local text = API.ScanForInterfaceTest2Get(false,
        {{744,0,-1,-1,0},
        {744,197,-1,0,0},
        {744,339,-1,197,0},
        {744,341,-1,339,0},
        {744,343,-1,341,0},
        {744,346,-1,343,0}})[1].textids

    return text and text:find("Invalid email or password.")
end

local function isNotLoggedOutInterfaceVisible()
    local text = API.ScanForInterfaceTest2Get(false,
        {{744,0,-1,-1,0},
        {744,197,-1,0,0},
        {744,339,-1,197,0},
        {744,341,-1,339,0},
        {744,343,-1,341,0},
        {744,346,-1,343,0}})[1].textids

    return text and text:find("Your account has not logged out")
end

local function clearPass()
    if (API.GetGameState2() == 1) then
        if USERNAME then
            API.KeyboardPress2(TAB_KEY, 50, 100)
            API.RandomSleep2(600, 200, 200)
        end

        if PASSWORD then
            for i = 1, 40 do
                API.KeyboardPress2(BACKSPACE_KEY, .6, .2)
            end
            API.RandomSleep2(600, 200, 200)
        end
    end
end

--------------------------LOGIN SHIT------------------------------------------------------

function LoginTask.validate()
    return API.GetGameState2() == 1 or API.GetGameState2() == 2
end

---@param username string optional, ignore if you set `accountusername` above
---@param password string optional, ignore if you set `passwordstring` above
function LoginTask.execute(username, password)
    if username ~= nil then
        accountusername = username
    end
    if password ~= nil then
        passwordstring = password
    end

    if (API.GetGameState2() == 1) then

        getCursorState()

        local usernametext = getUsernameInterfaceText()
        local password_text = getPasswordInterfaceText()

        if (isInvalidDetailsInterfaceVisible()) then
            API.KeyboardPress2(ESCAPE_KEY, 50, 100)
            API.RandomSleep2(50, 50, 50)
            clearPass()
        elseif isNotLoggedOutInterfaceVisible() then
            API.KeyboardPress2(ESCAPE_KEY, 50, 100)
            API.RandomSleep2(3000, 50, 50)
            return
        end

        if USERNAME then
            print("usernametext:", usernametext)
            if string.lower(usernametext) == string.lower(accountusername) then
                print("Username correct")
                API.KeyboardPress2(TAB_KEY, 50, 100)
                API.RandomSleep2(200, 200, 200)
            elseif usernametext == "" then
                TypeStringOnKeyboard(accountusername)
                API.RandomSleep2(200, 0, 0)
            elseif usernametext ~= "" and usernametext ~= accountusername then
                print("Random stuff, pressing backspace")
                for i = 1, 40 do
                    API.KeyboardPress2(BACKSPACE_KEY, .6, .2)
                end
                API.RandomSleep2(5, 0, 0)

                TypeStringOnKeyboard(accountusername)
                API.RandomSleep2(200, 0, 0)
            else
                print("Broke")
                API.Write_LoopyLoop(false)
            end
        end

        if PASSWORD then
            if string.lower(usernametext) == string.lower(accountusername) and string.len(password_text) == string.len(passwordstring) then
                API.KeyboardPress2(ENTER_KEY, 100, 200)
                API.RandomSleep2(200, 0, 0)
            else
                TypeStringOnKeyboard(passwordstring)
                API.RandomSleep2(200, 0, 0)

                if string.len(password_text) > 0 and string.len(password_text) ~= string.len(passwordstring) then
                    print("Incorrect password entered")
                    for i = 1, 40 do
                        API.KeyboardPress2(BACKSPACE_KEY, .6, .2)
                    end
                    API.RandomSleep2(5, 0, 0)
                elseif usernametext == accountusername then
                    API.KeyboardPress2(ENTER_KEY, 100, 200)
                    API.RandomSleep2(200, 0, 0)
                else
                    API.KeyboardPress2(TAB_KEY, 50, 100)
                    API.RandomSleep2(200, 0, 0)
                end
            end
        end
    elseif (API.GetGameState2() == 2) then
        API.DoAction_Interface(0x2e,0xffffffff,1,820,13,-1,API.OFF_ACT_GeneralInterface_route) --dismiss any minor login notices (i.e. error logging in, you have been muted)
        API.RandomSleep2(1000, 100, 100)

        API.KeyboardPress32(SPACE_KEY, 0)

        --wait slightly over 1 min to log in
        local success = false
        for i = 1, 60 do
            API.RandomSleep2(1000, 100, 100)
            if not LoginTask.validate() then
                success = true
                break
            end
        end

        if success then
            --Optional: do stuff after logging in i.e. disabling rendering
            --API.DisableRThread()
        end
    end
end

return LoginTask