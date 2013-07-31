sinon = require "sinon"

{ModelRepo, Model} = require "../../discrete"

describe "ModelRepo", ->
	repo = null
	beforeEach ->
		repo = new ModelRepo

	it "should be empty when created", ->
		expect(repo.size()).toBe 0

	it "should store and reteive models", ->
		m1 = new Model id:1
		m2 = new Model id:2
		expect(repo.put m1).toBe m1
		expect(repo.put m2).toBe m2
		expect(repo.size()).toBe 2
		expect(repo.get 1).toBe m1
		expect(repo.get 2).toBe m2

	it "should return null if models are not found", ->
		expect(repo.get 1).toBe null

	it "should complain if stored models do not have an ID", ->
		test = ->
			repo.put new Model
		expect(test).toThrow "Models stored in ModelRepo must have an ID set"

	it "should return the existing model if a model with the same ID is supplied", ->
		overwrite = sinon.spy repo, "handleOverwrite"
		m1 = new Model id:1
		m2 = new Model id:1
		repo.put m1
		expect(overwrite.callCount).toBe 0
		expect(repo.put m2).toBe m1
		# Verify overwrite method usage.
		expect(overwrite.callCount).toBe 1
		call = overwrite.getCall 0
		expect(call.args[0]).toBe m1
		expect(call.args[1]).toBe m2
		expect(call.returnValue).toBe m1
