-- Cover, clickable page ranges, and matching section end bookmarks.
local function tex(s)
  return s:gsub('([%%&#_$])', '\\%1')
end
local function xml(s)
  return s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;')
end
local function word_key(id)
  return id:gsub('[^%w_]', '_')
end
local function wp(text, style, align, before, after)
  return '<w:p><w:pPr><w:pStyle w:val="' .. style .. '"/><w:jc w:val="' .. align ..
    '"/><w:spacing w:before="' .. before .. '" w:after="' .. after ..
    '"/></w:pPr><w:r><w:t xml:space="preserve">' .. xml(text) .. '</w:t></w:r></w:p>'
end
local function cover_wp(text, style, size, line, before, indent, bold, italic)
  return '<w:p><w:pPr><w:pStyle w:val="' .. style .. '"/>' ..
    '<w:jc w:val="' .. (indent > 0 and 'left' or 'center') .. '"/>' ..
    '<w:ind w:left="' .. indent .. '" w:firstLine="0"/>' ..
    '<w:keepNext w:val="0"/><w:keepLines/><w:widowControl w:val="0"/><w:contextualSpacing w:val="0"/>' ..
    '<w:spacing w:before="' .. before .. '" w:after="0" w:line="' .. line .. '" w:lineRule="exact"/>' ..
    '</w:pPr><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>' ..
    '<w:sz w:val="' .. size*2 .. '"/><w:szCs w:val="' .. size*2 .. '"/>' ..
    '<w:b w:val="' .. (bold and '1' or '0') .. '"/><w:i w:val="' .. (italic and '1' or '0') .. '"/>' ..
    '<w:color w:val="000000"/></w:rPr><w:t xml:space="preserve">' .. xml(text) .. '</w:t></w:r></w:p>'
