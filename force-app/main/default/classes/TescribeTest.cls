@IsTest
private class TescribeTest {
    @IsTest
    static void testMetadataBuilderWithMock() {
        // 1. Define a mock metadata record in memory
        Tescribe_Template__mdt mockMeta = new Tescribe_Template__mdt(
            DeveloperName = 'Mock_Account',
            Object_API_Name__c = 'Account',
            JSON_Data__c = '{"Name": "Mock Account", "Industry": "Technology"}'
        );

        // 2. Inject it into the main class
        Tescribe.mockTemplate = mockMeta;

        // 3. Execute the builder
        Test.startTest();
        Tescribe instance = Tescribe.builder('Mock_Account');
        List<Account> results = (List<Account>) instance.build();
        Test.stopTest();

        // 4. Verify coverage-driving logic
        Assert.areNotEqual(null, instance, 'Instance should be created');
        Assert.areEqual(1, results.size());
        Assert.areEqual(
            'Mock Account',
            results[0].Name,
            'JSON data should be parsed into the SObject'
        );
    }

    @IsTest
    static void testStandardBuilderAndTokens() {
        // Test basic building with various tokens
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(3)
            .setFieldValue('Name', 'Test {alpha} {000:10}')
            .setFieldValue('AccountNumber', '{counter:100}')
            .build();

        Assert.areEqual(3, accs.size(), 'Should generate 3 records');

        // Verify Token replacements
        Assert.areEqual('Test A 010', accs[0].Name);
        Assert.areEqual('Test B 011', accs[1].Name);
        Assert.areEqual('100', accs[0].AccountNumber);
        Assert.areEqual('102', accs[2].AccountNumber);
    }

    @IsTest
    static void testSelectorsAndRanges() {
        // Test specific index and range overrides
        List<Contact> conts = (List<Contact>) Tescribe.builder(Contact.SObjectType)
            .repeat(5)
            .setFieldValue('LastName', 'Standard')
            .setFieldValue('LastName', 'Special', new List<String>{ '0', '2-3' })
            .build();

        Assert.areEqual('Special', conts[0].LastName);
        Assert.areEqual('Standard', conts[1].LastName); // Index 1 not in selector
        Assert.areEqual('Special', conts[2].LastName);
        Assert.areEqual('Special', conts[3].LastName);
        Assert.areEqual('Standard', conts[4].LastName);
    }

    @IsTest
    static void testFieldValuesList() {
        // Test 1-to-1 mapping from a list
        List<String> phoneNumbers = new List<String>{ '111', '222', '333' };

        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(3)
            .setFieldValues('Phone', phoneNumbers)
            .build();

        Assert.areEqual('111', accs[0].Phone);
        Assert.areEqual('333', accs[2].Phone);
    }

    @IsTest
    static void testMetadataException() {
        // Test the error handling when a template doesn't exist
        Boolean exceptionThrown = false;
        try {
            Tescribe.builder('NON_EXISTENT_TEMPLATE');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
            Assert.isTrue(e.getMessage().contains('Active template not found'));
        }
        Assert.isTrue(exceptionThrown, 'Should throw error for missing template');
    }

    @IsTest
    static void testAlphaEdgeCases() {
        // Test the Z to AA transition
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(2)
            .setFieldValue('Name', '{alpha:Z}')
            .build();

        Assert.areEqual('Z', accs[0].Name);
        Assert.areEqual('AA', accs[1].Name);
    }

