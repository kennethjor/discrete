_ = require "underscore"
sinon = require "sinon"
Discrete = require "../discrete"
{Model, Persistor, Collection, RepoPersistor} = Discrete
{HasMany, HasOne} = Discrete.Relation

describe "Model", ->
	model = null
	beforeEach ->
		RepoPersistor.reset()
		model = new Model

	it "should be empty when first created", ->
		json = model.toJSON()
		expect(_.keys(json).join(",")).toEqual ""

	it "should set and get values", ->
		model.set "byString", "yes"
		model.set byObject: "also"
		model.set
			multiple: "awesome"
			values: "stuff"
		expect(model.get "byString").toBe "yes"
		expect(model.get "byObject").toBe "also"
		expect(model.get "multiple").toBe "awesome"
		expect(model.get "values").toBe "stuff"

	# While this would be a nice feature, more thought needs to be put into it.
	it "should support custom getters, setters, and cloners"
	xit "should support custom getters and setters", ->
		getter = sinon.spy -> return "foo getter"
		setter = sinon.spy -> return "foo setter"
		clone =  sinon.spy -> return "foo clone"
		class CustomModel extends Model
			fields:
				foo:
					getter: getter
					setter: setter
					clone: clone
		model = new CustomModel
		model.set foo: "test"
		expect(model._values.foo).toBe "foo setter"
		expect(model.get "foo").toBe "foo getter"
		# Verify getter.
		expect(getter.callCount).toBe 1
		getCall = getter.getCall 0
		expect(getCall.args[0])
		# Verify setter.
		expect(setter.callCount).toBe 1

	it "should get and set deep object values"
	# model.set "first.second", val
	# And fire change events.

	it "should accept initial values", ->
		model = new Model
			id: "id:42"
			foo: "foo"
			bar: "bar"
		expect(model.id()).toBe "id:42"
		expect(model.get "id").toBe undefined
		expect(model.get "foo").toBe "foo"
		expect(model.get "bar").toBe "bar"

	it "should copy values when setting a whole model", ->
		other = new Model
			id: "id:42"
			foo: "FOO"
		model.set other
		expect(model.id()).toBe other.id()
		expect(model.get "foo").toBe other.get "foo"

	it "should provide a list of keys", ->
		model = new Model
			foo: "FOO"
			bar: "BAR"
		keys = model.keys()
		expect(keys.length).toBe 2
		expect(_.contains(keys, "foo")).toBe true
		expect(_.contains(keys, "bar")).toBe true

	it "should provide an iteration function", ->
		model.set
			foo: "FOO"
			bar: "BAR"
		i = 0
		model.each (key, val) ->
			switch i
				when 0
					expect(key).toBe "foo"
					expect(val).toBe "FOO"
				when 1
					expect(key).toBe "bar"
					expect(val).toBe "BAR"
			i++
		expect(i).toBe 2

	it "should execute optional change function on field changes"

	describe "default values", ->
		class Test extends Model
			fields:
				foo:
					"default": "FOO"
				bar:
					"default": "BAR"

		it "should be applied when creating the model", ->
			model = new Test
			expect(model.get "foo").toBe "FOO"
			expect(model.get "bar").toBe "BAR"

		it "should be overridden by initially supplied values", ->
			model = new Test
				bar: "other"
			expect(model.get "foo").toBe "FOO"
			expect(model.get "bar").toBe "other"

	# @todo merge change event tests in with normal tests.
	describe "change events", ->
		change = null
		changeEvent = null
		changeFoo = null
		changeFooEvent = null
		beforeEach ->
			# General change event.
			change = sinon.spy (event) -> changeEvent = event
			model.on "change", change
			changeEvent = null
			# Specific change event.
			changeFoo = sinon.spy (event) -> changeFooEvent = event
			model.on "change:foo", changeFoo
			changeFooEvent = null

		it "should should trigger specific and general change events with appropriate data", ->
			model.set foo: "bar"
			waitsFor (-> change.called and changeFoo.called), "Events not fired", 100
			runs ->
				expect(change.callCount).toBe 1
				expect(changeFoo.callCount).toBe 1
				expect(typeof changeEvent).toBe "object"
				expect(typeof changeFooEvent).toBe "object"
				expect(changeEvent.data.model).toBe model
				expect(changeFooEvent.data.model).toBe model
				expect(changeFooEvent.data.value).toBe "bar"

		it "should change all values before triggering events when multiple values are changed", ->
			model.set
				foo: "foo"
				bar: "bar"
			waitsFor (-> change.called), "Event not fired", 100
			runs ->
				expect(change.callCount).toBe 1

		it "should report the old value"
		it "should issue change events even if nothing changed"

	describe "toJSON", ->
		it "should convert to a json object", ->
			model = new Model
				foo: "bar"
				abc: "def"
			json = model.toJSON()
			expect(json.foo).toBe "bar"
			expect(json.abc).toBe "def"

		it "should not recursively serialize models", ->
			model = new Model
				foo: "foo"
				bar: new Model
					qwerty: "zxcvbn"
			json = model.toJSON()
			expect(typeof json).toBe "object"
			expect(json.foo).toBe "foo"
			expect(json.bar instanceof Model).toBe true

		it "should serialize the explicitly set id value and ignore any values set with set()", ->
			model.set id: "invalid"
			expect(model.toJSON().id).toBe undefined
			model.id "valid"
			expect(model.toJSON().id).toBe "valid"

	describe "cloning", ->
		beforeEach ->
			model = new Model
				id: "id:42"
				foo: "Foo"
				bar: "Bar"

		it "should clone all values", ->
			clone = model.clone()
			expect(clone).not.toBe model
			expect(clone.id()).toBe model.id()
			expect(clone.get "foo").toBe model.get "foo"
			expect(clone.get "bar").toBe model.get "bar"

		it "should not recursively clone values", ->
			model2 = new Model x:1
			model.set model2: model2
			clone = model.clone()
			expect(clone.get "model2").toBe model2

		it "should accept a base model object and clone into that rather than creating a new one", ->
			base = new Model()
			clone = model.clone base
			expect(clone).toBe base
			expect(clone).not.toBe model
			expect(clone.id()).toBe model.id()
			expect(clone.get "foo").toBe model.get "foo"
			expect(clone.get "bar").toBe model.get "bar"

	describe "persistance", ->
		save = null
		load = null
		done = null

		class PersistorModel extends Model
			persistor: RepoPersistor

		beforeEach ->
			model = new PersistorModel id:1
			save = sinon.spy model.getPersistor(), "save"
			load = sinon.spy model.getPersistor(), "load"
			done = sinon.spy()

		it "should complain if not persistor is defined", ->
			model = new Model
			test = ->
				model.save()
			expect(test).toThrow "Persistor not defined"

		it "should auto-construct the persistor, but keep a single instance around", ->
			persistor = model.getPersistor()
			expect(typeof persistor).toBe "object"
			expect(persistor instanceof RepoPersistor).toBe true
			expect(model.getPersistor()).toBe persistor

		it "should use the supplied persistor if an instance is supplied rather than a constructor", ->
			persistor = new RepoPersistor
			model.persistor = persistor
			expect(model.getPersistor()).toBe persistor

		it "should save through the persistor", ->
			model.save(done)
			waitsFor (-> done.called), "Done never called", 100
			runs ->
				expect(save.callCount).toBe 1
				# Verify save was called correctly on the persistor.
				saveCall = save.getCall 0
				expect(saveCall.args[0]).toBe model
				# Verify callback was supplied no error and the saved model.
				doneCall = done.getCall 0
				expect(doneCall.args[0]).toBe null # error
				expect(doneCall.args[1]).toBe model

	describe "relations", ->
		change = null
		changeFoo = null
		changeBar = null
		class RelationalModel extends Model
			persistor: RepoPersistor
			fields:
				foo:
					relation: "HasOne"
				bar:
					relation: "HasMany"
			clone: ->
				super new RelationalModel

		beforeEach ->
			model = new RelationalModel id:99
			change = sinon.spy()
			changeFoo = sinon.spy()
			changeBar = sinon.spy()
			model.on "change", change
			model.on "change:foo", changeFoo
			model.on "change:bar", changeBar

		it "should return relation handlers", ->
			foo = model.getRelation "foo"
			bar = model.getRelation "bar"
			expect(typeof foo).toBe "object"
			expect(typeof bar).toBe "object"
			expect(foo instanceof HasOne).toBe true
			expect(bar instanceof HasMany).toBe true

		it "should set and return relation values", ->
			m1 = new Model id:1
			model.set foo:m1
			expect(model.getRelation("foo").get()).toBe m1
			expect(model.get "foo").toBe m1

		it "should copy relations when setting model directly", ->
			m1 = new Model id:1
			m2 = new Model id:2
			m3 = new Model id:3
			model.getRelation("foo").set m1
			model.getRelation("bar").add m2
			model.getRelation("bar").add m3
			expect(model.get("foo")).toBe m1
			expect(model.get("bar").size()).toBe 2
			# Set on new model.
			model2 = new RelationalModel()
			model2.set model
			expect(model2.getRelation("foo").id()).toBe 1
			expect(model2.getRelation("foo").model()).toBe m1
			expect(model2.get("foo")).toBe m1
			expect(model2.get("bar").size()).toBe 2

		it "should convert to JSON", ->
			m1 = new Model id:1
			model.set foo:m1
			json = model.toJSON()
			expect(json.foo).toBe m1

		it "should serialize to IDs", ->
			model.getRelation("foo").set new Model id:1
			model.getRelation("bar").add new Model id:1
			model.getRelation("bar").add new Model id:2
			serial = model.serialize()
			expect(serial.foo).toBe 1
			expect(serial.bar[0]).toBe 1
			expect(serial.bar[1]).toBe 2

		it "should clone object references", ->
			m1 = new Model id:1
			m2 = new Model id:2
			m3 = new Model id:3
			model.set
				foo: m1
				bar: [m2, m3]
			clone = model.clone()
			expect(clone.get "foo").toBe m1
			bar = clone.get("bar").toJSON()
			expect(bar).toContain m2
			expect(bar).toContain m3

		it "should clone object IDs", ->
			model.set
				foo: 1
				bar: [2, 3]
			clone = model.clone()
			cloneFoo = clone.getRelation "foo"
			cloneBar = clone.getRelation "bar"
			expect(cloneFoo.id()).toBe 1
			expect(cloneBar.contains 2).toBe true
			expect(cloneBar.contains 3).toBe true

		describe "change events", ->
			m1 = new Model id:1
			m2 = new Model id:2

			it "should fire when setting HasOne", ->
				relation = model.getRelation "foo"
				model.set foo: m1
				#model.set foo: 1
				waitsFor (->changeFoo.called), "Change never called", 100
				runs ->
					expect(changeFoo.callCount).toBe 1
					expect(change.callCount).toBe 1
					data = changeFoo.getCall(0).args[0].data
					expect(data.model).toBe model
					expect(data.value).toBe relation.get()

			it "should fire when setting HasMany", ->
				relation = model.getRelation "bar"
				model.set bar: [m1, m2]
				waitsFor (->changeBar.called), "Change never called", 100
				runs ->
					expect(changeBar.callCount).toBe 1
					expect(change.callCount).toBe 1
					data = changeBar.getCall(0).args[0].data
					expect(data.model).toBe model
					expect(data.value).toBe relation.get()


			it "should fire when adding to HasMany", ->
				relation = model.getRelation "bar"
				relation.add m1, m2
				waitsFor (->changeBar.called), "Change never called", 100
				runs ->
					expect(changeBar.callCount).toBe 1
					expect(change.callCount).toBe 1
					data = changeBar.getCall(0).args[0].data
					expect(data.model).toBe model
					expect(data.value).toBe relation.get()

		describe "persistence", ->
			m1 = new Model id:1
			m2 = new Model id:2
			m3 = new Model id:3
			done = null

			beforeEach ->
				done = sinon.spy()

			it "should load through the persistor", ->
				RepoPersistor.add m1, m2, m3
				model.set "foo", 1
				model.set "bar", [2,3]
				model.loadRelations done
				waitsFor (-> done.called), "Done never called", 100
				runs ->
					expect(done.callCount).toBe 1
					expect(model.get "foo").toBe m1
					bar = model.get "bar"
					expect(bar.get 0).toBe m2
					expect(bar.get 1).toBe m3

#			describe "should save", -> # no, relations really shouldn't be saved like this ... @todo
#				beforeEach ->
#					model.set "foo", m1
#					model.set "bar", [m1, m2]
#
#				it "through the persistor", ->
#					model.saveRelations done
#					waitsFor (-> done.called), "Done never called", 100
#					runs ->
#						expect(done.callCount).toBe 1
#						repo = model.getPersistor().getRepo()
#						expect(repo.get 99).toBe null
#						expect(repo.get 1).toBe m1
#						expect(repo.get 2).toBe m2
#						expect(repo.get 3).toBe m3
#
#				it "individual relations through the persistor", ->
#					model.saveRelations "bar", done
#					waitsFor (-> done.called), "Done never called", 100
#					runs ->
#						expect(done.callCount).toBe 1
#						repo = model.getPersistor().getRepo()
#						expect(repo.get 99).toBe null
#						expect(repo.get 1).toBe null
#						expect(repo.get 2).toBe m2
#						expect(repo.get 3).toBe m3
