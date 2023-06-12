import { LightningElement } from "lwc";
import { isEmpty } from "c/helper";
import Id from "@salesforce/user/Id";
import getUserData from "@salesforce/apex/DemoClass.getUserData";
import getGoogleToken from "@salesforce/apex/DemoClass.getGoogleToken";
import saveToken from "@salesforce/apex/DemoClass.saveToken";
import refreshToken from "@salesforce/apex/DemoClass.refreshToken";
import logout from "@salesforce/apex/DemoClass.logout";

let listener = null;

const INSTALL_URL = "https://accounts.google.com/o/oauth2/v2/auth";
const REDIRECT_URI =
	"https://home-4bd-dev-ed--c.develop.vf.force.com/apex/RedirectPage";
const SCOPES = [
	"https://www.googleapis.com/auth/userinfo.email",
	"https://www.googleapis.com/auth/userinfo.profile",
	"https://www.googleapis.com/auth/calendar",
	"https://www.googleapis.com/auth/calendar.events"
];
const CLIENT_ID =
	"858680306047-qescfmuv1b7v565rhg0al52rp0j700sr.apps.googleusercontent.com";

class DemoGoogle extends LightningElement {
	userId = Id;
	userData = null;
	intervalID = null;
	isLoading = false;

	googleData = null;
	access_token = null;
	valid_to = null;

	get isLoggedIn() {
		return !isEmpty(this.userData?.Value__c);
	}

	get actionLabel() {
		return this.isLoggedIn ? "Logout" : "Login";
	}

	get buttonVariant() {
		return this.isLoggedIn ? "destructive" : "neutral";
	}

	setGoogleData() {
		let item = window.localStorage.getItem("googleToken");
		try {
			this.googleData = JSON.parse(item);
			this.access_token = this.googleData?.access_token ?? null;
			this.valid_to = Number(this.googleData?.valid_to ?? -1);
		} catch (err) {
			console.error(err);
		}
	}

	handleLoginLogout() {
		if (this.isLoggedIn) {
			this.handleLogout();
			return;
		}
		this.handleLogin();
	}

	handleLogin() {
		console.log("login");
		listener = this.handleMessage.bind(this);
		window.addEventListener("message", listener);
		const URI = `${INSTALL_URL}?&prompt=consent&access_type=offline&client_id=${CLIENT_ID}&scope=${encodeURIComponent(
			SCOPES.join(" ")
		)}&response_type=code&redirect_uri=${REDIRECT_URI}&state=${window.location.toString()}`;
		let w = window.open(
			URI,
			"Google Login",
			"resizable,scrollbars,status,location"
		);
		let counter = 0;
		this.intervalID = setInterval(() => {
			if (w.closed || counter > 30) {
				clearInterval(this.intervalID);
				this.isLoading = false;
			}
			counter++;
		}, 500);
	}

	async handleLogout() {
		try {
			await this.checkToken();
			await logout({ access_token: this.access_token });
			await this.saveTokenData(null);
		} catch (err) {
			console.error(err);
		}
	}

	async checkToken() {
		if (!this.isLoggedIn) {
			return;
		}
		try {
			let curTime = new Date().getTime();
			if (curTime > this.valid_to) {
				console.log("Need refresh token");
				let refreshData = await refreshToken({
					access_token: this.access_token
				});
				await this.saveTokenData(refreshData);
				console.debug("token refreshed");
			}
		} catch (err) {
			console.error(err);
		}
	}

	async handleMessage(e) {
		let parsed = null;
		try {
			parsed = JSON.parse(e.data);
		} catch (err) {
			console.log(err);
		}
		if (listener) {
			window.removeEventListener("message", listener);
			listener = null;
		}
		clearInterval(this.intervalID);
		this.intervalID = null;
		if (!parsed) {
			this.isLoading = false;
			return;
		}
		try {
			let token = await getGoogleToken({ code: parsed.code });
			this.userData = await this.saveTokenData(token);
		} catch (err) {
			console.error(err);
		}
	}

	async saveTokenData(token) {
		try {
			if (isEmpty(token)) {
				window.localStorage.removeItem("googleToken");
				await saveToken({
					tokenData: null
				});
				return null;
			}
			let parsed = JSON.parse(token);
			let { access_token, expires_in, refresh_token, scope } = parsed;
			let valid_to = new Date().getTime() + expires_in * 1000;
			window.localStorage.setItem(
				"googleToken",
				JSON.stringify({ access_token, expires_in, valid_to })
			);
			this.setGoogleData();
			let tokenData = await saveToken({
				tokenData: JSON.stringify({ refresh_token, scope })
			});
			return tokenData;
		} catch (err) {
			console.error(err);
			return null;
		}
	}

	// TODO: get calendar list
	// TODO: tests
	// TODO: get 10 events from cur month
	async connectedCallback() {
		this.isLoading = true;
		this.setGoogleData();
		try {
			this.userData = await getUserData({ userId: this.userId });
			await this.checkToken();
		} catch (err) {
			this.userData = null;
			console.error(err);
		}
		this.isLoading = false;
	}
}

export default DemoGoogle;
