local Crypt = {}

function Crypt.JSONEncode(self, data)
	data = data or self
	return HttpService:JSONEncode(data)
end

function Crypt.JSONDecode(self, data)
	data = data or self
	return HttpService:JSONDecode(data)
end

return Crypt