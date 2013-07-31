sinon = require "sinon"

Discrete = require "../../discrete"
{Model, Collection, Set} = Discrete
{HasMany} = Discrete.Relation

TestPersistor = require "../TestPersistor"

describe "HasManyRelation", ->
	relation = null
	beforeEach ->
		relation = new HasMany

	it "should be empty when created", ->
		expect(relation.empty()).toBe true
		expect(relation.loaded()).toBe true

	it "should accept IDs given to it and register itself as not loaded"
	it "should accept Models given to it an register itself as loaded"
	it "should serialize to IDs"
	it "should support multiple collection types"
	it "should support model type detection"

	describe "persistance", ->
		it "should load models through the persistor"
		it "should not load anything if already loaded"
		it "should save models through the persistor"
