'use strict';

/* Services */


// Demonstrate how to register services
// In this case it is a simple value service.

var myAppModule = angular.module('myApp.services',['ngResource']);

myAppModule.value('version', '0.1');

// Restful resource pour l'Etablissement
myAppModule.factory('Etablissement', function($resource){
  return $resource('../etablissement/:id',  {id: '@id' }, {
    query: {method:'GET', params:{id:''}, isArray:true}
  });
});

// another service 
angular.module('services.authentication.retry-queue', []);
// This is a generic retry queue for authentication failures.  Each item is expected to expose two functions: retry and cancel.
angular.module('services.authentication.retry-queue').factory('AuthenticationRetryQueue', ['$q', function($q) {
  var retryQueue = [];
  var service = {
    push: function(retryItem) {
      retryQueue.push(retryItem);
    },
    pushPromiseFn: function(promiseFn, reason) {
      var deferred = $q.defer();
      var retryItem = {
        reason: reason,
        retry: function() {
          promiseFn().then(function(value) {
            deferred.resolve(value);
          });
        },
        cancel: function() {
          deferred.reject();
        }
      };
      service.push(retryItem);
      return deferred.promise;
    },
    hasMore: function() {
      return retryQueue.length > 0;
    },
    getReason: function() {
      if ( service.hasMore() ) {
        return retryQueue[0].reason;
      }
    },
    getNext: function() {
      return retryQueue.shift();
    },
    cancel: function() {
      while(service.hasMore()) {
        service.getNext().cancel();
      }
    },
    retry: function() {
      while(service.hasMore()) {
        service.getNext().retry();
      }
    }
  };
  return service;
}]); 

angular.module('services.localizedMessages', []).factory('localizedMessages', ['$interpolate', 'I18N.MESSAGES', function ($interpolate, i18nmessages) {

  var handleNotFound = function (msg, msgKey) {
    return msg || '?' + msgKey + '?';
  };

  return {
    get : function (msgKey, interpolateParams) {
      var msg =  i18nmessages[msgKey];
      if (msg) {
        return $interpolate(msg)(interpolateParams);
      } else {
        return handleNotFound(msg, msgKey);
      }
    }
  };
}]);

// Based loosely around work by Witold Szczerba - https://github.com/witoldsz/angular-http-auth
angular.module('services.authentication', ['services.authentication.current-user', 'services.authentication.interceptor', 'services.authentication.retry-queue', 'ngCookies']);

// The AuthenticationService is the public API for this module.  Application developers should only need to use this service and not any of the others here.
angular.module('services.authentication').factory('AuthenticationService', ['$http', '$location', '$q', 'AuthenticationRetryQueue', 'currentUser', '$cookies', function($http, $location, $q, queue, currentUser, $cookies) {

  // TODO: We need a way to refresh the page to clear any data that has been loaded when the user logs out
  //  a simple way would be to redirect to the root of the application but this feels a bit inflexible.
  function redirect(url) {
    url = url || '/';
    $location.path(url);
  }

  function updateCurrentUser(user) {
    currentUser.update(user);
    if ( !!user ) {
      queue.retry();
    }
  }
  function setCurrentUserSession(session){
    currentUser.setSession(session);
  }

  var service = {
    isLoginRequired: function() {
      return queue.hasMore();
    },

    getLoginReason: function() {
      return queue.getReason();
    },

    showLogin: function() {
      // Push a no-op onto the queue to create a manual login
      queue.push({ retry: function() {}, cancel: function() {}, reason: 'user-request' });
    },

    login: function(login, password) {
      var request = $http.post('../auth/login', {login: login, password: password});
      return request.then(function(response) {
        updateCurrentUser(response.data.user);
        console.log('login .. \n'); 
        console.log('CurrentUser after login:', currentUser.info());
        console.log('location:', $location); 
        setCurrentUserSession(response.data.session_key);
        $cookies.appSession = response.data.session_key; 
        return currentUser.isAuthenticated();
      }, function(raison){
         console.log('login error: \n', raison);  
      } 
      );
    },

    cancelLogin: function(redirectTo) {
      queue.cancel();
      redirect(redirectTo);
    },

    logout: function(redirectTo) {
      $http.post('../auth/logout', {"session_key": currentUser.getSession()}).then(function() {
        console.log('Logout .. '); 
        currentUser.clear();
        $cookies.appSession = null; 
        redirect(redirectTo);
      });
    },

    // Ask the backend to see if a user is already authenticated - this may be from a previous session.
    // The app should probably do this at start up
    requestCurrentUser: function() {
      if ( currentUser.isAuthenticated() ) {
        return $q.when(currentUser);
      } else {
        console.log('request current user:'); 
        if ($cookies.appSession)
          return $http.get('../auth/user/'+$cookies.appSession).then(function(response) {
            updateCurrentUser(response.data.user);
            setCurrentUserSession(response.data.session_key);
            return currentUser;
          });
      }
    },

    requireAuthenticatedUser: function() {
      var promise = service.requestCurrentUser().then(function(currentUser) {
        if ( !currentUser.isAuthenticated() ) {
          return queue.pushPromiseFn(service.requireAuthenticatedUser, 'unauthenticated-client');
        }
      });
      return promise;
    },

    requireAdminUser: function() {
      var promise = service.requestCurrentUser().then(function(currentUser) {
        if ( !currentUser.isAdmin() ) {
          return queue.pushPromiseFn(service.requireAdminUser, 'unauthorized-client');
        }
      });
      return promise;
    }
  };

  // Get the current user when the service is instantiated
  //Request current  User : in a real situation 
  service.requestCurrentUser();

  return service;
}]);


