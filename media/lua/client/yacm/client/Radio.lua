local Character              = require('yacm/shared/utils/Character')
local World                  = require('yacm/shared/utils/World')
local YacmClientSendCommands = require('yacm/client/network/SendYacmClient')


local Radio = {}

function Radio.SyncSquare(turnedOn, mute, power, volume, frequency, x, y, z)
    if turnedOn == nil then
        print('yacm error: Radio.SyncSquare: nil turnedOn parameter')
        return
    end
    if mute == nil then
        print('yacm error: Radio.SyncSquare: nil mute parameter')
        return
    end
    if power == nil then
        print('yacm error: Radio.SyncSquare: nil power parameter')
        return
    end
    if volume == nil then
        print('yacm error: Radio.SyncSquare: nil volume parameter')
        return
    end
    if frequency == nil then
        print('yacm error: Radio.SyncSquare: nil frequency parameter')
        return
    end
    if x == nil then
        print('yacm error: Radio.SyncSquare: nil x parameter')
        return
    end
    if y == nil then
        print('yacm error: Radio.SyncSquare: nil y parameter')
        return
    end
    if z == nil then
        print('yacm error: Radio.SyncSquare: nil z parameter')
        return
    end
    local square = getSquare(x, y, z)
    if square == nil then -- legitimate error, when a client is too far away
        return
    end
    local radios = World.getSquareItemsByGroup(square, 'IsoRadio')
    if radios == nil or #radios <= 0 then
        print('yacm error: Radio.SyncSquare: no radio found at ' .. x .. ', ' .. y .. ', ' .. z)
        return
    end
    local radio = radios[1]
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('yacm error: Radio.SyncSquare: radio has not device data')
        return
    end
    if radioData.setIsTurnedOn ~= nil then
        radioData:setIsTurnedOn(turnedOn)
    end
    radioData:setMicIsMuted(mute)
end

function Radio.SyncInHand(id, turnedOn, mute, power, volume, frequency)
    if id == nil then
        print('yacm error: Radio.SyncInHand: nil id parameter')
        return
    end
    if turnedOn == nil then
        print('yacm error: Radio.SyncInHand: nil turnedOn parameter')
        return
    end
    if mute == nil then
        print('yacm error: Radio.SyncInHand: nil mute parameter')
        return
    end
    if power == nil then
        print('yacm error: Radio.SyncInHand: nil power parameter')
        return
    end
    if volume == nil then
        print('yacm error: Radio.SyncInHand: nil volume parameter')
        return
    end
    if frequency == nil then
        print('yacm error: Radio.SyncInHand: nil frequency parameter')
        return
    end
    local radio = Character.getItemById(getPlayer(), id)
    if radio == nil then
        print('yacm error: Radio.SyncInHand: no radio found on player')
        return
    end
    local radioData = radio:getDeviceData()
    if radioData == nil then
        print('yacm error: Radio.SyncInHand: radio has not device data')
        return
    end
    if radioData.setIsTurnedOn ~= nil then
        radioData:setIsTurnedOn(turnedOn)
    end
    radioData:setMicIsMuted(mute)
end

local function Update()
    local player = getPlayer()
    local inventoryRadios = player:getAttachedItems()
    local inventoryRadiosSize = inventoryRadios:size()
    for i = 0, inventoryRadiosSize - 1 do
        local item = inventoryRadios:getItemByIndex(i)
        local id = item:getID()
        if instanceof(item, "Radio") then
            -- is on belt
            local primary = player:getPrimaryHandItem()
            local secondary = player:getSecondaryHandItem()
            -- radios in hand already decrease the battery level
            if (primary and primary:getID() == id)
                or (secondary and secondary:getID() == id)
            then
                return
            end
            local radioData = item:getDeviceData()
            if radioData and radioData:getIsTurnedOn() then
                local useDelta = radioData:getUseDelta()
                local power = radioData:getPower()
                power = math.max(0, power - useDelta)
                radioData:setPower(power)
                -- we could only send it when the battery reach 0 but every 1 game-time minute
                -- is really not that much and it will protect us from any sync error
                YacmClientSendCommands.sendGiveRadioState(item)
            end
        end
    end
end

Events.EveryOneMinute.Add(Update)

return Radio
