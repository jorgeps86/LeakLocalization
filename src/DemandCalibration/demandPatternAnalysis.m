tic;

%% add epanet toolkit
directory = pwd;
cd ..\
EPAnet_dir = [ pwd '\00-Program\EPANET-Matlab-Toolkit-master'];
addpath(genpath( EPAnet_dir ))
addpath( genpath( directory ) );
cd(directory)

%% Read WDN
wdn = epanet('L-TOWN.inp');

%% get all nodes values
% [NodeElevations, NodeDemandPatternIndex, NodeEmitterCoeff,...
%     NodeInitialQuality, NodeSourceQuality, NodeSourcePatternIndex,...
%     NodeSourceTypeIndex, NodeTypeIndex] = getNodesInfo(wdn);

%% Explorative analysis of pattern names and values
% pattern_nameID = wdn.getNodeDemandPatternNameID;
% pattern_index = wdn.getNodeDemandPatternIndex;
% original_bd = wdn.getNodeBaseDemands;
% % % wdn.getPatternNameID; gives the name of the pattern: P-Residential or P-Commercial
% % % wdn.getPatternIndex; gives the number of the pattern: 1 and 2
% wdn.getNodeDemandCategoriesNumber;

%% get all links values
% [LinkDiameter, LinkLength, LinkRoughnessCoeff, LinkMinorLossCoeff,...
%     LinkInitialStatus, LinkInitialSetting, LinkBulkReactionCoeff,...
%     LinkWallReactionCoeff, NodesConnectingLinksIndex, LinkTypeIndex] = getLinksInfo(wdn);

%% get the nodes and demand for DMA C
% dem_dmaC_train = readtable('2018 SCADA.xlsx','sheet', 'Demands (L_h)');
% dem_dmaC_test = readtable('2019 SCADA.xlsx','sheet', 'Demands (L_h)');
% % p_scada2019 = readtable('2019 SCADA.xlsx','sheet', 'Pressures (m)');
% load('dem_dmaC2018.mat','dem_dmaC_train');
load('dem_dmaC2019.mat','dem_dmaC_test');
% dem_dmaC = dem_dmaC_train;
dem_dmaC = dem_dmaC_test;
nodes_dmaC = dem_dmaC.Properties.VariableNames;
nodes_dmaC(1) = []; % nodes labels as strings
nodes_dmaCnum = regexprep(nodes_dmaC, 'n', '');
nodes_dmaCnum = cell2mat(cellfun(@str2num,nodes_dmaCnum,'un',0));
dem_dmaC = dem_dmaC(:,nodes_dmaC);
% get the number of commercial nodes in DMA C
% nnz(original_bd{1,2}(:,nodes_dmaCnum)) % just an informative step
% nnz(original_bd{1,1}(:,nodes_dmaCnum)) % just an informative step

%% get the new pattern for each node
num_aux = mean(dem_dmaC{:,:},2); 
new_pattern = num_aux / mean(num_aux);

%% get the original pattern matrix
% original_patterns = wdn.getPattern;

%% Use the new_pattern to create a year long of new patterns
setTimeSimulationDuration(wdn, 3600*24*365);
setPatternMatrix(wdn, [new_pattern';new_pattern']);

%% save a new inp file with a new pattern and use it with WNTR
wdn.saveInputFile('L-TownNP.inp');
% For 2018, I get sf = 1.024406442921363
% For 2019, inserting a leak on p257 with A = 0.00011, I get sf = 
% sf = 1.0578819532580832; % 1.9049625916287327; %1.0581017316312038;

%% Use the scaling factor sf from WNTR to get the base demand for each node
% junction names
sf = 1.024406442921363; % division between the mean of the total demand from SCADA and WNTR
junctionNames = [wdn.getNodeJunctionNameID, wdn.getNodeTankNameID, wdn.getNodeReservoirNameID];
idxResid = 1; % 1: residential 2: commercial
% original bd of each junction as function of the consumption pattern
T = cell2table(num2cell(wdn.getNodeBaseDemands{1,idxResid}), 'VariableNames', junctionNames);
% Update base demand
func = @(x) x .* sf;
T = varfun(func,T);
T.Properties.VariableNames = regexprep(T.Properties.VariableNames, 'Fun_', '');
% base demand bd has two vectors because the inp file has two patterns
idxComme = 2;
bd = {T{:,:}, wdn.getNodeBaseDemands{1,idxComme}}; 
setNodeBaseDemands(wdn, bd);

%% Check the changes
new_bd = wdn.getNodeBaseDemands;

%% save a new inp file with a new pattern and new base demand and use it in WNTR
wdn.saveInputFile('L-TownNP_NBD2018.inp');
%%%%%% HERE IS THE END OF THE NEW PATTERN AND NEW BASE DEMAND ANALYSIS %%%%%

%% calculate the total demand for a year
% orig_pattern = wdn.getPattern; % we assume the weekly pattern starts on Monday
% orig_pattern = orig_pattern(idx,:); % resid_pattern for a week
% num_of_weeks = 52; % number of complete weeks in a year
% orig_pattern_year = repmat(orig_pattern, 1, num_of_weeks);
% % add Monday, December 31, 2018
% orig_pattern_year = [orig_pattern_year, orig_pattern(idx,1:height(dem_dmaC) - length(orig_pattern_year))];
% % get the original total demand over a year for each node of DMA C
% sum_pattern = sum(orig_pattern_year); orig_total_dem = zeros(1);
% for i = 1:width(bd_dmaC)
%     orig_total_dem(i) = table2array(bd_dmaC(:, bd_dmaC.Properties.VariableNames{i})) * sum_pattern;
% end
% 
% %% get the new base demand for each node of DMA C
% sum_new_pattern = sum(new_pattern); bd_dmaCnew = zeros(1);
% for i = 1:width(bd_dmaC)
%    bd_dmaCnew(i) = orig_total_dem(i) / sum_new_pattern;
% end
% 
% %% plot original base demand and new base demand
% plot(table2array(bd_dmaC(1,:))); hold on; plot(bd_dmaCnew);hold off % the same
% 
% %% plot original pattern and new pattern for a year
% plot(orig_pattern_year); hold on; plot(new_pattern); hold off



%% PREVIOUS CODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read Network file
%  Read network .INP file
% Indices of non-zero demand nodes
% nzdn = find(wdn.getNodeBaseDemands{1})';
% Indices of terminal nodes
% [tn_indx, ~] = find(sum(wdn.getConnectivityMatrix == 1,2)==1);
% Indices of non zero demand nzd terminal nodes
% tn_nzd = find(WDN.getNodeBaseDemands{1}(tn_indx)>0)';
% Indices of non-zero demand nodes that are not terminal nodes
% nzd_ntn = nzdn(~ismember(nzdn,tn_indx));

%%% more testing %%%% WORK ON THIS PART %%%%%%%%%%%%%%%%%%%%%%%%%
% WDN.getNodeDemandPatternNameID % empty or string w/ demand pattern name
% WDN.getNodeDemandPatternIndex % 0 or 1 for 2019Rainwater
% WDN.getNodePatternIndex % 0 or 1 for 2019Rainwater
% WDN.getPatternNameID % pattern names

% get nodes pattern index and demand
% [~, NodeDemandPatternIndex] = WDN.getNodesInfo;

% wdn.saveInputFile('newNetwork.inp');