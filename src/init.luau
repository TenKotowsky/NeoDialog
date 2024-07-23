--!strict
--!optimize 2

local UserInputService = game:GetService("UserInputService") :: UserInputService
local Players = game:GetService("Players") :: Players
local Dialogs = require(script.Dialogs) :: {}

local player = Players.LocalPlayer :: Player

local Dialog = {} :: dialog
Dialog.__index = Dialog

--The dialog sound won't play for those characters
local ignoredSoundCharacters = {" "} :: {}
local dialogQueue = {} :: {}

local function writeTextInput(textLabel: TextLabel, text: string, interval: number, sound: Sound?)
    textLabel.MaxVisibleGraphemes = 0
    local inputConnection
    inputConnection = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
        if (not gameProcessedEvent) and input.UserInputType == Enum.UserInputType.MouseButton1 then
            inputConnection:Disconnect()
        end
    end)
    textLabel.MaxVisibleGraphemes = 0
    textLabel.Text = text
    for i = 1, string.len(textLabel.ContentText) do
        if (not inputConnection.Connected) then break end
        textLabel.MaxVisibleGraphemes = i

        if sound and (not table.find(ignoredSoundCharacters, textLabel.ContentText:sub(i,i))) then
            local soundClone = sound:Clone()
            soundClone.Parent = sound.Parent
            soundClone.PlayOnRemove = true
            soundClone:Destroy()
        end

        local startTime = os.clock()
        repeat
            task.wait()
        until (not inputConnection.Connected) or os.clock() - startTime >= interval
    end
    if inputConnection.Connected then
        inputConnection:Disconnect()
    else
        textLabel.MaxVisibleGraphemes = -1
    end
    inputConnection = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
        if (not gameProcessedEvent) and input.UserInputType == Enum.UserInputType.MouseButton1 then
            inputConnection:Disconnect()
        end
    end)
    while inputConnection.Connected do task.wait() end
end

local function writeTextAuto(textLabel: TextLabel, text: string, interval: number, continueWait: number, sound: Sound?)
    textLabel.MaxVisibleGraphemes = 0
    textLabel.Text = text
    for i = 1, string.len(textLabel.ContentText) do
        textLabel.MaxVisibleGraphemes = i

        if sound and (not table.find(ignoredSoundCharacters, textLabel.ContentText:sub(i,i))) then
            local soundClone = sound:Clone()
            soundClone.Parent = sound.Parent
            soundClone.PlayOnRemove = true
            soundClone:Destroy()
        end

        task.wait(interval)
    end
    task.wait(continueWait)
end

local function runDialog(dialog: dialog, dialogID: string, isResponseDialog: boolean?) : boolean
    if (not Dialogs[dialogID]) then return false end
    local id: number
    if (not isResponseDialog) then
        if dialogQueue[1] then
            id = tick()
            table.insert(dialogQueue, id)
            repeat task.wait() until dialogQueue[1] == id
        else
            id = tick()
            table.insert(dialogQueue, id)
        end
    end

    local humanoid: Humanoid?
    local previousWalkSpeed: number

	if dialog.dialogWalkSpeed and player.Character then
		humanoid = player.Character:FindFirstChildOfClass("Humanoid") :: Humanoid?
        if humanoid then
            previousWalkSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = dialog.dialogWalkSpeed
        end
    end

    local awaitingResponse = false :: boolean
    local dialogData = Dialogs[dialogID] :: {}
    
    dialog.gui.Enabled = true
    dialog.dialogRunning = true
    
    for _, iteration in pairs(dialogData) do
        if dialog.responseContainer then
            dialog.responseContainer.Visible = false
        end
        if dialog.nameLabel then
            dialog.nameLabel.Text = iteration.Name
        end
        if dialog.portraitLabel then
            dialog.portraitLabel.Image = iteration.Portrait
        end
        if dialog.continueType == "Input" then
            writeTextInput(dialog.textLabel, iteration.Text, iteration.Interval, iteration.Sound)
        else
            writeTextAuto(dialog.textLabel, iteration.Text, iteration.Interval, iteration.AutoDialogWait, iteration.Sound)
        end

        if iteration.Responses and dialog.responseContainer and dialog.responseTemplate then
            awaitingResponse = true
            dialog.responseContainer.Visible = true
            for response, responseDialog in pairs (iteration.Responses) do
                local buttonClone = dialog.responseTemplate:Clone() :: TextButton
                buttonClone.Name = "ResponseButton"
                buttonClone.Text = response
                buttonClone.Parent = dialog.responseContainer :: Instance & {}
                buttonClone.Visible = true
                buttonClone.Activated:Once(function()
                    for _, button in pairs(dialog.responseContainer:GetChildren()) do
                        if button.Name == "ResponseButton" then button:Destroy() end
                    end
                    runDialog(dialog, responseDialog, true)
                    awaitingResponse = false
                end)
            end
        end
        if iteration.Function then
            iteration.Function()
        end
    end

    if awaitingResponse then
        repeat task.wait() until (not awaitingResponse) return true
    end

    if dialog.responseContainer then
        for _, button in pairs(dialog.responseContainer:GetChildren()) do
            if button.Name == "ResponseButton" then button:Destroy() end
        end
    end
    
    dialog.dialogRunning = false
    dialog.gui.Enabled = false

    if previousWalkSpeed and humanoid then
        humanoid.WalkSpeed = previousWalkSpeed
    end

    if dialogQueue[1] then table.remove(dialogQueue, 1) end

    return true
end

function Dialog.new(dialogGui: ScreenGui, textLabel: TextLabel, nameLabel: TextLabel?, portraitLabel: ImageLabel?, responseContainer: Instance?, responseTemplate: TextButton?, dialogConfig: dialogConfig?) : dialog
    local self = setmetatable({}, Dialog) :: dialog

    self.gui = dialogGui :: ScreenGui
	self.textLabel = textLabel :: TextLabel
	if nameLabel then
		self.nameLabel = nameLabel :: TextLabel
	end
    if portraitLabel then
		self.portraitLabel = portraitLabel :: ImageLabel
	end
    if responseContainer then
		self.responseContainer = responseContainer :: Instance & {Visible: boolean}
	end
    if responseTemplate then
		self.responseTemplate = responseTemplate :: TextButton
	end

    self.dialogRunning = false :: boolean
    self.continueType = "Input" :: "Auto" | "Input"

    if dialogConfig then
        
        if dialogConfig.continueType then
            self.continueType = dialogConfig.continueType
        end

        if dialogConfig.dialogWalkSpeed then
            self.dialogWalkSpeed = dialogConfig.dialogWalkSpeed
        end

    end

    self.run = function(dialogID: string) : boolean
        return runDialog(self, dialogID)
    end

    return self
end

export type dialogConfig = {
    continueType: "Auto" | "Input",
    dialogWalkSpeed: number
}
export type dialog = typeof(Dialog.new(Instance.new("ScreenGui"), Instance.new("TextLabel"), Instance.new("TextLabel"), Instance.new("ImageLabel"), Instance.new("Frame"), Instance.new("TextButton"), {} :: dialogConfig))

return table.freeze(Dialog) :: typeof(Dialog)