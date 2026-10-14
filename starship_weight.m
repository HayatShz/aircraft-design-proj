function W = starship_weight(W0, geom, mods)
% STARSHIP_WEIGHT  Calibrated component weight estimation for the Starship.
% Calibrated so baseline (W0=14900, no mods) reproduces published
% empty weight = 10,085 lb.
%
% Inputs:
%   W0   - design gross weight (lb)
%   geom - geometry struct
%   mods - struct:
%       .composite_factor   (1.00 = baseline; 0.85 = modern composites)
%       .avionics_saving    (lb, e.g., 250)
%       .interior_saving    (lb, e.g., 500)
%
% Method: Raymer Class II.5 fraction-based, with structural scaling
% W_i ~ (W0)^0.5 and K_corr calibrated to baseline.

if nargin < 3
    mods.composite_factor = 1.0;
    mods.avionics_saving  = 0;
    mods.interior_saving  = 0;
end

%% Calibration: baseline component weights at W0_ref = 14900 lb
W0_ref = 14900;
ref = struct();
ref.wing        = 1800;   % 17.8% of empty  (281 ft^2 composite wing)
ref.fuse        = 1350;   % 13.4%
ref.canard      =  550;   %  5.5%  (66 ft^2 foreplane + actuators)
ref.tipsails    =  100;   %  1.0%  (two vertical tipsails w/ rudders)
ref.gear        =  650;   %  6.4%  (retractable tricycle)
ref.engines     = 2521;   % 25.0%  (2 × PT6A-67A installed + accessories)
ref.props       =  400;   %  4.0%  (2 × 5-blade McCauley)
ref.systems     = 1000;   %  9.9%  (flight controls, hydraulics, electrical)
ref.avionics    =  800;   %  7.9%  (all-glass cockpit, dual EFIS)
ref.furnishings =  914;   %  9.1%  (8-seat executive interior)
% Total = 10085 lb  ? matches published empty weight

%% Structural scaling with gross weight (typical W0^0.5 exponent)
scale = (W0 / W0_ref)^0.5;

%% Apply modification factors
cf = mods.composite_factor;

W_wing        = ref.wing        * scale * cf;
W_fuse        = ref.fuse        * scale * cf;
W_canard      = ref.canard      * scale * cf;
W_tipsails    = ref.tipsails    * scale * cf;
W_gear        = ref.gear        * scale;        % no composite savings in gear
W_engines     = ref.engines;                    % fixed (engine swap modeled separately)
W_props       = ref.props;                      % fixed (same as baseline)
W_systems     = ref.systems     * (W0/W0_ref)^0.20;
W_avionics    = ref.avionics    - mods.avionics_saving;
W_furnishings = ref.furnishings * cf - mods.interior_saving;

W_empty = W_wing + W_fuse + W_canard + W_tipsails + W_gear + ...
          W_engines + W_props + W_systems + W_avionics + W_furnishings;

%% Package
W.W_empty = W_empty;   W.W_wing = W_wing;   W.W_fuse = W_fuse;
W.W_canard= W_canard;  W.W_tipsails = W_tipsails;
W.W_gear  = W_gear;    W.W_engines = W_engines;  W.W_props = W_props;
W.W_systems=W_systems; W.W_avionics=W_avionics;  W.W_furnishings = W_furnishings;
W.W0 = W0;

fprintf('=== COMPONENT WEIGHT BREAKDOWN ===\n');
fprintf('Wing:          %8.0f lb\n', W_wing);
fprintf('Fuselage:      %8.0f lb\n', W_fuse);
fprintf('Canard:        %8.0f lb\n', W_canard);
fprintf('Tipsails:      %8.0f lb\n', W_tipsails);
fprintf('Landing gear:  %8.0f lb\n', W_gear);
fprintf('Engines:       %8.0f lb\n', W_engines);
fprintf('Propellers:    %8.0f lb\n', W_props);
fprintf('Systems:       %8.0f lb\n', W_systems);
fprintf('Avionics:      %8.0f lb\n', W_avionics);
fprintf('Furnishings:   %8.0f lb\n', W_furnishings);
fprintf('?????????????????????????????\n');
fprintf('EMPTY WEIGHT:  %8.0f lb  (baseline 10085)\n', W_empty);
end