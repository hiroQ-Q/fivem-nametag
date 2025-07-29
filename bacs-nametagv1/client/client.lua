local QBCore = exports['qb-core']:GetCoreObject()

local player_list = {}
local newbie_list = {}
local stream_list = {}
local OilRig_list = {}
local Yacht_list = {}

local streamedPlayers = {}

local myName = true 
local nameThread = false
local namesVisible = true
local localPed = nil

RegisterCommand("allnames", function()
	setNamesVisible(not namesVisible)
	if namesVisible then
		exports['okokNotify']:Alert('allnames', '全体の名前を表示にしました(個人)', 3000, 'success', true)
	else
		exports['okokNotify']:Alert('allnames', '全体の名前を非表示にしました(個人)', 3000, 'success', true)
	end

end)

RegisterCommand("myname", function()
	myName = not myName
	if myName then
		exports['okokNotify']:Alert('myName', '全体の名前を表示にしました(個人)', 3000, 'success', true)

	else
		exports['okokNotify']:Alert('myName ', '全体の名前を非表示にしました(個人)', 3000, 'success', true)
	end

end)

AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
	Wait(1000)
    xPlayer = QBCore.Functions.GetPlayerData()
    firstname = xPlayer.charinfo.firstname
	lastname = xPlayer.charinfo.lastname
    citizenid = xPlayer.citizenid
	serverid = GetPlayerServerId(PlayerId())
    TriggerServerEvent('CheckPlayerdata', citizenid, firstname, lastname)
    Wait(1000)
    TriggerServerEvent('requestPlayerData',citizenid, serverid)
	TriggerServerEvent('getlist')
end)

RegisterNetEvent("receivePlayerNames", function(names, newbies)
	player_list = names
	newbie_list = newbies
end)

RegisterNetEvent("receivestreamlist", function(names)
	stream_list = names
end)

RegisterNetEvent("receiveYacht", function(names)
	Yacht_list = names
end)
RegisterNetEvent("receiveOilRig", function(names)
	OilRig_list = names
end)


function isNewbie(serverId)
	return (newbie_list[serverId] or 0) + newbie_time > GetCloudTimeAsInt()
end

function playerStreamer()
	while namesVisible do
		streamedPlayers = {}
		localPed = PlayerPedId()

		local localCoords <const> = GetEntityCoords(localPed)
		local localId <const> = PlayerId()

		for _, player in pairs(GetActivePlayers()) do
			local playerPed <const> = GetPlayerPed(player)

			if player == localId and myName or player ~= localId then
				if DoesEntityExist(playerPed) and HasEntityClearLosToEntity(localPed, playerPed, 17) and IsEntityVisible(playerPed) then
					local playerCoords = GetEntityCoords(playerPed)
					--print(playerCoords)
					if IsSphereVisible(playerCoords, 0.0099999998) then
						local distance <const> = #(localCoords - playerCoords)

						local serverId <const> = tonumber(GetPlayerServerId(player))
						if serverId and distance <= distance_now and player_list[serverId] then
							
							local label = (player_list[serverId] or "")
							label = label.. " (" .. serverId .. ")"
							streamedPlayers[serverId] = {
								playerId = player,
								ped = playerPed,
								label = label,
								newbie = isNewbie(serverId),
								streamer_pl = stream_list[serverId],
								Yachtt = Yacht_list[serverId],
								OilRigg = OilRig_list[serverId],
								talking = MumbleIsPlayerTalking(player) or NetworkIsPlayerTalking(player),
							}
						end
					end
				end
			end
		end

		if next(streamedPlayers) and not nameThread then
			CreateThread(drawNames)
		end

		Wait(500)
	end

	streamedPlayers = {}
end
CreateThread(playerStreamer)

function drawNames()
	nameThread = true
	while next(streamedPlayers) do
		serverid = GetPlayerServerId(PlayerId())
		local myCoords <const> = GetEntityCoords(localPed)

		for citizenid, playerData in pairs(streamedPlayers) do
			local coords <const> = getPedHeadCoords(playerData.ped)

			local dist <const> = #(coords - myCoords)
			local scale <const> = 1 - dist / distance_now
			local scale1 <const> = 0.2 + dist / distance_now
			--local scale2 <const> = 0.1 + dist / distance_now

			if scale > 0 then
				local newbieVisible <const> = playerData.newbie

				local labelText = playerData.label

				
				if playerData.streamer_pl and not labelText:find(stream_icon) then
					labelText = stream_icon..' '..labelText
				end
				if newbieVisible and not labelText:find(newbie_text) then
					labelText = newbie_text .. ' ' .. labelText
				end
				
				if playerData.Yachtt and not labelText:find(Yacht_icon) then
					labelText = labelText .. ' | ' .. Yacht_icon
				end
				if playerData.OilRigg and not labelText:find(OilRig_icon) then
					labelText = labelText .. ' | ' .. OilRig_icon
				end
				

				local mapping = coords
				--print(mapping)
				local newCoords = vector3(mapping.x, mapping.y, mapping.z + scale1)
				--print(newCoords)
				--print('coords | '..coords ..' | '.. newCoords)
				DrawText3D(newCoords, {
					{
						text = labelText,
						color = {255, 255, 255},
						scale = 0.46,
					},
				}, scale, 255)

				--[[local newCoords1 = vector3(newCoords.x, newCoords.y, newCoords.z + scale2)
				local labelText1 = ''
				if playerData.Yachtt and not labelText:find(Yacht_icon) then
					labelText1 = labelText1 .. Yacht_icon
				end
				if playerData.OilRigg and not labelText:find(OilRig_icon) then
					labelText1 = labelText1 .. OilRig_icon
				end

				DrawText3D(newCoords1, {
					{
						text = labelText1,
						color = {255, 255, 255},
						scale = 0.46,
					},
				}, scale, 255)]]--
			end
		end

		Wait(0)
	end

	nameThread = false
end

Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/changename', '名前の変更', {
		{ name="ファーストネーム", help="ファーストネーム" },
		{ name="ラストネーム", help="ラストネーム" }
	})
	TriggerEvent('chat:addSuggestion', '/stream', '配信バッチの表示の切り替え')
	TriggerEvent('chat:addSuggestion', '/allnames', '全体の名前を表示切り替え(個人)')
	TriggerEvent('chat:addSuggestion', '/myname', '全体の名前を表示切り替え(個人)')
	Wait(60)
end)

function setMyNameVisible(state)
	myName = state
end
exports("setMyNameVisible", setMyNameVisible)

function getMyNameVisible()
	return myName
end
exports("getMyNameVisible", getMyNameVisible)

function setNamesVisible(state)
	namesVisible = state
	if namesVisible then
		CreateThread(playerStreamer)
	end
end
exports("setNamesVisible", setNamesVisible)

exports("isNamesVisible", function()
	return namesVisible
end)