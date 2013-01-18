var Etablissement = can.Model({
		findAll: 'GET http://localhost:9292/etablissement',
		findOne: 'GET http://localhost:9292/etablissement/{id}', 
		create : 'POST http://localhost:9292/etablissement',
		update:  'PUT http://localhost:9292/etablissement/{id}',
		destroy: 'DELETE http://localhost:9292/etablissement/{id}', 
	},{}); 

var Etablissements = can.Control({
	'init': function( element , options ) {
		this.options.showorhide = true; 
	},
	'{document} #show_etablissements click': function(){
		if ( this.options.showorhide == true ) {
		  this.show();
		} else {
		  this.hide();
		}
	}, 
    show: function(){
    	var el = this.element; 
		Etablissement.findAll( {}, function(etabs) {
		   var frag = can.view('views/etabList.ejs', etabs); 
		   console.log(frag);
		   console.log(el);
		   el.html(frag);
		});
			this.element.slideDown(200);
			this.options.showorhide = false; 
	},
	
	hide: function(){
		this.element.slideUp(200);
		this.options.showorhide = true;
	},

});
var EtablissementGrid = can.Control({
	'init': function( element , options ) {
		this.options.showorhide = true; 
	},
	'{document} #show_etablissements click': function(){
		if ( this.options.showorhide == true ) {
		  this.show();
		} else {
		  this.hide();
		}
	}, 
    show: function(){
    	var el = this.element;
    	Etablissement.findAll( {}, function(etabs) {
		   var frag = can.view('views/EtablissementGrid.ejs', etabs); 
		   console.log(frag);
		   console.log(el);
		   el.html(frag);
		});
			this.element.slideDown(200);
			this.options.showorhide = false; 
		
		this.element.slideDown(200);
		this.options.showorhide = false; 
	},
	
	hide: function(){
		this.element.slideUp(200);
		this.options.showorhide = true;
	},
}); 

var etabsControl = new EtablissementGrid('#etablissement',{}); 
  


/*	
$('document').ready(function(){
	var etabsControl = new Etablissements('#etablissement',{});  
});
*/

