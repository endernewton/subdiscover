function model = eldaLearnDataset(pos, neg, name, bg_file_name, fname, options)
% model = learn_dataset(pos, neg, name)
% pos is a struct array for the positive patches, with fields:
%	im: full path to the image
%	x1: xmin
%	y1: ymin
%	x2: xmax
%	(note: If you just have image patches, instead of bounding boxes, consider using learn.m directly)
% neg is a struct array for the negative patches with field:
%	im: full path to the image
% neg is used only when the background statistics cannot be found. If the background statistics are stored in the file location specified in
% bg_file_name, neg can be left empty ( [] ).
% name is just a "name" for the model.

% Load background statistics if they exist; else build them

if nargin < 6
    options = [];
end

skew = 4;
if isfield(options,'eldaSkew')
    skew = options.eldaSkew;
end

% file = bg_file_name;
try
    load(bg_file_name);
catch ME
    disp(ME.message);
%     all = rmfield(pos,{'x1','y1','x2','y2'});
%     all = [all neg];
%     bg  = eldaTrainBG(all,20,5,8);
    bg = eldaTrainBG(neg,20,5,8);
    save(bg_file_name,'bg');
end
% bg

% Define model structure
model = eldaInitModel(pos,bg,fname);
%skip models if the HOG window is too skewed
if(max(model.maxsize)< skew *min(model.maxsize))
    
    %get image patches
    warped=eldaWarpPos(model,pos);
    
    %flip if necessary
    if(isfield(pos, 'flipped'))
        fprintf('Warning: contains flipped images. Flipping\n');
        for k=1:numel(warped)
            if(pos(k).flipped)
                warped{k}=warped{k}(:,end:-1:1,:);
            end
        end
    end
    
    % Learn by linear discriminant analysis
    model = eldaLearn(model,warped,bg_file_name,fname);
end

normw = norm(model.w(:))+eps;
model.w=model.w./normw;
model.nthresh = model.nthresh./normw;
fprintf('Model Thresh: %.2f\n',model.nthresh);
model.thresh = 0.5;
model.bg=[];
model.name=name;

end

