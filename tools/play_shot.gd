extends SceneTree
## Dev utility: opens the game at a level and plays a scripted sequence,
## saving screenshots along the way. Needs a renderer.
##   godot --path . -s res://tools/play_shot.gd -- --level=1 --size=720x1280 \
##       --do="0.4:pod;0.45:up;0.8:right;1.2:stop;3.0:shot:boom"
## Actions: pod, up, down, left, right, stop, shot:<name>, kill (every critter),
## give:<bomb|fire|speed|kick|shield> and pos:x,z (put the hero there).

var _steps: Array = []
var _t: float = 0.0
var _vp: SubViewport
var _main: Node


func _initialize() -> void:
	# Test runs stay silent.
	AudioServer.set_bus_mute(0, true)
	# ...and out of sight: the window is only a host for the off-screen
	# viewport, so park it far off the desktop (also pass --position
	# -20000,-20000 --resolution 64x64 so it never shows at all).
	DisplayServer.window_set_size(Vector2i(64, 64))
	DisplayServer.window_set_position(Vector2i(-20000, -20000))
	var size := Vector2i(720, 1280)
	var plan: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--do="):
			plan = arg.trim_prefix("--do=")
		elif arg.begins_with("--palette="):
			Models.use_palette(arg.trim_prefix("--palette="))
			Models.palette_locked = true
		elif arg == "--clay":
			Models.GLASS = false
		elif arg.begins_with("--size="):
			var p: PackedStringArray = arg.trim_prefix("--size=").split("x")
			size = Vector2i(p[0].to_int(), p[1].to_int())
	for item: String in plan.split(";", false):
		var parts: PackedStringArray = item.split(":")
		_steps.append([parts[0].to_float(), parts[1], parts[2] if parts.size() > 2 else ""])
	_vp = SubViewport.new()
	_vp.size = size
	_vp.msaa_3d = Viewport.MSAA_2X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	_main = (load("res://ui/Main.tscn") as PackedScene).instantiate()
	_vp.add_child(_main)


func _process(delta: float) -> bool:
	_t += delta
	while not _steps.is_empty() and _t >= float(_steps[0][0]):
		var s: Array = _steps.pop_front()
		_act(s[1], s[2])
	if _steps.is_empty() and _t > 0.5:
		quit(0)
	return false


