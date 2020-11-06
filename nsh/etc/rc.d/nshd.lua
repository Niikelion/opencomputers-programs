local term = require("term")
local event = require("event")
local modem = require("component").modem
local thread = require("thread")
local shell = require("shell")

local config = {
	port = 22297,
	hostname = "nsh host"
}

local vtcolors =
{
  black = 30,
  red = 31,
  green = 32,
  yellow = 33,
  blue = 34,
  magenta = 35,
  cyan = 36,
  white = 37
}

local function mkcolor(color)
	if io.stdout.tty and term.isAvailable() then
		return string.format("\27[%dm", color)
	else
		return ""
	end
end

function loadConfig()
end

local function commandCallback(_,_,cmd,...)
	local args = {...}
end

local users = {}

local function connectUser(sender)
	users[sender] = {
		env = {}
	}
end

local function disconnectUser(sender)
	users[sender] = nil
end

local function isConnected(sender)
	return users[sender] ~= nil
end

local function getUserEnv(sender)
	return users[sender].env
end

local broadcaster = {
	thread = 0,
	stop = false
}

function broadcaster.main()
	while broadcaster.stop == false do
		event.push("relay",config.port,"h",config.hostname)
		os.sleep(0.5)
	end
end

local function relayHandler(_,port,...)
	local msgs = {...}
	modem.broadcast(port,table.unpack(msgs))
end

local function networkHandler(_,_,sender,port,_,cmd,...)
	local args = {...}
	
	if cmd == "connect" and (args[1] == modem.address or args[1] == config.hostname) then
		connectUser(sender)
	elseif isConnected(sender) then
		if cmd == "disconnect" then
			disconnectUser(sender)
		elseif cmd == "cmd" then
			shell.execute(args[1]..' | nsh-r "'..sender..'"')
		end
	end
end

function start()
	loadConfig()
	if not modem.isOpen(config.port) then
		modem.open(config.port)
	end
	broadcaster.thread = thread.create(broadcaster.main)
	
	event.listen("modem_message",networkHandler)
	event.listen("relay",relayHandler);
end

function stop()
	broadcaster.stop = true
	event.ignore("modem_message",networkHandler)
	event.ignore("relay",relayHandler);
	thread.waitForAll({broadcaster.thread})
end