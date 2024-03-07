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
		if template_name == null || template_name.is_empty():
			continue
			
		#prints(template_name, "points", (template_line.size() - 1) / 2)
		
		var template_points:Array[Vector2] =  []
		for i in range(1, template_line.size(), 2):
			var x = float(template_line[i])
			var y = float(template_line[i + 1])
			template_points.append(Vector2(x, y))
		
		template_library.add_template(template_line[0], template_points)
	#print("Triangle before:")
	#prints(_templates["triangle"])
	#var resampled_points = template_library._resample_between_points_penny_pincher_style("triangle", _templates["triangle"])
	#
	#_resampled_templates["triangle"] = resampled_points
	#prints("Resampled points", resampled_points, "size", resampled_points.size())
	emit_signal("on_templates_loaded")
	
 