end
function Pandoc(doc)
  -- GitHub needs explicit anchors; print formats must not retain empty paragraphs.
  doc = doc:walk({Para = function(p)
    if #p.content == 0 then return nil end
    for _, inline in ipairs(p.content) do
      if inline.t ~= 'RawInline' or inline.format ~= 'html' or
          not inline.text:match('^</?a[%s>]') then return nil end
    end
    return {}
  end})
  local subject = pandoc.utils.stringify(doc.meta.title or '')
  local report_title = pandoc.utils.stringify(doc.meta.subtitle or '')
  local report_type = pandoc.utils.stringify(doc.meta['report-type'] or '')
  local group = pandoc.utils.stringify(doc.meta.group or '')
  local date = pandoc.utils.stringify(doc.meta.date or '')
  local function meta(key, default)
    return pandoc.utils.stringify(doc.meta[key] or default or '')
  end
  local university = meta('university')
  local faculty = meta('faculty')
  local department = meta('department')
  local laboratory = meta('laboratory-number')
  local cover_line1 = meta('cover-title-line1', subject)
  local cover_line2 = meta('cover-title-line2')
  local city = meta('city', 'Москва')
  local year = meta('year', '2026')
  local authors = {}
  for _, name in ipairs(doc.meta.author or {}) do authors[#authors+1] = pandoc.utils.stringify(name) end
  local entries = {}
  local chapter, sub = 0, 0
  for _, b in ipairs(doc.blocks) do
    if b.t == 'Header' and b.level <= 2 then
      local title = pandoc.utils.stringify(b.content)
      local number = ''
      if not b.classes:includes('unnumbered') then
        if b.level == 1 then chapter, sub = chapter + 1, 0; number = tostring(chapter)
        else sub = sub + 1; number = tostring(chapter) .. '.' .. tostring(sub) end
      end
      entries[#entries+1] = {id=b.identifier, title=title, level=b.level,
        label=(number ~= '' and number .. ' ' or '') .. title}
    end
  end
  local blocks = pandoc.List()
  if FORMAT:match('latex') then
    local names = {}
    for _, name in ipairs(authors) do names[#names+1] = tex(name) .. '\\par' end
    local cover = '\\newcommand{\\ReportTitle}{' .. tex(report_title) .. '}' ..
      '\\newcommand{\\ReportSubject}{' .. tex(subject) .. '}' ..
      '\\newcommand{\\ReportType}{' .. tex(report_type) .. '}' ..
      '\\newcommand{\\ReportAuthors}{' .. table.concat(names, '\n') .. '}' ..
      '\\newcommand{\\ReportGroup}{' .. tex(group) .. '}' ..
      '\\newcommand{\\ReportDate}{' .. tex(date) .. '}' ..
      '\\newcommand{\\ReportUniversity}{' .. tex(university) .. '}' ..
      '\\newcommand{\\ReportFaculty}{' .. tex(faculty) .. '}' ..
      '\\newcommand{\\ReportDepartment}{' .. tex(department) .. '}' ..
      '\\newcommand{\\ReportLabNumber}{' .. tex(laboratory) .. '}' ..
      '\\newcommand{\\ReportCoverLineOne}{' .. tex(cover_line1) .. '}' ..
      '\\newcommand{\\ReportCoverLineTwo}{' .. tex(cover_line2) .. '}' ..
      '\\newcommand{\\ReportCity}{' .. tex(city) .. '}' ..
      '\\newcommand{\\ReportYear}{' .. tex(year) .. '}' ..
      '\\hypersetup{pdftitle={' .. tex(subject) .. '},pdfauthor={' .. tex(table.concat(authors, '; ')) .. '}}' ..
      '\\input{pandoc/title.tex}'
    blocks:insert(pandoc.RawBlock('latex', cover))
    local toc = {'\\section*{Содержание}\\pdfbookmark[0]{Содержание}{contents}\\begingroup\\small\\setlength{\\parskip}{4pt}'}
    for _, e in ipairs(entries) do
      local indent = e.level == 2 and '\\hspace*{.7cm}' or ''
      local label = e.level == 1 and '\\textbf{' .. tex(e.label) .. '}' or tex(e.label)
      toc[#toc+1] = '\\noindent' .. indent .. '\\hyperref[' .. e.id .. ']{' .. label ..
        '\\nobreak\\dotfill\\mbox{\\pageref*{' .. e.id .. '}--\\pageref*{end:' .. e.id .. '}}}\\par'
    end
    toc[#toc+1] = '\\endgroup\\clearpage'
    blocks:insert(pandoc.RawBlock('latex', table.concat(toc, '\n')))
  elseif FORMAT == 'docx' then
    local cover = {}
    cover[#cover+1] = cover_wp(university, 'CoverInstitution', 14, 480, 0, 0, true, false)
    cover[#cover+1] = cover_wp(faculty, 'CoverFaculty', 14, 480, 0, 0, false, false)
    cover[#cover+1] = cover_wp(department, 'CoverDepartment', 14, 480, 0, 0, false, false)
    cover[#cover+1] = cover_wp('ОТЧЕТ', 'Title', 26, 640, 2032, 0, true, false)
    cover[#cover+1] = cover_wp('ПО ЛАБОРАТОРНОЙ РАБОТЕ № ' .. laboratory, 'Normal', 14, 400, 437, 0, true, false)
    cover[#cover+1] = cover_wp(cover_line1, 'Subtitle', 26, 660, 621, 0, true, false)
    cover[#cover+1] = cover_wp(cover_line2, 'Subtitle', 26, 660, 0, 0, true, false)
    cover[#cover+1] = cover_wp(report_type, 'Subtitle', 16, 440, 494, 0, false, true)
    cover[#cover+1] = cover_wp('Выполнили', 'Normal', 14, 400, 1828, 4365, true, false)
    for i, name in ipairs(authors) do
      cover[#cover+1] = cover_wp(name, 'Normal', 14, 400, i == 1 and 167 or 0, 4365, false, false)
    end
    cover[#cover+1] = cover_wp('Группа ' .. group, 'Normal', 14, 400, 205, 4365, false, false)
    cover[#cover+1] = cover_wp('Дата выполнения', 'Normal', 14, 400, 337, 4365, false, false)
    cover[#cover+1] = cover_wp(date, 'Normal', 14, 400, 0, 4365, false, false)
    cover[#cover+1] = cover_wp(city, 'CoverCity', 14, 400, 0, 0, false, false)
    cover[#cover+1] = cover_wp(year, 'CoverYear', 14, 400, 0, 0, false, false)
    cover[#cover+1] = '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
    cover[#cover+1] = wp('Содержание', 'TOCHeading', 'left', 0, 240)
    for _, e in ipairs(entries) do
      local key = word_key(e.id)
      local style = e.level == 2 and 'TOC2' or 'TOC1'
      cover[#cover+1] = '<w:p><w:pPr><w:pStyle w:val="' .. style ..
        '"/><w:tabs><w:tab w:val="right" w:leader="dot" w:pos="9354"/></w:tabs></w:pPr>' ..
        '<w:hyperlink w:anchor="start_' .. key .. '"><w:r><w:t>' .. xml(e.label) ..
        '</w:t></w:r><w:r><w:tab/></w:r><w:r><w:t>0–0</w:t></w:r></w:hyperlink></w:p>'
    end
    cover[#cover+1] = '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
    blocks:insert(pandoc.RawBlock('openxml', table.concat(cover, '\n')))
  end
  local stack = {}
  for _, b in ipairs(doc.blocks) do
    if b.t == 'Header' and b.level <= 2 and FORMAT:match('latex') then
      while #stack > 0 and stack[#stack].level >= b.level do
        local e = table.remove(stack)
        blocks:insert(pandoc.RawBlock('latex', '\\label{end:' .. e.id .. '}'))
      end
      if b.identifier == 'timeline' or (b.level == 1 and (b.identifier == 'detection' or b.identifier == 'wordpress' or
          b.identifier == 'ad' or b.identifier == 'exchange' or b.identifier == 'results' or b.identifier == 'conclusion' or b.classes:includes('unnumbered'))) then
        blocks:insert(pandoc.RawBlock('latex', '\\clearpage'))
      end
      if b.classes:includes('unnumbered') then
        blocks:insert(pandoc.RawBlock('latex', '\\phantomsection'))
      end
      stack[#stack+1] = {id=b.identifier, level=b.level}
    end
    blocks:insert(b)
  end
  while #stack > 0 do
    local e = table.remove(stack)
    blocks:insert(pandoc.RawBlock('latex', '\\label{end:' .. e.id .. '}'))
  end
  doc.meta.title, doc.meta.subtitle, doc.meta.author, doc.meta.date = nil, nil, nil, nil
  doc.blocks = blocks
  return doc
end
