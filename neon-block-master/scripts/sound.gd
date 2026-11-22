extends Node
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var cursor := 0

func _ready() -> void:
	music = AudioStreamPlayer.new()
	var track: AudioStreamWAV = load("res://assets/audio/pulse.wav")
	track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	track.loop_begin = 0
	track.loop_end = roundi(track.get_length()*track.mix_rate)
	music.stream = track
	music.volume_db = -15
	add_child(music)
	for i in 6:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -9
		add_child(voice)
		voices.append(voice)
	apply()

func apply() -> void:
	if Store.data.settings.music:
		if not music.playing: music.play()
	else: music.stop()

func play(kind: String) -> void:
	if not Store.data.settings.sound: return
	var player: AudioStreamPlayer = voices[cursor % voices.size()]
	cursor += 1
	player.stream = load("res://assets/audio/"+kind+".wav")
	player.play()

func haptic() -> void:
	if Store.data.settings.vibration and OS.get_name() == "Android": Input.vibrate_handheld(18)

func _notification(what: int) -> void:
	if music == null: return
	if what == NOTIFICATION_APPLICATION_PAUSED: music.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED: music.stream_paused = false

func shutdown() -> void:
	music.stop()
	music.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null

func _exit_tree() -> void:
	shutdown()
