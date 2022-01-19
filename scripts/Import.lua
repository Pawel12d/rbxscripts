local Import = {}

function Import.httpget(self, url)
	url = url or self
	return request({Url = url}).Body
end

function Import.httppost(self, url, body)
	url = url:sub(1,4) == "http" and url or body
	return request({Url = url}).Body
end

function Import.fromRBXM(self, rbxm)
	
end

function Import.fromASSET(self, asset)
	
end

return Import