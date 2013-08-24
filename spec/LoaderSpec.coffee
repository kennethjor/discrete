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
			forward: m3.id()
			back: m1.id()
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
		expect(loader.add "foo", "id:1").toBe loader
		expect(loader.get "foo").toBe "id:1"
		# No custom index and model.
		expect(loader.add m1).toBe loader
		expect(loader.get "id:111").toBe m1
		expect(loader.get "id:222").toBeUndefined()
		# With custom index and model.
		expect(loader.add "test", m2).toBe loader
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
		loader.add "m1", "id:111"
		loader.poll poll = sinon.spy (loader, name, model) ->
			if name is "m1"
				loader.add "m2", model.get "forward"
		loader.load done
		waitsFor (-> done.called), "Done never called", 100
		runs ->
			# Done.
			expect(done.callCount).toBe 1
			expect(done.args[0][0]).toBe loader
			# Poll.
			expect(poll.callCount).toBe 2
			expect(poll.args[0][0]).toBe loader
			expect(poll.args[0][1]).toBe "m1"
			expect(poll.args[0][2]).toBe m1
			expect(poll.args[1][0]).toBe loader
			expect(poll.args[1][1]).toBe "m2"
			expect(poll.args[1][2]).toBe m2
			# Check relations.
			expect(m1.relationsLoaded()).toBe true
			expect(m2.relationsLoaded()).toBe true
			expect(m3.relationsLoaded()).toBe false # m3 was never explicitly added, and thus not loaded.
			# Saved.
			expect(loader.get "m1").toBe m1
			expect(loader.get "m2").toBe m2
