% A script that evaluates the segmentation results against human
% foreground-background masks.
%
% Authors:  Michael Rubinstein, MIT,
%           Armand Joulin, INRIA
% Date: Apr 2013
%

clear;
warning off;

dataDir = Project.dataDir;
resultDir = Project.resultDir;

outDir = 'EvaluationResults';
createFigures = 1; % if 1, reproduces figures and tables in the paper
createWebpages = 1; % if 1, creates HTML pages showing/comparing the segmentation results

mkdir(outDir);


%%
% Compare with co-segmentation methods on MSRC and iCoseg

datasets = {'MSRC', 'iCoseg'};
methods = {'Joulin10', 'Joulin12', 'Kim11', 'ObjectDiscovery'};

for i = 1:length(datasets)
    dataset = datasets{i};
    datasetDir = fullfile(dataDir, dataset);
    
    P = []; J = [];
    
    for j = 1:length(methods)
        method = methods{j};
        fprintf('%s - %s\n', dataset, method);
        
        methodResultDir = fullfile(resultDir, dataset, method);
        [P(:,j), J(:,j), classes] = evaluateSegmentationMultiClass(methodResultDir, datasetDir);
    end
    
    save(fullfile(outDir, ['results_' dataset]), 'P', 'J', 'classes', 'methods');
end

% Reproduce figure 4 in the paper
if createFigures
    load(fullfile(outDir, 'results_MSRC'));
    showPerformancePerClass(P, classes, methods, 'Precision');
    export_fig(fullfile(outDir, 'MSRC_precision_per_class.pdf'));
    close(gcf);
    
    load(fullfile(outDir, 'results_iCoseg'));
    showPerformancePerClass(P, classes, methods, 'Precision');
    export_fig(fullfile(outDir, 'iCoseg_precision_per_class.pdf'));
    close(gcf);
end

% Create an HTML page comparing the results on MSRC
if createWebpages
    load(fullfile(outDir, 'results_MSRC'));
    createComparisonWebpageMultiClass('MSRC', methods, fullfile(outDir, 'Comparison_MSRC'));
end



%%
% Compare with Vicente et al. 2011 on the subsets of MSRC and iCoseg in
% their paper

datasets = {'sub_MSRC', 'sub_iCoseg'};
methods = {'Vicente11', 'ObjectDiscovery'};

for i = 1:length(datasets)
    dataset = datasets{i};
    disp(dataset);
    
    datasetDir = fullfile(dataDir, dataset);
    
    P = []; J = [];
    
    for j = 1:length(methods)
        method = methods{j};
        methodResultDir = fullfile(resultDir, dataset, method);
        [P(:,j), J(:,j), classes] = evaluateSegmentationMultiClass(methodResultDir, datasetDir);
    end
    
    save(fullfile(outDir, ['results_' dataset]), 'P', 'J', 'classes', 'methods');
end

% Reproduce table 1 in the paper
if createFigures
    tab = [];
    load(fullfile(outDir, 'results_sub_MSRC'));
    tab(:,1) = mean(P,1);
    tab(:,2) = mean(J,1);
    load(fullfile(outDir, 'results_sub_iCoseg'));
    tab(:,3) = mean(P,1);
    tab(:,4) = mean(J,1);
    
    fid = fopen(fullfile(outDir, 'results_sub_MSRC.csv'), 'wt');
    fprintf(fid, 'Method,MSRC \\bar{P},MSRC \\bar{J},iCoseg \\bar{P},iCoseg \\bar{J}\n');
    for i = 1:length(methods)
        fprintf(fid, '%s,%.2f,%.2f,%.2f,%.2f\n', methods{i}, tab(i,:)*100);
    end
    fclose(fid);
end

% Create an HTML page comparing the results on iCoseg
if createWebpages
    load(fullfile(outDir, 'results_sub_iCoseg'));
    createComparisonWebpageMultiClass('sub_iCoseg', methods, fullfile(outDir, 'Comparison_Vicente_iCoseg'));
