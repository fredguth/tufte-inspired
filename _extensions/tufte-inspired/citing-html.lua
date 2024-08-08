function Cite(cite)
  local citation = cite.citations[1]
  local suffix = citation.suffix and pandoc.utils.stringify(citation.suffix) or "none"
  -- takes something like (2001, 30, dy.–3.5cm)  into (2001, 30)
  citation.suffix = suffix:gsub("%S*dy%.[^,%)]*,?%s*", ""):gsub(",%s*$", ""):gsub("^%s*(.-)%s*$", "%1")             
  cite.citations[1] = citation
  return cite
end

