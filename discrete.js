/*! Discrete 0.1.0-dev - MIT license */
(function() {
  var Async, Calamity, Collection, Discrete, Map, Model, Persistor, Set, calamity, exports, object_toString, root, _, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  root = this;

  if (typeof require === "function") {
    _ = require("underscore");
    calamity = require("calamity");
    Async = require("async");
  } else {
    if (typeof root._ !== "function") {
      throw new Error("Failed to load underscore from global namespace");
    }
    _ = root._;
    if (typeof root.Calamity !== "object") {
      throw new Error("Failed to load Calamity from global namespace");
    }
    Calamity = root.Calamity;
    if (typeof root.async !== "object") {
      throw new Error("Failed to load Async from global namespace");
    }
    Async = root.async;
  }

  if (typeof root._ === "undefined" && typeof require === "function") {
    _ = require("underscore");
  }

  if (typeof root.Calamity === "undefined" && typeof require === "function") {
    Calamity = require("calamity");
  }

  Discrete = {
    version: "0.1.0-dev"
  };

  if (typeof exports !== "undefined") {
    exports = Discrete;
  } else if (typeof module !== "undefined" && module.exports) {
    module.exports = Discrete;
  } else if (typeof define === "function" && define.amd) {
    define(["underscore", "calamity", "async"], Discrete);
  } else {
    root["Discrete"] = Discrete;
  }

  Discrete.Model = Model = (function() {
    Calamity.emitter(Model.prototype);

    Model.prototype.defaults = {};

    Model.prototype.relations = {};

    Model.prototype.persistor = null;

    function Model(values) {
      this._id = null;
      if ((values != null ? values.id : void 0) != null) {
        this.id(values.id);
        delete values.id;
      }
      this._values = {};
      this._persistor = null;
      values = this._defaults(values);
      this.set(values);
    }

    Model.prototype._defaults = function(values) {
      var key, val, _ref;
      if (values == null) {
        values = {};
      }
      _ref = this.defaults;
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        val = _ref[key];
        if (values[key] != null) {
          continue;
        }
        if (_.isFunction(val)) {
          values[key] = val(values);
        } else {
          values[key] = val;
        }
      }
      return values;
    };

    Model.prototype.id = function(id) {
      if (id != null) {
        this._id = id;
      }
      return this._id;
    };

    Model.prototype.set = function(keyOrObj, val) {
      var key, obj, triggers;
      if (!keyOrObj) {
        return;
      }
      obj = keyOrObj;
      if (obj instanceof Model) {
        this.id(obj.id());
        obj = obj.toJSON();
      }
      if (!_.isObject(obj)) {
        obj = {};
        obj[keyOrObj] = val;
      }
      triggers = {};
      for (key in obj) {
        if (!__hasProp.call(obj, key)) continue;
        val = obj[key];
        triggers[key] = this._values[key];
        this._values[key] = val;
      }
      this._triggerChanges(triggers);
      return this;
    };

    Model.prototype._triggerChanges = function(keys) {
      var event, key, oldVal, _results;
      this.trigger("change", {
        model: this
      });
      _results = [];
      for (key in keys) {
        if (!__hasProp.call(keys, key)) continue;
        oldVal = keys[key];
        event = "change:" + key;
        _results.push(this.trigger(event, {
          model: this,
          value: this.get(key)
        }));
      }
      return _results;
    };

    Model.prototype.get = function(key) {
      return this._values[key];
    };

    Model.prototype.keys = function() {
      return _.keys(this._values);
    };

    Model.prototype.each = function(fn) {
      var key, val, _ref;
      _ref = this._values;
      for (key in _ref) {
        val = _ref[key];
        fn.apply(this, [key, val]);
      }
      return this;
    };

    Model.prototype.toJSON = function() {
      var json;
      json = _.clone(this._values);
      if (this._id != null) {
        json.id = this._id;
      } else {
        delete json.id;
      }
      return json;
    };

    Model.prototype.serialize = function() {
      var collectionArray, field, json, relation, val, _ref;
      json = this.toJSON();
      _ref = this.relations;
      for (field in _ref) {
        if (!__hasProp.call(_ref, field)) continue;
        relation = _ref[field];
        val = json[field];
        if (val == null) {
          continue;
        }
        if (relation.collection != null) {
          if (_.isArray(val)) {
            val = new relation.collection(val);
          }
          collectionArray = [];
          val.each(function(collectionVal) {
            if (!(collectionVal instanceof relation.model)) {
              return;
            }
            return collectionArray.push(collectionVal.id());
          });
          json[field] = collectionArray;
        } else if ((relation.model != null) && val instanceof relation.model) {
          json[field] = val.id();
        }
      }
      return json;
    };

    Model.prototype.clone = function(base) {
      if (base == null) {
        base = null;
      }
      base || (base = new Model);
      base.set(this);
      return base;
    };

    Model.prototype.getPersistor = function() {
      var persistor;
      if (this._persistor == null) {
        persistor = this.persistor;
        if (!((persistor != null) && typeof persistor === "function")) {
          throw new Error("Persistor not defined");
        }
        this._persistor = new persistor();
      }
      return this._persistor;
    };

    Model.prototype.save = function(done) {
      var field, persistor, relation, val, _ref;
      persistor = this.getPersistor();
      _ref = this.relations;
      for (field in _ref) {
        if (!__hasProp.call(_ref, field)) continue;
        relation = _ref[field];
        val = this.get(field);
        if (_.isEmpty(val)) {
          continue;
        }
        if (relation.collection != null) {
          val.each(function(entry) {
            return (function(entry) {
              return _.defer(function() {
                if (entry.id() == null) {
                  return done(new Error("Entry in collection relation \"" + field + "\" does not have an ID when saving model"));
                }
              });
            })(entry);
          });
        } else {
          (function(val) {
            return _.defer(function() {
              if (val.id() == null) {
                return done(new Error("Relation \"" + field + "\" does not have an ID when saving model"));
              }
            });
          })(val);
        }
      }
      persistor.save(this, done);
      return this;
    };

    Model.prototype.fetch = function(done) {
      var current, def, fetchers, field, id, ids, persistor, relation, results, _i, _j, _len, _len1, _ref,
        _this = this;
      persistor = this.getPersistor();
      results = {};
      ids = [];
      _ref = this.relations;
      for (field in _ref) {
        if (!__hasProp.call(_ref, field)) continue;
        relation = _ref[field];
        current = this.get(field);
        if (relation.collection != null) {
          if (current instanceof relation.collection) {
            continue;
          }
          results[field] = new relation.collection;
          if (_.isEmpty(current)) {
            continue;
          }
          if (!_.isArray(current)) {
            throw new Error("" + field + " is not empty and is not an array");
          }
          for (_i = 0, _len = current.length; _i < _len; _i++) {
            id = current[_i];
            ids.push([field, id]);
          }
        } else {
          if (current instanceof relation.model) {
            continue;
          }
          if (_.isEmpty(current)) {
            continue;
          }
          ids.push([field, current]);
        }
      }
      fetchers = [];
      for (_j = 0, _len1 = ids.length; _j < _len1; _j++) {
        def = ids[_j];
        field = def[0];
        id = def[1];
        fetchers.push((function(field, id) {
          return function(done) {
            return persistor.load(id, function(err, model) {
              if (err) {
                done(err);
                return;
              }
              return done(null, [field, model]);
            });
          };
        })(field, id));
      }
      return Async.parallel(fetchers, function(err, fetchResults) {
        var model, _k, _l, _len2, _len3, _ref1;
        if (err) {
          done(err);
          return;
        }
        _ref1 = _this.relations;
        for (relation = _k = 0, _len2 = _ref1.length; _k < _len2; relation = ++_k) {
          field = _ref1[relation];
          if (relation.collection != null) {
            if (results[field] == null) {
              results[field] = new relation.collection;
            }
          }
        }
        for (_l = 0, _len3 = fetchResults.length; _l < _len3; _l++) {
          def = fetchResults[_l];
          field = def[0];
          model = def[1];
          relation = _this.relations[field];
          if (relation.collection != null) {
            results[field].add(model);
          } else {
            results[field] = model;
          }
        }
        _this.set(results);
        return done(null);
      });
    };

    return Model;

  })();

  Discrete.Collection = Collection = (function() {
    Calamity.emitter(Collection.prototype);

    function Collection(values) {
      if (values != null) {
        if (values instanceof Collection) {
          values = values.toJSON();
        }
        if (!_.isArray(values)) {
          throw new Error("Initial values for Collection must be either Array or Collection");
        }
      }
      values || (values = []);
      this._items = values;
    }

    Collection.prototype.add = function(obj) {
      this._items.push(obj);
      this.trigger("change", {
        type: "add",
        map: this,
        value: obj
      });
      return true;
    };

    Collection.prototype.remove = function(obj) {
      var index, oldVal;
      index = this._getIndex(obj);
      if (index === false) {
        return false;
      }
      oldVal = this._items.splice(index, 1)[0];
      this.trigger("change", {
        type: "remove",
        map: this,
        oldValue: oldVal
      });
      return true;
    };

    Collection.prototype.get = function(index) {
      if ((0 <= index && index < this._items.length)) {
        return this._items[index];
      }
      return null;
    };

    Collection.prototype.contains = function(obj) {
      return this._getIndex(obj) !== false;
    };

    Collection.prototype.size = function(obj) {
      return this._items.length;
    };

    Collection.prototype.isEmpty = function() {
      return this.size() === 0;
    };

    Collection.prototype.each = function(fn) {
      var entry, index, _i, _len, _ref;
      _ref = this._items;
      for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
        entry = _ref[index];
        fn.apply(this, [entry, index]);
      }
      return this;
    };

    Collection.prototype.toJSON = function() {
      var json;
      json = [];
      this.each(function(val) {
        return json.push(val);
      });
      return json;
    };

    Collection.prototype._getIndex = function(obj) {
      var entry, i, _i, _len, _ref;
      _ref = this._items;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        entry = _ref[i];
        if (entry === obj) {
          return i;
        }
      }
      return false;
    };

    return Collection;

  })();

  Discrete.Set = Set = (function(_super) {
    __extends(Set, _super);

    function Set() {
      _ref = Set.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Set.prototype.add = function(obj) {
      if (this.contains(obj)) {
        return false;
      }
      return Set.__super__.add.apply(this, arguments);
    };

    return Set;

  })(Collection);

  object_toString = {}.toString;

  Discrete.Map = Map = (function() {
    Calamity.emitter(Map.prototype);

    function Map(values) {
      var items;
      if (values != null) {
        if (!(values instanceof Map)) {
          throw new Error("Initial values must be another Map");
        }
        items = [];
        values.each(function(key, val) {
          return items.push([key, val]);
        });
        values = items;
      } else {
        values = [];
      }
      this._items = values;
    }

    Map.prototype.put = function(key, val) {
      var entry, index, oldVal, returnVal;
      index = this._getIndexForKey(key);
      entry = [key, val];
      returnVal = null;
      if (index === false) {
        this._items.push(entry);
      } else {
        oldVal = this._items[index][1];
        if (val === oldVal) {
          return null;
        }
        this._items[index] = entry;
        returnVal = oldVal;
      }
      this.trigger("change", {
        type: "put",
        map: this,
        key: key,
        value: val,
        oldValue: returnVal
      });
      return returnVal;
    };

    Map.prototype.get = function(key) {
      var index;
      index = this._getIndexForKey(key);
      if (index === false) {
        return null;
      }
      return this._items[index][1];
    };

    Map.prototype.remove = function(key) {
      var index, returnVal;
      index = this._getIndexForKey(key);
      if (index === false) {
        return null;
      }
      returnVal = this._items.splice(index, 1)[0][1];
      this.trigger("change", {
        type: "remove",
        map: this,
        key: key,
        oldValue: returnVal
      });
      return returnVal;
    };

    Map.prototype.hasKey = function(key) {
      return this._getIndexForKey(key) !== false;
    };

    Map.prototype.hasValue = function(val) {
      return this._getIndexForValue(val) !== false;
    };

    Map.prototype.each = function(fn) {
      var entry, _i, _len, _ref1;
      _ref1 = this._items;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        entry = _ref1[_i];
        fn.apply(this, entry);
      }
      return this;
    };

    Map.prototype.size = function() {
      return this._items.length;
    };

    Map.prototype.isEmpty = function() {
      return this.size() === 0;
    };

    Map.prototype.toJSON = function() {
      var json,
        _this = this;
      json = {};
      this.each(function(key, value) {
        var keyString;
        keyString = _this._getStringForKey(key);
        return json[keyString] = {
          key: key,
          value: value
        };
      });
      return json;
    };

    Map.prototype.clone = function() {
      return new Map(this);
    };

    Map.prototype._getIndexForKey = function(key) {
      var entry, i, _i, _len, _ref1;
      _ref1 = this._items;
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        entry = _ref1[i];
        if (entry[0] === key) {
          return i;
        }
      }
      return false;
    };

    Map.prototype._getIndexForValue = function(val) {
      var entry, i, _i, _len, _ref1;
      _ref1 = this._items;
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        entry = _ref1[i];
        if (entry[1] === val) {
          return i;
        }
      }
      return false;
    };

    Map.prototype._getStringForKey = function(key) {
      if (_.isObject(key)) {
        if (_.isFunction(key.toString) && key.toString !== object_toString) {
          key = key.toString();
        }
      } else {
        key = "" + key;
      }
      if (!_.isString(key)) {
        throw new Error("Failed to convert key to string");
      }
      return key;
    };

    return Map;

  })();

  Discrete.Persistor = Persistor = (function() {
    function Persistor() {}

    Persistor.prototype.save = function(model, callback) {
      throw new Error("Save not extended");
    };

    return Persistor;

  })();

}).call(this);
