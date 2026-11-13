# Current WebP images

The user supplied these six original static WebP illustrations. All are mapped
in lib/models/exercise_media.dart and bundled by the existing directory entry
in pubspec.yaml. No original asset has been deleted or altered.

- bodyweight_squats.webp: Bodyweight Squats
- wall_push_ups.webp: Wall Push-ups
- glute_bridges.webp: Glute Bridges
- bird_dogs.webp: Bird Dogs
- standing_calf_raises.webp: Standing Calf Raises
- plank.webp: Plank

See README.txt for the supplied image notes. These are static visual aids, not
GIFs. Unsupported exercises retain the offline fallback. Category cards rotate
among matching images from each day's exercise list.

The GIF research below is retained as historical documentation only. Its missing
GIF paths are no longer used by the application.

---

﻿# Exercise GIF assets

No GIF files were successfully added in this setup pass.

The Flutter asset directory is registered and the reusable mapping lives in
`lib/models/exercise_gifs.dart`. Active workouts use `ExerciseGif`, which checks
both verified license metadata and the actual bundle manifest before attempting
to load an image. Missing, unknown, unlicensed, corrupt, or failed assets use the
same offline fallback. No runtime network request is made for demonstrations.

| Exercise | Expected filename | Current status |
| --- | --- | --- |
| Bodyweight Squats | bodyweight_squats.gif | Reuse license verified; download blocked by HTTP 429 twice |
| Wall Push-ups | wall_push_ups.gif | No suitable reusable GIF verified/downloaded |
| Glute Bridges | glute_bridges.gif | No suitable reusable GIF verified/downloaded |
| Bird Dogs | bird_dogs.gif | No suitable reusable GIF verified/downloaded |
| Standing Calf Raises | standing_calf_raises.gif | No suitable reusable animated GIF verified/downloaded |

## Verified candidate, not included

- Original title: Squats.gif
- Creator: Wensceslao (uploader identifies it as own work)
- Source: https://commons.wikimedia.org/wiki/File:Squats.gif
- Stable source revision: https://commons.wikimedia.org/w/index.php?title=File:Squats.gif&oldid=698458529
- Original binary URL: https://upload.wikimedia.org/wikipedia/commons/e/e6/Squats.gif
- License: Creative Commons Attribution-ShareAlike 4.0 International
- License URL: https://creativecommons.org/licenses/by-sa/4.0/
- Source describes a 640×480, 66-frame animated bodyweight squat GIF.
- Both download attempts returned HTTP 429. No error HTML was stored as a GIF.
- Because no local file was obtained, its frames could not be inspected locally.
- The existing metadata enables attribution in-app if an unmodified, inspected
  copy of this exact licensed GIF is later bundled. Keep its attribution/license;
  record changes and respect share-alike when adapting the image.

## Other sources reviewed and not copied

- TrainAI exercise-media: https://www.trainaiapp.com/exercise-media/
  Offers downloads for TrainAI content, but a suitable app-bundling reuse license
  was not verified. No TrainAI media was downloaded.
- IconScout/LottieFiles wall push-up assets: premium/export requirements; no
  licensed GIF entitlement was obtained. No previews copied.
- Wikimedia Standing-calf-raises-1.gif:
  https://commons.wikimedia.org/wiki/File:Standing-calf-raises-1.gif
  A .gif extension alone does not establish an animated full exercise demo.
  It was not used as a substitute for a verified bodyweight animation.
- CrossFitOS glute bridge and bird dog pages explicitly license their clips
  CC BY-SA 4.0, but the supplied clips are MP4 rather than GIF. No conversion or
  invented animation was substituted:
  https://crossfitos.com/exercises/glute-bridge
  https://crossfitos.com/exercises/bird-dog

To add a missing asset later: verify its creator and license, inspect its movement,
copy it under the expected filename, add its credit/source/license metadata to
the mapping, document it here, then run pub get and rebuild. Do not simply rename
a video, still image, or download error page to .gif.
