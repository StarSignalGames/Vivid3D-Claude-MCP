---
name: cinematic-checks
description: Visual QA (offered to the user, run on their yes) right after you create or change a Vivid3D cinematic (.cine). Captures one screenshot per 0.5 s of the whole cinematic and studies every frame for colour clashes, unreadable or invisible text, wrong framing, missing objects and popping. Also holds the keyframe-easing guide (hold/step/ease in/out/expo: choose per segment creatively) to read BEFORE writing any cinematic's keyframes. The visual check itself applies only when you have just created or edited a cinematic in this conversation.
---

# Cinematic checks

**When (visual check):** only right after you created or edited a `.cine` in this conversation (and the file passed `asset_validate`). Do not run it for cinematics you merely read, ran for the user, or did not touch.

**Why:** a valid file is not a good cinematic. Typical silent failures: text the same colour as what is behind it, a screen-colour fade that hides everything, a camera pointing at nothing, a node snapping to the wrong scale, a post-process colour wash. You only find these by looking.

## Choosing easing creatively (do this when WRITING the cinematic, and check it in the frames)
Every keyframe's `Easing` (a number) shapes the segment from THAT key to the NEXT one. Never default every key to one curve (e.g. all EaseInOutSine): that makes the camera stop and restart at every key, which looks mechanical. Pick per segment, by what the motion should feel like:
| number | name | feel / use |
|---|---|---|
| 0 | Linear | constant speed: continuous flowing moves (orbits, spins, tracking shots, scrolling), the middle of a multi-key move so speed does not dip at each key |
| 1 / 4 | EaseInQuad / EaseInCubic | starts slow, ends fast: something launching, a push-in building toward an impact, falling, accelerating into a cut |
| 2 / 5 | EaseOutQuad / EaseOutCubic | starts fast, settles gently: arriving at a hero shot, a camera landing on its subject, an object coming to rest |
| 3 / 6 | EaseInOutQuad / EaseInOutCubic | soft start and soft stop: a single deliberate move between two held poses; Cubic is stronger than Quad |
| 7 / 8 / 9 | EaseIn / EaseOut / EaseInOut Sine | the gentlest curves: slow drifts, floating/bobbing, breathing scale pulses, lazy cranes |
| 10 / 11 / 12 | EaseIn / EaseOut / EaseInOut Expo | very dramatic: a whip pan, a sudden snap-zoom, a slam-in (Out) after a long quiet build (In) |
| 13 | Step | keep this pose until the next key time, then CUT instantly: hard cuts between camera positions, popping props, on/off |
| 14 | Hold | same cut behaviour as Step; use it to say "stay here" (a deliberate pause: put a Hold key, then the next key) |
Guidelines:
- **Think in shots.** Each camera segment has an intent (reveal, push in, pull back, orbit, whip, settle). Choose the curve from that intent, and vary it across the cinematic.
- **Chain keys so speed stays continuous.** For a move through several keys, use Linear (or the same In/Out family arranged so the outgoing curve of one key matches the incoming speed of the next); use an Out curve on the LAST segment into a stop and an In curve on the FIRST segment out of a hold. An EaseInOut on every segment creates a pause at every key.
- **Holds make beats.** To linger on a pose, add two keys with the same value (or a Hold/Step key) so the camera/object visibly rests, e.g. before a title lands or a flash.
- **Cuts:** to jump to another angle, put Step/Hold on the key BEFORE the cut and a new key at the cut time with the new pose (two keys 0.01 s apart also works with Linear). Keep a cut on a beat (text change, flash, marker).
- **Objects, not only the camera:** props that spin use Linear; a bob/float uses Sine InOut; a pulse that hits on a beat uses Expo Out then Sine In/Out back; an object that drops uses EaseIn (gravity), settles with EaseOut.
- **Other tracks too:** `screencolor` fades: Linear (or EaseInOutSine for softer), a flash: Expo Out / Step; text keyframes always use Step (13) because their own fade-in/hold/fade-out is built in.
- **Rotation caveat:** easing applies to the whole pose of that key pair; keep quaternion hemisphere continuity and monotonic yaw (see data-assets.md) or rotations will spin the long way regardless of easing.
- **Verify by looking:** in `cinematic_frames` output, equal 0.5 s steps show speed: evenly spaced positions = Linear; bunching near a key = ease in/out. If a move stalls at a key where it should flow, change that key's easing and re-check.
- **Say what you chose.** When you report the cinematic, list the creative choices ("whip-pan at 7.4 s: Expo In, then cut on the flash; slow Sine crane 8-10 s").

