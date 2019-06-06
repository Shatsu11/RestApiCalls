/**
 * Created by BRITENET on 03.06.2019.
 */

public with sharing class R2G_SearchRestController {
    public List<R2G_Utils.R2G_CarWrapper> queriedCars { get; set; }
    public Integer year { get; set; }
    public String model { get; set; }
    public String brand { get; set; }
    public String country { get; set; }
    public String calloutResult { get; set; }
    public Boolean calloutOperationResult { get; set; }
    public R2G_CarDTO newCar { get; set; }
    public String selectedCarName { get; set; }
    public String selectedContactName { get; set; }
    public String selectedCarId { get; set; }
    public Boolean secondAttempt { get; set; }
    public R2G_Utils.R2G_CarWrapper selectedCarObject { get; set; }
    public static final String CREDENTIALS_CS = 'KarDyl2';
    public static final String REST_SERVICE_CS = 'Org2';
    public static final String RESULT_SUCCESS = 'Success';

    public R2G_SearchRestController() {
        queriedCars = new List<R2G_Utils.R2G_CarWrapper>();
        newCar = new R2G_CarDTO();
        calloutOperationResult = false;
        selectedCarId = '';
        selectedCarName = '';
        secondAttempt = false;
    }

    public PageReference clearFields() {
        model = '';
        brand = '';
        year = null;
        country = '';
        queriedCars.clear();
        return null;
    }

    public void calloutSuccessful() {
        calloutOperationResult = true;
        calloutResult = '';
        getCarsFromExternalService();
    }

    public PageReference clearNewCarFields() {
        newCar = new R2G_CarDTO();
        calloutResult = '';
        calloutOperationResult = false;
        return null;
    }

    public PageReference saveNewCarExternalService() {
        calloutOperationResult = false;
        calloutResult = R2G_RestHandler.saveNewCar(REST_SERVICE_CS,CREDENTIALS_CS,newCar);
        if (calloutResult == RESULT_SUCCESS) {
            calloutSuccessful();
            getCarsFromExternalService();
        }
        return null;
    }

    public PageReference editCarExternalService() {
        calloutOperationResult = false;
        calloutResult = R2G_RestHandler.editCar(REST_SERVICE_CS,CREDENTIALS_CS,selectedCarObject);
        if (calloutResult == RESULT_SUCCESS) {
            calloutSuccessful();
            getCarsFromExternalService();
        }
        return null;
    }

    public PageReference getCarsFromExternalService() {
        queriedCars.clear();
        queriedCars = R2G_RestHandler.getCar(REST_SERVICE_CS, CREDENTIALS_CS,brand,model,year,country,this);
        return null;
    }

    public PageReference deleteCarExternalService() {
        calloutOperationResult = false;
        calloutResult = R2G_RestHandler.deleteCar(REST_SERVICE_CS, CREDENTIALS_CS,selectedCarId);
        if (calloutResult == RESULT_SUCCESS) {
            calloutSuccessful();
            getCarsFromExternalService();
        }
        return null;
    }
}