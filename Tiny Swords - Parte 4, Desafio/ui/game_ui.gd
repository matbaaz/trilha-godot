extends CanvasLayer

@onready var timer_label: Label = %TimerLabel
@onready var meat_label: Label = %MeatLabel
@onready var kill_label: Label = %Kills

func _process(delta: float):
	# Update labels
	timer_label.text = GameManager.time_elapsed_string
	meat_label.text = str(GameManager.meat_counter)
	kill_label.text = str(GameManager.monsters_defeated_counter)
