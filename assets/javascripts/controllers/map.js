K.MapController = Ember.Controller.extend({
  needs: "application",


  // observers
  pass_map_name_to_header: function() {
    var m;
    var header_component = this.get(
      "controllers.application.header_component"
    );

    // check
    if (!header_component) return;

    // continue
    m = this.get("model").toArray()[0];

    if (m) {
      header_component.set("map_selector_value", m.get("name"));
      document.activeElement.blur();
    }
  }.observes(
    "model",
    "controllers.application.header_component"
  )

});
