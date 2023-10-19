trigger Interest on Interest__c (before insert, before update) {
    Set<Id> vehcileIds = new Set<Id>();
    for (Interest__c interest : Trigger.new) {
        vehcileIds.add(interest.Vehicle__c);
    }

    Map<Id,Asset> vehicles = new Map<Id,Asset>([SELECT ID, Year__c, Make__r.name, Model__r.name
                                                FROM Asset
                                                WHERE Id IN: vehcileIds]);
    for (Interest__c interest : Trigger.new) {
        Asset vehicle = vehicles.get(interest.Vehicle__c);
        interest.name = vehicle.Year__c + ' ' + vehicle.Make__r.name + ' ' + vehicle.Model__r.name;
    }
}