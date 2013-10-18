# A utility class for loading, saving, and managing a large number of models in a single group.
Discrete.Loader = class Loader
	constructor: (options) ->
		# Config.
		@persistor = options.persistor
		@concurrency = options.concurrency or 3
		# Containers.
		@_models = {}
		@_poll = null
		# State.
		@running = false
		@completed = false

	getPersistor: ->
		persistor = @persistor
		throw new Error "Persistor not set" unless persistor
		return persistor if persistor instanceof Persistor
		return @persistor = new persistor()

	# Adds a model to the loader.
	add: (models) ->
		throw new Error "No models supplied" unless models
		throw new Error "Expected one argument, #{arguments.length} supplied" unless arguments.length is 1
		map = {}
		# Convert collection to array.
		if models instanceof Collection
			models = models.toJSON()
		# Convert array to object.
		if _.isArray models
			for model in models
				continue unless model?
				# Models.
				if model instanceof Model
					id = model.id()
					throw new Error "Model '#{model.type}' does not have an ID" unless id?
					map[id] = model
				# IDs.
				else
					map[model] = model
		# Convert Map objects.
		else if models instanceof Map
			models.each (key, model) =>
				map[key] = model
		# Single models.
		else if models instanceof Model
			map[models.id()] = models
		# Actual map objects.
		else if _.isObject models
			for own key, val of models
				map[key] = val
		# Single stings.
		else if _.isString(models) or _.isNumber(models)
			map[models] = models
		else
			throw new Error "Models must be either Collection, array, Map, Model, Object, or string or number, '#{typeof models}' supplied"
		# Everything valid has now been converted to a simple map object, add it all to be loaded.
		for own name, model of map
			if _.isObject(model) and not (model instanceof Model)
				throw new Error "Non-model object supplied for model"
			#console.log name, model
			# Add to model container.
			@_models[name] = model
			# Push to queue.
			if @_queue and not @completed
				@_queue.push
					name: name
					model: model
		return @

	# Adds a single model to be loaded.
	# This an internal function.
	# `add()` should be used instead.
	_addSingle: (key, model) ->


	# Returns an added model.
	get: (name) ->
		return @_models[name]

	# Returns all the added models.
	getAll: ->
		return @_models

	# Set poll function.
	poll: (func) ->
		throw new Error "Poll must be a function" unless _.isFunction func
		@_poll = func

	# Runs the loader.
	load: (done) ->
		@running = true
		# Worker function.
		worker = (task, done) =>
			handlers = []
			# Load model through persistor.
			handlers.push (done) =>
				if task.model instanceof Model
					done null, task.model
				else
					@getPersistor().load task.model, (err, model) =>
						if err
							done err
							return
						# Set loaded model.
						@_models[task.name] = model
						# Pass.
						done null, model
			# Next we need to load the relation of the model.
			handlers.push (model, done) =>
				if model.relationsLoaded()
					done null, model
				else
					model.loadRelations (err) =>
						if err
							done err
							return
						done null, model
			# Finally we need to supply the prepared model to the polling function.
			handlers.push (model, done) =>
				@_poll @, task.name, model if _.isFunction @_poll
				done()
			# Execute task.
			Async.waterfall handlers, (err) =>
				if err
					done err
				else
					done null

		# Start queue.
		@_queue = queue = Async.queue worker, @concurrency
		# Drain function.
		queue.drain = =>
			@running = false
			@completed = true
			done null, @ # @todo catch errors
		# Populate queue with initial tasks.
		for own name, model of @_models
			queue.push
				name: name
				model: model

	# Saves all the known models.
	saveAll: (done) ->
		results = {}
		saveModel = (name, done) =>
			@_models[name].save (err, model) =>
				if err
					done err
				else
					results[name] = model
					done null
		Async.each _.keys(@_models), saveModel, (err) =>
			if err
				done err
			else
				@_models = results
				done null, results
