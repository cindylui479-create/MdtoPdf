-- Lua filter for pandoc: auto-set table column widths
-- Distributes width evenly across columns for better PDF rendering.
-- Compatible with pandoc 2.9.x and 3.x.

function Table(el)
  -- pandoc 2.9.x uses el.widths
  if el.widths then
    local n = #el.widths
    if n > 0 then
      local width = 1.0 / n
      for i = 1, n do
        el.widths[i] = width
      end
    end
    return el
  end

  -- pandoc 3.x uses el.colspecs
  if el.colspecs then
    local n = #el.colspecs
    if n > 0 then
      local width = 1.0 / n
      for i = 1, n do
        el.colspecs[i][2] = width
      end
    end
    return el
  end
end
