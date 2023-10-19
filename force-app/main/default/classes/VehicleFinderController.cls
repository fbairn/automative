public without sharing class VehicleFinderController {
    @AuraEnabled(Cacheable = true)
    public static SearchOptions getSearchOptions(){
        SearchOptions options = new SearchOptions();
        //Populate the Make options
        for(Manufacture__c make: [SELECT ID, Name
                                  FROM Manufacture__c
                                  ORDER By Name]) {
            options.makes.add(new OptionModel(make.name, make.Id));
        }

        //Populate the Model options
        for(Model__c model: [SELECT ID, Name
                             FROM Model__c
                             ORDER By Name]) {
            options.models.add(new OptionModel(model.name, model.Id));
        }

        //Populate the Body options
        options.bodies = picklistToOptions(Asset.Body_Style__c.getDescribe());

        //Populate the Color options
        options.colors = picklistToOptions(Asset.Color__c.getDescribe());

        return options;
    }

    @AuraEnabled
    public static List<VehicleMatch> vehicleSearch(String searchJSON){
        try {
            FinderData searchData = (FinderData)JSON.deserialize(searchJSON, FinderData.class);
            //Create the list of Vehicle matches
            List<VehicleMatch> matchList = new List<VehicleMatch>();
            for (Asset vehicle : [SELECT Year__c, Body_Style__c, Color__c, New_Used__c, Price,
                                  Make__r.name, Model__r.name, Account.name
                                  FROM Asset Where Status = 'On Lot' AND Account.RecordType.DeveloperName = 'Dealership']) {
                matchList.add(new VehicleMatch(vehicle).setScore(searchData));
            }

            matchList.sort();

            //Remove matches with less than 20% score
            for (Integer i = matchList.size() - 1; i >= 0; i--) {
                if(matchList[i].score < .2) {
                    matchList.remove(i);
                }
            }
            return matchList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static FinderData getLead(Id recordId){
        try {
            List<Lead> leads = [SELECT Id, FirstName, LastName, Company, Phone, Email, Min_Year__c, Max_Year__c,
                                Make__c, Model__c, Body_Style__c, Color__c, Credit_Range__c, Desired_Payment__c, Est_Vehicle_Price__c
                                FROM Lead
                                WHERE Id =:recordId];
            if(leads.isEmpty()) {
                throw new AuraHandledException('Lead Id is not valid. No lead found');
            }

            FinderData searchData = new FinderData();
            searchData.firstName = leads[0].FirstName;
            searchData.lastName = leads[0].LastName;
            searchData.phone = leads[0].Phone;
            searchData.email = leads[0].Email;
            searchData.minYear = (Integer)leads[0].Min_Year__c;
            searchData.maxYear = (Integer)leads[0].Max_Year__c;
            searchData.makeId = leads[0].Make__c;
            searchData.modelId = leads[0].Model__c;
            searchData.bodyStyle = leads[0].Body_Style__c;
            searchData.color = leads[0].Color__c;
            searchData.credit = leads[0].Credit_Range__c;
            searchData.payment = leads[0].Desired_Payment__c;
            searchData.estPrice = leads[0].Est_Vehicle_Price__c;

            return searchData;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Id saveLead(String searchJSON){
        try {
            FinderData searchData = (FinderData)JSON.deserialize(searchJSON, FinderData.class);
            Lead newLead = new Lead(
                FirstName = searchData.firstName,
                LastName = searchData.lastName,
                Company = searchData.lastName + ', ' + searchData.firstName,
                phone = searchData.phone,
                email = searchData.email,
                Min_Year__c = searchData.minYear,
                Max_Year__c = searchData.maxYear,
                Make__c = String.IsNotBlank(searchData.makeId) ? searchData.makeId : null,
                Model__c = String.IsNotBlank(searchData.modelId) ? searchData.modelId : null,
                Body_Style__c = searchData.bodyStyle,
                Color__c = searchData.color,
                Credit_Range__c = searchData.credit,
                Desired_Payment__c = searchData.payment,
                Est_Vehicle_Price__c = searchData.estPrice
                );
            if(searchData.recordId != null) {
                newLead.Id = searchData.recordId;
            }
            upsert newLead;
            return newLead.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<OptionModel> picklistToOptions(Schema.DescribeFieldResult fieldResult){
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<OptionModel> options = new List<OptionModel>();
        for( Schema.PicklistEntry pickListVal : ple) {
            options.add(new OptionModel(pickListVal.getLabel(), pickListVal.getValue()));
        }
        return options;
    }

    public class OptionModel {
        @AuraEnabled
        public string label;
        @AuraEnabled
        public string value;

        public OptionModel(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public class SearchOptions {
        @AuraEnabled
        public List<OptionModel> makes = new List<OptionModel>();

        @AuraEnabled
        public List<OptionModel> models = new List<OptionModel>();

        @AuraEnabled
        public List<OptionModel> bodies = new List<OptionModel>();

        @AuraEnabled
        public List<OptionModel> colors = new List<OptionModel>();
    }

    public class VehicleMatch implements Comparable {
        @AuraEnabled
        public Id Id;
        @AuraEnabled
        public Integer year;
        @AuraEnabled
        public String make;
        public Id makeId;
        @AuraEnabled
        public String model;
        public Id modelId;
        @AuraEnabled
        public String bodyStyle;
        @AuraEnabled
        public String color;
        @AuraEnabled
        public Decimal price;
        @AuraEnabled
        public String location;
        @AuraEnabled
        public String newUsed;
        @AuraEnabled
        public Decimal score;

        public VehicleMatch(Asset vehicle){
            id = vehicle.Id;
            year = Integer.valueOf(vehicle.Year__c);
            make = vehicle.Make__r.name;
            makeId = vehicle.Make__c;
            model = vehicle.Model__r.name;
            modelId = vehicle.Model__c;
            bodyStyle = vehicle.Body_Style__c;
            color = vehicle.Color__c;
            price = vehicle.price;
            location = vehicle.Account.name;
            newUsed = vehicle.New_Used__c;
            score = 0;
        }

        public VehicleMatch setScore(FinderData searchData){
            Decimal totalPos = 0.05;
            if(String.IsNotBlank(searchData.makeId)) {
                totalPos = totalPos + .2;
            }
            if(String.IsNotBlank(searchData.modelId)) {
                totalPos = totalPos + .2;
            }
            if(String.IsNotBlank(searchData.bodyStyle)) {
                totalPos = totalPos + .1;
            }
            if(String.IsNotBlank(searchData.color)) {
                totalPos = totalPos + .05;
            }
            if(searchData.estPrice != null) {
                totalPos = totalPos + .4;
            }

            score = 0;
            if(year >= searchData.minYear && year <= searchData.maxYear) {
                score = score + .05;
            }
            if(String.IsNotBlank(searchData.makeId) && makeId == searchData.makeId) {
                score = score + .2;
            }

            if(String.IsNotBlank(searchData.modelId) && modelId == searchData.modelId) {
                score = score + .2;
            }

            if(String.IsNotBlank(searchData.bodyStyle) && bodyStyle == searchData.bodyStyle) {
                score = score + .1;
            }

            if(String.IsNotBlank(searchData.color) && color == searchData.color) {
                score = score + .05;
            }

            if(searchData.estPrice != null && price <= searchData.estPrice) {
                score = score + .4;
            }
            score = (score / totalPos).setScale(2);
            return this;
        }

        public Integer compareTo(Object compareTo) {
            VehicleMatch compareToVehicle = (VehicleMatch)compareTo;
            if (score == compareToVehicle.score) {return 0;}
            if (score > compareToVehicle.score) { return -1;}
            return 1;
        }
    }

    public class FinderData {
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public string firstName;
        @AuraEnabled
        public string lastName;
        @AuraEnabled
        public string phone;
        @AuraEnabled
        public string email;
        @AuraEnabled
        public Integer minYear;
        @AuraEnabled
        public Integer maxYear;
        @AuraEnabled
        public string makeId;
        @AuraEnabled
        public string modelId;
        @AuraEnabled
        public string bodyStyle;
        @AuraEnabled
        public string color;
        @AuraEnabled
        public string credit;
        @AuraEnabled
        public Decimal payment;
        @AuraEnabled
        public Decimal estPrice;
    }
}