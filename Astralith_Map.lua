-- Crée une frame pour gérer les événements
local AstralithFrame = CreateFrame("Frame")

-- Table pour stocker les positions des membres
local guildMembers = {}
local lastSentPosition = { x = nil, y = nil, mapID = nil } -- Dernière position envoyée
local updateInterval = 10 -- En secondes
local movementThreshold = 0.05 -- 5% de la carte (approximativement 5 mètres)

local timeSinceLastUpdate = 0

-- Fonction pour calculer la distance entre deux points
local function CalculateDistance(x1, y1, x2, y2)
    if not x1 or not y1 or not x2 or not y2 then
        return math.huge -- Distance infinie si une des coordonnées est manquante
    end
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- Fonction pour envoyer la position du joueur
local function SendPlayerPosition(force)
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    local x, y = 0, 0
    if position then
        x, y = position:GetXY()
    end

    if not force then
        -- Vérifie la distance parcourue
        if lastSentPosition.mapID == mapID then
            local distance = CalculateDistance(lastSentPosition.x, lastSentPosition.y, x, y)
            if distance < movementThreshold then
                return -- Pas besoin d'envoyer la position
            end
        end
    end

    -- Met à jour la position envoyée
    lastSentPosition = { x = x, y = y, mapID = mapID }

    local name = UnitName("player")
    if name and x and y then
        local message = string.format("%s:%d:%.2f:%.2f", name, mapID, x * 100, y * 100)
        C_ChatInfo.SendAddonMessage("ASTRALITH_MAP", message, "GUILD")
    end
end

-- Fonction de mise à jour périodique
local function OnUpdate(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= updateInterval then
        SendPlayerPosition(true) -- Force l'envoi toutes les 10 secondes
        timeSinceLastUpdate = 0
    else
        SendPlayerPosition(false) -- Vérifie si le joueur a bougé suffisamment
    end
end

-- Fonction pour vérifier si le message provient du joueur lui-même
local function IsSelf(sender)
    local playerName = UnitName("player")
    local realmName = GetNormalizedRealmName()
    local fullPlayerName = playerName .. "-" .. realmName
    return sender == fullPlayerName
end

-- Fonction pour recevoir les positions
local function ReceivePlayerPosition(prefix, message, channel, sender)
    if prefix == "ASTRALITH_MAP" and not IsSelf(sender) then
        local name, mapID, x, y = string.match(message, "([^:]+):(%d+):([%d%.]+):([%d%.]+)")
        if name and mapID and x and y then
            -- Supprime l'ancien waypoint s'il existe
            if guildMembers[name] and guildMembers[name].uid then
                TomTom:RemoveWaypoint(guildMembers[name].uid)
            end
            -- Met à jour la table avec les nouvelles coordonnées
            guildMembers[name] = { mapID = tonumber(mapID), x = tonumber(x), y = tonumber(y) }
        end
    end
end

-- Fonction pour afficher les positions sur la carte avec TomTom
local function UpdateGuildMemberWaypoints()
    if not TomTom then
        print("TomTom is not installed or active.")
        return
    end

    -- Ajoute les nouveaux waypoints
    for name, data in pairs(guildMembers) do
        local mapID, x, y = data.mapID, data.x / 100, data.y / 100
        if mapID and x and y then
            local opts = {
                title = name,
                persistent = false,
                silent = true,
                crazyarrow = false, -- Désactive l'affichage de la flèche
            }
            -- Crée un nouveau waypoint pour la position actuelle
            data.uid = TomTom:AddWaypoint(mapID, x, y, opts)
        end
    end
end

-- Enregistre les événements
AstralithFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
AstralithFrame:RegisterEvent("ZONE_CHANGED")
AstralithFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
AstralithFrame:RegisterEvent("CHAT_MSG_ADDON")

-- Gère les événements
AstralithFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        C_ChatInfo.RegisterAddonMessagePrefix("ASTRALITH_MAP")
        SendPlayerPosition(true) -- Force l'envoi au chargement
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        SendPlayerPosition(true) -- Force l'envoi lors d'un changement de zone
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        ReceivePlayerPosition(prefix, message, channel, sender)
        UpdateGuildMemberWaypoints()
    end
end)

-- Ajoute un OnUpdate pour gérer la logique de mise à jour périodique
AstralithFrame:SetScript("OnUpdate", OnUpdate)

-- Commandes slash
SLASH_ASTRALITH1 = "/astralith"
SlashCmdList["ASTRALITH"] = function(msg)
    if msg == "update" then
        UpdateGuildMemberWaypoints()
    else
        print("Commandes disponibles : /astralith update")
    end
end

print("Astralith Map Addon chargé.")
