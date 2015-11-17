{CompositeDisposable} = require 'atom'
path = require 'path'

FULL_MID_PATTERN = "^(\\w+(?:/\\w+)+)(?:.js)?$"
RELATIVE_MID_PATTERN = "^((?:..?/)+(?:\\w+/)*\\w+)(?:.js)?$"

getMid = ->
	editor = atom.workspace.getActiveTextEditor()
	# using screen position and bufferRangeForScopeAtPosition is a workaround for https://github.com/atom/atom/issues/9648
	cursorPosition = editor.getCursorScreenPosition()
	midRange = editor.displayBuffer.bufferRangeForScopeAtPosition ".string", cursorPosition
	return unless midRange
	mid = editor.getTextInBufferRange editor.bufferRangeForScreenRange midRange
	mid.substring 1, mid.length - 1 #strip quotes

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
	fileName +=  ".js" unless fileName.endsWith ".js"
	fileLocation = path.join(packageLocation, path.join.apply(path, midParts), fileName)
	atom.workspace.open fileLocation

openRelativeMid = (mid) ->
	editor = atom.workspace.getActiveTextEditor()
	mid +=  ".js" unless mid.endsWith ".js"
	atom.workspace.open path.join(path.dirname(editor.getPath()), mid)

goToModule = ->
	# "dojo/Deferred"
	mid = getMid()
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
