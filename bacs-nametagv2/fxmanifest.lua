fx_version 'cerulean'
game 'gta5'
lua54 'yes'

auther 'bacs-scripts'
description 'bacs-nametag v2'
version '1.0.0' 

client_script{
	'client/client.lua',
}

server_script{
	'@oxmysql/lib/MySQL.lua',
	'server/server.lua'
}

shared_script{
	'config/config.lua',
    'locales.lua'
}

escrow_ignore {
	'config/config.lua',
	'locales.lua'
}