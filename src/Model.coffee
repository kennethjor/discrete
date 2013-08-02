Discrete.Model = class Model
	Calamity.emitter @prototype

	# Model field definitions.
	# The key is the field name, and the value may contain the following values:
	#
	# * `default`: The default value for the field.
	# * `relation`: The relation specification. This can either be a string or a `Relation` object.
	fields: null

	# Default values to be assigned automatically.
	# Any functions defined here will be executed and their return values will be used as the default.
	# These functions are executed once per needed default value, and they take the current values object as their only argument.
	#defaults: {}

	# Defined relations.
	#relations: {}

	# The `Persistor` to use for this model.
	# The value for this attribute should be a constructor method.
	# For custom implementations override `getPersistor()`.
	# This is required for the `save()` function to work.
	persistor: null

	# Constructor.
	constructor: (values) ->
		# ID.
		@_id = null
		if values?.id?
			@id values.id
			delete values.id
		# Prepare internal containers.
		@_values = {}
		@_relations = {}
		# Populate default values.
		values = @_defaults values
		# Set values.
		@set values

	# Populates default values.
	_defaults: (values = {}) ->
		for own name, field of @fields
			# Ignore if no default is defined.
			continue if field.default is undefined
			val = field.default
			# Ignore existing values.
			continue if values[name]?
			# Execute default function.
			if _.isFunction val
				values[name] = val values
			# Otherwise just set it.
			else
				values[name] = val
		return values

	# Returns a `Relation` object for the field name, or null if field doesn't exist or is not a relation.
	getRelation: (name) ->
		return null unless @fields
		field = @fields[name]
		# Check for known field definition.
		return null unless field?
		# Check for relation definition.
		relation = field.relation
		return null unless relation?
		# Return the current relation if we have it.
		current = @_relations[name]
		return current if current?
		# Construct relation.
		relation = Relation.create relation
		# Store it.
		@_relations[name] = relation

		return relation

	# ID getter/setter.
	id: (id) ->
		if id?
			@_id = id
		return @_id

	# Sets one or more values.
	# Can be called with a key and value, or with an object.
	# If a `Model` instance is supplied directly, the values will be copied over directly.
	set: (keyOrObj, val) ->
		return @ unless keyOrObj
		# Convert a supplied model to JSON.
		obj = keyOrObj
		if obj instanceof Model
			@id obj.id()
			obj = obj.toJSON()
		# Convert to object.
		unless _.isObject obj
			obj = {}
			obj[keyOrObj] = val
		# Prepare container to hold old values for changed keys
		triggers = {}
		# Iterate over object.
		for own key, val of obj
			oldVal = null
			# Check relation.
			relation = @getRelation key
			if relation?
				oldVal = relation.get()
			else
				oldVal = @_values[key]
			# Add old value to triggers.
			triggers[key] = @_values[key]
			# Set the value, checking relation.
			if relation?
				relation.set val
			else
				@_values[key] = val
		# Trigger change events.
		@_triggerChanges triggers
		return @

	# Executes change events.
	_triggerChanges: (keys) ->
		# Fire main trigger.
		@trigger "change",
			model: @
#			keys: _.keys keys
		for own key, oldVal of keys
			event = "change:#{key}"
			@trigger event,
				model: @
