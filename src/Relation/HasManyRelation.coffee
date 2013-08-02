# Represents a relation on a model which links to multiple other models.
Relation.register "HasMany", class HasManyRelation extends Relation
	constructor: ->
		super
		# Defaults.
		@options.collection or= Collection
		# We keep two of the collections around so we can allow a crazy mix of IDs and model instances.
		@_ids = new @options.collection
		@_models = new @options.collection # note that this contains the IDs for models which are not loaded.

	# Adds a model to the relation.
	add: (modelOrId...) ->
		# Wrap if adding multiple.
		modelOrId = _.flatten modelOrId
		if modelOrId.length > 1
			for m in modelOrId
				@add m
			return
		else
			modelOrId = modelOrId[0]

		# Handle individuals.
		id = modelOrId
		model = modelOrId
		if model instanceof Model
			id = model.id()
			throw new Error "Model must have an ID to be added to a relation" unless id?
		else
			model = null
			throw new Error "No ID supplied for relation" unless id?

		# Add the ID to the IDs collection, which will control whether the model should be added or not.
		added = false
		if @_ids.add(id)
			# Add the model or the ID to the models collection.
			@_models.add model or id
			added = true

		# If we are supplied a model, we need to replace all the known unloaded IDs with this instance.
		# This is done regardless of whether the model was added or not.
		if model instanceof Model
			@_models.replace model.id(), model

		return added

	# Loads the model(s) through the supplied persistor.
	load: (persistor, done) ->
		# Check if we have anything to load.
		if @empty()
			_.defer -> done null
			return
		# Check if we need to load.
		if @loaded()
			_.defer => done null
			return
		# We need to load, prepare the fetcher container.
		# This container is different than normal in that it's an object, so IDs are only fetched once.
		fetchers = {}
		# Constructor fetchers.
		@_models.each (model) =>
			# If model is loaded, ignore it.
			return if model instanceof Model
			# If we already have a fetcher for this ID, ignore it.
			id = model
			return if fetchers[id]?
			# Create and add the function.
			fetchers[id] = do (id) => (done) =>
				persistor.load id, (err, model) =>
					# Pass errors.
					if err
						_.defer -> done err
					# Replace model.
					else
						@_models.replace id, model if model
						_.defer -> done null
		# Execute them all.
		Async.parallel fetchers, (err) ->
			if err
				_.defer -> done err
			else
				_.defer -> done null

#	# Saves the model(s) through the supplied persistor.
#	save: (persistor, done) ->
#		# Check if we have anything to save.
#		if @empty()
#			_.defer -> done null
#			return
#		# Prepare a set of models which need to be saved.
#		savers = new Set()



	# Sets the relation.
	# Note that this will wipe any existing relational data.
	set: (modelsOrIds) ->
		modelsOrIds = _.flatten [modelsOrIds]
		# Crude! @todo
		@_ids.removeAll()
		@_models.removeAll()
		for m in modelsOrIds
			@add m

	# Returns the current collection of models or IDs, or both, depending on what's loaded.
	get: ->
		return @_models

	# Returns true if this relation doesn't point to any foreign model(s).
	empty: ->
		return @_ids.size() is 0

	# Returns true if this relation has loaded its foreign model(s).
	# If the relation is empty, loaded will also return true.
	loaded: ->
		loaded = true
		@_models.each (model, i) ->
			loaded = false unless model instanceof Model
		return loaded

	# Serializes the relation to a storable value containing only the IDs of the foreign models.
	serialize: ->
		json = []
		@_models.each (m) ->
			if m instanceof Model
				json.push m.id()
			else
				json.push m
		return json
