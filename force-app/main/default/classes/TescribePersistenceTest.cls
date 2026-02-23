@IsTest
private class TescribePersistenceTest {
    // ============================================================================
    // 1. DML EXECUTION (save)
    // ============================================================================

    @IsTest
    static void shouldInsertRecordsAndReturnIds() {
        // GIVEN a builder configured for 2 accounts
        Tescribe builder = Tescribe.builder(Account.SObjectType)
            .repeat(2)
            .setFieldValue(Account.Name, 'Persistence Test {alpha}');

        // WHEN save is called
        Test.startTest();
        List<Account> results = (List<Account>) builder.save();
        Test.stopTest();

        // THEN the records should have IDs and be found in the database
        Assert.isNotNull(results[0].Id, 'First record must have an ID');
        Assert.isNotNull(results[1].Id, 'Second record must have an ID');

        List<Account> dbCheck = [SELECT Id FROM Account WHERE Id IN :results];
        Assert.areEqual(2, dbCheck.size(), 'Two records should be persisted to the database');
    }

    @IsTest
    static void shouldHandleRelationalPersistence() {
        // GIVEN a persisted parent Account
        Account parent = (Account) Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.Name, 'Parent Org')
            .save()[0];

        // WHEN building children using the parent ID
        List<Contact> children = (List<Contact>) Tescribe.builder(Contact.SObjectType)
            .repeat(3)
            .setFieldValue(Contact.AccountId, parent.Id)
            .setFieldValue(Contact.LastName, 'Child {counter}')
            .save();

        // THEN all children should be linked to the parent in the database
        List<Contact> dbChildren = [SELECT Id FROM Contact WHERE AccountId = :parent.Id];
        Assert.areEqual(3, dbChildren.size(), 'All 3 children should be linked to the same parent');
    }

    // ============================================================================
    // 2. STATE MANAGEMENT (globalSequence)
    // ============================================================================

    @IsTest
    static void shouldIncrementGlobalSequenceBetweenBuilds() {
        // GIVEN two different builder instances
        Tescribe builder1 = Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.Name, '{random}');
        Tescribe builder2 = Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.Name, '{random}');

        // WHEN both are built
        List<Account> res1 = (List<Account>) builder1.build();
        List<Account> res2 = (List<Account>) builder2.build();

        // THEN the {random} token (which uses globalSequence) should produce different prefixes
        // Note: globalSequence increments on every build() call in Tescribe.cls
        Assert.areNotEqual(
            res1[0].Name,
            res2[0].Name,
            'Random tokens should be unique across different builds'
        );
    }

    // ============================================================================
    // 3. BULK PERSISTENCE LIMITS
    // ============================================================================

    @IsTest
    static void shouldHandleBulkInsertsEfficiently() {
        // GIVEN a request for a larger volume of records
        Integer bulkSize = 50;

        Test.startTest();
        // WHEN saving a bulk batch
        List<Account> bulkAccs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(bulkSize)
            .setFieldValue(Account.Name, 'Bulk {counter}')
            .save();

        // THEN it should only consume 1 DML statement
        // FIX: Assert while the Test limits are still active
        Assert.areEqual(
            1,
            Limits.getDmlStatements(),
            'Bulk save should be optimized to 1 DML statement'
        );
        Test.stopTest();

        Assert.areEqual(bulkSize, bulkAccs.size());
    }
}
