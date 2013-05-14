'use strict';


/* Controllers */

function MyCtrl($scope, $http) {
    var self = this;
    //self.pluginOne = new ngGridFlexibleHeightPlugin(); does not work 

    $scope.session_key = "3qauE3IohE3yxdYX4pznOg";
    $scope.filterOptions = {
        filterText: "",
        useExternalFilter: true
    };
    $scope.pagingOptions = {
        pageSizes: [50, 100, 200],
        pageSize: 50,
        totalServerItems: 0,
        currentPage: 1
    };  
    $scope.setPagingData = function(data){  
        var pagedData = data.data;
        $scope.myData = pagedData;
        //$scope.pagingOptions.totalServerItems = data.total;
        $scope.pagingOptions.totalServerItems = data.data.size;
        $scope.gridOptions.ngGrid.config.totalServerItems = data.total;
        console.log('total', data.total); 
        if (!$scope.$$phase) {
            $scope.$apply();
        }
    };
    $scope.getPagedDataAsync = function (pageSize, page, searchText) {
        setTimeout(function () {
            var data;
            if (searchText) {
                var ft = searchText.toLowerCase();
                $http.get('../users?session_key='+$scope.session_key+'&page='+page+'&limit='+pageSize+'&query='+searchText).success(function (largeLoad) {      
                    data = largeLoad;
                    $scope.setPagingData(data);
                });            
            } else {
                $http.get('../users?session_key='+$scope.session_key+'&page='+page+'&limit='+pageSize).success(function (largeLoad) {
                    $scope.setPagingData(largeLoad);
                });
            }
        }, 100);
    };
    
    $scope.getPagedDataAsync($scope.pagingOptions.pageSize, $scope.pagingOptions.currentPage);
    
    // $scope.$watch('pagingOptions', function (newVal, oldVal) {
    //     if (newVal !== oldVal && newVal.currentPage !== oldVal.currentPage) {
    //       $scope.getPagedDataAsync($scope.pagingOptions.pageSize, $scope.pagingOptions.currentPage, $scope.filterOptions.filterText);
    //     }
    // }, true);
    // $scope.$watch('filterOptions', function (newVal, oldVal) {
    //     if (newVal !== oldVal) {
    //       $scope.getPagedDataAsync($scope.pagingOptions.pageSize, $scope.pagingOptions.currentPage, $scope.filterOptions.filterText);
    //     }
    // }, true);

    $scope.$watch('pagingOptions', function () {
        $scope.getPagedDataAsync($scope.pagingOptions.pageSize, $scope.pagingOptions.currentPage, $scope.filterOptions.filterText);
    }, true);
    $scope.$watch('filterOptions', function () {
        $scope.getPagedDataAsync($scope.pagingOptions.pageSize, $scope.pagingOptions.currentPage, $scope.filterOptions.filterText);
    }, true); 
    
    $scope.gridOptions = {
        data: 'myData',
        //rowTemplate: '<div ng-repeat="col in columns" style="height:{{rowHeight}}; width: {{col.width}}px" class="ngCell {{columnClass($index)}} {{col.cellClass}}" ng-cell></div>', 
        enablePaging: true,
        showFooter: true,
        showFilter: false,
        enableSorting: true,
        i18n: 'fr',  
        pagingOptions: $scope.pagingOptions,
        filterOptions: $scope.filterOptions, 
        columnDefs: [{ field: "nom"},
                    { field: "prenom"},
                    { field: "login"},
                    { field: "id"}, 
                    { field: "emails", cellTemplate: '<div ng-repeat="val in row.entity[col.field]" class="inline"><span class = "label">{{val.adresse}}</span></div>'},
                    { field: "telephones", cellTemplate: '<div ng-repeat="val in row.entity[col.field]" class="inline"><span class = "label">{{val.numero}}</span></div>'},
                    { field: "profils", cellTemplate: '<div ng-repeat="val in row.entity[col.field]" class="inline"><span class = "label label-info">{{val.libelle}}</span></div>'}, 
                    { field: "action", cellTemplate: '<div><a  class="btn" id="edit_user" ng-click="show_modal(user)"><i class="icon-edit"></i>Editer</a>'+' </br></br><a class="btn" id="login" ng-click="show_modal(user)"><i class="icon-cog"></i>Login</a></div>'}  
                    ],
        plugins: []
    };
    $scope.searchText=""; 
    $scope.$watch('searchText', function () {
        $scope.getPagedDataAsync($scope.pagingOptions.pageSize, $scope.pagingOptions.currentPage, $scope.searchText);
    }, true); 
}


