_ = require "underscore"
sinon = require "sinon"
{Map, Model} = require "../discrete"

describe "Map", ->
	map = null
	key1 = key:1
	key2 = key:2
	val1 = val:1
	val2 = val:2

	beforeEach ->
		map = new Map

	it "should be empty when first created", ->
		expect(map.size()).toBe 0

	it "should add new values", ->
		expect(map.put key1, val1).toBe null
		expect(map.size()).toBe 1

	it "should overwrite existing values and return the old value when doing so", ->
		map.put key1, val1
		# Existing value should not change anything.
		expect(map.put key1, val1).toBe null
		# New value should return old one.
		expect(map.put key1, val2).toBe val1
		# Check size.
		expect(map.size()).toBe 1

	it "should remove values", ->
		map.put key1, val1
		expect(map.remove key1).toBe val1

	it "should accept initial Map values and make a copy", ->
		map1 = new Map
		map1.put "key1", 1
		map1.put "key2", 2
		# Make a copy.
		map2 = new Map map1
		expect(map2.size()).toBe 2
		# Add entry to old map, new map should remain the same.
		map1.put "key3", 3
		expect(map2.size()).toBe 2

	it "should allow iteration", ->
		map.put "key0", "val0"
		map.put "key1", "val1"
		map.put "key2", "val2"
		i = 0
		map.each (key, val) ->
			expect(key).toBe "key"+i
			expect(val).toBe "val"+i
			i++
		expect(i).toBe 3

	it "should clone", ->
		map.put key1, val1
		map.put key2, val2
		map2 = map.clone()
		expect(map2).not.toBe map
		expect(map2.size()).toBe 2
		expect(map2.get key1).toBe val1
		expect(map2.get key2).toBe val2
		map.put {key:3}, "foo"
		expect(map.size()).toBe 3
		expect(map2.size()).toBe 2

	describe "change events", ->
		change = null

		beforeEach ->
			change = sinon.spy()
			map.on "change", change

		it "should trigger when adding an element", ->
			map.put "key1", "val1"
			waitsFor (-> change.called), "Change not triggered", 100
			runs ->
				expect(change.callCount).toBe 1
				event = change.args[0][0]
				expect(event.data.type).toBe "put"
				expect(event.data.value).toBe "val1"

		it "should trigger when overwriting an element", ->
			map.put "key1", "val1"
			map.put "key1", "val2"
			waitsFor (-> change.called), "Change not triggered", 100
			runs ->
				expect(change.callCount).toBe 2
				# Check first call.
				data = change.args[0][0].data
				expect(data.type).toBe "put"
				expect(data.value).toBe "val1"
				expect(data.oldValue).toBe null
				# Check second call.
				data = change.args[1][0].data
				expect(data.type).toBe "put"
				expect(data.value).toBe "val2"
				expect(data.oldValue).toBe "val1"

		it "should not trigger when overwriting an element with the same value", ->
			map.put "key1", "val1"
			map.put "key1", "val1"
			waitsFor (-> change.called), "Change not triggered", 100
			runs ->
				expect(change.callCount).toBe 1

		it "should trigger change events when removing an element", ->
			map.put "key1", "val1"
			map.remove "key1"
			expect(map.size()).toBe 0
			waitsFor (-> change.called), "Change not triggered", 100
			runs ->
				expect(change.callCount).toBe 2
				# Check second call, which was the remove.
				data = change.args[1][0].data
				expect(data.type).toBe "remove"
				expect(data.value).toBe undefined
				expect(data.oldValue).toBe "val1"

	describe "serialization", ->
		class Obj
			constructor: (@i) ->
			toString: -> @i

		beforeEach ->
			map.put new Obj("key1"), new Obj("val1")
			map.put new Obj("key2"), new Obj("val2")

		it "should serialize to a json object", ->
			json = map.toJSON()
			expect(typeof json).toBe "object"
			expect(json.key1.key.toString()).toBe "key1"
			expect(json.key1.value.toString()).toBe "val1"
			expect(json.key2.key.toString()).toBe "key2"
			expect(json.key2.value.toString()).toBe "val2"

		it "should complain if key objects cannot convert to strings", ->
			key = {key:1} # Default Object.toString is not ignored.
			map.put key, "val"
			expect(-> map.toJSON()).toThrow new Error "Failed to convert key to string"

		it "should not recursively serialize models", ->
			map.put "key", new Model
				key: "val"
			json = map.toJSON()
			expect(json.key.value instanceof Model).toBe true
