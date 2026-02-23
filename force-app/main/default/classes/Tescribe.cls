/**
 * ============================================================================
 * T E S C R I B E - Fluent Test Data Generation for Salesforce Apex
 * ============================================================================
 * @author      Priyank Modi
 * @version     1.0.0
 * @license     MIT
 * @repository  https://github.com/priyankumodi/Tescribe
 * Documentation, Token Reference, & Guides: See README.md in the repo above.
 * ============================================================================
 */

public class Tescribe {
    private static Integer globalSequence = 0;

    // Mock variable for 100% test coverage
    @TestVisible
    private static Tescribe_Template__mdt mockTemplate;

    private final SObjectType targetType;
    private Integer quantity = 1;
    private final List<FieldRule> rules = new List<FieldRule>();

    // Optimized internal structure to minimize memory footprint
    private class IntegerRange {
        final Integer start, stop;
        IntegerRange(Integer start, Integer stop) {
            this.start = start;
            this.stop = stop;
        }
    }

    private class FieldRule {
        String field;
        Object value;
        List<Object> valueList;
        Set<Integer> specificIndices = new Set<Integer>();
        List<IntegerRange> ranges = new List<IntegerRange>();

        boolean appliesTo(Integer index) {
            if (specificIndices.isEmpty() && ranges.isEmpty())
                return true;
            if (specificIndices.contains(index))
                return true;
            // CPU Optimized: Using simple for-loop over ranges
            for (Integer i = 0, size = ranges.size(); i < size; i++) {
                IntegerRange r = ranges[i];
                if (index >= r.start && index <= r.stop)
                    return true;
            }
            return false;
        }
    }

    private Tescribe(SObjectType objType) {
        this.targetType = objType;
    }

    public static Tescribe builder(SObjectType objType) {
        return new Tescribe(objType);
    }

    /**
     * Metadata Entry Point
     * Optimized: Uses single SOQL and bulk field mapping
     * Updated with "Smart Mock" logic to improve code coverage.
     */
    public static Tescribe builder(String templateName) {
        Tescribe_Template__mdt meta;

        // 2. Check for mock first to drive 100% test coverage
        if (Test.isRunningTest() && mockTemplate != null) {
            meta = mockTemplate;
        } else {
            List<Tescribe_Template__mdt> templates = [
                SELECT JSON_Data__c, Object_API_Name__c
                FROM Tescribe_Template__mdt
                WHERE DeveloperName = :templateName AND Is_Active__c = TRUE
                LIMIT 1
            ];

            if (templates.isEmpty()) {
                throw new IllegalArgumentException(
                    'Tescribe: Active template not found: ' + templateName
                );
            }
            meta = templates[0];
        }

        SObjectType t = Schema.getGlobalDescribe().get(meta.Object_API_Name__c);

        if (t == null) {
            throw new IllegalArgumentException(
                'Tescribe: Invalid Object: ' + meta.Object_API_Name__c
            );
        }

        Tescribe instance = new Tescribe(t);

        if (String.isNotBlank(meta.JSON_Data__c)) {
            Map<String, Object> rawData = (Map<String, Object>) JSON.deserializeUntyped(
                meta.JSON_Data__c
            );
            Map<String, SObjectField> fieldMap = t.getDescribe().fields.getMap();

            for (String key : rawData.keySet()) {
                if (fieldMap.containsKey(key)) {
                    DescribeFieldResult d = fieldMap.get(key).getDescribe();
                    if (d.isCreateable() && !d.isCalculated()) {
                        instance.setFieldValue(key, rawData.get(key));
                    }
                }
            }
        }
        return instance;
    }

    public Tescribe repeat(Integer qty) {
        this.quantity = qty;
        return this;
    }

    public Tescribe setFieldValue(Schema.SObjectField field, Object value) {
        return setFieldValue(String.valueOf(field), value, new List<String>());
    }

    public Tescribe setFieldValue(Schema.SObjectField field, Object value, List<String> selectors) {
        return setFieldValue(String.valueOf(field), value, selectors);
    }

    public Tescribe setFieldValue(String fieldName, Object value) {
        return setFieldValue(fieldName, value, new List<String>());
    }

    public Tescribe setFieldValue(String fieldName, Object value, List<String> selectors) {
        FieldRule rule = new FieldRule();
        rule.field = fieldName;
        rule.value = value;

        // FIX: Add null check before iterating to avoid NullPointerException
        if (selectors != null) {
            for (String s : selectors) {
                if (s.contains('-')) {
                    List<String> parts = s.split('-');
                    rule.ranges.add(
                        new IntegerRange(
                            Integer.valueOf(parts[0].trim()),
                            Integer.valueOf(parts[1].trim())
                        )
                    );
                } else {
                    rule.specificIndices.add(Integer.valueOf(s.trim()));
                }
            }
        }

        rules.add(rule);
        return this;
    }

