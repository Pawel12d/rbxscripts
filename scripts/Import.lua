local fetch = fetch or request or http_request or (http and http.request) or (syn and syn.request)
local get_custom_asset = get_custom_asset or getcustomasset or getsynasset
local task_spawn = task.spawn

local Import = {}
function Import:Fetch(...)
    return fetch(...)
end
Import.fetch = Import.Fetch
Import.Request = Import.Fetch
Import.request = Import.Fetch

function Import:GetObjects(...)
    return game:GetObjects(...)
end

function Import.HttpGet(self: table, url: string)
    url = type(self) == "table" and url or self
    return game:HttpGet(url)
end
Import.http_get = Import.HttpGet

function Import.HttpPost(self: table, url: string)
    url = type(self) == "table" and url or self
    return game:HttpPost(url)
end
Import.http_post = Import.HttpPost

function Import.Compile(self, scr)
    if typeof(self) == "Instance" then
        scr = self
    end 
    if scr.Disabled then
        return
    end
    print(type(scr))
    local f = loadstring(scr.Source)
    getfenv(f).script = scr
    task_spawn(f)
end

function Import:LoadScripts(path: Instance)
    local tbl = path:GetDescendants()
    table.insert(tbl, path)
    for i,v in pairs(tbl) do
        if (v:IsA("Script") or v:IsA("LocalScript")) then
            v:GetPropertyChangedSignal("Disabled"):Connect(function()
                Import:Compile(v)
            end)
            Import:Compile(v)
        end
    end
end

function Import:Asset(...)
    local f = "temp/" .. tostring(os.time() + tick() % 1) .. ".asset"
    writefile(f, ...)
    return get_custom_asset(f)
end
Import.asset = Import.Asset

function Import:RBXM(...)
    return Import:GetObjects(Import:Asset(...))
end
Import.rbxm = Import.RBXM

function Import.require(self: table, module)
    module = type(self) == "table" and module or self
    if type(module) == "number" then
        local m = Import:GetObjects("rbxassetid://"..module)
        local mm = m[1]

        assert(mm, "empty object")
        assert(mm.Name == "MainModule", "module does not contain Instance MainModule")

        Import:LoadScripts(mm)

        return response
    end

    return require(module)
end
Import.Require = Import.require

return Import