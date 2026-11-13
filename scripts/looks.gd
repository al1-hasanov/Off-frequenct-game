class_name Looks
extends RefCounted
## Who looks like what. Each entry feeds Figure: body (sex, height, build),
## face, hair and clothes. Heights are in pixels at the game's 720p scale:
## a 172 cm woman is about 188 px; Tomas, at 13, about 152 px.
##
## sex: "f" / "m" / "boy". build: bust, belly, hips (0..1). head: head length
## as a fraction of height (adults ~0.135, Tomas 0.155).

const SKIN_LIGHT := Color("e2b597")
const SKIN_MARA := Color("dcab8c")

const ALL := {
	# Mara Lind, 34, night-shift maintenance tech. Dark brown hair in a low
	# ponytail with a side-swept fringe; olive canvas work jacket, toolbelt,
	# dark work trousers, boots.
	"mara": {
		"sex": "f", "age": 34, "height": 188.0, "head": 0.136,
		"bust": 0.55, "belly": 0.0, "hips": 0.55,
		"skin": SKIN_MARA, "hair": Color("3a2820"), "hair_hi": Color("5a4234"), "eyes": Color("3b2a1e"),
		"lips": Color("b8706a"), "style": "ponytail", "nose": "straight", "lines": 0.12,
		"top": "work_jacket", "top_col": Color("5f5c3c"), "top_trim": Color("4a4830"),
		"bottom": "trousers", "bottom_col": Color("2b3243"), "shoes": "boots", "shoe_col": Color("2a211b"),
		"toolbelt": true, "collar": Color("8a2f2a"),
	},
	# Mara three years earlier, in 1980: the same Mara, a little younger, her
	# ponytail longer (Ruth notices the haircut in 12). A navy work jacket over
	# the same red flannel; her olive work coat is the one she carries in.
	"mara_1980": {
		"sex": "f", "age": 31, "height": 188.0, "head": 0.136,
		"bust": 0.55, "belly": 0.0, "hips": 0.55,
		"skin": SKIN_MARA, "hair": Color("3a2820"), "hair_hi": Color("5a4234"), "eyes": Color("3b2a1e"),
		"lips": Color("b8706a"), "style": "ponytail_long", "nose": "straight",
		"top": "work_jacket", "top_col": Color("3c4a60"), "top_trim": Color("2e3a4c"),
		"bottom": "trousers", "bottom_col": Color("2f3340"), "shoes": "boots", "shoe_col": Color("2a211b"),
		"collar": Color("8a2f2a"),
	},
	# Eighty-One: another Mara, about 40, worn thin. Long hair in a loose braid
	# over her shoulder with a grey streak; a long charcoal coat and scarf; her
	# left hand wrapped in burn gauze.
	"eighty_one": {
		"sex": "f", "age": 41, "height": 188.0, "head": 0.136, "stoop": 0.05,
		"bust": 0.45, "belly": 0.0, "hips": 0.45, "gaunt": true,
		"skin": Color("d0a083"), "hair": Color("2f241e"), "hair_hi": Color("8d8780"), "eyes": Color("3b2a1e"),
		"lips": Color("a8706a"), "style": "braid", "nose": "straight", "lines": 0.4,
		"top": "long_coat", "top_col": Color("2c2e34"), "top_trim": Color("1f2025"),
		"bottom": "trousers", "bottom_col": Color("23262e"), "shoes": "boots", "shoe_col": Color("1b1a1a"),
		"scarf": Color("6a2f2c"), "gauze": true,
	},
	# June Pike, 70, ham radio operator: silver hair in a bun, glasses,
	# mustard cardigan over a blouse, a long plaid skirt.
	"june": {
		"sex": "f", "age": 70, "height": 176.0, "head": 0.138, "stoop": 0.07,
		"bust": 0.5, "belly": 0.35, "hips": 0.6,
		"skin": Color("e3bba3"), "hair": Color("cfccc6"), "hair_hi": Color("f0eee8"), "eyes": Color("4a5a6a"),
		"lips": Color("b07c78"), "style": "bun", "nose": "aquiline", "lines": 0.85, "glasses": true,
		"top": "cardigan", "top_col": Color("b08a32"), "top_trim": Color("e8e0cc"),
		"bottom": "skirt", "bottom_col": Color("4a3a48"), "skirt_len": 0.36, "plaid": true,
		"legs_col": Color("c9a990"), "shoes": "flats", "shoe_col": Color("3a2a22"),
	},
	# Ruth Lind ("Ma"), 58, night shift at the Lantern: an auburn perm going
	# grey, pale blue waitress dress, white apron.
	"ruth": {
		"sex": "f", "age": 58, "height": 180.0, "head": 0.137,
		"bust": 0.75, "belly": 0.35, "hips": 0.8,
		"skin": Color("ddab8e"), "hair": Color("8a5a40"), "hair_hi": Color("b0a296"), "eyes": Color("3b2a1e"),
		"lips": Color("b9706e"), "style": "perm", "nose": "button", "lines": 0.6,
		"top": "dress", "top_col": Color("8fb0c4"), "top_trim": Color("eef0ea"),
		"bottom": "dress", "bottom_col": Color("8fb0c4"), "skirt_len": 0.29,
		"legs_col": Color("caa48e"), "shoes": "flats", "shoe_col": Color("efede6"), "apron": Color("f2efe6"),
	},
	"ruth_1980": {
		"sex": "f", "age": 55, "height": 180.0, "head": 0.137,
		"bust": 0.75, "belly": 0.3, "hips": 0.8,
		"skin": Color("ddab8e"), "hair": Color("7a4630"), "hair_hi": Color("9a6448"), "eyes": Color("3b2a1e"),
		"lips": Color("bf6e6c"), "style": "perm", "nose": "button", "lines": 0.4,
		"top": "dress", "top_col": Color("8fb0c4"), "top_trim": Color("eef0ea"),
		"bottom": "dress", "bottom_col": Color("8fb0c4"), "skirt_len": 0.29,
		"legs_col": Color("caa48e"), "shoes": "flats", "shoe_col": Color("efede6"), "apron": Color("f2efe6"),
	},
	# Mrs. Lund, about 60, out in the snow in her rollers: camel coat over a
	# pink nightgown, slippers, the spare coat over her arm.
	"townswoman": {
		"sex": "f", "age": 60, "height": 178.0, "head": 0.137,
		"bust": 0.7, "belly": 0.4, "hips": 0.75,
		"skin": Color("e6b9a0"), "hair": Color("c8a46a"), "hair_hi": Color("e2c48a"), "eyes": Color("4a5a6a"),
		"lips": Color("c06e74"), "style": "rollers", "nose": "button", "lines": 0.6,
		"top": "long_coat", "top_col": Color("a07a52"), "top_trim": Color("7a5a3a"),
		"bottom": "nightgown", "bottom_col": Color("e2b8c4"), "skirt_len": 0.38,
		"legs_col": Color("e0b29a"), "shoes": "slippers", "shoe_col": Color("d896a8"), "prop": "coat",
	},
	# Mr. Lund (both of him), about 62: big, balding, grey moustache, plaid
	# robe over striped pyjamas, slippers.
	"husband": {
		"sex": "m", "age": 62, "height": 196.0, "head": 0.132,
		"bust": 0.0, "belly": 0.8, "hips": 0.4,
		"skin": Color("e0ae92"), "hair": Color("9a948c"), "hair_hi": Color("c4beb6"), "eyes": Color("3a4652"),
		"style": "horseshoe", "nose": "broad", "lines": 0.6, "beard": "moustache",
		"top": "robe", "top_col": Color("6a2e2e"), "top_trim": Color("3e3a52"),
		"bottom": "pajamas", "bottom_col": Color("a8b8d0"), "shoes": "slippers", "shoe_col": Color("4a3a30"),
	},
	# Main Street: a man in a parka and knit cap over pyjama bottoms, a thick
	# moustache.
	"townsman": {
		"sex": "m", "age": 50, "height": 194.0, "head": 0.132,
		"bust": 0.0, "belly": 0.45, "hips": 0.4,
		"skin": Color("d9a98a"), "hair": Color("4a3e36"), "hair_hi": Color("6a5a4e"), "eyes": Color("2e241e"),
		"style": "beanie", "hat_col": Color("7a2a2a"), "nose": "broad", "lines": 0.35, "beard": "moustache",
		"top": "parka", "top_col": Color("3e4a3a"), "top_trim": Color("8a7a5e"),
		"bottom": "pajamas", "bottom_col": Color("8aa0c8"), "shoes": "boots", "shoe_col": Color("4a3a30"),
	},
	# The search, 1980: a neighbour in a blaze-orange hunting jacket and knit
	# cap, and a woman from the church in a long coat and a knitted hat.
	"searcher_a": {
		"sex": "m", "age": 44, "height": 190.0, "head": 0.133,
		"bust": 0.0, "belly": 0.3, "hips": 0.4,
		"skin": Color("d8a688"), "hair": Color("5a4636"), "hair_hi": Color("7a6250"), "eyes": Color("2e241e"),
		"style": "beanie", "hat_col": Color("2e3a4a"), "nose": "straight", "lines": 0.25, "beard": "moustache",
		"top": "parka", "top_col": Color("d8622a"), "top_trim": Color("3a3028"),
		"bottom": "jeans", "bottom_col": Color("3a4660"), "shoes": "boots", "shoe_col": Color("4a3626"),
	},
	"searcher_b": {
		"sex": "f", "age": 50, "height": 178.0, "head": 0.137,
		"bust": 0.6, "belly": 0.2, "hips": 0.65,
		"skin": Color("e4b89c"), "hair": Color("8a6a50"), "hair_hi": Color("a88a70"), "eyes": Color("3a4652"),
		"style": "beanie", "hat_col": Color("8a3a4a"), "nose": "button", "lines": 0.35,
		"top": "long_coat", "top_col": Color("3a4a42"), "top_trim": Color("2a3430"),
		"bottom": "trousers", "bottom_col": Color("2e2e34"), "shoes": "boots", "shoe_col": Color("2a211b"),
	},
	# Mr. Dahl, the Lantern's regular: trucker cap, beard, flannel shirt.
	"dahl": {
		"sex": "m", "age": 56, "height": 192.0, "head": 0.133,
		"bust": 0.0, "belly": 0.7, "hips": 0.45,
		"skin": Color("d6a387"), "hair": Color("6a6058"), "hair_hi": Color("8a8078"), "eyes": Color("2e241e"),
		"style": "cap", "hat_col": Color("2e4a6a"), "nose": "broad", "lines": 0.5, "beard": "full",
		"top": "flannel", "top_col": Color("8a3a2e"), "top_trim": Color("2a2422"),
		"bottom": "jeans", "bottom_col": Color("3a4660"), "shoes": "boots", "shoe_col": Color("4a3626"),
		"prop": "mug",
	},
	# Tomas Lind, 13. Slight, with a boy's rounder face and a big head for his
	# body; tousled brown hair, red parka, jeans, sneakers, headphones and the
	# radio he built.
	"tomas": {
		"sex": "boy", "age": 13, "height": 152.0, "head": 0.162,
		"bust": 0.0, "belly": 0.0, "hips": 0.2,
		"skin": Color("dfb093"), "hair": Color("5a3b28"), "hair_hi": Color("7a5438"), "eyes": Color("3b2a1e"),
		"lips": Color("c08478"), "style": "tousled", "nose": "child",
		"top": "parka", "top_col": Color("b4352b"), "top_trim": Color("e2d6bc"),
		"bottom": "jeans", "bottom_col": Color("3a4d70"), "shoes": "sneakers", "shoe_col": Color("d8d6d0"),
		"headphones": true, "prop": "radio",
	},
	# Dr. Henrik Sollen, 64: bald with a white fringe and beard, glasses,
	# brown cardigan. Only ever seen asleep.
	"sollen": {
		"sex": "m", "age": 64, "height": 190.0, "head": 0.134,
		"bust": 0.0, "belly": 0.5, "hips": 0.4,
		"skin": Color("d8a68a"), "hair": Color("d8d4cc"), "hair_hi": Color("f0ece6"), "eyes": Color("3a4652"),
		"style": "bald_fringe", "nose": "aquiline", "lines": 0.8, "beard": "full", "glasses": true,
		"top": "cardigan", "top_col": Color("6b4f36"), "top_trim": Color("d8d0c0"),
		"bottom": "trousers", "bottom_col": Color("4a4440"), "shoes": "flats", "shoe_col": Color("2a221c"),
	},
	# Deputy Cal Ostrander, 35: short dark hair, moustache, tan uniform shirt
	# with a badge. Asleep at his desk in 05.
	"cal": {
		"sex": "m", "age": 35, "height": 194.0, "head": 0.132,
		"bust": 0.0, "belly": 0.2, "hips": 0.4,
		"skin": Color("d9a98a"), "hair": Color("33261c"), "hair_hi": Color("4a3a2c"), "eyes": Color("2e241e"),
		"style": "short", "nose": "straight", "lines": 0.2, "beard": "moustache",
		"top": "uniform", "top_col": Color("b49a6a"), "top_trim": Color("5a4630"),
		"bottom": "trousers", "bottom_col": Color("4a3a2a"), "shoes": "boots", "shoe_col": Color("17181c"),
	},

	# --- 1980: three years younger -------------------------------------------------------
	# Mr. Dahl at 53: the beard still dark, less grey at the temples.
	"dahl_1980": {
		"sex": "m", "age": 53, "height": 192.0, "head": 0.133,
		"bust": 0.0, "belly": 0.62, "hips": 0.45,
		"skin": Color("d6a387"), "hair": Color("4e4238"), "hair_hi": Color("6a5c50"), "eyes": Color("2e241e"),
		"style": "cap", "hat_col": Color("2e4a6a"), "nose": "broad", "lines": 0.32, "beard": "full",
		"top": "flannel", "top_col": Color("8a3a2e"), "top_trim": Color("2a2422"),
		"bottom": "jeans", "bottom_col": Color("3a4660"), "shoes": "boots", "shoe_col": Color("4a3626"),
		"prop": "mug",
	},
	# Deputy Cal Ostrander at 32, the night Tomas went missing: no lines yet,
	# a thinner moustache, a little leaner.
	"cal_1980": {
		"sex": "m", "age": 32, "height": 194.0, "head": 0.132,
		"bust": 0.0, "belly": 0.08, "hips": 0.4,
		"skin": Color("dcac8c"), "hair": Color("2c2018"), "hair_hi": Color("46342a"), "eyes": Color("2e241e"),
		"style": "side_part", "nose": "straight", "lines": 0.0, "beard": "moustache",
		"top": "uniform", "top_col": Color("b49a6a"), "top_trim": Color("5a4630"),
		"bottom": "trousers", "bottom_col": Color("4a3a2a"), "shoes": "boots", "shoe_col": Color("17181c"),
	},

	# --- 1991 ------------------------------------------------------------------------------
	# June Pike at 78: whiter, more bent, the same cardigan.
	"june_1991": {
		"sex": "f", "age": 78, "height": 168.0, "head": 0.139, "stoop": 0.15,
		"bust": 0.5, "belly": 0.35, "hips": 0.6,
		"skin": Color("e6c2ac"), "hair": Color("e8e6e1"), "hair_hi": Color("ffffff"), "eyes": Color("5a6a78"),
		"lips": Color("b08a84"), "style": "bun", "nose": "aquiline", "lines": 1.0, "glasses": true,
		"top": "cardigan", "top_col": Color("b08a32"), "top_trim": Color("e8e0cc"),
		"bottom": "skirt", "bottom_col": Color("4a3a48"), "skirt_len": 0.36, "plaid": true,
		"legs_col": Color("c9a990"), "shoes": "flats", "shoe_col": Color("3a2a22"),
	},
	# Tomas at 21, the boy Mara brought home, grown up in H: shaggy hair, a
	# jean jacket over a black T-shirt, sneakers. Headphones round his neck.
	"tomas_21": {
		"sex": "m", "age": 21, "height": 192.0, "head": 0.134,
		"bust": 0.0, "belly": 0.0, "hips": 0.35,
		"skin": Color("dfb093"), "hair": Color("5a3b28"), "hair_hi": Color("7a5438"), "eyes": Color("3b2a1e"),
		"style": "shaggy", "nose": "straight", "lines": 0.0,
		"top": "denim_jacket", "top_col": Color("4f6f9a"), "top_trim": Color("3e5a80"), "tee": Color("26272b"),
		"bottom": "jeans", "bottom_col": Color("2f3b55"), "shoes": "sneakers", "shoe_col": Color("e8e6e0"),
	},
	# Tomas at 24, twelve's Tomas, who never vanished: married, a baby coming.
	# Tidy hair, a day's stubble, a sweatshirt with yellow paint on it.
	"tomas_24": {
		"sex": "m", "age": 24, "height": 192.0, "head": 0.134,
		"bust": 0.0, "belly": 0.1, "hips": 0.37,
		"skin": Color("dfb093"), "hair": Color("5a3b28"), "hair_hi": Color("7a5438"), "eyes": Color("3b2a1e"),
		"style": "side_part", "nose": "straight", "lines": 0.05, "beard": "stubble",
		"top": "sweatshirt", "top_col": Color("5f7a8c"), "top_trim": Color("4a6070"), "paint": true,
		"bottom": "jeans", "bottom_col": Color("3a4560"), "shoes": "sneakers", "shoe_col": Color("e2e0da"),
	},
	# Lise Dahl in 1991, the baby asleep against her shoulder: a high ponytail
	# in a scrunchie, big curled bangs, an oversized cream sweater, light-wash jeans.
	"lise_1991": {
		"sex": "f", "age": 24, "height": 180.0, "head": 0.137,
		"bust": 0.6, "belly": 0.0, "hips": 0.62, "pregnant": 0.0,
		"skin": Color("e8bfa4"), "hair": Color("8a6440"), "hair_hi": Color("b08a5e"), "eyes": Color("4a6a5a"),
		"lips": Color("c2706e"), "style": "high_pony", "scrunchie": Color("2a8a8a"), "nose": "button",
		"top": "sweater", "top_col": Color("e2d4b8"), "top_trim": Color("9a3a4a"),
		"bottom": "jeans", "bottom_col": Color("6a86b0"), "shoes": "sneakers", "shoe_col": Color("f0eee8"),
	},

	# --- 2009 ------------------------------------------------------------------------------
	# The Tomas who lives outside the lamp line, about forty: gaunt, bearded and
	# going grey, a beanie, an old patched parka, the lantern he carries.
	"tomas_2009": {
		"sex": "m", "age": 42, "height": 192.0, "head": 0.134, "stoop": 0.03,
		"bust": 0.0, "belly": 0.0, "hips": 0.38, "gaunt": true,
		"skin": Color("d4a688"), "hair": Color("4a3a2e"), "hair_hi": Color("a29a8e"), "eyes": Color("3b2a1e"),
		"style": "beanie", "hat_col": Color("4a3e32"), "nose": "straight", "lines": 0.55,
		"beard": "scruff", "beard_col": Color("54463a"),
		"top": "parka", "top_col": Color("4b4d3a"), "top_trim": Color("7a6a50"), "patched": true,
		"bottom": "trousers", "bottom_col": Color("38362e"), "shoes": "boots", "shoe_col": Color("2a221a"),
		"prop": "none",
	},
	# Mrs. Lund at 86, keeping the gate: white hair in a bun, the green coat
	# from 1983 (its darn darned again).
	"lund_w_2009": {
		"sex": "f", "age": 86, "height": 168.0, "head": 0.138, "stoop": 0.15,
		"bust": 0.62, "belly": 0.4, "hips": 0.72,
		"skin": Color("e8c2aa"), "hair": Color("e4e2de"), "hair_hi": Color("ffffff"), "eyes": Color("6a7a8a"),
		"lips": Color("b8807a"), "style": "bun", "nose": "button", "lines": 1.0, "glasses": true,
		"top": "long_coat", "top_col": Color("3f5a3c"), "top_trim": Color("2c4029"), "scarf": Color("8a3a48"),
		"bottom": "skirt", "bottom_col": Color("4a4038"), "skirt_len": 0.36,
		"legs_col": Color("c8a898"), "shoes": "boots", "shoe_col": Color("3a2a22"), "prop": "none",
	},
	# Mr. Lund at 88, the one she kept: white, bent over a cane.
	"lund_h_2009": {
		"sex": "m", "age": 88, "height": 184.0, "head": 0.133, "stoop": 0.17,
		"bust": 0.0, "belly": 0.6, "hips": 0.42,
		"skin": Color("e2b49a"), "hair": Color("ecebe8"), "hair_hi": Color("ffffff"), "eyes": Color("5a6672"),
		"style": "horseshoe", "nose": "broad", "lines": 1.0, "beard": "moustache", "glasses": true,
		"top": "long_coat", "top_col": Color("3a3c44"), "top_trim": Color("2a2c32"), "scarf": Color("5a6a7a"),
		"bottom": "trousers", "bottom_col": Color("4a4640"), "shoes": "boots", "shoe_col": Color("2a2420"),
		"prop": "cane",
	},

	# --- 2031 ------------------------------------------------------------------------------
	# Cal Ostrander at 83, volunteer docent: white hair combed over, glasses, a
	# cardigan over a collared shirt, the visitor center's lanyard.
	"cal_2031": {
		"sex": "m", "age": 83, "height": 186.0, "head": 0.134, "stoop": 0.12,
		"bust": 0.0, "belly": 0.45, "hips": 0.42,
		"skin": Color("dcae96"), "hair": Color("e2e0dc"), "hair_hi": Color("fbfaf8"), "eyes": Color("4a525a"),
		"style": "receding", "nose": "straight", "lines": 1.0, "beard": "moustache", "glasses": true,
		"top": "cardigan", "top_col": Color("2f4858"), "top_trim": Color("e4e0d6"), "badge": true, "badge_col": Color("c4502e"),
		"bottom": "trousers", "bottom_col": Color("6a6258"), "shoes": "flats", "shoe_col": Color("2a221c"),
	},
	# Visitors, 2031: a woman in an orange puffer with a dead phone, a man in a
	# sage hoodie with a trimmed beard.
	"visitor_a": {
		"sex": "f", "age": 34, "height": 184.0, "head": 0.136,
		"bust": 0.5, "belly": 0.0, "hips": 0.55,
		"skin": Color("c98e6c"), "hair": Color("1e1612"), "hair_hi": Color("3a2a22"), "eyes": Color("3a2a1e"),
		"lips": Color("a8605a"), "style": "bob", "nose": "straight",
		"top": "puffer", "top_col": Color("c4502e"), "top_trim": Color("2a2a2a"),
		"bottom": "trousers", "bottom_col": Color("262a32"), "shoes": "sneakers", "shoe_col": Color("eeeae2"),
		"prop": "smartphone",
	},
	"visitor_b": {
		"sex": "m", "age": 40, "height": 194.0, "head": 0.132,
		"bust": 0.0, "belly": 0.2, "hips": 0.4,
		"skin": Color("e0b090"), "hair": Color("6a4a30"), "hair_hi": Color("8a6a4a"), "eyes": Color("3a4652"),
		"style": "short", "nose": "straight", "lines": 0.25, "beard": "trim",
		"top": "hoodie", "top_col": Color("6a7a62"), "top_trim": Color("ece8de"),
		"bottom": "jeans", "bottom_col": Color("26304a"), "shoes": "sneakers", "shoe_col": Color("3a3a3a"),
	},
}


static func get_look(kind: String) -> Dictionary:
	match kind:
		"body", "silhouette":
			return ALL.mara
		"sollen_asleep":
			return ALL.sollen
		"cal_asleep":
			return ALL.cal
	return ALL.get(kind, ALL.mara)
