%% RUN_STARSHIP  Full Starship baseline + optimized analysis.
clear; clc;

%% 1. Baseline Geometry
geom = starship_geometry();
fprintf('\n');

%% 2. Baseline Weight (validate to 10085 lb)
mods_base.composite_factor = 1.00;
mods_base.avionics_saving  = 0;
mods_base.interior_saving  = 0;
W_base = starship_weight(14900, geom, mods_base);
fprintf('\n');

%% 3. Baseline Cruise Aero
fprintf('===== BASELINE CRUISE AERODYNAMICS =====\n');
aero = starship_aero(geom, 2.0, 0.55, 35000);
fprintf('CL  = %.4f\n', aero.CL);
fprintf('CD  = %.5f  (CD0 = %.5f, CDi = %.5f)\n', ...
        aero.CD, aero.CD0, aero.CDi);
fprintf('L/D = %.2f\n', aero.LD);
fprintf('e   = %.3f\n', aero.e);
fprintf('\n');

%% 4. Optimized Design (weight reduction + propulsion upgrade)
fprintf('===== OPTIMIZED DESIGN =====\n');
mods_opt.composite_factor = 0.85;   % 15% structural weight saving
mods_opt.avionics_saving  = 250;    % modern avionics
mods_opt.interior_saving  = 500;    % lightweight interior

W0_target = 14500;
W_opt = starship_weight(W0_target, geom, mods_opt);
reduction = W_base.W_empty - W_opt.W_empty;
fprintf('Weight reduction: %.0f lb (target: 1200-1500 lb)\n\n', reduction);

%% 5. Trade Study: Range vs Empty Weight (CORRECT Breguet)
fprintf('===== TRADE STUDY: RANGE vs EMPTY WEIGHT =====\n');

W_empty_sweep = linspace(8200, 9800, 9);
W_payload     = 1800;         % lb (fixed mission requirement)
W_fuel_cap    = 3785;         % lb (from geometry, 565 gal Jet-A)
eta_p         = 0.85;         % propulsive efficiency
LD_cruise     = 15.6;         % from starship_aero
SFC_hp        = 0.48;         % lb/(hp*hr), PT6E-67XP upgraded
SFC_ft        = SFC_hp / (550 * 3600);   % 1/ft (Breguet for prop)
                                              % 1 hp = 550 ft*lb/s

% Mission segment weight fractions (Raymer Table 17.2, business turboprop)
f_taxi    = 0.970;
f_climb   = 0.985;
f_descent = 0.985;
f_reserve = 0.940;   % 6% reserve + 30 min loiter combined

R_sweep = zeros(size(W_empty_sweep));
W0_sweep = zeros(size(W_empty_sweep));

for k = 1:length(W_empty_sweep)
    We = W_empty_sweep(k);
    W0 = We + W_fuel_cap + W_payload;
    W0_sweep(k) = W0;

    % Weight at start of cruise
    W_start_cruise = W0 * f_taxi * f_climb;

    % Cruise fuel available = total fuel minus non-cruise segments
    Wf_taxi_climb   = W0 * (1 - f_taxi*f_climb);
    Wf_descent_res  = W0 * (1 - f_descent*f_reserve);
    Wf_cruise       = W_fuel_cap - Wf_taxi_climb - Wf_descent_res;

    if Wf_cruise <= 0
        R_sweep(k) = 0;
        continue;
    end

    W_end_cruise = W_start_cruise - Wf_cruise;

    % Breguet (propeller): R = (eta_p * L/D / SFC) * ln(W1/W2)
    R_ft  = (eta_p * LD_cruise / SFC_ft) * log(W_start_cruise / W_end_cruise);
    R_nmi = R_ft / 6076.12;
    R_sweep(k) = R_nmi;
end

fprintf('Empty wt (lb)  W0 (lb)  Range (nmi)  Payload (lb)\n');
for k = 1:length(W_empty_sweep)
    fprintf('%8.0f     %8.0f   %8.0f    %6.0f\n', ...
        W_empty_sweep(k), W0_sweep(k), R_sweep(k), W_payload);
end
fprintf('\n');

%% 6. Save results and plot
results.geom = geom;
results.W_base = W_base;
results.W_opt = W_opt;
results.aero = aero;
results.W_empty_sweep = W_empty_sweep;
results.R_sweep = R_sweep;
results.W0 = W0_target;

starship_plot(results);
fprintf('\nAnalysis complete. Plots generated.\n');