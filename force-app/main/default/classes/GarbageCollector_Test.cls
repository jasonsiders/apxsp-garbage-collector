@IsTest 
private class GarbageCollector_Test {
    static Garbage_Collection_Job__mdt testSoqlJob = new Garbage_Collection_Job__mdt(
        Active__c = true, 
        Batch_Size__c = 200, 
        SObjectType__c = 'Account',
        SOQL_Filter__c = 'CreatedDate = TODAY'
    );

    static Garbage_Collection_Job__mdt testApexJob = new Garbage_Collection_Job__mdt(
        Active__c = true, 
        Apex_Class_Name__c = 'GarbageCollector_Test.TestExtension',
        Batch_Size__c = 200, 
        SObjectType__c = 'Account'
    );

    @IsTest 
    static void shouldGenerateScopeUsingSoql() {
        Garbage_Collection_Job__mdt jobMdt = testSoqlJob; 
        
        Test.startTest(); 
        GarbageCollector batchJob = GarbageCollector.getInstance(jobMdt);
        Test.stopTest();

        System.assertEquals(true, (batchJob instanceOf GarbageCollectorSoql), 'Wrong extending type');
        GarbageCollectorSoql scopedJob = (GarbageCollectorSoql) batchJob; 
        System.assertEquals(true, scopedJob.start(null)?.getQuery().contains(jobMdt.SOQL_Filter__c), 'SOQL Filter was not applied'); 
        System.assertEquals(100, Database.query(scopedJob.start(null)?.getQuery())?.size(), 'Wrong # of query results');
    }

    @IsTest 
    static void shouldGenerateScopeUsingApex() {
        // Note: Salesforce does not allow Database.Batchable to be applied to inner types
        // When this happens, an error is thrown during batch execution:
        // `System.UnexpectedException - Error Processing Messages (System Code)`
        // For test purposes, we just need to see that the correct type is generated from the MDT,
        // And that the right records are returned via its start() method
        Garbage_Collection_Job__mdt jobMdt = testApexJob; 
        
        Test.startTest(); 
        GarbageCollector batchJob = GarbageCollector.getInstance(jobMdt);
        Test.stopTest();

        System.assertEquals(true, (batchJob instanceOf GarbageCollector_Test.TestExtension), 'Wrong extending type');
        GarbageCollector_Test.TestExtension scopedJob = (GarbageCollector_Test.TestExtension) batchJob; 
        System.assertEquals(200, scopedJob.start(null)?.size(), 'Wrong # of records returned');
    }

    @IsTest 
    static void shouldDeleteScopedRecords() {
        Garbage_Collection_Job__mdt jobMdt = testSoqlJob; 
        
        Test.startTest(); 
        GarbageCollector batchJob = GarbageCollector.getInstance(jobMdt).runBatch();
        Test.stopTest();

        System.assertNotEquals(null, batchJob?.jobId, 'A job was not created');
        System.assertEquals(0, [SELECT Id FROM Account]?.size(), 'Accounts were not deleted');
        System.assertEquals(100, [SELECT Id FROM Lead]?.size(), 'Leads were deleted');
    }

    @IsTest 
    static void shouldNotRunIfNoCriteriaDefined() {
        Garbage_Collection_Job__mdt jobMdt = testApexJob;
        jobMdt.Apex_Class_Name__c = null; // No Apex or SOQL defined!

        Test.startTest();
        Exception error; 
        try {
            GarbageCollector.getInstance(jobMdt);
        } catch (GarbageCollector.InvalidCriteriaException caughtError) {
            error = caughtError; 
        }
        Test.stopTest();

        System.assertNotEquals(null, error, 'An error was not caught');
    } 

    @IsTest 
    static void shouldNotRunIfInvalidTypeDefined() {
        Garbage_Collection_Job__mdt jobMdt = testApexJob;
        jobMdt.Apex_Class_Name__c = 'FakeClass'; 

        Test.startTest();
        Exception error; 
        try {
            GarbageCollector.getInstance(jobMdt);
        } catch (GarbageCollector.InvalidCriteriaException caughtError) {
            error = caughtError; 
        }
        Test.stopTest();

        System.assertNotEquals(null, error, 'An error was not caught');
    }

    @IsTest 
    static void shouldNotRunIfInvalidQuery() {
        Garbage_Collection_Job__mdt jobMdt = testSoqlJob;
        jobMdt.SOQL_Filter__c = 'THIS SHOULD NOT RUN'; // Leads to an invalid query
        GarbageCollector instance = GarbageCollector.getInstance(jobMdt);

        Exception error; 
        try {
            // Note: Placed Test.start/stopTest() inside the try block
            // to catch exceptions thrown DURING the batch execution context
            Test.startTest();
            instance.runBatch();
            Test.stopTest();   
        } catch (System.QueryException caughtError) {
            error = caughtError; 
        }

        System.assertNotEquals(null, error, 'An error was not caught');
    }

    @IsTest 
    static void shouldLogIndividualFailures() {
        // If an error is registered for an individual record, log it
        // Deleting a contact which is tied to a case will generate an error
        Logger.settings = new Log_Setting__c(
            Enabled__c = true, 
            Level__c = 'FINEST'
        );
        Contact contact = new Contact(LastName = 'Test');
        insert contact;
        insert new Case(ContactId = contact.Id); 
        GarbageCollector instance = new TestExtension(); 
        Database.BatchableContext mockContext = null; 
        List<SObject> scope = new List<SObject>{contact};

        Test.startTest();
        instance.execute(mockContext, scope);
        Test.stopTest();

        List<Log_Event__e> logEvents = (List<Log_Event__e>) Logger.dmlEngine.getPublishedEvents();
        System.assertEquals(scope?.size(), logEvents?.size(), 'Wrong # of log events: ' + Logger.dmlEngine);
    }

    @IsTest 
    static void shouldLogBatchFailure() {
        // If a fatal error is thrown during the execute() method, log it
        Logger.settings = new Log_Setting__c(
            Enabled__c = true, 
            Level__c = 'FINEST'
        );
        GarbageCollector instance = new TestExtension(); 
        Database.BatchableContext mockContext = null; 
        List<SObject> scope = null; 

        Test.startTest();
        Exception error; 
        try {
            instance.execute(mockContext, scope);
        } catch (Exception caughtError) {
            error = caughtError; 
        }
        Test.stopTest();

        List<Log_Event__e> logEvents = (List<Log_Event__e>) Logger.dmlEngine.getPublishedEvents();
        System.assertEquals(1, logEvents?.size(), 'Wrong # of log events');
        System.assert(logEvents[0].Message__c?.startsWith('Unexpected error'), 'Wrong event logged');
    }

    @TestSetup 
    static void setup() {
        IDml dml = new Dml(); 
        List<SObject> records = new List<SObject>(); 
        for (Integer i = 0; i < 100; i++) {
            records.add(new Account(
                Name = 'Test Account #' + (i + 1)
            ));
            records.add(new Lead(
                Company = 'Test Company #' + (i + 1),
                FirstName = 'John',
                LastName = 'Doe'
            )); 
        }
        records.sort();
        dml.doInsert(records); 
    }

    public class TestExtension extends GarbageCollector {
        // Will delete both Leads & Accounts
        public List<SObject> start(Database.BatchableContext context) {
            List<SObject> records = new List<SObject>(); 
            records.addAll([SELECT Id FROM Account]);
            records.addAll([SELECT Id FROM Lead]);
            return records;
        }
    }
}