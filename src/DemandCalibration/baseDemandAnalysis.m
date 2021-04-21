tic;

%% add epanet toolkit
directory = pwd;
cd ..\
EPAnet_dir = [ pwd '\00-Program\EPANET-Matlab-Toolkit-master'];
addpath(genpath( EPAnet_dir ))
addpath( genpath( directory ) );
cd(directory)

%% Read WDN
wdn = epanet('L-TOWN_NP.inp');

%% Use the scaling factor sf from WNTR to get the base demand for each node
% sf: division between the mean of the total demand from SCADA and WNTR
sf = 1.024406442921363;
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
wdn.saveInputFile('L-TownNP_NBD.inp');