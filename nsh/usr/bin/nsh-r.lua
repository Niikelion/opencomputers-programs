local modem = require("component").modem

local config = {
	port = 22297
}

local args = {...}
local sender = args[1]

local term = require("term")

local line = term.read()

local msg = ""

while line ~= nil and line ~= false do
	if msg == "" then
		 msg = line
	else 
		msg = msg .. line
	end
	line = term.read()
end
modem.send(sender,config.port,"r",msg)