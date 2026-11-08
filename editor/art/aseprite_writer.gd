extends RefCounted
## Writes an RGBA Aseprite file (.aseprite) with layers, frames and animation
## tags, following Aseprite's published file spec
## (https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md).
## Used by export_sprites.gd so code-drawn characters can be opened and edited
## by hand.
##
## frames: Array of Dictionary { layer name: Image } (missing or empty layers
## are skipped for that frame). layers: names, bottom to top. tags: Array of
## [name, from, to] (inclusive). durations: milliseconds per frame.

const CHUNK_LAYER: int = 0x2004
const CHUNK_CEL: int = 0x2005
const CHUNK_TAGS: int = 0x2018
const CHUNK_PALETTE: int = 0x2019
const CEL_COMPRESSED: int = 2


static func write(path: String, size: Vector2i, layers: Array[String], frames: Array[Dictionary], durations: Array[int], tags: Array[Array]) -> Error:
	var body: PackedByteArray = PackedByteArray()
	for i: int in range(frames.size()):
		var chunks: Array[PackedByteArray] = []
		if i == 0:
			for name: String in layers:
				chunks.append(_layer(name))
			chunks.append(_palette(frames))
			if not tags.is_empty():
				chunks.append(_tags(tags))
		for li: int in range(layers.size()):
			var img: Image = frames[i].get(layers[li])
			if img == null:
				continue
			var used: Rect2i = img.get_used_rect()
			if used.size.x <= 0 or used.size.y <= 0:
				continue
			chunks.append(_cel(li, img.get_region(used), used.position))
		body.append_array(_frame(chunks, durations[i]))
	var file: PackedByteArray = _header(size, frames.size(), 128 + body.size())
	file.append_array(body)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_buffer(file)
	f.close()
	return OK


static func _header(size: Vector2i, frame_count: int, file_size: int) -> PackedByteArray:
	var b: StreamPeerBuffer = StreamPeerBuffer.new()
	b.put_u32(file_size)
	b.put_u16(0xA5E0)
	b.put_u16(frame_count)
	b.put_u16(size.x)
	b.put_u16(size.y)
	b.put_u16(32)        # RGBA
	b.put_u32(1)         # layer opacity is valid
	b.put_u16(100)       # deprecated speed
	b.put_u32(0)
	b.put_u32(0)
	b.put_u8(0)          # transparent index (indexed mode only)
	for i: int in range(3):
		b.put_u8(0)
	b.put_u16(0)         # number of colours (0 = 256, old files)
	b.put_u8(1)          # pixel width
	b.put_u8(1)          # pixel height
	b.put_16(0)          # grid x
	b.put_16(0)          # grid y
	b.put_u16(size.x)    # grid: one cell per frame-sized area
	b.put_u16(size.y)
	for i: int in range(84):
		b.put_u8(0)
	return b.data_array


static func _frame(chunks: Array[PackedByteArray], ms: int) -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	for c: PackedByteArray in chunks:
		data.append_array(c)
	var b: StreamPeerBuffer = StreamPeerBuffer.new()
	b.put_u32(16 + data.size())
	b.put_u16(0xF1FA)
	b.put_u16(mini(chunks.size(), 0xFFFF))
	b.put_u16(ms)
	b.put_u8(0)
	b.put_u8(0)
	b.put_u32(chunks.size())
	var out: PackedByteArray = b.data_array
	out.append_array(data)
	return out


static func _chunk(type: int, data: PackedByteArray) -> PackedByteArray:
	var b: StreamPeerBuffer = StreamPeerBuffer.new()
	b.put_u32(6 + data.size())
	b.put_u16(type)
	var out: PackedByteArray = b.data_array
	out.append_array(data)
	return out


static func _string(b: StreamPeerBuffer, s: String) -> void:
	var bytes: PackedByteArray = s.to_utf8_buffer()
	b.put_u16(bytes.size())
	b.put_data(bytes)


static func _layer(name: String) -> PackedByteArray:
	var b: StreamPeerBuffer = StreamPeerBuffer.new()
	b.put_u16(3)    # visible, editable
	b.put_u16(0)    # normal image layer
	b.put_u16(0)    # child level
	b.put_u16(0)
	b.put_u16(0)
	b.put_u16(0)    # blend mode: normal
	b.put_u8(255)   # opacity
	for i: int in range(3):
		b.put_u8(0)
	_string(b, name)
	return _chunk(CHUNK_LAYER, b.data_array)


static func _cel(layer: int, img: Image, at: Vector2i) -> PackedByteArray:
	var rgba: Image = img.duplicate() as Image
	rgba.convert(Image.FORMAT_RGBA8)
	var b: StreamPeerBuffer = StreamPeerBuffer.new()
	b.put_u16(layer)
	b.put_16(at.x)
	b.put_16(at.y)
	b.put_u8(255)
	b.put_u16(CEL_COMPRESSED)
	b.put_16(0)     # z-index
	for i: int in range(5):
		b.put_u8(0)
	b.put_u16(rgba.get_width())
	b.put_u16(rgba.get_height())
	# Godot's deflate mode writes a zlib stream, which is what Aseprite reads.
	b.put_data(rgba.get_data().compress(FileAccess.COMPRESSION_DEFLATE))
	return _chunk(CHUNK_CEL, b.data_array)


static func _tags(tags: Array[Array]) -> PackedByteArray:
	var b: StreamPeerBuffer = StreamPeerBuffer.new()
	b.put_u16(tags.size())
	for i: int in range(8):
		b.put_u8(0)
	for t: Array in tags:
		b.put_u16(t[1])
		b.put_u16(t[2])
		b.put_u8(0)     # forward
		b.put_u16(0)    # repeat forever
		for i: int in range(6):
			b.put_u8(0)
		for i: int in range(3):
			b.put_u8(0)
		b.put_u8(0)
		_string(b, t[0])
	return _chunk(CHUNK_TAGS, b.data_array)


## The character's colours, most used first (up to 256), so the palette in
## Aseprite is the one the sprite is drawn in.
static func _palette(frames: Array[Dictionary]) -> PackedByteArray:
	var count: Dictionary[int, int] = {}
	for f: Dictionary in frames:
		for img: Image in f.values():
			for y: int in range(img.get_height()):
				for x: int in range(img.get_width()):
					var c: Color = img.get_pixel(x, y)
					if c.a <= 0.0:
						continue
					var key: int = c.to_rgba32()
					count[key] = count.get(key, 0) + 1
	var keys: Array = count.keys()
	keys.sort_custom(func(a: int, z: int) -> bool: return count[a] > count[z])
	keys = keys.slice(0, 256)
	var b: StreamPeerBuffer = StreamPeerBuffer.new()
	b.put_u32(maxi(keys.size(), 1))
	b.put_u32(0)
	b.put_u32(maxi(keys.size(), 1) - 1)
	for i: int in range(8):
		b.put_u8(0)
	if keys.is_empty():
		keys = [0]
	for k: int in keys:
		b.put_u16(0)
		b.put_u8((k >> 24) & 0xFF)
		b.put_u8((k >> 16) & 0xFF)
		b.put_u8((k >> 8) & 0xFF)
		b.put_u8(k & 0xFF)
	return _chunk(CHUNK_PALETTE, b.data_array)
