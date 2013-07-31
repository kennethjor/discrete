# Simple repository for storing `Model` instances.
Discrete.ModelRepo = class ModelRepo
	constructor: ->
		@_models = {}

	put: (model) ->
		models = @_models
		id = model.id()
		# Check ID.
		unless id?
			throw new Error "Models stored in ModelRepo must have an ID set"
		# Check if we already have a model.
		if models[id]?
			# Replace model.
			models[id] = @handleOverwrite models[id], model
		# Model doesn't already exist, save it.
		else
			models[id] = model
		return models[id]

	get: (id) ->
		if @_models[id]?
			return @_models[id]
		return null

	size: ->
		n = 0
		for own id, model of @_models
			n++
		return n

	# Called when an overwrite occurs.
	# Default returns the old model.
	# Extend at your leisure.
	handleOverwrite: (oldModel, newModel) ->
		return oldModel
