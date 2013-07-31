# Represents a relation on a model which links to multiple other models.
Relation.register "HasMany", class HasManyRelation extends Relation
	constructor: (options) ->
		super
		options or= {}
