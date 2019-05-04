hasAncestorWithId = (element, id) ->
  while element.parentElement
    if element.parentElement.id == id
      return true
    element = element.parentElement
  false


# Returns true if should bubble to site's esc handler.
# Returns false if should let Vimium do its thing (blur if focusable, ...)
bubbleWhitelistContains = (activeElement) ->
  # TODO Check domain

  # Slack --------------------------------------------------------------------
  # - Should return true for "find a channel/DM/etc" input
  # - Should return false for "type a message" input
  isQlEditor = activeElement.classList.contains('ql-editor')
  isMsgInput = hasAncestorWithId(activeElement, 'msg_input')
  if isQlEditor and not isMsgInput
    return true

  # Facebook -----------------------------------------------------------------
  # - Should return true for chat input, new post input
  # - Should return false for comment input
  isNoTranslate = activeElement.classList.contains('notranslate')
  isChat = hasAncestorWithId(activeElement, 'ChatTabsPagelet')
  isNewPost = hasAncestorWithId(activeElement, 'pagelet_composer')
  if isNoTranslate and (isChat or isNewPost)
    return true

  false

class InsertMode extends Mode
  constructor: (options = {}) ->
    # There is one permanently-installed instance of InsertMode.  It tracks focus changes and
    # activates/deactivates itself (by setting @insertModeLock) accordingly.
    @permanent = options.permanent

    # If truthy, then we were activated by the user (with "i").
    @global = options.global

    handleKeyEvent = (event) =>
      return @continueBubbling unless @isActive event

      # See comment here: https://github.com/philc/vimium/commit/48c169bd5a61685bb4e67b1e76c939dbf360a658.
      activeElement = @getActiveElement()
      return @passEventToPage if activeElement == document.body and activeElement.isContentEditable

      # Check for a pass-next-key key.
      if KeyboardUtils.getKeyCharString(event) in Settings.get "passNextKeyKeys"
        new PassNextKeyMode

      else if event.type == 'keydown' and KeyboardUtils.isEscape(event)
        if bubbleWhitelistContains activeElement
          return @continueBubbling
        activeElement.blur() if DomUtils.isFocusable activeElement
        @exit() unless @permanent

      else
        return @passEventToPage

      return @suppressEvent

    defaults =
      name: "insert"
      indicator: if not @permanent and not Settings.get "hideHud"  then "Insert mode"
      keypress: handleKeyEvent
      keydown: handleKeyEvent

    super extend defaults, options

    # Only for tests.  This gives us a hook to test the status of the permanently-installed instance.
    InsertMode.permanentInstance = this if @permanent

  isActive: (event) ->
    return false if event == InsertMode.suppressedEvent
    return true if @global
    DomUtils.isFocusable @getActiveElement()

  getActiveElement: ->
    activeElement = document.activeElement
    while activeElement?.shadowRoot?.activeElement
      activeElement = activeElement.shadowRoot.activeElement
    activeElement

  # Static stuff. This allows PostFindMode to suppress the permanently-installed InsertMode instance.
  @suppressedEvent: null
  @suppressEvent: (event) -> @suppressedEvent = event

# This implements the pasNexKey command.
class PassNextKeyMode extends Mode
  constructor: (count = 1) ->
    seenKeyDown = false
    keyDownCount = 0

    super
      name: "pass-next-key"
      indicator: "Pass next key."
      # We exit on blur because, once we lose the focus, we can no longer track key events.
      exitOnBlur: window
      keypress: =>
        @passEventToPage

      keydown: =>
        seenKeyDown = true
        keyDownCount += 1
        @passEventToPage

      keyup: =>
        if seenKeyDown
          unless 0 < --keyDownCount
            unless 0 < --count
              @exit()
        @passEventToPage

root = exports ? (window.root ?= {})
root.InsertMode = InsertMode
root.PassNextKeyMode = PassNextKeyMode
extend window, root unless exports?
