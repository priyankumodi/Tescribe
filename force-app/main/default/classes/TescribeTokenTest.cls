@IsTest
private class TescribeTokenTest {
    // ============================================================================
    // 1. NUMERIC TOKENS ({counter}, {000})
    // ============================================================================

    @IsTest
    static void shouldIncrementCounterToken() {
        // GIVEN a repeat of 2 with a basic counter
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(2)
            .setFieldValue(Account.AccountNumber, 'ACC-{counter}')
            .build();

        // THEN it should start at 1 and increment
        Assert.areEqual('ACC-1', accs[0].AccountNumber);
        Assert.areEqual('ACC-2', accs[1].AccountNumber);
    }

    @IsTest
    static void shouldApplyCounterTokenWithOffset() {
        // GIVEN a counter starting at 100
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.AccountNumber, '{counter:100}')
            .build();

        // THEN it should apply the offset correctly
        Assert.areEqual('100', accs[0].AccountNumber);
    }

    @IsTest
    static void shouldApplyPaddedNumericToken() {
        // GIVEN a padding token {000} (3 digits) starting at 10
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.AccountNumber, 'REF-{000:10}')
            .build();

        // THEN it should pad with zeros to the specified length
        Assert.areEqual('REF-010', accs[0].AccountNumber);
    }

    // ============================================================================
    // 2. ALPHA TOKENS ({alpha})
    // ============================================================================

    @IsTest
    static void shouldIncrementAlphaToken() {
        // GIVEN a repeat of 3 with alpha tokens
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(3)
            .setFieldValue(Account.Name, 'Org {alpha}')
            .build();

        // THEN it should follow A, B, C...
        Assert.areEqual('Org A', accs[0].Name);
        Assert.areEqual('Org B', accs[1].Name);
        Assert.areEqual('Org C', accs[2].Name);
    }

    @IsTest
    static void shouldHandleAlphaTransitionsAtZ() {
        // GIVEN a start at Z
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(2)
            .setFieldValue(Account.Name, '{alpha:Z}')
            .build();

        // THEN it should transition to AA
        Assert.areEqual('Z', accs[0].Name);
        Assert.areEqual('AA', accs[1].Name);
    }

    // ============================================================================
    // 3. UTILITY TOKENS ({index}, {random})
    // ============================================================================

    @IsTest
    static void shouldReplaceIndexTokenWithLoopIndex() {
        // GIVEN a repeat of 2 (indices 0 and 1)
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .repeat(2)
            .setFieldValue(Account.Site, 'Row-{index}')
            .build();

        // THEN it should use the 0-based index
        Assert.areEqual('Row-0', accs[0].Site);
        Assert.areEqual('Row-1', accs[1].Site);
    }

    @IsTest
    static void shouldGenerateRandomTokens() {
        // GIVEN a random token request
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.TickerSymbol, '{random}')
            .build();

        // THEN it should generate a string of at least 4 chars
        Assert.isTrue(accs[0].TickerSymbol.length() >= 4, 'Random token should be generated');
    }

    // ============================================================================
    // 4. ENGINE EDGE CASES
    // ============================================================================

    @IsTest
    static void shouldIgnoreNonStringValues() {
        // GIVEN an Integer value passed to the processor
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.NumberOfEmployees, 500)
            .build();

        // THEN the engine should return the value as-is without processing
        Assert.areEqual(500, accs[0].NumberOfEmployees);
    }

    @IsTest
    static void shouldIgnoreStringsWithoutBrackets() {
        // GIVEN a string without any tokens
        String plainText = 'Standard Industry';
        List<Account> accs = (List<Account>) Tescribe.builder(Account.SObjectType)
            .setFieldValue(Account.Industry, plainText)
            .build();

        // THEN the engine should return the string immediately
        Assert.areEqual(plainText, accs[0].Industry);
    }
}
