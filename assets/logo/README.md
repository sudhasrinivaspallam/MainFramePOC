# Logo drop-in

The demo deck (`MainFrame_Devin_Demo.pptx`) and the React screen mockups use a
pasted **Wells Fargo + Mphasis "The Next Applied"** logo. No brand assets are
fabricated or downloaded.

To brand the deck, drop the logo image here using one of these file names:

- `wells-fargo-mphasis.png`
- `logo.png`
- `wf-mphasis-logo.png`

(`.jpg` variants `wells-fargo-mphasis.jpg` / `logo.jpg` also work.)

Then regenerate the deck:

```
python3 tools/demo/gen_pptx.py
```

If no logo file is present, the generator inserts a clearly-marked
`[ LOGO ]` placeholder on the title slide, every footer, the in-slide UI
mockups, and the closing slide, and prints the exact path above.

> Brand colours used are approximations (primary red `#D71E28`, gold `#FFCD41`).
> Replace them with the official Wells Fargo brand guide values if available.
