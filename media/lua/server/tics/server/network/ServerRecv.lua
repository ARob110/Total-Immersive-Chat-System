local AvatarManager = require('tics/server/AvatarManager')
local Character     = require('tics/shared/utils/Character')
local ChatMessage   = require('tics/server/ChatMessage')
local ServerSend    = require('tics/server/network/ServerSend')
local Radio         = require('tics/server/radio/Radio')
local RadioManager  = require('tics/server/radio/RadioManager')
local World         = require('tics/shared/utils/World')


local RecvServer = {}


RecvServer['MuteInHandRadio'] = function(player, args)
    local playerName = args['player']
    if playerName == nil then
        print('TICS error: MuteInHandRadio packet with null player name')
        return
    end
    if args['id'] == nil then
        print('TICS error: MuteInHandRadio packet with a null id')
        return
    end
    local id = args['id']
    if id == nil then
        print('TICS error: MuteInHandRadio packet has no id value')
        return
    end
    local radio = Character.getItemById(player, id) or Character.getFirstAttachedItemByType(player, args['belt'])
    if radio == nil or not instanceof(radio, 'Radio') then
        print('TICS error: MuteInHandRadio packet asking for id ' .. id ..
            ' but no radio was found')
        return
    end
    local muteState = args['mute']
    if type(muteState) ~= 'boolean' then
        print('TICS error: MuteInHandRadio packet has no "mute" variable')
        return
    end
    Radio.MuteRadio(radio, muteState)
    Radio.SyncHand(radio, player, id)
end


