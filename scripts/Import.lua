if not isfolder("temp-assets") then
	makefolder("temp-assets")
end

game.OnClose = function()
	if isfolder("temp-assets") then
		delfolder("temp-assets")
	end
end

local Import = {} -- getobjects, httpget, httppost, fromRBXM, fromASSET

function Import.getobjects(self, url)
	url = url or self
	return getobjects(game, url)
end

function Import.httpget(self, url)
	url = url or self
	return request({Url = url}).Body
end

function Import.httppost(self, url, body)
	body = body or url
	url = typeof(url) == "string" and url or self
	return request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body})
end

function Import.fromRBXM(self, rbxm)
	
end

function Import.fromASSET(self, data)
	local name = "temp-assets/asset-" .. math.random(1, 999999999) .. ".temp"
	writefile(name, data)
	return getcustomasaset(name)
end

return Import