# v0.7.0 validation

Godot 4.6.3, 13 November 2026, after the last change. Every run below passed.

| Run | Result |
|---|---|
| `--check` | every room script compiles |
| `--autotest=answer` (answer the voice, take Tomas, trust June, ask about his life, cut Red's channel) | PASS, 209 checks |
| `--autotest=cut` (cut the power, leave Tomas, trust June, ask him to come, keep the channel) | PASS, 215 checks |
| `--autotest=answer_leave` (answer, leave Tomas, radio check only, ask about his life, keep the channel) | PASS, 213 checks |
| `--autotest=cut_take` (cut, take Tomas, radio check only, ask him to come, cut the channel) | PASS, 210 checks |
| `--autotest=act3_answer`, `act3_cut`, `act3_answer_leave`, `act3_cut_take` (Act 3 from chapter 3.1) | PASS, 65, 66, 65 and 65 checks |
| `--autotest=chapters` (every chapter, every choice combination, regenerated from the four playthroughs above) | PASS, 302 checks |
| `--autotest=layout` | PASS, 154 checks |
| `--autotest=continue` | PASS, 31 checks |
| `--autotest=atmosphere` | PASS, 30 checks |
| `--autotest=act3_answer_leave --shots`, `--autotest=eras --shots`, and the opening to Act 2 of `--autotest=answer --shots` | looked at, 1280x720, OpenGL under Xvfb |

What the playthroughs now check, beyond reaching the end:

- **Prologue and Act 1:** the goodbye pairs (including *Save my place*), the fuse label, every clock at 2:14 when the headphones go on, the chart strip on the answer path only, the pencilled H in the garage.
- **Act 2:** the 2:05 question appears once Mara has read Cal's board; on the answer path Eighty-One knows the goodbye and Mara asks what she did, with nothing on screen naming the tape; the swap turns the tape blue in her pocket and on her wrist; at the diner the only spoken mismatch is the dog, and nobody corrects the goodbye; June's door sets `JUNE` to trusted or check on both Tomas paths, and the PEPPER / BISCUIT card only when trusted; Mrs. Lund is alone only after June's door.
- **Act 3:** the margin note on Dad's chain; the four 2031 exhibits (the foot cap drawn, Cal's signature, the cuff) and the notebook entry about what fades; Henrik's scrap with the key; Mrs. Lund's rope stops you reaching Tomas until she lifts it; the coupling scene ends in the Silence; 2009 written by Mara herself; the tin (Day 42, the service card); Ruth's reunion (take) or the empty stool (send back), and the boy asking to go home only on the take path; HELD HERE, then the screwdriver out and 1991; `LETGO`; June's roster sets the name BLUE; the 07 cupboard hands control to Red with empty pockets; the ? button names the right sound at each of Red's turnings; the chart strip in Red's notebook only if she answered in 1.1; Blue's own set back, the photograph, the confession, the pistol out of reach; Choice 3 (`EIGHTY` cut: lead pulled and the dish wedged in PARK; keep: AUTO running and the white takes the corner); three knocks; the end card.
- **Notebook:** twelve theories to find; the playthroughs connect *loop*, *burned*, *other us*, *dark energy*, *not hers*, *same room*, *meant to open*, *words ahead* and *the whistle*, and check they last to the end.

The engine prints "Lambda capture at index 0 was freed" during Act 3 room changes (39 to 43 times per run, fewer than v0.6.2's 51). It doesn't affect play.

Period references in the new scenes follow the script's own list: the U.S. digital television switch on 12 June 2009, the first anniversary of German reunification (3 October 1991), and DESI's 2025 results on the 2031 panel, which now uses the script's more careful wording.