func _act(what: String, arg: String) -> void:
	var arena = _main.arena
	if _main.hud != null:
		_main.hud.auto_input = false
	match what:
		"pod":
			arena.drop_pod()
		"up":
			arena.set_input(Vector2i(0, -1), Vector2i.ZERO)
		"down":
			arena.set_input(Vector2i(0, 1), Vector2i.ZERO)
		"left":
			arena.set_input(Vector2i(-1, 0), Vector2i.ZERO)
		"right":
			arena.set_input(Vector2i(1, 0), Vector2i.ZERO)
		"stop":
			arena.set_input(Vector2i.ZERO, Vector2i.ZERO)
		"kill":
			for cr in arena.critters.duplicate():
				arena._kill_critter(cr)
		"give":
			arena._spawn_pickup(arena.hero_cell(), StringName(arg))
		"pos":
			var p: PackedStringArray = arg.split(",")
			arena.hero_pos = Vector2(p[0].to_float(), p[1].to_float())
		"blast":
			var b: PackedStringArray = arg.split(",")
			arena._blast(Vector2i(b[0].to_int(), b[1].to_int()), 2)
		"tap", "dtap":
			# Taps the screen over tile x,z the way a finger would.
			var t: PackedStringArray = arg.split(",")
			var at: Vector2 = arena.camera.unproject_position(Vector3(t[0].to_float(), 0.3, t[1].to_float()))
			_main.hud.tap(at)
			if what == "dtap":
				_main.hud.tap(at + Vector2(6, 4))
		"maptest":
			# Every inner tile's screen spot must map back to that tile.
			var bad: int = 0
			for z in range(1, arena.H - 1):
				for x in range(1, arena.W - 1):
					var sp: Vector2 = arena.camera.unproject_position(Vector3(x, 0.3, z))
					if arena.cell_at_screen(sp) != Vector2i(x, z):
						bad += 1
			var tl: Vector2 = arena.camera.unproject_position(Vector3(-0.5, 0, -0.5))
			var br: Vector2 = arena.camera.unproject_position(Vector3(arena.W - 0.5, 0, arena.H - 0.5))
			var bl: Vector2 = arena.camera.unproject_position(Vector3(-0.5, 0, arena.H - 0.5))
			print("maptest: %d tiles map wrong; arena top-left %s bottom-left %s bottom-right %s" % [bad, tl, bl, br])
		"die":
			# Loses every life at once: the "Out of lives!" card follows.
			arena.lives = 1
			arena.hero_invuln = 0.0
			arena.shield = false
			arena._hurt_hero()
		"fakead":
			root.get_node("Services").fake_rewarded = true
		"extralife":
			_main.hud._watch_for_life()
		"privacy":
			_main._show_privacy(_main._ui.get_child(0))
		"cam":
			# Close-up for store shots: cam:x,z,distance,height (height 11 = normal tilt).
			var c: PackedStringArray = arg.split(",")
			arena.shot_cam = Vector4(c[0].to_float(), c[1].to_float(), c[2].to_float(), c[3].to_float() if c.size() > 3 else 11.0)
		"stage":
			# stage:gap,distance,height - Pip on the free tile nearest to `gap`
			# rows in front of the boss (or first critter), camera framing both.
			var s: PackedStringArray = arg.split(",")
			var foe = arena.boss if arena.boss != null else (arena.critters[0] if not arena.critters.is_empty() else null)
			if foe == null:
				return
			var want: Vector2i = foe.cell + Vector2i(0, s[0].to_int())
			var best: Vector2i = arena.hero_cell()
			var best_d: float = INF
			for z in range(1, arena.H - 1):
				for x in range(1, arena.W - 1):
					var c := Vector2i(x, z)
					if arena.tile(c) == 0 and c.y > foe.cell.y and Vector2(c - want).length() < best_d:
						best_d = Vector2(c - want).length()
						best = c
			arena.hero_pos = Vector2(best)
			var mid: Vector2 = (Vector2(foe.cell) + Vector2(best)) * 0.5
			var fx: String = s[3] if s.size() > 3 else ""
			if fx == "pod":
				# A fizzy pod where Pip stood, Pip one step to the side.
				arena.drop_pod()
				for side: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
					if arena.tile(best + side) == 0:
						arena.hero_pos = Vector2(best + side)
						break
			elif fx == "solo":
				# Boss portrait: Pip back at the start, camera on the foe alone.
				arena.hero_pos = Vector2(arena.start_cell)
				arena.shot_cam = Vector4(foe.cell.x, foe.cell.y - 0.7, s[1].to_float(), s[2].to_float())
			elif fx == "blast":
				arena._blast(foe.cell + Vector2i(-2, 0) if foe.cell.x > 3 else foe.cell + Vector2i(2, 0), 2)
			arena.shot_cam = Vector4(mid.x, mid.y, s[1].to_float(), s[2].to_float())
			print("stage foe=%s pip=%s" % [foe.cell, best])
		"nohud":
			# Hides the HUD and any world overlay (timers and the like).
			for layer in root.find_children("*", "CanvasLayer", true, false):
				layer.visible = false
		"bosshit":
			if arena.boss != null:
				arena.flames[arena.hero_cell()] = 0.0
				arena.boss.invuln = 0.0
				arena._hit_critter(arena.boss)
		"shot":
			var img: Image = _vp.get_texture().get_image()
			var path: String = ProjectSettings.globalize_path("res://shots/%s.png" % arg)
			img.save_png(path)
			print("shot %s hero=%s cell=%s state=%s critters=%d lives=%d pods=%d boss=%s" % [arg, arena.hero_pos, arena.hero_cell(), arena.state, arena.critters.size(), arena.lives, arena.pods.size(), "%d@%s" % [arena.boss.hp, arena.boss.cell] if arena.boss != null else "-"])
			for p in arena.pods:
				print("  pod at ", p.cell, " slide ", p.slide)
