# Vimium fork for Slack

([Original readme](./ORIGINAL_README.md))

To "fix" a bug with Vimium + Slack. This is not the right way of fixing this
bug.

**The bug:**
- Open Slack in browser with Vimium installed.
- Press cmd-k (on Mac) to open the channel/DM/etc search.
- Press esc to try to close the search.
  - Expected behavior: The search will close (as it does without Vimium)
  - Actual behavior: The search does not close

**The fix:** (739211d) When handling an esc press in insert mode, if the
active element seems to be the search box, use Vimium's `@continueBubbling`.

```diff
  class InsertMode extends Mode
    constructor: (options = {}) ->
      ...
      handleKeyEvent = (event) =>
        ...
        else if event.type == 'keydown' and KeyboardUtils.isEscape(event)
+         # ql-editor is a class shared by both the 'type a message' box and the 'find a channel/dm/etc' box
+         # we only want to continue bubbling for the latter. for the former, we want vimium to unfocus the
+         # box so that the user can activate link hints mode with f (or whatever key)
+         if activeElement.classList.contains('ql-editor') and activeElement.parentElement.id != 'msg_input'
+           return @continueBubbling
        ...
```

**The main limitations:**
- The "seems to be the search box" logic is messy as described in the comment
  above.
  - Probably there are other `.ql-editor`s aside from the two I found.
  - If Slack changes implementation details I'm depending on, my fix will
    break.
- I think other manifestations of this bug exist in other places (in Slack and
  in other webapps too, probably), too. Since this fix is so specific, it
  obviously doesn't apply to the other manifestations.

## Changelog

- v0.1.0: Vimium 1.64.5 with fix.
