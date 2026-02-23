@IsTest
private class TescribeAssignmentTest {
    // ============================================================================
    // 1. SINGLE VALUE ASSIGNMENT (setFieldValue)
    // ============================================================================

    @IsTest
    static void shouldAssignValueUsingSObjectField() {
        // GIVEN a strongly-typed field assignment
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.Industry, 'Energy')
            .build();

        // THEN it should map correctly
        Assert.areEqual('Energy', accs[0].Industry);
    }

    @IsTest
    static void shouldAssignValueUsingStringFieldName() {
        // GIVEN a string-based field assignment
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .setFieldValue('Industry', 'Banking')
            .build();

        // THEN it should map correctly
        Assert.areEqual('Banking', accs[0].Industry);
    }

    @IsTest
    static void shouldApplyToAllRecordsWhenSelectorsAreEmpty() {
        // Targets Line 42: specificIndices.isEmpty() && ranges.isEmpty()
        // GIVEN a builder with 3 records and a rule with NO selectors
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(3)
            .setFieldValue(Account.Industry, 'Technology')
            .build();

        // THEN every record should have the value
        Assert.areEqual('Technology', accs[0].Industry);
        Assert.areEqual('Technology', accs[1].Industry);
        Assert.areEqual(
            'Technology',
            accs[2].Industry,
            'Rule should apply globally if no selectors exist'
        );
    }

    // ============================================================================
    // 2. LIST VALUE ASSIGNMENT (setFieldValues)
    // ============================================================================

    @IsTest
    static void shouldMapListToMultipleRecords() {
        // GIVEN a list of 2 values for 2 records
        List<String> industries = new List<String>{ 'Agriculture', 'Apparel' };
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(2)
            .setFieldValues(Account.Industry, industries)
            .build();

        // THEN it should map 1-to-1
        Assert.areEqual('Agriculture', accs[0].Industry);
        Assert.areEqual('Apparel', accs[1].Industry);
    }

    @IsTest
    static void shouldAssignNullWhenValuesAreExhausted() {
        // GIVEN 2 records but only 1 value in the list
        List<String> values = new List<String>{ 'Only One' };
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(2)
            .setFieldValues(Account.Industry, values)
            .build();

        // THEN the second record should be null
        Assert.areEqual('Only One', accs[0].Industry);
        Assert.areEqual(null, accs[1].Industry, 'Exhausted list should result in null');
    }

    // ============================================================================
    // 3. SMART MAPPING (SObject List Extraction)
    // ============================================================================

    @IsTest
    static void shouldExtractIdsFromSObjectList() {
        // GIVEN a list of parent Accounts with IDs
        Id mockId = '001000000000001AAA';
        List<Account> parents = new List<Account>{ new Account(Id = mockId) };

        // WHEN passing the SObject list directly to a Contact builder using SObjectField
        List<Contact> contacts = (List<Contact>) Tescribe.builder(Contact.SObjectType)
            .setFieldValues(Contact.AccountId, parents)
            .build();

        // THEN the ID should be automatically extracted
        Assert.areEqual(mockId, contacts[0].AccountId, 'Should extract Id from SObject list');
    }

    @IsTest
    static void shouldExtractIdsUsingStringFieldName() {
        // Targets Line 174-182: setFieldValues(String fieldName, List<SObject> records)
        // GIVEN a list of parent Accounts
        Id mockId = '001000000000001AAA';
        List<Account> parents = new List<Account>{ new Account(Id = mockId) };

        // WHEN using the String-based overload
        List<Contact> contacts = (List<Contact>) Tescribe.builder(Contact.SObjectType)
            .setFieldValues('AccountId', parents)
            .build();

        // THEN the ID should be extracted correctly
        Assert.areEqual(mockId, contacts[0].AccountId, 'Should map IDs using string field name');
    }

    // ============================================================================
    // 4. SELECTORS (Indices & Ranges)
    // ============================================================================

    @IsTest
    static void shouldApplyValueToSpecificIndicesOnly() {
        // GIVEN an override for index 1 only
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(3)
            .setFieldValue(Account.Name, 'Default')
            .setFieldValue(Account.Name, 'VIP', new List<String>{ '1' })
            .build();

        // THEN only index 1 changes
        Assert.areEqual('Default', accs[0].Name);
        Assert.areEqual('VIP', accs[1].Name);
        Assert.areEqual('Default', accs[2].Name);
    }

    @IsTest
    static void shouldApplyValueToRange() {
        // GIVEN a range selector '0-1'
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(3)
            .setFieldValue(Account.Name, 'Range', new List<String>{ '0-1' })
            .build();

        // THEN indices 0 and 1 are set, but 2 remains null
        Assert.areEqual('Range', accs[0].Name);
        Assert.areEqual('Range', accs[1].Name);
        Assert.areEqual(null, accs[2].Name);
    }

    @IsTest
    static void shouldHandleMixedSelectors() {
        // GIVEN both a specific index and a range
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(5)
            .setFieldValue(Account.Rating, 'Hot', new List<String>{ '0', '3-4' })
            .build();

        // THEN it applies to 0, 3, and 4
        Assert.areEqual('Hot', accs[0].Rating);
        Assert.areEqual(null, accs[1].Rating);
        Assert.areEqual('Hot', accs[3].Rating);
        Assert.areEqual('Hot', accs[4].Rating);
    }

    @IsTest
    static void shouldGracefullyHandleEmptySelectors() {
        // GIVEN a null selector list (should behave like no selectors)
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.Name, 'Global', (List<String>) null)
            .build();

        Assert.areEqual('Global', accs[0].Name, 'Null selectors should apply to all');
    }
}
