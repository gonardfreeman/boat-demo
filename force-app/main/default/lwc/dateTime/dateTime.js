import { LightningElement, api } from "lwc";
import { isEmpty } from "c/helper";
import LOCALE from "@salesforce/i18n/locale";

class DateTime extends LightningElement {
	@api dateString = null;

	get date() {
		if (isEmpty(this.dateString)) {
			return null;
		}
		return new Date(this.dateString);
	}

	get formatted() {
		return new Intl.DateTimeFormat(LOCALE, {
			dateStyle: "short",
			timeStyle: "short"
		}).format(this.date);
	}

	get showDate() {
		return !isEmpty(this.date);
	}
}

export default DateTime;