function MyCtrl1($scope, $http) {
    $scope.session_key = "3qauE3IohE3yxdYX4pznOg"; 
	$scope.filterOptions = {
        filterText: "",
        useExternalFilter: false
    };
    $scope.pagingOptions = {
        pageSizes: [10, 20, 30],
        pageSize: 10,
        totalServerItems: 0,
        currentPage: 1
    };  
    $scope.setPagingData = function(data){	
        var pagedData = data.data;
        $scope.myData = pagedData;
        //$scope.pagingOptions.totalServerItems = data.total;
        $scope.gridOptions.ngGrid.config.totalServerItems = data.total;
        if (!$scope.$$phase) {
            $scope.$apply();
        }
    };
    $scope.getPagedDataAsync = function (pageSize, page, searchText) {
        setTimeout(function () {
            var data;
            if (searchText) {
                var ft = searchText.toLowerCase();
                $http.get('../etablissements?session_key='+$scope.session_key+'&page='+page+'&limit='+pageSize+'&search='+searchText).success(function (largeLoad) {		
                    data = largeLoad;
                    $scope.setPagingData(data);
                });            
            } else {
                $http.get('../etablissements?session_key='+$scope.session_key+'&page='+page+'&limit='+pageSize).success(function (largeLoad) {
                    data = largeLoad;
                    $scope.setPagingData(data);
                });
            }
        }, 100);
    };
	
    $scope.getPagedDataAsync($scope.pagingOptions.pageSize, $scope.pagingOptions.currentPage);
	
    $scope.$watch('pagingOptions', function () {
        $scope.getPagedDataAsync($scope.pagingOptions.pageSize, $scope.pagingOptions.currentPage, $scope.filterOptions.filterText);
    }, true);
    $scope.$watch('filterOptions', function () {
        $scope.getPagedDataAsync($scope.pagingOptions.pageSize, $scope.pagingOptions.currentPage, $scope.filterOptions.filterText);
    }, true);   
	 

    $scope.gridOptions = {
        data: 'myData',
        enablePaging: true,
        pagingOptions: $scope.pagingOptions,
        showColumnMenu: true,
        showFooter: true,
        showFilter: false,
        enableSorting: true,
        i18n: 'fr',  
        filterOptions: $scope.filterOptions, 
        columnDefs: [{ field: "id", width: "auto"},
                    { field: "code_uai", width: "auto", resizable: true },
                    { field: "nom", width: 200 },
                    { field: "adresse", width: 200 }, 
                    { field: "Alimenté", width: "auto", minWidth: 50, cellTemplate: '<div class= "label label-success">oui</div>'}]
    };
    	
    
}
//MyCtrl1.$inject = [];


