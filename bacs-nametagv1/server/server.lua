local QBCore = exports['qb-core']:GetCoreObject()
local PlayerNames = {}
local joinTimes = {}
local stream = {}
local OilRig = {}
local Yacht = {}

CreateThread(function()
    local result = MySQL.query.await("SHOW COLUMNS FROM `names` LIKE 'firstJoin'")
    if not result or #result <= 0 then
        MySQL.query([[
            ALTER TABLE `names`
            ADD COLUMN `firstJoin` INT(11) NULL DEFAULT UNIX_TIMESTAMP()
        ]])
    end 
end)

function output(text, target)
	if IsDuplicityVersion() then --Server Side
		TriggerClientEvent("chat:addMessage", target or -1, {
			color = { 255, 0, 0 },
			multiline = true,
			args = { "Server", text },
		})
	else
		TriggerEvent("chat:addMessage", {
			color = { 255, 0, 0 },
			multiline = true,
			args = { "Server", text },
		})
	end
end

RegisterNetEvent('CheckPlayerdata',function(citizenid, firstname, lastname)
    local result = MySQL.query.await('SELECT * FROM names WHERE citizenid = ?', { citizenid })
    if not result or #result == 0 then
        local insert_result = MySQL.insert.await('INSERT INTO names (`citizenid`, `firstname`, `lastname`) VALUES (?, ?, ?)', { citizenid, firstname, lastname })
    end 
end)

function getPlayerNames(citizenid)
    local result = MySQL.query.await("SELECT firstname, lastname FROM names WHERE citizenid = ?", { citizenid })
    --print("getPlayerNames result:", json.encode(result))  -- 結果をログに出力
    names_result = json.encode(result)
    return names_result
end

function getPlayerFirstJoin(citizenid)
	local result = MySQL.query.await("SELECT firstJoin FROM names WHERE citizenid = ?", { citizenid })
    --print("getPlayerFirstJoin result:", json.encode(result))  -- 結果をログに出力
    FirstJoin_result = json.encode(result)
	return FirstJoin_result
end

function getlist()
    local player = QBCore.Functions.GetPlayer(source) 
	if player == 0 then
		return
	end
    if not OilRig[player] then
        OilRig[player] = true
        TriggerClientEvent('okokNotify:Alert', player, 'バッチ', 'バッチを付けた', 3000, 'info', true)
    else 
        OilRig[player] = not OilRig[player]
        TriggerClientEvent('okokNotify:Alert', player, 'バッチ', 'バッチを外した', 3000, 'info', true)
    end
    if not Yacht[player] then
        Yacht[player] = true
        TriggerClientEvent('okokNotify:Alert', player, 'バッチ', 'バッチを付けた', 3000, 'info', true)
    else 
        Yacht[player] = not Yacht[player]
        TriggerClientEvent('okokNotify:Alert', player, 'バッチ', 'バッチを外した', 3000, 'info', true)
    end
    TriggerClientEvent("receiveOilRig", -1, OilRig)
    TriggerClientEvent("receiveYacht", -1, Yacht)
end

RegisterNetEvent('requestPlayerData',function(citizenid, serverid)
    if not PlayerNames[serverid] then 
        local result = getPlayerNames(citizenid)
        local decoded_result = json.decode(result)
        local firstname, lastname = decoded_result[1].firstname, decoded_result[1].lastname
        local newName = firstname .. " " .. lastname
        --print('名前 | '.. newName)
        PlayerNames[serverid] = newName
    end 

    if not joinTimes[serverid] then 
        local result = getPlayerFirstJoin(citizenid)
        local decoded_result = json.decode(result)
        local firstJoin = decoded_result[1].firstJoin -- 非同期関数を待つ
        --print('初期値 | ',firstJoin)
        joinTimes[serverid] = firstJoin
    end 
    TriggerClientEvent("receivePlayerNames", -1, PlayerNames, joinTimes)
end)

CreateThread(function()
	Wait(1000)
	for _, player in pairs(GetPlayers()) do
		xPlayer = QBCore.Functions.GetPlayer(player)
		if not xPlayer then
			return
		end
		citizenid = xPlayer.PlayerData.citizenid
        if not PlayerNames[player] then
            local result = getPlayerNames(citizenid)
            local decoded_result = json.decode(result)
            local firstname, lastname = decoded_result[1].firstname, decoded_result[1].lastname
            local newName = firstname .. " " .. lastname
			PlayerNames[player] = newName
		end
		if not joinTimes[player] then
            local result = getPlayerFirstJoin(citizenid)
            local decoded_result = json.decode(result)
            local firstJoin = decoded_result[1].firstJoin -- 非同期関数を待つ
            joinTimes[player] = firstJoin
		end
	end
	TriggerClientEvent("receivePlayerNames", -1, PlayerNames, joinTimes)
end)

