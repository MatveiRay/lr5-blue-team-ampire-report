-- Render PDF tables with repeated dark headers and visible cell borders.
local table_index = 0
local function latex(blocks)
  return pandoc.write(pandoc.Pandoc(blocks), 'latex'):gsub('%s+$', '')
end
local function row_text(row, header)
  local cells = {}
  for _, cell in ipairs(row.cells) do
    local value = latex(cell.contents)
    cells[#cells+1] = header and '{\\color{white}\\bfseries ' .. value .. '}' or value
  end
  return table.concat(cells, ' & ') .. ' \\\\ \\hline'
end
function Table(t)
  if not FORMAT:match('latex') then return nil end
  -- Pandoc may probe the PDF writer with a small internal table.
  if not t.identifier:match('^tbl:') then return nil end
  table_index = table_index + 1
  local count = #t.colspecs
  local widths
  assert(count == 3, 'Unexpected report table structure: ' .. count .. ' columns')
  if table_index == 1 then widths = {.220, .189, .591}
  elseif table_index == 2 then widths = {.171, .329, .500}
  else widths = {.189, .390, .421} end
  local spec = '|'
  for _, width in ipairs(widths) do
    spec = spec .. '>{\\RaggedRight\\arraybackslash}p{' .. width .. '\\reporttablewidth}|'
  end
  local code = {'\\begingroup\\small\\arrayrulecolor{ReportBorder}\\setlength{\\tabcolsep}{5pt}',
    '\\setlength{\\reporttablewidth}{\\dimexpr\\linewidth-' .. (2*count) .. '\\tabcolsep-' .. (count+1) .. '\\arrayrulewidth\\relax}',
    '\\begin{longtable}{' .. spec .. '}',
    '\\caption{' .. latex(t.caption.long) .. '}\\label{' .. t.identifier .. '}\\\\', '\\hline'}
  for _, row in ipairs(t.head.rows) do
    code[#code+1] = '\\rowcolor{ReportHeader}' .. row_text(row, true)
  end
  code[#code+1] = '\\endfirsthead\\hline'
  for _, row in ipairs(t.head.rows) do
    code[#code+1] = '\\rowcolor{ReportHeader}' .. row_text(row, true)
  end
  code[#code+1] = '\\endhead'
  local row_index = 0
  for _, body in ipairs(t.bodies) do
    for _, row in ipairs(body.body) do
      row_index = row_index + 1
      code[#code+1] = (row_index % 2 == 1 and '\\rowcolor{ReportTint}' or '\\rowcolor{white}') .. row_text(row, false)
    end
  end
  code[#code+1] = '\\end{longtable}\\endgroup'
  return pandoc.RawBlock('latex', table.concat(code, '\n'))
end
