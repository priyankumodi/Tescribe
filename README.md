# Tescribe: Fluent Test Data Generation for Salesforce Apex

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) ![Platform](https://img.shields.io/badge/platform-Salesforce-blue)

**Tescribe** is a fluent, high-performance data generation library for Salesforce Apex. It allows you to "describe" complex test states using a descriptive API, eliminating the need for thousands of lines of boilerplate factory code.

It is designed to be a **scalable, modern replacement** for traditional test data factory classes that often become difficult to maintain as projects grow.

## 1. What is Tescribe?

Tescribe moves beyond the limitations of static “Test Data Factories” by providing a dynamic engine that handles everything from simple single-record creation to complex, multi-object relationship trees. It bridges the gap between rigid code and dynamic test requirements.

With Tescribe, you can:

- **Start Anywhere**: Build records from scratch using SObjectTypes or bootstrap instantly from pre-defined **Custom Metadata templates**.
- **Bulk Customize**: Set field values across an entire batch or target **specific rows and ranges** using an intuitive selector syntax.
- **Smart Sequencing**: Use the built-in **Token Engine** to generate unique, incrementing, or random data (e.g., `{counter}`, `{alpha}`, `{random}`) without manual loops.
- **Effortless Relationships**: Link parent and child records fluently, ensuring your relational data integrity is maintained automatically during the build process.

## 2. The Problem: The "Factory Fatigue"

### The Traditional Approach

In standard Salesforce development, teams typically build `TestDataFactory.cls` files. As requirements grow and orgs become more complex, these files become a significant bottleneck:

- **The Parameter Explosion**: One of the most painful sights in a legacy codebase is the 20+ parameter factory method. For example: `createAccount(String name, Boolean isGold, String type, Id ownerId, Boolean isPartner...)`. These methods eventually become unmanageable and impossible to read.
- **Complex Data Orchestration**: In large orgs, setting up a single test case often requires instantiating data across dozens of objects and carefully linking them before you can even begin writing logic. Developers spend more time "wiring" relationships than testing.
- **Lack of Extensibility**: Adding a single required field or validation rule often breaks hundreds of existing factory calls, requiring a massive, manual effort to update the entire test suite.
- **Redundancy**: To avoid changing existing methods, developers often create "overload" versions (e.g., `createAccountV2`, `createAccountV3`), leading to a cluttered and confusing API.
- **Performance Heavy**: Traditional factories often lead to redundant SOQL/DML and high CPU usage.

❌ Before: The "Factory Fatigue" Approach

In a traditional setup, you are often forced to use rigid methods with a "parameter explosion" or write complex manual loops to handle unique data.

```java
// Traditional TestDataFactory.cls
public class TestDataFactory {
    // Rigid method signature: requires a value for every parameter even if not needed
    public static List<Contact> createContacts(Integer count, Id accountId, String lastName, String level, Boolean isVIP) {
        List<Contact> contacts = new List<Contact>();
        for(Integer i=0; i < count; i++) {
            Contact c = new Contact(
                AccountId = accountId,
                LastName = lastName + i, // Manual counter logic
                Level__c = (isVIP && i < 3) ? 'Secondary' : level // Hard-coded conditional logic
            );
            contacts.add(c);
        }
        insert contacts;
        return contacts;
    }
}

// Usage in Test Class:
// Difficult to read: What does the 'false' at the end represent?
List<Contact> contacts = TestDataFactory.createContacts(10, myAccId, 'User', 'Primary', false);
```

### The Tescribe Solution

Tescribe significantly eliminates this pain by shifting the focus from **generating records** to **describing states**.

- **Zero Boilerplate**: No need to create or maintain a separate class for every new object variation.
- **Template Driven**: Store "Golden Record" setups in Custom Metadata and load them with one line. Creating templates is effortless—simply export existing data as JSON using tools like **Salesforce Inspector** and paste it into the metadata, or write your own JSON from scratch.
- **Precision Targeting**: Use "Selectors" to modify specific records within a batch without complex manual loops or huge parameter lists.
- **Enhanced Readability**: Test setups become self-documenting. Instead of guessing what the 14th parameter in a factory method does, you see a clear, fluent chain of `setFieldValue` calls that describe exactly what the data looks like.

✅ After: The Tescribe "Artisan" Approach

Tescribe replaces rigid methods with a fluent API that describes the state. It handles the loops, the unique naming (Tokens), and the targeted overrides (Selectors) for you.

```java
// No separate factory class needed. Just describe the state:
List<Contact> contacts = (List<Contact>) Tescribe.builder(Contact.SObjectType)
    .repeat(10)                                          // 1. Define volume
    .setFieldValue(Contact.AccountId, myAccountId)       // 2. Map relationships
    .setFieldValue(Contact.LastName, 'User {alpha}')     // 3. Dynamic naming (User A, User B...)
    .setFieldValue(Contact.Level__c, 'Primary')          // 4. Set global default
    .setFieldValue(Contact.Level__c, 'Secondary', '0-2') // 5. Precision targeting (indices 0, 1, 2)
    .save();                                             // 6. Bulkified DML
```

## 3. Installation

Clone the repository and deploy the source directly to your Scratch Org or Sandbox using the Salesforce CLI.

```bash
# 1. Clone the repository
git clone https://github.com/priyankumodi/Tescribe.git
cd Tescribe

# 2. Deploy to your default org
sf project deploy start
```

> **✅ Quick Start Verification**: After deployment, run the [TescribeSuite](force-app/main/default/testSuites/TescribeSuite.testSuite-meta.xml) Apex Test Suite to ensure the engine and modular test classes are fully compatible with your environment's specific object configurations and governor limits.

## 4. How to Use

Tescribe is built on a "Describe and Build" philosophy. Follow these steps to generate exactly the data you need.

### Step 1: Choose Your Starting Point

You can start with a blank slate using an `SObjectType` or bootstrap from a pre-defined template in `Tescribe_Template__mdt`.

```java
// Option A: Starting from scratch
Tescribe.builder(Account.SObjectType);

// Option B: Starting from a Metadata Template (e.g., 'Enterprise_Account_Template')
// This loads all default field values and logic defined in your JSON template.
Tescribe.builder('Enterprise_Account_Template');
```

#### How to Create a JSON Template

Tescribe allows you to move away from manual Apex setup by "recording" perfect data states directly into Custom Metadata.

##### Step 1: Export or Write your JSON

Use **Salesforce Inspector** or a similar tool to copy an existing "perfect" record from your sandbox.

```javascript
//Example JSON for a "Enterprise Client" Account
{
    "Name": "Enterprise Client {alpha}",
    "Type": "Prospect",
    "Industry": "Technology",
    "Description": "Record {counter} of {quantity}. Batch ID: {random} Index: {index}"
}
```

##### Step 2: Create the Custom Metadata Record

> **💡 Quick Start:** You can refer to the [Enterprise_Account_Template](force-app/main/default/customMetadata/Tescribe_Template.Enterprise_Account_Template.md-meta.xml) included in this repository to see a finished example of how the JSON and fields are mapped.

1.  Navigate to **Setup** > **Custom Metadata Types**.
2.  Find **Tescribe Template** (`Tescribe_Template__mdt`) and click **Manage Records**.
3.  Create a **New** record:
4.  - **Label**: `Enterprise Account`
    - **Developer Name**: `Enterprise_Account_Template` (This must match the string used in your Apex builder).
    - **Object API Name**: `Account`.
    - **Description**:`Standard template for Enterprise-level Accounts. Automatically generates unique names with alpha-sequencing and includes dynamic descriptions for easier test debugging.`
    - **JSON Data**: Paste your JSON here.
    - **Is Active**: Ensure this is checked.

> **Template Scrubbing:** When exporting data, replace specific names with **Tescribe Tokens** like `{alpha}` or `{counter}`. This ensures your unit tests remain dynamic and won't fail due to duplicate value errors.

### Step 2: Use Tokens for Dynamic Values

Instead of hardcoding values or writing loops, use the **Token Engine** to ensure data uniqueness and realism.

```java
.repeat(3)									 // Prepare 3 records
.setFieldValue('Name', 'Acme {alpha}')       // Generates: Acme A, Acme B, Acme C
.setFieldValue('Phone', '555-0{counter:1}')  // Generates: 555-01, 555-02, 555-03
.setFieldValue('External_Id__c', '{random}') // Generates unique GUID-like strings
```

### Step 3: Targeted Customization

Tescribe’s power lies in its precision. Use the following features to transition from generic data to highly specific test states.

#### A. Compile-Time Safety vs. Flexibility

Tescribe supports both **Strongly Typed Fields** (Recommended) and **String-based Names**. Lead with typed fields to catch errors during development.

```java
// RECOMMENDED: Strongly typed (Catch errors at compile-time)
.setFieldValue(Account.Industry, 'Technology')

// FLEXIBLE: String-based (Useful for dynamic field logic)
.setFieldValue('Industry', 'Technology')
```

#### B. Targeting Specific Rows (Selectors)

You don't need to write loops to differentiate records in a batch. Use **Selectors** to apply a single value to specific indices or ranges.

```java
// Prepare 10 records
.repeat(10)

// Apply to ALL 10 records
.setFieldValue(Account.Type, 'Customer')

// Apply ONLY to the first record (index 0) and a range (indices 5 to 8)
.setFieldValue(Account.Type, 'Partner', new List<String>{ '0', '5-8' })
```

> ### 💡 Pro-Tip: The "Artisan" Approach
>
> Mixing these features allows for incredible precision. You can define a "base" state for 100 records using a **Strongly Typed Field** in one line, then "carve out" specific exceptions for a handful of them using a **Selector** in the next. This layer-by-layer approach makes your test data expressive and easy to maintain.

#### C. Multiple Values (`setFieldValues`)

Use `setFieldValues` (plural) to map an ordered list of values to your records. This is the most efficient way to set up varied states or link multiple parent IDs.

```java
// Ex 1. Mapping 3 specific IDs to 3 new records
List<Id> parentIds = new List<Id>{id1, id2, id3};
//...
.repeat(3)
.setFieldValues('ParentId', parentIds)

//Ex 2. Smart Mapping: Passing a List<SObject> directly
// Tescribe automatically extracts the .Id from each record in the list.
List<Account> accounts = [SELECT Id FROM Account LIMIT 3];
//...
.repeat(3)
.setFieldValues(Contact.AccountId, accounts)

// Ex 3. Mapping 4 different Stages to 4 Opportunities or any List<String>
List<String> allStages = new List<String>{'Prospecting', 'Qualification', 'Review', 'Closed Won'};
//...
.repeat(4)
.setFieldValues(Opportunity.StageName, allStages)
```

> ### ⚠️ Important: Understanding `setFieldValues` (Lists)
>
> When mapping a list of values to a batch of records, Tescribe follows a strict 1-to-1 mapping:
>
> - **Balanced Mapping**: If the number of records equals the number of values, every record receives a unique value from your list in sequential order.
> - **Graceful Nulls**: If you have more records than values (e.g., using `.repeat(10)` with only 3 IDs), the additional records will have this field set to `null`. This ensures your data remains predictable and avoids accidental data duplication.
> - **Smart Mapping (SObjects)**: When you pass a List<SObject>, Tescribe automatically extracts the Id field for you. There is no need to manually loop through the list to build a List<Id>

### Step 4: Finalize and Persist

Decide whether you need the records only in memory (for unit tests that don't require DML) or saved to the database.

```java
// Option A: Build in memory (Returns List<SObject>)
// Fast, saves on DML limits, great for logic-only tests.
List<Account> accs = (List<Account>) builder.build();

// Option B: Save to Database (Inserts and returns List<SObject>)
// Handles the DML insert for you automatically.
List<Account> accs = (List<Account>) builder.save();
```

### Full Example: Putting it all together

In this real-world scenario, we are creating 5 Contacts. We use the **Token Engine** for unique names, **Strongly Typed Fields** for safety, and **Selectors** to differentiate a specific "VIP" record—all linked to a single Account.

```java
List<Contact> contacts = (List<Contact>) Tescribe.builder(Contact.SObjectType)
    .repeat(5)                                          // 1. Prepare a batch of 5 records
    .setFieldValue(Contact.AccountId, myAccountId)      // 2. Link all records to a specific Account
    .setFieldValue(Contact.LastName, 'User {counter}')  // 3. Dynamic naming: User 1, User 2, etc.
    .setFieldValue(Contact.Level__c, 'Primary')         // 4. Set 'Primary' as the default for all
    .setFieldValue(Contact.Level__c, 'Secondary', '0')  // 5. Override ONLY the first record (Index 0)
    .save();                                            // 6. Insert to Database and return the list
```

## 5. Token Reference & Performance

### Token Reference Guide

Tescribe’s built-in **Token Engine** allows you to generate unique, sequential, or random data without writing manual loops or counter variables. Use these tokens within any string field value to create dynamic test states.

| Token           | Description                                                               | Example Output                   |
| :-------------- | :------------------------------------------------------------------------ | :------------------------------- |
| `{index}`       | The current loop index, starting at 0.                                    | `0`, `1`, `2`                    |
| `{counter}`     | Simple incrementing numbers starting at 1.                                | `1`, `2`, `3`                    |
| `{counter:100}` | Incrementing numbers starting at a specific value.                        | `100`, `101`, `102`              |
| `{0...:start}`  | Variable Padded Numbers. The number of zeros determines the total length. | `{0000:1}` `→` `0001`, `0002...` |
| `{alpha}`       | Alphabetic sequencing (A-Z, then AA-ZZ).                                  | `A`, `B` ... `Z`, `AA`           |
| `{random}`      | A unique identifier (Sequence + 4-digit crypto hash).                     | `1-8A2F`, `2-9B1C`               |

---

<a name="advanced-tokens"></a>

### 💡 Advanced Token Usage

You can combine tokens with static text to create complex, realistic data patterns:

- **Unique Emails**: `testuser.{counter}@example.com` → `testuser.1@example.com`
- **Reference Numbers**: `INV-{0000:10}-{alpha}` → `INV-0010-A`, `INV-0011-B`
- **External IDs**: `EXT-{random}` → `EXT-1-A2F3`

## 6. Performance & Safety

Tescribe is engineered for the constraints of large-scale Salesforce environments, focusing on CPU efficiency and predictable data states.

### Performance

- **O(n) Complexity**: The internal engine uses a single-pass loop to process tokens and build records. Generating 500 records is nearly as fast as generating 5, making it ideal for performance testing.
- **CPU Efficiency**: Token processing utilizes `indexOf` and `replace` instead of heavy Regex, preserving your transaction's CPU limits.
- **Bulkified Persistence**: The `.save()` method performs a single DML operation for the entire batch.

### Safety & Limitations

- **Template Field Safety**: When using **Custom Metadata templates**, Tescribe automatically ignores non-writable fields (like Formulas or System fields) to prevent DML errors.
    - _Note: Manual `setFieldValue` calls on non-writable fields will still throw standard Apex exceptions._
- **Governor Limit Awareness**: Tescribe operates within standard Salesforce limits. While the builder can generate large batches, the `.save()` method is subject to the **10,000 DML row limit** per transaction.
- **Predictable Nulls**: If you provide a list of values shorter than your batch size, Tescribe explicitly sets the remaining fields to `null` to ensure data consistency.

## 7. Technical Inventory & Security

Before you begin, ensure you are familiar with the components included in the Tescribe package.

### Package Components

Tescribe is a lightweight solution consisting of the following elements:

- **Apex Classes**:
    - **The Engine (`Tescribe.cls`)**: The core fluent API and token processing logic.
    - **Modular Test Suite**: Specialized test classes—`TescribeBuilderTest.cls`, `TescribeTokenTest.cls`, `TescribeAssignmentTest.cls`, and `TescribePersistenceTest.cls`—ensuring high-speed, isolated validation.
- **Apex Test Suite**: `TescribeSuite.testSuite-meta.xml` groups all modular tests for single-click regression testing.
- **Custom Metadata**: `Tescribe_Template__mdt` used for storing your "Golden Record" JSON templates.
- **Sample Record**: A pre-configured template (`Enterprise_Account_Template`) is included to help you get started.
    - _Note: This record is for demonstration only and can be safely deleted if not needed._
- **Page Layouts**: Optimized layouts for the Custom Metadata to make JSON entry clean and manageable.
- **Permission Sets**: Pre-configured access controls for developers and automated test users.

### Permissions & Access Control

To use Tescribe effectively, users or integration users must be assigned the **Tescribe Developer** Permission Set.

**Why assign the Permission Set?**

- **Metadata Access**: It grants the necessary `Read` access to the `Tescribe_Template__mdt` object. Without this, the `builder('TemplateName')` method will fail to retrieve your records.
- **System Safety**: It provides the permissions required to utilize the Token Engine's cryptographic functions for the `{random}` token.
- **Security Best Practices**: Instead of granting "Modify All Data," this permission set follows the principle of least privilege, giving your test execution user only what it needs to generate data.

> **Admin Tip:** Assign this permission set to your **CI/CD Integration User** to ensure that automated builds and deployments can generate test data seamlessly in your pipeline.

## 8. Closing Remarks & Roadmap

### The Artisan Philosophy

Tescribe was born out of a desire to solve the very real "Factory Fatigue" that plagues mature Salesforce orgs. We have focused on building a stable, high-performance engine that handles the most painful aspects of test data orchestration—from relationship wiring to dynamic sequencing.

### Disclaimer & Community Feedback

While we have strived for perfection and high stability, software is an evolving craft.

- **Use at your own risk**: As with any open-source utility, please validate Tescribe in your sandbox environments before integrating it into critical CI/CD pipelines.
- **Discovered an edge case?**: We acknowledge there may be imperfections. If you find a bug or a unique data shape that Tescribe can't handle yet, we want to hear about it.
- **Share your thoughts**: Your feedback is the fuel for this project. If Tescribe has saved you time or simplified your codebase, please let us know.

We are just getting started. If there is significant community interest, we have many plans including publishing to AppExchange.

_Your interest and contributions will determine how fast we build the next generation of Tescribe._
