extends SceneTree
## Renders the app icon (icons/icon.png, 512 px): Pip and a fizz pod on a
## sunny backdrop. Needs a renderer:  godot --path . -s res://tools/make_icon.gd

var _vp: SubViewport
var _frames: int = 20


func _initialize() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(512, 512)
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#8EC5EC")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#AFC8EA")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	_vp.add_child(sun)
	var holder := Node3D.new()
	_vp.add_child(holder)
	Models.part(holder, Models.box_mesh(Vector3(3.0, 0.4, 3.0), 0.3), Models.GRASS_A, Vector3(0, -0.2, 0))
	var hero := Models.hero()
	hero.position = Vector3(-0.22, 0, 0.1)
	hero.rotation.y = 0.35
	_vp.add_child(hero)
	var pod := Models.pod()
	pod.position = Vector3(0.42, 0, 0.0)
	pod.scale = Vector3.ONE * 0.85
	_vp.add_child(pod)
	var cam := Camera3D.new()
	cam.fov = 30
	_vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.5, 2.7), Vector3(0.08, 0.38, 0), Vector3.UP)


func _process(_d: float) -> bool:
	_frames -= 1
	if _frames > 0:
		return false
	var img: Image = _vp.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://icons/icon.png"))
	print("icon saved")
	quit(0)
	return true
