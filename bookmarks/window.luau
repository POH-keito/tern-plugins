--!strict
-- Lists the URLs in bookmarks.json (next to this file) as "Bookmarks: …"
-- commands in the palette (Cmd+Shift+P) and opens them in Tern's own browser.
-- To add one, append an entry to bookmarks.json and run `tern plugin reload`.
-- Do not use cx:open: a URL opened from a plugin goes to the system browser,
-- outside Tern.
-- `browser open` can only create a picture-in-picture float, so the page is
-- released from automation and docked as a normal block with cx.layout:dock.

type Bookmark = { alias: string, title: string, url: string }

local BOOKMARKS: { Bookmark } = tern.json.decode(tern.fs.read("bookmarks.json"))

local function open_in_tern(url: string, cx: WindowCx)
	local owner = cx.session:focused()
	if owner == nil then
		return
	end
	cx.browser:call({ op = "open", owner = owner, url = url }):next(function(res: any, _err: any, cx2: WindowCx)
		local block = res and res.ok and res.ok.block
		if block == nil then
			-- Fallback through the CLI. Children of the daemon have no
			-- TERN_PANE_SOCKET and look for Temp\tern.sock on Windows, so pass
			-- the pane's pipe. Only Windows sets USERNAME; inventing a pipe name
			-- on macOS would stop ctl from finding the real socket.
			local user = tern.getenv("USERNAME")
			local sock = tern.getenv("TERN_PANE_SOCKET") or (user and `\\\\.\\pipe\\tern-{user}`)
			tern.process.run({ "tern", "ctl", "browser", "open", url }, sock and { env = { TERN_PANE_SOCKET = sock } } or nil):next(function(result: any, err: any, cx3: WindowCx)
				if err ~= nil or result == nil or result.status ~= 0 then
					cx3:toast("error", "Could not open bookmark", err or (result and result.stderr))
				end
			end)
			return
		end
		cx2.browser:call({ op = "release", block = block }):next(function(_r: any, _e: any, cx3: WindowCx)
			cx3.layout:dock(block, owner, "right")
		end)
	end)
end

for _, b in BOOKMARKS do
	tern.command({
		id = b.alias,
		title = `{b.title} ({b.alias})`,
		icon = "bookmark",
		group = "Bookmarks",
		run = function(cx: WindowCx)
			open_in_tern(b.url, cx)
		end,
	})
end
