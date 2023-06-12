export function isEmpty(obj) {
	if (obj === undefined || obj === null || obj === "") {
		return true;
	}
	if (Array.isArray(obj)) {
		return obj.length === 0;
	}
	if (
		!Array.isArray(obj) &&
		typeof obj === "object" &&
		Object.prototype.toString.call(obj) === "[object Object]"
	) {
		return Object.keys(obj).length === 0;
	}
	if (obj instanceof Map || obj instanceof Set) {
		return obj.size === 0;
	}
	return false;
}
