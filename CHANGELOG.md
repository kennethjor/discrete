# Changelog

## 0.1.0 (dev)
* *API change:* `Model` is now configured with `fields` rather than `defaults` and `relations`.
* *Feature:* Added classes for handling model relations rather than having a giant `Model` class.
* *Feature:* Added `ModelRepo` and `RepoPersistor` for caching, testing, and other memory-only purposes.
* *Feature:* Implemented a field definition on `Model` called `changed`, which will be called whenever a field is modified, the return value replacing the supplied value.
* *Feature:* Implemented `contains()` and `removeByIndex()` on `Collection`.
* *Feature:* Implemented `contains()`, `remove()` on `HasManyRelation`.
* *Feature:* Relations issue change events which a proxied through the model as well.
* *Feature:* `Loader` implementation to help loader many and multiple levels of models. ([pull/1][pull/1])
* *Fix:* toJSON ignored all defined relations.
* *Fix:* `HasManyRelation` will no longer lose existing `Model` instances when set with a list of IDs.
* *Fix:* Old value was not supplied on `Model` change events.
* *Fix:* `Collection` can now add and remove entries during iteration.

## 0.0.1 (2013-07-30)
* Initial version after splitting modelling off from Antifreeze.

[pull/1]: https://bitbucket.org/kennethjor/discrete/pull-request/1 "Loader implementation."
