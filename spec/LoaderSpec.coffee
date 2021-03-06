_ = require "underscore"
sinon = require "sinon"

{Loader, Model, RepoPersistor, Collection, Map} = require "../discrete"

describe "Loader", ->
	class RelationModel extends Model
		fields:
			forward: relation: "HasOne"
			back: relation: "HasOne"
	m1 = m2 = m3 = null
	loader = null
	poll = null
	done = null

	beforeEach ->
		RepoPersistor.reset()
		# m1 <-> m2 <-> m3
		RepoPersistor.add m1 = new RelationModel id:"id:111"
		RepoPersistor.add m2 = new RelationModel id:"id:222"
		RepoPersistor.add m3 = new RelationModel id:"id:333"
		m1.set
			forward: m2.id()
		m2.set
			back: m1.id()
			forward: m3.id()
		m3.set
			back: m2.id()
		# Loader.
		poll = sinon.spy()
		done = sinon.spy()
		loader = new Loader
			persistor: new RepoPersistor
		loader.poll poll

	it "should accept models and remember them", ->
		# No custom index and id.
		expect(loader.add "id:0").toBe loader
		expect(loader.add "id:0").toBe loader
		expect(loader.get "id:0").toBe "id:0"
		# With custom index and id.
		expect(loader.add foo: "id:1").toBe loader
		expect(loader.get "foo").toBe "id:1"
		# No custom index and model.
		expect(loader.add m1).toBe loader
		expect(loader.get "id:111").toBe m1
		expect(loader.get "id:222").toBeUndefined()
		# With custom index and model.
		expect(loader.add test: m2).toBe loader
		expect(loader.get "test").toBe m2
		expect(loader.get "id:222").toBeUndefined()
		# Return all.
		models = loader.getAll()
		expect(models["id:0"]).toBe "id:0"
		expect(models.foo).toBe "id:1"
		expect(models["id:111"]).toBe m1
		expect(models.test).toBe m2

	it "should accept arrays of Models", ->
		expect(loader.add [m1, m2]).toBe loader
		expect(loader.get "id:111").toBe m1
		expect(loader.get "id:222").toBe m2
		expect(loader.get "id:333").toBeUndefined()

	it "should accept objects of Models", ->
		expect(loader.add (m1:m1, m2:m2)).toBe loader
		expect(loader.get "m1").toBe m1
		expect(loader.get "m2").toBe m2
		expect(loader.get "m3").toBeUndefined()
		expect(loader.get "id:333").toBeUndefined()

	it "should accept Collections of Models", ->
		expect(loader.add new Collection [m1, m2]).toBe loader
		expect(loader.get "id:111").toBe m1
		expect(loader.get "id:222").toBe m2
		expect(loader.get "id:333").toBeUndefined()

	it "should accept Maps of Models", ->
		map = new Map
		map.put "m1", m1
		map.put "m2", m2
		expect(loader.add map).toBe loader
		expect(loader.get "m1").toBe m1
		expect(loader.get "m2").toBe m2
		expect(loader.get "m3").toBeUndefined()
		expect(loader.get "id:333").toBeUndefined()

	it "should load IDs, load relations, and poll on completion", ->
		loader.add m1: "id:111"
		# Create spies on the loadRelation functions.
		m1loadRelations = sinon.spy m1, "loadRelations"
		m2loadRelations = sinon.spy m2, "loadRelations"
		m3loadRelations = sinon.spy m3, "loadRelations"
		# When m1 is loaded, add the forward relation, which is m2.
		loader.poll poll = sinon.spy (loader, name, model) ->
			if name is "m1"
				id = model.getRelation("forward").id()
				loader.add m2: id
		loader.load done
		waitsFor (-> done.called), "Done never called", 100
		runs ->
			# Loader should never call loadRelations.
			expect(m1loadRelations.callCount).toBe 0
			expect(m2loadRelations.callCount).toBe 0
			expect(m3loadRelations.callCount).toBe 0
			# Done should be called once with no error and the loader as argument.
			expect(done.callCount).toBe 1
			expect(done.args[0][0]).toBe null
			expect(done.args[0][1]).toBe loader
			# Poll should be called twice, once with `m1` and one with `m2`.
			expect(poll.callCount).toBe 2
			expect(poll.args[0][0]).toBe loader
			expect(poll.args[0][1]).toBe "m1"
			expect(poll.args[0][2]).toBe m1
			expect(poll.args[1][0]).toBe loader
			expect(poll.args[1][1]).toBe "m2"
			expect(poll.args[1][2]).toBe m2
			# `m1` relations.
#			expect(m1.get "forward").toBe m2 # loaded explicitly.
#			expect(m1.relationsLoaded()).toBe true # m2 was added explicitly.
			# `m2` relations.
#			expect(m2.get "back").toBe m1 # loaded explicitly.
#			expect(m2.get "forward").toBe m3.id() # not loaded explicitly.
#			expect(m2.relationsLoaded()).toBe false # m1 was added, but m3 wasn't.
			# `m3` relations.
#			expect(m3.get "back").toBe m2.id() # not loaded explicitly. Theoretically this should come from the repo or something. Future feature.
#			expect(m3.relationsLoaded()).toBe false # m3 was never explicitly added, and thus not loaded.
			# Check contents.
			expect(loader.get "m1").toBe m1
			expect(loader.get "m2").toBe m2
			expect(loader.get "m3").toBe undefined

	it "should not start fetching more models when loading is completed", ->
		loader.load done
		loader.add m1: "id:111"
		waitsFor (-> done.called), "Done never called", 100
		defer = sinon.spy()
		runs ->
			expect(done.callCount).toBe 1
			loader.add m2: "id:222"
			expect(done.callCount).toBe 1
			_.defer defer
		waitsFor (-> defer.called), "Defer never called", 100
		runs ->
			expect(done.callCount).toBe 1

	it "should save known models", ->
		sinon.spy m1, "save"
		sinon.spy m2, "save"
		sinon.spy m3, "save"
		loader.add [m1, m2]
		saved = sinon.spy()
		loader.saveAll saved
		waitsFor (-> saved.called), "Saved never called", 100
		runs ->
			expect(saved.callCount).toBe 1
			expect(m1.save.callCount).toBe 1
			expect(m2.save.callCount).toBe 1
			expect(m3.save.callCount).toBe 0
			models = saved.args[0][1]
			expect(models["id:111"]).toBe m1
			expect(models["id:222"]).toBe m2
			expect(models["id:333"]).toBeUndefined()

	it "should complain if adding non-models", ->
		test = -> loader.add index: {}
		expect(test).toThrow "Non-model object supplied for model"

	it "should complain when adding models wrong", ->
		expect(-> loader.add "key", "val").toThrow "Expected one argument, 2 supplied"
