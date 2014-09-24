function feats=featuresWrapper(warped,sbin,fname)
% globals;
switch fname
    case 'HOG'
        feats = features(warped, sbin);
    case 'CHOG'
        %%% late fusion of CN + HOG
        %% Original Code before checking the automatica weighting
        feats1=features(warped,sbin);
        feats2=colorname(warped,sbin);
        feats=cat(3,(feats1(:,:,1:end-1)),(feats2(:,:,1:end)),feats1(:,:,32));
end
