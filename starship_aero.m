function aero = starship_aero(geom, alpha_deg, Mach, altitude_ft)
% STARSHIP_AERO  DATCOM/Raymer-style aerodynamic analysis for the Starship.
% Computes CL, CD (parasite + induced), L/D for the compound-taper wing
% + canard configuration. Includes compressibility (Prandtl-Glauert).
%
% Inputs:
%   geom        - from starship_geometry()
%   alpha_deg   - angle of attack (deg)
%   Mach        - flight Mach number
%   altitude_ft - pressure altitude (ft)
%
% Methods:
%   [1] Raymer Eq. 12.10 (lift-curve slope, swept wing)
%   [2] Raymer Eq. 12.48 (Oswald efficiency, swept wing)
%   [3] Raymer Ch. 12.5 (CD0 buildup)
%   [4] Hoerner, Fluid-Dynamic Drag (component buildup)

%% ?? Atmosphere & Flight State ?????????????????????????????????????
[T, a_sound, P, rho_SI] = atmosisa(altitude_ft * 0.3048);  % SI
rho   = rho_SI * 0.00194032;   % slug/ft^3
V     = Mach * a_sound / 0.3048;   % ft/s (TAS)

w = geom.wing;
AR = w.aspect_ratio;
S  = w.area;
beta2 = max(1 - Mach^2, 0.01);   % Prandtl-Glauert factor squared

%% ?? Lift-Curve Slope (Raymer Eq. 12.10) ???????????????????????????
% Use area-weighted quarter-chord sweep
Lam = w.sweep_MAC;
a_w = 2*pi*AR / (2 + sqrt(4 + AR^2*beta2*(1 + tand(Lam)^2/beta2)));

% Canard (separate panel, no crank)
AR_c = geom.canard.aspect_ratio;
Lam_c = geom.canard.sweep_cruise;
a_c = 2*pi*AR_c / (2 + sqrt(4 + AR_c^2*beta2*(1 + tand(Lam_c)^2/beta2)));

% Zero-lift angles (estimated for Roncz laminar sections)
alpha0_w = -2.5;   % deg
alpha0_c = -2.5;   % deg

% Wing lift
CL_w = a_w * (alpha_deg - alpha0_w) * pi/180;

% Canard lift (includes its own incidence)
CL_c = a_c * (alpha_deg + geom.canard.incidence - alpha0_c) * pi/180;

% Total CL: canard contributes with efficiency factor (downwash + fuselage)
k_canard = 0.85;
CL = CL_w + k_canard * CL_c * (geom.canard.area / S);

%% ?? Induced Drag (Raymer Eq. 12.48) ???????????????????????????????
% Oswald efficiency for swept wing
e = 4.61 * (1 - 0.045*AR^0.68) * (cosd(Lam))^0.15 - 3.1;
e = min(max(e, 0.65), 0.95);   % clamp to physical range

CDi = CL^2 / (pi * AR * e);
% Canard trim drag penalty (Raymer §12.5, canard configuration)
% The canard lifts up; wing must lift more to balance -> extra induced drag
CDi = CDi * 1.20;   % 20% penalty

%% ?? Parasite Drag Buildup (Raymer Ch. 12.5) ???????????????????????
% Equivalent skin-friction coefficients (turbulent flat plate, Re ~ 10^7)
Cf_wing  = 0.0030;
Cf_fuse  = 0.0025;
Cf_misc  = 0.0035;

% Wetted areas
Swet_wing = 2.05 * S;                                    % both sides, form factor 2.05
Swet_can  = 2.05 * geom.canard.area;
Swet_fuse = pi * geom.fuse.diameter * geom.fuse.length * 0.80;  % 80% of cylinder
Swet_tip  = 2 * 2.05 * geom.tipsail.area_each;

% Nacelles (2 engines behind wing)
Swet_nac = 2 * pi * 1.8 * 6.0;   % 2 nacelles, ~3.6 ft dia x 6 ft long

% CD0 components
CD0_wing = Cf_wing * Swet_wing / S;
CD0_can  = Cf_can_wing(Swet_can, S, Cf_wing);
CD0_fuse = Cf_fuse * Swet_fuse / S;
CD0_tip  = Cf_wing * Swet_tip  / S;
CD0_nac  = Cf_misc * Swet_nac  / S;
CD0_misc = 0.0035;   % antennae, gaps, leaks, cooling

CD0 = CD0_wing + CD0_can + CD0_fuse + CD0_tip + CD0_nac + CD0_misc;

% Compressibility drag rise (simple wave drag correction)
if Mach > 0.70
    CD0 = CD0 + 0.02 * (Mach - 0.70)^2;
end

%% ?? Totals ????????????????????????????????????????????????????????
CD = CD0 + CDi;
LD = CL / CD;

%% ?? Package ???????????????????????????????????????????????????????
aero.CL      = CL;
aero.CL_w    = CL_w;
aero.CL_c    = CL_c;
aero.CD      = CD;
aero.CD0     = CD0;
aero.CDi     = CDi;
aero.LD      = LD;
aero.e       = e;
aero.a_w     = a_w;
aero.V       = V;
aero.q       = 0.5 * rho * V^2;
aero.rho     = rho;
aero.alpha   = alpha_deg;
aero.Mach    = Mach;
aero.altitude= altitude_ft;
aero.CD0_breakdown = struct('wing',CD0_wing,'canard',CD0_can, ...
    'fuse',CD0_fuse,'tipsail',CD0_tip,'nacelle',CD0_nac,'misc',CD0_misc);
end

% Local helper for canard contribution
function cd0 = Cf_can_wing(Swet, S, Cf)
    cd0 = Cf * Swet / S;
end