K.MapManageController = Ember.Controller.extend({
  needs: ["application"],
  selfDestructConfirmation: false,


  set_default_self_destruct: function() {
    this.set("selfDestructConfirmation", false);
  }.on("didInsertElement").observes("model"),


  //
  //  Actions
  //
  actions: {

    self_destruct: function() {
      this.set("selfDestructConfirmation", true);
    },

    self_destruct_confirmation: function() {
      var model = this.get("model");
      if (model) model.destroyRecord();

      // reset map selector
      var header_component = this.get(
        "controllers.application.header_component"
      );

      header_component.set("map_selector_value", "");
      header_component.set("map_selector_show_message", false);

      // redirect to index
      this.transitionToRoute("index");
    }

  }


});