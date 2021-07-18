-- I did not author this script!
Span = function(span)
  color = span.attributes['color']
  -- if no color attribute, return unchange
  if color == nil then return span end
  
  -- tranform to <span style="color: red;"></span>
  if FORMAT:match 'html' then
    -- remove color attributes
    span.attributes['color'] = nil
    -- use style attribute instead
    span.attributes['style'] = 'color: ' .. color .. ';'
    -- return full span element
    return span
  elseif FORMAT:match 'latex' then
    -- remove color attributes
    span.attributes['color'] = nil
    -- encapsulate in latex code
    table.insert(
      span.content, 1,
      pandoc.RawInline('latex', '\\textcolor{'..color..'}{')
    )
    table.insert(
      span.content,
      pandoc.RawInline('latex', '}')
    )
    -- returns only span content
    return span.content
  else
    -- for other format return unchanged
    return span
  end
end