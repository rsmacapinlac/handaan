# handaan's wallpapers

The curated set the wallpaper picker offers alongside your own. It is empty until an image that may be redistributed is found: this tree is public, and a wallpaper here is handed to everyone who clones it.

Your own wallpapers go in `~/.config/handaan/wallpapers/`, from your dotfiles. Anything is fine there, because nothing there is published.

## Every image carries a credit

Beside each image is a sidecar with the same name plus `.credit`:

```
sunset-lake.jpg
sunset-lake.jpg.credit
```

```
# One field per line. Comments and blank lines are ignored.
title:   Sunset Lake
artist:  Jane Doe
via:     Wikimedia Commons
source:  https://commons.wikimedia.org/wiki/File:Sunset_Lake.jpg
license: CC0-1.0
```

`artist`, `source` and `license` are required. `title` is optional, and so is `via`, the publisher or collection it came through when that is not the artist -- a magazine's wallpaper post, say. The picker shows the credit for the wallpaper under the cursor.

`license` must allow redistribution without conditions beyond credit, written as an SPDX identifier:

| license | what it asks |
|---|---|
| `CC0-1.0`, `public-domain` | nothing |
| `CC-BY-4.0`, `CC-BY-3.0`, `CC-BY-2.0` | credit, which the sidecar is |
| `CC-BY-SA-4.0`, `CC-BY-SA-3.0`, `CC-BY-SA-2.0` | credit, and the image stays under the same licence |

Not allowed: anything non-commercial (`NC`) or no-derivatives (`ND`), because they conflict with the MIT licence handaan hands to anyone who forks it; Unsplash, Pexels and Pixabay, whose licences restrict redistributing their photos as a collection; and anything with no licence at all, which is most of what wallpaper sites carry. A credit does not make an image shareable -- only its licence does.

`test/wallpaper-credits.sh` fails on an image here without a valid credit, or a credit without an image. Run it before committing a wallpaper.
