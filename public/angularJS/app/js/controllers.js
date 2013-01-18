'use strict';

/* Controllers */


function MyCtrl1($scope, Etablissement) {
	//$scope.etablissements = Etablissement.query();
    
}
//MyCtrl1.$inject = [];


function EtabCtrl($scope, Etablissement, $filter){
	
	$scope.etablissements = Etablissement.query(function(result){
		$scope.total = result.length; 
	}); 

	var etabs = Etablissement.query(function(){
		var length = etabs.length; 
	});
 
    console.log($scope.etablissements instanceof Array);
    console.log($scope.etablissements); 
	
	//console.log(etabs.length);
	// why etab.length does not work. 

 	var etab = Etablissement.get({id:'1'}, function(){
 		//console.log(etab.nom); 
 		//console.log(etab.id); 
 	});
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


function MyCtrl2() {
}
MyCtrl2.$inject = [];
