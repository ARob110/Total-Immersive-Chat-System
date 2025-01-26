local Parser        = require('tics/client/parser/Parser')
local StringBuilder = require('tics/client/parser/StringBuilder')

local ABubble       = ISUIElement:derive("ABubble")

function ABubble:loadTextures()
    error('loadTextures not implemented in child class')
end

function ABubble:render()
    error('render not implemented in child class')
end

function ABubble:prerender()
    -- nothing
end

local function Lerp(start, target, progression)
    if progression < 0.0 then
        progression = 0.0
    elseif progression >= 1.0 then
        progression = 1.0
    end
    local distance = target - start
    distance = distance * progression
    return start + distance
end

local function BuildPlayerNameString(playerName, playerColor)
    return StringBuilder.BuildBracketColorString(playerColor) .. playerName
end

function ABubble:parseMessage(length)
    local messageLength = length
    if length and self.showPlayerName and self.playerName then
        local nameLength = length and (#self.playerName + 1) or nil -- + 1 for the trailing space
        messageLength = length - nameLength
        if messageLength < 0 then
            messageLength = 0
        end
    end
    local parsedMessages = Parser.ParseTicsMessage(self.message, self.color, 20, messageLength)
    local rawMessage = parsedMessages['rawMessage']
    local bubbleMessage = parsedMessages['bubble']
    if self.showPlayerName then
        local nameLength = length and (#self.playerName + 1) or nil -- + 1 for the trailing space
        local truncatedName = self.playerName .. ' '
        truncatedName = length >= nameLength and truncatedName or truncatedName:sub(1, length)
        rawMessage = truncatedName .. rawMessage
        bubbleMessage = BuildPlayerNameString(truncatedName, self.playerColor) .. ' ' .. bubbleMessage
    end
    return rawMessage, bubbleMessage
end

function ABubble:updateText(x, y)
    local time = Calendar.getInstance():getTimeInMillis()
    local elapsedTime = time - self.startTime
    local delta = time - self.previousTime

    local length = nil
    if self.voice ~= nil then
        length = self.voice:currentMessageIndex()
        if not self.messageFinishedScrolling and length == self.fullMessageLength then
            self.messageFinishedScrolling = true
            -- if the bubble is following the voice speed we want it to stay alive at least
            -- until 2s after all the text appeared
            self.timer = math.max(elapsedTime + 2000, self.timer)
        end
    else
        self.messageFinishedScrolling = true
    end
    local rawMessage, bubbleMessage = self:parseMessage(length)
    self.text = StringBuilder.BuildFontSizeString('medium') .. bubbleMessage
    self.rawText = rawMessage
    self:paginate()

    if self.voice then
        self.voice:subscribe()
    end
    if not self.texturesLoaded then
        self:loadTextures()
        self.texturesLoaded = true
    end

    if self.currentProgression >= 1 then
        self.currentProgression = 1
        self.heightOffset = 0
    else
        local newProgression = delta / (2 * 100)
        self.currentProgression = self.currentProgression + newProgression
        self.heightOffset = Lerp(self.heightOffsetStart, 0, self.currentProgression)
    end

    self:setX(x)
    self.currentX = self:getX()
    self:setY(y + self.heightOffset)
    self.currentY = self:getY()
end

function ABubble:drawBubble()
    if self.dead then
        return
    end

    local time = Calendar.getInstance():getTimeInMillis()
    local elapsedTime = time - self.startTime

    local scale = 1
    if self.timer - elapsedTime > 1000 or not self.messageFinishedScrolling then
        self.alpha = self.opacity
    elseif self.timer - elapsedTime > 0 then
        local fadingTime = elapsedTime - (self.timer - 1000)
        self.fadingProgression = (1000 - fadingTime) / 1000
        self.alpha = self.fadingProgression * self.opacity
    else
        self.dead = true
        if self.voice then
            self.voice:unsubscribe()
        end
        return
    end

    local leftX = 0
    local leftW = math.floor(10 * 1 / scale)
    local rightW = math.floor(10 * 1 / scale)
    local centerW = math.floor(self:getWidth()) - rightW - leftW
    local centerX = leftX + leftW
    local rightX = centerX + centerW
    local topH = math.floor(10 * 1 / scale)
    self:drawTextureScaled(self.bubbleTopLeft, leftX, 0, leftW, topH, self.alpha)
    self:drawTextureScaled(self.bubbleTop, centerX, 0, centerW, topH, self.alpha)
    self:drawTextureScaled(self.bubbleTopRight, rightX, 0, rightW, topH, self.alpha)

    local centerY = topH
    local botH = math.floor(10 * 1 / scale)
    local centerH = math.floor(self:getHeight()) - botH - topH
    local botY = centerY + centerH

    self:drawTextureScaled(self.bubbleCenterLeft, leftX, centerY, leftW, centerH, self.alpha)
    self:drawTextureScaled(self.bubbleCenter, centerX, centerY, centerW, centerH, self.alpha)
    self:drawTextureScaled(self.bubbleCenterRight, rightX, centerY, rightW, centerH, self.alpha)

    if self.playerAvatar or self.playerModel then
        self:drawTextureScaled(self.bubbleBotLeftSquare, leftX, botY, leftW, botH, self.alpha)
    else
        self:drawTextureScaled(self.bubbleBotLeft, leftX, botY, leftW, botH, self.alpha)
    end
    self:drawTextureScaled(self.bubbleBot, centerX, botY, centerW, botH, self.alpha)
    self:drawTextureScaled(self.bubbleBotRight, rightX, botY, rightW, botH, self.alpha)

    if self.showArrow and self.currentX > 0 and self.currentY > self.topSpace
        and self.currentX + self:getWidth() < getCore():getScreenWidth()
        and self.currentY + self:getHeight() < getCore():getScreenHeight()
    then
        self:drawTextureScaled(self.bubbleArrow,
            centerX + centerW / 2 + 5,
            botY + 4 * botH / 5,
            7 / scale,
            9 / scale,
            self.alpha)
    end

    ISRichTextPanel.render(self)
    self.previousTime = time
end

function ABubble:setY(y)
    local ys = y
    if self:getKeepOnScreen() then
        local maxY = getCore():getScreenHeight();
        local topSpace = self.topSpace
        ys = math.max(topSpace, math.min(y, maxY - self.height));
    end

    self.y = ys;
    if self.javaObject ~= nil then
        self.javaObject:setY(ys);
    end
end

function ABubble:new(
    x, y, text, rawText, message, messageColor, timer, opacity, heightOffsetStart,
    showArrow, showPlayerName, playerName, playerColor)
    local textLength = getTextManager():MeasureStringX(UIFont.medium, rawText)
    local width = math.min(textLength * 1.25, 162) + 40
    local height = 0
    ABubble.__index = self
    setmetatable(ABubble, { __index = ISRichTextPanel })
    local o = ISRichTextPanel:new(x, y, width, height)
    setmetatable(o, ABubble)
    o.text = StringBuilder.BuildFontSizeString('medium') .. text
    o.timer = timer * 1000
    o.opacity = opacity / 100
    o.message = message
    o.color = messageColor
    o.rawText = rawText
    o.fullMessageLength = #rawText
    o.messageFinishedScrolling = false
    o.background = true
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.anchorLeft = true
    o.anchorRight = false
    o.anchorTop = true
    o.anchorBottom = false
    o.moveWithMouse = false
    o.startTime = Calendar.getInstance():getTimeInMillis()
    o.previousTime = o.startTime
    o.dead = false
    ISUIElement.initialise(o)
    o:paginate()
    o.texturesLoaded = false
    o.currentX = x
    o.currentY = y
    o.currentProgression = 0
    o.heightOffsetStart = heightOffsetStart
    o.heightOffset = heightOffsetStart
    o.showArrow = showArrow
    o.showPlayerName = showPlayerName
    o.playerName = playerName
    o.playerColor = playerColor
    o.subscribed = false
    o.defaultWidth = width
    o.alpha = o.opacity
    o.fadingProgression = 1
    o.defaultLeftMargin = 20
    o.defaultTopMargin = 10
    -- I mean padding is already called padding in ISRichTextPanel, how do I call a real margin?
    o.topSpace = 0
    return o
end

return ABubble
