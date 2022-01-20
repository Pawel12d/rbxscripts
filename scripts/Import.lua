local LoadString, request, getcustomasset, getobjects, HttpService = ...

if not isfolder("temp-assets") then
	makefolder("temp-assets")
end

local onClose; onClose = hookfunc(game.OnClose, function(...)
	delfolder("temp-assets")
	return onClose(...)
end

local Import = {} -- F: getobjects, httpget, httppost, fromRBXM, fromASSET

function Import.getobjects(self, data)
	data = data or self
	return getobjects(game, data)
end

function Import.httpget(self, data)
	data = data or self
	return request({Url = data}).Body
end

function Import.httppost(self, url, body)
	body = body or url
	url = typeof(url) == "string" and url or self
	return request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body})
end

function Import.fromRBXM(self, rbxm)
	
end

function Import.fromASSET(self, data)
	data = data or self
	local name = "temp-assets/asset-" .. math.random(1, 999999999) .. ".temp"
	writefile(name, data)
	return getcustomasaset(name)
end

return Import