sinon = require "sinon"

Discrete = require "../../discrete"
{Model} = Discrete
{HasOne} = Discrete.Relation

TestPersistor = require "../TestPersistor"

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
		expect(relation.get()).toBe null
		# Strings
		relation.set "id:42"
		expect(relation.loaded()).toBe false
		expect(relation.empty()).toBe false
		expect(relation.id()).toBe "id:42"
		expect(relation.get()).toBe null

	it "should accept Models given to it an register itself as loaded", ->
		model = new Model id:42
		relation.set model
		expect(relation.loaded()).toBe true
		expect(relation.empty()).toBe false
		expect(relation.id()).toBe 42
		expect(relation.get()).toBe model

	it "should serialize to IDs", ->
		model = new Model id:42
		relation.set model
		expect(relation.serialize()).toBe "42"

	it "should support model type detection", ->
		class TestModel extends Model
			type: "TestModel"
		relation = new HasOne
			type: TestModel
		test = -> relation.set new Model
		expect(test).toThrow "Invalid model type supplied, \"TestModel\" expected"

	describe "persistance", ->
		it "should load model through the persistor"
		it "should not load anything if already loaded"
		it "should save model through the persistor"
