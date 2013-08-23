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
	add: (name, model) ->
		throw new Error "Models cannot be added to a completed Loader" if @completed
		# No custom name and model
		if name instanceof Model
			model = name
			name = model.id()
		# Single ID.
		else if not (name instanceof Model) and not model?
			model = name
		# Add to model container.
		@_models[name] = model
		# Push to queue.
		if @_queue
			@_queue.push
				name: name
				model: model
		return @

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
				throw err if err
				done()

		# Start queue.
		@_queue = queue = Async.queue worker, @concurrency
		# Drain function.
		queue.drain = =>
			@running = false
			@completed = true
			done @
		# Populate queue with initial tasks.
		for own name, model of @_models
			queue.push
				name: name
				model: model
