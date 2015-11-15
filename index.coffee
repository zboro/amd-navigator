{CompositeDisposable} = require 'atom'
path = require 'path'

module.exports =

	subscriptions: null

	activate: (state) ->
		@subscriptions = new CompositeDisposable
		@subscriptions.add atom.commands.add 'atom-text-editor', 'amd-navigator:go-to-module': => @goToModule()

	goToModule: ->
		"dojo/Deferred"
		editor = atom.workspace.getActiveTextEditor()
		currentLine = editor.lineTextForBufferRow(editor.getCursorBufferPosition().row)
		match = currentLine.match("[\"'](\\w+(/\\w+)+)[\"']")
		if match and match[1]
			@openModule(match[1])

	openModule: (mid) ->
		packages = atom.config.get("amd-navigator.packages")
		if !packages
			console.error("Packages not configured.")
			return

		midParts = mid.split("/")
		packageLocation = packages[midParts.shift()]
		fileName = midParts.pop() + ".js"
		fileLocation = path.join(packageLocation, path.join.apply(path, midParts), fileName)
		atom.workspace.open(fileLocation)

	deactivate: ->
		@subscriptions.dispose()
