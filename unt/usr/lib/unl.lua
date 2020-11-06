local component = require("component")

local tunnel = nil
if component.isAvailable("tunnel") then tunnel = component.tunnel end

local modem = nil
if component.isAvailable("modem") then modem = component.modem end

local event = require("event")

local sockets = {}

local unl = {}

local Socket = {}

function Socket:open()
	if modem ~= nil then
		modem.open(self.port)
	end
end
function Socket:close()
	if modem ~= nil then
		modem.close(self.port)
	end
end
function Socket:isOpen()
	if modem ~= nil then
		return modem.isOpen(self.port)
	end
	return false
end
function Socket:broadcast(...)
	if modem ~= nil then
		modem.broadcast(self.port,...)
	end
end
function Socket:sendToTunnel(...)
	if tunnel ~= nil then
		tunnel.send(self.port,...)
	end
end
function Socket:send(address,...)
	if modem ~= nil and (tunnel == nil or tunnel.getChannel() ~= address) then
		modem.send(address,self.port,...)
	end
end
function Socket:uniBroadcast(...)
	self:broadcast(...)
	if tunnel ~= nil then
		self:sendToTunnel(...)
	end
end
function Socket:uniSend(address,...)
	self:send(address,...)
	if tunnel ~= nil and address == tunnel.getChannel() then
		self:sendToTunnel(...)
	end
end
function Socket:listen(callback,allowsNetworks,allowsTunnels)
	self.listeners[callback] = {allowsNetworks = allowsNetworks, allowsTunnels = allowsTunnels}
end
function Socket:ignore(callback)
	self.listeners[callback] = nil
end

function Socket:new(o)
	o = o or {}
	if o.listeners == nil then
		o.listeners = {}
	end
	setmetatable(o, self)
	self.__index = self
	return o
end

function networkListener(name,receiver,sender,port,distance,...)
	local args = {...}
	local t = false
	if tunnel ~= nil and receiver == tunnel.address then
		port = args[1]
		sender = tunnel.getChannel()
		table.remove(args,1)
		t = true
	end
	local socket = sockets[port]
	if socket ~= nil then
		local listeners = socket.listeners
		for callback,config in pairs(listeners) do
			if (t == true and config.allowsTunnels == true) or (t == false and config.allowsNetworks == true) then
				callback(name,receiver,sender,port,distance,table.unpack(args))
			end
		end
	end
end

function unl.getSocket(port)
	socket = sockets[port]
	if socket == nil then
		socket = Socket:new({port = port})
		sockets[port] = socket
	end
	return socket
end

function unl.handle(...)
	networkListener(...)
end

event.listen("modem_message",networkListener)

return unl