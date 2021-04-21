#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr  8 07:32:13 2020

@author: mkhaksa
"""

#%%
import os
import wntr
import time
import pickle
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


#%% loading functions
def load_base_wn():
    with open('temp_result/first21days', 'rb') as f:
        _, _, _, _, wn = pickle.load(f)  
    return(wn)
        
def load_result(file_name):
    with open('temp_result/'+ file_name, 'rb') as f:
        P, F, D, T, wn = pickle.load(f) 
    return(P, F, D, T, wn)

def load_nodal_results(file_name):
    with open('temp_result/'+ file_name, 'rb') as f:
        P, F, D, T, _ = pickle.load(f) 
    return(P[P_list], F[F_list], D[D_list], T[T_list])

P_list = ['n332', 'n105', 'n229', 'n516', 'n519', 'n4', 'n722', 'n415', 'n1', 'n495', 'n740', 'n31', 'n188', 'n644', 'n679', 'n769', 'n114', 'n613', 'n215', 'n752', 'n458', 'n296', 'n726', 'n429', 'n288', 'n506', 'n636', 'n54', 'n410', 'n342', 'n163', 'n469', 'n549']
F_list = ['p227', 'p235', 'PUMP_1']
D_list = ['n22', 'n371', 'n385', 'n39', 'n382', 'n386', 'n16', 'n4', 'n3', 'n389', 'n40', 'n31', 'n353', 'n347', 'n349', 'n379', 'n377', 'n387', 'n375', 'n25', 'n351', 'n376', 'n362', 'n43', 'n6', 'n366', 'n2', 'n35', 'n1', 'n354', 'n19', 'n34', 'n8', 'n17', 'n357', 'n9', 'n24', 'n345', 'n344', 'n370', 'n18', 'n352', 'n26', 'n364', 'n11', 'n27', 'n28', 'n372', 'n368', 'n23', 'n355', 'n42', 'n32', 'n378', 'n346', 'n44', 'n45', 'n356', 'n361', 'n33', 'n13', 'n343', 'n365', 'n388', 'n7', 'n36', 'n29', 'n358', 'n30', 'n383', 'n10', 'n360', 'n20', 'n374', 'n350', 'n381', 'n384', 'n373', 'n21', 'n369', 'n367', 'n41']
T_list = ['T1']

#%% create matrix 
#lead nodes : p232, p673, p461, p628, p538,p866, p31,  p183, p158, p369,
base_P, base_F, base_D, base_T = load_nodal_results('no_leak')
#pipe_nme = 'p31'
leak_ind =  base_P.index.values <= 27 * 86400


#P, F, D, T = load_nodal_results(pipe_nme)
#leak_P = (P.subtract(base_P)/base_P).iloc[leak_ind,:]
#affect_P = np.sum(leak_P).to_frame()
#affect_P.columns = [pipe_nme]

st_tme = time.time()
wn = load_base_wn()
count = 0 
for pipe_nme, pipe in wn.pipes():
    P, F, D, T = load_nodal_results(pipe_nme)
    leak_P = (P.subtract(base_P)/base_P).iloc[leak_ind,:]
    leak_F = (F.subtract(base_F)/base_F).iloc[leak_ind,:]
    leak_T = (T.subtract(base_T)/base_T).iloc[leak_ind,:]
    if count == 0:
        affect_P = np.sum(leak_P).to_frame()
        affect_F = np.sum(leak_F).to_frame()
        affect_T = np.sum(leak_T).to_frame()
        affect_P.columns = [pipe_nme]
        affect_F.columns = [pipe_nme]
        affect_T.columns = [pipe_nme]
    else:
        affect_P[pipe_nme] = np.sum(leak_P).to_frame()
        affect_F[pipe_nme] = np.sum(leak_F).to_frame()
        affect_T[pipe_nme] = np.sum(leak_T).to_frame()
    count = count + 1
#    print(f'{count}st pipe: {pipe_nme}\n')

affect_P.to_excel('affect_P_6days.xlsx')
affect_F.to_excel('affect_F_6days.xlsx')
affect_T.to_excel('affect_T_6days.xlsx')
end_tme = time.time()
print(f'end time is {end_tme - st_tme}')

#%%

wn = load_base_wn()
#Start the data generation
base_P, base_F, base_D, base_T, base_wn = load_result('no_leak')
count = 0 
for pipe_nme, pipe in wn.pipes():
    if not os.path.exists('temp_result/'+pipe_nme):
        count = count + 1
        s_tme = time.time()
        simulate_nthdays(pipe_name=pipe_nme)
        f_tme = time.time()
        print(f'{count}st pipe: {pipe_nme}\n run-time was:{f_tme-s_tme} ')

#s_tme = time.time()
#pipe_nme = 'p283'   
#simulate_nthdays(pipe_name = pipe_nme, surf_area=0)    
#f_tme = time.time()
#print(f_tme-s_tme)
#
#    

