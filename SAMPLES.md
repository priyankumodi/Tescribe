# 1. Basic Generation: save() vs build()

Tescribe gives you full control over the record lifecycle. Use save() for Integration Tests (Database) and build() for Lightning Fast Unit Tests (In-Memory).

## A. The Persistent Approach (save)

Use this when your test logic depends on IDs, Formulas, or Rollup Summaries.

```java
// Inserts 3 Accounts into the Database
List<Account> accounts = (List<Account>) Tescribe.builder(Account.SObjectType)
    .repeat(3)
    .setFieldValue('Industry', 'Technology')
    .save(); // Performs DML: insert
```

The Result:
| Index | Industry | Id | IsInserted? |
| :--- | :--- | :--- | :--- |
| 0 | Technology | 001... | Yes |
| 1 | Technology | 001... | Yes |
| 2 | Technology | 001... | Yes |

## B. The In-Memory Approach (build)

Use this for pure logic testing or Mocking. It is significantly faster because it avoids the Salesforce Save Cycle.

```java
// Generates 3 Accounts in memory only
List<Account> accounts = (List<Account>) Tescribe.builder(Account.SObjectType)
    .repeat(3)
    .setFieldValue('Industry', 'Banking')
    .build(); // No DML performed
```

The Result:
| Index | Industry | Id | IsInserted? |
| :--- | :--- | :--- | :--- |
| 0 | Banking | null | No |
| 1 | Banking | null | No |
| 2 | Banking | null | No |

# 2. Comprehensive Token Usage

Tokens are evaluated dynamically for every record in the sequence. You can mix and match them within the same string.

```java
List<Contact> contacts = (List<Contact>) Tescribe.builder(Contact.SObjectType)
    .repeat(3)
    .setFieldValue(Contact.FirstName, 'Tester {alpha}')                     // Alphabetic sequence
    .setFieldValue(Contact.Employee_ID__c, 'ID-{000:10}')                   // Padded counter starting at 10
    .setFieldValue(Contact.Description, 'Index {index}, Hash: {random}')    // 0-based index and Crypto-random hash
    .save();
```

The Result:
| Index | FirstName | Employee_ID\_\_c | Description |
| :--- | :--- | :--- | :--- |
| 0 | Tester A | ID-010 | Index 0, Hash: 1-A3F2 |
| 1 | Tester B | ID-011 | Index 1, Hash: 2-B9C1 |
| 2 | Tester C | ID-012 | Index 2, Hash: 3-D4E8 |

# 3. Precision Targeting (Index & Range Overrides)

Apply different values to specific records within a single batch. Tescribe processes these in order; later rules for the same field override earlier ones.

```java
List<Opportunity> opps = (List<Opportunity>) Tescribe.builder(Opportunity.SObjectType)
    .repeat(6)
    .setFieldValue(Opportunity.StageName, 'Prospecting')      // 1. Set Global Default
    .setFieldValue(Opportunity.StageName, 'Closed Won', '0')  // 2. Target Index 0
    .setFieldValue(Opportunity.Amount, 1000, '0,2')           // 3. Target specific indices
    .setFieldValue(Opportunity.Amount, 5000, '3-5')           // 4. Target inclusive range
    .save();
```

The Result:
| Index | StageName | Amount |
| :--- | :--- | :--- |
| 0 | Closed Won | 1000 |
| 1 | Prospecting | null |
| 2 | Prospecting | 1000 |
| 3 | Prospecting | 5000 |
| 4 | Prospecting | 5000 |
| 5 | Prospecting | 5000 |

# 4. Multiple Value Mapping (Lists, IDs, and Objects)

Tescribe is flexible with the types of data you pass into fields.

```java
List<String> levels = new List<String>{'Low', 'Medium', 'High'};
List<Id> accountIds = [ '001...A', '001...B', '001...C', '001...D' ];
List<Contact> contacts = [Select Id, name from Contact limit 4];

List<Case> cases = (List<Case>) Tescribe.builder(Case.SObjectType)
    .repeat(4)
    .setFieldValues(Case.Priority, levels)          // Cycle through a List (wraps around if count > list size)
    .setFieldValues(Case.AccountId, accountIds)    // Direct ID mapping
    .setFieldValues(Case.contactId, contacts)    // Direct ID mapping
    .save();
```

The Result:
| Index | Priority | AccountId | contactId |
| :--- | :--- | :--- | :--- |
| 0 | Low | 001...A | 003...P |
| 1 | Medium | 001...B | 003...Q |
| 2 | High | 001...C | 003...R |
| 3 | null | 001...D | 003...S |

# 5. Metadata Templates

Load a pre-defined state from Tescribe_Template\_\_mdt and then apply specific changes for this particular test scenario.

```javascript
//Tescribe_Template__mdt
{
  "Industry": "Banking",
  "Rating": "Hot",
  "Type": "Prospect",
  "Description": "Default Template Description"
}
```

```java
// Assume 'Standard_Account' template has Industry='Banking' and Rating='Hot'
List<Account> accs = (List<Account>) Tescribe.builder('Standard_Account')
    .repeat(3)
    // Add a field not in the template
    .setFieldValue('Description', 'Created via Template')
    // Override a specific template value for the last record
    .setFieldValue('Industry', 'Education', '2')
    .save();
```

The Result:
| Index | Industry | Rating | Type | Description |
| :--- | :--- | :--- | :--- | :--- |
| 0 | Banking | Hot | Prospect | Created via Template |
| 1 | Banking | Hot | Prospect | Created via Template |
| 2 | Education | Hot | Prospect | Created via Template |
