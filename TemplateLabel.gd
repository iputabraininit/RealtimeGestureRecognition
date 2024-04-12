extends Node2D
class_name TemplateLabelBehaviour

var default_font : Font = ThemeDB.fallback_font;
@export var text = "Default"
@export var font_size:int = 16
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	var text_size_in_font:Vector2 = default_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	text_size_in_font.y = 0
	
	draw_string(default_font, Vector2.ZERO - (text_size_in_font / 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
