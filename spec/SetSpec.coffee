_ = require "underscore"
sinon = require "sinon"
{Set} = require "../discrete"

describe "Set", ->
	# The Set works exactly like Collection, so let's only test the obvious differences.
	set = null
	change = null
	val1 = val:1
	val2 = val:2

	beforeEach ->
		set = new Set
		change = sinon.spy()
		set.on "change", change

	it "should not accept the same value twice", ->
		expect(set.add val1).toBe true
		expect(set.add val2).toBe true
		expect(set.add val1).toBe false
		expect(set.size()).toBe 2
		expect(set.contains val1).toBe true
		expect(set.contains val2).toBe true
		waitsFor (-> change.called), "Change never triggered", 100
		runs ->
			expect(change.callCount).toBe 2

	it "should not construct with the same value twice", ->
		set = new Set [val1, val2, val1]
		expect(set.size()).toBe 2

	it "should replace values", ->
		set = new Set ["a", "b", "c"]
		expect(set.replace "b", "x").toBe 1
		expect(set.get 0).toBe "a"
		expect(set.get 1).toBe "x"
		expect(set.get 2).toBe "c"
