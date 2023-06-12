import { LightningElement, api } from "lwc";
import { isEmpty } from "c/helper";
import getGoogleCalendars from "@salesforce/apex/DemoClass.getGoogleCalendars";
import getGoogleEvents from "@salesforce/apex/DemoClass.getGoogleEvents";

class CalendarsList extends LightningElement {
	_accessToken = null;
	selectedCalendar = null;

	@api
	get accessToken() {
		return this._accessToken;
	}

	set accessToken(v) {
		this._accessToken = v;
	}

	calendarsList = [];
	events = [];

	get preparedCalendars() {
		return this.calendarsList.map((c) => ({
			label: c.summary,
			value: c.id,
			selected: this.selectedCalendar === c.id
		}));
	}

	async loadCalendars() {
		console.debug(this.accessToken);
		if (
			!this.accessToken ||
			typeof this.accessToken !== "string" ||
			(typeof this.accessToken === "string" &&
				this.accessToken.trim().length < 1)
		) {
			return;
		}
		let resp = await getGoogleCalendars({ access_token: this.accessToken });
		try {
			let parsed = JSON.parse(resp);
			if (isEmpty(parsed?.items)) {
				this.calendarsList = [];
				return;
			}
			this.calendarsList = parsed.items;
		} catch (err) {
			console.error(err);
		}
	}

	handleCalendarChange(e) {
		this.selectedCalendar = e.currentTarget.value;
		this.getCalendarEvents();
	}

	async getCalendarEvents() {
		if (isEmpty(this.selectedCalendar)) {
			this.events = [];
			return;
		}
		try {
			let events = await getGoogleEvents({
				access_token: this.accessToken,
				calendarId: encodeURIComponent(this.selectedCalendar)
			});
			let parsed = JSON.parse(events);
			if (isEmpty(parsed?.items)) {
				this.events = [];
				return;
			}
			this.events = parsed.items.map((e) => {
				return {
					id: e.id,
					label: e.summary,
					start: isEmpty(e.start.dateTime)
						? e.start.date
						: e.start.dateTime,
					end: isEmpty(e.end.dateTime) ? e.end.date : e.end.dateTime
				};
			});
		} catch (err) {
			console.error(err);
		}
	}

	connectedCallback() {
		console.debug("test");
		this.loadCalendars();
	}
}

export default CalendarsList;
