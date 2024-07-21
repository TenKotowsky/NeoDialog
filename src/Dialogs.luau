--!strict
--!optimize 2
local TextModule = require(script.Parent.TextModule)

local dialogs = {
    --example dialog tree
    ["Start"] = {
        [1] = {
            ["Name"] = "Bri'ish weatherman",
            ["Text"] = "yo what's up",
            ["Interval"] = 0.02,
            ["AutoDialogWait"] = 5,
            ["Sound"] = nil
        },
        [2] = {
            ["Name"] = "Bri'ish weatherman",
            ["Text"] = "the weather's quite nice, innit?",
            ["Interval"] = 0.02,
            ["AutoDialogWait"] = 5,
            ["Sound"] = nil
        },
        [3] = {
            ["Name"] = "Fellix",
            ["Text"] = TextModule:Customize({"b r u h", Color = "#ff5500"}),
            ["Interval"] = 0.5,
            ["AutoDialogWait"] = 5,
            ["Sound"] = nil
        }
    }
}

return dialogs :: typeof(dialogs)