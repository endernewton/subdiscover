function dirs = getDirectories(path)

dirs = dir(path);
dirs([dirs.isdir] == 0) = [];
dirs(cellfun(@(x) x(1)=='.', {dirs.name})) = []; % remove '.' and '..'

% prepend path
% if ~isempty(dirs)
%     dirs = cellfun(@(x) fullfile(path,x), dirs, 'UniformOutput',false);
% end
