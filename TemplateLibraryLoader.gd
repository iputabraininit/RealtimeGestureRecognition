extends Node
class_name TemplateLibraryLoader

@export var template_library: TemplateLibraryBehaviour
@export var file_name: String

signal on_templates_loaded

# Called when the node enters the scene tree for the first time.
func _ready():
	var template_file = FileAccess.open(file_name, FileAccess.READ)
	

	while !template_file.eof_reached():
		var template_line:PackedStringArray =  template_file.get_csv_line(",")
		
		var template_name = template_line[0]
		if template_name == null || template_name.is_empty() || template_name.begins_with("#"):
			continue
			
		prints(template_name, "points", (template_line.size() - 1) / 2)
		
		var template_points:Array[Vector2] =  []
		for i in range(1, template_line.size(), 2):
			var x = float(template_line[i])
			var y = float(template_line[i + 1])
			template_points.append(Vector2(x, y))
			
		_move_to_origin_and_normalize(template_points)
		template_library.add_template(template_name, template_points)
	
	template_file.close()
	emit_signal("on_templates_loaded")
	
 
func _move_to_origin_and_normalize(points:Array[Vector2]):
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	var origin = points[0]

	for i in points.size():
		var point = points[i] 
		points[i] = point - origin
		min_x = min(point.x, min_x)
		max_x = max(point.x, max_x)
		min_y = min(point.y, min_y)
		max_y = max(point.y, max_y)
		
	var x_span = max_x - min_x
	var y_span = max_y - min_y
	
	var max_span:float = max(x_span, y_span)
	
	# normalizing time
	for i in points.size():
		var point = points[i]
		points[i] = point / max_span

func on_new_template_added(template_name, points:Array[Vector2]):
	print("Saving gesture " + template_name)
	var template_file = FileAccess.open(file_name, FileAccess.READ_WRITE)
	template_file.seek_end()
	
	var name_and_gesture_as_strings:Array[String] = []
	
	name_and_gesture_as_strings.append(template_name)
	for point in points:
		name_and_gesture_as_strings.append(str(point.x).pad_decimals(2))
		name_and_gesture_as_strings.append(str(point.y).pad_decimals(2))
	
	var data_to_persist = PackedStringArray(name_and_gesture_as_strings)
	template_file.store_csv_line(data_to_persist)
	
