var Etablissements = Backbone.Collection.extend({
            url: "/etablissement"
        }); 
var UserList = Backbone.View.extend({
    el: '.page', 
    render: function(){
    	var self = this; 
       etabs = new Etablissements();
       etabs.fetch({
       	success: function(etabs){
       		var template = _.template($('#etab-list-template').html(),{etabs: etabs.models});
       		self.$el.html(template); 
       	}
       });
        
    }
}); 
var Router = Backbone.Router.extend({
    routes: {
        '': "home"
    }
}); 

var userlist = new UserList(); 
var router = new Router(); 
router.on("route:home", function(){ 
    userlist.render(); 
});
Backbone.history.start();