    public Tescribe setFieldValues(Schema.SObjectField field, List<SObject> records) {
        List<Object> ids = new List<Object>();
        if (records != null) {
            for (SObject so : records)
                ids.add(so.Id);
        }
        return setFieldValues(String.valueOf(field), ids);
    }

    public Tescribe setFieldValues(Schema.SObjectField field, List<Object> values) {
        return setFieldValues(String.valueOf(field), values);
    }

    public Tescribe setFieldValues(String fieldName, List<SObject> records) {
        List<Object> ids = new List<Object>();
        if (records != null) {
            for (SObject so : records) {
                ids.add(so.Id);
            }
        }
        return setFieldValues(fieldName, ids);
    }

    public Tescribe setFieldValues(String fieldName, List<Object> values) {
        FieldRule rule = new FieldRule();
        rule.field = fieldName;
        rule.valueList = values;
        rules.add(rule);
        return this;
    }

    public List<SObject> build() {
        List<SObject> records = new List<SObject>();
        List<FieldRule> globalRules = new List<FieldRule>();
        Map<Integer, List<FieldRule>> specificRuleMap = new Map<Integer, List<FieldRule>>();

        // Pre-sort rules into buckets to avoid double-looping later
        for (FieldRule rule : rules) {
            if (rule.specificIndices.isEmpty() && rule.ranges.isEmpty()) {
                globalRules.add(rule);
            } else {
                for (Integer i = 0; i < quantity; i++) {
                    if (rule.appliesTo(i)) {
                        if (!specificRuleMap.containsKey(i))
                            specificRuleMap.put(i, new List<FieldRule>());
                        specificRuleMap.get(i).add(rule);
                    }
                }
            }
        }

        for (Integer i = 0; i < quantity; i++) {
            globalSequence++;
            SObject obj = targetType.newSObject();
            // Apply global prototype fields
            for (FieldRule rule : globalRules)
                obj.put(rule.field, getFieldValue(rule, i));
            // Overwrite with specific selector fields
            if (specificRuleMap.containsKey(i)) {
                for (FieldRule rule : specificRuleMap.get(i))
                    obj.put(rule.field, getFieldValue(rule, i));
            }
            records.add(obj);
        }
        return records;
    }

    public List<SObject> save() {
        List<SObject> records = this.build();
        if (!records.isEmpty())
            insert records; // Safe insert
        return records;
    }

    private Object getFieldValue(FieldRule rule, Integer i) {
        if (rule.valueList != null)
            return (i < rule.valueList.size()) ? rule.valueList[i] : null;
        return processTokens(rule.value, i);
    }

    /**
     * Performance Optimized Token Processor
     * Uses String.contains() and String.replace() for CPU efficiency
     */
    private Object processTokens(Object val, Integer index) {
        if (!(val instanceof String))
            return val;
        String s = (String) val;
        if (s.indexOf('{') == -1)
            return s;

        if (s.contains('{counter')) {
            String t = extractToken(s, '{counter');
            Integer off = t.contains(':')
                ? Integer.valueOf(t.substring(t.indexOf(':') + 1, t.length() - 1)) - 1
                : 0;
            s = s.replace(t, String.valueOf(index + 1 + off));
        }
        if (s.contains('{alpha')) {
            String t = extractToken(s, '{alpha');
            Integer off = t.contains(':')
                ? getAlphaIndex(t.substring(t.indexOf(':') + 1, t.length() - 1).toUpperCase())
                : 0;
            s = s.replace(t, toAlpha(index + off));
        }
        if (s.contains('{0')) {
            String t = extractToken(s, '{0');
            Integer colonIdx = t.indexOf(':');
            Integer pad = (colonIdx != -1) ? colonIdx - 1 : t.length() - 2;
            Integer startVal = (colonIdx != -1)
                ? Integer.valueOf(t.substring(colonIdx + 1, t.length() - 1))
                : 1;
            s = s.replace(t, String.valueOf(index + startVal).leftPad(pad, '0'));
        }
        if (s.contains('{index}'))
            s = s.replace('{index}', String.valueOf(index));
        if (s.contains('{random}'))
            s = s.replace(
                '{random}',
                globalSequence + String.valueOf(Crypto.getRandomInteger()).left(4)
            );

        return s;
    }

    private String extractToken(String full, String key) {
        Integer start = full.indexOf(key);
        return full.substring(start, full.indexOf('}', start) + 1);
    }

    private String toAlpha(Integer idx) {
        String res = '';
        while (idx >= 0) {
            res = String.fromCharArray(new List<Integer>{ 65 + Math.mod(idx, 26) }) + res;
            idx = (idx / 26) - 1;
        }
        return res;
    }

    private Integer getAlphaIndex(String a) {
        Integer res = 0;
        for (Integer i = 0, len = a.length(); i < len; i++) {
            res = res * 26 + (a.charAt(i) - 64);
        }
        return res - 1;
    }
}
