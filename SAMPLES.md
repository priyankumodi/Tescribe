# 1. Basic Generation: save() vs build()

Tescribe gives you full control over the record lifecycle. Use save() for Integration Tests (Database) and build() for Lightning Fast Unit Tests (In-Memory).

## A. The Persistent Approach (save)

Use this when your test logic depends on IDs, Formulas, or Rollup Summaries.

```java
// Inserts 3 Accounts into the Database
List<Account> accounts =
    (List<Account>) Tescribe.builder(Account.SObjectType)
        .repeat(3)
        .setFieldValue(Account.Industry, 'Technology')
        // Performs DML: insert
        .save();
```

The Result:
| _Index_ | Id | Industry | _Is Inserted?_ |
| :--- | :--- | :--- | :--- |
| _0_ | 001... | Technology | _Yes_ |
| _1_ | 001... | Technology | _Yes_ |
| _2_ | 001... | Technology | _Yes_ |

## B. The In-Memory Approach (build)

Use this for pure logic testing or Mocking. It is significantly faster because it avoids the Salesforce Save Cycle.

```java
// Generates 3 Accounts in memory only
List<Account> accounts =
    (List<Account>) Tescribe.builder(Account.SObjectType)
        .repeat(3)
        .setFieldValue(Account.Industry, 'Banking')
        // No DML performed
        .build();
```

The Result:
| _Index_ | Id | Industry | _Is Inserted?_ |
| :--- | :--- | :--- | :--- |
| _0_ | null | Banking | _No_ |
| _1_ | null | Banking | _No_ |
| _2_ | null | Banking | _No_ |

# 2. Comprehensive Token Usage

Tokens are evaluated dynamically for every record in the sequence. You can mix and match them within the same string.

```java
List<Contact> contacts =
    (List<Contact>) Tescribe.builder(Contact.SObjectType)
        .repeat(3)
        // Alphabetic sequence
        .setFieldValue(Contact.FirstName, 'Tester {alpha}')
        // Padded counter starting at 10
        .setFieldValue(Contact.EmployeeID__c, 'ID-{000:10}')
        // 0-based index
        .setFieldValue(Contact.SeqNo__c, 'SEQ-{index}')
        //Crypto-random hash
        .setFieldValue(Contact.ClientCode__c, 'CD-{random}')
        .save();
```

The Result:
| _Index_ | FirstName | EmployeeID\_\_c | SeqNo\_\_c | ClientCode\_\_c |
| :--- | :--- | :--- | :--- | :--- |
| _0_ | Tester A | ID-010 | SEQ-0 | CD-A3F2 |
| _1_ | Tester B | ID-011 | SEQ-1 | CD-B9C1 |
| _2_ | Tester C | ID-012 | SEQ-2 | CD-D4E8 |

# 3. Precision Targeting (Index & Range Overrides)

Apply different values to specific records within a single batch. Tescribe processes these in order; later rules for the same field override earlier ones.

```java
List<Opportunity> opps =
    (List<Opportunity>) Tescribe.builder(Opportunity.SObjectType)
    .repeat(6)
    // 1. Set Global Default
    .setFieldValue(Opportunity.StageName, 'Prospecting')
    // 2. Target Index 0
    .setFieldValue(Opportunity.StageName, 'Closed Won', '0','4')
    // 3. Target specific indices
    .setFieldValue(Opportunity.Amount, 1000, '0','2')
    // 4. Target inclusive range
    .setFieldValue(Opportunity.Amount, 5000, '3-5')
    .save();
```

The Result:
| _Index_ | StageName | Amount |
| :--- | :--- | :--- |
| _0_ | Closed Won | 1000 |
| _1_ | Prospecting | null |
| _2_ | Prospecting | 1000 |
| _3_ | Prospecting | 5000 |
| _4_ | Closed Won | 5000 |
| _5_ | Prospecting | 5000 |

# 4. Multiple Value Mapping (Lists, IDs, and Objects)

Tescribe is flexible with the types of data you pass into fields.

```java
List<String> levels = new List<String>{'Low', 'Medium', 'High'};
List<Id> accountIds = new List<Id>{ '001...A', '001...B', '001...C', '001...D' };
List<Contact> contacts = [Select Id, name from Contact limit 4];

List<Case> cases =
    (List<Case>) Tescribe.builder(Case.SObjectType)
        .repeat(4)
        // Cycle through a List (sets null if count > list size)
        .setFieldValues(Case.Priority, levels)
        // Direct ID mapping
        .setFieldValues(Case.AccountId, accountIds)
        // When SObject is mapped, id is auto extracted
        .setFieldValues(Case.contactId, contacts)
        .save();
```

The Result:
| _Index_ | Priority | AccountId | contactId |
| :--- | :--- | :--- | :--- |
| _0_ | Low | 001...A | 003...P |
| _1_ | Medium | 001...B | 003...Q |
| _2_ | High | 001...C | 003...R |
| _3_ | null | 001...D | 003...S |

# 5. Metadata Templates

Load a pre-defined state from Tescribe_Template\_\_mdt and then apply specific changes for this particular test scenario.

```javascript
//Tescribe_Template__mdt
{
  "Industry": "Banking",
  "Rating": "Hot",
  "Type": "Prospect"
}
```

```java
// Assume 'Standard_Account' template has Industry='Banking' and Rating='Hot'
List<Account> accs = (List<Account>) Tescribe.builder('Standard_Account')
    .repeat(6)
    // Add a field not in the template
    .setFieldValue('Description', 'Created from code')
    // Override a specific template value
    .setFieldValue('Industry', 'Education', '2','5')
    // Override a specific template value
    .setFieldValue('Rating', 'Cool', '1', '3-5')
    .save();
```

The Result:
| _Index_ | Industry | Rating | Type | Description |
| :--- | :--- | :--- | :--- | :--- |
| _0_ | Banking | Hot | Prospect | Created from code |
| _1_ | Banking | Cool | Prospect | Created from code |
| _2_ | Education | Hot | Prospect | Created from code |
| _3_ | Banking | Cool | Prospect | Created from code |
| _4_ | Banking | Cool | Prospect | Created from code |
| _5_ | Education | Cool | Prospect | Created from code |
