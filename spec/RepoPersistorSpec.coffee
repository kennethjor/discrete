sinon = require "sinon"

Discrete = require "../../discrete"
{RepoPersistor, Model} = Discrete

describe "RepoPersistor", ->
	persistor = null
	done = null

	beforeEach ->
		RepoPersistor.reset()
		persistor = new RepoPersistor()
		done = sinon.spy()

	it "should load models", ->
		m1 = new Model id:1
		RepoPersistor.add m1
		persistor.load 1, done
		waitsFor (-> done.called), "Done never called", 100
		runs ->
			expect(done.callCount).toBe 1
			call = done.getCall 0
			expect(call.args[0]).toBe null # error
			expect(call.args[1]).toBe m1 # model

	it "should save models", ->
		m1 = new Model id:1
		persistor.save m1, done
		waitsFor (-> done.called), "Done never called", 100
		runs ->
			expect(done.callCount).toBe 1
			call = done.getCall 0
			expect(call.args[0]).toBe null # error
			expect(call.args[1]).toBe m1 # model

	it "should not overwrite already existing models", ->
		m1 = new Model id:1
		m2 = new Model id:1 # same ID
		RepoPersistor.add m1
		persistor.save m2, done
		waitsFor (-> done.called), "Done never called", 100
		runs ->
			expect(done.callCount).toBe 1
			call = done.getCall 0
			expect(call.args[0]).toBe null # error
			expect(call.args[1]).toBe m1 # model

	it "should return an error when models don't exist", ->
		persistor.load 1, done
		waitsFor (-> done.called), "Done never called", 100
		runs ->
			expect(done.callCount).toBe 1
			call = done.getCall 0
			expect(call.args[0].message).toBe "not-found" # error
			expect(call.args[1]).toBe null # model
