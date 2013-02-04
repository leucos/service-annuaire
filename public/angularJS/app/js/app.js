'use strict';


// Declare app level module which depends on filters, and services
angular.module('myApp', ['myApp.filters', 'myApp.services', 'myApp.directives', 'ngGrid', 'ui.bootstrap', 'services.breadcrumbs', 
  'services.authentication.current-user', 'services.i18nNotifications', 'services.notifications', 'services.httpRequestTracker','services.authentication']).
  config(['$routeProvider', function($routeProvider, AuthenticationService) {
    var AuthenticatedUser =  ['AuthenticationService', function(AuthenticationService) {
      return AuthenticationService.requireAuthenticatedUser();
    }];
    $routeProvider.when('/', {templateUrl: 'partials/home.html', controller: HomeCtrl});
    $routeProvider.when('/admin_laclasse', {templateUrl:'partials/admin_laclasse.html'}); 
    $routeProvider.when('/admin_etab', {templateUrl:'partials/admin_etab.html'}); 
    $routeProvider.when('/admin_laclasse/etablissements', {templateUrl: 'partials/etablissements_grid.html', controller: EtabCtrl, resolve: { user: AuthenticatedUser}});
    $routeProvider.when('/etablissement/add', {templateUrl: 'partials/add_etablissemenet.html', controller: EtabCtrl});
    $routeProvider.when('/admin_laclasse/users', {templateUrl: 'partials/users.html', controller: UserCtrl });
    $routeProvider.when('/user/add', {templateUrl: 'partials/add_users.html', controller:UserCtrl });
    $routeProvider.when('/applications', {templateUrl: 'partials/applications.html', controller:MyCtrl1 });
    $routeProvider.when('/applications/add', {templateUrl: 'partials/add_application.html', controller:MyCtrl1 });  
    $routeProvider.otherwise({redirectTo: '/'});
  }]).config(function($httpProvider) {
   var interceptor = ['$rootScope','$q', '$log',  function(scope, $q) {
 
    function success(response) {
      console.log('Successful response: ' + response);
      //$log.info('Successful response: ' + response); 
      return response;
    }
 
    function error(response) {
      var status = response.status;
      //$log.error();
      console.log('Response status: ' + status + '. ' + response); 
 
      if (status == 401) {
        var deferred = $q.defer();
        var req = {
          config: response.config,
          deferred: deferred
        }
        scope.requests401.push(req);
        scope.$broadcast('event:loginRequired');
        return deferred.promise;
      }
      // otherwise
      return $q.reject(response);
 
    }
 
    return function(promise) {
      return promise.then(success, error);
    }
 
  }];
  $httpProvider.responseInterceptors.push(interceptor);
}).run(['$rootScope', '$http', function(scope, $http) {
 
  /**
   * Holds all the requests which failed due to 401 response.
   */
  scope.requests401 = [];
  console.log('inside run block');
  console.log(scope.requests401);  
 
  /**
   * On 'event:loginConfirmed', resend all the 401 requests.
   */
  scope.$on('event:loginConfirmed', function() {
  	console.log('inside loginConfirmed event'); 
    var i, requests = scope.requests401;
    for (i = 0; i < requests.length; i++) {
      retry(requests[i]);
    }
    scope.requests401 = [];
 
    function retry(req) {
      $http(req.config).then(function(response) {
        req.deferred.resolve(response);
      });
    }
  });
 
  /**
   * On 'event:loginRequest' send credentials to the server.
   */
  scope.$on('event:loginRequest', function(event, username, password) {
  	// show login
  	console.log('inside loginRequest event');  
    var payload = $.param({j_username: username, j_password: password});
    var config = {
      headers: {'Content-Type':'application/x-www-form-urlencoded; charset=UTF-8'}
    }
    $http.post('../auth', payload, config).success(function(data) {
      if (data === 'AUTHENTICATION_SUCCESS') {
        scope.$broadcast('event:loginConfirmed');
      }
    });
  });
 
  /**
   * On 'logoutRequest' invoke logout on the server and broadcast 'event:loginRequired'.
   */
  scope.$on('event:logoutRequest', function() {
    $http.put('../auth', {}).success(function() {
      ping();
    });
  });
 
  /**
   * Ping server to figure out if user is already logged in.
   */
  function ping() {
    $http.get('something').success(function() {
      scope.$broadcast('event:loginConfirmed');
    });
  }
  //ping();
 
}]);


//TODO: move those messages to a separate module
angular.module('myApp').constant('I18N.MESSAGES', {
  'errors.route.changeError':'Route change error',
  'crud.user.save.success':"A user with id '{{id}}' was saved successfully.",
  'crud.user.remove.success':"A user with id '{{id}}' was removed successfully.",
  'crud.user.save.error':"Something went wrong when saving a user...",
  'crud.project.save.success':"A project with id '{{id}}' was saved successfully.",
  'crud.project.remove.success':"A project with id '{{id}}' was removed successfully.",
  'crud.project.save.error':"Something went wrong when saving a project...",
  'login.error.notAuthorized':"You do not have the necessary access permissions.  Do you want to login as someone else?",
  'login.error.notAuthenticated':"You must be logged in to access this part of the application."
});


