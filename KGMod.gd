extends Node

const TITLE = "Buckshot Roulette | KGuest"
const ACH = ["ach1", "ach2", "ach3", "ach4", "ach5", "ach6", "ach7", "ach8", "ach9", "ach10", "ach11", "ach12", "ach13", "ach14", "ach15", "ach16"]

var rm
var ss
var hc
var da
var gs
var ih
var im
var scene_id = 0
var next_find = 0.0

var ui_layer
var panel
var hud
var shell_label
var co_label
var money_label
var status_label

var sp_pl_freeze = false
var sp_pl_value = 4
var sp_dl_freeze = false
var sp_dl_value = 4
var sp_show_shells = false
var sp_double = false
var co_freeze = false
var co_value = 4
var co_show_shells = false
var co_double = false
var sharp = false
var render_mode = 0
var theme_idx = 0
var sb = {}
var acc_nodes = []
const THEMES = [["Ocean", 0.60, 0.62], ["Crimson", 0.99, 0.70], ["Forest", 0.36, 0.60], ["Violet", 0.76, 0.58], ["Sunset", 0.07, 0.75], ["Sakura", 0.92, 0.45], ["Cyber", 0.50, 0.70], ["Gold", 0.12, 0.80], ["Mint", 0.44, 0.50], ["Midnight", 0.62, 0.12], ["Halloween", 0.08, 0.90], ["Ice", 0.54, 0.35], ["Lava", 0.02, 0.88], ["Lime", 0.25, 0.78], ["Royal", 0.68, 0.72]]
var base_mode = -1
var win = null
var ctl = {}
var sp_full = false
var co_full = false
var dealer_forget = false
var skip_intro = false
var speed_on = false
var speed_value = 1.0
var speed_prev = 1.0
var speed_taken = false
var sp_item_idx = 0
var co_item_idx = 0
var co_item_opt
var role_label
const SP_ITEMS = ["adrenaline", "beer", "burner phone", "cigarettes", "expired medicine", "handcuffs", "handsaw", "inverter", "magnifying glass"]
var money_lock = false
var money_value = 70000.0

const CFG = "user://kgmod.cfg"
const KEYS = [["Insert / F8", [KEY_INSERT, KEY_F8]], ["F9", [KEY_F9]], ["F10", [KEY_F10]], ["Home", [KEY_HOME]], ["Delete", [KEY_DELETE]]]
var ui_scale = 100.0
var opacity = 100.0
var unlock_mouse = true
var key_idx = 0
var hud_size = 22.0
var hud_bottom = false
var prev_mouse = 0
var mouse_taken = false
var dragging = false
var drag_off = Vector2.ZERO
var panel_pos = Vector2(20, 20)

var dh_prev = false
var shell_tick = 0.0
var ach_status = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	LoadCfg()
	MakeShared()
	base_mode = get_tree().root.content_scale_mode
	BuildUi()
	ApplyLayout()
	ApplyRender()

func LoadCfg():
	var c = ConfigFile.new()
	if c.load(CFG) != OK:
		return
	ui_scale = float(c.get_value("menu", "ui_scale", ui_scale))
	opacity = float(c.get_value("menu", "opacity", opacity))
	unlock_mouse = bool(c.get_value("menu", "unlock_mouse", unlock_mouse))
	key_idx = clampi(int(c.get_value("menu", "key_idx", key_idx)), 0, KEYS.size() - 1)
	hud_size = float(c.get_value("menu", "hud_size", hud_size))
	hud_bottom = bool(c.get_value("menu", "hud_bottom", hud_bottom))
	panel_pos = c.get_value("menu", "panel_pos", panel_pos)
	render_mode = clampi(int(c.get_value("menu", "render_mode", render_mode)), 0, 2)
	theme_idx = clampi(int(c.get_value("menu", "theme_idx", theme_idx)), 0, THEMES.size() - 1)

func SaveCfg():
	var c = ConfigFile.new()
	c.load(CFG)
	c.set_value("menu", "ui_scale", ui_scale)
	c.set_value("menu", "opacity", opacity)
	c.set_value("menu", "unlock_mouse", unlock_mouse)
	c.set_value("menu", "key_idx", key_idx)
	c.set_value("menu", "hud_size", hud_size)
	c.set_value("menu", "hud_bottom", hud_bottom)
	c.set_value("menu", "panel_pos", panel.position if panel != null and not sharp else panel_pos)
	c.set_value("menu", "render_mode", render_mode)
	c.set_value("menu", "theme_idx", theme_idx)
	c.save(CFG)