#				key: key
#				oldVal: val
				value: @get key

	# Returns a value on the object.
	get: (key) ->
		# Pass to relation.
		relation = @getRelation key
		if relation?
			return relation.get()
		# Return normal value.
		return @_values[key]

	# Returns a list of keys.
	keys: ->
		keys = _.keys @_values
		# Add relations.
		keys = _.union keys, _.keys @_relations
		return keys

	# Iterator.
	each: (fn) ->
		for key, val of @_values
			fn.apply @, [key, val]
		return @

	# Serializes the model into a plain JSON object.
	# This method does not serialize recursively, and extending it to do so is not recommended.
	toJSON: ->
		json = _.clone @_values
		# Set ID if we have it.
		if @_id?
			json.id = @_id
		# Otherwise make sure the serialized form does not contain an ID.
		else
			delete json.id

		return json

	# Serializes the model to a JSON object.
	# `serialize` is different from `toJSON` in that it will convert relations to IDs.
	# Any other recursive serialization should be handled by overriding this method.
	serialize: ->
		# First off do a straight toJSON.
		json = @toJSON()
		# Extra field processing.
		for own name, field of @fields
			# Handle relations.
			relation = @getRelation name
			if relation?
				json[name] = relation.serialize()

		return json

	# Creates a clone of this model.
	# Extend to properly implement deep cloning where needed.
	# `base` can be used when extending to provide a base model object to clone into.
	clone: (base = null) ->
		base or= new Model
		base.set @
		return base

	# Returns a persistor instance to use for this model.
	# Set the `persistor` class attribute to your desired `Persistor` constructor function, or override this method to add custom functionality.
	getPersistor: ->
		persistor = @persistor
		throw new Error "Persistor not defined" unless persistor?
		return persistor if persistor instanceof Persistor
		@persistor = new persistor
		return @persistor

	# Saves the model through the defined persistor.
	# Note that relations are not saved automatically as this could lead to infinite recursion and general unexpected nastiness.
	save: (done) ->
		@getPersistor().save @, done

#		# Check relations for IDs. We can't save ID references unless all relations were previously saved.
#		for own field, relation of @relations
#			val = @get field
#			continue if _.isEmpty val
#			if relation.collection?
#				val.each (entry) ->
#					do (entry) -> _.defer -> done new Error "Entry in collection relation \"#{field}\" does not have an ID when saving model" unless entry.id()?
#			else
#				do (val) -> _.defer -> done new Error "Relation \"#{field}\" does not have an ID when saving model" unless val.id()?
#		# Execute save.
#		persistor.save @, done
#		return @

	# Laods all the defined relations.
	loadRelations: (done) ->
		persistor = @getPersistor()
		# Prepare list of fetchers.
		fetchers = []
		# Iterate over fields.
		for own name, field of @fields
			relation = @getRelation name
			# Ignore non-relational fields.
			continue unless relation
			# Create fetcher function.
			fetchers.push do (relation) -> (done) ->
				# Load from persistor and pass errors if they occur.
				# The callbacks here have the same format.
				relation.load persistor, done
		# Array of fetcher functions create, execute them.
		Async.parallel fetchers, done

#	# Fetches all the defined relations.
#	fetch: (done) ->
#		persistor = @getPersistor()
#		# Final results container.
#		results = {}
#		# Create a list of IDs which need to be fetched and the field they belong to.
#		ids = []
#		for own field, relation of @relations
#			current = @get field
#			# If relation is a collection.
#			if relation.collection?
#				# Check is a collection is already initialised/loaded.
#				continue if current instanceof relation.collection
#				# Initialise empty collection.
#				results[field] = new relation.collection
#				# If current is empty, take no further action.
#				continue if _.isEmpty current
#				# Current value must be an array.
#				throw new Error "#{field} is not empty and is not an array" unless _.isArray current
#				# Iterate over all values and add them to the list.
#				for id in current
#					ids.push [field, id]
#			# Relation is not a collection, must be a model.
#			else
#				# Skip if loaded.
#				continue if current instanceof relation.model
#				# Check if ID and add it to the list.
#				continue if _.isEmpty current
#				ids.push [field, current]
#		# Now we have a list of IDs to fetch, create an array of fetcher functions.
#		fetchers = []
#		for def in ids
#			field = def[0]
#			id = def[1]
#			fetchers.push do (field, id) => (done) =>
#				persistor.load id, (err, model) =>
#					# Proxy errors.
#					if err
#						done err
#						return
#					# Pass result on.
#					done null, [field, model]
#		# Execute all the fetchers.
#		Async.parallel fetchers, (err, fetchResults) =>
#			# Proxy error.
#			if err
#				done err
#				return
#			# Initialise all collections.
#			for field, relation in @relations
#				if relation.collection?
#					results[field] = new relation.collection unless results[field]?
#			# We now have an array of a bunch of models, add them to the results object.
#			for def in fetchResults
#				field = def[0]
#				model = def[1]
#				relation = @relations[field]
#				# If collection, add
#				if relation.collection?
#					results[field].add model
#				# If model, set.
#				else
#					results[field] = model
#			# All results collected, set it.
#			@set results
#			done null
