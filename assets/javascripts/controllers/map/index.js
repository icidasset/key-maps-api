K.MapIndexController = Ember.ArrayController.extend(DebouncedPropertiesMixin, {
  needs: ["map"],

  full_width_types: ["text"],
  deleted_map_items: [],

  // aliases
  keys: Ember.computed.alias("controllers.map.keys"),
  has_keys: Ember.computed.alias("controllers.map.has_keys"),


  //
  //  Observers
  //
  model_observer: function() {
    Ember.run.once(Ember.run.bind(this, this.set_sorted_model));
  }.observes("keys", "model.[]"),


  make_new_item_when_there_is_none: function() {
    if (this.get("model.length") === 0 && this.get("hasKeys")) {
      this.add_new();
    }
  }.observes("sorted_model"),


  //
  //  Properties
  //
  has_data: function() {
    return this.get("sorted_model") !== null;
  }.property("sorted_model"),


  sort_by: function() {
    var keys = this.get("keys");

    return (
      this.get("controllers.map.model.sort_by") ||
      (keys[0] ? keys[0].key : null)
    );
  }.property("controllers.map.model.sort_by", "keys"),


  struct: function() {
    var keys = this.get("keys");
    var fwt = this.get("full_width_types");
    var full = [];
    var all = [];

    keys.forEach(function(k) {
      var l = all.length === 0 ? undefined : all[all.length - 1];

      if (fwt.contains(k.type)) {
        full.push(k);
      } else {
        if (l === undefined || l.length >= 2) {
          l = [];
          all.push(l);
        }

        l.push(k);
      }
    });

    if (full.length > 0) {
      all.push(full);
    }

    all.forEach(function(a) {
      a.has_one_item = (a.length === 1);
    });

    return all;
  }.property("keys"),


  set_sorted_model: function() {
    var items = this.get("model").toArray();
    var sort_by = this.get("sort_by");

    items = items.filter(function(m) {
      return !m.get("isDeleted");
    });

    items = items.sort(function(a, b) {
      var a_struct = a.get("structure_data");
      var b_struct = b.get("structure_data");

      a_struct = a_struct ? JSON.parse(a_struct) : null;
      b_struct = b_struct ? JSON.parse(b_struct) : null;

      a_struct = a_struct && sort_by ? a_struct[sort_by] || "" : "";
      b_struct = b_struct && sort_by ? b_struct[sort_by] || "" : "";

      return a_struct.localeCompare(b_struct);
    });

    this.set("sorted_model", items);
  },


  //
  //  Other
  //
  clean_up_data: function(item, keys) {
    var data = JSON.parse(item.get("structure_data") || "{}");
    var data_keys = Object.keys(data);
    var changed_structure = false;

    for (var i=0, j=data_keys.length; i<j; ++i) {
      var key = data_keys[i];
      if (keys.indexOf(key) === -1) {
        delete data[key];
        changed_structure = true;
      }
    }

    if (changed_structure) {
      item.set("structure_data", JSON.stringify(data));
    }
  },


  add_new: function() {
    var controller = this;

    controller.get("controllers.map.model.map_items").then(function() {
      controller.get("controllers.map.model.map_items").addObject(
        controller.store.createRecord("map_item", {})
      );
    });
  },


  //
  //  Actions
  //
  actions: {

    add: function() {
      this.add_new();
    },


    save: function() {
      var controller = this;

      Ember.run(function() {
        var promises = [];
        var deleted_items = controller.deleted_map_items;
        var keys = controller.get("keys").map(function(k) {
          return k.key;
        });

        // persist deleted items
        deleted_items.forEach(function(d) {
          promises.push(d.save());
        });

        deleted_items.length = 0;

        // clean up data and save modified items
        controller.get("model").forEach(function(item) {
          controller.clean_up_data(item, keys);
          if (item.get("isDirty")) promises.push(item.save());
        });

        // Ember.RSVP.all(promises).then(function() {});
      });

      // woof
      this.wuphf.success("<i class='check'></i> Saved");
    }

  }
});
