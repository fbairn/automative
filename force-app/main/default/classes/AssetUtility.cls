public inherited sharing class AssetUtility {
    public static void countVehicles(List<Asset> vehicles, List<Asset> oldVehicles) {
        Set<Id> accountIds = new Set<Id>();
        for (Asset vehicle : vehicles) {
            accountIds.add(vehicle.AccountId);
        }
        for (Asset vehicle : oldVehicles) {
            accountIds.add(vehicle.AccountId);
        }


        List<Account> updateAccounts = new List<Account>();
        for(AggregateResult count : [SELECT AccountId, COUNT(Id) vehicleCount
                                     FROM Asset
                                     WHERE AccountId IN :accountIds
                                     GROUP BY AccountId]) {
            updateAccounts.add(new Account(
                                   id = (Id)count.get('AccountId'),
                                   Vehicle_Count__c = (Decimal)count.get('vehicleCount')
                                   ));
        }
        update updateAccounts;
    }
}