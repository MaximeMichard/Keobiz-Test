public class AccountTriggerHandler {
    public static void handleCancelledMissions(List<Account> updatedAccounts) {
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Account acc : updatedAccounts) {
            if (acc.MissionStatus__c == 'canceled' && acc.MissionCanceledDate__c == null) {
                // Mettre à jour la date d'annulation
                acc.MissionCanceledDate__c = Date.today();
            }

            // Vérifier le statut d'activité des contacts
            if (acc.MissionStatus__c == 'canceled') {
                List<AccountContactRelation> accountContactRelations = [SELECT ContactId FROM AccountContactRelation WHERE AccountId = :acc.Id];
                Set<Id> contactIds = new Set<Id>();

                for (AccountContactRelation acr : accountContactRelations) {
                    contactIds.add(acr.ContactId);
                }

                List<Contact> relatedContacts = [SELECT Id, IsActive__c FROM Contact WHERE Id IN :contactIds];

                Boolean allCancelled = true;
                for (Contact con : relatedContacts) {
                    if (con.IsActive__c) {
                        allCancelled = false;
                        break;
                    }
                }

                if (allCancelled) {
                    acc.IsActive__c = false;
                }

                contactsToUpdate.addAll(relatedContacts);
            }
        }

        update updatedAccounts; // Mettre à jour les comptes

        // Appel à la classe d'API pour synchroniser les contacts
        ContactSyncAPI.syncContactStatus(contactsToUpdate);
    }
}