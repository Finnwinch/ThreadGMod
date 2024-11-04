local FilsTraitement = {}
FilsTraitement.__index = FilsTraitement

FilsTraitement.instance = nil
FilsTraitement.executions = {}
FilsTraitement.timerID = "CoroutineUpdateTimer"

function FilsTraitement.new(RATIO)
    if FilsTraitement.instance == nil then
        local self = setmetatable({}, FilsTraitement)
        FilsTraitement.instance = self
    end
    FilsTraitement.instance.RATIO = RATIO
    return FilsTraitement.instance
end

function FilsTraitement:startTraitement(delaySeconds, traitement, nomExecution)
    if self.executions[nomExecution] then
        print("Coroutine '" .. nomExecution .. "' is already running.")
        return
    end

    local function coroutineFunction()
        while true do
            traitement()
            coroutine.yield(delaySeconds)
        end
    end

    local co = coroutine.create(coroutineFunction)
    self.executions[nomExecution] = { co = co, delay = delaySeconds }

    if next(self.executions) then
        timer.Create(self.timerID, self.RATIO, 0, function()
            self:update()
        end)
    end
end

function FilsTraitement:update()
    for nomExecution, execution in pairs(self.executions) do
        local success, delay = coroutine.resume(execution.co)
        if not success then
            print("Error in coroutine '" .. nomExecution .. "': " .. tostring(delay))
            self:stopTraitement(nomExecution)
        elseif coroutine.status(execution.co) == "dead" then
            self:stopTraitement(nomExecution)
        end
    end

    if not next(self.executions) then
        timer.Remove(self.timerID)
    end
end

function FilsTraitement:stopTraitement(nomExecution)
    if self.executions[nomExecution] then
        self.executions[nomExecution] = nil
        print("Coroutine '" .. nomExecution .. "' has been stopped.")
        
        if not next(self.executions) then
            timer.Remove(self.timerID)
        end
    else
        print("Coroutine '" .. nomExecution .. "' is not running.")
    end
end

return FilsTraitement

--[[ DEMO
function mainLoop()
    local moteur = include("gdkCoroutine.lua")
    local TICK_POST = 1
    local FRAME = 1 / 100
    local moteur = FilsTraitement.new(FRAME)
    local counter = 0
    moteur:startTraitement(TICK_POST, function()
        counter = counter + 1
        print(counter)
        if (counter == 1000) then
            moteur:stopTraitement("exampleCoroutine")
        end
    end, "exampleCoroutine")
end
mainLoop()

]]
