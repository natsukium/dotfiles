import {
	Action,
	ActionPanel,
	Icon,
	List,
	showToast,
	Toast,
	useNavigation,
} from "@vicinae/api";
import { useCallback, useEffect, useState } from "react";
import { performAction } from "./actions";
import { type ActionType, getPreferences } from "./preferences";
import {
	getFields,
	listEntries,
	type VaultEntry,
	type VaultField,
} from "./vault";

const preferences = getPreferences();

export default function Command() {
	const [entries, setEntries] = useState<VaultEntry[]>([]);
	const [isLoading, setIsLoading] = useState(true);
	const [error, setError] = useState<string | undefined>();
	const { push } = useNavigation();

	const refresh = useCallback(async () => {
		setIsLoading(true);
		setError(undefined);
		try {
			setEntries(await listEntries());
		} catch (err) {
			const message = err instanceof Error ? err.message : "Unexpected error";
			setError(message);
			await showToast({
				style: Toast.Style.Failure,
				title: "Failed to load vault",
				message,
			});
		} finally {
			setIsLoading(false);
		}
	}, []);

	useEffect(() => {
		refresh();
	}, [refresh]);

	return (
		<List isLoading={isLoading} searchBarPlaceholder="Search vault">
			{error ? (
				<List.EmptyView
					title="Vault unavailable"
					description={error}
					actions={
						<ActionPanel>
							<Action
								title="Reload"
								icon={Icon.RotateAntiClockwise}
								onAction={refresh}
							/>
						</ActionPanel>
					}
				/>
			) : (
				entries.map((entry) => (
					<List.Item
						key={entry.id}
						title={entry.name}
						subtitle={entry.user}
						accessories={entry.folder ? [{ text: entry.folder }] : undefined}
						icon={Icon.Key}
						actions={
							<ActionPanel>
								<Action
									title="View Secrets"
									icon={Icon.Key}
									onAction={() => push(<SecretsView entry={entry} />)}
								/>
								<Action
									title="Reload"
									icon={Icon.RotateAntiClockwise}
									onAction={refresh}
								/>
							</ActionPanel>
						}
					/>
				))
			)}
		</List>
	);
}

function SecretsView({ entry }: { entry: VaultEntry }) {
	const [fields, setFields] = useState<VaultField[]>([]);
	const [isLoading, setIsLoading] = useState(true);
	const [error, setError] = useState<string | undefined>();

	useEffect(() => {
		let disposed = false;
		(async () => {
			try {
				const resolved = await getFields(entry.id);
				if (!disposed) {
					setFields(resolved);
					setIsLoading(false);
				}
			} catch (err) {
				const message =
					err instanceof Error ? err.message : "Unable to read entry";
				if (!disposed) {
					setError(message);
					setIsLoading(false);
				}
				await showToast({
					style: Toast.Style.Failure,
					title: "Failed to read entry",
					message,
				});
			}
		})();
		return () => {
			disposed = true;
		};
	}, [entry.id]);

	const primary = preferences.action;
	const secondary: ActionType = primary === "paste" ? "copy" : "paste";

	return (
		<List
			isLoading={isLoading}
			searchBarPlaceholder="Select a field to copy or paste"
		>
			{error ? (
				<List.EmptyView title="Unable to read entry" description={error} />
			) : (
				fields.map((field, index) => (
					<List.Item
						key={`${field.title}-${index}`}
						title={field.title}
						icon={iconFor(field)}
						actions={
							<ActionPanel>
								<Action
									title={actionLabel(primary)}
									icon={actionIcon(primary)}
									onAction={() => performAction(field, primary)}
								/>
								<Action
									title={actionLabel(secondary)}
									icon={actionIcon(secondary)}
									onAction={() => performAction(field, secondary)}
								/>
							</ActionPanel>
						}
					/>
				))
			)}
		</List>
	);
}

function actionLabel(action: ActionType): string {
	return action === "paste" ? "Paste" : "Copy to Clipboard";
}

function actionIcon(action: ActionType): Icon {
	return action === "paste" ? Icon.Keyboard : Icon.CopyClipboard;
}

function iconFor(field: VaultField): Icon {
	if (field.kind === "otp") return Icon.Clock;
	if (field.kind === "password") return Icon.Key;
	if (/user/i.test(field.title)) return Icon.Person;
	if (/uri|url/i.test(field.title)) return Icon.Link;
	if (/note/i.test(field.title)) return Icon.Document;
	return Icon.Text;
}
