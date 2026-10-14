function geom = starship_geometry()
% STARSHIP_GEOMETRY  Beechcraft Starship 2000 baseline geometry.
% Compound-taper (cranked) main wing + slender canard foreplane.
% Wing area validated to published 281 ft^2.

%% ?? Main Wing (Compound Taper) ????????????????????????????????????
wing.root_chord    = 7.2;      % ft
wing.crank_chord   = 5.4;      % ft  (lambda_1 = 0.750)
wing.tip_chord     = 2.7;      % ft  (lambda_2 = 0.500)
wing.crank_span    = 13.5;     % ft semi-span at crank (49.5%)
wing.semi_span     = 27.25;    % ft (54.5 ft full span)
wing.sweep_inbd    = 6.0;      % deg quarter-chord (inboard)
wing.sweep_outbd   = 14.0;     % deg quarter-chord (outboard)
wing.dihedral      = 1.0;      % deg
wing.twist_tip     = -3.0;     % deg washout
wing.aspect_ratio  = (2*wing.semi_span)^2 / 281;   % 10.57

% Areas
A_inbd  = 2 * 0.5 * (wing.root_chord + wing.crank_chord) * wing.crank_span;
A_outbd = 2 * 0.5 * (wing.crank_chord + wing.tip_chord) * ...
          (wing.semi_span - wing.crank_span);
wing.area        = A_inbd + A_outbd;   % 281.5 ft^2
wing.area_inbd   = A_inbd;
wing.area_outbd  = A_outbd;
wing.lambda_inbd = wing.crank_chord / wing.root_chord;
wing.lambda_outbd= wing.tip_chord   / wing.crank_chord;

% MAC (area-weighted over the two panels)
MAC1 = (2/3)*wing.root_chord  * (1 + wing.lambda_inbd  + wing.lambda_inbd^2)  / (1 + wing.lambda_inbd);
MAC2 = (2/3)*wing.crank_chord * (1 + wing.lambda_outbd + wing.lambda_outbd^2) / (1 + wing.lambda_outbd);
wing.MAC = (MAC1*A_inbd + MAC2*A_outbd) / (A_inbd + A_outbd);

% Area-weighted quarter-chord sweep (for lift-curve slope)
wing.sweep_MAC = (wing.sweep_inbd*A_inbd + wing.sweep_outbd*A_outbd) / (A_inbd + A_outbd);

%% ?? Canard Foreplane (Variable Geometry) ??????????????????????????
canard.span         = 26.46;   % ft
canard.semi_span    = 13.23;   % ft
canard.root_chord   = 3.0;     % ft
canard.tip_chord    = 2.0;     % ft
canard.area         = (canard.root_chord + canard.tip_chord) * canard.semi_span;  % 66.2 ft^2
canard.taper_ratio  = canard.tip_chord / canard.root_chord;
canard.aspect_ratio = (2*canard.semi_span)^2 / canard.area;
canard.sweep_cruise = 30.0;    % deg aft
canard.sweep_land   = -4.0;    % deg forward
canard.incidence    = 2.0;     % deg
canard.airfoil      = 'Roncz 1085';

%% ?? Tipsails (Winglets with Rudders) ??????????????????????????????
tipsail.height      = 6.58;    % ft
tipsail.area_each   = 12.0;    % ft^2

%% ?? Fuselage ??????????????????????????????????????????????????????
fuse.length         = 46.1;
fuse.diameter       = 5.83;
fuse.cabin_width    = 5.42;
fuse.cabin_height   = 5.25;
fuse.cabin_length   = 21.08;
fuse.fineness_ratio = fuse.length / fuse.diameter;

%% ?? Weights ???????????????????????????????????????????????????????
weight.empty        = 10085;
weight.MTOW         = 14900;
weight.max_ramp     = 15010;
weight.fuel         = 3785;
weight.payload_max  = 1800;

%% ?? Propulsion ????????????????????????????????????????????????????
engine.baseline     = 'PT6A-67A';
engine.power_base   = 1200;    % shp
engine.count        = 2;
engine.prop_dia     = 8.67;    % ft
engine.prop_blades  = 5;

%% ?? Package & Print ???????????????????????????????????????????????
geom.wing=wing; geom.canard=canard; geom.tipsail=tipsail;
geom.fuse=fuse; geom.weight=weight; geom.engine=engine;

fprintf('=== STARSHIP GEOMETRY ===\n');
fprintf('Wing area:      %.1f ft^2  (target 281)\n', wing.area);
fprintf('Wing AR:        %.2f\n', wing.aspect_ratio);
fprintf('Wing MAC:       %.2f ft\n', wing.MAC);
fprintf('Wing sweep_MAC: %.1f deg\n', wing.sweep_MAC);
fprintf('lambda_inbd:    %.3f\n', wing.lambda_inbd);
fprintf('lambda_outbd:   %.3f\n', wing.lambda_outbd);
fprintf('Canard area:    %.1f ft^2 (%% wing: %.1f%%)\n', ...
        canard.area, 100*canard.area/wing.area);
fprintf('Canard AR:      %.2f\n', canard.aspect_ratio);
fprintf('Fineness:       %.2f\n', fuse.fineness_ratio);
end