RecvServer['MuteSquareRadio'] = function(player, args)
    local x = args['x']
    local y = args['y']
    local z = args['z']
    if x == nil or y == nil or z == nil then
        print('TICS error: MuteSquareRadio packet with null coordinate')
        return
    end
    local square = getSquare(x, y, z)
    if square == nil then
        print('TICS error: MuteSquareRadio packet coordinate do not point to a square: x: ' ..
            x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radios = World.getSquareItemsByGroup(square, 'IsoRadio')
    if radios == nil or #radios <= 0 then
        print('TICS error: MuteSquareRadio packet square does not contain a radio at: x: ' ..
            x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radio = radios[1]
    if radio == nil or radio.getModData == nil or radio:getModData() == nil then
        print('TICS error: MuteSquareRadio packet lead to an impossible error where we found a corrupted radio')
        return
    end
    local muteState = args['mute']
    if type(muteState) ~= 'boolean' then
        print('TICS error: MuteSquareRadio packet has no "mute" variable')
        return
    end
    Radio.MuteRadio(radio, muteState)
    Radio.SyncSquare(radio)
end


RecvServer['ChatMessage'] = function(player, args)
    ChatMessage.ProcessMessage(player, args, 'ChatMessage', true)
end

RecvServer['ChangeName'] = function(player, args)
    ChatMessage.ChangeName(player, args.fullName) -- Pass args.fullName to ChatMessage.ChangeName
end

RecvServer['Typing'] = function(player, args)
    ChatMessage.ProcessMessage(player, args, 'Typing', false)
end


RecvServer['AskSandboxVars'] = function(player, args)
    ServerSend.Command(player, 'SendSandboxVars', ChatMessage.MessageTypeSettings)
end


RecvServer['GiveBeltRadioState'] = function(player, args)
    local playerName = args['player']
    if playerName == nil then
        print('TICS error: GiveBeltRadioState packet with null player name')
        return
    end
    local beltType = args['belt']
    if beltType == nil then
        print('TICS error: GiveBeltRadioState packet has no "belt" variable')
        return
    end
    local turnedOn = args['turnedOn']
    if type(turnedOn) ~= 'boolean' then
        print('TICS error: GiveBeltRadioState packet has no "turnedOn" variable')
        return
    end
    local muteState = args['mute']
    if type(muteState) ~= 'boolean' then
        print('TICS error: GiveBeltRadioState packet has no "mute" variable')
        return
    end
    local volume = args['volume']
    if type(volume) ~= 'number' then
        print('TICS error: GiveBeltRadioState packet has no "volume" variable')
        return
    end
    local frequency = args['frequency']
    if type(frequency) ~= 'number' then
        print('TICS error: GiveBeltRadioState packet has no "frequency" variable')
        return
    end
    local battery = args['battery']
    if type(battery) ~= 'number' then
        print('TICS error: GiveBeltRadioState packet has no "battery" variable')
        return
    end
    local headphone = args['headphone']
    if type(headphone) ~= 'number' then
        print('TICS error: GiveBeltRadioState packet has no "headphone" variable')
        return
    end
    local isTwoWay = args['isTwoWay']
    if type(isTwoWay) ~= 'boolean' then
        print('TICS error: GiveBeltRadioState packet has no "isTwoWay" variable')
        return
    end
    local transmitRange = args['transmitRange']
    if type(transmitRange) ~= 'number' then
        print('TICS error: GiveBeltRadioState packet has no "transmitRange" variable')
        return
    end
    local radio = Character.getFirstAttachedItemByType(player, beltType)
    if radio == nil or not instanceof(radio, 'Radio') then
        print('TICS error: GiveBeltRadioState packet asking for a belt radio of type ' .. beltType ..
            ' but no radio was found')
        return
    end
    radio = RadioManager:getOrCreateFakeBeltRadio(player)
    Radio.MuteRadio(radio, muteState)
    Radio.SyncBelt(radio, player, turnedOn, muteState, volume, frequency, battery, headphone, isTwoWay, transmitRange)
end


RecvServer['AskInHandRadioState'] = function(player, args)
    local playerName = args['player']
    if playerName == nil then
        print('TICS error: AskInHandRadioState packet with null player name')
        return
    end
    local id = args['id']
    if id == nil then
        print('TICS error: AskInHandRadioState packet with a null id')
        return
    end
    local radio = Character.getItemById(player, id) or Character.getFirstAttachedItemByType(player, args['belt'])
    if radio == nil or not instanceof(radio, 'Radio') then
        print('TICS error: AskInHandRadioState packet asking for id ' .. id ..
            ' but no radio was found')
        return
    end
    Radio.SyncHand(radio, player, id)
end


RecvServer['AskSquareRadioState'] = function(player, args)
    local x = args['x']
    local y = args['y']
    local z = args['z']
    if x == nil or y == nil or z == nil then
        print('TICS error: AskSquareRadioState packet with null coordinate')
        return
    end
    local square = getSquare(x, y, z)
    if square == nil then
        print('TICS error: AskSquareRadioState packet coordinate do not point to a square: x: ' ..
            x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radios = World.getSquareItemsByGroup(square, 'IsoRadio')
    if radios == nil or #radios <= 0 then
        print('TICS error: AskSquareRadioState packet square does not contain a radio at: x: ' ..
            x .. ', y: ' .. y .. ', z: ' .. z)
        return
    end
    local radio = radios[1]
    Radio.SyncSquare(radio, player)
end


RecvServer['KnownAvatars'] = function(player, args)
    local avatars = args['avatars']
    if avatars == nil or type(avatars) ~= 'table' then
        print('TICS error: KnownAvatars packet does not contain an "avatars" variable')
    end
    AvatarManager:registerPlayerAvatars(player, avatars)
end


RecvServer['AvatarRequest'] = function(player, args)
    local data = args['data']
    if data == nil or type(data) ~= 'table' then
        print('TICS error: AvatarRequest packet does not contain a "data" variable')
        return
    end
    local checksum = args['checksum']
    if checksum == nil or type(checksum) ~= 'number' then
        print('TICS error: AvatarRequest packet does not contain a "checksum" variable')
        return
    end
    local extension = args['extension']
    if extension == nil or type(extension) ~= 'string' then
        print('TICS error: AvatarRequest packet does not contain an "extension" variable')
        return
    end
    local username = player:getUsername()
    if username == nil or type(username) ~= 'string' then
        print('TICS error: AvatarRequest packet does not contain an "username" variable')
        return
    end
    local firstName = args['firstName']
    if firstName == nil or type(firstName) ~= 'string' then
        print('TICS error: AvatarRequest packet does not contain a "firstName" variable')
        return
    end
    local lastName = args['lastName']
    if lastName == nil or type(lastName) ~= 'string' then
        print('TICS error: AvatarRequest packet does not contain a "lastName" variable')
        return
    end
    AvatarManager:registerAvatarRequest(username, firstName, lastName, extension, checksum, data)
end

RecvServer['ApproveAvatar'] = function(player, args)
    local username  = args['username']
    local firstName = args['firstName']
    local lastName  = args['lastName']
    local checksum  = args['checksum']
    if type(username) ~= 'string' then
        print('TICS error: ApproveAvatar packet does not contain a "username" variable')
        return
    end
    if type(firstName) ~= 'string' then
        print('TICS error: ApproveAvatar packet does not contain a "firstName" variable')
        return
    end
    if type(lastName) ~= 'string' then
        print('TICS error: ApproveAvatar packet does not contain a "lastName" variable')
        return
    end
    if type(checksum) ~= 'number' then
        print('TICS error: ApproveAvatar packet does not contain a "checksum" variable')
        return
    end
    AvatarManager:approveAvatar(player, username, firstName, lastName, checksum)
end

RecvServer['RejectAvatar'] = function(player, args)
    local username  = args['username']
    local firstName = args['firstName']
    local lastName  = args['lastName']
    local checksum  = args['checksum']
    if type(username) ~= 'string' then
        print('TICS error: RejectAvatar packet does not contain a "username" variable')
        return
    end
    if type(firstName) ~= 'string' then
        print('TICS error: RejectAvatar packet does not contain a "firstName" variable')
        return
    end
    if type(lastName) ~= 'string' then
        print('TICS error: RejectAvatar packet does not contain a "lastName" variable')
        return
    end
    if type(checksum) ~= 'number' then
        print('TICS error: RejectAvatar packet does not contain a "checksum" variable')
        return
    end
    AvatarManager:rejectAvatar(player, username, firstName, lastName, checksum)
end

RecvServer['Roll'] = function(player, args)
    local diceCount = args['diceCount']
    local diceType  = args['diceType']
    local addCount  = args['addCount']
    if type(diceCount) ~= 'number' then
        print('TICS error: Roll packet does not contain a "diceCount" variable')
        return
    end
    if type(diceType) ~= 'number' then
        print('TICS error: Roll packet does not contain a "diceType" variable')
        return
    end
    if addCount ~= nil and type(addCount) ~= 'number' then
        print('TICS error: Roll packet does not contain a "diceType" variable')
        return
    end
    ChatMessage.RollDice(player, diceCount, diceType, addCount)
end

local function OnClientCommand(module, command, player, args)
    if module == 'TICS' and RecvServer[command] then
        RecvServer[command](player, args)
    end
end


Events.OnClientCommand.Add(OnClientCommand)
