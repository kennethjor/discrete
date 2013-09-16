sinon = require "sinon"

Discrete = require "../../discrete"
{Model, RepoPersistor} = Discrete
{HasOne} = Discrete.Relation

describe "HasOneRelation", ->
	relation = null
	change = null
	beforeEach ->
		relation = new HasOne
		change = sinon.spy()
		relation.on "change", change

	it "should be empty when created", ->
		expect(relation.empty()).toBe true
		expect(relation.loaded()).toBe true

	it "should accept IDs given to it and register itself as not loaded", ->
		# Numbers
		relation.set 42
		expect(relation.loaded()).toBe false
		expect(relation.empty()).toBe false
		expect(relation.id()).toBe 42
		expect(relation.model()).toBe null
		expect(relation.get()).toBe null
		# Strings
		relation.set "id:42"
		expect(relation.loaded()).toBe false
		expect(relation.empty()).toBe false
		expect(relation.id()).toBe "id:42"
		expect(relation.model()).toBe null

	it "should accept Models given to it an register itself as loaded", ->
		model = new Model id:42
		relation.set model
		expect(relation.loaded()).toBe true
		expect(relation.empty()).toBe false
		expect(relation.id()).toBe 42
		expect(relation.model()).toBe model
		expect(relation.get()).toBe model

	it "should rely on the ID of the model, if set", ->
		model = new Model id:42
		relation.set model
		expect(relation.id()).toBe 42
		# Set new value on model.
		model.id 43
		expect(relation.id()).toBe 43

	it "should not lose the model if ID is being set", ->
		model = new Model id:42
		relation.set model
		expect(relation.model()).toBe model
		# Set new ID.
		relation.id 42
		expect(relation.model()).toBe model

	it "should preserve model instances when being set by another relation", ->
		model = new Model id:42
		relation = new HasOne
		relation.set 42
		newRelation = new HasOne
		newRelation.set model
		relation.set newRelation
		expect(relation.id()).toBe 42
		expect(relation.model()).toBe model
		expect(relation.get()).toBe model

	it "should not lose model instances when being set by another relation", ->
		model = new Model id:42
		model = new Model id:42
		relation = new HasOne
		relation.set model
		newRelation = new HasOne
		newRelation.set 42
		relation.set newRelation
		expect(relation.id()).toBe 42
		expect(relation.model()).toBe model
		expect(relation.get()).toBe model

	it "should serialize to IDs, and preserve data type", ->
		# Int.
		relation.set new Model id:42
		expect(relation.serialize()).toBe 42
		# String.
		relation.set new Model id:"42"
		expect(relation.serialize()).toBe "42"

	it "should support model type detection", ->
		class TestModel extends Model
		relation = new HasOne
			model: TestModel
		test = -> relation.set new Model
		expect(test).toThrow "Invalid model type supplied"

	it "should fire change events when setting an ID", ->
		relation.set 1
		waitsFor (-> change.called), "Change never called", 100
		runs ->
			expect(change.callCount).toBe 1
			data = change.getCall(0).args[0].data
			expect(data.relation).toBe relation
			expect(data.id).toBe 1
			expect(data.value).toBe null

	it "should fire change events when setting a model", ->
		m1 = new Model id:1
		relation.set m1
		waitsFor (-> change.called), "Change never called", 100
		runs ->
			expect(change.callCount).toBe 1
			data = change.getCall(0).args[0].data
			expect(data.relation).toBe relation
			expect(data.id).toBe 1
			expect(data.value).toBe m1

	it "should not trigger change on handlers assigned after the event", ->
		newChange = sinon.spy()
		relation.set 1
		relation.on "change", newChange
		waitsFor (->change.called), "Change never called", 100
		runs ->
			expect(change.callCount).toBe 1
			expect(newChange.callCount).toBe 0

	it "should not trigger a change when an ID is assigned, but model is already present", ->
		m1 = new Model id:1
		relation.set m1
		relation.set 1
		waitsFor (-> change.called), "Change never called", 100
		runs ->
			#console.log change.args[0][0].data
			#console.log change.args[1][0].data
			expect(change.callCount).toBe 1
			call = change.getCall 0
			expect(call.args[0].data.oldValue).toBe null
			expect(call.args[0].data.value).toBe m1



	describe "cloning", ->
		m1 = new Model id:1

		it "should handle a model", ->
			relation.set m1
			clone = relation.clone()
			expect(clone).not.toBe relation
			expect(clone.id()).toBe 1
			expect(clone.model()).toBe m1
			expect(clone.get()).toBe m1
			# Modify from original, should not affect clone.
			relation.set 2
			expect(clone.get()).toBe m1

		it "should handle an ID", ->
			relation.set 1
			clone = relation.clone()
			expect(clone).not.toBe relation
			expect(clone.id()).toBe 1
			expect(clone.model()).toBe null
			expect(clone.get()).toBe null
			# Modify from original, should not affect clone.
			relation.set 2
			expect(clone.id()).toBe 1

	describe "persistance", ->
		persistor = null
		load = null
		save = null
		done = null

		beforeEach ->
			persistor = new RepoPersistor
			RepoPersistor.reset()
			load = sinon.spy persistor, "load"
			save = sinon.spy persistor, "save"
			done = sinon.spy()

		it "should load the model through the persistor", ->
			m1 = RepoPersistor.add new Model id:1
			relation.set 1
			relation.load persistor, done
			waitsFor (-> done.called), "Done never called", 100
			runs ->
				expect(done.callCount).toBe 1
				expect(load.callCount).toBe 1
				expect(save.callCount).toBe 0
				call = load.getCall 0
				expect(call.args[0]).toBe m1.id()
				expect(relation.model()).toBe m1

		it "should not load anything if already loaded", ->
			relation.set new Model id:1
			relation.load persistor, done
			waitsFor (-> done.called), "Done never called", 100
			runs ->
				expect(done.callCount).toBe 1
				expect(load.callCount).toBe 0
				expect(save.callCount).toBe 0

#		it "should save model through the persistor", ->
#			relation.set new Model id:1
#			relation.save persistor, done
#			waitsFor (-> done.called), "Done never called", 100
#			runs ->
#				expect(done.callCount).toBe 1
#				expect(load.callCount).toBe 0
#				expect(save.callCount).toBe 1
#				call = load.getCall 0
#				expect(call.args[0]).toBe m1.id()
#				expect(relation.model()).toBe m1