## Ask first
Never start the check silently. When you have just created or edited a cinematic, finish the file and `asset_validate` it, then **ask the user** (AskUserQuestion, or one plain question) whether they want you to inspect it this way, and say what it involves: the editor enters play mode, scrubs the cinematic and takes about 30 screenshots (roughly a minute), then stops play. Offer two answers: "Yes, inspect it" / "No, I'll look myself". Only on a clear yes run the procedure below. On no, hand the cinematic over (what you made, its path, how to play it) and stop. If the user has already said in this conversation to always check cinematics, you may skip the question.

## Procedure
1. `asset_validate` the `.cine` first and fix every error. Make sure the scene it uses is open (`project_info`, `scene_io load` if needed) and not in an unsaved half-built state you would lose.
2. Call **`cinematic_frames {path:"content/cines/X.cine"}`**. Defaults: one frame every **0.5 s** from 0 to the end, 640 px wide, the Scene View only. It starts play mode itself, scrubs the cinematic to each time (camera, node poses, text, screen colour, post-process all applied), captures, and returns every image labelled `t = N.NNs`.
   - Long cinematics: the cap is 60 frames per call. Split with `start`/`end` (e.g. 0-29.5, then 30-59.5), keep `step` 0.5.
   - Need detail on a suspicious spot: call again with `start`, `end`, a smaller `step` (min 0.1) and `maxWidth` 1000+.
3. **Look at EVERY image, one by one.** Do not skim or sample. Keep a short note per frame or per range of frames. Check each item below.
4. `play stop` when done (scene edits are refused while playing).
5. If anything is wrong: fix the **`.cine` file** (not the UI), `asset_validate`, and run the check again on the affected time range. Repeat until every frame is acceptable. Then tell the user what you checked (frame count, time range) and what you fixed. If you could not fix something, say exactly which times and why.

## What to check in each frame
**Text tracks (most important).** For every `text` track keyframe period, find the text in the frames and confirm it is actually readable:
- It is **visible at all** during its time range (not missing, not fully faded, not off-screen, not clipped).
- **Contrast against what is behind it.** Light text over a bright wall/sky/floor, or dark text over a dark scene, is invisible. Check the frame behind the text, not the text colour in isolation: the background changes as the camera moves, so check the start, middle and end of each title. A pale floor behind white text is the classic failure.
- Also a `screencolor` overlay on the same time range: text under a full-opacity fade layer, or the same colour as the fade, disappears.
- Fix options: change the text colour to contrast with the actual background; move the text (`Position`); add a dark/light backing (a `screencolor` track with low alpha under it is *below* the text only if track order allows: verify in the frames); change the camera angle; lengthen the fade-in so the text is solid while readable.
- Fades: text should be fully opaque for most of its duration, and its fade in/out must not be so long that it is never solid.

**Known traps found by this check.**
- Text fade types **Blur** (1) and **CyberGlitch** (2) can render the whole frame solid white in these captures while the fade is running. If every frame during a text's fade-in/out is white, switch that text to **Smooth** (0) in the file, re-check, and tell the user.
- A black `screencolor` fade at partial alpha can look milky grey over the black sky instead of darker. Judge fades by whether they reach full black/clear at the planned times.
- A camera keyframe path that passes straight through a hero object puts the lens inside it: when a frame is filled by one object, move that keyframe out and aim it at the object from a distance.
- Titles too small to read: check the Font Size is reasonable (pixel size at 1080p; 100-170 for big titles). Sizes scale with the viewport height, and the scene view is much smaller than the final screen.
- Moving lights are fine, but check frames after any light/exposure change: a point light swung in front of the camera can blow a frame out.

**Colours.** Fades and overlays (`screencolor`) do not wash out or blacken the scene unintentionally; fade-to-black really reaches the intended colour at the intended time and comes back; post-process tracks do not tint everything; no clipping to pure white or crushed black; colours of consecutive frames change smoothly, not in jumps unless it is a deliberate cut.

**Camera and framing.** The subject is in frame when it matters; the camera is not inside geometry, looking at the sky/void, or upside down; moves are smooth (no sudden flip at a rotation wrap, see data-assets.md quaternion/Euler notes); the camera that should be active is the one rendering (`ActivateCamera`).

**Scene content.** Objects the cinematic animates are present and the right size (node3d keyframe `Scale` replaces node scale: a thing suddenly huge/tiny/missing means wrong keyframe scale); nothing flickers, pops or teleports unintentionally; lighting and shadows still look right from the cinematic camera (see lighting.md / shadows.md).

**Timing.** Things happen at the intended times (titles appear when planned, the cut/fade lands where expected); the last frame is a deliberate end state (not an accidental black or a mid-move).

## Report format
Briefly list: frames checked, problems found (time + what + fix), final result. Be honest about frames you could not judge. Never say "looks fine" without having looked at every returned image.

## Limits of the check
Frames are scrubbed, not real time playback: motion speed, audio, narration and video tracks are not judged. Particle one-shots and event-fired effects may not appear when scrubbing. Check those separately with real playback (`play start`, `run_event`, `screenshot`) if they matter.
