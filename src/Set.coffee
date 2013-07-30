# A set is a specialized collection which will never allow the same value to exist twice.
Discrete.Set = class Set extends Collection
	# Adds an element to the collection.
	# Returns true if the element was added.
	add: (obj) ->
		return false if @contains obj
		return super
