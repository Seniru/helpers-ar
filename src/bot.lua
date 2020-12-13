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

cmds["ping"] = function(args, msg)
    msg.channel:send("Pong!")
end

cmds["verify"] = function(args, msg)

    verificationKeys[msg.author.id] = { key = generateKey(10), toLink = args[2], attempts = 5 }

    local res, err = forum.createPrivateMessage(args[2], "AR Helpers verification", "Here's your verification key: " .. verificationKeys[msg.author.id].key)

    if not res then
        print(err)
        verificationKeys[msg.author.id] = nil
        return msg.channel:send("We encountered an error while sending the DM... check if your username is correct and try again later!")
    end


    msg.channel:send({
        embed = {
            title = "Verification",
            description = "We sent a DM to your forum to confirm it's you\n\n[Open](https://atelier801.com/conversation?" .. res.raw_data .. ")"
        }
    })

    timer.setTimeout(1000 * 60 * 1, coroutine.wrap(function() -- expire the key in 5 minutes
        if not verificationKeys[msg.author.id] then return end
        verificationKeys[msg.author.id] = nil
        msg.channel:send("<@" .. msg.author.id .. "> Verification process timed out! Please do !verify again")
    end))

end

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
                msg.channel:send("Linking you with " .. keys.toLink)
                verificationKeys[msg.author.id] = nil
                msg.member:setNickname(keys.toLink)
            else
                if keys.attempts < 1 then
                    verificationKeys[msg.author.id] = nil
                    return msg.channel:send("Verification failed!!! Please try again later")
                end
                msg.channel:send("Wrong key! ** " .. keys.attempts .. "** attempts left!")
                verificationKeys[msg.author.id].attempts = keys.attempts - 1
            end
            return msg:delete()
        end
    end

    -- general commands
    if msg.content:sub(1, 1) ~= PREFIX then return end
    local args = utils.string_split(msg.content:sub(2), " ")
    if cmds[args[1]] then
        coroutine.wrap(function() cmds[args[1]](args, msg) end)()
    end
end)




discord:run("Bot " .. os.getenv("DISCORD"))