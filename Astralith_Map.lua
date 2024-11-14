-- Crée une frame pour gérer les événements
local AstralithFrame = CreateFrame("Frame")

-- Table pour stocker les positions des membres
local guildMembers = {}

-- Fonction pour envoyer la position du joueur
local function SendPlayerPosition()
    local x, y, mapID = UnitPosition("player")
    local name = UnitName("player")
    local level = UnitLevel("player")
    local class = select(2, UnitClass("player"))

    if x and y then
        local message = string.format("%s|%f|%f|%d|%d|%s", name, x, y, mapID, level, class)
        C_ChatInfo.SendAddonMessage("Astralith_Map", message, "GUILD")
        print(string.format("Envoi position : %s - X: %f, Y: %f, MapID: %d", name, x, y, mapID))
    end
end

-- Fonction pour recevoir les positions
local function ReceivePlayerPosition(prefix, message, channel, sender)
    if prefix == "Astralith_Map" then
        local name, x, y, mapID, level, class = strsplit("|", message)
        guildMembers[name] = {
            x = tonumber(x),
            y = tonumber(y),
            mapID = tonumber(mapID),
            level = tonumber(level),
            class = class
        }
        print(string.format("Réception position : %s - X: %f, Y: %f, MapID: %d", name, tonumber(x), tonumber(y), tonumber(mapID)))
    end
end

-- Fonction pour gérer les événements
local function OnEvent(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" then
        ReceivePlayerPosition(prefix, message, channel, sender)
    elseif event == "GUILD_ROSTER_UPDATE" then
        print("Mise à jour du roster de guilde détectée.")
    end
end

-- Inscription au préfixe et aux événements
C_ChatInfo.RegisterAddonMessagePrefix("Astralith_Map")
AstralithFrame:RegisterEvent("CHAT_MSG_ADDON")
AstralithFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
AstralithFrame:SetScript("OnEvent", OnEvent)

-- Envoie la position toutes les 5 secondes
C_Timer.NewTicker(5, SendPlayerPosition)

-- Fonction pour mettre à jour les pins sur la carte
local pins = {}

local function UpdateMapPins()
    -- Nettoie les anciens pins
    for _, pin in pairs(pins) do
        pin:Hide()
    end

    -- Ajoute les nouveaux pins
    for name, data in pairs(guildMembers) do
        if data.mapID == C_Map.GetBestMapForUnit("player") then
            local pin = pins[name]
            if not pin then
                pin = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer.Child)
                pin:SetSize(16, 16)
                pin.icon = pin:CreateTexture(nil, "OVERLAY")
                pin.icon:SetAllPoints()
                pin.icon:SetTexture("Interface\\Minimap\\POIIcons") -- Icône standard
                pins[name] = pin
            end

            -- Positionne le pin
            local uiMapX = data.x / 100
            local uiMapY = data.y / 100
            pin:SetPoint("CENTER", WorldMapFrame.ScrollContainer.Child, "TOPLEFT", uiMapX * WorldMapFrame:GetWidth(), -uiMapY * WorldMapFrame:GetHeight())
            pin:Show()
        end
    end
end

-- Met à jour les pins toutes les 5 secondes
C_Timer.NewTicker(5, UpdateMapPins)

-- Commande pour afficher/masquer la fenêtre (si nécessaire)
SLASH_ASTRALITH1 = "/astralith"
SlashCmdList["ASTRALITH"] = function()
    print("Addon chargé : Les positions sont mises à jour.")
end
