class_name ToolState
extends RefCounted

enum Tool { NONE, SPONGE, SPRAYER }

var selected_tool: Tool = Tool.NONE
var sponge_is_wet: bool = false
var faucet_is_on: bool = false
var soap_bottle_is_held: bool = false
