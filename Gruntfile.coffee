files = [
	"src/init.coffee"
	"src/Model.coffee"
	"src/Collection.coffee"
	"src/Set.coffee"
	"src/Map.coffee"
	"src/Persistor.coffee"
	"src/Relation.coffee"
	"src/Relation/HasOneRelation.coffee"
	"src/Relation/HasManyRelation.coffee"
	"src/ModelRepo.coffee"
	"src/RepoPersistor.coffee"
	"src/Loader.coffee"
]

module.exports = (grunt) ->
	grunt.initConfig
		pkg: grunt.file.readJSON "package.json"

		coffee:
			# Compiles all files to check for compilation errors.
			all:
				expand: true
				cwd: ""
				src: ["src/**/*.coffee", "spec/**/*.coffee"]
				dest: "build/"
				ext: ".js"

			# Compiles the framework into a single JS file.
			framework:
				files:
					"build/discrete.js": files
				options:
					join: true

		jessie:
			all:
				expand: true
				cwd: ""
				src: "build/spec/**/*.js"

		coffeelint:
			src:
				files:
					src: files
			options: require "./coffeelint.coffee"

		concat:
			# Packages the final JS file with a header
			dist:
				options:
					banner: "/*! <%= pkg.fullname %> <%= pkg.version %> - MIT license */\n"
					process: true
				src: ["build/discrete.js"]
				dest: "build/discrete.js"

		copy:
			# Copies the built dist file to the root for npm packaging
			dist:
				files:
					"discrete.js": "build/discrete.js"

		watch:
			files: ["src/**", "spec/**"]
			tasks: "default"

	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-concat"
	grunt.loadNpmTasks "grunt-contrib-copy"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-jessie"
	grunt.loadNpmTasks "grunt-coffeelint"

	grunt.registerTask "default", [
		"coffee:all"
		"coffee:framework"
		"concat:dist"
		"copy:dist"
		"jessie"
		"coffeelint"
	]
