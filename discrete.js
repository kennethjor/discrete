/*! Discrete 0.1.0-dev.9 - MIT license */
(function() {
  var Async, Calamity, Collection, Discrete, HasManyRelation, HasOneRelation, Loader, Map, Model, ModelRepo, Persistor, Relation, RepoPersistor, Set, SortedMap, calamity, exports, object_toString, root, _, _ref, _ref1,
    __hasProp = {}.hasOwnProperty,
    __slice = [].slice,
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
    version: "0.1.0-dev.9"
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

    Model.prototype.fields = null;

    Model.prototype.persistor = null;

    function Model(values) {
      this._values = {};
      this._relations = {};
      this._id = null;
      if ((values != null ? values.id : void 0) != null) {
        this.id(values.id);
        delete values.id;
      }
      this._relationChangeSubscriptions = {};
      this._relationEventCatcher = false;
      values = this._defaults(values);
      this.set(values);
    }

    Model.prototype._defaults = function(values) {
      var field, name, val, _ref;
      if (values == null) {
        values = {};
      }
      _ref = this.fields;
      for (name in _ref) {
        if (!__hasProp.call(_ref, name)) continue;
        field = _ref[name];
        if (field["default"] === void 0) {
          continue;
        }
        val = field["default"];
        if (values[name] != null) {
          continue;
        }
        if (_.isFunction(val)) {
          values[name] = val(values);
        } else {
          values[name] = val;
        }
      }
      return values;
    };

    Model.prototype.getRelation = function(name) {
      var current, field, relation;
      if (!this.fields) {
        return null;
      }
      field = this.fields[name];
      if (field == null) {
        return null;
      }
      relation = field.relation;
      if (relation == null) {
        return null;
      }
      current = this._relations[name];
      if (current != null) {
        return current;
      }
      relation = Relation.create(relation);
      this.setRelation(name, relation);
      return relation;
    };

    Model.prototype.setRelation = function(name, relation) {
      var subs,
        _this = this;
      if (!(relation instanceof Relation)) {
        throw new Error("Relation must be a Relation instance, " + (typeof relation) + " supplied");
      }
      if (this._relations[name] === relation) {
        return this;
      }
      if (!this._relations[name]) {
        relation = relation;
        this._relations[name] = relation;
        subs = this._relationChangeSubscriptions;
        subs[name] = relation.on("change", (function(name) {
          return function(msg) {
            var relationEventCatcher, triggers;
            relationEventCatcher = _this._relationEventCatcher;
            if (relationEventCatcher) {
              return relationEventCatcher(name, msg.data);
            } else {
              triggers = {};
              triggers[name] = msg.data;
              return _this._triggerChanges(triggers);
            }
          };
        })(name));
      } else {
        this._relations[name].set(relation);
      }
      return this;
    };

    Model.prototype.id = function(id) {
      if (id != null) {
        this._id = id;
      }
      return this._id;
    };

    Model.prototype.set = function(keyOrObj, val) {
      var field, handled, key, model, obj, otherField, otherRelation, relation, thisField, thisRelation, triggers, _ref, _ref1, _ref2, _ref3,
        _this = this;
      if (!keyOrObj) {
        return this;
      }
      obj = keyOrObj;
      model = null;
      triggers = {};
      handled = [];
      if (obj instanceof Model) {
        model = obj;
        obj = {};
        this.id(model.id());
        _ref = model.fields;
        for (key in _ref) {
          if (!__hasProp.call(_ref, key)) continue;
          otherField = _ref[key];
          thisField = (_ref1 = this.fields) != null ? _ref1[key] : void 0;
          thisRelation = thisField != null ? thisField.relation : void 0;
          otherRelation = model.getRelation(key);
          if ((thisRelation != null) && (otherRelation != null)) {
            triggers[key] = {
              oldValue: this.get(key)
            };
            this.setRelation(key, otherRelation.clone());
          } else {
            obj[key] = model.get(key);
          }
        }
        _ref2 = model._values;
        for (key in _ref2) {
          if (!__hasProp.call(_ref2, key)) continue;
          val = _ref2[key];
          if (_.contains(handled, key)) {
            continue;
          }
          obj[key] = val;
        }
      }
      if (!_.isObject(obj)) {
        obj = {};
        obj[keyOrObj] = val;
      }
      for (key in obj) {
        if (!__hasProp.call(obj, key)) continue;
        val = obj[key];
        field = (_ref3 = this.fields) != null ? _ref3[key] : void 0;
        relation = this.getRelation(key);
        if (relation == null) {
          triggers[key] = {
            oldValue: this.get(key)
          };
        }
        if (((field != null ? field.change : void 0) != null) && _.isFunction(field.change)) {
          val = field.change.call(this, val);
        }
        if (relation != null) {
          try {
            this._relationEventCatcher = function(field, data) {
              return triggers[field] = data;
            };
            relation.set(val);
          } finally {
            this._relationEventCatcher = false;
          }
        } else {
          this._values[key] = val;
        }
      }
      this._triggerChanges(triggers);
      return this;
    };

    Model.prototype._triggerChanges = function(keys) {
      var data, event, key, _results;
      if (_.isEmpty(keys)) {
        return;
      }
      this.trigger("change", {
        model: this
      });
      _results = [];
      for (key in keys) {
        if (!__hasProp.call(keys, key)) continue;
        data = keys[key];
        event = "change:" + key;
        data || (data = {});
        data.model = this;
        data.value || (data.value = this.get(key));
        _results.push(this.trigger(event, data));
      }
      return _results;
    };

    Model.prototype.get = function(key) {
      var relation;
      relation = this.getRelation(key);
      if (relation != null) {
        return relation.get();
      }
      return this._values[key];
    };

    Model.prototype.keys = function() {
      var keys;
      keys = _.keys(this._values);
      keys = _.union(keys, _.keys(this._relations));
      return keys;
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
      var id, json, key, keys, _i, _len;
      json = {};
      keys = [];
      if (_.isObject(this._values)) {
        keys.push(_.keys(this._values));
      }
      if (_.isObject(this.fields)) {
        keys.push(_.keys(this.fields));
      }
      keys = _.uniq(_.flatten(keys));
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        key = keys[_i];
        json[key] = this.get(key);
      }
      id = this.id();
      if (id != null) {
        json.id = id;
      } else {
        delete json.id;
      }
      return json;
    };

    Model.prototype.serialize = function() {
      var field, json, name, relation, _ref;
      json = this.toJSON();
      _ref = this.fields;
      for (name in _ref) {
        if (!__hasProp.call(_ref, name)) continue;
        field = _ref[name];
        relation = this.getRelation(name);
        if (relation != null) {
          json[name] = relation.serialize();
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
      persistor = this.persistor;
      if (persistor == null) {
        throw new Error("Persistor not defined");
      }
      if (persistor instanceof Persistor) {
        return persistor;
      }
      this.persistor = new persistor;
      return this.persistor;
    };

    Model.prototype.save = function(done) {
      return this.getPersistor().save(this, done);
    };

    Model.prototype.loadRelations = function(done) {
      var fetchers, field, name, persistor, relation, _ref;
      persistor = this.getPersistor();
      fetchers = [];
      _ref = this.fields;
      for (name in _ref) {
        if (!__hasProp.call(_ref, name)) continue;
        field = _ref[name];
        relation = this.getRelation(name);
        if (!relation) {
          continue;
        }
        fetchers.push((function(relation) {
          return function(done) {
            return relation.load(persistor, done);
          };
        })(relation));
      }
      return Async.parallel(fetchers, done);
    };

    Model.prototype.relationsLoaded = function() {
      var field, name, relation, _ref;
      _ref = this.fields;
      for (name in _ref) {
        if (!__hasProp.call(_ref, name)) continue;
        field = _ref[name];
        relation = this.getRelation(name);
        if ((relation != null) && !relation.loaded()) {
          return false;
        }
      }
      return true;
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
      this._items = [];
      values || (values = []);
      this.addAll(values);
    }

    Collection.prototype.add = function(obj) {
      this._items.push(obj);
      this.trigger("change", {
        type: "add",
        collection: this,
        value: obj
      });
      return true;
    };

    Collection.prototype.addAll = function() {
      var o, obj, _i, _len;
      obj = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      obj = _.flatten(obj);
      for (_i = 0, _len = obj.length; _i < _len; _i++) {
        o = obj[_i];
        this._items.push(o);
      }
      this.trigger("change", {
        type: "add",
        collection: this,
        value: obj
      });
      return true;
    };

    Collection.prototype.remove = function(obj) {
      var index;
      index = this.getIndexForValue(obj);
      if (index === false) {
        return false;
      }
      return this.removeByIndex(index);
    };

    Collection.prototype.removeByIndex = function(index) {
      var oldVal;
      if (!((0 <= index && index < this._items.length))) {
        return false;
      }
      oldVal = this._items.splice(index, 1)[0];
      this.trigger("change", {
        type: "remove",
        collection: this,
        oldValue: oldVal
      });
      return true;
    };

    Collection.prototype.removeAll = function() {
      this._items = [];
      return this.trigger("change", {
        type: "remove",
        collection: this
      });
    };

    Collection.prototype.get = function(index) {
      if ((0 <= index && index < this._items.length)) {
        return this._items[index];
      }
      return null;
    };

    Collection.prototype.contains = function(obj) {
      return this.getIndexForValue(obj) !== false;
    };

    Collection.prototype.size = function(obj) {
      return this._items.length;
    };

    Collection.prototype.replace = function(oldObj, newObj) {
      var i, o, replaced, _i, _len, _ref;
      replaced = 0;
      _ref = this._items;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        o = _ref[i];
        if (o === oldObj) {
          this._items[i] = newObj;
          replaced++;
        }
      }
      return replaced;
    };

    Collection.prototype.isEmpty = function() {
      return this.size() === 0;
    };

    Collection.prototype.each = function(fn) {
      var entry, index, _i, _len, _ref;
      _ref = _.clone(this._items);
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

    Collection.prototype.getIndexForValue = function(obj) {
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

    Collection.prototype.clone = function(base) {
      if (base == null) {
        base = new Collection;
      }
      base.addAll(this.toJSON());
      return base;
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

    Set.prototype.addAll = function() {
      var added, o, obj, _i, _len;
      obj = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      added = [];
      obj = _.flatten(obj);
      for (_i = 0, _len = obj.length; _i < _len; _i++) {
        o = obj[_i];
        if (this.contains(o)) {
          continue;
        }
        this._items.push(o);
        added.push(o);
      }
      this.trigger("change", {
        type: "add",
        collection: this,
        value: added
      });
      return added.length > 0;
    };

    Set.prototype.clone = function(base) {
      if (base == null) {
        base = new Set;
      }
      return Set.__super__.clone.call(this, base);
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

    Map.prototype.keys = function() {
      var keys;
      keys = [];
      this.each(function(key, val) {
        return keys.push(key);
      });
      return keys;
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

  Discrete.SortedMap = SortedMap = (function(_super) {
    __extends(SortedMap, _super);

    function SortedMap(values, sorter) {
      if (_.isFunction(values)) {
        sorter = values;
        values = null;
      }
      if (!_.isFunction(sorter)) {
        throw new Error("Sorter is required and must be a function, " + (typeof sorter) + " supplied");
      }
      this._sorter = sorter;
      SortedMap.__super__.constructor.call(this, values);
      this._sort();
    }

    SortedMap.prototype.put = function() {
      var r;
      r = SortedMap.__super__.put.apply(this, arguments);
      this._sort();
      return r;
    };

    SortedMap.prototype.remove = function() {
      var r;
      r = SortedMap.__super__.remove.apply(this, arguments);
      this._sort();
      return r;
    };

    SortedMap.prototype.firstKey = function() {
      if (this.size() === 0) {
        return null;
      }
      return this._items[0][0];
    };

    SortedMap.prototype.lastKey = function() {
      var s;
      s = this.size();
      if (s === 0) {
        return null;
      }
      return this._items[s - 1][0];
    };

    SortedMap.prototype._sort = function() {
      var _this = this;
      if (!(this.size() > 1)) {
        return;
      }
      this._items.sort(function(a, b) {
        return _this._sorter({
          key: a[0],
          value: a[1]
        }, {
          key: b[0],
          value: b[1]
        });
      });
      return void 0;
    };

    return SortedMap;

  })(Map);

  Discrete.Persistor = Persistor = (function() {
    function Persistor() {}

    Persistor.prototype.save = function(model, callback) {
      throw new Error("Save not extended");
    };

    Persistor.prototype.load = function(model, callback) {
      throw new Error("Load not extended");
    };

    return Persistor;

  })();

  Discrete.Relation = Relation = (function() {
    Calamity.emitter(Relation.prototype);

    function Relation(options) {
      this.options = options != null ? options : {};
    }

    Relation.prototype.verifyType = function(model) {
      var options;
      options = this.options;
      if ((options.model != null) && model instanceof options.model !== true) {
        throw new Error("Invalid model type supplied");
      }
      return true;
    };

    Relation.prototype.empty = function() {
      throw new Error("empty() not extended");
    };

    Relation.prototype.loaded = function() {
      throw new Error("loaded() not extended");
    };

    Relation.prototype.serialize = function() {
      throw new Error("serialize() not extended");
    };

    Relation.prototype.clone = function() {
      throw new Error("Clone not extended");
    };

    Relation.prototype.load = function(persistor, callback) {
      throw new Error("Load not extended");
    };

    Relation.prototype.save = function(persistor, callback) {
      throw new Error("Save not extended");
    };

    Relation.prototype._triggerChange = function(data) {
      data.relation = this;
      return this.trigger("change", data);
    };

    /*
       STATIC METHODS.
    */


    Relation.register = function(name, func) {
      var _base;
      this[name] = func;
      (_base = func.prototype).clone || (_base.clone = (function(func) {
        return new func(this.options);
      })(func));
      return func;
    };

    Relation.create = function(options) {
      var relation, type;
      type = null;
      if (_.isString(options) || _.isFunction(options)) {
        type = options;
        options = {};
      } else if (_.isObject(options)) {
        type = options.type;
      } else {
        throw new Error("Options must be either string, function, or object");
      }
      if (_.isString(type)) {
        if (this[type] == null) {
          throw new Error("Unknown relation type: \"" + type + "\"");
        }
        type = this[type];
      }
      if (type == null) {
        throw new Error("No relation type found");
      }
      relation = new type(options);
      return relation;
    };

    return Relation;

  })();

  Relation.register("HasOne", HasOneRelation = (function(_super) {
    __extends(HasOneRelation, _super);

    function HasOneRelation(options) {
      if (options == null) {
        options = {};
      }
      HasOneRelation.__super__.constructor.apply(this, arguments);
      this._id = null;
      this._model = null;
    }

    HasOneRelation.prototype.set = function(modelOrId) {
      var change, id, model, oldId, oldModel;
      oldId = this.id();
      oldModel = this.model();
      id = null;
      model = null;
      change = false;
      if (modelOrId instanceof HasOneRelation) {
        modelOrId = modelOrId.model() || modelOrId.id();
      }
      if (modelOrId instanceof Model) {
        this.verifyType(modelOrId);
        this._model = model = modelOrId;
        this._id = id = model.id();
        if (model !== oldModel) {
          change = true;
        }
      } else {
        this._id = id = modelOrId;
        if ((oldModel != null) && id !== oldId) {
          this._model = null;
          change = true;
        }
      }
      if (id !== oldId) {
        change = true;
      }
      if (change) {
        return this._triggerChange({
          id: id,
          oldId: oldId,
          value: this.get(),
          oldValue: oldModel
        });
      }
    };

    HasOneRelation.prototype.id = function() {
      if (this._model) {
        return this._model.id();
      } else {
        return this._id;
      }
    };

    HasOneRelation.prototype.model = function() {
      return this._model;
    };

    HasOneRelation.prototype.get = function() {
      return this.model() || this.id();
    };

    HasOneRelation.prototype.empty = function() {
      return this._id == null;
    };

    HasOneRelation.prototype.loaded = function() {
      return this.empty() || (this._model != null);
    };

    HasOneRelation.prototype.serialize = function() {
      return this.id();
    };

    HasOneRelation.prototype.clone = function(base) {
      if (base == null) {
        base = new HasOneRelation;
      }
      base.set(this.model() || this.id());
      return base;
    };

    HasOneRelation.prototype.load = function(persistor, done) {
      var _this = this;
      if (this.empty()) {
        _.defer(function() {
          return done(null, null);
        });
        return;
      }
      if (this.loaded()) {
        _.defer(function() {
          return done(null, _this.model());
        });
        return;
      }
      return persistor.load(this.id(), function(err, model) {
        if (err) {
          _.defer(function() {
            return done(err, null);
          });
          return;
        }
        _this.set(model);
        return _.defer(function() {
          return done(null, model);
        });
      });
    };

    return HasOneRelation;

  })(Relation));

  Relation.register("HasMany", HasManyRelation = (function(_super) {
    __extends(HasManyRelation, _super);

    function HasManyRelation() {
      var _base;
      HasManyRelation.__super__.constructor.apply(this, arguments);
      (_base = this.options).collection || (_base.collection = Collection);
      this._ids = new this.options.collection;
      this._models = new this.options.collection;
    }

    HasManyRelation.prototype.add = function() {
      var added, modelOrId;
      modelOrId = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      added = this._add(modelOrId);
      if (added) {
        this._triggerChange({
          operation: "add"
        });
      }
      return added;
    };

    HasManyRelation.prototype._add = function() {
      var added, id, m, model, modelOrId, _i, _len;
      modelOrId = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      modelOrId = _.flatten(modelOrId);
      if (modelOrId.length > 1) {
        added = false;
        for (_i = 0, _len = modelOrId.length; _i < _len; _i++) {
          m = modelOrId[_i];
          if (this._add(m)) {
            added = true;
          }
        }
        return added;
      } else {
        modelOrId = modelOrId[0];
      }
      id = modelOrId;
      model = modelOrId;
      if (model instanceof Model) {
        id = model.id();
        if (id == null) {
          throw new Error("Model must have an ID to be added to a relation");
        }
      } else {
        model = null;
        if (id == null) {
          throw new Error("No ID supplied for relation");
        }
      }
      added = false;
      if (this._ids.add(id)) {
        this._models.add(model || id);
        added = true;
      }
      if (model instanceof Model) {
        this._models.replace(model.id(), model);
      }
      return added;
    };

    HasManyRelation.prototype.load = function(persistor, done) {
      var fetchers,
        _this = this;
      if (this.empty()) {
        _.defer(function() {
          return done(null);
        });
        return;
      }
      if (this.loaded()) {
        _.defer(function() {
          return done(null);
        });
        return;
      }
      fetchers = {};
      this._models.each(function(model) {
        var id;
        if (model instanceof Model) {
          return;
        }
        id = model;
        if (fetchers[id] != null) {
          return;
        }
        return fetchers[id] = (function(id) {
          return function(done) {
            return persistor.load(id, function(err, model) {
              if (err) {
                return _.defer(function() {
                  return done(err);
                });
              } else {
                if (model) {
                  _this._models.replace(id, model);
                }
                return _.defer(function() {
                  return done(null);
                });
              }
            });
          };
        })(id);
      });
      return Async.parallel(fetchers, function(err) {
        if (err) {
          return _.defer(function() {
            return done(err);
          });
        } else {
          return _.defer(function() {
            return done(null);
          });
        }
      });
    };

    HasManyRelation.prototype.remove = function(modelOrId) {
      var removed;
      removed = this._remove(modelOrId);
      if (removed) {
        this._triggerChange({
          operation: "remove"
        });
      }
      return removed;
    };

    HasManyRelation.prototype._remove = function(modelOrId) {
      var id, index, n;
      if (!this.contains(modelOrId)) {
        return false;
      }
      id = modelOrId instanceof Model ? modelOrId.id() : modelOrId;
      n = 0;
      while (this.contains(id)) {
        index = this._ids.getIndexForValue(id);
        this._ids.removeByIndex(index);
        this._models.removeByIndex(index);
        n++;
      }
      return n > 0;
    };

    HasManyRelation.prototype.set = function(modelsOrIds) {
      var altered;
      altered = this._set(modelsOrIds);
      if (altered) {
        this._triggerChange({
          operation: "set"
        });
      }
      return altered;
    };

    HasManyRelation.prototype._set = function(modelsOrIds) {
      var id, item, remaining, _i, _len,
        _this = this;
      if (modelsOrIds === null) {
        modelsOrIds = [];
      }
      if (modelsOrIds instanceof HasManyRelation) {
        modelsOrIds = modelsOrIds.get();
      }
      if (modelsOrIds instanceof Collection) {
        modelsOrIds = modelsOrIds.toJSON();
      }
      if (!_.isArray(modelsOrIds)) {
        throw new Error("Setting the values of HasMany must be an array or collection");
      }
      remaining = new Collection(this._ids);
      for (_i = 0, _len = modelsOrIds.length; _i < _len; _i++) {
        item = modelsOrIds[_i];
        if (this.contains(item)) {
          if (item instanceof Model) {
            this._models.replace(item.id(), item);
          }
        } else {
          this._add(item);
        }
        id = item instanceof Model ? item.id() : item;
        remaining.remove(id);
      }
      remaining.each(function(item) {
        return _this._remove(item);
      });
      return true;
    };

    HasManyRelation.prototype.contains = function(modelOrId) {
      var found, id, model;
      found = false;
      if (modelOrId instanceof Model) {
        model = modelOrId;
        id = model.id();
        found = this._models.contains(model);
        if (!found && (id != null)) {
          found = this._ids.contains(id);
        }
      } else {
        found = this._ids.contains(modelOrId);
      }
      return found;
    };

    HasManyRelation.prototype.get = function() {
      return this._models;
    };

    HasManyRelation.prototype.empty = function() {
      return this._ids.size() === 0;
    };

    HasManyRelation.prototype.loaded = function() {
      var loaded;
      loaded = true;
      this._models.each(function(model, i) {
        if (!(model instanceof Model)) {
          return loaded = false;
        }
      });
      return loaded;
    };

    HasManyRelation.prototype.serialize = function() {
      var json;
      json = [];
      this._models.each(function(m) {
        if (m instanceof Model) {
          return json.push(m.id());
        } else {
          return json.push(m);
        }
      });
      return json;
    };

    HasManyRelation.prototype.clone = function(base) {
      if (base == null) {
        base = new HasManyRelation;
      }
      base._ids = this._ids.clone();
      base._models = this._models.clone();
      return base;
    };

    HasManyRelation.prototype._triggerChange = function(data) {
      data.models = this._models.toJSON();
      data.value = this.get();
      return HasManyRelation.__super__._triggerChange.apply(this, arguments);
    };

    return HasManyRelation;

  })(Relation));

  Discrete.ModelRepo = ModelRepo = (function() {
    function ModelRepo() {
      this._models = {};
    }

    ModelRepo.prototype.put = function(model) {
      var id, models;
      models = this._models;
      id = model.id();
      if (id == null) {
        throw new Error("Models stored in ModelRepo must have an ID set");
      }
      if (models[id] != null) {
        models[id] = this.handleOverwrite(models[id], model);
      } else {
        models[id] = model;
      }
      return models[id];
    };

    ModelRepo.prototype.get = function(id) {
      if (this._models[id] != null) {
        return this._models[id];
      }
      return null;
    };

    ModelRepo.prototype.size = function() {
      var id, model, n, _ref1;
      n = 0;
      _ref1 = this._models;
      for (id in _ref1) {
        if (!__hasProp.call(_ref1, id)) continue;
        model = _ref1[id];
        n++;
      }
      return n;
    };

    ModelRepo.prototype.handleOverwrite = function(oldModel, newModel) {
      return oldModel;
    };

    return ModelRepo;

  })();

  Discrete.RepoPersistor = RepoPersistor = (function(_super) {
    var repo;

    __extends(RepoPersistor, _super);

    function RepoPersistor() {
      _ref1 = RepoPersistor.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    repo = null;

    RepoPersistor.add = function() {
      var m, models, _i, _len;
      models = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      models = _.flatten([arguments]);
      for (_i = 0, _len = models.length; _i < _len; _i++) {
        m = models[_i];
        repo.put(m);
        m.persistor = this;
      }
      return models[0];
    };

    RepoPersistor.reset = function() {
      return repo = new ModelRepo;
    };

    RepoPersistor.reset();

    RepoPersistor.prototype.load = function(id, callback) {
      var err, model;
      model = repo.get(id);
      if (model == null) {
        err = new Error("not-found");
        (function(err) {
          return _.defer(function() {
            return callback(err, null);
          });
        })(err);
        return;
      }
      if (_.isFunction(callback)) {
        return (function(model) {
          return _.defer(function() {
            return callback(null, model);
          });
        })(model);
      }
    };

    RepoPersistor.prototype.save = function(model, callback) {
      var id;
      id = model.id();
      model = repo.put(model);
      if (_.isFunction(callback)) {
        return (function(model) {
          return _.defer(function() {
            return callback(null, model);
          });
        })(model);
      }
    };

    RepoPersistor.prototype.getRepo = function() {
      return repo;
    };

    return RepoPersistor;

  })(Persistor);

  Discrete.Loader = Loader = (function() {
    function Loader(options) {
      this.persistor = options.persistor;
      this.concurrency = options.concurrency || 3;
      this._models = {};
      this._poll = null;
      this.running = false;
      this.completed = false;
    }

    Loader.prototype.getPersistor = function() {
      var persistor;
      persistor = this.persistor;
      if (!persistor) {
        throw new Error("Persistor not set");
      }
      if (persistor instanceof Persistor) {
        return persistor;
      }
      return this.persistor = new persistor();
    };

    Loader.prototype.add = function(models) {
      var id, key, map, model, name, val, _i, _len,
        _this = this;
      if (!models) {
        throw new Error("No models supplied");
      }
      if (arguments.length !== 1) {
        throw new Error("Expected one argument, " + arguments.length + " supplied");
      }
      map = {};
      if (models instanceof Collection) {
        models = models.toJSON();
      }
      if (_.isArray(models)) {
        for (_i = 0, _len = models.length; _i < _len; _i++) {
          model = models[_i];
          if (model == null) {
            continue;
          }
          if (model instanceof Model) {
            id = model.id();
            if (id == null) {
              throw new Error("Model '" + model.type + "' does not have an ID");
            }
            map[id] = model;
          } else {
            map[model] = model;
          }
        }
      } else if (models instanceof Map) {
        models.each(function(key, model) {
          return map[key] = model;
        });
      } else if (models instanceof Model) {
        map[models.id()] = models;
      } else if (_.isObject(models)) {
        for (key in models) {
          if (!__hasProp.call(models, key)) continue;
          val = models[key];
          map[key] = val;
        }
      } else if (_.isString(models) || _.isNumber(models)) {
        map[models] = models;
      } else {
        throw new Error("Models must be either Collection, array, Map, Model, Object, or string or number, '" + (typeof models) + "' supplied");
      }
      for (name in map) {
        if (!__hasProp.call(map, name)) continue;
        model = map[name];
        if (_.isObject(model) && !(model instanceof Model)) {
          throw new Error("Non-model object supplied for model");
        }
        this._models[name] = model;
        if (this._queue && !this.completed) {
          this._queue.push({
            name: name,
            model: model
          });
        }
      }
      return this;
    };

    Loader.prototype._addSingle = function(key, model) {};

    Loader.prototype.get = function(name) {
      return this._models[name];
    };

    Loader.prototype.getAll = function() {
      return this._models;
    };

    Loader.prototype.poll = function(func) {
      if (!_.isFunction(func)) {
        throw new Error("Poll must be a function");
      }
      return this._poll = func;
    };

    Loader.prototype.load = function(done) {
      var model, name, queue, task, worker, _ref2, _results,
        _this = this;
      this.running = true;
      worker = function(task, done) {
        var handlers;
        handlers = [];
        handlers.push(function(done) {
          if (task.model instanceof Model) {
            return done(null, task.model);
          } else {
            return _this.getPersistor().load(task.model, function(err, model) {
              if (err) {
                done(err);
                return;
              }
              _this._models[task.name] = model;
              return done(null, model);
            });
          }
        });
        handlers.push(function(model, done) {
          if (_.isFunction(_this._poll)) {
            _this._poll(_this, task.name, model);
          }
          return done(null);
        });
        return Async.waterfall(handlers, function(err) {
          if (err) {
            return done(err);
          } else {
            return done(null);
          }
        });
      };
      this._queue = queue = Async.queue(worker, this.concurrency);
      queue.drain = function() {
        _this.running = false;
        _this.completed = true;
        return done(null, _this);
      };
      _ref2 = this._models;
      _results = [];
      for (name in _ref2) {
        if (!__hasProp.call(_ref2, name)) continue;
        model = _ref2[name];
        task = {
          name: name,
          model: model
        };
        _results.push(queue.push(task, function(err) {
          if (err) {
            return done(err);
          }
        }));
      }
      return _results;
    };

    Loader.prototype.saveAll = function(done) {
      var results, saveModel,
        _this = this;
      results = {};
      saveModel = function(name, done) {
        return _this._models[name].save(function(err, model) {
          if (err) {
            return done(err);
          } else {
            results[name] = model;
            return done(null);
          }
        });
      };
      return Async.each(_.keys(this._models), saveModel, function(err) {
        if (err) {
          return done(err);
        } else {
          _this._models = results;
          return done(null, results);
        }
      });
    };

    return Loader;

  })();

}).call(this);
