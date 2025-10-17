Timetable = Core.class()

----------------------------------------------------
-- INITIALISATION
----------------------------------------------------

function Timetable:init(owner)
    -- owner = joueur concerné
    self.owner = owner
    self.turns = {}

    -- 14 tours de jeu (1 à 14)
    for i = 1, 14 do
        self.turns[i] = {
            cost = {},
            reward = {}
        }
    end
end

----------------------------------------------------
-- ------------- AJOUT D’EFFETS  -------------------  
----------------------------------------------------

-- Ajoute un coût à un tour donné (ex: nourriture, bois, etc.)
function Timetable:addCostAtTurn(turn, costTable)
    local cell = self.turns[turn]
    if not cell then return end
    for res, qty in pairs(costTable) do
        cell.cost[res] = (cell.cost[res] or 0) + qty
    end
end

-- Ajoute une récompense à un tour donné (ex: PN, ressources, etc.)
function Timetable:addRewardAtTurn(turn, rewardTable)
    local cell = self.turns[turn]
    if not cell then return end
    for res, qty in pairs(rewardTable) do
        cell.reward[res] = (cell.reward[res] or 0) + qty
    end
end

----------------------------------------------------
-- APPLICATION D’UN TOUR
----------------------------------------------------

-- Applique les effets (coûts et récompenses) du tour indiqué
-- Retourne un tableau de résumé textuel (ex: {"+1 PN", "-2 nourriture"})
function Timetable:applyTurn(turn)
    local cell = self.turns[turn]
    if not cell then return {} end

    local summary = {}

    -- Application des coûts
    for res, qty in pairs(cell.cost) do
        if qty ~= 0 then
            self.owner:removeResource(res, qty)
            table.insert(summary, string.format("-%d %s", qty, res))
        end
    end

    -- Application des récompenses
    for res, qty in pairs(cell.reward) do
        if qty ~= 0 then
            self.owner:addResource(res, qty)
            table.insert(summary, string.format("+%d %s", qty, res))
        end
    end

    return summary
end

----------------------------------------------------
-- OUTILS / HELPERS
----------------------------------------------------

-- Vérifie si le tour contient au moins un effet (cost ou reward)
function Timetable:hasTurnEffect(turn)
    local cell = self.turns[turn]
    if not cell then return false end

    for _, qty in pairs(cell.cost) do
        if qty ~= 0 then return true end
    end
    for _, qty in pairs(cell.reward) do
        if qty ~= 0 then return true end
    end

    return false
end

-- Efface tout le contenu d’un tour (utile si on annule un effet planifié)
function Timetable:clearTurn(turn)
    if self.turns[turn] then
        self.turns[turn].cost = {}
        self.turns[turn].reward = {}
    end
end

-- Pour debug ou UI : renvoie une vue simplifiée de la timetable
function Timetable:getOverview()
    local overview = {}
    for t = 1, #self.turns do
        local cell = self.turns[t]
        local costCount, rewardCount = 0, 0
        for _, v in pairs(cell.cost) do costCount = costCount + v end
        for _, v in pairs(cell.reward) do rewardCount = rewardCount + v end
        overview[t] = { turn = t, cost = costCount, reward = rewardCount }
    end
    return overview
end
