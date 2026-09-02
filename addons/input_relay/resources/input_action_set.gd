## Configures available set of input actions for a particular context
class_name InputActionSet extends Resource

## Additional layers that can be activated ontop of this set, sorted by name.
## These will be ignored on layers (only top level sets will use this.
@export var layers: Dictionary[StringName, InputActionSet]

## These flags control how the mouse should appear when this set is active for
## a mouse and keyboard player.
var mouse_flags: int = 0

## Available actions for this set, sorted by name
@export var actions: Dictionary[StringName, InputActionDef]
