sinon = require "sinon"

Discrete = require "../../discrete"
{Model, Collection, Set, RepoPersistor} = Discrete
{HasMany} = Discrete.Relation

describe "HasManyRelation", ->
	relation = null
	collection = null
	beforeEach ->
		relation = new HasMany
		collection = relation.get()

	it "should be empty when created", ->
		expect(relation.empty()).toBe true
		expect(relation.loaded()).toBe true

	it "should accept IDs given to it and register itself as not loaded", ->
		relation.add 1
		expect(relation.empty()).toBe false
		expect(relation.loaded()).toBe false

	it "should accept any number of IDs", ->
		relation.add 1, 2, [3,[4,5]]
		expect(collection.size()).toBe 5

	it "should accept Models given to it an register itself as loaded", ->
		relation.add new Model id:1
		expect(relation.empty()).toBe false
		expect(relation.loaded()).toBe true

	it "should accept both IDs and Models and register itself as not loaded", ->
		relation.add 1
		#relation.add new Model id:1
		expect(relation.empty()).toBe false
		expect(relation.loaded()).toBe false

	it "should serialize to an array of IDs from IDs", ->
		relation.add 1
		relation.add 2
		expect(JSON.stringify(relation.serialize())).toBe JSON.stringify [1,2]

	it "should serialize to an array of IDs from Models", ->
		relation.add new Model id:1
		relation.add new Model id:2
		expect(JSON.stringify(relation.serialize())).toBe JSON.stringify [1,2]

	it "should serialize to an array of IDs from both IDs and Models", ->
		relation.add new Model id:1
		relation.add 2
		relation.add new Model id:3
		relation.add 4
		expect(JSON.stringify(relation.serialize())).toBe JSON.stringify [1,2,3,4]

	it "should return the full Collection when calling get", ->
		expect(collection instanceof Collection).toBe true

	it "should overwrite IDs with their Model instances upon receiving them", ->
		relation.add 1
		relation.add 2
		relation.add 1
		expect(collection.size()).toBe 3
		model = new Model id:1
		relation.add model
		expect(collection.size()).toBe 4
		expect(collection.get 0).toBe model
		expect(collection.get 1).toBe 2
		expect(collection.get 2).toBe model
		expect(collection.get 3).toBe model


	it "should mark itself as loaded if all IDs are overwritten with models", ->
		relation.add 1
		relation.add 2
		expect(relation.loaded()).toBe false
		relation.add new Model id:1
		expect(relation.loaded()).toBe false
		relation.add new Model id:2
		expect(relation.loaded()).toBe true

	it "should support model type detection"

	it "should detect what's contained in the relation", ->
		m1 = new Model id:1
		m2 = new Model id:2
		m3 = new Model id:3
		relation.add m1
		relation.add 2
		expect(relation.contains 1).toBe true
		expect(relation.contains 2).toBe true
		expect(relation.contains 3).toBe false
		expect(relation.contains m1).toBe true
		expect(relation.contains m2).toBe true
		expect(relation.contains m3).toBe false

	it "should remove elements", ->
		# 1 :: ID - ID
		relation.add 1
		# 2 :: ID - Model
		m2 = new Model id:2
		relation.add 2
		# 3 :: Model - ID
		relation.add new Model id:3
		# 4 :: Model - Model
		m4 = new Model id:4
		relation.add m4

		expect(relation.contains 1).toBe true
		expect(relation.contains 2).toBe true
		expect(relation.contains 3).toBe true
		expect(relation.contains 4).toBe true
		expect(collection.size()).toBe 4
		# Remove 1.
		expect(relation.remove 1).toBe true
		expect(relation.contains 1).toBe false
		expect(collection.size()).toBe 3
		# Remove 2.
		expect(relation.remove m2).toBe true
		expect(relation.contains 2).toBe false
		expect(collection.size()).toBe 2
		# Remove 3.
		expect(relation.remove 3).toBe true
		expect(relation.contains 3).toBe false
		expect(collection.size()).toBe 1
		# Remove 4.
		expect(relation.remove m4).toBe true
		expect(relation.contains 4).toBe false
		expect(collection.size()).toBe 0

	it "should effeciently handle setting multiple IDs", ->
		# 1 :: ID <- ID = ID
		relation.add 1
		# 2 :: ID <- Model = Model
		relation.add 2
		m2 = new Model id:2
		# 3 :: Model <- ID = Model
		m3 = new Model id:3
		relation.add m3
		# 4 :: Model <- Model = Model
		m4 = new Model id:4
		relation.add m4
		# 5 :: undefined <- ID = ID
		# 6 :: undefined <- Model = Model
		m6 = new Model id:6
		# 7 :: ID <- undefined = null
		relation.add 7
		# 8 :: Model <- undefined = null
		m8 = new Model id:8
		relation.add m8
		# Two of the values have yet to be defined.
		expect(collection.size()).toBe 6
		# Overwrite.
		relation.set [
			1 #1
			m2 #2
			3 #3
			m4 #4
			5 #5
			m6 #6
			#7
			#8
		]
		# Check collection, this is the only way to ensure model instances have bee replaced correctly.
		expect(collection.contains 1).toBe true
		expect(collection.contains m2).toBe true
		expect(collection.contains m3).toBe true
		expect(collection.contains m4).toBe true
		expect(collection.contains 5).toBe true
		expect(collection.contains m6).toBe true
		expect(collection.size()).toBe 6

	describe "Sets", ->
		set = null
		beforeEach ->
			relation = new HasMany
				collection: Set
			set = relation.get()

		it "should use the Set collection type", ->
			expect(set instanceof Set).toBe true

		it "should not allow the same model to be added more than once", ->
			# Add the same model twice, and ensure the feature of Set is preserved.
			model = new Model id:1
			relation.add model
			relation.add model
			expect(set.size()).toBe 1
			expect(set.get 0).toBe model

		it "should not allow the same ID to be more than once", ->
			relation.add 1
			relation.add 1
			expect(relation.get().size()).toBe 1
			expect(set.get 0).toBe 1

		it "should overwrite IDs with received models", ->
			relation.add 1
			model = new Model id:1
			relation.add model
			expect(set.size()).toBe 1
			expect(set.get 0).toBe model

	describe "persistance", ->
		persistor = null
		load = null
		save = null
		done = null
		m1 = null
		m2 = null

		beforeEach ->
			persistor = new RepoPersistor
			RepoPersistor.reset()
			load = sinon.spy persistor, "load"
			save = sinon.spy persistor, "save"
			done = sinon.spy()
			m1 = RepoPersistor.add new Model id:1
			m2 = RepoPersistor.add new Model id:2

		it "should load models through the persistor", ->
			relation.add 1, 2
			relation.load persistor, done
			waitsFor (-> done.called), "Done never called", 100
			runs ->
				expect(done.callCount).toBe 1
				expect(load.callCount).toBe 2
				expect(save.callCount).toBe 0
				expect(collection.get 0).toBe m1
				expect(collection.get 1).toBe m2

		it "should not load anything if already loaded", ->
			relation.add m1, m2
			relation.load persistor, done
			waitsFor (-> done.called), "Done never called", 100
			runs ->
				expect(done.callCount).toBe 1
				expect(load.callCount).toBe 0
				expect(save.callCount).toBe 0

#		it "should save models through the persistor", ->
#			m3 = new Model id:3
#			m4 = new Model id:4
#			relation.add m3, m4
#			relation.save persistor, done
#			waitsFor (-> done.called), "Done never called", 100
#			runs ->
#				expect(done.callCount).toBe 1
#				expect(load.callCount).toBe 0
#				expect(save.callCount).toBe 2
#				repo = persistor.getRepo()
#				expect(repo.get 3).toBe m3
#				expect(repo.get 4).toBe m4
