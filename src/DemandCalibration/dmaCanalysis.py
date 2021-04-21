import wntr
import pandas as pd
import pprint
import matplotlib.pyplot as plt
import pickle
import time

def readExcelPressureWritePickle():
    filename = '2019 SCADA.xlsx'
    df = pd.read_excel(filename, sheet_name='Pressures (m)')
    df.to_pickle('scadaPressureTest')

def retrieveScada(df):
    scada_demandDmaC = df.drop(['Timestamp'], axis=1).div(1000) # m3/h
    return scada_demandDmaC
    
def runHydraulics(inp_file, nDays):
    wn = wntr.network.WaterNetworkModel(inp_file)
    wn.options.time.duration = nDays * 24 * 60 * 60
    # Run hydraulics analysis with a leak at the start node of pipe_id
    sim = wntr.sim.WNTRSimulator(wn, mode = 'PDD')
    # sim = wntr.sim.EpanetSimulator(wn)
    results = sim.run_sim()
    with open('yearRun2019', 'wb') as f:
        pickle.dump([results,wn], f)

def load_wn():
    with open('yearRun2019', 'rb') as f:
        [results, wn] = pickle.load(f)   
    return results, wn
    
def load_wn_orig():
    with open('yearRun', 'rb') as f:
        [results, wn] = pickle.load(f)   
    return results, wn

def retrieveWntr(df):
    results, wn = load_wn()
    nodesDmaC = df.drop(['Timestamp'], axis=1).columns.tolist()
    # Get the demand of all nodes
    wntr_demand = results.node['demand']
    # get the actual demand of the nodes in DMA C at all time steps
    demandDmaC = wntr_demand.loc[:, nodesDmaC].mul(3600) # m3/h a year
    wntr_demandDmaC = demandDmaC.reset_index(drop=True)
    return wntr_demandDmaC

def retrieveWntrOriginal(df):
    results,_ = load_wn_orig()
    nodesDmaC = df.drop(['Timestamp'], axis=1).columns.tolist()
    # Get the pressure of all nodes
    wntr_demand = results.node['demand']
    # get the actual demand of the nodes in DMA C at all time steps
    demandDmaC = wntr_demand.loc[:, nodesDmaC].mul(3600) # m3/h a year
    wntr_demandDmaC = demandDmaC.reset_index(drop=True)
    return wntr_demandDmaC

def main():
    df = pd.read_pickle('scadaTest')
    runHydraulics('L-Town_newPattern_newBd.inp', nDays=365)
    # N = 12*24 # number of daily timestamps
    dfScada = retrieveScada(df)
    dfWntr = retrieveWntr(df)
    # dfWntrOrig = retrieveWntrOriginal(df)
    # # # delete the last row of dfWntr
    dfWntr.drop(dfWntr.tail(1).index,inplace=True) # drop last row
    # dfWntrOrig.drop(dfWntrOrig.tail(1).index,inplace=True)
    # # calculate the scaling factor between SCADA and WNTR
    scale_factor = dfScada.mean() / dfWntr.mean()
    print('Use this scale factor in MATLAB', scale_factor.mean())
    # print(scale_factor.mean()) # 1.024406442921363
    # plotDailyDem(N, dfScada, dfWntr, dfWntrOrig)

if __name__ == "__main__":
    main()