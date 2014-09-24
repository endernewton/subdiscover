function Feature_opts=lsvmFeature(featurename)

switch featurename
    case 'HOG'
        %% ORIGINAL HOG
        Feature_opts.name='HOG';  %%%%% Coice of Features, Options are: 'HOG', 'ColorName_HOG'
        Feature_opts.sbin=8;     %%%%% CelL size (i.e. 8*8 cell to compute a feature)
        Feature_opts.dim=32;   %%%%% Number of Feature bins in a block (i.e in case of HOG its 8*4=32 feat dim vector per block)
        Feature_opts.flag=0;
        Feature_opts.truncation_dim=32;
        Feature_opts.extra_octave=false;
        Feature_opts.bias_feature=10;
    case 'CHOG'
        %% Color Name + HOG
        Feature_opts.name='CHOG';  %%%%% Coice of Features, Options are: 'HOG', ' ColorName_HOG'
        Feature_opts.sbin=8;     %%%%% CelL size (i.e. 8*8 cell to compute a feature)
        Feature_opts.dim=43;   %%%%% Number of Feature bins in a block (i.e in case of CNHOG its 8*4=32+11 feat dim vector per block)
        Feature_opts.flag=1;
        Feature_opts.truncation_dim=43;
        Feature_opts.extra_octave=false;
        Feature_opts.bias_feature=10;
end

end
