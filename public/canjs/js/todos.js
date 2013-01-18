$(document).ready(function(){
	var Session = can.Model({  
	  findOne : 'GET http://localhost:9292/auth/{id}',
	  create  : 'POST http://localhost:9292/auth/',
	  update  : 'PUT http://localhost:9292/auth/{id}',
	  destroy : 'DELETE http://localhost:9292/auth/{id}'
	}, {});

	var sess = Session.findOne({ id: "3qauE3IohE3yxdYX4pznOg" }, function( session ) {
  		console.log( session.user_id);
	});
	
	var Etablissement = can.Model({
		findAll : 'GET http://localhost:9292/etablissement/',
		findOne : 'GET http://localhost:9292/etablissement/{id}',
		create  : 'POST http://localhost:9292/etablissement',
		update  : 'PUT http://localhost:9292/etablissement/{id}',
		destroy : 'DELETE http://localhost:9292/etablissement/{id}'
	}, {}); 	
   
   var etablissements = Etablissement.findAll({}, function( etabs ) {
	  console.log(etabs[0].id);
	}); 

	console.log("modified");  
		
});