func SaveFeatures():
	var c = ConfigFile.new()
	c.load(CFG)
	for k in ctl:
		var n = ctl[k]
		if n is CheckButton:
			c.set_value("features", k, n.button_pressed)
		else:
			c.set_value("features", k, n.value)
	c.save(CFG)

func LoadFeatures():
	var c = ConfigFile.new()
	if c.load(CFG) != OK:
		return
	for k in ctl:
		if not c.has_section_key("features", k):
			continue
		var n = ctl[k]
		var v = c.get_value("features", k)
		if n is CheckButton:
			n.button_pressed = bool(v)
		else:
			n.value = float(v)

func ViewSize():
	return get_viewport().get_visible_rect().size

func ApplyRender():
	var root = get_tree().root
	var hd = render_mode == 1 or (render_mode == 0 and IsOpen())
	var want = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS if hd else base_mode
	if root.content_scale_mode != want:
		root.content_scale_mode = want

func IsOpen():
	if sharp:
		return win != null and win.visible
	return panel.visible

func CalcScale():
	if sharp:
		var h = float(DisplayServer.screen_get_size().y)
		return clampf(h / 1080.0, 0.75, 2.5) * (ui_scale / 100.0)
	var vs = ViewSize()
	var v = clampf(vs.x * 0.30 / 440.0, 0.4, 3.0) * (ui_scale / 100.0)
	if panel.size.y > 0.0:
		v = minf(v, vs.y * 0.92 / panel.size.y)
	return maxf(v, 0.3)

func ClampPanel():
	if sharp:
		return
	var vs = ViewSize()
	var sc = panel.scale.x
	panel.position.x = clampf(panel.position.x, 60.0 - panel.size.x * sc, vs.x - 60.0)
	panel.position.y = clampf(panel.position.y, 0.0, vs.y - 40.0)

func ApplyLayout():
	var sc = CalcScale()
	panel.scale = Vector2(sc, sc)
	panel.modulate.a = opacity / 100.0
	ClampPanel()
	if sharp and win != null:
		panel.position = Vector2.ZERO
		win.size = Vector2i(ceili(panel.size.x * sc), ceili(panel.size.y * sc))
	hud.add_theme_font_size_override("normal_font_size", int(hud_size))
	hud.add_theme_font_size_override("bold_font_size", int(hud_size))
	var h = hud_size * 2.0 + 30.0
	if hud_bottom:
		hud.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		hud.offset_left = 0.0
		hud.offset_right = 0.0
		hud.offset_top = -h - 14.0
		hud.offset_bottom = -14.0
	else:
		hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
		hud.offset_left = 0.0
		hud.offset_right = 0.0
		hud.offset_top = 10.0
		hud.offset_bottom = 10.0 + h

func MenuKeyPressed(code):
	return KEYS[key_idx][1].has(code)

func SetMenu(open):
	if open == IsOpen():
		return
	if sharp:
		win.visible = open
	else:
		panel.visible = open
	ApplyRender()
	if open:
		ApplyLayout()
		if sharp and win.visible:
			win.size = Vector2i(ceili(panel.size.x * panel.scale.x), ceili(panel.size.y * panel.scale.y))
		if unlock_mouse:
			prev_mouse = Input.mouse_mode
			mouse_taken = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		dragging = false
		if mouse_taken:
			Input.mouse_mode = prev_mouse
			mouse_taken = false
		SaveCfg()

func WinInput(event):
	if event is InputEventKey and event.pressed and not event.echo and MenuKeyPressed(event.keycode):
		SetMenu(not IsOpen())
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = false

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if MenuKeyPressed(event.keycode):
			SetMenu(not IsOpen())
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = false

