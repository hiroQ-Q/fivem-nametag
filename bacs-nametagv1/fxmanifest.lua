fx_version "cerulean"
lua54 'yes'
game "gta5"

author "hiro"
description 'bacs-nametag @hiroq_q_m'
version '1.0.0'

shared_script{
	"config/config.lua"
}

client_script{
	"config/utils.lua",
	"client/client.lua",
}

server_script{
	'@oxmysql/lib/MySQL.lua',
	"server/server.lua"
	
}

escrow_ignore {
	"config/config.lua"
}