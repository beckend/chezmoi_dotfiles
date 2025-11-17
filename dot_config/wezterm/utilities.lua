function object_assign(tbl, props)
  for k, v in pairs(props) do
    tbl[k] = v
  end
end

return {
  object_assign = object_assign,
}
