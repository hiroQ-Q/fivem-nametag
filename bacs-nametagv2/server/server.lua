local QBCore = exports['qb-core']:GetCoreObject()

local playerss = {}
local firstjoin = {}
local stream = {}
local togspeaker = {}

--alart event
function alert(player,title,description,status)
    if notify == 'qb' then 
        TriggerClientEvent('QBCore:Notify', player, description, 'primary', 3000)
    elseif notify == 'okok' then 
        TriggerClientEvent('okokNotify:Alert', player, title, description, 3000, status, true)
    end
end

--loop db setup
CreateThread(function()
    local result = MySQL.query.await("SHOW COLUMNS FROM `names` LIKE 'firstJoin'")
    if not result or #result <= 0 then
        MySQL.query([[
            ALTER TABLE `names`
            ADD COLUMN `firstJoin` INT(11) NULL DEFAULT UNIX_TIMESTAMP()
        ]])
    end
end)

-- Function
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
function GetPlayer(citizenid)
    local result = MySQL.query.await('SELECT firstname, lastname FROM names WHERE citizenid = ?', { citizenid })
    result = json.encode(result)
    result = json.decode(result)
    return result
end 
function GetFirstjoin(citizenid)
    local result = MySQL.query.await('SELECT firstJoin FROM names WHERE citizenid = ?', { citizenid })
    result = json.encode(result)
    result = json.decode(result)
	return result
end
function updatePlayerNames(citizenid, newFirstname, newLastname)
    local result = MySQL.query.await("UPDATE names SET firstname = ?, lastname = ? WHERE citizenid = ?", { newFirstname, newLastname, citizenid })
    result = json.encode(result)
    result = json.decode(result)
    return result
end

--Register event
RegisterNetEvent('CheckPlayerdata',function(citizenid, firstname, lastname)
    local result = MySQL.query.await('SELECT * FROM names WHERE citizenid = ?', { citizenid })
    if not result or #result == 0 then
        local insert_result = MySQL.insert.await('INSERT INTO names (`citizenid`, `firstname`, `lastname`) VALUES (?, ?, ?)', { citizenid, firstname, lastname })
    end 
end)
RegisterNetEvent('RequestPlayers', function(citizenid, serverid)
    if not playerss[serverid] then 
        local result = GetPlayer(citizenid)
        local firstname, lastname = result[1].firstname, result[1].lastname
        local newName = firstname .. " " .. lastname
        --print('名前 | '.. newName)
        playerss[serverid] = newName
    end 
    if not firstjoin[serverid] then 
        local result = GetFirstjoin(citizenid)
        local firstJoin_time = result[1].firstJoin -- 非同期関数を待つ
        --print('初期値 | ',firstJoin_time)
        firstjoin[serverid] = firstJoin_time
    end
    TriggerClientEvent('ReceivePlayers', -1, playerss, firstjoin)
end)
RegisterNetEvent('RequestStreams',function()
    TriggerClientEvent('ReceiveStreams',stream)
end)

-- Command add
RegisterCommand('changename', function(player, args, cmd)
    if player == 0 then 
        return 
    end 

    if #args < 2 then 
        alert(player, locales.error_title, locales.error_text, 'error')
        return output(locales.changename_error, player)
    end

    xplayer = QBCore.Functions.GetPlayer(player)

	citizenid = xplayer.PlayerData.citizenid

	local newName = table.concat(args, " ")
	local firstname, lastname = string.match(newName, "(.*)% (.*)")
    
    local maxNameLength = 255
    if #firstname > maxNameLength then
        alert(player, locales.error_title, locales.error_firstname, 'error')
        return
    end
    if #lastname > maxNameLength then
        alert(player, locales.error_title, locales.error_lastname, 'error')
        return
    end

	local success = updatePlayerNames(citizenid, firstname, lastname)
    
    if success.changedRows > 0 then
        playerss[player] = newName
        TriggerClientEvent("ReceivePlayers", -1, playerss, firstjoin)
        alert(player, locales.success_title, locales.success_changename, 'success')
    else
        alert(player, locales.error_title, locales.bad_changename, 'error')
    end
end, false)

RegisterCommand("stream", function(player)
	if player == 0 then
		return
	end
    if not stream[player] then
        stream[player] = true
        alert(player, locales.stream_title, locales.stream_add, 'info')
        
    else 
        stream[player] = not stream[player]
        alert(player, locales.stream_title, locales.stream_del, 'info')
    end
    TriggerClientEvent("ReceiveStreams", -1, stream)
end)