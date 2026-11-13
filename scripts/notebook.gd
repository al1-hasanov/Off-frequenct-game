class_name Notebook
extends RefCounted
## Mara's notebook. What she has seen and heard is kept apart from what she
## thinks it means. Entries come from story flags, so the notebook always
## agrees with the save, and it keeps what the player found even when another
## character later says otherwise.
##
## Two notes can be connected. The right pairs become a theory (flag
## "theory_<id>"). The notebook never states a truth the script keeps open:
## who first said "Hold it still", whether the echo chooses, what 00 is.

## "a+b" (ids sorted) -> theory id.
const LINKS := {
	"board_cb+heard_214": "loop",
	"knock_hand+note_81": "knocker_81",
	"board_sketch+e81_gauze": "sketch_81",
	"gauze+knock_hand": "burned",
	"e81_signoff+voice_test": "listened",
	"body_tape+red_tape_cal": "not_hers",
	"signature+transcript": "same_room",
	"fuse_label+service_card": "meant_to_open",
	"early_phrase+hold_it_still": "words_ahead",
	"ruth_whistle+tomas_whistle": "the_whistle",
	# What Dad was listening to.
	"dad_notes+museum_lambda": "dark_energy",
	"dad_bridge+tape_lind": "other_us",
}


## Everything seen and heard so far, oldest first: [{id, text}].
static func seen() -> Array:
	var g := GameState
	var out: Array = []
	var add := func(id: String, cond: bool, text: String) -> void:
		if cond:
			out.append({"id": id, "text": text})
	add.call("ruth_whistle", g.has("ruth_whistle"),
		"1980. Mom whistled us out of the diner: two notes, down, then up. \"Your father could call you in from three streets away.\"")
	add.call("early_phrase", g.has("early_phrase"),
		"1980. Three words in Tomas's headphones, then I said \"Hold it still.\" He said I already had.")
	add.call("signoff", g.has("p1_talked"),
		"1980. What I always said when Tomas went off to listen: \"%s\" And he'd say: \"%s\"" % [Story.signoff_line(), Story.signoff_reply()])
	add.call("fuse_label", g.has("fuse_label"),
		"Behind Sollen's note, Dad's old label on receiver 2: 5 A FAST. ENABLE LINK. DO NOT UPRATE. 1979.")
	add.call("heard_214", g.has("heard_transmission"),
		"2:14 AM. My own voice on 2.14 MHz: \"Don't let her in.\" Every clock stopped at 2:14.")
	add.call("signature", g.has("heard_signature"),
		"Under the voice: a chair foot dragging, two relay clicks, a clipped breath. The same places, every time round.")
	add.call("voice_test", g.has("voice_tested"),
		"I proved I was me to the voice with our goodbye. Said it out loud, on an open frequency.")
	add.call("strip_1983", g.has("strip_1983"),
		"The chart strip, folded in my work notebook: the trace stepped up under each burst of speech, and didn't come back down.")
	add.call("boot_prints", g.has("saw_footprints"),
		"Wet prints across the lobby: my boots, my size, my cracked heel. They stop in the middle of the floor.")
	add.call("gauze", g.has("saw_gauze"), "Burn gauze on the floor where the prints stop. It smells of smoke.")
	add.call("body_tape", g.has("inspected_wrist"), "The body: blue electrical tape around the left wrist. I don't own blue tape.")
	add.call("body_watch", g.has("inspected_watch"), "The body's watch stopped at 2:14. Mine shivers on the same mark. The clocks, not us.")
	add.call("body_arm", g.has("inspected_arm"), "The body's arm is stretched out along the floor, toward the microphone stand.")
	add.call("note_81", g.has("inspected_pocket"), "In her pocket, in my handwriting: THE KNOCK IS HER. SHE'LL SAY SHE'S ME. 81.")
	add.call("key_missing", g.has("inspected_transmitter"), "The transmitter's key slot is empty. Somebody took the key.")
	add.call("folded_wires", g.has("junction_open"),
		"The lobby phone pair was cut clean and folded back so the ends couldn't touch. Somebody who knows how I'd fix it.")
	add.call("call_cal", g.has("called_sheriff"), "Cal, on the phone: \"I buried her Tuesday.\"")
	add.call("call_home", g.has("called_home"), "Home, on the phone. Mom: \"My daughter died in 1980.\"")
	add.call("call_office", g.has("called_observatory"), "I rang Sollen's office. Somebody picked up. My voice: \"Don't.\"")
	add.call("receiver_warm", g.has("phone_found"), "Sollen's phone was off the hook, and the receiver was still warm.")
	add.call("obs_corridor", g.has("obs_corridor"), "My notebook: dark corridor changed. Lamp on: no change. Try again only with a way back. WHY?")
	add.call("log_1980", g.has("read_logbook"), "Sollen's log, Oct 14, 1980, 02:14, a \"LAMBDA RUN\": the same voice on 2.14. The night Tomas vanished.")
	add.call("chalk_lambda", g.has("saw_chalk_lambda"),
		"Sollen's chalkboard: under the rubbed-out sums, a big Λ, circled, pressed in too hard to wipe off. Dad made his A's like that.")
	add.call("tape_lind", g.has("heard_cassette"),
		"Tomas, on Sollen's tape: six steps to the shelf, then eight. Dad's lamp stopped it changing. \"A voice can answer you and still not be talking to you.\"")
	add.call("tape_day41", g.has("heard_day41"),
		"Tomas, Day 41: a lady on 2.14 who sounds like Mara says she's stuck in the dark. \"There's a breath before she says my name.\"")
	add.call("knock_hand", g.has("knock_done"), "The woman at the basement door: my voice, through the frosted glass. She knew about his radio.")
	add.call("pencil_h", g.has("pencil_h"), "The garage: the hum between six and seven is the one I'm standing in. I pencilled H under the strap.")
	add.call("stencil", g.has("saw_stencil"), "Under Tomas's HOME = 00, an older stencil on the case. A word, then two zeros. He copied it.")
	add.call("lund_darn", g.has("lund_darn"),
		"Two Mr. Lunds, one coat with a green darn. One says she darned it after the fishing trip. The other says before.")
	add.call("bell_note", g.has("bell_note"), "St. Olaf's clapper moved once in the wind, and a radio lost one note of its song in the same instant.")
	add.call("june_tape", g.has("june_tape_test"),
		"June's bench: the warning is a tape, the same breath every time. Under it, somebody live, trying to get a word in.")
	add.call("week_ahead", g.has("saw_week_ahead"), "Cal's office in 05 is a week ahead: Friday the 21st. The funeral notice says Tuesday.")
	add.call("board_sketch", g.has("read_board"), "Cal's board, in 05: a witness sketch of an older me. Bandaged left hand. Seen on Ash St.")
	add.call("board_cb", g.has("read_board"), "Cal's board, in 05: a plow driver heard \"Don't let her in\" on his CB at 2:05.")
	add.call("e81_gauze", g.has("e81_gauze"), "Eighty-One's left hand is wrapped in burn gauze. A tally counter taped to her radio.")
	add.call("e81_claim", g.has("met_81"), "Eighty-One, about the body: \"I know.\" Who did it? \"I saw what came after.\"")
	add.call("e81_tomas", g.has("e81_tomas"),
		"Eighty-One brought a Tomas home from 12. Eleven days. The white came back while she was in the cellar and he was in the kitchen with the light on.")
	add.call("e81_signoff", g.has("e81_signoff"), "Eighty-One knew our goodbye, word for word. \"A password stops being a password when you give it to the room.\"")
	add.call("kept_signoff", g.has("kept_signoff"), "Eighty-One asked for our goodbye. I didn't tell her.")
	add.call("e81_loop", g.has("pressed_81"), "Eighty-One: \"I've sat at this table nineteen times.\"")
	add.call("dog_name", g.has("dog_wrong"), "I asked Ma who's feeding Biscuit. She said Pepper's fine.")
	add.call("june_card", g.has("june_card"), "June's card on her receiver: PEPPER / BISCUIT / ASH STREET. She'll ask which dog.")
	add.call("tomas12", g.has("saw_top_button"),
		"Tomas, in 12: his coat's buttoned to the top. Mine never kept it done up for a second.")
	add.call("tomas_goal", g.has("tomas_goal"), "Tomas, in 12: the lady on 2.14 told him to come to the trees. He was trying to rescue her.")
	add.call("lund_gone", g.has("lund_gone"),
		"One of the Mr. Lunds went upstairs for a coat. When the dish stopped, a radio on a windowsill played clean, every note.")
	# Act 3.
	add.call("dad_diagram", g.has("chain_known"),
		"Dad's 2.14 chain, initialled Λ.L. 10/79. In the margin: \"Enable link: 5 A fast. It is meant to open. Park the drive BEFORE you replace it.\"")
	add.call("relay", g.has("patched"), "Patched in, the Tuner clicked: a relay Tomas never used. Dad's. Now the dial has a fourth digit.")
	add.call("dad_notes", g.has("dad_notes_read"),
		"Dad's LAMBDA notes: Einstein's Λ can act like energy belonging to empty space itself. \"It isn't the same everywhere. Here, Λ runs thin.\"")
	add.call("dad_bridge", g.has("dad_notes_read"),
		"Dad's notes: Einstein and Rosen's bridge. Everett's relative states. Gödel's paths that come back to their own past. \"On 2.14 I can hear the next sheet over.\"")
	add.call("ruth_tape", g.has("ruth_tape"), "2031: Ma's last night at the Lantern, on tape. \"I still cut two slices.\"")
	add.call("transcript", g.has("transcript_seen"),
		"2031: the museum's listening button. A chair scrapes, two relay clicks, the clipped breath. A photo of a fallen chair by the console.")
	add.call("red_tape_cal", g.has("cal_plaque"),
		"2031: Cal found \"Mara Lind\" by the console. Ma never believed it was her: \"her girl used red tape.\"")
	add.call("anders_uphill", g.has("anders_exhibit"),
		"2031: Dad was \"driving home\" in 1979, but the wreck points uphill. Cal signed the time under a sentence he hadn't written.")
	add.call("museum_lambda", g.has("museum_lambda"),
		"2031: Dad's study had an Air Force code name, LAMBDA, after Einstein's Λ. In 1998 the unknown cause of the speeding-up universe was named dark energy. Nobody yet knows what it is.")
	add.call("key_placard", g.has("knows_key"), "2031: the transmit key turns up in 1998, inside the hollow left rear leg of Sollen's desk. I drew the foot cap.")
	add.call("note_futures", g.has("note_futures"),
		"The numbered stations let me bring things across. A thing from one of the dish's years faded when I left. Don't count on a person from there staying either.")
	add.call("lost_safer", g.has("key_taken"), "In the desk leg, with the key: \"H.S. — Lost is safer than available.\" Henrik hid it himself.")
	add.call("board_dates", g.has("board_2009"), "The chalkboard: under my SILENCE: 2031, somebody wrote 2009. In my handwriting.")
	add.call("coupling", g.has("coupling_drawn"),
		"2009, the coupling under the dish: park it, pull it clear, latch it. In that order. The pawl's worn smooth.")
	add.call("tomas_whistle", g.has("coupling_drawn"),
		"2009: Tomas left the coupling out every night, listening. \"Once it was Dad. The whistle. Down, then up.\"")
	add.call("day42", g.has("tin_open"),
		"Tomas, Day 42: \"The lady says the big dish can hear me even when this set is off.\" His drawing: every station's arrow through the dish.")
	add.call("service_card", g.has("tin_open"),
		"Dad's service card, October 1979: LEFT OPEN ON PURPOSE. PARK BEFORE RESTORING. Sollen, under it: \"Programme requires an uninterrupted sample.\"")
	add.call("hold_it_still", g.has("hold_it_still"), "A page torn out of Tomas's notebook. Pressed into the sheet underneath: HOLD IT STILL.")
	add.call("held_here", g.has("held_here"), "The chart: PARK, and the pen levels. AUTO, and it climbs. HELD HERE.")
	add.call("oct25", g.has("saw_oct25"), "Sollen's board: the next 2.14 run is October 25.")
	add.call("roster", g.has("named_blue"),
		"June's 1983 roster: H — PEPPER — MOM. 07 — BISCUIT — MA. \"After Ash Street, H's set answered as 07. She didn't know.\"")
	add.call("red_h", g.has("named_blue"), "A red pencil H under the strap of the set in my hands. I didn't write it.")
	add.call("photo", g.has("saw_photo"), "In the dead woman's coat, my photograph. On the back, my writing: MA IS STILL THERE. GO BACK FOR THE OTHER ONE.")
	add.call("e81_confession", g.has("e81_confessed"),
		"Eighty-One shot her. Cut the lobby pair. Picked up Sollen's phone and said \"Don't.\" She put Red in the dark so she'd know where the caller was.")
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
	if g.has("held_here"):
		out.append({"id": "listening", "text": "It's the listening. Parked, the pen holds flat. On AUTO it climbs. Dad left the link open on purpose, and I kept putting it back."})
	if g.has("named_blue"):
		out.append({"id": "blue", "text": "I'm from 07. Biscuit, Ma, and my own goodbye. Since Ash Street I've been carrying someone else's set."})
	if g.has("red_knows"):
		out.append({"id": "caller", "text": "Red: the lady on 2.14, the one who told him to come to the trees, was me. Somebody cut the ends off what I said."})
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
		"not_hers":
			return "Ma never believed the body was me: her girl used red tape. The body wore blue."
		"same_room":
			return "The chair, the two relay clicks, the breath: the museum keeps the same sounds that run under the warning. It was recorded in our control room, by the console."
		"meant_to_open":
			return "Dad's label says DO NOT UPRATE. His card says LEFT OPEN ON PURPOSE. The fuse I keep replacing is the enable link. It was meant to open."
		"words_ahead":
			return "Tomas heard \"Hold it still\" before I said it. His torn page says HOLD IT STILL. Words are getting through ahead of the people who say them. Who said them first, I don't know."
		"the_whistle":
			return "Ma's two notes, down then up. Dad's, from the bottom of the garden. Tomas left the dish listening for them for twenty-six years. A sound that makes a Lind follow it."
		"dark_energy":
			return "Dad's Λ and the museum's are the same symbol: Einstein's constant, energy that belongs to empty space. In 1998 the cause of the speeding-up universe got the name dark energy. Nobody knows what it is. Dad thought he was listening to it."
		"other_us":
			return "Dad: on 2.14 I can hear the next sheet over. Tomas: a voice can answer you and still not be talking to you. Whoever answers on 2.14 might be another Halvard's, not ours."
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
