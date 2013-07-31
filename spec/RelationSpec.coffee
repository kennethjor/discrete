{Relation} = require "../../discrete"

describe "Relation", ->
	class TestRelation extends Relation

	it "should register and return custom relations", ->
		Relation.register "Test", TestRelation
		expect(Relation.get "Test").toBe TestRelation
		expect(Relation.Test).toBe TestRelation

	it "should return the relation when registering", ->
		expect(Relation.register "Test", TestRelation).toBe TestRelation

	xit "should complain if requested relation doesn't exist", ->
		test = ->
			Relation.get "No"
		expect(test).toThrow "Unknown relation type: \"No\""
