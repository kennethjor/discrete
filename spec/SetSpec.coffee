_ = require "underscore"
sinon = require "sinon"
{Set} = require "../discrete"

describe "Set", ->
	# The Set works exactly like Collection, so let's only test the obvious differences.

	it "should not accept the same value twice", ->
		set = new Set
		change = sinon.spy()
		set.on "change", change
		val1 = val:1
		val2 = val:2
		expect(set.add val1).toBe true
		expect(set.add val2).toBe true
		expect(set.add val1).toBe false
		expect(set.size()).toBe 2
		expect(set.contains val1).toBe true
		expect(set.contains val2).toBe true
		waitsFor (-> change.called), "Change never triggered", 100
		runs ->
			expect(change.callCount).toBe 2
