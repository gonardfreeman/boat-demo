public with sharing class FLSHelper {
	private static DescribeSObjectResult describeResultCache = null;

	public FLSHelper() {
	}

	private static DescribeSObjectResult googleDescribe() {
		if (describeResultCache == null) {
			Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(
				new List<String>{ 'GoogleAPI__c' }
			);
			describeResultCache = descResult.get(0);
		}
		return describeResultCache;
	}

	public static Boolean isGoogleObjectAccesible() {
		return googleDescribe()?.isAccessible();
	}

	public static Boolean isGoogleObjectCreateable() {
		return googleDescribe()?.isCreateable();
	}

	public static Boolean isGoogleObjectUpdateable() {
		return googleDescribe()?.isUpdateable();
	}

	public static Boolean isGoogleObjectDeletable() {
		return googleDescribe()?.isDeletable();
	}

	public static Boolean checkGoogleObjectFLS(
		Set<String> fields,
		String operation
	) {
		for (String field : fields) {
			Schema.SObjectField sObjectField = googleDescribe()
				?.fields.getMap()
				.get(field);
			if (sObjectField == null) {
				continue;
			}
			if (
				(operation == 'read' &&
				!sObjectField.getDescribe().isAccessible()) ||
				(operation == 'update' &&
				!sObjectField.getDescribe().isUpdateable()) ||
				(operation == 'create' &&
				!sObjectField.getDescribe().isCreateable())
			) {
				return false;
			}
		}
		return true;
	}
}
