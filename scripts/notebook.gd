class_name Notebook
extends RefCounted
## Mara's notebook. What she has seen and heard is kept apart from what she
## thinks it means. Entries come from story flags, so the notebook always
## agrees with the save, and it keeps what the player found even when another
## character later says otherwise.
##
## Two notes can be connected. The right pairs become a theory (flag
## "theory_<id>"). One of them, the 2:05 warning, lets Mara challenge
## Eighty-One in the kitchen.

## "a+b" (ids sorted) -> theory id.
const LINKS := {
	"board_cb+heard_214": "loop",
	"knock_hand+note_81": "knocker_81",
	"board_sketch+e81_gauze": "sketch_81",
	"gauze+knock_hand": "burned",
	"e81_signoff+voice_test": "listened",
	"signoff+signoff_wrong": "not_me",
	"day1_whistle+lund_whistle": "dad_whistle",
	"body_tape+red_tape_cal": "not_hers",
	# v0.6.2: what Dad was listening to.
	"dad_notes+museum_lambda": "dark_energy",
	"dad_bridge+tape_lind": "other_us",
	"big_rip+strips": "white_rip",
	"relay+wormhole_paper": "time_door",
}


## Everything seen and heard so far, oldest first: [{id, text}].
static func seen() -> Array:
	var g := GameState
	var out: Array = []
	var add := func(id: String, cond: bool, text: String) -> void:
		if cond:
			out.append({"id": id, "text": text})
	add.call("signoff", g.has("p1_talked"),
		"1980. What I always said when Tomas went off to listen: \"%s\" And he'd say: \"%s\"" % [Story.signoff_line(), Story.signoff_reply()])
	add.call("heard_214", g.has("heard_transmission"),
		"2:14 AM. My own voice on 2.14 MHz: \"Don't let her in.\" Every clock stopped at 2:14.")
	add.call("voice_test", g.has("voice_tested"),
		"I proved I was me to the voice with our goodbye. Said it out loud, on an open frequency.")
	add.call("boot_prints", g.has("saw_footprints"),
		"Wet prints across the lobby: my boots, my size, my cracked heel. They stop in the middle of the floor.")
	add.call("gauze", g.has("saw_gauze"), "Burn gauze on the floor where the prints stop. It smells of smoke.")
	add.call("body_tape", g.has("inspected_wrist"), "The body: blue electrical tape around the left wrist. I don't own blue tape.")
	add.call("body_watch", g.has("inspected_watch"), "The body's watch stopped at 2:14.")
	add.call("note_81", g.has("inspected_pocket"), "In her pocket, in my handwriting: THE KNOCK IS HER. SHE'LL SAY SHE'S ME. 81.")
	add.call("key_missing", g.has("inspected_transmitter"), "The transmitter's key slot is empty. Somebody took the key.")
	add.call("call_cal", g.has("called_sheriff"), "Cal, on the phone: \"I buried her Tuesday.\"")
	add.call("call_home", g.has("called_home"), "Home, on the phone. Mom: \"My daughter died in 1980.\"")
	add.call("call_office", g.has("called_observatory"), "I rang Sollen's office. Somebody picked up. My voice: \"Don't.\"")
	add.call("receiver_warm", g.has("phone_found"), "Sollen's phone was off the hook, and the receiver was still warm.")
	add.call("log_1980", g.has("read_logbook"), "Sollen's log, Oct 14, 1980, 02:14, a \"LAMBDA RUN\": the same voice on 2.14. The night Tomas vanished.")
	add.call("chalk_lambda", g.has("saw_chalk_lambda"),
		"Sollen's chalkboard: under the rubbed-out sums, a big Λ, circled, pressed in too hard to wipe off. Dad made his A's like that.")
	add.call("tape_lind", g.has("heard_cassette"), "Tomas, on Sollen's tape: \"It's not static. It's other us.\"")
	add.call("tape_day41", g.has("heard_day41"), "Tomas, Day 41: a lady on 2.14 who \"sounds like Mara\" says she's stuck in the dark.")
	add.call("knock_hand", g.has("knock_done"), "The woman at the basement door: my voice, and a bandaged left hand on the glass.")
	add.call("board_sketch", g.has("read_board"), "Cal's board, in 05: a witness sketch of an older me. Bandaged left hand. Seen on Ash St.")
	add.call("board_cb", g.has("read_board"), "Cal's board, in 05: a plow driver heard \"Don't let her in\" on his CB at 2:05.")
	add.call("e81_gauze", g.has("e81_gauze"), "Eighty-One's left hand is wrapped in burn gauze.")
	add.call("e81_claim", g.has("met_81"), "Eighty-One says the body was \"one of us who went wrong.\" Her words, not mine.")
	add.call("e81_tomas", g.has("e81_tomas"), "Eighty-One took a Tomas from 12 once. His station went quiet eleven days later.")
	add.call("e81_signoff", g.has("e81_signoff"), "Eighty-One knew our goodbye, word for word.")
	add.call("kept_signoff", g.has("kept_signoff"), "Eighty-One asked for our goodbye. I didn't tell her.")
	add.call("e81_loop", g.has("pressed_81"), "Eighty-One: \"I've sat at this table nineteen times.\"")
	add.call("tape_blue", g.has("saw_blue"), "Eighty-One told me to look at my wrist. The tape is blue.")
	add.call("dog_name", g.has("talked_ma"), "I asked Ma who's feeding Biscuit. She said Pepper's fine.")
	add.call("signoff_wrong", g.has("signoff_wrong"),
		"I told Ma we always said \"%s\" She says it was \"%s\"" % [Story.signoff_line(2), Story.signoff_line()])
	add.call("june_tuesday", g.has("told_june"),
		"June: on Tuesday a woman with my face and a bandaged hand asked her about being two places on the dial.")
	add.call("tomas12", g.has("saw_top_button") or g.has("saw_black_tape"),
		"Tomas, in 12: his coat's buttoned to the top. Mine undid it every time Ma did it up.")
	add.call("tomas_goal", g.has("tomas_goal"), "Tomas, in 12: the lady on 2.14 told him to come to the trees. He was trying to rescue her.")
	add.call("tomas_reply", g.has("tomas12_goodbye"), "Tomas, in 12, didn't know our goodbye. He answered with someone else's.")
	add.call("lund_gone", g.has("lund_gone"), "One of the Mr. Lunds went upstairs for a coat and never came back.")
	# Act 3.
	add.call("dad_diagram", g.has("chain_known"),
		"Sollen's logbook: the patch-bay routing, \"the 2.14 chain\", initialled Λ.L. 10/79. Dad's handwriting.")
	add.call("relay", g.has("patched"), "Patched in, the Tuner clicked: a relay Tomas never used. Dad's. Now the dial has a fourth digit.")
	add.call("dad_notes", g.has("dad_notes_read"),
		"Dad's LAMBDA notes, in his old textbook on Sollen's shelf: Einstein's Λ, the energy of empty space. \"It isn't the same everywhere. Here, Λ runs thin.\"")
	add.call("dad_bridge", g.has("dad_notes_read"),
		"Dad's notes: Einstein and Rosen's bridge between two sheets of space. Everett: every branch is real. Gödel's loop into the past. \"On 2.14 I can hear the next sheet over.\"")
	add.call("ruth_tape", g.has("ruth_tape"), "2031: Ma's last night at the Lantern, on tape. \"I still cut two slices.\"")
	add.call("red_tape_cal", g.has("cal_plaque"),
		"2031: Cal found \"Mara Lind\" against the console. Ma never believed it was her: \"her girl used red tape.\"")
	add.call("anders_uphill", g.has("anders_exhibit"),
		"2031: Dad was \"driving home\" in November 1979. In the photo of the wreck his car points uphill. The Air Force took his briefcase.")
	add.call("museum_lambda", g.has("museum_lambda"),
		"2031: Dad's study had an Air Force code name, LAMBDA, after Einstein's Λ: the energy of empty space. In 1998 they named it dark energy.")
	add.call("key_placard", g.has("knows_key"), "2031: the transmit key turns up in 1998, inside the hollow left rear leg of Sollen's desk.")
	add.call("future_fades", g.has("cassette_faded"), "Ma's tape faded out of my hand on the way back. Nothing comes back from a future.")
	add.call("board_dates", g.has("board_2009"), "The chalkboard: under my SILENCE: 2031, somebody wrote 2009. In my handwriting.")
	add.call("lund_whistle", g.has("lund_count"),
		"2009: Mrs. Lund asked what Dad whistled to call us in. I whistled it. \"Down, then up, dear. Close isn't the same.\"")
	add.call("padlock", g.has("tomas09_met"), "2009: the dish's main disconnect has had an Air Force padlock on it since November 1979.")
	add.call("tin_2009", g.has("knows_tin"), "2009: a biscuit tin behind the boiler, T.L. in the lid. \"I'm T.L. too. Doesn't make it mine.\"")
	add.call("big_rip", g.has("big_rip"),
		"2009, on Tomas's door: \"dark energy\", in a 1999 clipping. A printout on phantom energy's Big Rip: space pulled apart. In his writing: \"Here it's small. Here it's the white.\"")
	add.call("day1_whistle", g.has("notebook_read"),
		"Tomas, Day 1: Dad's field set, from the basement. In the lid: Λ  LIGHT = BALLAST. On 2.14, Dad's whistle: two notes, down then up.")
	add.call("day17_18", g.has("notebook_read"),
		"Tomas, Days 17 and 18: dish parked, six crossings, chart flat. Dish listening, no crossings, chart climbing.")
	add.call("oct25", g.has("saw_oct25"), "Sollen's board: the next 2.14 run is October 25.")
	add.call("strips", g.has("experiment_done"), "My own strips: flat with the dish parked, climbing while it listens. The same as his.")
	add.call("wormhole_paper", g.has("wormhole_paper"),
		"1991, Tomas's pegboard: WORMHOLES, TIME MACHINES (1988). Move one mouth of a wormhole and it's a short cut through time, if something holds it open. \"Dad's thin places push.\"")
	add.call("roll_call", g.has("roll_call"),
		"1991: Eighty-One's voice reads a list every October 14 at 2:14. \"Blue. Zero-seven. Took Red's place at Ash Street. Doesn't know.\"")
	add.call("e81_23", g.has("e81_told"),
		"Eighty-One, station 23: she pulled a Mara off the mic at 2:14 and the white went back. On the 25th it came back.")
	return out