function updatePlayerNames(citizenid, newFirstname, newLastname)
    local result = MySQL.query.await("UPDATE names SET firstname = ?, lastname = ? WHERE citizenid = ?", { newFirstname, newLastname, citizenid })
    return json.encode(result)
end
function updateSpeakerStatus(citizenid,arg)
    local result = MySQL.query.await("UPDATE names SET speakstatus = ? WHERE citizenid = ?", { arg, citizenid })
    return json.encode(result)
end


RegisterCommand("changename", function(player, args, cmd)
	if player == 0 then
		return
	end

	if #args < 2 then
        TriggerClientEvent('okokNotify:Alert', player, 'エラー', '何かが間違っています', 3000, 'error', true)
		return output("/changename [ファーストネーム] [ラストネーム]", player)
	end

	selfplayer = QBCore.Functions.GetPlayer(player)

	citizenid = selfplayer.PlayerData.citizenid

	local newName = table.concat(args, " ")
	local firstname, lastname = string.match(newName, "(.*)% (.*)")
    
    local maxNameLength = 255  -- firstname および lastname の最大長
    -- firstname の長さが制限を超えているかをチェック
    if #firstname > maxNameLength then
        print("エラー: ファーストネームが長すぎます 255文字以下にしてください")
        TriggerClientEvent('okokNotify:Alert', player, 'エラー', 'ファーストネームが長すぎます', 3000, 'error', true)
        return
    end
    -- lastname の長さが制限を超えているかをチェック
    if #lastname > maxNameLength then
        print("エラー: ラストネームが長すぎます 255文字以下にしてください")
        TriggerClientEvent('okokNotify:Alert', player, 'エラー', 'ラストネームが長すぎます', 3000, 'error', true)
        return
    end

	local success = updatePlayerNames(citizenid, firstname, lastname)
    local success_result = json.decode(success)
    --print(success)
    
    if success_result.changedRows > 0 then
        PlayerNames[player] = newName
        TriggerClientEvent("receivePlayerNames", -1, PlayerNames, joinTimes)
        --print("更新が完了しました")
        TriggerClientEvent('okokNotify:Alert', player, '名前変更', '名前変更されました', 3000, 'success', true)
    else
        TriggerClientEvent('okokNotify:Alert', player, '名前変更', '名前の変更に失敗しました', 3000, 'error', true)
        --print("更新に失敗しました")
    end
end, false)

RegisterCommand("stream", function(player)
	if player == 0 then
		return
	end
    if not stream[player] then
        stream[player] = true
        TriggerClientEvent('okokNotify:Alert', player, '配信バッチ', 'バッチを付けた', 3000, 'info', true)
    else 
        stream[player] = not stream[player]
        TriggerClientEvent('okokNotify:Alert', player, '配信バッチ', 'バッチを外した', 3000, 'info', true)
    end
    TriggerClientEvent("receivestreamlist", -1, stream)
end)

RegisterCommand("yacht", function(player)
	if player == 0 then
		return
	end
    if not Yacht[player] then
        Yacht[player] = true
        TriggerClientEvent('okokNotify:Alert', player, 'バッチ', 'バッチを付けた', 3000, 'info', true)
    else 
        Yacht[player] = not Yacht[player]
        TriggerClientEvent('okokNotify:Alert', player, 'バッチ', 'バッチを外した', 3000, 'info', true)
    end
    TriggerClientEvent("receiveYacht", -1, Yacht)
end)

RegisterCommand("oilrig", function(player)
	if player == 0 then
		return
	end
    if not OilRig[player] then
        OilRig[player] = true
        TriggerClientEvent('okokNotify:Alert', player, 'バッチ', 'バッチを付けた', 3000, 'info', true)
    else 
        OilRig[player] = not OilRig[player]
        TriggerClientEvent('okokNotify:Alert', player, 'バッチ', 'バッチを外した', 3000, 'info', true)
    end
    TriggerClientEvent("receiveOilRig", -1, OilRig)
end)