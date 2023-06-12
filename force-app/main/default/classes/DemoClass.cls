public with sharing class DemoClass {
	@AuraEnabled
	public static GoogleAPI__c getUserData(String userId) {
		if (!FLSHelper.isGoogleObjectAccesible()) {
			throw new AuraHandledException(
				'Please check access to the GoogleAPI__c'
			);
		}
		try {
			List<GoogleAPI__c> userData = [
				SELECT Id, Name, Value__c, User__c
				FROM GoogleAPI__c
				WHERE User__c = :userId
				LIMIT 1
			];
			if (!userData.isEmpty()) {
				return userData[0];
			}
			return null;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static String getGoogleToken(String code) {
		return GoogleApi.getToken(code);
	}

	@AuraEnabled
	public static GoogleAPI__c saveToken(String tokenData) {
		if (
			!FLSHelper.isGoogleObjectAccesible() ||
			!FLSHelper.isGoogleObjectCreateable() ||
			!FLSHelper.isGoogleObjectUpdateable() ||
			!FLSHelper.checkGoogleObjectFLS(
				new Set<String>{ 'Name', 'Value__c', 'User__c' },
				'update'
			) ||
			!FLSHelper.checkGoogleObjectFLS(
				new Set<String>{ 'Name', 'Value__c', 'User__c' },
				'create'
			)
		) {
			throw new AuraHandledException(
				'Google Object isn\'t accessible by this user. Please check permissions'
			);
		}
		List<GoogleAPI__c> googleRecords = [
			SELECT Id, Name, Value__c, User__c
			FROM GoogleAPI__c
			WHERE User__c = :UserInfo.getUserId()
			LIMIT 1
		];
		if (String.isBlank(tokenData) || googleRecords.isEmpty()) {
			GoogleAPI__c google = new GoogleAPI__c();
			google.Name = 'token';
			google.User__c = UserInfo.getUserId();
			googleRecords.add(google);
		}
		try {
			GoogleApi gApi = new GoogleApi('access_token');
			if (
				String.isNotBlank(gApi.refresh_token) &&
				!tokenData?.contains('refresh_token')
			) {
				Map<String, Object> untyped = (Map<String, Object>) JSON.deserializeUntyped(
					tokenData
				);
				untyped.put('refresh_token', gApi.refresh_token);
				tokenData = JSON.serialize(untyped);
			}
			googleRecords[0].Value__c = tokenData;

			upsert googleRecords;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return googleRecords[0];
	}

	// Google methods
	@AuraEnabled
	public static String getGoogleCalendars(String access_token) {
		try {
			GoogleApi google = new GoogleApi(access_token);
			return google.getCalendars();
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static String getGoogleEvents(
		String access_token,
		String calendarId
	) {
		try {
			GoogleApi google = new GoogleApi(access_token);
			return google.getCalendarEvents(calendarId);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static string refreshToken(String access_token) {
		try {
			GoogleApi google = new GoogleApi(access_token);
			return google.refreshToken();
		} catch (Exception e) {
			System.debug(e.getStackTraceString());
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static string logout(String access_token) {
		try {
			GoogleApi google = new GoogleApi(access_token);
			return google.logout();
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}
