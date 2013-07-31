sinon = require "sinon"

Discrete = require "../../discrete"
{Model, RepoPersistor} = Discrete
HasOne = Discrete.Relation.get "HasOne"

describe "HasOneRelation", ->
	relation = null
	beforeEach ->
		relation = new HasOne

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

	it "should rely on the ID of the model, if set", ->
		model = new Model id:42
		relation.set model
		expect(relation.id()).toBe 42
		# Set new value on model.
		model.id 43
		expect(relation.id()).toBe 43

	it "should serialize to IDs, and preserve data type", ->
		# Int.
		relation.set new Model id:42
		expect(relation.serialize()).toBe 42
		# String.
		relation.set new Model id:"42"
		expect(relation.serialize()).toBe "42"

	it "should support model type detection", ->
		class TestModel extends Model
			type: "TestModel"
		relation = new HasOne
			type: TestModel
		test = -> relation.set new Model
		expect(test).toThrow "Invalid model type supplied"

	describe "persistance", ->
		class PersistentModel extends Model
			persistor: RepoPersistor

		model = null
		persistor = null
		load = null
		save = null
		done = null

		beforeEach ->
			model = new PersistentModel
			persistor = model.getPersistor()
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

		it "should save model through the persistor", ->
			relation.set new Model id:1
			relation.save persistor, done
			waitsFor (-> done.called), "Done never called", 100
			runs ->
				expect(done.callCount).toBe 1
				expect(load.callCount).toBe 0
				expect(save.callCount).toBe 1
				call = load.getCall 0
				expect(call.args[0]).toBe m1.id()
				expect(relation.model()).toBe m1

