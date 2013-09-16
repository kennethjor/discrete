Discrete.Model = class Model
	Calamity.emitter @prototype

	# Model field definitions.
	# The key is the field name, and the value may contain the following values:
	#
	# * `default`: The default value for the field.
	# * `relation`: The relation specification. This can either be a string or a `Relation` object.
	fields: null

	# The `Persistor` to use for this model.
	# The value for this attribute should be a constructor method.
	# For custom implementations override `getPersistor()`.
	# This is required for the `save()` function to work.
	persistor: null

	# Constructor.
	constructor: (values) ->
		# Prepare internal containers.
		@_values = {}
		@_relations = {}
		# ID.
		@_id = null
		if values?.id?
			@id values.id
			delete values.id
		# Contains subscription objects for relation change events.
		@_relationChangeSubscriptions = {}
		@_relationEventCatcher = false
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
		@setRelation name, relation

		return relation

	# Sets the current relation to a specific instance.
	# **WARNING**: *Don't use this method unless you know exactly what you're doing.*
	setRelation: (name, relation) ->
		throw new Error "Relation must be a Relation instance, #{typeof relation} supplied" unless relation instanceof Relation
		# Ignore noops.
		return @ if @_relations[name] is relation


		# NEW METHOD: copy content rather than clone.
		unless @_relations[name]
			# Clone relation to disassociate it with any other models.
			relation = relation #.clone()
			# Save it.
			@_relations[name] = relation
			# Bind event.
			subs = @_relationChangeSubscriptions
			subs[name] = relation.on "change", do (name) => (msg) =>
				relationEventCatcher = @_relationEventCatcher
				if relationEventCatcher
					relationEventCatcher name, msg.data
				else
					triggers = {}
					triggers[name] = msg.data
					@_triggerChanges triggers
		# Transfer values from supplied relation to this one.
		else
			@_relations[name].set relation

		return @

	# ID getter/setter.
	id: (id) ->
		if id?
			@_id = id
		return @_id

	# Sets one or more values.
	# Can be called with a key and value, or with an object.
	# If a `Model` instance is supplied directly, the values will be copied or cloned over directly.
	set: (keyOrObj, val) ->
		return @ unless keyOrObj
		obj = keyOrObj
		model = null
		# Prepare container to hold the old values for changed keys, which is used for triggering change events.
		triggers = {}
		handled = []
		# If we received a Model, we need to handle that specially.
		if obj instanceof Model
			model = obj
			obj = {}
			# Set ID.
			@id model.id()
			# Iterate over all foreign fields.
			for own key, otherField of model.fields
				thisField = @fields?[key]
				thisRelation = thisField?.relation # definition
				otherRelation = model.getRelation key # instance
				# If a relation exists on both.
				if thisRelation? and otherRelation?
					# Save old value.
					triggers[key] =
						oldValue: @get key
					# Clone it.
					@setRelation key, otherRelation.clone()
				# If not, get the value in case it's not stored in _values.
				else
					obj[key] = model.get key
			for own key, val of model._values
				continue if _.contains handled, key
				obj[key] = val

		# Convert a single value to an object, so we always work from an object.
		unless _.isObject obj
			obj = {}
			obj[keyOrObj] = val

		# Iterate over object.
		for own key, val of obj
			# Import field.
			field = @fields?[key]
			# Get relation.
			relation = @getRelation key
			# Add scheduled trigger event.
			unless relation?
				triggers[key] =
					oldValue: @get key
			# Run the value through optional field handler.
			if field?.change? and _.isFunction field.change
				val = field.change.call @, val
			# Set the value, checking relation.
			if relation?
				# We need to catch the change event and prevent it from immediately executing.
				# This is a bad way of doing it, but needed it fixed. @todo
				try
					@_relationEventCatcher = (field, data) => triggers[field] = data
					relation.set val
				finally
					@_relationEventCatcher = false
			else
				@_values[key] = val
		# Trigger change events.
		@_triggerChanges triggers
		return @

	# Executes change events.
	_triggerChanges: (keys) ->
		return if _.isEmpty keys
		# Fire main trigger.
		@trigger "change",
			model: @
#			keys: _.keys keys
		for own key, data of keys
			event = "change:#{key}"
			# Augment data.
			data or= {}
			data.model = @
			data.value or= @get key
			# Trigger.
			@trigger event, data
#				model: @
#				oldValue: oldVal
#				value: @get key

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
		json = {}
		# Create list of all known keys.
		keys = []
		keys.push _.keys(@_values) if _.isObject @_values
		keys.push _.keys(@fields) if _.isObject @fields
		keys = _.uniq _.flatten keys
		# Get the value of all of them. ALL OF THEM I SAY!
		for key in keys
			json[key] = @get key

		# Set ID if we have it.
		id = @id()
		if id?
			json.id = id
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

	# Returns true if all the relations are loaded.
	relationsLoaded: ->
		for own name, field of @fields
			relation = @getRelation name
			if relation? and not relation.loaded()
				return false
		return true
