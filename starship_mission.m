function M = starship_mission(W0, W_empty, geom, engine, mods)
% STARSHIP_MISSION  Turboprop mission profile using Breguet range equation.
% Implements the propeller-aircraft Breguet equation with power SFC.
%
% Inputs:
%   W0       - design gross weight (lb)
%   W_empty  - empty weight (lb)
%   geom     - geometry struct
%   engine   - engine struct (with .power_base, .count, .SFC)
%   mods     - modification struct:
%              mods.SFC_improvement  (fraction, e.g., 0.04 for 4%)
%              mods.LD_cruise        (estimated cruise L/D)
%              mods.eta_prop         (propulsive efficiency, e.g., 0.85)
%              mods.payload          (lb)
%              mods.range_target     (nmi)
%
% References:
%   [1] Raymer, D.P., Aircraft Design: A Conceptual Approach, 6th Ed.,
%       Eq. 17.14 (propeller Breguet).
%   [2] Roskam, J., Airplane Design Part VII: Determination of Stability,
%       Control and Performance.
%   [3] Mattingly, J.D., Heiser, W.H., Pratt, D.T., Aircraft Engine Design.

if nargin < 5
    mods.SFC_improvement = 0;
    mods.LD_cruise = 15.0;
    mods.eta_prop = 0.85;
    mods.payload = 1800;
    mods.range_target = 1600;
end

%% ?? Mission Segment Weight Fractions ??????????????????????????????
% Raymer Table 17.2 adapted for business turboprop
WF_taxi     = 0.970;   % start, taxi, takeoff
WF_climb    = 0.985;   % climb to cruise altitude
WF_descent  = 0.990;   % descent and landing
WF_loiter   = 0.995;   % 30 min loiter at 1500 ft (IFR reserve)

%% ?? Cruise Segment (Breguet for Propeller Aircraft) ???????????????
% R = (eta_p / (SFC * g)) * (L/D) * ln(W1/W2)
% In consistent units:
%   R [ft], eta_p [-], SFC [lb/(hp*hr)], L/D [-], V [ft/s]
%
% Rearranged: W2/W1 = exp(-R * SFC / (eta_p * L/D * V))

Range_ft = mods.range_target * 6076.12;   % nmi to ft
V_cruise_kt = 340;                         % target cruise TAS (kt)
V_cruise_fps = V_cruise_kt * 1.68781;      % kt to ft/s

% Power-specific fuel consumption (PSFC)
% PT6A-67A baseline: ~0.50 lb/(hp*hr) at cruise
SFC_baseline = 0.50;   % lb/(hp*hr)
SFC_modified = SFC_baseline * (1 - mods.SFC_improvement);

% Cruise weight fraction (Breguet for prop)
WF_cruise = exp(-Range_ft * SFC_modified / ...
                (mods.eta_prop * mods.LD_cruise * V_cruise_fps));

%% ?? Loiter Segment (Breguet for Propeller) ????????????????????????
% E = (eta_p / SFC) * (L/D) * ln(W1/W2)
Loiter_hr = 0.5;   % 30 min reserve
SFC_loiter = SFC_modified;
LD_loiter = 13.0;  % estimated loiter L/D
WF_loiter = exp(-Loiter_hr * SFC_loiter / (mods.eta_prop * LD_loiter));

%% ?? Total Mission Fuel Fraction ???????????????????????????????????
FF = WF_taxi * WF_climb * WF_cruise * WF_descent * WF_loiter;
FF_reserve = 1.06;   % 6% fuel safety margin

W_fuel = (1 - FF * FF_reserve) * W0;   % fuel burned (lb)
W_payload = mods.payload;
W_landing = W0 - W_fuel;

% Check payload capability
W_payload_max = W0 - W_empty - W_fuel;

%% ?? Range Calculation (for a given fuel load) ?????????????????????
% Solve for range given the fuel capacity
W_fuel_capacity = geom.weight.fuel;
W1 = W0;
W2 = W1 - W_fuel_capacity;

% Account for mission segments before cruise
W_before_cruise = W0 * WF_taxi * WF_climb;
W_after_cruise = W_before_cruise * WF_cruise;
W_at_landing = W_after_cruise * WF_descent * WF_loiter * FF_reserve;

% Maximum range with full fuel
R_max_ft = (mods.eta_prop * mods.LD_cruise * V_cruise_fps / SFC_modified) * ...
           log(W_before_cruise / (W_before_cruise - W_fuel_capacity*0.9));
R_max_nmi = R_max_ft / 6076.12;

%% ?? Endurance ?????????????????????????????????????????????????????
E_max_hr = (mods.eta_prop * LD_loiter / SFC_loiter) * ...
           log(W0 / (W0 - W_fuel_capacity));

%% ?? Power Required ????????????????????????????????????????????????
% Cruise power required
W_cruise = 0.95 * W0;
D_cruise = W_cruise / mods.LD_cruise;
P_req_hp = D_cruise * V_cruise_fps / (550 * mods.eta_prop);  % hp
P_avail_hp = engine.count * engine.power_base;
P_margin = P_avail_hp - P_req_hp;

%% ?? Package Results ???????????????????????????????????????????????
M.WF_taxi    = WF_taxi;
M.WF_climb   = WF_climb;
M.WF_cruise  = WF_cruise;
M.WF_descent = WF_descent;
M.WF_loiter  = WF_loiter;
M.FF         = FF;
M.W_fuel     = W_fuel;
M.W_payload  = W_payload;
M.W_payload_max = W_payload_max;
M.W_landing  = W_landing;
M.R_max_nmi  = R_max_nmi;
M.E_max_hr   = E_max_hr;
M.SFC        = SFC_modified;
M.LD_cruise  = mods.LD_cruise;
M.V_cruise   = V_cruise_kt;
M.P_req_hp   = P_req_hp;
M.P_avail_hp = P_avail_hp;
M.P_margin   = P_margin;

fprintf('=== MISSION ANALYSIS (Turboprop Breguet) ===\n');
fprintf('SFC (cruise):      %.4f lb/(hp*hr)\n', SFC_modified);
fprintf('L/D (cruise):      %.1f\n', mods.LD_cruise);
fprintf('Cruise speed:      %.0f kt\n', V_cruise_kt);
fprintf('Cruise WF:         %.4f\n', WF_cruise);
fprintf('Total FF:          %.4f\n', FF);
fprintf('Fuel burned:       %.0f lb\n', W_fuel);
fprintf('Max payload:       %.0f lb\n', W_payload_max);
fprintf('Max range:         %.0f nmi\n', R_max_nmi);
fprintf('Max endurance:     %.2f hr\n', E_max_hr);
fprintf('Power required:    %.0f hp\n', P_req_hp);
fprintf('Power available:   %.0f hp\n', P_avail_hp);
fprintf('Power margin:      %.0f hp\n', P_margin);
end