func TitleInput(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			if sharp:
				drag_off = Vector2(DisplayServer.mouse_get_position() - win.position)
			else:
				drag_off = get_viewport().get_mouse_position() - panel.position
	elif event is InputEventMouseMotion and dragging:
		if sharp:
			win.position = DisplayServer.mouse_get_position() - Vector2i(drag_off)
		else:
			panel.position = get_viewport().get_mouse_position() - drag_off
			ClampPanel()

func Valid(n):
	return n != null and is_instance_valid(n) and n.is_inside_tree()

func FindNodes():
	var cs = get_tree().current_scene
	if cs == null:
		return
	var id = cs.get_instance_id()
	if id != scene_id:
		scene_id = id
		rm = null
		ss = null
		hc = null
		da = null
		gs = null
		ih = null
		im = null
	var mp = str(cs.name) == "mp_main"
	if mp:
		if Valid(gs) and Valid(ih):
			return
	elif Valid(rm) and Valid(ss) and Valid(hc) and Valid(da) and Valid(im):
		return
	for n in cs.find_children("*", "", true, false):
		var sc = n.get_script()
		if sc == null:
			continue
		var f = str(sc.resource_path).get_file().get_basename()
		if mp:
			if f == "MP_GameStateManager":
				gs = n
			elif f == "MP_UserInstanceHandler":
				ih = n
		elif f == "ItemManager":
			im = n
		elif f == "RoundManager":
			rm = n
		elif f == "ShellSpawner":
			ss = n
		elif f == "HealthCounter":
			hc = n
		elif f == "DealerIntelligence":
			da = n

func LocalProps():
	if not Valid(ih):
		return null
	var arr = ih.get("instance_property_array")
	if arr == null:
		return null
	for p in arr:
		if Valid(p) and bool(p.get("is_active")):
			return p
	return null

func CoopHealth(value):
	var p = LocalProps()
	if p == null:
		return
	var cur = int(p.get("health_current"))
	if cur <= 0:
		return
	var mx = int(p.get("health_on_round_start"))
	if mx < 1:
		mx = 4
	var v = clampi(int(value), 1, mx)
	if cur != v:
		p.set("health_current", v)
		var h = p.get("health_counter")
		if Valid(h):
			h.call("UpdateDisplay")

func CoopSequence():
	if not Valid(gs):
		return null
	var d = gs.get("MAIN_active_sequence_dict")
	if d == null or not d.has("sequence_in_shotgun"):
		return null
	return d["sequence_in_shotgun"]

func CoopDouble():
	var p = LocalProps()
	if p == null:
		return
	if bool(p.get("has_turn")) and Valid(gs):
		gs.set("MAIN_barrel_sawed_off", true)
	var arr = ih.get("instance_property_array")
	for q in arr:
		if not Valid(q):
			continue
		var sh = q.get("shotgun")
		if Valid(sh) and bool(q.get("is_shooting")) and int(sh.get("active_shooter_socket_self")) == int(p.get("socket_number")):
			sh.set("active_shooter_shotgun_damage", 2)

func MaxHealth():
	if Valid(hc):
		var a = hc.get("symbolArray_player")
		if a != null and a.size() > 1:
			return a.size() - 1
	return 6

func ApplyHealth(player, value):
	if not Valid(rm):
		return
	var v = clampi(int(value), 1, MaxHealth())
	var key = "health_player" if player else "health_opponent"
	if int(rm.get(key)) != v:
		rm.set(key, v)
		if Valid(hc):
			hc.call("UpdateDisplay")

func ShellName(a, i):
	if a == null or a.size() <= i:
		return "-"
	return "[color=#ff5050]Live[/color]" if str(a[i]) == "live" else "[color=#5a8cff]Blank[/color]"

func FullText(a):
	if a == null or a.size() == 0:
		return ""
	var t = ""
	var lv = 0
	var bl = 0
	for x in a:
		if str(x) == "live":
			t += "[color=#ff5050]L[/color] "
			lv += 1
		else:
			t += "[color=#5a8cff]B[/color] "
			bl += 1
	return "\n" + t.strip_edges() + "  (" + str(lv) + " Live, " + str(bl) + " Blank)"

func ShellText2(a):
	return "Next: " + ShellName(a, 1) + " - Current: " + ShellName(a, 0)

func ShellText():
	var a = null
	if Valid(ss):
		a = ss.get("sequenceArray")
	return "Next: " + ShellName(a, 1) + " - Current: " + ShellName(a, 0)

func _process(delta):
	if IsOpen() and unlock_mouse and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	next_find -= delta
	if next_find <= 0.0:
		next_find = 0.5
		FindNodes()
		if IsOpen() and not dragging:
			ApplyLayout()
	var ready_rm = Valid(rm)
	if ready_rm:
		if dealer_forget and Valid(da):
			da.set("knownShell", "")
			da.set("dealerKnowsShell", false)
			da.set("dealerTarget", "")
			var kn = da.get("sequenceArray_knownShell")
			if kn != null:
				for i in range(kn.size()):
					kn[i] = false
		if skip_intro:
			var pd = rm.get("playerData")
			if pd != null:
				for f in ["hasReadIntroduction", "hasReadItemSwapIntroduction", "hasReadItemDistributionIntro", "hasReadItemDistributionIntro2", "skippingShellDescription", "indicatorShown", "cutterDialogueRead", "seenHint"]:
					pd.set(f, true)
		if sp_pl_freeze:
			ApplyHealth(true, sp_pl_value)
		if sp_dl_freeze:
			ApplyHealth(false, sp_dl_value)
		if sp_double:
			var holding = false
			var saw = false
			if Valid(da):
				holding = bool(da.get("dealerHoldingShotgun"))
				saw = bool(da.get("usingHandsaw"))
			if holding and not dh_prev:
				rm.set("currentShotgunDamage", 2 if saw else 1)
			elif not holding:
				rm.set("currentShotgunDamage", 2)
			dh_prev = holding
		if money_lock and bool(rm.get("doubling")):
			SetMoney(money_value)
	if speed_on:
		if not speed_taken:
			speed_prev = Engine.time_scale
			speed_taken = true
		Engine.time_scale = speed_value
	elif speed_taken:
		Engine.time_scale = speed_prev
		speed_taken = false
	var ready_mp = Valid(gs) and Valid(ih)
	role_label.text = RoleText(ready_mp)
	if ready_mp:
		if co_freeze:
			CoopHealth(co_value)
		if co_double:
			CoopDouble()
		if co_item_opt.item_count == 0:
			FillMpItems()
	shell_tick -= delta
	if shell_tick <= 0.0:
		shell_tick = 0.1
		var t = ShellText()
		var sa = null
		if Valid(ss):
			sa = ss.get("sequenceArray")
		if sp_full:
			t += FullText(sa)
		shell_label.text = "[center]" + t + "[/center]"
		var cseq = CoopSequence()
		var ct = ShellText2(cseq)
		if co_full:
			ct += FullText(cseq)
		co_label.text = "[center]" + ct + "[/center]"
		var show_sp = sp_show_shells and ready_rm
		var show_co = co_show_shells and ready_mp
		hud.visible = show_sp or show_co
		if show_co:
			hud.text = "[center]" + ct + "[/center]"
		elif show_sp:
			hud.text = "[center]" + t + "[/center]"
		money_label.text = "Current Money: " + MoneyText()
		status_label.text = ach_status

func IsHost():
	var g = get_node_or_null("/root/GlobalSteam")
	if g == null:
		return true
	return g.get("STEAM_ID") == g.get("HOST_ID")

func RoleText(in_mp):
	if not in_mp:
		return "Role: not in a lobby"
	return "Role: Host" if IsHost() else "Role: Client"

func SetShellSp(index, shell):
	if not Valid(ss):
		return
	var a = ss.get("sequenceArray")
	if a != null and a.size() > index:
		a[index] = shell

func SetShellCoop(index, shell):
	var a = CoopSequence()
	if a != null and a.size() > index:
		a[index] = shell

func GiveItemSp():
	if not Valid(im):
		return
	var name = SP_ITEMS[sp_item_idx]
	var res = null
	for r in im.get("instanceArray"):
		if r != null and str(r.itemName) == name:
			res = r
			break
	if res == null:
		return
	var occ = im.get("gridOccupiedArray")
	var grids = im.get("gridParentArray")
	var free = -1
	for i in range(mini(occ.size(), grids.size())):
		if not occ[i]:
			free = i
			break
	if free < 0:
		return
	var inst = res.instance.instantiate()
	im.get("itemSpawnParent").add_child(inst)
	var ind = inst.get_child(0)
	var inter = inst.get_child(1)
	im.get("items_dynamicIndicatorArray").append(ind)
	im.get("items_dynamicInteractionArray").append(inter)
	ind.set("locationInDynamicArray", im.get("items_dynamicIndicatorArray").size() - 1)
	inst.transform.origin = grids[free].transform.origin + res.pos_offset
	inst.rotation_degrees = grids[free].rotation_degrees + res.rot_offset
	inter.set("isPlayerSide", true)
	inter.set("itemGridIndex", free)
	ind.set("dealerGridIndex", free + 8)
	occ[free] = true
	im.set("numberOfOccupiedGrids", int(im.get("numberOfOccupiedGrids")) + 1)
	if name == "cigarettes":
		im.set("numberOfCigs_player", int(im.get("numberOfCigs_player")) + 1)
	ind.set("interactionAllowed", true)
	inter.set("interactionAllowed", true)

func FillMpItems():
	if not Valid(gs):
		return
	var arr = gs.get("MAIN_item_resource_array")
	if arr == null:
		return
	co_item_opt.clear()
	for r in arr:
		if r != null:
			co_item_opt.add_item(str(r.name).capitalize())
			co_item_opt.set_item_metadata(co_item_opt.item_count - 1, int(r.id))
	if co_item_opt.item_count > 0:
		co_item_opt.select(0)

func GiveItemCoop():
	var p = LocalProps()
	if p == null or not Valid(gs) or co_item_opt.item_count == 0:
		return
	var sel = co_item_opt.selected
	if sel < 0:
		return
	var id = int(co_item_opt.get_item_metadata(sel))
	var inv = p.get("user_inventory")
	var free = -1
	for i in range(inv.size()):
		if inv[i].is_empty():
			free = i
			break
	if free < 0:
		return
	var im2 = p.get("item_manager")
	if not Valid(im2):
		return
	im2.call("Debug_SpawnItemSeparately", id, free)
	inv[free] = {"item_id": id, "item_local_grid_index": free}
	var cnt = p.get("user_inventory_count_by_item_id")
	if cnt != null and cnt.size() > id:
		cnt[id] += 1
	var gc = gs.get("global_item_count_on_table_by_id")
	if gc != null and gc.size() > id:
		gc[id] += 1

func MoneyText():
	if Valid(rm) and bool(rm.get("doubling")):
		return str(int(rm.get("prevscore")))
	return "0"

func SetMoney(v):
	if not Valid(rm):
		return
	var n = int(v)
	rm.set("prevscore", n)
	rm.set("endscore", n)
	rm.set("double_or_nothing_score", n)

func UnlockAll():
	var st = null
	if Engine.has_singleton("Steam"):
		st = Engine.get_singleton("Steam")
	if st == null:
		ach_status = "Steam not found"
		return
	for a in ACH:
		st.call("setAchievement", a)
	st.call("storeStats")
	ach_status = "Unlocked " + str(ACH.size()) + " achievements"

func StyleBox(color):
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(6)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func Flat(radius, mx, my):
	var s = StyleBoxFlat.new()
	s.set_corner_radius_all(radius)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	return s

func MakeShared():
	sb["panel"] = Flat(10, 12, 10)
	sb["panel"].set_border_width_all(1)
	sb["card"] = Flat(8, 12, 9)
	sb["card"].border_width_left = 3
	sb["btn"] = Flat(7, 10, 8)
	sb["btn_h"] = Flat(7, 10, 8)
	sb["btn_p"] = Flat(7, 10, 8)
	sb["tab_sel"] = Flat(7, 16, 8)
	sb["tab_sel"].corner_radius_bottom_left = 0
	sb["tab_sel"].corner_radius_bottom_right = 0
	sb["tab_sel"].border_width_bottom = 3
	sb["tab_uns"] = Flat(7, 16, 8)
	sb["tab_uns"].corner_radius_bottom_left = 0
	sb["tab_uns"].corner_radius_bottom_right = 0
	sb["tab_hov"] = Flat(7, 16, 8)
	sb["tab_hov"].corner_radius_bottom_left = 0
	sb["tab_hov"].corner_radius_bottom_right = 0
	sb["slider"] = Flat(4, 0, 3)
	sb["fill"] = Flat(4, 0, 3)
	ApplyTheme()

func ApplyTheme():
	var t = THEMES[theme_idx]
	var h = float(t[1])
	var sat = float(t[2])
	var acc = Color.from_hsv(h, sat, 1.0)
	var low = sat * 0.55
	sb["panel"].bg_color = Color.from_hsv(h, low, 0.11, 0.97)
	sb["panel"].border_color = Color.from_hsv(h, low, 0.40)
	sb["card"].bg_color = Color.from_hsv(h, low, 0.18)
	sb["card"].border_color = acc
	sb["btn"].bg_color = Color.from_hsv(h, sat, 0.85)
	sb["btn_h"].bg_color = Color.from_hsv(h, sat * 0.85, 1.0)
	sb["btn_p"].bg_color = Color.from_hsv(h, sat, 0.6)
	sb["tab_sel"].bg_color = Color.from_hsv(h, low, 0.22)
	sb["tab_sel"].border_color = acc
	sb["tab_uns"].bg_color = Color.from_hsv(h, low, 0.13)
	sb["tab_hov"].bg_color = Color.from_hsv(h, low, 0.18)
	sb["slider"].bg_color = Color.from_hsv(h, low, 0.30)
	sb["fill"].bg_color = acc
	for n in acc_nodes:
		if is_instance_valid(n):
			n.add_theme_color_override("font_color", acc)

func AddToggle(parent, text, initial, cb, key = ""):
	var c = CheckButton.new()
	if key != "":
		ctl[key] = c
	c.text = text
	c.button_pressed = initial
	c.toggled.connect(cb)
	c.focus_mode = Control.FOCUS_NONE
	parent.add_child(c)
	return c

func AddButton(parent, text, cb):
	var b = Button.new()
	b.text = text
	b.pressed.connect(cb)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", sb["btn"])
	b.add_theme_stylebox_override("hover", sb["btn_h"])
	b.add_theme_stylebox_override("pressed", sb["btn_p"])
	parent.add_child(b)
	return b

func AddSpin(parent, text, minv, maxv, initial, cb, key = ""):
	var row = HBoxContainer.new()
	var l = Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s = SpinBox.new()
	s.min_value = minv
	s.max_value = maxv
	s.step = 1
	s.value = initial
	s.custom_minimum_size = Vector2(120, 0)
	s.value_changed.connect(cb)
	row.add_child(l)
	row.add_child(s)
	parent.add_child(row)
	if key != "":
		ctl[key] = s
	return s

func Head(parent, text):
	var l = Label.new()
	l.text = text.to_upper()
	l.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	parent.add_child(l)

func AddSlider(parent, text, minv, maxv, initial, suffix, cb, key = ""):
	var row = HBoxContainer.new()
	var l = Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(110, 0)
	var vl = Label.new()
	vl.custom_minimum_size = Vector2(52, 0)
	vl.text = str(int(initial)) + suffix
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var sl = HSlider.new()
	sl.min_value = minv
	sl.max_value = maxv
	sl.step = 1
	sl.value = initial
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.focus_mode = Control.FOCUS_NONE
	sl.value_changed.connect(func(v):
		vl.text = str(int(v)) + suffix
		cb.call(v))
	row.add_child(l)
	row.add_child(sl)
	row.add_child(vl)
	parent.add_child(row)
	if key != "":
		ctl[key] = sl
	return sl

func Page(tabs, name):
	var sc = ScrollContainer.new()
	sc.name = name
	sc.custom_minimum_size = Vector2(0, 470)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	sc.add_child(v)
	tabs.add_child(sc)
	return v

func Accent():
	var t = THEMES[theme_idx]
	return Color.from_hsv(float(t[1]), float(t[2]), 1.0)

func MakeTheme():
	var th = Theme.new()
	th.set_stylebox("tab_selected", "TabContainer", sb["tab_sel"])
	th.set_stylebox("tab_unselected", "TabContainer", sb["tab_uns"])
	th.set_stylebox("tab_hovered", "TabContainer", sb["tab_hov"])
	th.set_stylebox("tab_disabled", "TabContainer", sb["tab_uns"])
	th.set_stylebox("panel", "TabContainer", StyleBoxEmpty.new())
	th.set_stylebox("slider", "HSlider", sb["slider"])
	th.set_stylebox("grabber_area", "HSlider", sb["fill"])
	th.set_stylebox("grabber_area_highlight", "HSlider", sb["fill"])
	th.set_color("font_selected_color", "TabContainer", Color(1, 1, 1))
	th.set_color("font_unselected_color", "TabContainer", Color(0.66, 0.7, 0.8))
	th.set_color("font_hovered_color", "TabContainer", Color(0.95, 0.97, 1))
	th.set_font_size("font_size", "TabContainer", 16)
	th.set_font_size("font_size", "Label", 15)
	th.set_font_size("font_size", "Button", 15)
	th.set_font_size("font_size", "CheckButton", 15)
	th.set_font_size("font_size", "OptionButton", 15)
	th.set_constant("separation", "VBoxContainer", 7)
	th.set_constant("separation", "HBoxContainer", 8)
	return th

func Card(parent, title, note = ""):
	var pc = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb["card"])
	var v = VBoxContainer.new()
	pc.add_child(v)
	var l = Label.new()
	l.text = title.to_upper()
	l.add_theme_color_override("font_color", Accent())
	acc_nodes.append(l)
	l.add_theme_font_size_override("font_size", 14)
	if note != "":
		var h = HBoxContainer.new()
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var n = Label.new()
		n.text = note
		n.add_theme_color_override("font_color", Color(1.0, 0.7, 0.25))
		n.add_theme_font_size_override("font_size", 12)
		h.add_child(n)
		v.add_child(h)
	else:
		v.add_child(l)
	parent.add_child(pc)
	return v

