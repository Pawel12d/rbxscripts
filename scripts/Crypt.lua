local Crypt = {}

local HttpService = game:GetService("HttpService")

function Crypt.JSONEncode(self, data)
	data = data or self
	return HttpService:JSONEncode(data)
end

function Crypt.JSONDecode(self, data)
	data = data or self
	return HttpService:JSONDecode(data)
end

return Crypt

--[[
function encode(data, depth)
    local depth = 1
    local result = data
    
    if typeof(data) == "table" then
        result = "["
        
        for i,v in pairs(data) do
            if typeof(i) == "number" then
                
            elseif typeof(i) == "string" then
                result = result .. [["]] .. i .. [[":]] .. encode(v, depth + 1)
            end
        end
    end
    
    return result
end

local test = {a = {"a","b","c"}}

print("orig", game.HttpService:JSONEncode(test))

print("mine", encode(test))
--]]