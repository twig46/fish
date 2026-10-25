@tool
@icon("res://addons/almios_screen_shake/icon.svg")
class_name ScreenShake
extends Node

## Screen shake for Camera2D and Camera3D, with several kinds of motion.
##
## Add it as a child of your camera, then call it when something happens:
##     $Camera2D/ScreenShake.shake(0.4)                 # all around
##     $Camera2D/ScreenShake.shake_horizontal(0.5)      # left and right only
##     $Camera2D/ScreenShake.shake_vertical(0.5)        # up and down only
##     $Camera2D/ScreenShake.shake_along(0.6, dir)      # along a hit or a blast
##     $Camera2D/ScreenShake.shake_rotation(0.5)        # a twist, no sliding
##     $Camera2D/ScreenShake.kick(Vector2.DOWN, 0.6)    # a recoil that springs back
##     $Camera2D/ScreenShake.zoom_punch(0.5)            # a quick zoom in and back
##     $Camera2D/ScreenShake.rumble(0.3, 2.0)           # a steady rumble for 2 s
##     $Camera2D/ScreenShake.sway(0.6, 5.0)             # slow nausea, dizziness, a ship
##     $Camera2D/ScreenShake.preset("explosion")        # ready-made combinations
##
## Every hit starts with a clear jolt (a spring impulse), then shakes with smooth
## noise that fades out: light hits stay readable, big ones stack up. Several
## calls combine. Slow motion and freeze frames (Engine.time_scale) do not slow it.
## Screen Shake by Dimension Almios, MIT licence.

## Ready-made combinations for preset().
const PRESETS := ["light_hit", "heavy_hit", "explosion", "gunshot", "landing",
	"earthquake", "engine", "dizzy", "seasick", "impact_zoom"]

## Scales every motion: wire it to an accessibility option (0 turns shaking off).
@export_range(0.0, 1.0) var intensity := 1.0

@export_group("Shake")
## Offset at full strength for a Camera2D, in pixels.
@export var max_offset := Vector2(30.0, 26.0)
## Offset at full strength for a Camera3D, in metres. About 2 % of the distance to what
## the camera looks at reads like the 2D default.
@export var max_offset_3d := Vector2(0.3, 0.26)
## Rotation that comes with the other shakes at full strength, in radians
## (a Camera2D needs ignore_rotation off to show any rotation).
@export_range(0.0, 0.3) var max_roll := 0.03
## Rotation of shake_rotation() at full strength, in radians (a Camera2D needs
## ignore_rotation off to show it).
@export_range(0.0, 0.3, 0.01, "or_greater") var max_twist := 0.1
## How fast the camera moves while shaking: noise wiggles per second. Above 30 it looks
## the same at 60 fps.
@export_range(1.0, 30.0, 0.5, "or_greater") var frequency := 22.0
## Strength lost per second (1.2: a full shake lasts about 0.8 s).
@export_range(0.1, 10.0) var decay := 1.2
## How strength turns into motion: 1 linear, 2 squared (small hits much softer
## than big ones). The default 1.3 keeps light hits readable and heavy hits strong.
@export_range(1.0, 3.0) var response := 1.3

@export_group("Jolt")
## Size of the first jolt of each hit (0 = noise only, like classic trauma shakes).
@export_range(0.0, 2.0) var jolt := 1.7
## How stiff the spring that brings the camera back is (higher = snappier).
@export_range(20.0, 1000.0) var spring_stiffness := 320.0
## How quickly the spring stops bouncing (higher = fewer bounces). Above about 35 the
## jolt also gets smaller.
@export_range(1.0, 60.0) var spring_damping := 13.0

## Strength of the all-around shake, 0 to 1 (kept for older scripts: setting it
## sets both axes, scaled by `intensity` like every other call).
var trauma: float:
	get:
		return maxf(_tx, _ty)
	set(v):
		_tx = clampf(v * intensity, 0.0, 1.0)
		_ty = _tx

