extends CanvasLayer

signal start_game

func _ready():
	print("Tutorial caricato correttamente")
	
	# Tentativo automatico di collegamento (in caso non l'hai fatto nell'editor)
	var button = $CenterContainer/VBoxContainer/StartButton
	if button:
		if not button.pressed.is_connected(_on_start_button_pressed):
			button.pressed.connect(_on_start_button_pressed)
			print("Segnale collegato automaticamente")
	else:
		push_error("Bottone non trovato! Controlla il nome esatto")

func _on_start_button_pressed():
	print("✅ Bottone cliccato! Sto avviando il gioco...")
	emit_signal("start_game")
	queue_free()
	print("BOTTONE PREMUTO – segnale arrivato correttamente!")
	emit_signal("start_game")
	queue_free()
