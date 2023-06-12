global with sharing class GoogleApi {
	private static final String clientId = 'YOUR_CLIENT_ID';
	private static final String clientSecret = 'YOUR_CLIENT_SECRET';
	private static final String redirectURI = 'https://YOUR_ORG_DOMAIN/apex/RedirectPage';
	private static final String format = 'yyyy-MM-dd\'T\'hh:mm:ssZ';

	public static String getToken(String code) {
		String authorizationHeader = EncodingUtil.base64Encode(
			Blob.valueof(clientId + ':' + clientSecret)
		);
		String requestBody = 'grant_type=authorization_code';
		requestBody += '&code=' + EncodingUtil.urlEncode(code, 'UTF-8');
		requestBody +=
			'&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8');
		requestBody +=
			'&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');
		requestBody +=
			'&redirect_uri=' + EncodingUtil.urlEncode(redirectURI, 'UTF-8');
		Map<String, String> params = new Map<String, String>{
			'endpoint' => 'https://oauth2.googleapis.com/token',
			'method' => 'POST',
			'body' => requestBody,
			'headers' => JSON.serialize(
				new Map<String, String>{
					'Content-Type' => 'application/x-www-form-urlencoded',
					'Authorization' => 'Basic' + authorizationHeader
				}
			)
		};
		return makeCallout(params);
	}

	private String access_token = null;

	private GoogleAPI__c tokenData;

	private Map<String, Object> tokenDataUntyped;

	public String refresh_token {
		get {
			if (this.tokenDataUntyped != null) {
				return String.valueOf(
					this.tokenDataUntyped.get('refresh_token')
				);
			}
			return null;
		}
	}

	public GoogleApi(String token) {
		this.access_token = token;
		List<GoogleAPI__c> records = [
			SELECT Id, Name, Value__c, User__c
			FROM GoogleAPI__c
			WHERE User__c = :UserInfo.getUserId()
			LIMIT 1
		];
		if (!records.isEmpty()) {
			this.tokenData = records[0];
		}
		if (
			this.tokenData == null || String.isBlank(this.tokenData?.Value__c)
		) {
			return;
		}
		try {
			this.tokenDataUntyped = (Map<String, Object>) JSON.deserializeUntyped(
				this.tokenData.Value__c
			);
		} catch (Exception e) {
			System.debug(e.getMessage());
		}
	}

	public String refreshToken() {
		String requestBody = 'grant_type=refresh_token';
		requestBody += '&refresh_token=' + this.refresh_token;
		requestBody += '&client_id=' + clientId;
		requestBody +=
			'&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');
		Map<String, String> params = new Map<String, String>{
			'endpoint' => 'https://oauth2.googleapis.com/token',
			'method' => 'POST',
			'body' => requestBody,
			'headers' => JSON.serialize(
				new Map<String, String>{
					'Content-Type' => 'application/x-www-form-urlencoded'
				}
			)
		};
		return makeCallout(params);
	}

	public String logout() {
		String requestBody = 'token=' + this.access_token;
		Map<String, String> requestParams = new Map<String, String>{
			'endpoint' => 'https://oauth2.googleapis.com/revoke',
			'method' => 'POST',
			'body' => requestBody,
			'headers' => JSON.serialize(
				new Map<String, String>{
					'Content-Type' => 'application/x-www-form-urlencoded'
				}
			)
		};
		return makeCallout(requestParams);
	}

	public String getCalendars() {
		return makeCallout(
			new Map<String, String>{
				'endpoint' => 'https://www.googleapis.com/calendar/v3/users/me/calendarList?maxResults=10&minAccessRole=owner',
				'method' => 'GET',
				'body' => null,
				'headers' => JSON.serialize(
					new Map<String, String>{
						'Authorization' => 'Bearer ' + this.access_token
					}
				)
			}
		);
	}

	public String getCalendarEvents(String calendarId) {
		String endPoint =
			'https://www.googleapis.com/calendar/v3/calendars/' +
			calendarId +
			'/events';
		Date startOfMonth = Date.today().toStartOfMonth();
		Date endOfMonth = startOfMonth.addMonths(1).addDays(-1);
		Datetime dtStart = (Datetime) startOfMonth;
		Datetime dtEnd = (Datetime) endOfMonth;
		endPoint +=
			'?timeMin=' +
			EncodingUtil.urlEncode(dtStart.format(format), 'UTF-8');
		endPoint +=
			'&timeMax=' + EncodingUtil.urlEncode(dtEnd.format(format), 'UTF-8');
		endPoint += '&singleEvents=true';
		System.debug(endPoint);
		return makeCallout(
			new Map<String, String>{
				'endpoint' => endPoint,
				'method' => 'GET',
				'body' => null,
				'headers' => JSON.serialize(
					new Map<String, String>{
						'Authorization' => 'Bearer ' + this.access_token
					}
				)
			}
		);
	}

	private static String makeCallout(Map<String, String> requestParams) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
		request.setEndpoint(requestParams.get('endpoint'));
		request.setMethod(requestParams.get('method'));
		Map<String, Object> headers = (Map<String, Object>) JSON.deserializeUntyped(
			requestParams.get('headers')
		);
		for (String headerName : headers.keySet()) {
			request.setHeader(
				headerName,
				String.valueOf(headers.get(headerName))
			);
		}
		if (requestParams.get('body') != null) {
			request.setBody(String.valueOf(requestParams.get('body')));
		}
		// https://www.googleapis.com
		try {
			HttpResponse response = http.send(request);
			switch on response.getStatusCode() {
				when 200 {
					return response.getBody();
				}
				when 201 {
					return response.getBody();
				}
				when else {
					System.debug(response.getBody());
					return null;
				}
			}
		} catch (Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			return '{"status": "error", "message": "' + e.getMessage() + '"}';
		}
	}
}
