local function SendYacmServerCommand(player, commandName, args)
    sendServerCommand(player, 'YACM', commandName, args)
end

local function ServerPrint(player, message)
    SendYacmServerCommand(player, 'ServerPrint', { message = message })
end

local function SendErrorMessage(player, type, message)
    SendYacmServerCommand(player, 'ChatError', { message = message, type = type })
end

local function PlayersDistance(source, target)
    return source:DistTo(target:getX(), target:getY())
end

local MessageHasAccessByType = {
    ['whisper']   = function(author, player, args) return true end,
    ['low']       = function(author, player, args) return true end,

    ['say']       = function(author, player, args) return true end,

    ['yell']      = function(author, player, args) return true end,
    ['pm']        = function(author, player, args)
        return args.target ~= nil and args.author ~= nil and
            (player:getUsername() == args.target or player:getUsername() == args.author)
    end,
    ['faction']   = function(author, player, args)
        local playerFaction = Faction.getPlayerFaction(player)
        local authorFaction = Faction.getPlayerFaction(author)
        return playerFaction ~= nil and authorFaction ~= nil and playerFaction:getName() == authorFaction:getName()
    end,
    ['safehouse'] = function(author, player, args)
        local playerSafeHouse = SafeHouse.hasSafehouse(player)
        local authorSafeHouse = SafeHouse.hasSafehouse(author)
        return playerSafeHouse ~= nil and authorSafeHouse ~= nil and
            playerSafeHouse:getTitle() == authorSafeHouse:getTitle()
    end,
    ['general']   = function(author, player, args) return true end,
    ['admin']     = function(author, player, args)
        return player:getAccessLevel() == 'Admin'
    end,
    ['ooc']       = function(author, player, args) return true end,
}

local MessageTypeSettings = {
    ['whisper'] = {
        ['range'] = SandboxVars.YetAnotherChatMod.WhisperRange,
        ['zombieRange'] = SandboxVars.YetAnotherChatMod.WhisperZombieRange,
        ['enabled'] = SandboxVars.YetAnotherChatMod.WhisperEnabled,
    },
    ['low'] = {
        ['range'] = SandboxVars.YetAnotherChatMod.LowRange,
        ['zombieRange'] = SandboxVars.YetAnotherChatMod.LowZombieRange,
        ['enabled'] = SandboxVars.YetAnotherChatMod.LowEnabled,
    },
    ['say'] = {
        ['range'] = SandboxVars.YetAnotherChatMod.SayRange,
        ['zombieRange'] = SandboxVars.YetAnotherChatMod.SayZombieRange,
        ['enabled'] = SandboxVars.YetAnotherChatMod.SayEnabled,
    },
    ['yell'] = {
        ['range'] = SandboxVars.YetAnotherChatMod.YellRange,
        ['zombieRange'] = SandboxVars.YetAnotherChatMod.YellZombieRange,
        ['enabled'] = SandboxVars.YetAnotherChatMod.YellEnabled,
    },
    ['pm'] = {
        ['range'] = -1,
        ['zombieRange'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.PrivateMessageEnabled,
    },
    ['faction'] = {
        ['range'] = -1,
        ['zombieRange'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.FactionMessageEnabled,
    },
    ['safehouse'] = {
        ['range'] = -1,
        ['zombieRange'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.SafeHouseMessageEnabled,
    },
    ['general'] = {
        ['range'] = -1,
        ['zombieRange'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.GeneralMessageEnabled,
    },
    ['admin'] = {
        ['range'] = -1,
        ['zombieRange'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.AdminMessageEnabled,
    },
    ['ooc'] = {
        ['range'] = SandboxVars.YetAnotherChatMod.OutOfCharacterMessageRange,
        ['zombieRange'] = -1,
        ['enabled'] = SandboxVars.YetAnotherChatMod.OutOfCharacterMessageEnabled,
    },
}

local function GetRangeForMessageType(type)
    local messageSettings = MessageTypeSettings[type]
    if messageSettings ~= nil then
        return messageSettings['range']
    end
    error('unknown message type "' .. type .. '"')
    return nil
end

local function GetConnectedPlayer(username)
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if connectedPlayer:getUsername() == username then
            return connectedPlayer
        end
    end
    return nil
end

local function IsAllowed(author, player, args)
    if args.type == nil or MessageTypeSettings[args.type] == nil
        or MessageTypeSettings[args.type]['enabled'] ~= true
        or MessageHasAccessByType[args.type] == nil
    then
        return false
    end
    return MessageHasAccessByType[args.type](author, player, args)
end

local ProcessYacmPackets = {}

local function ProcessYacmPacket(player, args, packetType, sendError)
    if args.type == nil then
        error('error: YACM: Received a message from "' .. player:getUsername() .. '" with no type')
        return
    end
    if args.type == "faction" then
        if Faction.getPlayerFaction(player) == nil then
            if sendError then
                SendErrorMessage(player, args.type, 'you are not part of a faction.')
            end
            return
        end
    elseif args.type == 'safehouse' then
        if SafeHouse.hasSafehouse(player) == nil then
            if sendError then
                SendErrorMessage(player, args.type, 'you are not part of a safe house.')
            end
            return
        end
    elseif args.type == 'pm' then
        if args.target == nil or GetConnectedPlayer(args.target) == nil then
            if args.target ~= nil then
                if sendError then
                    SendErrorMessage(player, args.type, 'unknown player "' .. args.target .. '".')
                end
            else
                error('error: YACM: Received a private message from "' .. player:getUsername() .. '" without a contact.')
            end
            return
        end
    end
    local range = GetRangeForMessageType(args.type)
    if range == nil then
        error('error: YACM: No range for message type "' .. args.type .. '".')
        return
    end
    local connectedPlayers = getOnlinePlayers()
    for i = 0, connectedPlayers:size() - 1 do
        local connectedPlayer = connectedPlayers:get(i)
        if (connectedPlayer:getOnlineID() == player:getOnlineID()
                or range == -1 or PlayersDistance(player, connectedPlayer) < range)
            and IsAllowed(player, connectedPlayer, args)
        then
            SendYacmServerCommand(connectedPlayer, packetType, args)
        end
    end
end

ProcessYacmPackets['ChatMessage'] = function(player, args)
    ProcessYacmPacket(player, args, 'ChatMessage', true)
end

ProcessYacmPackets['Typing'] = function(player, args)
    ProcessYacmPacket(player, args, 'Typing', false)
end

ProcessYacmPackets['AskSandboxVars'] = function(player, args)
    print('RECEIVED AskSandboxVars')
    SendYacmServerCommand(player, 'SendSandboxVars', MessageTypeSettings)
end

local function OnClientCommand(module, command, player, args)
    print('PACKET RECEIVED: ' .. module .. ' ' .. command)
    if module == 'YACM' and ProcessYacmPackets[command] then
        ProcessYacmPackets[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)
