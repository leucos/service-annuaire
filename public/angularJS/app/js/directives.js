'use strict';

/* Directives */

angular.module('myApp.directives', []).directive('appVersion', ['version', function(version) {
    return function(scope, elm, attrs) {
      elm.text(version);
    	};
  }]); 

angular.module('myApp.directives', ['services.authentication', 'services.localizedMessages', 'directives.modal']).directive('loginForm', ['AuthenticationService', 'localizedMessages', 'currentUser', function(AuthenticationService, localizedMessages, currentUser) {
  var directive = {
    templateUrl: 'partials/loginform.html',
    restrict: 'E',
    scope: true,
    link: function($scope, $element, $attrs, $controller) {
      $scope.user = {};
      $scope.authError = null;
      $scope.authService = AuthenticationService;
      $scope.showLoginForm = false;

      $scope.clearForm = function() {
        $scope.user = {};
      };

      $scope.showLogin = function(msg) {
        $scope.authError = msg;
        $scope.showLoginForm = true;
      };

      $scope.cancelLogin = function() {
        AuthenticationService.cancelLogin();
      };

      $scope.hideLogin = function() {
        $scope.showLoginForm = false;
      };

      $scope.getLoginReason = function() {
        var reason = AuthenticationService.getLoginReason();
        var isAuthenticated = currentUser.isAuthenticated();

        var message = "";
        switch(reason) {
          case 'user-request':
            message = "Please enter you login details below";
            break;
          case 'unauthenticated-client':
          case 'unauthorized-client':
          case 'unauthorized-server':
            if ( isAuthenticated ) {
                message = localizedMessages.get('login.error.notAuthorized');
            } else {
                message = localizedMessages.get('login.error.notAuthenticated');
            }
            break;
          default:
            message = "";
            break;
          }
        return message;
      };

      // A login is required.  If the user decides not to login then we can call cancel
      $scope.$watch(AuthenticationService.isLoginRequired, function(value) {
        if ( value ) {
          $scope.showLogin($scope.getLoginReason());
        } else {
          $scope.hideLogin();
        }
      });

      $scope.login = function() {
        $scope.authError = null;
        AuthenticationService.login($scope.user.email, $scope.user.password).then(function(loggedIn) {
          if ( !loggedIn ) {
            $scope.authError = "Login failed.  Please check your credentials and try again.";
          }
        });
      };

    }
  };
  return directive;
}]);

angular.module('myApp.directives').directive('loginToolbar', ['currentUser', 'AuthenticationService', function(currentUser, AuthenticationService) {
  var directive = {
    templateUrl: 'partials/logintoolbar.html',
    restrict: 'E',
    replace: true,
    scope: true,
    link: function($scope, $element, $attrs, $controller) {
      $scope.userInfo = currentUser.info;
      $scope.isAuthenticated = currentUser.isAuthenticated;
      $scope.logout = function() { AuthenticationService.logout(); };
      $scope.login = function() { AuthenticationService.showLogin(); };
    }
  };
  return directive;
}]);

angular.module('directives.modal', []).directive('modal', ['$parse',function($parse) {
  var backdropEl;
  var body = angular.element(document.getElementsByTagName('body')[0]);
  var defaultOpts = {
    backdrop: true,
    escape: true
  };
  return {
    restrict: 'ECA',
    link: function(scope, elm, attrs) {
      var opts = angular.extend(defaultOpts, scope.$eval(attrs.uiOptions || attrs.bsOptions || attrs.options));
      var shownExpr = attrs.modal || attrs.show;
      var setClosed;

      if (attrs.close) {
        setClosed = function() {
          scope.$apply(attrs.close);
        };
      } else {
        setClosed = function() {
          scope.$apply(function() {
            $parse(shownExpr).assign(scope, false);
          });
        };
      }
      elm.addClass('modal');

      if (opts.backdrop && !backdropEl) {
        backdropEl = angular.element('<div class="modal-backdrop"></div>');
        backdropEl.css('display','none');
        body.append(backdropEl);
      }

      function setShown(shown) {
        scope.$apply(function() {
          model.assign(scope, shown);
        });
      }

      function escapeClose(evt) {
        if (evt.which === 27) { setClosed(); }
      }
      function clickClose() {
        setClosed();
      }

      function close() {
        if (opts.escape) { body.unbind('keyup', escapeClose); }
        if (opts.backdrop) {
          backdropEl.css('display', 'none').removeClass('in');
          backdropEl.unbind('click', clickClose);
        }
        elm.css('display', 'none').removeClass('in');
        body.removeClass('modal-open');
      }
      function open() {
        if (opts.escape) { body.bind('keyup', escapeClose); }
        if (opts.backdrop) {
          backdropEl.css('display', 'block').addClass('in');
          backdropEl.bind('click', clickClose);
        }
        elm.css('display', 'block').addClass('in');
        body.addClass('modal-open');
      }

      scope.$watch(shownExpr, function(isShown, oldShown) {
        if (isShown) {
          open();
        } else {
          close();
        }
      });
    }
  };
}]);