end


%%
% Compare with co-segmentation methods on the Internet 100 datasets

datasets = {'Car100', 'Horse100', 'Airplane100'};
methods = {'Baseline1', 'Baseline2', 'Joulin10', 'Joulin12', 'Kim11', 'ObjectDiscovery'};

for i = 1:length(datasets)
    dataset = datasets{i};
    datasetDir = fullfile(dataDir, dataset);
    
    P = []; J = [];
    
    for j = 1:length(methods)
        method = methods{j};
        fprintf('%s - %s\n', dataset, method);
        
        if strcmp(method, 'Baseline1')
            [P(:,j), J(:,j)] = evaluateSegmentationBaseline(fullfile(datasetDir, 'GroundTruth'), 1);
        elseif strcmp(method, 'Baseline2')
            [P(:,j), J(:,j)] = evaluateSegmentationBaseline(fullfile(datasetDir, 'GroundTruth'), 2);
        else
            methodResultDir = fullfile(resultDir, dataset, method);
            [P(:,j), J(:,j)] = evaluateSegmentation(methodResultDir, fullfile(datasetDir, 'GroundTruth'));
        end
    end
    
    save(fullfile(outDir, ['results_' dataset]), 'P', 'J', 'methods');
end

% Reproduce table 3 in the paper
if createFigures
    tab = [];
    load(fullfile(outDir, 'results_Car100'));
    tab(:,1) = P;
    tab(:,2) = J;
    load(fullfile(outDir, 'results_Horse100'));
    tab(:,3) = P;
    tab(:,4) = J;
    load(fullfile(outDir, 'results_Airplane100'));
    tab(:,5) = P;
    tab(:,6) = J;
    
    fid = fopen(fullfile(outDir, 'results_Internet100.csv'), 'wt');
    fprintf(fid, 'Method,Car P,Car J,Horse P,Horse J,Airplane P,Airplane J\n');
    for i = 1:length(methods)
        fprintf(fid, '%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n', methods{i}, tab(i,:)*100);
    end
    fclose(fid);
end

% Create an HTML page comparing the results on Car100
if createWebpages
    load(fullfile(outDir, 'results_car100'));
    createComparisonWebpage('Car100', methods, fullfile(outDir, 'Comparison_Car'));
end


%%
% Evaluate results on the full Internet datasets (against the images we
% have labeled)

datasets = {'Car', 'Horse', 'Airplane'};
methods = {'ObjectDiscovery'};

for i = 1:length(datasets)
    dataset = datasets{i};
    datasetDir = fullfile(dataDir, dataset);
    
    P = []; J = [];
    
    for j = 1:length(methods)
        method = methods{j};
        fprintf('%s - %s\n', dataset, method);
        
        methodResultDir = fullfile(resultDir, dataset, method);
        [P(:,j), J(:,j)] = evaluateSegmentation(methodResultDir, fullfile(datasetDir, 'GroundTruth'));
    end
    
    save(fullfile(outDir, ['results_' dataset]), 'P', 'J', 'methods');
end

% Reproduce table 2 in the paper
if createFigures
    tab = [];
    load(fullfile(outDir, 'results_Car'));
    tab(:,1) = P;
    tab(:,2) = J;
    load(fullfile(outDir, 'results_Horse'));
    tab(:,3) = P;
    tab(:,4) = J;
    load(fullfile(outDir, 'results_Airplane'));
    tab(:,5) = P;
    tab(:,6) = J;
    
    fid = fopen(fullfile(outDir, 'results_Internet.csv'), 'wt');
    fprintf(fid, 'Method,Car P,Car J,Horse P,Horse J,Airplane P,Airplane J\n');
    for i = 1:length(methods)
        fprintf(fid, '%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n', methods{i}, tab(i,:)*100);
    end
    fclose(fid);
end


