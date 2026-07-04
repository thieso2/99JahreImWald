@tool
extends TextureRect

# Erzeugt eine einfache Kreis-Textur für den Joystick

@export var circle_color: Color = Color(1, 1, 1, 1)
@export var circle_radius: int = 80
@export var is_filled: bool = false
@export var border_width: int = 3


func _ready() -> void:
	_generate_circle_texture()


func _generate_circle_texture() -> void:
	var img := Image.create(circle_radius * 2, circle_radius * 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var center := Vector2(circle_radius, circle_radius)

	for x in range(circle_radius * 2):
		for y in range(circle_radius * 2):
			var dist := Vector2(x, y).distance_to(center)
			if is_filled:
				if dist <= circle_radius:
					img.set_pixel(x, y, circle_color)
			else:
				if dist <= circle_radius and dist >= circle_radius - border_width:
					img.set_pixel(x, y, circle_color)

	var tex := ImageTexture.create_from_image(img)
	texture = tex
