extends RefCounted
## Procura uma imagem em assets/art/ (JPG ou PNG). Devolve null se não houver,
## para a interface cair na arte provisória desenhada em código.

const FOLDER := "res://assets/art/"


static func load_art(name: String) -> Texture2D:
	for ext in [".jpg", ".png"]:
		var path: String = FOLDER + name + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null
