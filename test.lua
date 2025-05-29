local M = {
    q = { 1, 2, 3, 4 }
}

M.w = M.q

M.w[1] = 27

for i, v in ipairs(M.q) do
    print(v)
end