var _noise := FastNoiseLite.new()
var _time := 0.0
var _last_usec := 0
var _tx := 0.0                 # strength on the x axis
var _ty := 0.0                 # strength on the y axis
var _troll := 0.0              # strength of the twist
var _tdir := 0.0               # strength of the directional shake
var _dir := Vector2.RIGHT
var _spring := Vector2.ZERO    # jolt offset, in "full strength" units
var _spring_vel := Vector2.ZERO
var _twist := 0.0              # twist jolt spring (radians)
var _twist_vel := 0.0
var _zoom := 0.0               # zoom punch spring
var _zoom_vel := 0.0
var _rumble := 0.0
var _rumble_left := 0.0
var _rumble_fade := 0.0
var _rumble_age := 0.0
var _sway := 0.0
var _sway_left := 0.0
var _sway_fade := 0.0
var _sway_age := 0.0
var _applied_offset := Vector2.ZERO
var _applied_roll := 0.0
var _applied_zoom := 1.0


func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_NONE   # one smooth octave: uses the full -1..1 range
	_noise.seed = randi()
	_noise.frequency = 1.0
	_last_usec = Time.get_ticks_usec()
	# keeps working while the game is paused for a hitstop (unless you chose otherwise)
	if not Engine.is_editor_hint() and process_mode == Node.PROCESS_MODE_INHERIT:
		process_mode = Node.PROCESS_MODE_ALWAYS


# ---------------------------------------------------------------- calls

## Shakes all around. `amount` 0 to 1; several calls add up (capped at 1).
func shake(amount: float) -> void:
	_tx = clampf(_tx + amount * intensity, 0.0, 1.0)
	_ty = clampf(_ty + amount * intensity, 0.0, 1.0)
	_jolt(Vector2.from_angle(randf() * TAU), amount)


## Shakes left and right only.
func shake_horizontal(amount: float) -> void:
	_tx = clampf(_tx + amount * intensity, 0.0, 1.0)
	_jolt(Vector2(1.0 if randf() < 0.5 else -1.0, 0.0), amount)


## Shakes up and down only.
func shake_vertical(amount: float) -> void:
	_ty = clampf(_ty + amount * intensity, 0.0, 1.0)
	_jolt(Vector2(0.0, 1.0 if randf() < 0.5 else -1.0), amount)