function EtabCtrl($scope, $http, $cookies){

    console.log('cookies', $cookies);
    //console.log(currentUser.getSession()); 
	$scope.session_key = $cookies.appSession; 
	$scope.url = '../etablissements'; 
	$scope.limit = 500 ; 
	$scope.currentPage = 1; 
	$scope.recordParPage= [250, 500, 1000]; 
	$scope.params = {"session_key": $scope.session_key, "limit": $scope.limit, "page": $scope.currentPage}; 
	$scope.noOfPages = 1; 
	$scope.searchText = ""; 
	$scope.maxSize = 10; //maximum number of pages to display
	$scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+$scope.limit+"&page="+$scope.currentPage;
	$scope.listeEtablissements = function(){
		$http.get($scope.request).success(function(data){
			$scope.etabs = data;
			$scope.total = data.total; 
			$scope.noOfPages = Math.ceil($scope.total/$scope.limit);
		}).error(function(err){
			console.log("get error"+err); 
		});
	}; 

	$scope.setselectedEtab = function(etab){
		$scope.selectedEtab = etab; 
	}; 
	$scope.listeEtablissements(); 

	$scope.sortingOrder = 'nom'; 
	$scope.reverse = false ;
	$scope.$watch('currentPage', function(newValue, oldValue) {  
		console.log('current page changed from '+oldValue+' to '+newValue);
    	
    	if ( newValue <= 0 )
    	{ 
    		newValue = 1;
    		
    	}
    	$scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+$scope.limit+"&page="+newValue+"&query="+$scope.searchText;
    	$scope.request += "&sort_col="+$scope.sortingOrder+"&sort_dir="+($scope.reverse ? "asc" : "desc"); 
    	console.log($scope.request);  
    	$http.get($scope.request).
	    	success(function(data, status){ 
	    		$scope.etabs = data;
	    		$scope.status = status;   
	    	}).
	    	error(function(data, status){ 
	    		$scope.data = data || "request failed"; 
	    		$scope.status = status; 
	    	});

	});
	$scope.$watch('searchText', function(newValue, oldValue) {
    	console.log('search Text changed from '+oldValue+' to '+ newValue);
    	$scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+$scope.limit+"&page="+$scope.currentPage+"&query="+newValue;
    	console.log($scope.request);
    	$http.get($scope.request).
	    	success(function(data, status){ 
	    		$scope.etabs = data;
	    		$scope.total = data.total; 
	    		if (data.total == 0){
	    			//$scope.currentPage = 1 ; 
	    			$scope.noOfPages = 1;
	    		}
	    		else{
	    			$scope.noOfPages = Math.ceil(data.total/$scope.limit);
	    		}
	    		$scope.status = status;   
	    	}).
	    	error(function(data, status){ 
	    		$scope.data = data || "request failed"; 
	    		$scope.status = status; 
	    	});

    });
    $scope.$watch('limit', function(newValue, oldValue){
    	console.log('limit page changed from '+oldValue+' to '+newValue);
    	$scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+newValue+"&page="+$scope.currentPage+"&query="+$scope.searchText;
    	console.log($scope.request);  
    	$http.get($scope.request).
	    	success(function(data, status){ 
	    		$scope.etabs = data;
	    		$scope.noOfPages = Math.ceil(data.total/newValue);
	    		$scope.status = status;   
	    	}).
	    	error(function(data, status){ 
	    		$scope.data = data || "request failed"; 
	    		$scope.status = status; 
	    	});
    });

    $scope.sort_by = function(newSortingOrder) {
    	console.log("sorting column changed from"+$scope.sortingOrder+" to "+newSortingOrder); 
        console.log("sorting direction"+ $scope.reverse); 
        if ($scope.sortingOrder == newSortingOrder)
            $scope.reverse = !$scope.reverse; 

        $scope.sortingOrder = newSortingOrder;

        // icon setup
        $('th i').each(function(){
            // icon reset
            $(this).removeClass().addClass('icon-sort');
        });
        if ($scope.reverse)
            $('th.'+newSortingOrder+' i').removeClass().addClass('icon-caret-up');
        else
            $('th.'+newSortingOrder+' i').removeClass().addClass('icon-caret-down');

        //get data
        $scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+$scope.limit+"&page="+$scope.currentPage+"&query="+$scope.searchText;
        $scope.request += "&sort_col="+newSortingOrder+"&sort_dir="+($scope.reverse ? "asc" : "desc"); 
    	console.log($scope.request);
    	$http.get($scope.request).
	    	success(function(data, status){ 
	    		$scope.etabs = data;
	    		$scope.status = status;   
	    	}).
	    	error(function(data, status){ 
	    		$scope.data = data || "request failed"; 
	    		$scope.status = status; 
	    	});
    }; 

}

EtabCtrl.$inject=['$scope', '$http', '$cookies'];


