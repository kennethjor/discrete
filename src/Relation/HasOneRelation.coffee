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
		oldId = @id()
		oldModel = @model()
		id = null
		model = null
		change = false
		# If another relation was passed, import the values from it.
		if modelOrId instanceof HasOneRelation
			modelOrId = modelOrId.model() or modelOrId.id()
		# Set model.
		if modelOrId instanceof Model
			@verifyType modelOrId
			@_model = model = modelOrId
			@_id = id = model.id()
			# A different model instance should force a change.
			change = true if model isnt oldModel
		# Set ID.
		else
			@_id = id = modelOrId
			# Reset model instance if we received a different ID.
			if oldModel? and id isnt oldId
				@_model = null
				change = true
		# If the ID changes, we always have a change.
		change = true if id isnt oldId
		# Detect change.
		if change
			@_triggerChange
				id: id
				oldId: oldId
				value: @get()
				oldValue: oldModel

	# Returns the ID of the foreign model.
	id: ->
		if @_model
			return @_model.id()
		else
			return @_id

	# Returns the foreign model instance.
	model: ->
		return @_model

	get: ->
		return @model() or @id()

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

	# Clones the relation.
	clone: (base = new HasOneRelation) ->
		base.set @model() or @id()
		return base

	# Loads the model(s) through the supplied persistor.
	load: (persistor, done) ->
		# Check if we have anything to load.
		if @empty()
			_.defer -> done null, null
			return
		# Check if we need to load.
		if @loaded()
			_.defer => done null, @model()
			return
		# We need to load.
		persistor.load @id(), (err, model) =>
			if err
				_.defer -> done err, null
				return
			@set model
			_.defer -> done null, model

#	# Saves the model(s) through the supplied persistor.
#	# Note: it could be argued that this is not the responsibility of the relation ... @todo
#	save: (persistor, callback) ->
#		# Check if we are empty.
#		if @empty() or not @loaded()
#			callback null, @model()
#			return
#		# Save.
#		persistor.save @model(), (err, model) =>
#			if err
#				_.defer -> callback err, null
#				return
#			# Remember the saved model.
#			@set model
#			_.defer -> callback null, model

