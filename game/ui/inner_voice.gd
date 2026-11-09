class_name InnerVoice
extends Control
## The detective's inner voice, as text only (Look and Feel doc, settled
## 2026-11-04): his thoughts type out over his head, and narration opening a
## scene types out in a caption box at the bottom of the screen.
##
## What it says, in order of who wins: narration, then a line from the case
## (`say`: a passenger arriving, a dose, bleed-through in a new room), then
## the idle thoughts it was given, one after another until it goes quiet.
## Each line stays up a little after it finishes typing, then gives way.

enum Mode { THOUGHT, CAPTION, NONE }

const P = preload("res://game/art/art_palette.gd")
const TEXT: Color = Color("d4dce6")
## Letters a second, and how many letters' worth a finished line stays up.
const TYPE_SPEED: float = 38.0
const LINGER: float = 140.0

## How thoughts are shown (narration is always the caption box).
var mode: Mode = Mode.THOUGHT
## Thoughts to go through when nothing else is being said.
var thoughts: Array[String] = []
var narration: String = ""
var said: String = ""
## Which of `thoughts` is up, and how many have been.
var line: int = 0
var thoughts_shown: int = 1
## Out of idle thoughts: only narration and the case's lines show now.
var quiet: bool = false
## Letters typed of the current line.
var typed: float = 0.0
## Holds the line as it is (screenshots).
var still: bool = false

var _thought: Label
var _caption: PanelContainer
var _caption_label: Label


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thought = Label.new()
	_thought.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_thought.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thought.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_thought.add_theme_color_override("font_color", TEXT)
	_thought.add_theme_color_override("font_outline_color", Color(P.INK, 0.9))
	_thought.visible = false
	add_child(_thought)

	_caption = PanelContainer.new()
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(P.NAVY, 0.9)
	box.border_color = P.AMBER_DIM
	box.border_width_left = 4
	_caption.add_theme_stylebox_override("panel", box)
	_caption.visible = false
	add_child(_caption)
	_caption_label = Label.new()
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_label.add_theme_color_override("font_color", TEXT)
	_caption.add_child(_caption_label)


## Narration opening a scene, in the caption box.
func narrate(text: String) -> void:
	narration = text
	typed = 0.0


## A line of the inner voice from the case.
func say(text: String) -> void:
	said = text
	typed = 0.0


## Takes back a line from the case if it's still up (it's been answered).
func unsay(text: String) -> void:
	if said == text:
		said = ""


## Brings the next idle thought up (and wakes the voice if it went quiet).
func next_thought() -> void:
	if thoughts.is_empty():
		return
	quiet = false
	line = (line + 1) % thoughts.size()
	thoughts_shown += 1
	typed = 0.0


## What the voice is saying now ("" when quiet).
func current() -> String:
	if narration != "":
		return narration
	if said != "":
		return said
	if quiet or thoughts.is_empty():
		return ""
	return thoughts[line]


## Types the line out, and moves on once it's lingered.
func advance(delta: float) -> void:
	if still:
		return
	typed += delta * TYPE_SPEED
	if typed <= current().length() + LINGER:
		return
	if narration != "":
		narration = ""
		typed = 0.0
	elif said != "":
		said = ""
		typed = 0.0
	elif not quiet:
		if thoughts_shown < thoughts.size():
			next_thought()
		else:
			quiet = true


## Shows the line: over the detective's head at `head` (native pixels, in
## view), or in the caption box. Hidden while `busy` (talking, at the board,
## holding something up).
func show_line(view: PixelView, head: Vector2, busy: bool) -> void:
	var text: String = current()
	var shown: String = text.substr(0, int(typed))
	var speaking: bool = text != "" and not busy and mode != Mode.NONE
	# Narration opening a scene is always the caption box (Look and Feel doc).
	var as_mode: Mode = Mode.CAPTION if narration != "" else mode
	_thought.visible = as_mode == Mode.THOUGHT and speaking
	_caption.visible = as_mode == Mode.CAPTION and speaking
	var font_px: int = view.font_px()
	if _thought.visible:
		_thought.add_theme_font_size_override("font_size", font_px)
		_thought.add_theme_constant_override("outline_size", maxi(2, font_px / 5))
		_thought.text = shown
		var win: Vector2 = Vector2(get_window().size)
		var width: float = minf(win.x * 0.36, 640.0)
		var at: Vector2 = view.to_window(head)
		_thought.size = Vector2(width, 10)
		_thought.reset_size()
		_thought.size.x = width
		var h: float = _thought.get_combined_minimum_size().y
		_thought.position = Vector2(clampf(at.x - width * 0.5, view.offset.x + 16.0, view.offset.x + view.shown.x - width - 16.0), at.y - h)
	elif _caption.visible:
		_caption_label.add_theme_font_size_override("font_size", font_px)
		var box: StyleBoxFlat = _caption.get_theme_stylebox("panel") as StyleBoxFlat
		box.set_content_margin_all(font_px * 0.8)
		box.content_margin_left = font_px * 1.2
		var width: float = minf(view.shown.x * 0.5, 900.0)
		_caption.size = Vector2(width, 0)
		_caption.reset_size()
		_caption.size.x = width
		# Reserve the full line's height so the box doesn't grow as it types.
		_caption_label.text = text
		var h: float = _caption.get_combined_minimum_size().y
		_caption_label.text = shown
		_caption.size = Vector2(width, h)
		_caption.position = view.offset + Vector2(view.shown.x * 0.04, view.shown.y - h - view.shown.y * 0.05)


func is_showing() -> bool:
	return _thought.visible or _caption.visible
