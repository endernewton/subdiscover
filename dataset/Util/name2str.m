function str = name2str(method)

for i = 1:length(method)
   str{i} = strrep(method{i},'_','\_');
end
