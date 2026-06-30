import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { getPreferences } from "./preferences";

const execFileAsync = promisify(execFile);

export type VaultEntry = {
	id: string;
	name: string;
	user?: string;
	folder?: string;
};

export type FieldKind = "text" | "password" | "otp";

export type VaultField = {
	title: string;
	kind: FieldKind;
	// Plain fields carry their value directly; OTP codes are fetched on demand
	// so a fresh code is generated at the moment the user acts on it.
	value?: string;
	resolve?: () => Promise<string>;
};

type RawListEntry = {
	id: string;
	name?: string | null;
	user?: string | null;
	folder?: string | null;
};

type RawCipher = {
	id: string;
	name: string;
	folder?: string | null;
	// `data` is an untagged enum in rbw: Login/Card/Identity/SshKey all flatten
	// their fields onto this object, so unknown keys are handled generically.
	data?: Record<string, unknown> & {
		username?: string | null;
		password?: string | null;
		totp?: string | null;
		uris?: { uri?: string }[] | null;
	};
	fields?: {
		name?: string | null;
		value?: string | null;
		type?: string | null;
	}[];
	notes?: string | null;
};

// Replaced at Nix build time with the store bin/ holding rbw and rbw-agent.
// Left as the placeholder under `vici develop`, where PATH already has rbw.
// rbw locates rbw-agent through PATH too, so this single entry covers both.
const BUNDLED_BIN_DIR = "@rbwBinDir@";

function rbwEnv(): NodeJS.ProcessEnv {
	const { additionalPath } = getPreferences();
	const env = { ...process.env };
	const bundled = BUNDLED_BIN_DIR.startsWith("@") ? undefined : BUNDLED_BIN_DIR;
	const prefix = [additionalPath, bundled].filter(Boolean).join(":");
	if (prefix) {
		env.PATH = env.PATH ? `${prefix}:${env.PATH}` : prefix;
	}
	return env;
}

async function rbw(args: string[]): Promise<string> {
	try {
		const { stdout } = await execFileAsync("rbw", args, {
			env: rbwEnv(),
			maxBuffer: 16 * 1024 * 1024,
		});
		return stdout;
	} catch (error) {
		// rbw reports actionable causes (locked vault, agent failure) on stderr;
		// surface that instead of the generic non-zero-exit message.
		const stderr = (error as { stderr?: string }).stderr;
		throw new Error(stderr?.trim() || (error as Error).message);
	}
}

export async function listEntries(): Promise<VaultEntry[]> {
	// `rbw list --raw` unlocks via the agent first, then emits every field as JSON.
	const parsed = JSON.parse(await rbw(["list", "--raw"])) as RawListEntry[];
	return parsed
		.filter((entry) => entry.name)
		.map((entry) => ({
			id: entry.id,
			name: entry.name as string,
			user: entry.user ?? undefined,
			folder: entry.folder ?? undefined,
		}));
}

export async function getFields(id: string): Promise<VaultField[]> {
	// Address the entry by UUID to stay unambiguous when names collide.
	const cipher = JSON.parse(await rbw(["get", "--raw", id])) as RawCipher;
	const data = cipher.data ?? {};
	const fields: VaultField[] = [];

	if (data.username) {
		fields.push({
			title: "Username",
			kind: "text",
			value: String(data.username),
		});
	}
	if (data.password) {
		fields.push({
			title: "Password",
			kind: "password",
			value: String(data.password),
		});
	}
	if (data.totp) {
		fields.push({
			title: "One-Time Password",
			kind: "otp",
			resolve: () => getCode(id),
		});
	}

	if (Array.isArray(data.uris)) {
		const uris = data.uris;
		uris.forEach((entry, index) => {
			const uri = entry?.uri;
			if (uri) {
				fields.push({
					title: uris.length > 1 ? `URI ${index + 1}` : "URI",
					kind: "text",
					value: uri,
				});
			}
		});
	}

	// Card/Identity/SshKey expose their own flat keys on `data`; treat the
	// sensitive-looking ones as concealed.
	const handled = new Set(["username", "password", "totp", "uris"]);
	for (const [key, raw] of Object.entries(data)) {
		if (handled.has(key) || typeof raw !== "string" || raw === "") continue;
		const concealed = /password|code|number|private_key|ssn/.test(key);
		fields.push({
			title: humanize(key),
			kind: concealed ? "password" : "text",
			value: raw,
		});
	}

	for (const field of cipher.fields ?? []) {
		if (!field?.name || field.value == null || field.value === "") continue;
		fields.push({
			title: field.name,
			kind: field.type === "hidden" ? "password" : "text",
			value: field.value,
		});
	}

	if (cipher.notes) {
		fields.push({ title: "Notes", kind: "text", value: cipher.notes });
	}

	return fields;
}

async function getCode(id: string): Promise<string> {
	return (await rbw(["code", id])).trim();
}

function humanize(key: string): string {
	return key.replace(/_/g, " ").replace(/\b\w/g, (char) => char.toUpperCase());
}
