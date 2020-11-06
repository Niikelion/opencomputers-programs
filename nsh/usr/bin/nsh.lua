local shell = require("shell")
local event = require("event")
local keyboard = require("keyboard")
local modem = require("component").modem
local term = require("term")

local port = 22297

local args, ops = shell.parse(...)

local stop = false

if ops["p"] ~= nil then
	port = ops["p"]
end

local messages = {}

modem.open(port);

local server = nil
local waiting = false
local returnedMsg = nil

if ops["d"] == true then
	server = args[1]
end

function split (inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

local function hostScanner(_,_,sender,p,_,cmd,hostname)
	if p == port and cmd == "h" then
		local msg = hostname..": "..sender
		if messages[msg] == nil then
			messages[msg] = true
			term.write(msg)
		end
	end
end

local function handleResponse(_,_,sender,p,_,cmd,msg)
	if p == port and cmd == "r" then
		server = sender
		returnedMsg = msg
		waiting = false
	end
end

local function stopHandler(_,_,c,code,player)
	if code == 32 and keyboard.isControlDown() then
		stop = true
	end
end

local function handleListerEvent(id, ...)
	if id == "modem_message" then
		hostScanner(id,...)
	elseif id == "key_down" then
		stopHandler(id,...)
	end
end

local function sendMessage(...)
	if server == nil then
		modem.broadcast(port,...)
	else
		modem.send(server,port,...)
	end
end

local function sendCommand(line)
	sendMessage("cmd",line)
end

local function printPrefix()
	_,y = term.getCursor()
	term.write("remote #")
	term.setCursor(string.len("remote #")+1,y)	
end

if ops["l"] == true then
	while stop == false do
		handleListerEvent(event.pull())
	end
else
	sendMessage("connect",args[1])
	event.listen("modem_message",handleResponse)
	printPrefix()
	local line = term.read()
	while line ~= nil and line ~= false do
		sendCommand(line)
		waiting = true
		while waiting == true do
			term.pull()
		end
		term.write(returnedMsg)
		printPrefix()
		line = term.read()
	end
	sendMessage("disconnect",args[1])
	event.ignore("modem_message",handleResponse)
end