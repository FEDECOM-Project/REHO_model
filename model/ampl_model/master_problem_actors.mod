set Actors default {"Owner", "Lodger", "Utility"};
set ActorObjective;

# energy tariffs
var Cost_supply_district{l in ResourceBalances, f in FeasibleSolutions, h in House};
var Cost_demand_district{l in ResourceBalances, f in FeasibleSolutions, h in House};
var Cost_self_consumption{f in FeasibleSolutions, h in House};

subject to size_cstr1{l in ResourceBalances, f in FeasibleSolutions, h in House}:            
   Cost_demand_cst[l] *lambda[f,h] <= Cost_supply_district[l,f,h];

subject to size_cstr2{l in ResourceBalances, f in FeasibleSolutions, h in House}:            
   Cost_supply_district[l,f,h] <= Cost_supply_cst[l] *lambda[f,h];

subject to size_cstr3{l in ResourceBalances, f in FeasibleSolutions, h in House}:            
   Cost_demand_cst[l] *lambda[f,h] <= Cost_demand_district[l,f,h];

subject to size_cstr4{l in ResourceBalances, f in FeasibleSolutions, h in House}:           
   Cost_demand_district[l,f,h] <= Cost_supply_cst[l] *lambda[f,h];

subject to size_cstr5{l in ResourceBalances, f in FeasibleSolutions, h in House: l="Electricity"}:            
   Cost_demand_cst[l] *lambda[f,h] <= Cost_self_consumption[f,h];

subject to size_cstr6{l in ResourceBalances, f in FeasibleSolutions, h in House: l="Electricity"}:           
   Cost_self_consumption[f,h] <= Cost_supply_cst[l] *lambda[f,h];


# self-consumption
param PV_prod{f in FeasibleSolutions, h in House, p in Period, t in Time[p]};
param PV_self_consummed{f in FeasibleSolutions, h in House, p in Period, t in Time[p]} :=  PV_prod[f,h,p,t] - Grid_demand["Electricity",f,h,p,t];
var objective_functions{a in Actors};


/*---------------------------------------------------------------------------------------------------------------------------------------
Lodger actor constraints
---------------------------------------------------------------------------------------------------------------------------------------*/
var C_op_lod_dist{h in House};
var C_op_lod_own{h in House};

subject to Costs_opex_lodger1{h in House}:
C_op_lod_dist[h] = sum{l in ResourceBalances, f in FeasibleSolutions, p in PeriodStandard, t in Time[p]} ( Cost_supply_district[l,f,h] * Grid_supply[l,f,h,p,t] * dp[p] * dt[p] ); 

subject to Costs_opex_lodger2{h in House}:
C_op_lod_own[h] = sum{l in ResourceBalances, f in FeasibleSolutions, p in PeriodStandard, t in Time[p]} ( Cost_self_consumption[f,h] * PV_self_consummed[f,h,p,t] * dp[p] * dt[p] ); 

# EMOO
#var C_op_lod_max{h in House} default 0;
#param EMOO_totex_lodger default 1.0;

#subject to Lodger1{h in House, f in FeasibleSolutions}:
#C_op_lod_max[h] <= sum{l in ResourceBalances, p in PeriodStandard, t in Time[p]} ( (Cost_supply_cst[l] * Grid_supply[l,f,h,p,t] + Cost_supply_cst["Electricity"] * PV_self_consummed[f,h,p,t]) * dp[p] * dt[p] ); 

#subject to Lodger_epsilon:
#sum{h in House} (C_op_lod_dist[h] + C_op_lod_own[h]) <= sum{h in House} C_op_lod_max[h] * EMOO_totex_lodger;

subject to obj_fct1:
objective_functions["Lodger"] = sum {h in House} (C_op_lod_dist[h] + C_op_lod_own[h]); 


/*---------------------------------------------------------------------------------------------------------------------------------------
Utility actor constraints
---------------------------------------------------------------------------------------------------------------------------------------*/
param utility_portfolio_min default -1e6;
var utility_portfolio;
var C_op_dist_own{h in House};
#var Grid_exchange {l in ResourceBalances, p in Period, t in Time[p]} >= 0;
#subject to P_exchange_cst{l in ResourceBalances, p in Period, t in Time[p]}:
#Grid_exchange[l,p,t] = (sum{f in FeasibleSolutions, h in House} ((Grid_supply[l,f,h,p,t] + Grid_demand[l,f,h,p,t]) * lambda[f,h]*dp[p]*dt[p]) - (Network_supply[l,p,t] + Network_demand[l,p,t]) ) /2;

subject to Utility1{h in House}: 
C_op_dist_own[h] = sum{l in ResourceBalances, f in FeasibleSolutions, p in PeriodStandard, t in Time[p]} ( Cost_demand_district[l,f,h] * Grid_demand[l,f,h,p,t] * dp[p] * dt[p] );

subject to Utility2:
utility_portfolio = sum{h in House} C_op_lod_dist[h] - Costs_op - tau * sum{u in Units} Costs_Unit_inv[u] - Costs_rep - sum {h in House} (C_op_dist_own[h]);

subject to Utility_epsilon:
utility_portfolio >= utility_portfolio_min;

subject to obj_fct2:
objective_functions["Utility"] = - utility_portfolio;


/*---------------------------------------------------------------------------------------------------------------------------------------
Owner actor constraints
---------------------------------------------------------------------------------------------------------------------------------------*/
param owner_portfolio_min default -1e6;
var owner_portfolio{h in House};

subject to Owner1{h in House}:
owner_portfolio[h] = C_op_lod_own[h] + C_op_dist_own[h] - Costs_House_inv[h]; 

subject to Owner_epsilon:
sum{h in House} owner_portfolio[h] >= owner_portfolio_min; 

subject to obj_fct3:
objective_functions["Owner"] = - sum{h in House} owner_portfolio[h]; 


/*---------------------------------------------------------------------------------------------------------------------------------------
Objectives
---------------------------------------------------------------------------------------------------------------------------------------*/

minimize TOTEX_bui:
sum {a in ActorObjective} objective_functions[a];