## Shakes mostly along `direction` (a hit, a blast, a shot), starting with a jolt
## that way.
func shake_along(amount: float, direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		shake(amount)
		return
	_dir = direction.normalized()
	_tdir = clampf(_tdir + amount * intensity, 0.0, 1.0)
	_jolt(_dir, amount)


## A twist of the camera around its centre, without sliding.
func shake_rotation(amount: float) -> void:
	_troll = clampf(_troll + amount * intensity, 0.0, 1.0)
	_twist_vel += (1.0 if randf() < 0.5 else -1.0) * amount * intensity * max_twist * jolt * sqrt(spring_stiffness) * 0.9


## A recoil: the camera is pushed along `direction` and springs back, with a
## bounce or two (a landing, a punch received, a gun's kick).
func kick(direction: Vector2, amount := 0.5) -> void:
	_spring_vel += direction.normalized() * amount * intensity * sqrt(spring_stiffness) * 1.6


## A quick zoom in that springs back (positive) or a zoom out (negative).
func zoom_punch(amount := 0.5) -> void:
	_zoom_vel += amount * intensity * sqrt(spring_stiffness) * 0.4


## A steady rumble (an engine, an earthquake, a boss charging) for `seconds`
## (-1 = until stop_rumble()). It fades in and out over `fade` seconds.
func rumble(strength := 0.3, seconds := 1.0, fade := 0.3) -> void:
	_rumble = clampf(strength, 0.0, 1.0)
	_rumble_left = seconds if seconds >= 0.0 else INF
	_rumble_fade = maxf(fade, 0.01)
	_rumble_age = 0.0


func stop_rumble() -> void:
	_rumble_left = minf(_rumble_left, _rumble_fade)


## A slow, drifting sway with a gentle roll and breathing zoom: nausea, dizziness,
## being drunk, a ship at sea. For `seconds` (-1 = until stop_sway()).
func sway(strength := 0.5, seconds := 3.0, fade := 1.0) -> void:
	_sway = clampf(strength, 0.0, 1.0)
	_sway_left = seconds if seconds >= 0.0 else INF
	_sway_fade = maxf(fade, 0.01)
	_sway_age = 0.0


func stop_sway() -> void:
	_sway_left = minf(_sway_left, _sway_fade)


## Plays a ready-made combination, see PRESETS. `scale` makes it weaker or stronger.
func preset(name: String, scale := 1.0, direction := Vector2.ZERO) -> void:
	match name:
		"light_hit":
			shake(0.3 * scale)
		"heavy_hit":
			shake(0.6 * scale)
			zoom_punch(0.25 * scale)
		"explosion":
			shake(0.9 * scale)
			shake_rotation(0.6 * scale)
			zoom_punch(-0.4 * scale)
			rumble(0.25 * scale, 0.6, 0.5)
		"gunshot":
			var d := direction if direction != Vector2.ZERO else Vector2.LEFT
			kick(d, 0.35 * scale)
			shake_along(0.25 * scale, d)
		"landing":
			kick(Vector2.DOWN, 0.6 * scale)
			shake_vertical(0.25 * scale)
		"earthquake":
			rumble(0.5 * scale, 3.0, 0.8)
			shake_horizontal(0.3 * scale)
		"engine":
			rumble(0.15 * scale, -1.0, 0.5)
		"dizzy":
			sway(0.5 * scale, 4.0, 1.0)
		"seasick":
			sway(0.9 * scale, -1.0, 1.5)
		"impact_zoom":
			zoom_punch(0.6 * scale)
			shake(0.4 * scale)
		_:
			push_warning("ScreenShake: unknown preset '%s' (see PRESETS)" % name)


## Stops everything at once.
func stop() -> void:
	_tx = 0.0
	_ty = 0.0
	_troll = 0.0
	_tdir = 0.0
	_spring = Vector2.ZERO
	_spring_vel = Vector2.ZERO
	_twist = 0.0
	_twist_vel = 0.0
	_zoom = 0.0
	_zoom_vel = 0.0
	_rumble_left = 0.0
	_sway_left = 0.0


## True while anything is still moving the camera.
func is_shaking() -> bool:
	return _tx + _ty + _troll + _tdir > 0.0 or _rumble_left > 0.0 or _sway_left > 0.0 \
		or _spring.length() > 0.002 or absf(_zoom) > 0.0005 or absf(_twist) > 0.0005 \
		or _spring_vel.length() > 0.02 or absf(_zoom_vel) > 0.005 or absf(_twist_vel) > 0.005


# ---------------------------------------------------------------- motion

func _jolt(direction: Vector2, amount: float) -> void:
	# the first frame of a hit always moves: a push on the spring, in "full strength" units
	_spring_vel += direction * amount * intensity * jolt * sqrt(spring_stiffness) * 0.9


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# game time without the time scale: slow motion and hitstops do not slow the
	# shake, and it stays in step with the frames when recording with Movie Maker.
	# During a full freeze (time_scale 0) the frame time is 0: use the real clock.
	var now := Time.get_ticks_usec()
	var dt := delta / Engine.time_scale if Engine.time_scale > 0.0001 else (now - _last_usec) / 1000000.0
	dt = minf(dt, 0.1)
	_last_usec = now
	if not is_shaking():
		# at rest: nothing to do once the camera is back to its own settings
		if _applied_offset != Vector2.ZERO or _applied_roll != 0.0 or _applied_zoom != 1.0:
			_apply(Vector2.ZERO, 0.0, 1.0)
		# the noise clock restarts while nothing moves (precision stays high forever)
		_time = 0.0
		return
	_time += dt
	_tx = maxf(_tx - decay * dt, 0.0)
	_ty = maxf(_ty - decay * dt, 0.0)
	_troll = maxf(_troll - decay * dt, 0.0)
	_tdir = maxf(_tdir - decay * dt, 0.0)

	var f := _time * frequency
	var n := Vector2(_noise.get_noise_2d(f, 0.0), _noise.get_noise_2d(f, 100.0))
	var motion := Vector2(pow(_tx, response) * n.x, pow(_ty, response) * n.y)
	# along a direction: mostly that way, a little across
	var sd := pow(_tdir, response)
	motion += (_dir * n.x + _dir.orthogonal() * n.y * 0.25) * sd
	var roll := (max_roll * pow(maxf(_tx, _ty), response) + max_twist * pow(_troll, response)) * _noise.get_noise_2d(f, 200.0)

	# spring jolts and kicks (critically damped enough to settle after a bounce or two),
	# in steps of 1/120 s at most: stable at any frame rate and any stiffness
	var steps := ceili(dt * 120.0)
	var h := dt / float(maxi(steps, 1))
	for _i in steps:
		_spring_vel += (-spring_stiffness * _spring - spring_damping * _spring_vel) * h
		_spring += _spring_vel * h
		_zoom_vel += (-spring_stiffness * _zoom - spring_damping * _zoom_vel) * h
		_zoom += _zoom_vel * h
		_twist_vel += (-spring_stiffness * _twist - spring_damping * _twist_vel) * h
		_twist += _twist_vel * h
	motion += _spring
	roll += _twist
	# many punches at once never turn the view inside out
	var zoom := clampf(1.0 + _zoom * 0.6, 0.3, 3.0)

	# rumble: small, fast and steady
	if _rumble_left > 0.0:
		_rumble_left -= dt
		_rumble_age += dt
		# fades in over `fade` seconds and out over the last `fade` seconds
		var r := _rumble * intensity * clampf(_rumble_left / _rumble_fade, 0.0, 1.0) \
			* clampf(_rumble_age / _rumble_fade, 0.0, 1.0)
		var rf := _time * frequency * 2.2
		motion += Vector2(_noise.get_noise_2d(rf, 300.0), _noise.get_noise_2d(rf, 400.0)) * r * 0.45
	# sway: slow drifting figure of eight, rolling and breathing
	if _sway_left > 0.0:
		_sway_left -= dt
		_sway_age += dt
		var s := _sway * intensity * clampf(_sway_left / _sway_fade, 0.0, 1.0) \
			* clampf(_sway_age / _sway_fade, 0.0, 1.0)
		motion += Vector2(sin(_time * 0.9) * 0.9, sin(_time * 1.3 + 0.7) * 0.6) * s
		roll += sin(_time * 0.7) * max_roll * 2.2 * s
		zoom *= 1.0 + sin(_time * 0.55) * 0.035 * s
	_apply(motion, roll, zoom)


# motion: in "full strength" units (-1 to 1 on each axis for a full shake)
func _apply(motion: Vector2, roll: float, zoom: float) -> void:
	var cam := get_parent()
	var offset := Vector2.ZERO
	# only our own part is added and removed, so the camera's own settings are kept
	if cam is Camera2D:
		offset = motion * max_offset
		cam.offset += offset - _applied_offset
		cam.rotation += roll - _applied_roll
		cam.zoom = cam.zoom / _applied_zoom * zoom
	elif cam is Camera3D:
		offset = motion * max_offset_3d
		cam.h_offset += offset.x - _applied_offset.x
		cam.v_offset += offset.y - _applied_offset.y
		cam.rotation.z += roll - _applied_roll
		cam.fov = clampf(cam.fov * _applied_zoom / zoom, 1.0, 179.0)
	else:
		return
	_applied_offset = offset
	_applied_roll = roll
	_applied_zoom = zoom


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		_apply(Vector2.ZERO, 0.0, 1.0)


func _get_configuration_warnings() -> PackedStringArray:
	if not (get_parent() is Camera2D or get_parent() is Camera3D):
		return ["ScreenShake must be a child of a Camera2D or a Camera3D."]
	return []
