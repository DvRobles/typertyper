extends Label

var text_speed = 0.1 # Velocidad a la que se muestra el texto
var text_content = "" # El texto que se va a mostrar
var current_index = 0 # Índice del carácter actual en el texto
var accumulated_time = 0.0 # Tiempo acumulado

func _ready():
	text_content = self.text
	self.text = ""
	set_process(true)

func _process(delta):
	if current_index < len(text_content):
		accumulated_time += delta
		if accumulated_time >= text_speed:
			self.text += text_content[current_index]
			current_index += 1
			accumulated_time = 0.0
	else:
		# Todo el texto se ha escrito, reiniciar para un nuevo ciclo
		self.text = ""
		current_index = 0
		accumulated_time = 0.0
