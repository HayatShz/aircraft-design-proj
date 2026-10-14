function results = starship_optimize()
% STARSHIP_OPTIMIZE  Runs the full Starship redesign optimization.
% Iterates on empty weight reduction and propulsion upgrade to meet
% the mission requirements: 1800 lb payload, 1600 nmi range, 340 kt cruise.

%% ?? Load baseline geometry ????????????????????????????????????????
geom = starship_geometry();

%% ?? Design Variables ??????????????????????????????????????????????
% Modification factors (relative to baseline)
composite_factor   = 0.85;    % modern composite savings (15% reduction)
avionics_saving    = 250;     % lb
interior_saving    = 500;     % lb
SFC_improvement    = 0.04;    % 4% SFC reduction (PT6E-67XP)
eta_prop           = 0.87;    % modern propeller efficiency
LD_cruise          = 15.5;    % optimized canard + winglets

%% ?? Initial Gross Weight Estimate ?????????????????????????????????
W0_guess = 14500;   % lb (slightly below baseline MTOW)

%% ?? Iteration Loop (Weight Convergence) ???????????????????????????
tol = 1.0;   % lb
max_iter = 50;
W0 = W0_guess;

fprintf('\n========== STARSHIP OPTIMIZATION ==========\n');
fprintf('Target: 1800 lb payload, 1600 nmi range, 340 kt cruise\n\n');

for iter = 1:max_iter
    % Estimate empty weight
    mods_w.composite_factor = composite_factor;
    mods_w.avionics_saving = avionics_saving;
    mods_w.interior_saving = interior_saving;
    W = starship_weight(W0, geom, mods_w);

    % Estimate mission fuel
    mods_m.SFC_improvement = SFC_improvement;
    mods_m.LD_cruise = LD_cruise;
    mods_m.eta_prop = eta_prop;
    mods_m.payload = 1800;
    mods_m.range_target = 1600;
    M = starship_mission(W0, W.W_empty, geom, geom.engine, mods_m);

    % New gross weight estimate
    W0_new = W.W_empty + M.W_fuel + mods_m.payload;

    % Convergence check
    if abs(W0_new - W0) < tol
        W0 = W0_new;
        fprintf('Converged at iteration %d: W0 = %.0f lb\n', iter, W0);
        break;
    end
    W0 = 0.7 * W0 + 0.3 * W0_new;   % under-relaxation
end

%% ?? Final Results ?????????????????????????????????????????????????
W = starship_weight(W0, geom, mods_w);
M = starship_mission(W0, W.W_empty, geom, geom.engine, mods_m);

% Check requirements
fprintf('\n========== REQUIREMENT CHECK ==========\n');
fprintf('Payload:   %.0f lb  (target: 1800 lb)  ', M.W_payload_max);
if M.W_payload_max >= 1800, fprintf('[PASS]\n'); else, fprintf('[FAIL]\n'); end
fprintf('Range:     %.0f nmi (target: 1600 nmi) ', M.R_max_nmi);
if M.R_max_nmi >= 1600, fprintf('[PASS]\n'); else, fprintf('[FAIL]\n'); end
fprintf('Cruise:    %.0f kt  (target: 340 kt)   ', M.V_cruise);
if M.V_cruise >= 340, fprintf('[PASS]\n'); else, fprintf('[FAIL]\n'); end
fprintf('MTOW:      %.0f lb  (baseline: 14900 lb)\n', W0);
fprintf('Empty wt:  %.0f lb  (baseline: 10085 lb)\n', W.W_empty);
fprintf('Weight reduction: %.0f lb\n', 10085 - W.W_empty);

%% ?? Trade Study: Sensitivity of Range to W_empty ??????????????????
fprintf('\n========== TRADE STUDY: Range vs Empty Weight ==========\n');
W_empty_sweep = linspace(8200, 9500, 15);
R_sweep = zeros(size(W_empty_sweep));
for k = 1:length(W_empty_sweep)
    W0_k = W_empty_sweep(k) + M.W_fuel + 1800;
    Mk = starship_mission(W0_k, W_empty_sweep(k), geom, geom.engine, mods_m);
    R_sweep(k) = Mk.R_max_nmi;
end

results.W0 = W0;
results.W_empty = W.W_empty;
results.W_fuel = M.W_fuel;
results.R_max = M.R_max_nmi;
results.W_payload_max = M.W_payload_max;
results.P_margin = M.P_margin;
results.W_empty_sweep = W_empty_sweep;
results.R_sweep = R_sweep;
results.geom = geom;
results.W = W;
results.M = M;

fprintf('\n========== OPTIMIZATION COMPLETE ==========\n');
end