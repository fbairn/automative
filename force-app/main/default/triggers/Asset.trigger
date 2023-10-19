trigger Asset on Asset (after insert, after update) {
    AssetUtility.countVehicles(Trigger.new, Trigger.old);
}