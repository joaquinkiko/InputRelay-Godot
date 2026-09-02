## Global InputRelay manager
extends Node

## All connected [InputRelayDevice]s
var devices: Array[InputRelayDevice]
## All [InputRelayPlayer]s
var players: Array[InputRelayPlayer]
## All [InputActionSet]s sets, sorted by name
var action_sets: Dictionary[StringName, InputActionSet]
