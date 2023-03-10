global without sharing class GarbageScheduler implements System.Schedulable {
	@TestVisible
	static final Integer FLEX_QUEUE_LIMIT = 100;
	static final apxsp.Logger.AdvancedOptions LOG_OPTIONS = new apxsp.Logger.AdvancedOptions().setSource(GarbageScheduler.class);

	@TestVisible
	List<Garbage_Collection_Job__mdt> activeJobs = this.getActiveJobs();
	@TestVisible
	List<Garbage_Collection_Job__mdt> processedJobs = new List<Garbage_Collection_Job__mdt>();
	@TestVisible
	List<Garbage_Collection_Job__mdt> skippedJobs = new List<Garbage_Collection_Job__mdt>();
	@TestVisible
	Integer flexQueueSize = this.getFlexQueueSize();

	global void execute(System.SchedulableContext context) {
		for (Garbage_Collection_Job__mdt jobMdt : this.activeJobs) {
			if (FLEX_QUEUE_LIMIT > flexQueueSize) {
				GarbageCollector batchJob = GarbageCollector.createFromMetadata(jobMdt).runBatch();
				this.logNewBatch(jobMdt, batchJob.jobId);
				processedJobs.add(jobMdt);
				flexQueueSize++;
			} else {
				this.skippedJobs.add(jobMdt);
			}
		}
		this.logSkippedJobs();
		apxsp.Logger.publish();
	}

	private void logNewBatch(Garbage_Collection_Job__mdt jobMdt, Id batchId) {
		final String template = '{0} GarbageCollector job created\nJob Name: {1}\nJob Id: {2}';
		final String message = String.format(template, new List<String>{
			jobMdt?.SObjectType__c, 
			jobMdt?.DeveloperName,
			batchId
		});
		apxsp.Logger.info(LOG_OPTIONS, message);
	}

	private void logSkippedJobs() {
		if (this.skippedJobs?.isEmpty() == false) {
			final String template =
				'Skipped {0} GarbageCollection jobs, because the Apex Flex Queue is full.\n' +
				'Please retry these jobs manually, or wait until the next scheduled run\n' +
				'Skipped jobs: {1}';
			final String message = String.format(template, new List<String>{ 
				String.valueOf(this.skippedJobs?.size()), 
				JSON.serializePretty(this.skippedJobs) 
			});
			apxsp.Logger.error(LOG_OPTIONS, message);
		}
	}

	private List<Garbage_Collection_Job__mdt> getActiveJobs() {
		Soql query = DB.Soql
			.newQuery(Garbage_Collection_Job__mdt.SObjectType)
			.selectFields(
				new List<SObjectField>{
					Garbage_Collection_Job__mdt.Apex_Class_Name__c,
					Garbage_Collection_Job__mdt.Batch_Size__c,
					Garbage_Collection_Job__mdt.DeveloperName,
					Garbage_Collection_Job__mdt.SOQL_Filter__c,
					Garbage_Collection_Job__mdt.SObjectType__c
				}
			)
			.whereCriteria(new Filter(Garbage_Collection_Job__mdt.Active__c, Filter.EQUALS, true))
			.orderBy(new SoqlSort(Garbage_Collection_Job__mdt.Priority__c, SoqlSort.Order.ASCENDING));
		return (List<Garbage_Collection_Job__mdt>) query.run();
	}

	private Integer getFlexQueueSize() {
		Soql query = DB.Soql
			.newQuery(AsyncApexJob.SObjectType)
			.whereCriteria(
				new Filter(
					AsyncApexJob.Status,
					Filter.IN_COLLECTION,
					new List<String>{ 'Holding', 'Pending', 'Processing' }
				)
			);
		return query.run()?.size();
	}
}
