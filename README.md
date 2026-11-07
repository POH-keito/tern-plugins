# tern-plugins

Small window plugins for [Tern](https://github.com/stencil-hq/tern-sdk). Each directory is one plugin; link the ones you want.

| plugin | what it does |
| --- | --- |
| [`board-copy-card`](board-copy-card/) | Copies the card selected on a board as the Markdown it is written in: the card line with its tags and due date, plus its indented child lines. |
| [`bookmarks`](bookmarks/) | Turns the URLs in `bookmarks.json` into palette commands that open in Tern's built-in browser, docked next to the focused pane. |
| [`keymap-dump`](keymap-dump/) | Writes this OS's **default** key bindings to `keymap-defaults/<apple\|pc>.toml`, with your own keybinds temporarily cleared so they do not leak in. |

Tested with Tern 0.9.12 on macOS.

## Install

```sh
git clone https://github.com/POH-keito/tern-plugins
tern plugin link tern-plugins/board-copy-card
tern plugin link tern-plugins/bookmarks
tern plugin link tern-plugins/keymap-dump
tern plugin list        # each one should show "ready"
```

`link` uses the directory where it is, so edit in place and run `tern plugin reload`.

## board-copy-card

Commands:

- `Board: copy card as Markdown` (`plugin.board-copy-card.copy-card`)
- `Board: open focused Markdown as board` (`plugin.board-copy-card.open-as-board`): on a Markdown file it opens the board view, elsewhere it opens a new browser block, so it can take over a key that Tern already uses for that.

Example keybinds in Tern's `settings.json` (chord to action):

```json
"keybinds": {
  "shift+cmd+c": "plugin.board-copy-card.copy-card",
  "shift+cmd+b": "plugin.board-copy-card.open-as-board"
}
```

The card is matched by title against the first top-level `- [ ]` line that contains it, so two cards with the same title copy the first one.

## bookmarks

Edit [`bookmarks/bookmarks.json`](bookmarks/bookmarks.json):

```json
[
  { "alias": "tsdk", "title": "Tern SDK", "url": "https://github.com/stencil-hq/tern-sdk" }
]
```

`alias` becomes the command id, so `plugin.bookmarks.tsdk` can be bound to a key. Run `tern plugin reload` after editing.

## keymap-dump

Run `Keymap: dump defaults` from the palette. The output lists every action, including actions with no default key, as `"action" = ["chord", ...]`, under the Tern version that produced it. Diffing two dumps shows what a Tern update changed.

If clearing your keybinds does not change the effective keymap, nothing is written and a note explains why.

## License

[MIT](LICENSE)
