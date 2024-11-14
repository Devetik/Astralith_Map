-- Crée une frame pour gérer les événements
local AstralithFrame = CreateFrame("Frame")

-- Table pour stocker les positions des membres
local guildMembers = {}

-- Fonction pour envoyer la position du joueur
local function SendPlayerPosition()
    local mapID = C_Map.GetBestMapForUnit("player")
    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    local x, y = 0, 0
    if position then
        x, y = position:GetXY()
    end
    local name = UnitName("player")
    local level = UnitLevel("player")
    local class = select(2, UnitClass("player"))

    if x and y then
        local message = string.format("%s|%f|%f|%d|%d|%s", name, x, y, mapID, level, class)
        C_ChatInfo.SendAddonMessage("Astralith_Map", message, "PARTY")
        print(string.format("Envoi position : %s - X: %f, Y: %f, MapID: %d", name, x, y, mapID))
    end
end

-- Fonction pour recevoir les positions
local function ReceivePlayerPosition(prefix, message, channel, sender)
    if prefix == "Astralith_Map" then

        -- Traitement des données reçues
        local name, x, y, mapID, level, class = strsplit("|", message)
        guildMembers[name] = {
            x = tonumber(x),
            y = tonumber(y),
            mapID = tonumber(mapID),
            level = tonumber(level),
            class = class
        }
        if name == UnitName("player") then return end
        print(string.format("Position reçue de %s : X=%f, Y=%f, MapID=%d", name, tonumber(x), tonumber(y), tonumber(mapID)))
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
    print("Taille de la carte :", WorldMapFrame.ScrollContainer.Child:GetSize())
    -- Nettoie les anciens pins
    for _, pin in pairs(pins) do
        pin:Hide()
    end

    -- Ajoute les nouveaux pins
    for name, data in pairs(guildMembers) do
        -- Vérifie que le joueur est dans la même zone
        if data.mapID == C_Map.GetBestMapForUnit("player") then
            local uiMapID = C_Map.GetBestMapForUnit("player")
            local position = C_Map.GetPlayerMapPosition(uiMapID, "player")
            if position then
                local pin = pins[name]
                if not pin then
                    pin = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer.Child)
                    pin:SetSize(16, 16)
                    pin.icon = pin:CreateTexture(nil, "OVERLAY")
                    pin.icon:SetAllPoints()
                    pin.icon:SetTexture("Interface\\Minimap\\POIIcons") -- Icône standard
                    pins[name] = pin
                end

                -- Convertit les coordonnées pour la carte
                local normalizedX, normalizedY = data.x / 100, data.y / 100
                local frameWidth, frameHeight = WorldMapFrame.ScrollContainer.Child:GetSize()

                -- Positionne le pin
                pin:SetPoint("CENTER", WorldMapFrame.ScrollContainer.Child, "TOPLEFT", normalizedX * frameWidth, -normalizedY * frameHeight)
                pin:Show()
                print(string.format("Ajout du pin pour %s : X=%f, Y=%f", name, normalizedX, normalizedY))
            end
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