// current user provides a way to track logged user
angular.module('services.authentication.current-user', []);
// The current user.  You can watch this for changes due to logging in and out
angular.module('services.authentication.current-user').factory('currentUser', function() {
  var userInfo = null;
  var sessionKey = ""; 
  var currentUser = {
    update: function(info) { userInfo = info; },
    clear: function() { userInfo = null; sessionKey = ""; },
    info: function() { return userInfo; },
    isAuthenticated: function(){ return !!userInfo; },
    isAdmin: function() { return !!(userInfo && userInfo.admin); },
    setSession: function(session){sessionKey = session;},
    getSession: function(){ return sessionKey;}

  };
  return currentUser;
});


//session key service.
/*
angular.module('services.authentication.session-key', []); 
angular.module('services.authentication.session-key').factory('sessionKey', function(){
  var session = "";
  session 
  var sessionkey = {
    update: function(key){session = key;}, 
    clear:  function(){session = ""}, 
    info: function(){ return session}    
  };

  return sessionKey; 
});
*/
// interceptor  which i dont know why? 

angular.module('services.authentication.interceptor', ['services.authentication.retry-queue']);

// This http interceptor listens for authentication failures
angular.module('services.authentication.interceptor').factory('AuthenticationInterceptor', ['$rootScope', '$injector', '$q', 'AuthenticationRetryQueue', function($rootScope, $injector, $q, queue) {
  var $http; // To be lazy initialized to prevent circular dependency
  return function(promise) {
    $http = $http || $injector.get('$http');
    
    // Intercept failed requests
    return promise.then(null, function(originalResponse) {
      if(originalResponse.status === 401) {
        // The request bounced because it was not authorized - add a new request to the retry queue
        promise = queue.pushPromiseFn(function() { return $http(originalResponse.config); }, 'unauthorized-server');
      }
      return promise;
    });
  };
}]);

// We have to add the interceptor to the queue as a string because the interceptor depends upon service instances that are not available in the config block.
angular.module('services.authentication.interceptor').config(['$httpProvider', function($httpProvider) {
  $httpProvider.responseInterceptors.push('AuthenticationInterceptor');
}]);


