var attr = DS.attr;


K.Map = DS.Model.extend({
  name: attr("string"),
  slug: attr("string"),
  structure: attr(),
  created_at: attr(),
  updated_at: attr(),
  user_id: attr()
});
