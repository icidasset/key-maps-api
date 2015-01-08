(function() {

var EmberWuphf = {};

//
//  Components
//
EmberWuphf.XWuphfComponent = Ember.Component.extend({
  classNames: ['wuphf-message-container'],
  messages: Ember.computed.alias('wuphf')
});


EmberWuphf.XWuphfMessageComponent = Ember.Component.extend({
  classNames: ['wuphf-message'],
  classNameBindings: ['type'],
  type: Ember.computed.alias('message.type'),
  click: function() {
    this.wuphf.removeObject(this.get('message'));
  }
});



//
//  Services
//
EmberWuphf.Service = Ember.ArrayProxy.extend({
  initTypes: Ember.on('init', function() {
    this.registerTypes('danger', 'info', 'warning', 'success');
  }),
  content: Ember.computed(function() {
    return Ember.A();
  }),
  pushObject: function(object) {
    var _this = this;
    this._super(object);

    if (object.timeout || this.timeout) {
      setTimeout(function() {
        _this.removeObject(object);
      }, object.timeout || this.timeout);
    }
  },
  registerType: function(type) {
    this[type] = function(message, timeout) {
      this.pushObject({
        type: type,
        message: message,
        timeout: timeout
      });
    };
  },
  registerTypes: function() {
    for (var i = 0; i < arguments.length; i++) {
      this.registerType(arguments[i]);
    }
  }
});


//
//  Globalize
//
window.EmberWuphf = EmberWuphf;

}());