angular.module('services.breadcrumbs', []);
angular.module('services.breadcrumbs').factory('breadcrumbs', ['$rootScope', '$location', function($rootScope, $location){

  var breadcrumbs = [];
  var breadcrumbsService = {};

  //we want to update breadcrumbs only when a route is actually changed
  //as $location.path() will get updated imediatelly (even if route change fails!)
  $rootScope.$on('$routeChangeSuccess', function(event, current){

    var pathElements = $location.path().split('/'), result = [], i;
    var breadcrumbPath = function (index) {
      return '/' + (pathElements.slice(0, index + 1)).join('/');
    };

    pathElements.shift();
    for (i=0; i<pathElements.length; i++) {
      result.push({name: pathElements[i], path: breadcrumbPath(i)});
    }

    breadcrumbs = result;
  });

  breadcrumbsService.getAll = function() {
    return breadcrumbs;
  };

  breadcrumbsService.getFirst = function() {
    return breadcrumbs[0] || {};
  };

  return breadcrumbsService;
}]);

angular.module('services.i18nNotifications', ['services.notifications', 'services.localizedMessages']);
angular.module('services.i18nNotifications').factory('i18nNotifications', ['localizedMessages', 'notifications', function (localizedMessages, notifications) {

  var prepareNotification = function(msgKey, type, interpolateParams, otherProperties) {
     return angular.extend({
       message: localizedMessages.get(msgKey, interpolateParams),
       type: type
     }, otherProperties);
  };

  var I18nNotifications = {
    pushSticky:function (msgKey, type, interpolateParams, otherProperties) {
      return notifications.pushSticky(prepareNotification(msgKey, type, interpolateParams, otherProperties));
    },
    pushForCurrentRoute:function (msgKey, type, interpolateParams, otherProperties) {
      return notifications.pushForCurrentRoute(prepareNotification(msgKey, type, interpolateParams, otherProperties));
    },
    pushForNextRoute:function (msgKey, type, interpolateParams, otherProperties) {
      return notifications.pushForNextRoute(prepareNotification(msgKey, type, interpolateParams, otherProperties));
    },
    getCurrent:function () {
      return notifications.getCurrent();
    },
    remove:function (notification) {
      return notifications.remove(notification);
    }
  };

  return I18nNotifications;
}]);

angular.module('services.notifications', []).factory('notifications', ['$rootScope', function ($rootScope) {

  var notifications = {
    'STICKY' : [],
    'ROUTE_CURRENT' : [],
    'ROUTE_NEXT' : []
  };
  var notificationsService = {};

  var addNotification = function (notificationsArray, notificationObj) {
    if (!angular.isObject(notificationObj)) {
      throw new Error("Only object can be added to the notification service");
    }
    notificationsArray.push(notificationObj);
    return notificationObj;
  };

  $rootScope.$on('$routeChangeSuccess', function () {
    notifications.ROUTE_CURRENT.length = 0;

    notifications.ROUTE_CURRENT = angular.copy(notifications.ROUTE_NEXT);
    notifications.ROUTE_NEXT.length = 0;
  });

  notificationsService.getCurrent = function(){
    return [].concat(notifications.STICKY, notifications.ROUTE_CURRENT);
  };

  notificationsService.pushSticky = function(notification) {
    return addNotification(notifications.STICKY, notification);
  };

  notificationsService.pushForCurrentRoute = function(notification) {
    return addNotification(notifications.ROUTE_CURRENT, notification);
  };

  notificationsService.pushForNextRoute = function(notification) {
    return addNotification(notifications.ROUTE_NEXT, notification);
  };

  notificationsService.remove = function(notification){
    angular.forEach(notifications, function (notificationsByType) {
      var idx = notificationsByType.indexOf(notification);
      if (idx>-1){
        notificationsByType.splice(idx,1);
      }
    });
  };

  notificationsService.removeAll = function(){
    angular.forEach(notifications, function (notificationsByType) {
      notificationsByType.length = 0;
    });
  };

  return notificationsService;
}]);

angular.module('services.httpRequestTracker', []);
angular.module('services.httpRequestTracker').factory('httpRequestTracker', ['$http', function($http){

  var httpRequestTracker = {};
  httpRequestTracker.hasPendingRequests = function() {
    return $http.pendingRequests.length > 0;
  };

  return httpRequestTracker;
}]);












