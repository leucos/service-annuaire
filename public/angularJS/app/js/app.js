'use strict';


// Declare app level module which depends on filters, and services
angular.module('myApp', ['myApp.filters', 'myApp.services', 'myApp.directives', 'ngGrid', 'ui.bootstrap']).
  config(['$routeProvider', function($routeProvider) {
    $routeProvider.when('/etablissements', {templateUrl: 'partials/etablissements_grid.html', controller: EtabCtrl});
    $routeProvider.when('/etablissement/add', {templateUrl: 'partials/add_etablissemenet.html', controller: MyCtrl2});
    $routeProvider.when('/users', {templateUrl: 'partials/users.html', controller: UserCtrl });
    $routeProvider.when('/user/add', {templateUrl: 'partials/add_users.html', controller:MyCtrl1 });
    $routeProvider.when('/applications', {templateUrl: 'partials/applications.html', controller:MyCtrl1 });
    $routeProvider.when('/applications/add', {templateUrl: 'partials/add_application.html', controller:MyCtrl1 });  
    $routeProvider.otherwise({redirectTo: '/etablissements'});
  }]);
