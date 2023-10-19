@IsTest
public inherited sharing class VehicleFinderControllerTest {
    @IsTest
    public static void returnsOptions(){
        Manufacture__c maker = new Manufacture__c(Name = 'Test');
        insert maker;

        Model__c model = new Model__c(Name = '007', Manufacture__c = maker.Id);
        insert model;

        Test.startTest();
        VehicleFinderController.SearchOptions results = VehicleFinderController.getSearchOptions();
        Test.stopTest();

        System.assertEquals(1, results.makes.size(),'Make count is not correct.');
        System.assertEquals(maker.Id, results.makes[0].value, 'Make value is orrect.');
        System.assertEquals(maker.Name, results.makes[0].label, 'Make label not correct.');

        System.assertEquals(1, results.models.size(),'Model count is not correct.');
        System.assertEquals(model.Id, results.models[0].value, 'Model value is not correct.');
        System.assertEquals(model.Name, results.models[0].label, 'Model label not correct.');

    }
}