extends Control
# this is the script that drives the main menu
var select_pack    # the OptionButton for selecting packs
var target         # When moveing the view, where do we want to go?
var level_btn_scene = preload("res://scenes/level_select_btn.xml") # the Level selecion button in a scene
var level_list     # the node that contains all level buttons
export var level_btn_size = Vector2(100,100) # the size+margin of every level selecion button
var level_btn_row_count = 6 #
var level_selected # The level we have selected
var global # the global node (serves like a library, see global.gd)
var packs_included = [] # name of packs loaded from "res://levels" (levels existing when exporting project), generated in _ready

func _ready():
	# Finding nodes
	global = get_node("/root/global")
	select_pack = get_node("level_selection/opt_pack")
	level_list = get_node("level_selection/level_list")
	# Filling the credits label
	var credits = get_node("credits/Label")
	var f = File.new()
	f.open("res://CREDITS.txt", f.READ)
	var credit = ""
	while(!f.eof_reached()):
		credit = str(credit, "\n", f.get_line())
	credits.set_text(credit)
	# Using the Diectory class to list all folders, so we can add the packs to the menu
	var diraccess = Directory.new()
	# check 2 paths - 1. bundled levels, 2. created later using map editor
	var dir_paths = ["res://levels/"] # res://levels (bundled)
	dir_paths.append(Globals.globalize_path(dir_paths[0])) # C:/.../levels (disk)
	for path in dir_paths:
		diraccess.open(path)
		diraccess.list_dir_begin()
		var name = diraccess.get_next()
		var i = 1 # the id of the number
		select_pack.add_item("tutorial")
		while name:
			if diraccess.current_is_dir():
				if name != "." and name != ".." and name != "tutorial":
					if path.begins_with("res://"): # bundled
						select_pack.add_item(name)
						packs_included.append(name)
					else: # made with map editor
						if !name in packs_included: 
							select_pack.add_item(name)
			name = diraccess.get_next()
		diraccess.list_dir_end()
	_on_opt_pack_item_selected(0)#Update level list

func _on_opt_pack_item_selected( ID ):
	#remove old level selection buttons
	for i in range(level_list.get_child_count()):
		level_list.get_child(i).queue_free()
	#Get the number of locked levels
	var locked_count = global.get_reached_level(select_pack.get_text())
	#Get the names of the levels
	var level_names = {}
	var f = File.new()
	var err = f.open(str("res://levels/", select_pack.get_text(), "/names.txt"),File.READ)
	if(!err):#if we can open that file
		while(!f.eof_reached()):
			var line = f.get_line().split(":")      #Read every line
			if(line[0] != ""):
				level_names[int(line[0])] = line[1] #and record the result
	f.close()
	#Using the Directory class to list all files
	var diraccess = Directory.new()
	if diraccess.open(str("res://levels/", select_pack.get_text())) != 0: # pack is not bundled
		diraccess.open(Globals.globalize_path(str("res://levels/", select_pack.get_text()))) # load from disk
	diraccess.list_dir_begin()
	var name = diraccess.get_next()
	var i = 0 #The number of the current level
	while name:
		if !diraccess.current_is_dir():
			if name.substr(0,5) == "level":# the file starts with "level"
				var new_instance = level_btn_scene.instance() # an instance of the level button
				if(level_names.has(i+1)):
					new_instance.set_title(level_names[i+1]) # When we have a name for that level, we use it
				else:
					new_instance.set_title(str("Level ",i + 1)) # Otherwise we write simply "Level N"
				new_instance.set_metadata(i + 1) # We set some metadata for later, so we won't forget which level this button is bound to
				new_instance.set_locked((i + 1) > locked_count) # When the level is locked we show it as one
				var row_pos = int(i % level_btn_row_count) # The position on X
				var col_pos = int(i / level_btn_row_count) # and on Y
				new_instance.set_pos(Vector2(level_btn_size.x * row_pos, level_btn_size.y * col_pos)) # then both of them used to make the final pos
				level_list.add_child(new_instance) # At last we add it to the list
				i = i + 1
		name = diraccess.get_next()
	diraccess.list_dir_end()

func level_btn_clicked(var id): # When any level button is clicked
	level_selected = id
	set_fixed_process(true) # We use _fixed_process to change scenes, so no crashes happen

func _fixed_process(delta):
	set_fixed_process(false)
	global.load_level(select_pack.get_text(),level_selected) # We use _fixed_process to change scenes, so no crashes happen
	
func _process(delta):
	# We use _process to move the screen
	set_pos((get_pos()*4 + target)/5)
	if(abs(get_pos().x - target.x) < 1 && abs(get_pos().y - target.y) < 1):
		set_pos(target)
		set_process(false)


func goto_levels():
	target = Vector2(-1024,0) #Select the target coordinates
	set_process(true) # We use _process to move the screen

func goto_start():
	target = Vector2(0,0)
	set_process(true)
	
func goto_options():
	target = Vector2(1024,0)
	set_process(true)
	
func goto_credits():
	target = Vector2(0,-768)
	set_process(true)

func quit():
	get_tree().quit() # Exit the game
