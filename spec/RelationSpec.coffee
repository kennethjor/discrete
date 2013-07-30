{Relation} = require "../../discrete"

describe "Relation", ->
	class TestRelation extends Relation

	it "should register and return custom relations", ->
		Relation.register "Test", TestRelation
		expect(Relation.get "Test").toBe TestRelation
		expect(Relation.Test).toBe TestRelation

	it "should return the relation when registering", ->
		expect(Relation.register "Test", TestRelation).toBe TestRelation

	it "should complain if supplied relation doesn't extend Relation", ->
		class NotRelation
		test = ->
			Relation.register "No", NotRelation
		expect(test).toThrow "Supplied relation \"No\" does not extend Relation"