    @IsTest
    static void testSaveMethod() {
        // Test DML execution
        Test.startTest();
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .setFieldValue('Name', 'DML Test')
            .save();
        Test.stopTest();

        Assert.isNotNull(accs[0].Id, 'Record should have an ID after save()');
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'DML Test']);
    }

    @IsTest
    static void testSObjectFieldWrappers() {
        // 1. Test setFieldValue(Schema.SObjectField, Object)
        // This covers the first missing method
        Tescribe builder1 = Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.Name, 'Token Test');

        List<Account> results1 = (List<Account>) builder1.build();
        Assert.areEqual('Token Test', results1[0].Name, 'Should map using SObjectField token');

        // 2. Test setFieldValues(Schema.SObjectField, List<SObject>)
        // This covers the second missing method (1-to-1 parent linking)
        List<Account> parents = new List<Account>{
            new Account(Id = '001000000000001AAA'),
            new Account(Id = '001000000000002AAA')
        };

        List<Contact> children = (List<Contact>) Tescribe.builder(Contact.SObjectType)
            .repeat(2)
            .setFieldValues(Contact.AccountId, parents)
            .build();

        Assert.areEqual(parents[0].Id, children[0].AccountId, 'Index 0 should link to Parent 0');
        Assert.areEqual(parents[1].Id, children[1].AccountId, 'Index 1 should link to Parent 1');
    }

    @IsTest
    static void testTokenEdgeCaseCoverage() {
        // 1. Define mock to hit the builder logic again (safety)
        Tescribe.mockTemplate = new Tescribe_Template__mdt(
            DeveloperName = 'Token_Edge_Case',
            Object_API_Name__c = 'Account',
            JSON_Data__c = '{"Name": "Base"}'
        );

        // 2. Build with tokens that trigger all default and specific branches
        Test.startTest();
        List<Account> accs = (List<Account>) Tescribe.builder('Token_Edge_Case')
            .repeat(1)
            // Hits Line 238 (non-string)
            .setFieldValue('NumberOfEmployees', 100)
            // Hits Lines 247, 254, 263 (default offsets for tokens)
            .setFieldValue('Description', 'C:{counter} A:{alpha} P:{000}')
            // Hits Line 267 ({index})
            .setFieldValue('Site', 'Index-{index}')
            // Hits Line 271 ({random})
            .setFieldValue('TickerSymbol', '{random}')
            .build();
        Test.stopTest();

        // 3. Verify specific outputs to ensure logic was actually processed
        Assert.areEqual(100, accs[0].NumberOfEmployees, 'Integer values should pass through');
        Assert.areEqual(
            'C:1 A:A P:001',
            accs[0].Description,
            'Default tokens should use start values'
        );
        Assert.areEqual('Index-0', accs[0].Site, 'Index token should be 0');
        Assert.isTrue(accs[0].TickerSymbol.length() >= 4, 'Random token should be generated');
    }

    @IsTest
    static void testFinalCoverageGaps() {
        // 1. Cover the 'Invalid Object' exception branch (Lines 105-108)
        Tescribe.mockTemplate = new Tescribe_Template__mdt(
            DeveloperName = 'Invalid_Obj',
            Object_API_Name__c = 'Invalid_Object_Name_X',
            JSON_Data__c = '{"Name": "Test"}'
        );

        try {
            Tescribe.builder('Invalid_Obj');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(
                e.getMessage().contains('Invalid Object'),
                'Should hit invalid object branch'
            );
        }

        // 2. Cover Token defaults, non-string values, and basic FieldRules
        Tescribe.mockTemplate = new Tescribe_Template__mdt(
            DeveloperName = 'Token_Gap_Filler',
            Object_API_Name__c = 'Account',
            JSON_Data__c = '{"Name": "Base"}'
        );

        Test.startTest();
        List<Account> accs = (List<Account>) Tescribe.builder('Token_Gap_Filler')
            .repeat(1)
            // Hits Line 56 (Rule with no selectors)
            .setFieldValue('Description', 'Standard Rule')
            // Hits Line 238 (non-string value)
            .setFieldValue('NumberOfEmployees', 100)
            // Hits Lines 247, 254, 263 (default offsets)
            .setFieldValue('Site', '{counter} {alpha} {000}')
            // Hits Lines 267, 271 ({index} and {random})
            .setFieldValue('TickerSymbol', '{index}-{random}')
            .build();
        Test.stopTest();

        // Verification
        Assert.areEqual(100, accs[0].NumberOfEmployees, 'Integer should pass through');
        Assert.isTrue(accs[0].Site.contains('1 A 001'), 'Defaults should be 1, A, and 001');
        Assert.isTrue(accs[0].TickerSymbol.contains('0-'), 'Index should be 0');
    }
}
