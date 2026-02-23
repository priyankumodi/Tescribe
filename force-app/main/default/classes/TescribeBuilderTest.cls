@IsTest
private class TescribeBuilderTest {
    // ============================================================================
    // SOBJECT TYPE COMPOSITION
    // ============================================================================

    @IsTest
    static void shouldInitializeWithSObjectType() {
        // GIVEN an SObject Type
        Schema.SObjectType target = Account.SObjectType;

        // WHEN the builder is initialized
        Test.startTest();
        Tescribe instance = Tescribe.builder(target);
        Test.stopTest();

        // THEN it should return a valid instance
        Assert.areNotEqual(null, instance, 'Builder must initialize successfully with SObjectType');
    }

    // ============================================================================
    // METADATA TEMPLATE COMPOSITION
    // ============================================================================

    @IsTest
    static void shouldInitializeFromMetadataTemplate() {
        // GIVEN a mock template with pre-defined industry
        Tescribe.mockTemplate = new Tescribe_Template__mdt(
            Object_API_Name__c = 'Account',
            JSON_Data__c = '{"Industry": "Technology"}'
        );

        // WHEN the builder is initialized by name
        Tescribe instance = Tescribe.builder('Tech_Template');
        List<Account> records = (List<Account>) instance.build();

        // THEN the records should inherit the template values
        Assert.areEqual(
            'Technology',
            records[0].Industry,
            'Instance must map fields from Metadata JSON'
        );
    }

    // ============================================================================
    // ERROR HANDLING & NEGATIVE SCENARIOS
    // ============================================================================

    @IsTest
    static void shouldThrowExceptionWhenMetadataNameIsNotFound() {
        // GIVEN a template name that does not exist
        String invalidName = 'Unknown_Template';

        // WHEN calling the builder
        try {
            Tescribe.builder(invalidName);
            Assert.fail('Should have thrown IllegalArgumentException for missing template');
        } catch (IllegalArgumentException e) {
            // THEN it should return a clear error message
            Assert.isTrue(
                e.getMessage().contains('Active template not found'),
                'Error must be descriptive'
            );
        }
    }

    @IsTest
    static void shouldThrowExceptionWhenMetadataContainsInvalidObject() {
        // GIVEN a template pointing to a non-existent object API name
        Tescribe.mockTemplate = new Tescribe_Template__mdt(
            Object_API_Name__c = 'Imaginary_Object__c'
        );

        // WHEN calling the builder
        try {
            Tescribe.builder('Bad_Object_Template');
            Assert.fail('Should have thrown IllegalArgumentException for invalid object');
        } catch (IllegalArgumentException e) {
            // THEN it should report the object name is invalid
            Assert.isTrue(
                e.getMessage().contains('Invalid Object'),
                'Error must report incorrect API name'
            );
        }
    }

    @IsTest
    static void shouldGracefullyHandleNullJsonInMetadata() {
        // GIVEN a template with an empty JSON field
        Tescribe.mockTemplate = new Tescribe_Template__mdt(
            Object_API_Name__c = 'Account',
            JSON_Data__c = null
        );

        // WHEN the builder is initialized
        Tescribe instance = Tescribe.builder('Null_JSON_Template');
        List<Account> records = (List<Account>) instance.build();

        // THEN it should still produce a record without failing
        Assert.areEqual(1, records.size(), 'Should create record even if JSON data is null');
    }
}
