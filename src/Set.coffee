# A set is a specialized collection which will never allow the same value to exist twice.
Discrete.Set = class Set extends Collection
	# Adds an element to the collection.
	# Returns true if the element was added.
	add: (obj) ->
		return false if @contains obj
		return super

	# Adds all the supplied values.
	# Returns true if any elements were added.
	addAll: (obj...) ->
		added = []
		obj = _.flatten obj
		for o in obj
			continue if @contains o
			@_items.push o
			added.push o
		# Fire change event.
		@trigger "change",
			type: "add"
			collection: @
			value: added
		return added.length > 0
