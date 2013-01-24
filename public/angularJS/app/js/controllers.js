'use strict';

/* Controllers */


function MyCtrl1($scope, $http) {
	$scope.filterOptions = {
        filterText: "",
        useExternalFilter: true
    };
    $scope.pagingOptions = {
        pageSizes: [10, 20, 30],
        pageSize: 10,
        totalServerItems: 0,
        currentPage: 1
    };  
    $scope.setPagingData = function(data, page, pageSize){	
        var pagedData = data.slice((page - 1) * pageSize, page * pageSize);
        $scope.myData = pagedData;
        $scope.pagingOptions.totalServerItems = data.length;
        if (!$scope.$$phase) {
            $scope.$apply();
        }
    };
    $scope.getPagedDataAsync = function (pageSize, page, searchText) {
        setTimeout(function () {
            var data;
            if (searchText) {
                var ft = searchText.toLowerCase();
                $http.get('../etablissement?page='+page+'&limit='+pageSize+'&search='+searchText).success(function (largeLoad) {		
                    data = largeLoad;
                    $scope.setPagingData(data,page,pageSize);
                });            
            } else {
                $http.get('../etablissement?page='+page+'&limit='+pageSize).success(function (largeLoad) {
                    $scope.setPagingData(largeLoad,page,pageSize);
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
        filterOptions: $scope.filterOptions
    };	
    
}
//MyCtrl1.$inject = [];


function EtabCtrl($scope, Etablissement, $filter){
	
	$scope.myData = [{name: "Moroni", age: 50},
                     {name: "Tiancum", age: 43},
                     {name: "Jacob", age: 27},
                     {name: "Nephi", age: 29},
                     {name: "Enos", age: 34}];

    $scope.gridOptions = { data: 'myData' };

	// query etablissements depending on page, limit
	$scope.etablissements = Etablissement.query(function(result){
		$scope.total = result.length; 
	}); 

	
	//console.log(etabs.length);
	// why etab.length does not work. 

 	var etab = Etablissement.get({id:'1'}, function(){
 		//console.log(etab.nom); 
 		//console.log(etab.id); 
 	});
 	$scope.total = $scope.etablissements.length; 
    console.log($scope.total);  
 	//console.log(etab.id); 


	/* 
    $scope.gridOptions = { 
        data: 'etablissements'
    };
	*/
    
	// pagination
    //model to store the number of records per page 
    $scope.recordParPage = [10, 20, 30]; 
    $scope.filterdResult = []; 
    $scope.rpp = 10;  
    $scope.currentPage = 1; 

	$scope.range = function (start, end) {
		var ret = [];
		if (!end) {
		  end = start;
		  start = 0;
		}
		for (var i = start; i < end; i++) {
		  ret.push(i);
		}
		return ret;
	};

	$scope.prevPage = function () {
		if ($scope.currentPage > 0) {
		  $scope.currentPage--;
		}
	};

	$scope.nextPage = function () {
		if ($scope.currentPage < $scope.etablissements.length - 1) {
		  $scope.currentPage++;
		}
	};

	$scope.setPage = function () {
		$scope.currentPage = this.n;
	}; 

	// Search 
	$scope.searchPrase = ""; 

	var searchMatch = function (haystack, needle) {
        if (!needle) {
            return true;
        }
        return haystack.toLowerCase().indexOf(needle.toLowerCase()) !== -1;
    };

	$scope.search = function(){
		$scope.filterdResult = $filter('filter')($scope.etablisssements, function (etab) {
            for(var attr in etab) {
                if (searchMatch(etab[attr], $scope.searchPrase)){
                	return true; 
                	console.log('match found'); 
                }
            }
            return false;
        });
        // take care of the sorting order
        /*
        if ($scope.sortingOrder !== '') {
            $scope.filteredItems = $filter('orderBy')($scope.filteredItems, $scope.sortingOrder, $scope.reverse);
        }
        $scope.currentPage = 0;
        // now group by pages
        $scope.groupToPages();

		return etablissements.filter("search phrase")
		*/	
	};
	$scope.sortDirection = ''; 
	$scope.sortcolumn = ''; 


	// test Pagination 
	// il faut resoudre le probleme de etablissement.length
	$scope.noOfPages = Math.ceil($scope.total/$scope.rpp);
  	//$scope.currentPage = 4;
  	$scope.currentPage = 1; 
  	$scope.maxSize = 3;
  
	$scope.setPage = function (pageNo) {
	   $scope.currentPage = pageNo;
	};

	// $scope.sort = function(){
		// sort acccording to sortDirection and sortcolumn
		// i think i need to write a filter here 

	//};

	// $scope.pagedResult = function(){

		//}; 

	//$scope.search(); 
	//console.log($scope.recordParPage);  
}

function UserCtrl($scope, $http){

	// find the cookie value
	$scope.session_key = "3qauE3IohE3yxdYX4pznOg"; 
	$scope.url = '../user'; 
	$scope.limit = 10;
	$scope.currentPage = 1;
	$scope.recordParPage = [10, 25, 50, 100];    
	$scope.params = {"session_key": "3qauE3IohE3yxdYX4pznOg", "limit": $scope.limit, "page": $scope.currentPage}
    // query friends method
    $scope.noOfPages = 1;
    $scope.request = $scope.url+"?session_key="+$scope.session_key+"&limit="+$scope.limit+"&page="+$scope.currentPage;

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

    $scope.setPage = function(){
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

UserCtrl.$inject=['$scope', '$http']; 

/* 
window.LoginCtrl = ($scope, $location, User) ->
    $scope.login = ->
        User.login $scope.username, $scope.password, (result) ->
            if !result
                window.alert('Authentication failed!')
            else
                $scope.$apply -> $location.path('/assignments')
 
window.AssignmentListCtrl = ($scope, User) ->
    $scope.User = User  
*/



function MyCtrl2() {
}
MyCtrl2.$inject = [];
