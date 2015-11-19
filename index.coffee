{CompositeDisposable} = require 'atom'
path = require 'path'

FULL_MID_PATTERN = "^(\\w+(?:/\\w+)+)(?:.js)?$"
RELATIVE_MID_PATTERN = "^((?:..?/)+(?:\\w+/)*\\w+)(?:.js)?$"
REQUIRE_PATTERN = "(?:require|define)\\s*\\(\\s*\\[((?:\\s|\\S)+?)\\]\\s*,\\s*function\\s*\\(((?:\\s|\\S)+?)\\)"

getTarget = ->
	editor = atom.workspace.getActiveTextEditor()
	# using screen position and bufferRangeForScopeAtPosition is a workaround for https://github.com/atom/atom/issues/9648
	cursorPosition = editor.getCursorScreenPosition()
	midRange = editor.displayBuffer.bufferRangeForScopeAtPosition ".string", cursorPosition
	return unless midRange
	mid = editor.getTextInBufferRange editor.bufferRangeForScreenRange midRange

	return {
		mid: mid.substring 1, mid.length - 1 #strip quotes
	}

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

getTargetFromVariable = ->
	editor = atom.workspace.getActiveTextEditor()
	cursor = editor.getLastCursor()
	currentWord = editor.getWordUnderCursor()
	currentWordRange = cursor.getCurrentWordBufferRange()
	# if current word is preceded with '.', current word is not module, try the previous one
	if editor.getTextInBufferRange([[currentWordRange.start.row, currentWordRange.start.column - 1], currentWordRange.start]) == "."
		# create new temporary cursor, this will place it after '.'
		tempCursor = editor.addCursorAtBufferPosition(cursor.getPreviousWordBoundaryBufferPosition())
		tempCursor.moveToPreviousWordBoundary() # this will move it before '.'
		moduleName = tempCursor.getCurrentWordPrefix().trim()
		functionName = currentWord
		tempCursor.destroy()
	else
		moduleName = currentWord
	moduleMap = getModuleMap()
	return {
		mid: moduleMap?[moduleName]
		functionName: functionName
	}

isFullMid = (mid) ->
	mid.match FULL_MID_PATTERN

isRelativeMid = (mid) ->
	mid.match RELATIVE_MID_PATTERN

openTargetWithFullMid = (target) ->
	packages = atom.config.get "amd-navigator.packages"
	if !packages
		console.error "Packages not configured."
		return

	midParts = target.mid.split "/"
	packageLocation = packages[midParts.shift()]
	return unless packageLocation
	fileName = midParts.pop()
	fileName += ".js" unless fileName.endsWith ".js"
	fileLocation = path.join(packageLocation, path.join.apply(path, midParts), fileName)
	atom.workspace.open fileLocation

openTargetWithRelativeMid = (target) ->
	editor = atom.workspace.getActiveTextEditor()
	mid = target.mid
	mid += ".js" unless mid.endsWith ".js"
	atom.workspace.open path.join(path.dirname(editor.getPath()), mid)

goToModule = ->
	# "dojo/DeferredList"
	target = getTarget()
	unless target?.mid
		target = getTargetFromVariable()
	return unless target?.mid

	if isFullMid target.mid
		openTargetWithFullMid target
	else if isRelativeMid target.mid
		openTargetWithRelativeMid target

module.exports =

	subscriptions: null

	activate: (state) ->
		@subscriptions = new CompositeDisposable
		@subscriptions.add atom.commands.add 'atom-text-editor', 'amd-navigator:go-to-module': => goToModule()

	deactivate: ->
		@subscriptions.dispose()
