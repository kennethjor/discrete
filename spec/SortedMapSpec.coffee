_ = require "underscore"
sinon = require "sinon"
{SortedMap, Map, Model} = require "../discrete"

describe "SortedMap", ->
	map = null
	sorter = null
	key1 = name:"Alice",   age:42
	key2 = name:"Bob",     age:43
	key3 = name:"Charlie", age:44
	val1 = floor:1, salary:1000
	val2 = floor:2, salary:2000
	val3 = floor:3, salary:3000

	beforeEach ->
		sorter = sinon.spy (a, b) ->
			return a.key.age - b.key.age
		map = new SortedMap sorter

	it "should be empty when first created", ->
		expect(map.size()).toBe 0

	it "should use sorter to evaluate order", ->
		expect(sorter.callCount).toBe 0
		map.put key1, val1
		map.put key2, val2
		expect(sorter.callCount).toBe 1
		expect(sorter.args[0][0].key).toBe key1
		expect(sorter.args[0][0].value).toBe val1
		expect(sorter.args[0][1].key).toBe key2
		expect(sorter.args[0][1].value).toBe val2

	it "should return the first and the last element", ->
		# Empty.
		expect(map.firstKey()).toBe null
		expect(map.lastKey()).toBe null
		# Add three entries.
		map.put key1, val1
		expect(map.firstKey()).toBe key1
		expect(map.lastKey()).toBe key1
		map.put key2, val2
		expect(map.firstKey()).toBe key1
		expect(map.lastKey()).toBe key2
		map.put key3, val3
		expect(map.firstKey()).toBe key1
		expect(map.lastKey()).toBe key3
		# Remove two entries.
		map.remove key3
		expect(map.firstKey()).toBe key1
		expect(map.lastKey()).toBe key2
		map.remove key1
		expect(map.firstKey()).toBe key2
		expect(map.lastKey()).toBe key2

	it "should sort initially", ->
		oldMap = new Map
		oldMap.put key2, val2
		oldMap.put key3, val3
		oldMap.put key1, val1
		map = new SortedMap oldMap, sorter
		expect(map.firstKey()).toBe key1
		expect(map.lastKey()).toBe key3
