--!strict
-- Copies the card selected on a board as its source Markdown: the card line
-- (checkbox, title, tags, due date) and its indented child lines, exactly as
-- they appear in the file.
-- shortcut: the card is found as "the first top-level card line containing the
-- title". Two cards with the same title resolve to the first one.

local function focused_info(cx: WindowCx): any
	local id = cx.session:focused()
	if id == nil then
		return nil
	end
	for _, pane in cx.session:panes() do
		if pane.pane == id then
			return pane
		end
	end
	return nil
end

local function focused_card(cx: WindowCx, info: any): (string?, string?, string?)
	-- Read by the "@focused" string: a round trip through the numeric pane id
	-- loses its high bits.
	-- The default of 25 rows leaves cards in later lanes out of `lanes`, so the
	-- cursor is never found.
	local r: any = cx.session:read("@focused", { rows = 500, max_chars = 64000 })
	if r == nil then
		return nil, nil, "session:read returned nil"
	end
	if type(r) == "string" then
		return nil, nil, r
	end
	-- `read` omits `path` in some phases; the pane list always has it.
	local path: string? = r.path or info.path
	if path == nil then
		return nil, nil, "could not get the board's file path"
	end
	for _, lane in r.lanes or {} do
		for _, card in lane.cards do
			if card.cursor then
				return path, card.text, nil
			end
		end
	end
	return path, nil, nil
end

local function block_of(src: string, title: string): string?
	local lines = string.split(src, "\n")
	for i, line in lines do
		if line:match("^%- %[.%]") and line:find(title, 1, true) then
			local out = { line }
			for j = i + 1, #lines do
				local nxt = lines[j]
				if nxt:match("^%s+%S") then
					table.insert(out, nxt)
				else
					break
				end
			end
			return table.concat(out, "\n")
		end
	end
	return nil
end

tern.command({
	id = "copy-card",
	title = "Board: copy card as Markdown",
	icon = "clipboard",
	group = "Board",
	run = function(cx: WindowCx)
		local info = focused_info(cx)
		if info == nil or info.kind ~= "board" then
			cx:toast("warn", "Select a card on a board first")
			return
		end
		local path, title, err = focused_card(cx, info)
		if path == nil then
			cx:toast("error", "Could not read the board", err)
			return
		end
		if title == nil then
			cx:toast("error", "No card is selected")
			return
		end
		cx.docs:read(path):next(function(src: string, _err: any, cx2: WindowCx)
			local block = block_of(src, title)
			if block == nil then
				cx2:toast("error", "Could not find the card in the file", title)
				return
			end
			cx2:copy(block)
			cx2:toast("info", "Copied card", title)
		end)
	end,
})

-- Toggle-style companion: on a Markdown file it opens the board view; anywhere
-- else it falls through to a new browser block. Binding it to a key that Tern
-- already uses keeps that key's default outside Markdown files, because a
-- plugin command cannot hand a key back once it is bound.
tern.command({
	id = "open-as-board",
	title = "Board: open focused Markdown as board",
	icon = "columns",
	group = "Board",
	run = function(cx: WindowCx)
		local info = focused_info(cx)
		local p: string = if info ~= nil and info.path ~= nil then info.path else ""
		if info ~= nil and info.kind ~= "board" and (p:match("%.md$") ~= nil or p:match("%.markdown$") ~= nil) then
			cx:action("open_as_board")
		else
			cx:command("new_browser_block")
		end
	end,
})
