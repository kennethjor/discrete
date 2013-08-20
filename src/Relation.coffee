# Base class for relations.
# These objects manage the functionality of a relation type and also contains the value in question.
# When a relation is set on a model, it's actually changed in the relation object and not the model,
# leaving the model free from knowing how to handle individual relation types.
# Also serves as a factory for relations.
Discrete.Relation = class Relation
	Calamity.emitter @prototype

	constructor: (@options = {}) ->
		# Valid options:
		#
		# * `model`: Model type to enforce on the relation.

	# Throws an `Error` if the supplied object doesn't match the relation's optional type.
	# If no type is set, this method returns true.
	verifyType: (model) ->
		options = @options
		if options.model? and model instanceof options.model isnt true
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
		throw new Error "Clone not extended"

	# Loads the model(s) through the supplied persistor.
	load: (persistor, callback) ->
		throw new Error "Load not extended"

	# Saves the model(s) through the supplied persistor.
	save: (persistor, callback) ->
		throw new Error "Save not extended"

	# Utility method for triggering a change event.
	_triggerChange: (data) ->
		data.relation = @
		@trigger "change", data

	###
    STATIC METHODS.
	###

	# Registers a relation with the factory.
	@register = (name, func) ->
		@[name] = func
		# Add a clone function. @todo remove, it's bad
		func::clone or= do (func) ->
			return new func @options
		return func

	# Constructs a relation from a model's configuration object.
	@create = (options) ->
		# Get type.
		type = null
		if _.isString(options) or _.isFunction(options)
			type = options
			options = {}
		else if _.isObject options
			type = options.type
		else
			throw new Error "Options must be either string, function, or object"
		# Get type if needed.
		if _.isString type
			throw new Error "Unknown relation type: \"#{type}\"" unless @[type]?
			type = @[type]
		# Complain about missing type.
		throw new Error "No relation type found" unless type?
		# Type is now a function, construct.
		relation = new type options
		return relation
