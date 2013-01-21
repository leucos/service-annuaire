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

	$scope.url = '../user';
	$scope.params = {"session_key": "3qauE3IohE3yxdYX4pznOg", "limit": $scope.limit, "page": $scope.currentPage}
	$scope.limit = 10;
	$scope.currentPage = 1;
	$scope.recordParPage = [10, 25, 50, 100];    
    // query friends method
    $scope.noOfPages = 1; 
    $scope.listUsers = function() {
      // call GET http method
      $http.get($scope.url+"?session_key=3qauE3IohE3yxdYX4pznOg&limit=10&page=2", {"session_key": "3qauE3IohE3yxdYX4pznOg", "limit":10, "page":2}).success(function (data) {
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
    


} 

UserCtrl.$inject=['$scope', '$http']; 

  



function MyCtrl2() {
}
MyCtrl2.$inject = [];
