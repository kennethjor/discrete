sinon = require "sinon"

{ModelRepo, Model} = require "../../discrete"

describe "ModelRepo", ->
	repo = null
	beforeEach ->
		repo = new ModelRepo

	it "should be empty when created", ->
		expect(repo.size()).toBe 0

	it "should store and reteive models", ->
		m1 = repo.put new Model id:1
		m2 = repo.put new Model id:2
		expect(m1.id()).toBe 1
		expect(m1.id()).toBe 2
		expect(repo.size()).toBe 2
		expect(repo.get 1).toBe m1
		expect(repo.get 2).toBe m2

	it "should return null if models are not found", ->
		expect(repo.get 1).toBe null
