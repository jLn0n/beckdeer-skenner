-- objects
local player = game:GetService("Players").LocalPlayer

-- main
return {
	["configVer"] = 9, -- don't touch this!
	-- @tweaks
	["enableLogging"] = true, -- logs anything that happens
	["redirectOutput"] = true, -- redirects output to console
	["redirectRemote"] = true, -- uses a custom created remote for server-side execution

	-- @customization
	-- $scripts that executes after backdoor is found
	-- $you can add any scripts here
	["autoExec"] = {
		[[print("jLn0n's beckdeer skenner is epic!")]],
	},

	-- $remote filters that you don't want to be scanned
	-- $should be thread-safe
	["remoteFilters"] = {
		["AdminRemotes"] = function(remoteObj)
			local remoteObjPath = remoteObj:GetFullName()

			return remoteObj:IsDescendantOf(game:GetService("ReplicatedStorage")) and (string.find(remoteObjPath, "HDAdminClient") or string.find(remoteObjPath, "Basic Admin Essentials"))
		end,
		["AdonisRemotes"] = function(remoteObj)
			return (
				(remoteObj.Parent and remoteObj.Parent:IsA("ReplicatedStorage") and remoteObj:FindFirstChild("__FUNCTION")) or
				(remoteObj.Name == "__FUNCTION" and remoteObj.Parent:IsA("RemoteEvent") and remoteObj.Parent.Parent:IsA("ReplicatedStorage"))
			)
		end,
		["RespawnRemotes"] = function(remoteObj)
			local remoteObjName = string.lower(remoteObj.Name)

			return (string.find(remoteObjName, "respawn"))
		end,
		["SkidCannonRemotes"] = function(remoteObj)
			local remoteObjPath = remoteObj:GetFullName()

			return (string.find(remoteObjPath, "JointsService") and (string.find(remoteObjPath, "Lightning Cannon") or string.find(remoteObjPath, " Cannon")))
		end,
		["RobloxReplicatedStorage"] = function(remoteObj)
			return remoteObj:IsDescendantOf(game:GetService("RobloxReplicatedStorage"))
		end,
		["RedirectedRemote"] = function(remoteObj)
			return remoteObj:GetAttribute("isNonced")
		end
	},

	-- $any macro shenanigans you can add here
	-- $prefixed as "%macro%" | example: %username% -> "Roblox", %plr_pos% -> Vector3
	["scriptMacros"] = {
		["username"] = player.Name,
		["userid"] = player.UserId,
		["placeid"] = game.PlaceId
	},

	-- $backdoor payloads
	["backdoorPayloads"] = {
		["default"] = {
			["Args"] = {"source"},
			["Priority"] = 1
		},
	},

	-- $cached backdoor remotes
	["cachedPlaces"] = {
		[5033592164] = {
			["Remote"] = game:GetService("ReplicatedStorage"):FindFirstChildWhichIsA("RemoteEvent"),
			["Args"] = {"1234567890", "source"}
		},
		[6879465970] = {
			["Remote"] = "ReplicatedStorage.RemoteEvent",
			["Args"] = {"source"}
		},
	},
}