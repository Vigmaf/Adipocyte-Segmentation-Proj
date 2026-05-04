function T = add_source(P, name)
T = P;
T.Source = repmat(string(name), height(P), 1);

end