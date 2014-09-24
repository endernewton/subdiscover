function features = getFeature( classpath , options )
% Get Features, ensure sparsity
% by Ender, xinleic@cs.cmu.edu

if nargin < 2
    options = [];
end

features = cell(length(classpath),1);
for i=1:length(classpath)
    try
        if options.bMore == 0
            clear mainFea
            load(classpath{i},'mainFea');
            index = ~any(isnan(mainFea),2);
            mainFea = mainFea(index,:);
            features{i} = sparse(double(mainFea));
        else
            clear mainFea moreFea
            load(classpath{i},'mainFea','moreFea');
            mFea = [mainFea;moreFea];
            index = ~any(isnan(mFea),2);
            mFea = mFea(index,:);
            features{i} = sparse(double(mFea));
        end
        
    catch ME
        disp(ME.message);
        features{i} = [];
    end
end

features = cat(1,features{:});

end