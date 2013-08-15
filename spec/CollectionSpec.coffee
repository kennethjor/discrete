_ = require "underscore"
sinon = require "sinon"
{Collection, Model} = require "../discrete"

describe "Collection", ->
	collection = null
	val1 = val:1
	val2 = val:2
	val3 = val:3
	beforeEach ->
		collection = new Collection

	it "should be empty when first created", ->
		expect(collection.size()).toBe 0

	it "should add new values given to it", ->
		expect(collection.add val1).toBe true
		expect(collection.size()).toBe 1
		# Add new value.
		expect(collection.add val2).toBe true
		expect(collection.size()).toBe 2
		# Add first value again.
		expect(collection.add val1).toBe true
		expect(collection.size()).toBe 3
		# Check correct contains.
		expect(collection.contains val1).toBe true
		expect(collection.contains val2).toBe true
		expect(collection.contains val3).toBe false

	it "should return specific values", ->
		collection.add val1
		expect(collection.get 0).toBe val1
		expect(collection.get 1).toBe null
		expect(collection.get -1).toBe null

	it "should remove values by index"
		# removeByIndex

	it "should remove values", ->
		# Remove non-existant value.
		expect(collection.remove val1).toBe false
		# Remove existing value.
		collection.add val2
		expect(collection.remove val2).toBe true

	it "should accept initial array values", ->
		collection = new Collection [val1, val2]
		expect(collection.size()).toBe 2
		expect(collection.contains val1).toBe true
		expect(collection.contains val2).toBe true
		expect(collection.contains val3).toBe false

	it "should accept initial Collection values and make a copy", ->
		collection1 = new Collection [val1, val2]
		collection2 = new Collection collection1
		collection1.add val3
		expect(collection2.size()).toBe 2
		expect(collection2.contains val3).toBe false

	it "should allow iteration", ->
		vals = [val1, val2, val3]
		collection = new Collection vals
		i = 0
		collection.each (val, key) ->
			expect(key).toBe i
			expect(val).toBe vals[i]
			i++
		expect(i).toBe 3

	it "should replace values", ->
		collection = new Collection ["a", "b", "c", "b"]
		expect(collection.replace "b", "x").toBe 2
		expect(collection.get 0).toBe "a"
		expect(collection.get 1).toBe "x"
		expect(collection.get 2).toBe "c"
		expect(collection.get 3).toBe "x"

	it "should clone", ->
		collection.addAll val1, val2
		clone = collection.clone()
		expect(clone).not.toBe collection
		expect(clone.size()).toBe 2
		# Modify original, should not affect clone.
		collection.add val3
		expect(clone.size()).toBe 2

	describe "change events", ->
		change = null
		changeEvent = null
		beforeEach ->
			change = sinon.spy (event) -> changeEvent = event
			changeEvent = null
			collection.on "change", change

		it "should trigger when adding an element", ->
			collection.add val1
			waitsFor (-> change.called), "Change not triggered", 100
			runs ->
				expect(change.callCount).toBe 1
				expect(changeEvent.data.type).toBe "add"
				expect(changeEvent.data.value).toBe val1

		it "should trigger when removing an element", ->
			collection.add val1
			collection.remove val1
			waitsFor (-> change.called), "Change not triggered", 100
			runs ->
				expect(change.callCount).toBe 2
				expect(changeEvent.data.type).toBe "remove"
				expect(changeEvent.data.value).toBe undefined
				expect(changeEvent.data.oldValue).toBe val1

	describe "serialization", ->
		beforeEach ->
			collection = new Collection [
				"foo",
				new Model
					bar: "bar"
			]

		it "should serialize to a json array and not recursively serialize contained models", ->
			json = collection.toJSON()
			expect(_.isArray json).toBe true
			expect(json.length).toBe 2
			expect(json[0]).toBe "foo"
			expect(json[1] instanceof Model).toBe true
