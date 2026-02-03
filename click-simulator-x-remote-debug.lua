if getgenv().CrosswalkLoaded then
    print("✅ Crosswalk already loaded (skipping)")
    return
end

local Network = {}

do
    local RemoteStorage = nil
    local RemotesFolder = nil
    local RemoteCache = {}
    local renamedCount = 0

    for _, obj in next, getgc() do
        if RemoteStorage then break end 
        if type(obj) == "table" then
            if obj.remotes and obj.currentKeys then
                RemoteStorage = obj
            end
        elseif type(obj) == "function" and islclosure(obj) and not isexecutorclosure(obj) then
            local src = debug.info(obj, "s")
            if src and src:find("Initialize") then
                for _, upv in ipairs(getupvalues(obj)) do
                    if type(upv) == "table" and upv.remotes and upv.currentKeys then
                        RemoteStorage = upv
                        break
                    end
                end
            end
        end
    end

    if not RemoteStorage then
        for _, obj in next, getgc() do
            if type(obj) == "table" and obj.remotes and obj.currentKeys then
                RemoteStorage = obj
                break
            end
        end
    end

    if not RemoteStorage then
        game.Players.LocalPlayer:Kick("❌ Crosswalk decryptor failed: RemoteStorage not found")
        return
    end

    RemotesFolder = game.ReplicatedStorage:WaitForChild("Remotes", 12)
    if not RemotesFolder then
        game.Players.LocalPlayer:Kick("❌ Remotes folder not found")
        return
    end

    if RemoteStorage.remotes then
        for moduleName, funcs in pairs(RemoteStorage.remotes) do
            for funcName, remote in pairs(funcs) do
                if typeof(remote) == "Instance" and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                    local newName = moduleName .. "." .. funcName
                    remote.Name = newName
                    RemoteCache[newName] = remote
                    renamedCount += 1
                end
            end
        end
    end

    print(`[✅] Successfully renamed & cached {renamedCount} remotes`)

    local function getKey(moduleName, funcName)
        if typeof(moduleName) == "string" and moduleName:find("%.") then
            local mod, func = moduleName:match("([^%.]+)%.(.+)")
            if mod and func then
                moduleName = mod
                funcName = func
            end
        end
        if RemoteStorage.currentKeys and RemoteStorage.currentKeys[moduleName] then
            local key = RemoteStorage.currentKeys[moduleName][funcName]
            if key and typeof(key) == "string" then
                return key
            end
            return key
        end
        return nil
    end

    local function getRemote(moduleName, funcName)
        if typeof(moduleName) == "string" and moduleName:find("%.") then
            local mod, func = moduleName:match("([^%.]+)%.(.+)")
            if mod and func then
                return getRemote(mod, func)
            end
        end
        local name = moduleName .. "." .. (funcName or "")
        return RemoteCache[name] or RemotesFolder:FindFirstChild(name, true)
    end

    function Network:GetKey(moduleName, funcName)
        return getKey(moduleName, funcName)
    end

    function Network:FireServer(moduleName, funcName, ...)
        local remote = getRemote(moduleName, funcName)
        if not remote or not remote:IsA("RemoteEvent") then
            warn(`[Network] RemoteEvent not found: {moduleName}.{funcName or ""}`)
            return
        end
        remote:FireServer(...)
    end

    function Network:InvokeServer(moduleName, funcName, ...)
        local remote = getRemote(moduleName, funcName)
        if not remote or not remote:IsA("RemoteFunction") then
            warn(`[Network] RemoteFunction not found: {moduleName}.{funcName or ""}`)
            return
        end
        return remote:InvokeServer(...)
    end

    function Network:GetRemote(moduleName, funcName)
        return getRemote(moduleName, funcName)
    end

    function Network:ListAllRemotes()
        print("\n" .. string.rep("=", 60))
        print("📋 DECRYPTED REMOTES")
        print(string.rep("=", 60))
        if RemoteStorage.remotes then
            for moduleName, funcs in pairs(RemoteStorage.remotes) do
                print(`\n📦 Module: {moduleName}`)
                for funcName, remote in pairs(funcs) do
                    local hasKey = RemoteStorage.currentKeys and RemoteStorage.currentKeys[moduleName] and RemoteStorage.currentKeys[moduleName][funcName]
                    print(`   {hasKey and "🔑" or "🔓"} {funcName} [{remote.ClassName}]`)
                end
            end
        end
        print(string.rep("=", 60))
    end

    getgenv().Network = Network
    getgenv().RemoteStorage = RemoteStorage
    getgenv().CrosswalkLoaded = true

    print("\n✅ Crosswalk decryptor loaded successfully!")
end

return Network
