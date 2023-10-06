function A = normalizeFromRange(A,normRange)
    A = (A - normRange(1))./(normRange(2)-normRange(1));
end