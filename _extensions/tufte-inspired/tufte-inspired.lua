function Cite(cite)
    local citation = cite.citations[1]
    
    -- Deconstruct the citation object
    local key = citation.id
    local mode = citation.mode or "NormalCitation"
    local prefix = citation.prefix and pandoc.utils.stringify(citation.prefix) or "none"
    local suffix = citation.suffix and pandoc.utils.stringify(citation.suffix) or "none"
    local locator = citation.locator or "none"
    local label = citation.label or "none"

    -- Create a Typst function call with deconstructed parts
    local typst_call = string.format(
        '#margincite(<%s>, "%s", "%s", "%s", %s, %s)',
        key, mode, prefix, suffix, locator, label
    )

    return pandoc.Inlines({
        pandoc.RawInline('typst', typst_call)
    })
end


-- -- inspired by: https://github.com/quarto-ext/typst-templates  ams/_extensions/ams/ams.lua
local function endTypstBlock(blocks)
    local lastBlock = blocks[#blocks]
    if lastBlock.t == "Para" or lastBlock.t == "Plain" then
      lastBlock.content:insert(pandoc.RawInline('typst', '\n]'))
      return blocks
    else
      blocks:insert(pandoc.RawBlock('typst', ']\n'))
      return blocks
    end
  end
  
function Div(el)
  -- ::{.column-margin}
    if el.classes:includes('column-margin') then
      local dx = el.attributes.dx or "0em"
      local dy = el.attributes.dy or "-2em"
      local blocks = pandoc.List({
          pandoc.RawBlock('typst', string.format('#margin-note(dx:%s, dy:%s)[#set par(first-line-indent: 0em)', dx, dy))
      })
      blocks:extend(el.content)
      return endTypstBlock(blocks)
    end
  -- ::{.fullwidth}
    if el.classes:includes('fullwidth') then
      local width = "100%+3.5in-0.75in"
      local blocks = pandoc.List({
          pandoc.RawBlock('typst', string.format('#block(width: %s)[', width))
      })
      blocks:extend(el.content)
      return endTypstBlock(blocks)
    end
  end

  