function s = procid()
% Returns a string identifying the process.

d = pwd();
i = strfind(d, '/');
s = d(i(end)+1:end);

end