# A simple `Persistor` which uses a local `ModelRepo` for storage.
# This maintains a static "database", so multiple instances have access to the same data.
Discrete.RepoPersistor = class RepoPersistor extends Persistor
	# Static DB.
	repo = null

	# Convenience method for quickly adding models to the database.
	# Any array combination and multiple arguments are accepted.
	# Added models will automatically be configured to use this persistor.
	@add = (models...) ->
		models = _.flatten [arguments]
		for m in models
			repo.put m
			m.persistor = @
		return models[0]

	# Resets the DB.
	@reset = ->
		repo = new ModelRepo
	@reset()

	# Loads a model.
	load: (id, callback) ->
		model = repo.get id
		unless model?
			err = new Error("not-found")
			do (err) -> _.defer -> callback err, null
#			callback new Error("not-found"), null
			return
		if _.isFunction callback
			do (model) -> _.defer -> callback null, model
#			callback null, model

	# Saves a model.
	save: (model, callback) ->
		id = model.id()
		model = repo.put model
		if _.isFunction callback
			do (model) -> _.defer -> callback null, model

	# Returns the repo.
	getRepo: ->
		return repo
