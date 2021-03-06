{Relation, Model} = require "../../discrete"

describe "Relation", ->
	class TestRelation extends Relation
	Relation.register "Test", TestRelation

	it "should register custom relations", ->
		expect(Relation.register "Test", TestRelation).toBe TestRelation
		expect(Relation.Test).toBe TestRelation

	it "should construct relations from strings", ->
		relation = Relation.create "Test"
		expect(typeof relation).toBe "object"
		expect(relation instanceof TestRelation).toBe true

	it "should construct relations from constructors", ->
		relation = Relation.create TestRelation
		expect(typeof relation).toBe "object"
		expect(relation instanceof TestRelation).toBe true

	it "should construct relations from objects", ->
		relation = Relation.create
			type: "Test"
			model: Model
		expect(relation instanceof TestRelation).toBe true
		expect(relation.options.model).toBe Model

	it "should complain if requested relation doesn't exist", ->
		test = ->
			Relation.create "No"
		expect(test).toThrow "Unknown relation type: \"No\""
