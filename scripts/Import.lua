local Import = {}

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

function Import.fromASSET(self, asset)
	
end

return Import