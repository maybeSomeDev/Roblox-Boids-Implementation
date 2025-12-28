local packet = require("../Libs/Packet")

return {
	sync = packet("sync",packet.Instance, packet.CFrameF32U8, packet.NumberF64),
	removeObject = packet("remove", packet.Instance, packet.Boolean8)
}