# Represents a relation on a model which links directly to another model.
Relation.register "HasOne", class HasOneRelation extends Relation
	constructor: (options = {}) ->
		super
		# The ID of the foreign model.
		@_id = null
		# The foreign model instance.
		@_model = null

	# Sets the relation model or ID.
	set: (modelOrId) ->
		# Set model.
		if modelOrId instanceof Model
			@verifyType modelOrId
			@_model = modelOrId
			@_id = modelOrId.id()
		# Set ID.
		else
			@_id = modelOrId
			# Reset model instance unless ID is the same.
			if @_model isnt null and @_model.id() isnt modelOrId
				@_model = null

	# Returns the ID of the foreign model.
	id: ->
		if @_model
			return @_model.id()
		else
			return @_id

	# Returns the foreign model instance.
	model: ->
		return @_model

	# Returns true if this relation doesn't point to a foreign model.
	empty: ->
		return not @_id?

	# Returns true if this relation has loaded its foreign model.
	# If the relation is empty, loaded will also return true.
	loaded: ->
		return @empty() or @_model?

	# Serializes the relation to a storable value containing only the IDs of the foreign models.
	serialize: ->
		return @id()

	# Loads the model(s) through the supplied persistor.
	load: (persistor, callback) ->
		# Check if we have anything to load.
		if @empty()
			_.defer -> callback null, null
			return
		# Check if we need to load.
		if @loaded()
			_.defer => callback null, @model()
			return
		# We need to load.
		persistor.load @id(), (err, model) =>
			if err
				callback err, null
				return
			@set model

	# Saves the model(s) through the supplied persistor.
	save: (persistor, callback) ->
		# Check if we are empty.
		if @empty() or not @loaded()
			callback null, @model()
			return
		# Save.
		persistor.save @model(), (err, model) =>
			if err
				_.defer -> callback err, null
				return
			# Remember the saved model.
			@set model
			_.defer -> callback null, model

