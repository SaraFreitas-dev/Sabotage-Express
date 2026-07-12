extends Sprite2D
## bg.gd
## Attached to the BG node (Sprite2D) inside level_base (a Node2D).
## Resizes itself every frame to always cover the full viewport,
## regardless of window size, by scaling based on the texture's native
## size vs the current viewport size.
##
## top_level = true makes this node ignore any scale/position/rotation
## inherited from level_base (or any ancestor) - it uses only its own
## global transform, which we set directly.
##
## Checked every frame instead of relying only on size_changed, since
## that signal isn't always reliable on Web/HTML5 exports.
 
const OVERSCAN := 1.02  # slight extra scale (2%) to absorb rounding gaps
 
func _ready() -> void:
	top_level = true
	centered = false  # so position (0,0) = top-left corner, easier to reason about
	_update_size()
 
func _process(_delta: float) -> void:
	_update_size()
 
func _update_size() -> void:
	if texture == null:
		return
 
	var vp_size: Vector2 = get_viewport_rect().size
	var tex_size: Vector2 = texture.get_size()
 
	# Scale so the texture covers the viewport on BOTH axes (may distort
	# aspect ratio slightly, same trade-off as Stretch Mode = Scale).
	var scale_x: float = (vp_size.x / tex_size.x) * OVERSCAN
	var scale_y: float = (vp_size.y / tex_size.y) * OVERSCAN
	var target_scale := Vector2(scale_x, scale_y)
 
	if scale != target_scale:
		scale = target_scale
 
	# Center the (slightly oversized) sprite on the viewport.
	var target_position: Vector2 = -(tex_size * target_scale - vp_size) / 2.0
	if global_position != target_position:
		global_position = target_position
 
	if rotation != 0.0:
		rotation = 0.0
