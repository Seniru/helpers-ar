local timer = require("timer")

local fromage = require("fromage")
local discordia = require('discordia')

local utils = require("src.utils")
local config = require("src.config")

local forum = fromage()
local discord = discordia.Client()

-- [[ configuration stuff ]]
local PREFIX = "!"

-- [[ verification system ]]
local verificationKeys = {}
local abc = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local chars = abc:len()

local generateKey = function(length)
    local res = ""
    while length > 0 do
        local rand = math.random(chars)
        res = res .. abc:sub(rand, rand)
        length = length - 1
    end
    return res
end

-- [[ commands ]]
local cmds = {}

cmds["ping"] = {
    isForumAction = false,
    f = function(args, msg)
        msg.channel:send("Pong!")
    end
}
cmds["verify"] = {
    isForumAction = true,
    f = function(args, msg)

        if not args[2] then
            local m = msg.channel:send("الرجاء إدخال اسم مستخدم صالح")
            return timer.setTimeout(1000 * 60 * 1, coroutine.wrap(function()
                msg:delete()
                m:delete()
            end))
        end

        if msg.member:hasRole(config["role-verified"]) then
            local m = msg.channel:send("لقد تم التحقق من هويتك من قبل  !")
            return timer.setTimeout(1000 * 60 * 1, coroutine.wrap(function()
                msg:delete()
                m:delete()
            end))
        end

        verificationKeys[msg.author.id] = { key = generateKey(10), toLink = args[2], attempts = 5 }
        timer.setTimeout(1000 * 60 * 1, coroutine.wrap(function() msg:delete() end))

        local res, err = forum.createPrivateMessage(args[2], "التحقق من خادم فريق المساعدين العربي ",
        ([[ [p=center][img]https://i.imgur.com/w16ABsN.png[/img][/p]
        مرحبا بك [color=#FEB1FC][b]%s[/b][/color]
        
        شكرا على إنضمامك[b] [color=#2E72CB]لمخدم فريق المساعدين[/color][/b] , لإتمام عملية التسجيل في المخدم الخاص بنا انسخ الكود التالي وقم بإرساله عن طريق القناة الموجودة في المخدم الخاص بنا [b][color=#2E72CB]#[/color][color=#2E72CB]verification[/color][/b]
        [hr]
        [b][p=center]الكود الخاص بك هو : [color=#FEB1FC]%s[/color] [/p][/b]
        [hr] ]]):format(verificationKeys[msg.author.id].toLink, verificationKeys[msg.author.id].key)
        )

        if not res then
            print(err)
            verificationKeys[msg.author.id] = nil
            local m = msg.channel:send("لقد واجهنا خطأ اثناء إرسال رسالة خاصة للتحقق من اسم المستخدم الخاص بك، حاول مرة اخرى لاحقا!")
            return timer.setTimeout(1000 * 60 * 1, coroutine.wrap(function() m:delete() end))
        end

        local e = msg.channel:send({
            embed = {
                title = "التحقق",
                description = "لقد ارسلنا رساله خاصه في المنتدى الخاص بك للتأكيد من هويتك \n\n [فتح](https://atelier801.com/conversation?" .. res.raw_data .. ")"
            }
        })
        timer.setTimeout(1000 * 60 * 5, coroutine.wrap(function() e:delete() end))
        timer.setTimeout(1000 * 60 * 5, coroutine.wrap(function() -- expire the key in 5 minutes
            if not verificationKeys[msg.author.id] then return end
            verificationKeys[msg.author.id] = nil
            local m = msg.channel:send(("انتهت مهله %s  للتحقق! افعل ذالك مره اخرى في وقت لاحق من فضلك!"):format("<@" .. msg.author.id .. ">"))
            timer.setTimeout(1000 * 60 * 5, coroutine.wrap(function() m:delete() end))
        end))
    end

}

discord:on("ready", function()
    print('[DISCORD] Logged in as '.. discord.user.username)
    coroutine.wrap(function()
        forum.connect(os.getenv("USERNAME"), os.getenv("PASSWORD"))
        if forum.isConnected() then
            print("Connected!")
        end
        os.execute("pause >nul")
    end)()
end)

discord:on("messageCreate", function(msg)

    -- special messages
    if msg.channel.id == config["verification-channel"] then
        local keys = verificationKeys[msg.author.id]
        if keys then
            -- checking if the given key matches with the generated key
            if keys.key == msg.content then
                local m = msg.channel:send("ربطك بـ " .. keys.toLink)
                timer.setTimeout(1000 * 60 * 1, coroutine.wrap(function() m:delete() end))
                verificationKeys[msg.author.id] = nil
                msg.member:addRole(config["role-verified"])
                msg.member:setNickname(keys.toLink)
            else
                if keys.attempts < 1 then
                    verificationKeys[msg.author.id] = nil
                    local m = msg.channel:send("فشل التحقق!!! يرجى المحاوله مره اخرى")
                    return timer.setTimeout(1000 * 60 * 1, coroutine.wrap(function() m:delete() end))
                end
                local m = msg.channel:send(("رمز تحقق خاطئ!%s محاولات باقيه"):format(keys.attempts))
                timer.setTimeout(1000 * 60 * 1, coroutine.wrap(function() m:delete() end))
                verificationKeys[msg.author.id].attempts = keys.attempts - 1
            end
            return msg:delete()
        end
    end

    -- general commands
    if msg.content:sub(1, 1) ~= PREFIX then return end
    local args = utils.string_split(msg.content:sub(2), " ")
    local cmd = cmds[args[1]]
    if cmd then
        if cmd.isForumAction then
            if not (forum.isConnected() and forum.isConnectionAlive()) then
                forum.connect(os.getenv("USERNAME"), os.getenv("PASSWORD"))
            end
        end
        coroutine.wrap(function() cmd.f(args, msg) end)()
    end
end)

discord:run("Bot " .. os.getenv("DISCORD"))
