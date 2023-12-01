local util = {}
util.allocateMemory = allocateMemory;
util.startThread = executeCode;
util.freeMemory = deAlloc;

openProcess("RobloxPlayerBeta.exe")
openProcess("Windows10Universal.exe")

util.aobScan = function(aob, code)
	local new_results = {}
	local results = AOBScan(aob, "*X*C*W")
	if not results then
		return new_results
	end
	for i = 1,results.Count do
		local x = getAddress(results[i - 1])
		table.insert(new_results, x)
	end
	return new_results
end

util.intToBytes = function(val)
	if val == nil then
		error'Cannot convert nil value to byte table'
	end
	local t = { val & 0xFF }
	for i = 1,7 do
		table.insert(t, (val >> (8 * i)) & 0xFF)
	end
	return t
end

util.stringToBytes = function(str)
	local result = {}
	for i = 1, #str do
		table.insert(result, string.byte(str, i))
	end
	return result
end

local strexecg, game = ''

local Players, nameOffset, valid, game, parentOffset, childrenOffset, dataModel, childrenOffset, LocalPlayerOffset, LocalPlayer

local rapi = {}
rapi.toInstance = function(address)
	return setmetatable({}, {
		__index = function(self, name)
			if name == "self" then
				return address
			elseif name == "Name" then
				local ptr = readQword(self.self + nameOffset)
				if ptr then
					local fl = readQword(ptr + 0x18)
					if fl == 0x1F then
						ptr = readQword(ptr)
					end

					if readString(readQword(ptr)) then
						return readString(readQword(ptr))
					end

					return readString(ptr)
				else
					return "???"
				end
			elseif name == "JobId" then
				if self.self == dataModel then
					return readString(readQword(dataModel + jobIdOffset))
				end

				return self:findFirstChild(name)
			elseif name == "className" or name == "ClassName" then
				local ptr = readQword(self.self + 0x18) or 0
				ptr = readQword(ptr + 0x8)
				if ptr then
					local fl = readQword(ptr + 0x18)
					if fl == 0x1F then
						ptr = readQword(ptr)
					end
					return readString(ptr)
				else
					return "???"
				end
			elseif name == "Parent" then
				return rapi.toInstance(readQword(self.self + parentOffset))
			elseif name == "getChildren" or name == "GetChildren" then
				return function(self)
					local instances = {}
					local ptr = readQword(self.self + childrenOffset)
					if ptr then
						local childrenStart = readQword(ptr + 0)
						local childrenEnd = readQword(ptr + 8)
						local at = childrenStart
						if not at or not childrenEnd then
							return instances
						end
						while at < childrenEnd do
							local child = readQword(at)
							table.insert(instances, rapi.toInstance(child))
							at = at + 16
						end
					end
					return instances
				end
			elseif name == "findFirstChild" or name == "FindFirstChild" then
				return function(self, name)
					for _, v in pairs(self:getChildren()) do
						if v.Name == name then
							return v
						end
					end
					return nil
				end
			elseif name == "findFirstClass" or name == "FindFirstClass" or name == "FindFirstChildOfClass" then
				return function(self, name)
					for _, v in pairs(self:getChildren()) do
						if v.className == name then
							return v
						end
					end
					return nil
				end
			elseif name == "setParent" or name == "SetParent" then
				return function(self, new)
					writeQword(self.self + parentOffset, new.self)
					local newChildren = util.allocateMemory(0x400)
					writeQword(newChildren + 0, newChildren + 0x40)
					local ptr = readQword(new.self + childrenOffset)
					local childrenStart = readQword(ptr + 0) or 0
					local childrenEnd = readQword(ptr + 8) or 0
					local b = readBytes(childrenStart, childrenEnd - childrenStart, true)
					writeBytes(newChildren + 0x40, b)
					local e = newChildren + 0x40 + (childrenEnd - childrenStart)
					writeQword(e, self.self)
					writeQword(e + 8, readQword(self.self + 0x10))
					e = e + 0x10
					writeQword(newChildren + 0x8, e)
					writeQword(newChildren + 0x10, e)
				end
			elseif name == "value" or name == "Value" then
				if self.className == "StringValue" then
					return readString(self.self + 0xC0)
				elseif self.className == "BoolValue" then
					return readByte(self.self + 0xC0) == 1
				elseif self.className == "IntValue" then
					return readInteger(self.self + 0xC0)
				elseif self.className == "NumberValue" then
					return readDouble(self.self + 0xC0)
				elseif self.className == "ObjectValue" then
					return rapi.toInstance(readQword(self.self + 0xC0))
				elseif self.className == "Vector3Value" then
					local x = readFloat(self.self + 0xC0)
					local y = readFloat(self.self + 0xC4)
					local z = readFloat(self.self + 0xC8)
					return {
						X = x,
						Y = y,
						Z = z
					}
				else
					print("Value read failed, indexing Instance instead")
					return self:findFirstChild(name)
				end
			elseif name == "Disabled" then
				if self.className == "LocalScript" then
					return readByte(self.self + 0x1EC) == 1
				end

				return self:findFirstChild(name)
			elseif name == "Enabled" then
				if self.className == "LocalScript" then
					return readByte(self.self + 0x1EC) == 0
				end

				return self:findFirstChild(name)
			elseif name == "DisplayName" then
				if self.className == "Humanoid" then
					return readString(self.self + 728)
				end

				return self:findFirstChild(name)
			elseif name == "LocalPlayer" or name == "LocalPlayer" then
				return rapi.toInstance(readQword(Players.self + LocalPlayerOffset))
			elseif name == "GetService" or name == "getService" then
				return function(self, name)
					return self:findFirstChild(name)
				end
			elseif name == "Locked" then
				return readByte(self.self + 0x1BA) == 1
			else
				return self:findFirstChild(name)
			end
		end,
		__newindex = function(self, name, value)
			if name == "value" or name == "Value" then
				if self.className == "StringValue" then
					writeString(self.self + 0xC0, value)
				elseif self.className == "BoolValue" then
					writeByte(self.self + 0xC0, value and 1 or 0)
				elseif self.className == "IntValue" then
					writeInteger(self.self + 0xC0, value)
				elseif self.className == "NumberValue" then
					writeDouble(self.self + 0xC0, value)
				elseif self.className == "ObjectValue" then
					writeQword(self.self + 0xC0, value.self)
				elseif self.className == "Vector3Value" then
					writeFloat(self.self + 0xC0, value.X)
					writeFloat(self.self + 0xC4, value.Y)
					writeFloat(self.self + 0xC8, value.Z)
				else
					print("Value write failed, indexing Instance instead")
					self:findFirstChild(name)
				end
			elseif name == "Disabled" then
				if self.className == "LocalScript" then
					writeByte(self.self + 0x1EC, value and 1 or 0)
				end

				self:findFirstChild(name)
			elseif name == "Enabled" then
				if self.className == "LocalScript" then
					writeByte(self.self + 0x1EC, value and 0 or 1)
				end
			elseif name == "DisplayName" then
				if self.className == "Humanoid" then
					writeString(self.self + 728, value)
				end
			elseif name == "Locked" then
				writeByte(self.self + 0x1BA, value and 1 or 0)
			elseif name == "Parent" then
				self:setParent(value)
			elseif name == "Name" then
				local ptr = readQword(self.self + nameOffset)
				if ptr then
					local fl = readQword(ptr + 0x18)
					if fl == 0x1F then
						ptr = readQword(ptr)
					end

					if readString(readQword(ptr)) then
						writeString(readQword(ptr), value)
					else
						writeString(ptr, value)
					end
				end
			end
		end,
		__metatable = "The metatable is locked",
		__tostring = function(self)
			return string.format("Instance: %s", self.Name)
		end
	})
