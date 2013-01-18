'use strict';

/* jasmine specs for controllers go here */

describe('myApp controllers', function(){


  beforeEach(function(){
    this.addMatchers({
      toEqualData: function(expected) {
        return angular.equals(this.actual, expected);
      }
    });
  });

  beforeEach(module('myApp.services'));

  describe('MyCtrl1', function(){
    var myCtrl1;

    beforeEach(function(){
      myCtrl1 = new MyCtrl1();
    });


    it('should ....', function() {
      //spec body
    });
  });


  describe('MyCtrl2', function(){
    var myCtrl2;


    beforeEach(function(){
      myCtrl2 = new MyCtrl2();
    });


    it('should ....', function() {
      //spec body
    });
  });


  describe('EtabCtrl', function(){

    //  intilization  and injection  with mockup backend
    // i must have a way to use existing data
    var scope, ctrl, $httpBackend;
    beforeEach(inject(function(_$httpBackend_, $rootScope, $controller) {
      $httpBackend = _$httpBackend_;
      $httpBackend.expectGET('../etablissement').respond([{"json_class":"Etablissement","id":1,"code_uai":null,"nom":"ERASME","siren":null,"adresse":null,"code_postal":null,"ville":null,"telephone":null,"fax":null,"longitude":null,"latitude":null,"date_last_maj_aaf":null,"nom_passerelle":null,"ip_pub_passerelle":null,"type_etablissement_id":1},
        {"json_class":"Etablissement","id":2,"code_uai":"0691670R","nom":"Victor Dolto","siren":null,"adresse":null,"code_postal":null,"ville":null,"telephone":null,"fax":null,"longitude":null,"latitude":null,"date_last_maj_aaf":null,"nom_passerelle":null,"ip_pub_passerelle":null,"type_etablissement_id":2},
        {"json_class":"Etablissement","id":3,"code_uai":"0690016T","nom":"FranÃ§oise Kandelaft","siren":null,"adresse":null,"code_postal":null,"ville":null,"telephone":null,"fax":null,"longitude":null,"latitude":null,"date_last_maj_aaf":null,"nom_passerelle":null,"ip_pub_passerelle":null,"type_etablissement_id":2}]);
      
      scope = $rootScope.$new();
      ctrl = $controller(EtabCtrl, {$scope: scope});
    }));
    
    it('should have etablissements in scope variables', function(){
      expect(scope.etablissements).toEqual([]);
      $httpBackend.flush();
 
      expect(scope.etablissements.length).toBe(3);
      expect(scope.etablissements).toEqualData([{"json_class":"Etablissement","id":1,"code_uai":null,"nom":"ERASME","siren":null,"adresse":null,"code_postal":null,"ville":null,"telephone":null,"fax":null,"longitude":null,"latitude":null,"date_last_maj_aaf":null,"nom_passerelle":null,"ip_pub_passerelle":null,"type_etablissement_id":1},
        {"json_class":"Etablissement","id":2,"code_uai":"0691670R","nom":"Victor Dolto","siren":null,"adresse":null,"code_postal":null,"ville":null,"telephone":null,"fax":null,"longitude":null,"latitude":null,"date_last_maj_aaf":null,"nom_passerelle":null,"ip_pub_passerelle":null,"type_etablissement_id":2},
        {"json_class":"Etablissement","id":3,"code_uai":"0690016T","nom":"FranÃ§oise Kandelaft","siren":null,"adresse":null,"code_postal":null,"ville":null,"telephone":null,"fax":null,"longitude":null,"latitude":null,"date_last_maj_aaf":null,"nom_passerelle":null,"ip_pub_passerelle":null,"type_etablissement_id":2}]); 

    });

    it('should connect to remote apis', function(){
        // i dont know how to do this 
        // additionally the distinction between $inject, $injector.
        // 
    });

    it('should be able to get paginated data', function(){

    });

    it('should be able to do search', function(){

    }); 

    it('should be able to sort the database', function(){

    }); 

    it('should be able to show  a grid with pagination toolbar and search toolbar', function(){

    }); 



    /*
    it('should show test value', function(){
       expect(scope.testval).toBe('testval');
    });
    */



  }); 
});