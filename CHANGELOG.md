# Changelog

## 0.1.0 (dev)
* *API change:* `Model` is now configured with `fields` rather than `defaults` and `relations`.
* *Feature:* Added classes for handling model relations rather than having a giant `Model` class.
* *Feature:* Added `ModelRepo` and `RepoPersistor` for caching, testing, and other memory-only purposes.
* *Feature:* Implemented a field definition on `Model` called `changed`, which will be called whenever a field is modified, the return value replacing the supplied value.
* *Fix:* toJSON ignored all defined relations.

## 0.0.1 (2013-07-30)
* Initial version after splitting modelling off from Antifreeze.