end

local pid;

local function HttpGet(url)
	local int = getInternet()
	local res = int.getURL(url)
	int.destroy()
	return res
end

local function inject()
	openProcess("RobloxPlayerBeta.exe")
	openProcess("Windows10Universal.exe")

	if pid == getOpenedProcessID() then
		return
	end
	
	pid = getOpenedProcessID()

	local results = util.aobScan("506C6179657273??????????????????07000000000000000F")
	for rn = 1,#results do
		local result = results[rn];

		if not result then
			return false
		end

		local bres = util.intToBytes(result);
		local aobs = ""
		for i = 1,8 do
			aobs = aobs .. string.format("%02X", bres[i])
		end

		local first = false
		local res = util.aobScan(aobs)
		if res then
			valid = false
			for i = 1,#res do
				result = res[i]
				for j = 1,10 do
					local ptr = readQword(result - (8 * j))
					if ptr then
						ptr = readQword(ptr + 8)
                        if readString(ptr) == "Players" and readString(readQword(readQword(((result-(8*j))-0x18)+0x60)+0x48))== "Game" then
							--print(string.format("Got result: %08X", result))
							-- go to where the vftable is, 0x18 before classname offset (always)
							Players = (result - (8 * j)) - 0x18
							-- calculate where we just were
							nameOffset = result - Players
							value = true
							break
						end
					end
				end
				if valid then break end
			end
		end

		if valid then break end
	end

	print(string.format("Players: %08X", Players))
	print(string.format("Name offset: %02X", nameOffset))

	for i = 0x10, 0x120, 8 do
		local ptr = readQword(Players + i)
		if ptr ~= 0 and ptr % 4 == 0 then
			if (readQword(ptr + 8) == ptr) then
				parentOffset = i
				break
			end
		end
	end
	print(string.format("Parent offset: %02X", parentOffset))

	dataModel = readQword(Players + parentOffset)

	print(string.format("DataModel: %08X", dataModel))

	for i = 0x10, 0x200, 8 do
		local ptr = readQword(dataModel + i)
		if ptr then
			local childrenStart = readQword(ptr)
			local childrenEnd = readQword(ptr + 8)
			if childrenStart and childrenEnd then
				if childrenEnd > childrenStart --[[and ((childrenEnd - childrenStart) % 16) == 0]] and childrenEnd - childrenStart > 1 and childrenEnd - childrenStart < 0x1000 then
					childrenOffset = i
					break
				end
			end
		end
	end

	print(string.format("Children offset: %02X", childrenOffset))
	
	Players = rapi.toInstance(Players)
	game = rapi.toInstance(dataModel)

	for i = 0x10,0x600,4 do
		local ptr = readQword(Players.self + i)
		if readQword(ptr + parentOffset) == Players.self then
			LocalPlayerOffset = i
			break
		end
	end
	print(string.format("Players->LocalPlayer offset: %02X", LocalPlayerOffset))

	LocalPlayer = rapi.toInstance(readQword(Players.self + LocalPlayerOffset));
	print(("LocalPlayer %s [%s]"):format(LocalPlayer.self, LocalPlayer.Name))
