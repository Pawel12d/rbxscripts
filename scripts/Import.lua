local Import = {}

function Import.getobjects(self, url)
	url = url or self
	return getobjects(url)
end

function Import.httpget(self, url)
	url = url or self
	return request({Url = url}).Body
end

function Import.httppost(self, url, body)
	url = url:sub(1,4) == "http" and url or self
	body = url:sub(1,4) == "http" and body or url
	return request({Url = url, Method = "POST", Headers = {['Content-Type'] = 'application/json'}, Body = body})
end

function Import.fromRBXM(self, rbxm)
	
end

function Import.fromASSET(self, asset)
	
end

return Import