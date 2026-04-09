-- Lua filter for pandoc: auto-set table column widths + strip horizontal rules
-- v1.0.1: Use 0.94 total width (prevents margin overflow); apply proportional
--         widths so wider tables don't spill into margins; compatible with
--         pandoc 2.9.x and 3.x.
-- v1.0.2: Strip HorizontalRule elements (--- in Markdown) from body text.

function HorizontalRule()
  return {}
end

-- Total usable fraction of the text width (leave ~6% for column separators
-- and margins to prevent cell content from overflowing into the page margin).
local TOTAL_WIDTH = 0.94

function Table(el)
  -- pandoc 3.x uses el.colspecs: list of {Alignment, ColWidth}
  if el.colspecs then
    local n = #el.colspecs
    if n > 0 then
      local width = TOTAL_WIDTH / n
      for i = 1, n do
        el.colspecs[i][2] = width
        -- AlignDefault lets LaTeX use \raggedright inside p{} columns,
        -- which allows long words and URLs to break across lines.
        el.colspecs[i][1] = pandoc.AlignDefault
      end
    end
    return el
  end

  -- pandoc 2.9.x uses el.widths (plain list of floats)
  if el.widths then
    local n = #el.widths
    if n > 0 then
      local width = TOTAL_WIDTH / n
      for i = 1, n do
        el.widths[i] = width
      end
    end
    return el
  end
end