## What Mara makes of it: [{id, text}]. Some come by themselves; the rest are
## connections the player made.
static func theories() -> Array:
	var g := GameState
	var out: Array = []
	if g.has("body_done"):
		out.append({"id": "me", "text": "The body is me. Or a me. She wore blue tape, so she isn't from here."})
	if g.has("heard_day41"):
		out.append({"id": "crossing", "text": "Tomas wasn't lost. He was crossing on purpose, for weeks, looking for someone."})
	if g.has("experiment_done"):
		out.append({"id": "listening", "text": "It isn't the crossings that bring the Silence. It's the dish, listening on 2.14. Tomas proved it in 1980. I just did it again."})
	if g.has("roll_call"):
		out.append({"id": "blue", "text": "I'm the blue one. From 07. I took Red's place at Ash Street, and I didn't know."})
	for id in LINKS.values():
		if g.has("theory_" + id):
			out.append({"id": id, "text": theory_text(id)})
	return out


static func theory_text(id: String) -> String:
	match id:
		"loop":
			return "The warning was heard nine minutes before it was sent. Either someone knew it was coming, or tonight has happened before. Ask Eighty-One."
		"knocker_81":
			return "THE KNOCK IS HER... 81. The woman at the basement door is the 81 in the note."
		"sketch_81":
			return "Cal's suspect is Eighty-One: an older me with a burned left hand, seen on Ash Street."
		"burned":
			return "Whoever knocked came in wearing my boots and dropped burn gauze. The knocker has a burned hand."
		"listened":
			return "I said our goodbye on an open band and Eighty-One knew it. She was listening. Anyone could have been."
		"not_me":
			return "The notebook says \"%s\" I'd swear it was \"%s\" Since the kitchen I remember a life that isn't quite mine." % [
				Story.signoff_line(), Story.signoff_line(2)]
		"dad_whistle":
			return "Mrs. Lund says Dad whistled down, then up. So does Tomas's notebook. I whistled it the other way. Whose father taught me?"
		"not_hers":
			return "Ma never believed the body was me: her girl used red tape. The body wore blue. So do I."
		"dark_energy":
			return "Dad's Λ and the museum's are the same thing: the energy of empty space. In 1998 they named it dark energy. He was measuring it here twenty years before it had a name, and the dish hears it on 2.14."
		"other_us":
			return "\"It's not static. It's other us.\" Dad wrote it first: every branch is real, and on 2.14 you can hear the next sheet over. The frequencies are the branches, parallel Halvards side by side. The dark is where they touch."
		"white_rip":
			return "The white is a Big Rip, a small one over one town: space pulled apart until light and sound can't cross it. My strips climb while the dish listens. The dish is what's pulling."
		"time_door":
			return "Tomas's paper says a wormhole can reach through time if something holds it open. Dad's thin places hold it open, and his relay made the dial read years. He found the way through and wired it into a radio."
	return ""


## Connect two notes. Returns the new theory's id, "known" if Mara already
## worked it out, or "" if the two notes don't connect.
static func connect_notes(a: String, b: String) -> String:
	var key := "%s+%s" % ([a, b] if a < b else [b, a])
	if not LINKS.has(key):
		return ""
	var id: String = LINKS[key]
	if GameState.has("theory_" + id):
		return "known"
	GameState.set_flag("theory_" + id)
	return id


static func count() -> int:
	return seen().size() + theories().size()
