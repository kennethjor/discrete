# Initialises the global object and ties into whatever loader is present.

root = this

# Load required libs which may or may not be already defined.
if typeof require is "function"
	_ = require "underscore"
	calamity = require "calamity"
	Async = require "async"
else
	# Underscore.
	unless typeof root._ is "function"
		throw new Error "Failed to load underscore from global namespace"
	_ = root._
	# Calamity
	unless typeof root.Calamity is "object"
		throw new Error "Failed to load Calamity from global namespace"
	Calamity = root.Calamity
	# Async
	unless typeof root.async is "object"
		throw new Error "Failed to load Async from global namespace"
	Async = root.async

# Import underscore if necessary.
if typeof root._ is "undefined" and typeof require is "function"
	_ = require "underscore"
# Import calamity if necessary.
if typeof root.Calamity is "undefined" and typeof require is "function"
	Calamity = require "calamity"

# Init main object.
Discrete = version: "<%= pkg.version %>"

# CommonJS
if typeof exports isnt "undefined"
	exports = Discrete
else if typeof module isnt "undefined" and module.exports
	module.exports = Discrete
# AMD
else if typeof define is "function" and define.amd
	define ["underscore", "calamity", "async"], Discrete
# Browser
else
	root["Discrete"] = Discrete
