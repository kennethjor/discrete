Discrete.Persistor = class Persistor
	# Saves the supplied model, calling the callback as necesarry.
	# The format of the callback should be `callback(error = null)`.
	save: (model, callback) ->
		throw new Error "Save not extended"
