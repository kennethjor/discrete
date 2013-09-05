# A `SortedMap` works just like `Map`, except elements are continously sorted according to supplied sorter.
# Loosely based on http://docs.oracle.com/javase/7/docs/api/java/util/SortedMap.html
Discrete.SortedMap = class SortedMap extends Map
	constructor: (values, sorter) ->
		if _.isFunction values
			sorter = values
			values = null
		unless _.isFunction sorter
			throw new Error "Sorter is required and must be a function, #{typeof sorter} supplied"
		@_sorter = sorter
		super values
		@_sort()

	put: ->
		r = super
		@_sort()
		return r

	remove: ->
		r = super
		@_sort()
		return r

	# Returns the first (lowest) key.
	firstKey: ->
		return null if @size() is 0
		return @_items[0][0]

	# Returns the last (highest) key.
	lastKey: ->
		s = @size()
		return null if s is 0
		return @_items[s - 1][0]

	# Internal method for sorting the internal array.
	_sort: ->
		return unless @size() > 1
		@_items.sort (a, b) =>
			return @_sorter (key:a[0],value:a[1]), (key:b[0],value:b[1])
		return undefined
