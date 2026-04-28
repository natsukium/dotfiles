const HEADERS = {
	"content-type": "application/json",
	"access-control-allow-origin": "*",
	"cache-control": "public, max-age=3600",
};

const SERVER = JSON.stringify({ "m.server": "matrix.natsukium.com:443" });
const CLIENT = JSON.stringify({
	"m.homeserver": { base_url: "https://matrix.natsukium.com" },
});

export default {
	async fetch(request) {
		const { pathname } = new URL(request.url);
		if (pathname === "/.well-known/matrix/server") {
			return new Response(SERVER, { headers: HEADERS });
		}
		if (pathname === "/.well-known/matrix/client") {
			return new Response(CLIENT, { headers: HEADERS });
		}
		return new Response("Not Found", { status: 404 });
	},
};
