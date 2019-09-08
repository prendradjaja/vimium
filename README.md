# Pandu's Vimium fork (site-specific Esc behavior)

([Original readme](./ORIGINAL_README.md))

**Problem:** Vimium uses Esc to blur `<input>`s and other focusable elements.
This works well to go from insert mode to normal mode, but some websites have
their own Esc handlers that get clobbered by Vimium (e.g. closing chat tabs on
Facebook).

**My solution:** Add site-specific exceptions (where we tell Vimium to
continue bubbling a `keydown` event to the site instead of blurring), e.g.

```diff
+ # Returns true if should bubble to site's esc handler.
+ # Returns false if should let Vimium do its thing (blur if focusable, ...)
+ shouldContinueBubbling = (activeElement) ->
+   # Facebook -----------------------------------------------------------------
+   # - Should return true for chat input
+   # - Should return false for other inputs
+   isNoTranslate = activeElement.classList.contains('notranslate')
+   isChat = hasAncestorWithId(activeElement, 'ChatTabsPagelet')
+   if isNoTranslate and isChat
+     return true
+   false

  class InsertMode extends Mode
    constructor: (options = {}) ->
      ...
      handleKeyEvent = (event) =>
        ...
        else if event.type == 'keydown' and KeyboardUtils.isEscape(event)
+         if shouldContinueBubbling activeElement
+           return @continueBubbling
          activeElement.blur() if DomUtils.isFocusable activeElement
          ...
```

**Vanilla Vimium solution:** As described in [Vimium Tips and
Tricks][vimium-tips], another solution to this issue is to use the built-in
`passNextKey` command and press something like `<c-[><esc>`. (You can find
more discussion of this by searching Vimium's issues for e.g. "escape",
"passNextKey")

## Changelog

- v0.1.6: Add Google Sheets search rule (might overlap with Docs etc?)
- v0.1.5: Add Slack emoji rule
- v0.1.4: Add Google Sheets cell rule
- v0.1.3: Rename `bubbleWhitelistContains` -> `shouldContinueBubbling`.
- v0.1.2: Add Facebook rule, refactor Slack rule.
- v0.1.1: Refactor to make it easier to use this fix for other places & sites.
- v0.1.0: Vimium 1.64.5 with fix.


[vimium-tips]: https://github.com/philc/vimium/wiki/Tips-and-Tricks#using-the-escape-key-in-inputs
