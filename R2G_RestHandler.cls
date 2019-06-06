/**
 * Created by BRITENET on 04.06.2019.
 */
//TODO: Cała klasa do przemyślenia i przepisania. 
public with sharing class R2G_RestHandler {

    //Dlaczego static? Wszystkie metody masz statyczne i przekrzucasz w paramterach wartości. Lepiej jest zainicjować stan i w metodach prywatnych z nich koysrzystać. Generalnie statickki są be i nie zaakceptuje tego rozwiązania tak długo jak będą w tej kalsie static
    //Dlaczego wszystko public?  
    public static HttpRequest getRequest(String method, String csEndpoint, String csCredentials,
            String endpointParams, String requestBody) {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(getEndpoint(csEndpoint, endpointParams));
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', getAccessTokenToEndpoint(csCredentials));
        if (requestBody != null) {
            request.setBody(requestBody);
        }
        return request;
    }


    public static String getEndpoint(String csName, String params) {
        R2G_RestCalloutsEndpoint__c csItem = R2G_RestCalloutsEndpoint__c.getInstance(csName);
        if (params != null) {
            return csItem.Endpoint__c + '?' + params;
        }
        return csItem.Endpoint__c;
    }

    public static Boolean isTokenAvailable() {
        return ((String) Cache.Session.get('token') != null);
    }

    public static String getAccessTokenToEndpoint(String csCredentials) {
        if (isTokenAvailable()) {
            return (String) Cache.Session.get('token');
        } else {
            return updateAccessToken(csCredentials);
        }
    }

    public static Boolean verifyEndpointAuthorization(Integer responseCode, String csCredentials){
        if (responseCode == 400 || responseCode == 401) {
            R2G_RestHandler.updateAccessToken(csCredentials);
            return false;
        }
        return true;
    }

    public static void verifyEditOperationSuccess(Integer responseCode, R2G_Utils.R2G_CarWrapper selectedCarObject){
        if (responseCode !=200){
            selectedCarObject.car = selectedCarObject.carToRollback;
        }
    }

    public static String updateAccessToken(String csCredentials) {
        R2G_LoginResponseBodyWrapper loginResponse = getExternalServiceAccessToken(csCredentials);
        String token = 'Bearer ' + loginResponse.access_token;
        //TODO: zmieniłbym nazwę na car-token czy coś ... i przerzucił ją do CS, a nie zahardcodowaną
        Cache.Session.put('token', token, 28800);
        return (String) Cache.Session.get('token');
    }

    public static R2G_LoginResponseBodyWrapper getExternalServiceAccessToken(String csCredentials) {
        ExternalServiceOAuth2Credentials__c externalCredentials = ExternalServiceOAuth2Credentials__c.getInstance(csCredentials);
        if (externalCredentials == null) {
            return null;
        }
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(externalCredentials.loginUri__c);
        req.setBody(buildLoginCredentialsUri(externalCredentials));
        R2G_LoginResponseBodyWrapper loginResponseBody = (R2G_LoginResponseBodyWrapper) JSON.deserialize(authorizationCalloutResponse(req), R2G_LoginResponseBodyWrapper.class);
        return loginResponseBody;
    }

    public static String authorizationCalloutResponse(HttpRequest request) {
        Http http = new Http();
        HTTPResponse response = http.send(request);
        return response.getBody();
    }

    //Nie lpeije zro
    public static String buildLoginCredentialsUri(ExternalServiceOAuth2Credentials__c externalCredentials) {
        return 'grant_type=' + externalCredentials.grant_type__c +
                '&client_id=' + externalCredentials.client_id__c +
                '&client_secret=' + externalCredentials.client_secret__c +
                '&username=' + externalCredentials.username__c +
                '&password=' + externalCredentials.password__c;
    }

// dlaczego tworzysz jsona w taki sposób? Nie lepiej wraper i JSON.seriallize? 
    public static String buildPUTRequestBody(R2G_Utils.R2G_CarWrapper selectedCarObject) {
        return '{"car":{'
                + '"brand":"' + selectedCarObject.car.Brand__c
                + '","model":"' + selectedCarObject.car.Model__c
                + '","year":"' + selectedCarObject.year
                + '","country":"' + selectedCarObject.car.Country__c
                + '","vin":"' + selectedCarObject.car.VIN__c
                + '","regNumber":"' + selectedCarObject.car.Registration_Number__c
                + '","id":"' + selectedCarObject.car.Id
                + '"}}';
    }

    public static String buildPostRequestBody(R2G_CarDTO newCar) {
        return '{"car":{'
                + '"brand":"' + newCar.brand
                + '","model":"' + newCar.model
                + '","year":"' + newCar.year
                + '","country":"' + newCar.country
                + '","vin":"' + newCar.vin
                + '","regNumber":"' + newCar.regNumber
                + '"}}';
    }

    public static List<R2G_Utils.R2G_CarWrapper> wrapRequestedCars(String responseBody, R2G_SearchRestController ctr) {
        list <R2G_CarDTO> carWrappers = (List<R2G_CarDTO>) JSON.deserialize(responseBody, List<R2G_CarDTO>.class);
        List<R2G_Utils.R2G_CarWrapper> wrappedCars = new List<R2G_Utils.R2G_CarWrapper>();
        for (R2G_CarDTO c : carWrappers) {
            wrappedCars.add(new R2G_Utils.R2G_CarWrapper(c, ctr));
        }
        return wrappedCars;
    }

    public static String getSerializedParametersMap(String brand, String model, Integer year, String country) {
        Map<String, String> paramsMap = new Map<String, String>();
        paramsMap.put('brand', brand);
        paramsMap.put('model', model);
        year = (year == null) ? 0 : year;
        paramsMap.put('year', String.valueOf(year));
        paramsMap.put('country', country);
        return serializeMapToString(paramsMap);
    }

    public static String serializeMapToString(Map<String, String> paramsMap) {
        String output;
        for (String parameterValue : paramsMap.keySet()) {
            output = output + '&' + parameterValue + '=' + paramsMap.get(parameterValue);
        }
        return output;
    }

    public static HttpResponse saveNewCarCallout(String CsRestService, String CsCredentials,R2G_CarDTO newCar){
        HttpRequest request = R2G_RestHandler.getRequest('POST', CsRestService, CsCredentials, null,
                R2G_RestHandler.buildPostRequestBody(newCar));
        HttpResponse response = new Http().send(request);
        return response;
    }

    public static HttpResponse editCarCallout(String CsRestService, String CsCredentials,R2G_Utils.R2G_CarWrapper selectedCarObject){
        HttpRequest request = R2G_RestHandler.getRequest('PUT', CsRestService, CsCredentials, null,
                R2G_RestHandler.buildPUTRequestBody(selectedCarObject));
        HttpResponse response = new Http().send(request);
        return response;
    }

    public static HttpResponse getCarCallout(String CsRestService, String CsCredentials, String parameters){
        HttpRequest request = R2G_RestHandler.getRequest('GET', CsRestService, CsCredentials, parameters, null);
        HttpResponse response = new Http().send(request);
        return response;
    }

    public static HttpResponse deleteCarCallout(String CsRestService, String CsCredentials, String selectedCarId){
        HttpRequest request = R2G_RestHandler.getRequest('DELETE', CsRestService, CsCredentials, 'id=' + selectedCarId, null);
        HttpResponse response = new Http().send(request);
        return response;
    }

    public static String saveNewCar(String CsRestService, String CsCredentials,R2G_CarDTO newCar){
        HttpResponse response = R2G_RestHandler.saveNewCarCallout(CsRestService,CsCredentials,newCar);
        if (!R2G_RestHandler.verifyEndpointAuthorization(response.getStatusCode(),CsCredentials)) {
            response = R2G_RestHandler.saveNewCarCallout(CsRestService,CsCredentials,newCar);
        }
        return (String) JSON.deserializeUntyped(response.getBody());
    }

    public static String editCar(String CsRestService, String CsCredentials,R2G_Utils.R2G_CarWrapper selectedCarObject){
        HttpResponse response = R2G_RestHandler.editCarCallout(CsRestService,CsCredentials,selectedCarObject);
        if (!R2G_RestHandler.verifyEndpointAuthorization(response.getStatusCode(),CsCredentials)) {
            response = R2G_RestHandler.editCarCallout(CsRestService,CsCredentials,selectedCarObject);
        }
        R2G_RestHandler.verifyEditOperationSuccess(response.getStatusCode(),selectedCarObject);
        return (String) JSON.deserializeUntyped(response.getBody());
    }

    public static List<R2G_Utils.R2G_CarWrapper> getCar(String CsRestService, String CsCredentials,String brand, String model,
            Integer year, String country, R2G_SearchRestController parentCtr){
        String parameters = R2G_RestHandler.getSerializedParametersMap(brand,model,year,country);
        HttpResponse response = R2G_RestHandler.getCarCallout(CsRestService,CsCredentials,parameters);
        if (!R2G_RestHandler.verifyEndpointAuthorization(response.getStatusCode(),CsCredentials)) {
            response = R2G_RestHandler.getCarCallout(CsRestService,CsCredentials,parameters);
        }
        if (response.getStatusCode() == 200) {
            return R2G_RestHandler.wrapRequestedCars(response.getBody(), parentCtr);
        }
        return null;
    }

    public static String deleteCar(String CsRestService, String CsCredentials,String selectedCarId){
        HttpResponse response = R2G_RestHandler.deleteCarCallout(CsRestService,CsCredentials,selectedCarId);
        if (!R2G_RestHandler.verifyEndpointAuthorization(response.getStatusCode(),CsCredentials)) {
            response = R2G_RestHandler.deleteCarCallout(CsRestService,CsCredentials,selectedCarId);
        }
        return (String) JSON.deserializeUntyped(response.getBody());
    }

    public with sharing class R2G_LoginResponseBodyWrapper {
        public String access_token { get; set; }
        public String instance_url { get; set; }
        public String id { get; set; }
        public String token_type { get; set; }
        public String issued_at { get; set; }
        public String signature { get; set; }
    }

}