func AddOption(parent, text, items, initial, cb):
	var row = HBoxContainer.new()
	var l = Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var o = OptionButton.new()
	o.focus_mode = Control.FOCUS_NONE
	o.custom_minimum_size = Vector2(170, 0)
	for it in items:
		o.add_item(it)
	o.select(initial)
	o.item_selected.connect(cb)
	row.add_child(l)
	row.add_child(o)
	parent.add_child(row)
	return o

func AddPair(parent, text_a, cb_a, text_b, cb_b):
	var row = HBoxContainer.new()
	var a = AddButton(row, text_a, cb_a)
	var b = AddButton(row, text_b, cb_b)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

func ShellCard(page, setter, host_note):
	var c = Card(page, "Change Shells", host_note)
	var l1 = Label.new()
	l1.text = "Current Shell"
	c.add_child(l1)
	AddPair(c, "Live", func(): setter.call(0, "live"), "Blank", func(): setter.call(0, "blank"))
	var l2 = Label.new()
	l2.text = "Next Shell"
	c.add_child(l2)
	AddPair(c, "Live", func(): setter.call(1, "live"), "Blank", func(): setter.call(1, "blank"))

func BuildUi():
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 128
	add_child(ui_layer)

	hud = RichTextLabel.new()
	hud.bbcode_enabled = true
	hud.fit_content = false
	hud.scroll_active = false
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.visible = false
	hud.add_theme_constant_override("outline_size", 6)
	hud.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	ui_layer.add_child(hud)

	panel = PanelContainer.new()
	panel.theme = MakeTheme()
	panel.add_theme_stylebox_override("panel", sb["panel"])
	panel.position = panel_pos
	panel.custom_minimum_size = Vector2(440, 0)
	if sharp:
		get_tree().root.gui_embed_subwindows = false
		win = Window.new()
		win.borderless = true
		win.unresizable = true
		win.always_on_top = true
		win.visible = false
		win.size = Vector2i(400, 300)
		win.position = DisplayServer.screen_get_position() + Vector2i(40, 40)
		win.close_requested.connect(func(): SetMenu(false))
		win.window_input.connect(WinInput)
		add_child(win)
		win.add_child(panel)
	else:
		panel.visible = false
		ui_layer.add_child(panel)

	var root = VBoxContainer.new()
	panel.add_child(root)
	var bar = HBoxContainer.new()
	root.add_child(bar)
	var title = Label.new()
	title.text = TITLE
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	title.mouse_default_cursor_shape = Control.CURSOR_MOVE
	title.gui_input.connect(TitleInput)
	bar.add_child(title)
	var xb = Button.new()
	xb.text = "X"
	xb.focus_mode = Control.FOCUS_NONE
	xb.custom_minimum_size = Vector2(32, 0)
	xb.add_theme_stylebox_override("normal", StyleBox(Color(0.75, 0.2, 0.2)))
	xb.add_theme_stylebox_override("hover", StyleBox(Color(0.92, 0.3, 0.3)))
	xb.add_theme_stylebox_override("pressed", StyleBox(Color(0.55, 0.12, 0.12)))
	xb.pressed.connect(func(): SetMenu(false))
	bar.add_child(xb)
	root.add_child(HSeparator.new())

	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)

	var sp = Page(tabs, "Singleplayer")
	var c = Card(sp, "LocalPlayer Health")
	AddSpin(c, "Health", 1, 8, sp_pl_value, func(v): sp_pl_value = int(v), "sp_pl_val")
	AddToggle(c, "Freeze Health", false, func(on): sp_pl_freeze = on, "sp_pl_freeze")
	AddButton(c, "Set Health Once", func(): ApplyHealth(true, sp_pl_value))
	c = Card(sp, "Dealer Health")
	AddSpin(c, "Health", 1, 8, sp_dl_value, func(v): sp_dl_value = int(v), "sp_dl_val")
	AddToggle(c, "Freeze Health", false, func(on): sp_dl_freeze = on, "sp_dl_freeze")
	AddButton(c, "Set Health Once", func(): ApplyHealth(false, sp_dl_value))
	c = Card(sp, "Shells")
	AddToggle(c, "Show The Next Shells", false, func(on): sp_show_shells = on, "sp_shells")
	AddToggle(c, "Show Full Sequence", false, func(on): sp_full = on, "sp_full")
	shell_label = RichTextLabel.new()
	shell_label.bbcode_enabled = true
	shell_label.fit_content = true
	shell_label.scroll_active = false
	shell_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(shell_label)
	ShellCard(sp, SetShellSp, "")
	c = Card(sp, "Damage")
	AddToggle(c, "Always Double Damage", false, func(on): sp_double = on, "sp_double")
	c = Card(sp, "Dealer")
	AddToggle(c, "Dealer Forgets Shell", false, func(on): dealer_forget = on, "sp_forget")
	c = Card(sp, "Item Giver")
	AddOption(c, "Item", SP_ITEMS, sp_item_idx, func(i): sp_item_idx = i)
	AddButton(c, "Give Item", func(): GiveItemSp())

	var co = Page(tabs, "Co-op")
	role_label = Label.new()
	role_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	co.add_child(role_label)
	c = Card(co, "LocalPlayer Health")
	AddSpin(c, "Health", 1, 8, co_value, func(v): co_value = int(v), "co_val")
	AddToggle(c, "Freeze Health", false, func(on): co_freeze = on, "co_freeze")
	AddButton(c, "Set Health Once", func(): CoopHealth(co_value))
	c = Card(co, "Shells")
	AddToggle(c, "Show The Next Shells", false, func(on): co_show_shells = on, "co_shells")
	AddToggle(c, "Show Full Sequence", false, func(on): co_full = on, "co_full")
	co_label = RichTextLabel.new()
	co_label.bbcode_enabled = true
	co_label.fit_content = true
	co_label.scroll_active = false
	co_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(co_label)
	ShellCard(co, SetShellCoop, "Host-Only")
	c = Card(co, "Damage", "Host-Only")
	AddToggle(c, "Always Double Damage", false, func(on): co_double = on, "co_double")
	c = Card(co, "Item Giver", "Host-Only")
	co_item_opt = OptionButton.new()
	co_item_opt.focus_mode = Control.FOCUS_NONE
	c.add_child(co_item_opt)
	AddButton(c, "Give Item", func(): GiveItemCoop())

	var ms = Page(tabs, "Misc")
	c = Card(ms, "Intro", "Singleplayer")
	AddToggle(c, "Skip Intro", false, func(on): skip_intro = on, "skip_intro")
	c = Card(ms, "Game Speed")
	AddToggle(c, "Enable Game Speed", false, func(on): speed_on = on, "speed_on")
	AddSlider(c, "Speed", 1, 100, 1, "x", func(v): speed_value = float(v), "speed_val")
	c = Card(ms, "Achievements")
	AddButton(c, "Unlock All Achievements", func(): UnlockAll())
	status_label = Label.new()
	status_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	c.add_child(status_label)
	c = Card(ms, "Double Or Nothing")
	money_label = Label.new()
	money_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	c.add_child(money_label)
	AddSpin(c, "Money", 0, 999999999999, money_value, func(v): money_value = v, "money_val")
	AddToggle(c, "Lock Money", false, func(on): money_lock = on, "money_lock")
	AddButton(c, "Set Money Once", func(): SetMoney(money_value))

	var st = Page(tabs, "Settings")
	c = Card(st, "Menu")
	AddSlider(c, "UI Scale", 50, 200, ui_scale, "%", func(v):
		ui_scale = v
		ApplyLayout()
		SaveCfg())
	AddSlider(c, "Opacity", 30, 100, opacity, "%", func(v):
		opacity = v
		ApplyLayout()
		SaveCfg())
	AddToggle(c, "Unlock Mouse", unlock_mouse, func(on):
		unlock_mouse = on
		if IsOpen():
			if on and not mouse_taken:
				prev_mouse = Input.mouse_mode
				mouse_taken = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			elif not on and mouse_taken:
				Input.mouse_mode = prev_mouse
				mouse_taken = false
		SaveCfg())
	var names = []
	for k in KEYS:
		names.append(k[0])
	AddOption(c, "Menu Key", names, key_idx, func(i):
		key_idx = i
		SaveCfg())
	c = Card(st, "Shell Text")
	AddSlider(c, "Text Size", 12, 60, hud_size, "", func(v):
		hud_size = v
		ApplyLayout()
		SaveCfg())
	AddToggle(c, "Show At Bottom", hud_bottom, func(on):
		hud_bottom = on
		ApplyLayout()
		SaveCfg())
	c = Card(st, "Theme")
	var tn = []
	for t in THEMES:
		tn.append(t[0])
	AddOption(c, "Menu Theme", tn, theme_idx, func(i):
		theme_idx = i
		ApplyTheme()
		SaveCfg())
	c = Card(st, "Quality")
	AddOption(c, "HD Render", ["While Menu Open", "Always", "Off"], render_mode, func(i):
		render_mode = i
		ApplyRender()
		SaveCfg())
	c = Card(st, "Configs")
	AddButton(c, "Save Config", func(): SaveFeatures())
	AddButton(c, "Load Config", func(): LoadFeatures())
	c = Card(st, "Config")
	AddButton(c, "Reset Position", func():
		panel.position = Vector2(20, 20)
		ApplyLayout()
		SaveCfg())
	AddButton(c, "Reset Settings", func():
		ui_scale = 100.0
		opacity = 100.0
		hud_size = 22.0
		hud_bottom = false
		panel.position = Vector2(20, 20)
		ApplyLayout()
		SaveCfg())