function UserCtrl($scope, $http, $cookies){

	console.log('cookies', $cookies); 
	//$scope.session_key = ""; 
	$scope.session_key = "3qauE3IohE3yxdYX4pznOg"; 
	$scope.url = '../users'; 
	$scope.limit = 10;
	$scope.currentPage = 1;
	$scope.recordParPage = [10, 25, 50, 100];    
	$scope.params = {"session_key": "3qauE3IohE3yxdYX4pznOg", "limit": $scope.limit, "page": $scope.currentPage}
    // query friends method
    $scope.noOfPages = 1;
    $scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+$scope.limit+"&page="+$scope.currentPage;
    $scope.maxSize = 10;
    //search Text
    $scope.searchText = ""; 


    $scope.listUsers = function() {
      // call GET http method
      $http.get($scope.request).success(function (data) {
        $scope.users = data;
        $scope.noOfPages = Math.ceil(data.total/$scope.limit);
      }).error(function(err) {
        console.log("get error : "+err);
      });
    };

    $scope.setSelectedUser = function(user) {
      $scope.selectedUser = user;
    };
    // first, query all friends to intialize $scope.friends
    $scope.listUsers();

    $scope.setPage = function(page){
    	$scope.currentPage =  page ; 
    }

    // Add Watchers to events
    $scope.$watch('currentPage', function(newValue, oldValue) { 

    	console.log('current page changed from '+oldValue+' to '+newValue);
    	
    	if ( newValue <= 0 )
    	{ 
    		newValue = 1;
    		
    	}
    	$scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+$scope.limit+"&page="+newValue+"&query="+$scope.searchText;
    	$scope.request += "&sort_col="+$scope.sortingOrder+"&sort_dir="+($scope.reverse ? "asc" : "desc"); 
    	console.log($scope.request);  
    	$http.get($scope.request).
	    	success(function(data, status){ 
	    		$scope.users = data;
	    		$scope.status = status;   
	    	}).
	    	error(function(data, status){ 
	    		$scope.data = data || "request failed"; 
	    		$scope.status = status; 
	    	});

    });

    $scope.$watch('limit', function(newValue, oldValue){

    	console.log('limit page changed from '+oldValue+' to '+newValue);
    	$scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+newValue+"&page="+$scope.currentPage+"&query="+$scope.searchText;
    	console.log($scope.request);  
    	$http.get($scope.request).
	    	success(function(data, status){ 
	    		$scope.users = data;
	    		$scope.noOfPages = Math.ceil(data.total/newValue);
	    		$scope.status = status;   
	    	}).
	    	error(function(data, status){ 
	    		$scope.data = data || "request failed"; 
	    		$scope.status = status; 
	    	});

    });

    $scope.$watch('searchText', function(newValue, oldValue) {
    	console.log('search Text changed from '+oldValue+' to '+ newValue);
    	$scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+$scope.limit+"&page="+$scope.currentPage+"&query="+newValue;
    	console.log($scope.request);
    	$http.get($scope.request).
	    	success(function(data, status){ 
	    		$scope.users = data;
	    		if (data.total == 0){
	    			//$scope.currentPage = 1 ; 
	    			$scope.noOfPages = 1;
	    		}
	    		else{
	    			$scope.noOfPages = Math.ceil(data.total/$scope.limit);
	    		}
	    		$scope.status = status;   
	    	}).
	    	error(function(data, status){ 
	    		$scope.data = data || "request failed"; 
	    		$scope.status = status; 
	    	});

    });



    // change sorting order
    $scope.sortingOrder = 'id';
    $scope.reverse = false;

    $scope.sort_by = function(newSortingOrder) {
    	console.log("sorting column changed from"+$scope.sortingOrder+" to "+newSortingOrder); 
        console.log("sorting direction"+ $scope.reverse); 
        if ($scope.sortingOrder == newSortingOrder)
            $scope.reverse = !$scope.reverse; 

        $scope.sortingOrder = newSortingOrder;

        // icon setup
        $('th i').each(function(){
            // icon reset
            $(this).removeClass().addClass('icon-sort');
        });
        if ($scope.reverse)
            $('th.'+newSortingOrder+' i').removeClass().addClass('icon-caret-up');
        else
            $('th.'+newSortingOrder+' i').removeClass().addClass('icon-caret-down');

        //get data
        $scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+$scope.limit+"&page="+$scope.currentPage+"&query="+$scope.searchText;
        $scope.request += "&sort_col="+newSortingOrder+"&sort_dir="+($scope.reverse ? "asc" : "desc"); 
    	console.log($scope.request);
    	$http.get($scope.request).
	    	success(function(data, status){ 
	    		$scope.users = data;
	    		$scope.status = status;   
	    	}).
	    	error(function(data, status){ 
	    		$scope.data = data || "request failed"; 
	    		$scope.status = status; 
	    	});
    };

    $scope.show_modal = function(user){
    	$scope.selectedUser = user; 
    	$scope.editUser = true; 	

    };

    $scope.close = function(){
    	$scope.editUser = false; 
    }; 

} 

UserCtrl.$inject=['$scope', '$http', '$cookies']; 
 
/* 
function LoginCtrl($scope, $location, User){
	// add router to login page 
	$scope.login = User.login($scope.usernamej, $scope.password, function(result){
		if !result 
			window.alert('Authentication failed!'); 
		else 
			$scope.$apply($location.path('/index.html')); 
	});

	$scope.User = User;  
}
*/

function MyCtrl2() {
}
MyCtrl2.$inject = [];


function HeaderCtrl($scope, $location, $route, currentUser, breadcrumbs, notifications, httpRequestTracker) {
  $scope.location = $location;
  $scope.currentUser = currentUser;
  $scope.breadcrumbs = breadcrumbs;

  $scope.home = function () {
    if ($scope.currentUser.isAuthenticated()) {
      $location.path('/etablissements');
    } else {
      $location.path('/');
    }
  };

  $scope.isNavbarActive = function (navBarPath) {
    return navBarPath === breadcrumbs.getFirst().name;
  };

  $scope.hasPendingRequests = function () {
    return httpRequestTracker.hasPendingRequests();
  };
}

HeaderCtrl.$inject = ['$scope', '$location', '$route', 'currentUser', 'breadcrumbs', 'notifications', 'httpRequestTracker'];

function HomeCtrl($scope, $location, currentUser){
    $scope.currentUser = currentUser;
} 
HomeCtrl.$inject = ['$scope', '$location', 'currentUser']; 

