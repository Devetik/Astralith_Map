-- Crée une frame pour écouter les événements du jeu
local AstralithFrame = CreateFrame("Frame")

-- Fonction appelée lorsqu'un événement est détecté
local function OnEvent(self, event, ...)
    print("Événement détecté :", event)
    if event == "GUILD_ROSTER_UPDATE" then
        -- Met à jour la liste des membres connectés
        local totalMembers = GetNumGuildMembers()
        print("Nombre total de membres dans la guilde :", totalMembers)
        print("Membres connectés :")
        for i = 1, totalMembers do
            local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
            if isOnline then
                print(name)
            end
        end
    end
end

-- S'abonne à l'événement "GUILD_ROSTER_UPDATE"
AstralithFrame:RegisterEvent("GUILD_ROSTER_UPDATE")

-- Associe la fonction OnEvent à la frame
AstralithFrame:SetScript("OnEvent", OnEvent)

-- Force une mise à jour du roster de la guilde au démarrage
C_GuildInfo.GuildRoster()
print("Astralith Map chargé !")


-- Crée une frame principale pour afficher la liste des membres connectés
local AstralithFrame = CreateFrame("Frame", "AstralithFrame", UIParent, "BasicFrameTemplateWithInset")
AstralithFrame:SetSize(300, 400) -- Taille de la fenêtre
AstralithFrame:SetPoint("CENTER") -- Position au centre de l'écran
AstralithFrame:SetMovable(true)
AstralithFrame:EnableMouse(true)
AstralithFrame:RegisterForDrag("LeftButton")
AstralithFrame:SetScript("OnDragStart", AstralithFrame.StartMoving)
AstralithFrame:SetScript("OnDragStop", AstralithFrame.StopMovingOrSizing)

-- Titre de la fenêtre
local title = AstralithFrame:CreateFontString(nil, "OVERLAY")
title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
title:SetPoint("TOP", AstralithFrame, "TOP", 0, -10)
title:SetText("Membres connectés")

-- ScrollFrame pour afficher la liste
local scrollFrame = CreateFrame("ScrollFrame", nil, AstralithFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(240, 2000) -- Taille estimée pour le contenu
scrollFrame:SetScrollChild(content)

-- Fonction pour mettre à jour la liste des membres
local function UpdateGuildList()
    local totalMembers = GetNumGuildMembers()
    local yOffset = -10

    -- Supprime les anciens affichages
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
    end

    -- Ajoute les membres connectés
    for i = 1, totalMembers do
        local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
        if isOnline then
            local memberText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            memberText:SetPoint("TOPLEFT", 10, yOffset)
            memberText:SetText(name)
            yOffset = yOffset - 20
        end
    end

    content:SetHeight(math.abs(yOffset) + 10)
end

-- Bouton de mise à jour
local updateButton = CreateFrame("Button", nil, AstralithFrame, "GameMenuButtonTemplate")
updateButton:SetPoint("BOTTOM", AstralithFrame, "BOTTOM", 0, 10)
updateButton:SetSize(100, 25)
updateButton:SetText("Actualiser")
updateButton:SetScript("OnClick", function()
    C_GuildInfo.GuildRoster()
    UpdateGuildList()
end)

-- Initialise la fenêtre
AstralithFrame:Hide()

SLASH_ASTRALITH1 = "/astralith"
SlashCmdList["ASTRALITH"] = function(msg)
    if AstralithFrame:IsShown() then
        AstralithFrame:Hide()
    else
        AstralithFrame:Show()
        C_GuildInfo.GuildRoster()
        UpdateGuildList()
    end
end

local function SendPlayerPosition()
    local x, y, mapID = UnitPosition("player")
    local name = UnitName("player")
    local level = UnitLevel("player")
    local class = select(2, UnitClass("player")) -- Récupère le code de la classe (ex. : "MAGE", "WARRIOR")

    if x and y then
        local message = string.format("%s|%f|%f|%d|%d|%s", name, x, y, mapID, level, class)
        C_ChatInfo.SendAddonMessage("Astralith_Map", message, "GUILD")
        print(string.format("Envoi position : %s - X: %f, Y: %f, MapID: %d", name, x, y, mapID))
    end
end

-- Envoie la position toutes les 5 secondes
C_Timer.NewTicker(5, SendPlayerPosition)

local guildMembers = {}

local function ReceivePlayerPosition(_, _, message, _, sender)
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

-- S'inscrit pour recevoir les messages de position
C_ChatInfo.RegisterAddonMessagePrefix("Astralith_Map")
AstralithFrame:RegisterEvent("CHAT_MSG_ADDON")
AstralithFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        ReceivePlayerPosition(...)
    end
end)

local pins = {}

local function UpdateMapPins()
    -- Nettoie les anciens pins
    for _, pin in pairs(pins) do
        pin:Hide()
    end

    -- Ajoute les nouveaux pins
    for name, data in pairs(guildMembers) do
        if true then
            local pin = pins[name]
            if not pin then
                pin = CreateFrame("Frame", nil, WorldMapFrame)
                pin:SetSize(16, 16)
                pin.icon = pin:CreateTexture(nil, "OVERLAY")
                pin.icon:SetAllPoints()
                pin.icon:SetTexture("Interface\\Minimap\\POIIcons") -- Utilise une icône standard
                pins[name] = pin
            end

            -- Positionne le pin
            local uiMapPoint = WorldMapFrame.ScrollContainer:NormalizeUIPosition(data.x, data.y)
            pin:SetPoint("CENTER", WorldMapFrame.ScrollContainer.Child, "TOPLEFT", uiMapPoint.x, -uiMapPoint.y)
            pin:Show()
        end
    end
end

-- Met à jour les pins toutes les 5 secondes
C_Timer.NewTicker(5, UpdateMapPins)



