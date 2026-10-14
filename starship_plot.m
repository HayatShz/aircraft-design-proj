function starship_plot(results)
% STARSHIP_PLOT  Planform + weight + trade-study visualization.
% If called with no argument, uses baseline geometry + placeholder data.

if nargin < 1
    results.geom = starship_geometry();
    results.W_empty_sweep = linspace(8200, 9800, 9);
    results.R_sweep = 1400:30:1640;
    results.W = starship_weight(14500, results.geom, ...
        struct('composite_factor',0.85,'avionics_saving',250,'interior_saving',500));
end

geom = results.geom;
w = geom.wing;

figure('Position',[100 100 1200 800],'Color','w');

%% (a) Planform with crank
subplot(2,2,1); hold on; axis equal; grid on;
y_in = linspace(0, w.crank_span, 30);
xle_in = y_in * tand(w.sweep_inbd);
c_in = w.root_chord + (w.crank_chord - w.root_chord) * (y_in/w.crank_span);

y_out = linspace(w.crank_span, w.semi_span, 30);
xle_out = w.crank_span*tand(w.sweep_inbd) + ...
          (y_out - w.crank_span)*tand(w.sweep_outbd);
c_out = w.crank_chord + (w.tip_chord - w.crank_chord) * ...
        (y_out - w.crank_span)/(w.semi_span - w.crank_span);

y_all = [y_in y_out]; xle = [xle_in xle_out]; c_all = [c_in c_out];
for s = [-1 1]
    plot(s*y_all, xle, 'b-', 'LineWidth', 2);
    plot(s*y_all, xle+c_all, 'b-', 'LineWidth', 2);
end
plot([0 0],[0 w.root_chord],'b-','LineWidth',2);
plot([ w.crank_span  w.crank_span], xle_in(end)+[0 c_in(end)],'r--','LineWidth',1.5);
plot([-w.crank_span -w.crank_span], xle_in(end)+[0 c_in(end)],'r--','LineWidth',1.5);

% Canard
yc = linspace(0, geom.canard.semi_span, 30);
xle_c = yc * tand(geom.canard.sweep_cruise) - 15;   % place canard forward
cc = geom.canard.root_chord + (geom.canard.tip_chord - geom.canard.root_chord)*(yc/geom.canard.semi_span);
for s = [-1 1]
    plot(s*yc, xle_c, 'g-', 'LineWidth', 1.8);
    plot(s*yc, xle_c+cc, 'g-', 'LineWidth', 1.8);
end

xlabel('y (ft)'); ylabel('x (ft)');
title(sprintf('Planform: crank at %.1f ft (%.0f%% semi-span), S = %.0f ft^2', ...
      w.crank_span, 100*w.crank_span/w.semi_span, w.area));
legend('Wing','Wing TE','','','Crank','','Canard','Canard TE','Location','best');
xlim([-30 30]); ylim([-25 12]);

%% (b) Spanwise lift (approximate)
subplot(2,2,2);
eta = linspace(-1, 1, 100);
cl_span = 1.4*sqrt(max(0,1-eta.^2)) + 0.25;   % elliptic-ish for reference
plot(eta, cl_span, 'b-','LineWidth',2);
hold on;
plot([-w.crank_span/w.semi_span -w.crank_span/w.semi_span], [0 max(cl_span)*1.05], 'r--');
plot([ w.crank_span/w.semi_span  w.crank_span/w.semi_span], [0 max(cl_span)*1.05], 'r--');
xlabel('2y/b'); ylabel('c_l(y)'); grid on;
title('Spanwise Loading (schematic — crank shown dashed)');

%% (c) Range vs Empty Weight
subplot(2,2,3);
if isfield(results,'W_empty_sweep') && isfield(results,'R_sweep')
    plot(results.W_empty_sweep, results.R_sweep, 'b-o','LineWidth',2,'MarkerFaceColor','b');
    yline(1600, 'r--', 'Target 1600 nmi');
    xlabel('Empty Weight (lb)'); ylabel('Range (nmi)');
    title('Trade Study: Range vs Empty Weight');
    grid on;
end

%% (d) Component weights
subplot(2,2,4);
if isfield(results,'W')
    W = results.W;
    labels = {'Wing','Fuselage','Canard','Tipsails','Gear', ...
              'Engines','Props','Systems','Avionics','Furnishings'};
    vals = [W.W_wing W.W_fuse W.W_canard W.W_tipsails W.W_gear ...
            W.W_engines W.W_props W.W_systems W.W_avionics W.W_furnishings];
    pie(vals, labels);
    title(sprintf('Optimized Empty Weight = %.0f lb', W.W_empty));
end

sgtitle('Beechcraft Starship — Conceptual Redesign');
end