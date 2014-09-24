function model = eldaLearnDatasetFixedmodel(pos, neg, name, model, bg_file_name)

% Load background statistics if they exist; else build them
% file = bg_file_name;
try
    load(bg_file_name);
catch ME
    disp(ME.message);
    all = rmfield(pos,{'x1','y1','x2','y2'});
    all = [all neg];
    bg  = eldaTrainBG(all,20,5,8);
    save(bg_file_name,'bg');
end
% bg

% Define model structure
%model = initmodel(name,pos,bg);
model.bg=bg;
%skip models if the HOG window is too skewed
if(max(model.maxsize)<4*min(model.maxsize))
    
    warped=eldaWarpPos(model, pos);
    
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
    model = eldaLearn(model,warped);
end

model.w=model.w./norm(model.w(:));
model.bg=[];
model.thresh = 0.5;
model.name=name;

end

