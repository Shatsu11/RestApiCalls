/**
 * Created by BRITENET on 03.06.2019.
 */

public with sharing class R2G_SearchRestController {
    public List<R2G_Utils.R2G_CarWrapper> queriedCars { get; set; }

    //TODO: Filtry powinny być w oddzielnej klasie np. SearchCriteria
    public Integer year { get; set; }
    public String model { get; set; }
    public String brand { get; set; }
    public String country { get; set; }

    //TODO: Result powien być obiektem zawierającym inforamcje o rezultacie zapytania. Czy potrzebujesz trzymać te inforamcje w kontrolerze? 
    public String calloutResult { get; set; }
    public Boolean calloutOperationResult { get; set; }
    public R2G_CarDTO newCar { get; set; }

    //TODO: IMO te to powinna być oddzielan klasa z infrmacjami o wyborze
    public String selectedCarName { get; set; }
    public String selectedContactName { get; set; }
    public String selectedCarId { get; set; }

    //TODO: Wut? 
    public Boolean secondAttempt { get; set; }
    public R2G_Utils.R2G_CarWrapper selectedCarObject { get; set; }

    //TODO: Wut v2? Powinno to być w Custom settingu/Custom Metadata Type 
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

    //TODO: Po co ta metoda? 
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

    //TODO: Metody saveNewCarExternalService, editCarExternalService, deleteCarExternalService i getCarsFromExternalService zawierają logikę biznsową. Najprościej jest je przenieść do kalst CarService i ją wywoływać z kontrolera. Chdzoi o to, e jak byś chciał wywołać te kalsy w inny miejscu to musisz towrzyć instancję kontrolera i łączysz wartwę UI z logiką biznesową co generalnie jest złym pomysłem.
    // Przykładowa imple, tacja 

    // public PageReference editCarExternalService() {
    //     Car service = new CarSerbvice(); 
    //     CarServiceResult result = service.editCar(REST_SERVICE_CS,CREDENTIALS_CS,selectedCarObject);
    //      handleREulst(result);   
    
    //     return null;
    // }

    // private void handleResult(CarServiceResult result){
    //     if(result.isSuccess()){
    //         addPageMessage(result.message,ApexPages.severity.INFO)
    //     else {
    //         addPageMessage(reusult.message, ApexPages.severity.Error);
    //     }
    // }

    // private void addPageMessage(String message, ApexPages.severity severity){
    //     ApexPages.addmessage(new ApexPages.message(severity, message));
    // }

    //TODO: Kompletnie nie rozumime o co chodzi  z tym calloutOperationResult. Do czego to słuzy? Jest to raczej zły design   
    public PageReference saveNewCarExternalService() {
        calloutOperationResult = false;
        calloutResult = R2G_RestHandler.saveNewCar(REST_SERVICE_CS,CREDENTIALS_CS,newCar);
        //TODO: takie coś jest bez sensu. Dlaczego nie boolean z informacją o sukcesie? Jakbyś miał klase z rezultatem to tam mógbyś mieć metocę co zawiera tą informację 
        if (calloutResult == RESULT_SUCCESS) {
            calloutSuccessful();
            //Dlaczego robisz get ponownie? Nie mówię, ze źle... tlyko ptyam 
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