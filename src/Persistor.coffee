Discrete.Persistor = class Persistor
	# Saves the supplied model.
	# The format of the callback should be `callback(error, model)`.
	save: (model, callback) ->
		throw new Error "Save not extended"

	# Loads the supplied model ID.
	# The format of the callback should be `callback(error, model)`.
	load: (model, callback) ->
		throw new Error "Load not extended"
