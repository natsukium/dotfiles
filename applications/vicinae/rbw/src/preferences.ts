import { getPreferenceValues } from "@vicinae/api";

export type ActionType = "paste" | "copy";

export type Preferences = {
	action: ActionType;
	additionalPath?: string;
};

export function getPreferences(): Preferences {
	const raw = getPreferenceValues<{
		action?: ActionType;
		additionalPath?: string;
	}>();
	const additionalPath = raw.additionalPath?.trim();
	return {
		action: raw.action ?? "paste",
		additionalPath: additionalPath ? additionalPath : undefined,
	};
}
