{CompositeDisposable} = require 'atom'
path = require 'path'

FULL_MID_PATTERN = "^(\\w+(?:/\\w+)+)(?:.js)?$"
RELATIVE_MID_PATTERN = "^((?:..?/)+(?:\\w+/)*\\w+)(?:.js)?$"
REQUIRE_PATTERN = "(?:require|define)\\s*\\(\\s*\\[((?:\\s|\\S)+?)\\]\\s*,\\s*function\\s*\\(((?:\\s|\\S)+?)\\)"

getMid = ->
	editor = atom.workspace.getActiveTextEditor()
	# using screen position and bufferRangeForScopeAtPosition is a workaround for https://github.com/atom/atom/issues/9648
	cursorPosition = editor.getCursorScreenPosition()
	midRange = editor.displayBuffer.bufferRangeForScopeAtPosition ".string", cursorPosition
	return unless midRange
	mid = editor.getTextInBufferRange editor.bufferRangeForScreenRange midRange
	mid.substring 1, mid.length - 1 #strip quotes

getModuleMap = ->
	editor = atom.workspace.getActiveTextEditor()
	match = editor.getText().match(REQUIRE_PATTERN)
	return unless match
	# mids = (quotedMid = mid.trim() && quotedMid.substring(1, quotedMid.length - 1) for mid in match[1].split(","))
	mids = match[1].split(",").map (mid) ->
		mid = mid.trim()
		mid.substring 1, mid.length - 1
	aliases = (alias.trim() for alias in match[2].split(","))
	moduleMap = {}
	moduleMap[alias] = mids[i] for alias, i in aliases
	return moduleMap

getMidFromVariable = ->
	editor = atom.workspace.getActiveTextEditor()
	cursor = editor.getLastCursor()
	currentWordRange = cursor.getCurrentWordBufferRange()
	# if current word is preceded with '.', current word is not module, try the previous one
	if editor.getTextInBufferRange([[currentWordRange.start.row, currentWordRange.start.column - 1], currentWordRange.start]) == "."
		# create new temporary cursor, this will place it after '.'
		tempCursor = editor.addCursorAtBufferPosition(cursor.getPreviousWordBoundaryBufferPosition())
		tempCursor.moveToPreviousWordBoundary() # this will move it before '.'
		moduleName = tempCursor.getCurrentWordPrefix().trim()
		tempCursor.destroy()
	else
		moduleName = editor.getWordUnderCursor()
	moduleMap = getModuleMap()
	return moduleMap?[moduleName];

isFullMid = (mid) ->
	mid.match FULL_MID_PATTERN

isRelativeMid = (mid) ->
	mid.match RELATIVE_MID_PATTERN

openFullMid = (mid) ->
	packages = atom.config.get "amd-navigator.packages"
	if !packages
		console.error "Packages not configured."
		return

	midParts = mid.split "/"
	packageLocation = packages[midParts.shift()]
	return unless packageLocation
	fileName = midParts.pop()
	fileName += ".js" unless fileName.endsWith ".js"
	fileLocation = path.join(packageLocation, path.join.apply(path, midParts), fileName)
	atom.workspace.open fileLocation

openRelativeMid = (mid) ->
	editor = atom.workspace.getActiveTextEditor()
	mid += ".js" unless mid.endsWith ".js"
	atom.workspace.open path.join(path.dirname(editor.getPath()), mid)

goToModule = ->
	# "dojo/Deferred"
	mid = getMid()
	unless mid
		mid = getMidFromVariable()
	return unless mid

	if isFullMid(mid)
		openFullMid(mid)
	else if isRelativeMid(mid)
		openRelativeMid(mid)

module.exports =

	subscriptions: null

	activate: (state) ->
		@subscriptions = new CompositeDisposable
		@subscriptions.add atom.commands.add 'atom-text-editor', 'amd-navigator:go-to-module': => goToModule()

	deactivate: ->
		@subscriptions.dispose()
