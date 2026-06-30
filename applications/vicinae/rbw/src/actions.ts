import { Clipboard, closeMainWindow, showToast, Toast } from "@vicinae/api";
import type { ActionType } from "./preferences";
import type { VaultField } from "./vault";

export async function performAction(
	field: VaultField,
	action: ActionType,
): Promise<void> {
	try {
		const value = field.value ?? (field.resolve ? await field.resolve() : "");
		if (!value) {
			throw new Error("Field is empty");
		}
		// Mark secrets concealed so clipboard managers can avoid persisting them.
		const concealed = field.kind === "password" || field.kind === "otp";
		if (action === "copy") {
			await Clipboard.copy(value, { concealed });
			await closeMainWindow();
		} else {
			await closeMainWindow();
			await Clipboard.paste(value);
		}
	} catch (error) {
		const message = error instanceof Error ? error.message : "Unexpected error";
		await showToast({
			style: Toast.Style.Failure,
			title: `Failed to ${action}`,
			message,
		});
	}
}
