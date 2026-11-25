function d = disenar_lab7(p,mostrar)
%DISENAR_LAB7 Discretizacion, realimentacion y dos observadores por dualidad.
% Requiere Control System Toolbox: ss, c2d, ctrb, obsv, place.
% De acuerdo con el enunciado: un solo canal de salida y una entrada.

arguments
    p struct
    mostrar (1,1) logical = true
end

% El diseño predeterminado usa el modelo identificado. El nominal solo se
% admite cuando el llamador lo pide expresamente para una comparación.
permiteNominal = isfield(p,"simulacion_nominal") && p.simulacion_nominal && ...
    isfield(p,"origen_modelo") && p.origen_modelo == "GUIA_OFICIAL_NOMINAL";
assert(isfield(p,"validado") && (p.validado || permiteNominal), ...
    "Modelo sin validación ni procedencia nominal documentada.");
if permiteNominal
    warning("LAB7:modeloNominal", ...
        "Modelo nominal usado solo como referencia de simulación.");
end
F=p.F; G=p.G; H=p.H; J=p.J;
assert(isequal(size(F),[2 2]) && isequal(size(G),[2 1]) && ...
       isequal(size(H),[1 2]) && isscalar(J), 'Dimensiones incompatibles.');
assert(all(isfinite([F(:);G(:);H(:);J])),'Modelo contiene NaN/Inf.');
assert(isscalar(p.Ts_s) && p.Ts_s>0 && isfinite(p.Ts_s), ...
       'Tiempo de muestreo invalido.');
assert(abs(J)<1e-12, ...
       'La version inicial supone J=0; ajustar la formula si hay paso directo.');

sys_c=ss(F,G,H,J);
sys_d=c2d(sys_c,p.Ts_s,'zoh');
[A,B,C,D]=ssdata(sys_d);
assert(rank(ctrb(A,B))==2, 'Modelo discreto no controlable.');
assert(rank(obsv(A,C))==2, 'Modelo discreto no observable.');
assert(rank(obsv(A,C*A))==2, ...
       'No se puede asignar libremente el observador actual con C*A.');

pc=p.polos_control(:).';
assert(all(abs(pc)<1), 'Los polos del controlador deben ser estables.');
K=place(A,B,pc);
% u[k] = -K*x_est[k] + Nr*r[k]; para sistema SISO con D=0.
den=C*((eye(2)-(A-B*K))\B);
assert(abs(den)>1e-10,'No existe ganancia de seguimiento estatica no nula.');
Nr=1/den;

d=struct('A',A,'B',B,'C',C,'D',D,'K',K,'Nr',Nr, ...
         'Ts_s',p.Ts_s,'polos_control',pc,'F',F,'G',G,'H',H, ...
         'origen_modelo',p.origen_modelo, ...
         'revision_modelo',p.revision_modelo, ...
         'validado_fisicamente',p.validado);
d.observadores=struct('nombre',{},'polos',{},'L_pred',{},'L_actual',{});
for i=1:numel(p.polos_estimador)
    po=p.polos_estimador{i}(:).';
    assert(numel(po)==2 && all(abs(po)<1), 'Polos del observador invalidos.');
    Lp=place(A',C',po).';
    La=place(A',(C*A)',po).';
    assert(max(abs(eig(A-Lp*C)))<1, 'Predictor no estable.');
    assert(max(abs(eig((eye(2)-La*C)*A)))<1,'Observador actual no estable.');
    d.observadores(end+1)=struct('nombre',sprintf('E%d',i), ...
        'polos',po,'L_pred',Lp,'L_actual',La);
end

if mostrar
    fprintf('Ts = %.6f s; rank(ctrb)=2; rank(obsv)=2\n',p.Ts_s);
    fprintf('A=\n');disp(A); fprintf('B=\n');disp(B);
    fprintf('K=\n');disp(K);fprintf('Nr=%.9g\n',Nr);
    for i=1:numel(d.observadores)
        fprintf('%s: L_pred = ',d.observadores(i).nombre);
        disp(d.observadores(i).L_pred.');
        fprintf('%s: L_actual = ',d.observadores(i).nombre);
        disp(d.observadores(i).L_actual.');
    end
end
end
