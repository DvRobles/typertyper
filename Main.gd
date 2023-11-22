extends Node2D

var Enemy = preload("res://Enemy.tscn")

onready var enemy_container = $EnemyContainer
onready var spawn_container = $SpawnContainer
onready var spawn_timer = $SpawnTimer
onready var difficulty_timer = $DifficultyTimer

onready var shoot = $shoot
onready var boom = $boom
onready var song = $spaceloop



onready var difficulty_value = $CanvasLayer/VBoxContainer/BottomRow/HBoxContainer/DifficultyValue
onready var killed_value = $CanvasLayer/VBoxContainer/TopRow2/TopRow/EnemiesKilledValue
onready var wpm_label = $CanvasLayer/VBoxContainer/BottomRow/HBoxContainer2/wpm_label
onready var game_over_screen = $CanvasLayer/GameOverScreen
onready var finalwpm = $CanvasLayer/GameOverScreen/CenterContainer/VBoxContainer/Label2

var active_enemy = null
var current_letter_index: int = -1

var difficulty: int = 0
var enemies_killed: int = 0
var total_words: int = 0
var start_time: float = 0.0


func _ready() -> void:
	start_game()
	song.connect("finished", self, "_on_Song_finished")
	
func _on_Song_finished():
	# Esta función se llama cuando la canción termina
	song.play()

func play_shoot():
	# Reproduce el sonido de disparo
	shoot.play()
	# Espera 0.1 segundos
	yield(get_tree().create_timer(0.9), "timeout")
	# Detiene el sonido de disparo
	shoot.stop()


func play_boom():
	# Reproduce el sonido de la explosión
	boom.play()
	# Espera 1 segundo
	yield(get_tree().create_timer(0.15), "timeout")
	# Detiene el sonido de la explosión
	boom.stop()

func find_new_active_enemy(typed_character: String):
	for enemy in enemy_container.get_children():
		var prompt = enemy.get_prompt()
		var next_character = prompt.substr(0, 1)
		if next_character == typed_character:
			print("found new enemy that starts with %s" % next_character)
			active_enemy = enemy
			current_letter_index = 1
			active_enemy.set_next_character(current_letter_index)
			return


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var typed_event = event as InputEventKey
		var key_typed = PoolByteArray([typed_event.unicode]).get_string_from_utf8()

		if active_enemy == null:
			find_new_active_enemy(key_typed)
		else:
			var prompt = active_enemy.get_prompt()
			var next_character = prompt.substr(current_letter_index, 1)
			if key_typed == next_character:
				play_shoot()
				print("successfully typed %s" % key_typed)
				current_letter_index += 1
				active_enemy.set_next_character(current_letter_index)
				if current_letter_index == prompt.length():
					print("done")
					current_letter_index = -1
					active_enemy.queue_free()
					active_enemy = null
					enemies_killed += 1
					total_words += 1
					update_wpm()
					killed_value.text = str(enemies_killed)
					play_boom()
			else:
				print("incorrectly typed %s instead of %s" % [key_typed, next_character])


func _on_SpawnTimer_timeout() -> void:
	spawn_enemy()


func spawn_enemy():
	var enemy_instance = Enemy.instance()
	var spawns = spawn_container.get_children()
	var index = randi() % spawns.size()
	enemy_instance.global_position = spawns[index].global_position
	enemy_container.add_child(enemy_instance)
	enemy_instance.set_difficulty(difficulty)


func _on_DifficultyTimer_timeout() -> void:
	if difficulty >= 20:
		difficulty_timer.stop()
		difficulty = 20
		return

	difficulty += 1
	GlobalSignals.emit_signal("difficulty_increased", difficulty)
	print("Difficulty increased to %d" % difficulty)
	var new_wait_time = spawn_timer.wait_time - 0.2
	spawn_timer.wait_time = clamp(new_wait_time, 1, spawn_timer.wait_time)
	difficulty_value.text = str(difficulty)


func _on_LoseArea_body_entered(body: Node) -> void:
	game_over()


func start_game():
	game_over_screen.hide()
	spawn_timer.start()
	difficulty_timer.start()
	spawn_enemy()

	# Reinicia las variables a su estado inicial
	difficulty = 0
	enemies_killed = 0
	total_words = 0
	start_time = OS.get_ticks_msec() / 1000.0 # Guarda el tiempo de inicio en segundos

	active_enemy = null
	current_letter_index = -1

	# Actualiza los valores en la interfaz de usuario
	difficulty_value.text = str(difficulty)
	killed_value.text = str(enemies_killed)

	# Deshabilita el cursor del mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)  # Oculta el cursor del mouse
	song.play()


func game_over():
	game_over_screen.show()
	spawn_timer.stop()
	difficulty_timer.stop()
	active_enemy = null
	current_letter_index = -1

	# Habilita nuevamente el cursor del mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Muestra el cursor del mouse

	for enemy in enemy_container.get_children():
		enemy.queue_free()

	print_final_wpm()
	song.stop()

func _on_RestartButton_pressed() -> void:
	start_game()
	wpm_label.text = "            WPM: 0"  # Reinicia el valor del WPM a cero
	finalwpm.text = ""  # Borra el valor de "Final WPM"



func _on_homePage_pressed():
	get_tree().change_scene("res://Menu.tscn")
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func update_wpm():
	var elapsed_time = (OS.get_ticks_msec() / 1000.0) - start_time
	var wpm = (total_words / elapsed_time) * 60.0
	# Actualiza la etiqueta en pantalla con el valor de WPM
	wpm_label.text = "            WPM: " + str(round(wpm))



func print_final_wpm():
	var elapsed_time = (OS.get_ticks_msec() / 1000.0) - start_time # Calcula el tiempo total del juego en segundos
	var wpm = (total_words / elapsed_time) * 60.0 # Calcula las palabras por minuto
	finalwpm.text = "             Final WPM: " + str(round(wpm))
 
