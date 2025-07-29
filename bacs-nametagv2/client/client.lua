local QBCore = exports['qb-core']:GetCoreObject()

local playerss = {}
local newbiess = {}
local streams = {}
local togspeakers = {}
local LoadPlayers = {}


local NamesVisible = true 
local MyName =true
local Thread = false 
local localped = nil

--player loaded
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    Citizen.Wait(2000)
    xPlayer = QBCore.Functions.GetPlayerData()
    firstname = xPlayer.charinfo.firstname
	lastname = xPlayer.charinfo.lastname
    citizenid = xPlayer.citizenid
	serverid = GetPlayerServerId(PlayerId())
    TriggerServerEvent('CheckPlayerdata', citizenid, firstname, lastname)
    Citizen.Wait(1000)
    TriggerServerEvent('RequestPlayers',citizenid, serverid)
    TriggerServerEvent('RequestStreams')
    
end)

-- Receive and process from server
RegisterNetEvent('ReceivePlayers', function(player, newbies)
    playerss = player
    newbiess = newbies
end)
RegisterNetEvent('ReceiveStreams', function(stream)
    streams = stream
end)

--  function
function DrawText3D(coords, texts, scale, alpha)
	scale = scale or 1
	SetDrawOrigin(coords)
	for _, text in pairs(texts) do
		SetTextScale((text.scale or 0.3) * scale, (text.scale or 0.3) * scale)
		SetTextFont(0)
		local r, g, b = table.unpack(text.color or { 255, 255, 255, alpha })
		r = r or 255
		g = g or 255
		b = b or 255
		SetTextWrap(0.0, 1.0)
		SetTextColour(r, g, b, math.floor(alpha))
		SetTextOutline()
		SetTextCentre(1)
		BeginTextCommandDisplayText("STRING")
		AddTextComponentString(text.text)
		local x, y = table.unpack(text.pos or { 0, 0 })
		EndTextCommandDisplayText(x or 0, y or 0)
	end
	ClearDrawOrigin()
end
function getPedHeadCoords(ped)
	local coords = GetWorldPositionOfEntityBone(ped, GetPedBoneIndex(ped, 31086))
	coords = coords == vector3(0, 0, 0) and GetEntityCoords(ped) + vector3(0, 0, 0.9) or coords + vector3(0, 0, 0.3)
	local frameTime <const> = GetFrameTime()
	local vel <const> = GetEntityVelocity(ped)
	coords = vector3(coords.x + vel.x * frameTime, coords.y + vel.y * frameTime, coords.z + vel.z * frameTime)
	return coords
end

function isNewbie(serverId)
	--print(newbiess[serverId])
	return (newbiess[serverId] or 0) + beginner.time > GetCloudTimeAsInt()
end

--  loop
function playerStreamer()
	while NamesVisible do
		LoadPlayers = {}
		localPed = PlayerPedId()
		local localCoords <const> = GetEntityCoords(localPed)
		local localId <const> = PlayerId()
		for _, player in pairs(GetActivePlayers()) do
			local playerPed <const> = GetPlayerPed(player)
			if player == localId and MyName or player ~= localId then
				if DoesEntityExist(playerPed) and HasEntityClearLosToEntity(localPed, playerPed, 17) and IsEntityVisible(playerPed) then
					local playerCoords = GetEntityCoords(playerPed)
					--print(playerCoords)
					if IsSphereVisible(playerCoords, 0.0099999998) then
						local distance <const> = #(localCoords - playerCoords)

						local serverId <const> = tonumber(GetPlayerServerId(player))
						if serverId and distance <= d_Distance and playerss[serverId] then
							
							local label = (playerss[serverId] or "")
							label = label.. " (" .. serverId .. ")"
							LoadPlayers[serverId] = {
								playerId = player,
								ped = playerPed,
								label = label,
								newbie = isNewbie(serverId),
								streamer_pl = streams[serverId],
							}
						end
					end
				end
			end
		end
		if next(LoadPlayers) and not Thread then
			CreateThread(drawNames)
		end
		Citizen.Wait(500)
	end
	LoadPlayers = {}
end
CreateThread(playerStreamer)

function drawNames()
	Thread = true
	while next(LoadPlayers) do
		serverid = GetPlayerServerId(PlayerId())
		local myCoords <const> = GetEntityCoords(localPed)
		for citizenid, playerData in pairs(LoadPlayers) do
			local coords <const> = getPedHeadCoords(playerData.ped)
			local dist <const> = #(coords - myCoords)
			local scale <const> = 1 - dist / d_Distance
			if scale > 0 then
				local newbieVisible <const> = playerData.newbie
				local labelText = playerData.label
				if  stream.Enable == true then
					if playerData.streamer_pl and not labelText:find(stream.stream_icon) then
						labelText = stream.stream_icon..' '..labelText
					end
				end
				if	beginner.Enable == true then
					if newbieVisible and not labelText:find(beginner.newbie_text) then
						labelText = labelText .. ' ' .. beginner.newbie_text
					end
				end
				local mapping = coords
				local newCoords = vector3(mapping.x, mapping.y, mapping.z + 0.1)
				DrawText3D(newCoords, {
					{
						text = labelText,
						color = {255, 255, 255},
						scale = 0.46,
					},
				}, scale, 255)
			end
		end

		Citizen.Wait(0)
	end

	Thread = false
end

-- Commands
