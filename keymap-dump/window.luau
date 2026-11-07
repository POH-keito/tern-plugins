--!strict
-- Palette command "Keymap: dump defaults" writes this OS's default Tern key
-- bindings to keymap-defaults/<apple|pc>.toml inside this plugin's directory.
-- Your own keybinds hide the defaults, so they are cleared only while the keys
-- are read, and are always restored afterwards.

local function toml_str(s: string): string
	return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local function snapshot(keys: { [string]: { string } }): { [string]: string }
	local out: { [string]: string } = {}
	for chord, actions in keys do
		out[chord] = table.concat(actions, ",")
	end
	return out
end

local function same(a: { [string]: string }, b: { [string]: string }): boolean
	for k, v in a do
		if b[k] ~= v then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

-- If the overrides did not actually come off, reading would record your keys as
-- defaults; return nil instead.
-- Do not test "is an override chord still bound": on macOS an override can be
-- the same chord as the default.
local function read_defaults(cx: WindowCx): { [string]: { string } }?
	local overrides = cx.settings:keybinds()
	local has_overrides = next(overrides) ~= nil
	local ok, keys = pcall(function()
		local before = cx.actions:keys()
		cx.settings:set("keybinds", {})
		local after = cx.actions:keys()
		if has_overrides and same(snapshot(before), snapshot(after)) then
			return nil
		end
		return after
	end)
	cx.settings:set("keybinds", overrides)
	if not ok then
		error(keys)
	end
	if keys == nil then
		return nil
	end
	local by_action: { [string]: { string } } = {}
	for chord, actions in keys do
		for _, action in actions do
			if action:sub(1, 7) ~= "plugin." then
				by_action[action] = by_action[action] or {}
				table.insert(by_action[action], chord)
			end
		end
	end
	-- List actions that have no default key too, so the file is a complete
	-- inventory of Tern's actions, not only of the bound ones.
	for _, a in cx.actions:list() do
		if a.id:sub(1, 7) ~= "plugin." then
			by_action[a.id] = by_action[a.id] or {}
		end
	end
	return by_action
end

local function dump(cx: WindowCx)
	local by_action = read_defaults(cx)
	if by_action == nil then
		cx.docs:new_note("Keymap dump", "The effective keymap did not change after clearing keybinds, so nothing was written. keys() read with your overrides still applied cannot be used as the defaults.")
		return
	end

	local names: { string } = {}
	for action, chords in by_action do
		table.sort(chords)
		table.insert(names, action)
	end
	table.sort(names)

	-- A GUI launch on macOS has no ~/.local/bin on PATH, so "tern" does not resolve.
	local exe = if tern.runtime.os == "macos" then "/Applications/Tern.app/Contents/MacOS/tern" else "tern"
	tern.process.run({ exe, "--version" }):next(function(res: any, _err: any, cx2: WindowCx)
		local version = (res and res.stdout or ""):gsub("^tern%s+", ""):gsub("%s+$", "")
		local lines = { `tern_version = {toml_str(version)}`, "", "[defaults]" }
		for _, action in names do
			local quoted: { string } = {}
			for _, c in by_action[action] do
				table.insert(quoted, toml_str(c))
			end
			table.insert(lines, `{toml_str(action)} = [{table.concat(quoted, ", ")}]`)
		end

		local os = if tern.runtime.os == "macos" then "apple" else "pc"
		local dir = tern.plugin.dir .. "/keymap-defaults"
		tern.fs.mkdir(dir)
		local path = `{dir}/{os}.toml`
		tern.fs.write(path, table.concat(lines, "\n") .. "\n")
		cx2.docs:new_note("Keymap dump", `{#names} actions → {path}\n\nTern {version}`)
	end)
end

tern.command({
	id = "dump-defaults",
	title = "Keymap: dump defaults",
	icon = "keyboard",
	group = "Keymap",
	run = dump,
})
