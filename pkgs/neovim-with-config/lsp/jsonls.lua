return {
	server_config = {
		on_new_config = function(new_config)
			new_config.settings.json.schemas = new_config.settings.json.schemas or {}
			vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
		end,
		settings = {
			json = {
				validate = { enable = true },
			},
		},
		filetypes = { "json", "jsonc", "json5" },
	},
}
