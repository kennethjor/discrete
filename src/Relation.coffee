# Base class for relations.
# Also serves as a factory for relations.
Discrete.Relation = class Relation
	# Optional static type for this relation.
	type: null

	constructor: (@options = {}) ->
		@type ?= @options.type

	# Throws an `Error` if the supplied object doesn't match the relation's optional type.
	# If no type is set, this method returns true.
	verifyType: (model) ->
		if @type? and model instanceof @type isnt true
			throw new Error "Invalid model type supplied"
		return true

	# Returns true if this relation doesn't point to any foreign model(s).
	empty: ->
		throw new Error "empty() not extended"

	# Returns true if this relation has loaded its foreign model(s).
	# If the relation is empty, loaded will also return true.
	loaded: ->
		throw new Error "loaded() not extended"

	# Serializes the relation to a storable value containing only the IDs of the foreign models.
	serialize: ->
		throw new Error "serialize() not extended"

	# Clones the relation.
	# This should only ever be used by `Model`.
	clone: ->
		throw new Error

	# Loads the model(s) through the supplied persistor.
	load: (persistor, callback) ->
		throw new Error "Load not extended"

	# Saves the model(s) through the supplied persistor.
	save: (persistor, callback) ->
		throw new Error "Save not extended"

	###
    STATIC METHODS.
	###

	# Registers a relation with the factory.
	@register = (name, func) ->
		@[name] = func
		# Add a clone function.
		func::clone or= do (func) ->
			return new func @options
		return func

	# Returns a relation instance based on a string.
	@get = (name) ->
		unless @[name]?
			throw new Error "Unknown relation type: \"#{name}\""
		return @[name]
