function count__ = saveFS(filename__, variables__, variableNames__)

if length(variables__) ~= length(variableNames__)
  error('Input variables should be consistant in numbers!');
end

saved__ = 0;

for i__=1:length(variables__)
  varName__ = variableNames__{i__};
  eval([varName__,'=','variables__{i__};']);
end

count__ = 0;
while ~saved__

  if exist(filename__,'file')
    disp(['Deleting... ',filename__]);
    delete(filename__);
  end

  try
    for i__=1:length(variables__)
      varName__ = variableNames__{i__};
      if i__==1
        save(filename__,varName__,'-v7.3');
      else
        save(filename__,varName__,'-append','-v7.3');
      end
    end
    load(filename__);
    saved__ = 1;
  catch ME
    disp(ME.message);
    saved__ = 0;
    pause(randi(20));
  end
  count__ = count__ + 1;
end

if count__ >= 2
  disp(['Fucking disk, takes ',int2str(count__),' times to save!']);
end
