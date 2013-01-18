'use strict';

/* Services */


// Demonstrate how to register services
// In this case it is a simple value service.

var myAppModule = angular.module('myApp.services',['ngResource']);

myAppModule.value('version', '0.1');

myAppModule.factory('Etablissement', function($resource){
  return $resource('../etablissement/:id',  {id: '@id' }, {
    query: {method:'GET', params:{id:''}, isArray:true}
  });
});

