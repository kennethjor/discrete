_ = require "underscore"
{Persistor} = require "../discrete"

# Simple memory `Persistor` used for testing.
module.exports = class TestPersistor extends Persistor
	_db = {}

	TestPersistor.add = (models...) ->
		models = _.flatten [arguments]
		for m in models
			id = m.id()
			_db[id] = m
			m.persistor = TestPersistor
		return models[0]

	@reset = ->
		_db = {}

	load: (id, callback) ->
		unless _db[id]?
			_.defer -> callback new Error "not-found"
			return
		if _.isFunction callback
			_.defer => callback null, _db[id]

	save: (model, callback) ->
		id = model.id()
		_db[id] = model
		if _.isFunction callback
			_.defer -> callback null
