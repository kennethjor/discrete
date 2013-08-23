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
	# Returns true if the relation was altered by the call.
	add: (modelOrId...) ->
		added = @_add modelOrId
		if added
			@_triggerChange operation: "add"
		return added
	# The real add method.
	_add: (modelOrId...) ->
		# Wrap if adding multiple.
		modelOrId = _.flatten modelOrId
		if modelOrId.length > 1
			added = false
			for m in modelOrId
				if @_add m then added = true
			return added
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

	# Removes an element from the relation.
	# Returns true if the relation was altered by the call.
	remove: (modelOrId) ->
		removed = @_remove modelOrId
		if removed
			@_triggerChange operation: "remove"
		return removed
	# The real remove method.
	_remove: (modelOrId) ->
		return false unless @contains modelOrId
		id = if modelOrId instanceof Model then modelOrId.id() else modelOrId
		n = 0
		while @contains id
			index = @_ids.getIndexForValue id
			@_ids.removeByIndex index
			@_models.removeByIndex index
			n++
		return n > 0

	# Sets the relation.
	set: (modelsOrIds) ->
		altered = @_set modelsOrIds
		if altered
			@_triggerChange operation: "set"
		return altered
	# The real set call.
	_set: (modelsOrIds) ->
		modelsOrIds = [] if modelsOrIds is null
		modelsOrIds = modelsOrIds.toJSON() if modelsOrIds instanceof Collection
		throw new Error "Setting the values of HasMany must be an array or collection" unless _.isArray modelsOrIds
		# Prepare a collection of all current IDs.
		remaining = new Collection @_ids
		# Copy a list of the existing elements.
		for item in modelsOrIds
			# If we have the item.
			if @contains item
				# If it's a model, replace all the internal ID elements.
				if item instanceof Model
					@_models.replace item.id(), item
				# Otherwise ignore it.
			# If we don't have it the item, add it.
			else
				@_add item
			# Remove processed item from the array of original IDs.
			id = if item instanceof Model then item.id() else item
			remaining.remove id
		# Now remaining contains a list of originally present IDs which were not present in the supplied array. Remove them.
		remaining.each (item) => @_remove item
		return true # @todo implement alteration detection

	# Returns true of the Model or ID exists in the relation.
	contains: (modelOrId) ->
		found = false
		if modelOrId instanceof Model
			model = modelOrId
			id = model.id()
			found = @_models.contains model
			if not found and id?
				found = @_ids.contains id
		else
			found = @_ids.contains modelOrId
		return found

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

	# Clones the relation.
	clone: (base = new HasManyRelation) ->
		base._ids = @_ids.clone()
		base._models = @_models.clone()
		return base

	# Utility method for triggering a change event.
	_triggerChange: (data) ->
		data.models = @_models.toJSON()
		data.value = @get()
		super
