Discrete.Collection = class Collection
	Calamity.emitter @prototype

	constructor: (values) ->
		# Process initial values.
		if values?
			# Convert supplied collection to array.
			if values instanceof Collection
				values = values.toJSON()
			# Complain if not array supplied array.
			unless _.isArray values
				throw new Error "Initial values for Collection must be either Array or Collection"
		# Prepare container.
		@_items = []
		# Default.
		values or= []
		@addAll values

	# Adds an element to the collection.
	# Returns true if the element was added.
	add: (obj) ->
		@_items.push obj
		# Fire change event.
		@trigger "change",
			type: "add"
			collection: @
			value: obj
		return true

	# Adds all the supplied values.
	# Returns true if any elements were added.
	addAll: (obj...) ->
		obj = _.flatten obj
		for o in obj
			@_items.push o
		# Fire change event.
		@trigger "change",
			type: "add"
			collection: @
			value: obj
		return true

	# Removes a element from the collection.
	# Returns true if the collection was altered by the remove.
	remove: (obj) ->
		index = @getIndexForValue(obj)
		return false if index is false
		return @removeByIndex index

	# Removes an element from a specific index.
	# Returns true if the collection was altered as a result of this call.
	removeByIndex: (index) ->
		return false unless 0 <= index < @_items.length
		# Remove element.
		oldVal = @_items.splice(index, 1)[0]
		# Fire change event.
		@trigger "change",
			type: "remove"
			collection: @
			oldValue: oldVal
		# Return old value.
		return true


	# Removes everything in the collection.
	removeAll: ->
		@_items = []
		# Fire change event.
		@trigger "change",
			type: "remove"
			collection: @

	# Returns the object at the specified index, or null if it doesn't exist.
	get: (index) ->
		if 0 <= index < @_items.length
			return @_items[index]
		return null

	# Returns true of this collection contains the supplied element.
	contains: (obj) ->
		return @getIndexForValue(obj) isnt false

	# Returns the sizxe of the collection.
	size: (obj) ->
		return @_items.length

	# Replaces all instances of one value with another.
	# Returns the number of entries which were replaces.
	replace: (oldObj, newObj) ->
		replaced = 0
		for o, i in @_items
			if o is oldObj
				@_items[i] = newObj
				replaced++
		return replaced

	# Returns true if the collection is empty.
	isEmpty: ->
		return @size() is 0

	# Iterator.
	each: (fn) ->
		for entry, index in @_items
			fn.apply @, [entry, index]
		return @

	toJSON: ->
		json = []
		@each (val) ->
			json.push val
		return json

	# Returns the internal array index for the object, or false if it not found.
	getIndexForValue: (obj) ->
		for entry, i in @_items
			if entry is obj
				return i
		return false