end

local function start()
	local CoreGui = game:GetService("CoreGui")

	local Backpack = LocalPlayer:FindFirstClass("Backpack")
	local PlayerGui = LocalPlayer:FindFirstClass("PlayerGui")
	local PlayerScripts = LocalPlayer:FindFirstClass("PlayerScripts")

	local function AutoExec()
		if true then return end --HttpGet
		createNativeThread(function()
			PlayerGui.RC1.Parent = CoreGui
			local NetworkClient = game:GetService("NetworkClient")
			local GetURL = LocalPlayer.PlayerGui.RC1.Components.Loadstring.Environment.GetURL
			GetURL.Parent = NetworkClient
			while true do
				local success, response = pcall(function()
					print(GetURL.Value)
				end)
				if not success then
					print("[ERR]:", success, response)
				end
				sleep(2500)
			end
		end)
	end

	local function InjectBytecode(targetScript)
		local injectScript
		local results = util.aobScan("496E6A656374????????????????????06")
		for i=1,#results do
			local result = results[i];
			local bres = util.intToBytes(result);
			local aobs = ""

			for i = 1,8 do
				aobs = aobs .. string.format("%02X", bres[i])
			end

			local first = false
			local res = util.aobScan(aobs)

			if res then
				valid = false
				for i = 1,#res do
					result = res[i]
					--print(string.format("Result: %08X", result))

					if (readQword(result - nameOffset + 8) == result - nameOffset) then
						injectScript = result - nameOffset
						valid = true
						break
					end
				end
			end

			if valid then break end
		end

		if injectScript == nil then
			error("InjectScript not found!")
		end

		injectScript = rapi.toInstance(injectScript)
		print(string.format("Inject Script: %08X", injectScript.self))

		local oldBytes = readBytes(targetScript.self + 0x100, 0x150, true)

		local newBytes = readBytes(injectScript.self + 0x100, 0x150, true)
		writeBytes(targetScript.self + 0x100, newBytes)
		print("Bytecode injected successfully!")

		return function()
			AutoExec()
			writeBytes(targetScript.self + 0x100, oldBytes)
			print("Bytecode restored successfully!")
		end
	end

	--local char = game:GetService("Workspace")[LocalPlayer.Name]
	--char.Humanoid.Parent = game:GetService("ReplicatedStorage")
	

	-- Counter Blox
	if game:GetService("StarterGui"):FindFirstChild("CBScoreboard") then
		print(("PlayerGui %s [%s]"):format(PlayerGui.Name, PlayerGui.self))

		local FreeCam2 = PlayerGui:FindFirstChild("FreeCam2") -- ALERTA! SKIDO DETECTED
		print(("FreeCam2 %s [%s]"):format(FreeCam2.Name, FreeCam2.self))

		local RestoreBytecode = InjectBytecode(FreeCam2)
        createNativeThread(function()
            repeat sleep(200) until PlayerGui:FindFirstChild("RC1")
            print("RC1 Loaded!")
            RestoreBytecode()
        end)
		return
	end

	-- Tool
	if Backpack:FindFirstClass("Tool") then
		local RestoreBytecode = InjectBytecode(Backpack:FindFirstClass("Tool"):FindFirstClass("LocalScript"))
        createNativeThread(function()
            repeat sleep(200) until PlayerGui:FindFirstChild("RC1")
            print("RC1 Loaded!")
            RestoreBytecode()
        end)
		return
	end
end

inject()
start()