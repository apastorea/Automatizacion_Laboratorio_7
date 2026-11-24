% VALIDAR_NOMINAL_LAB7 — Modelo guia, sin mediciones ni PSoC fisico.
% Ejecutar en MATLAB con Control System Toolbox.
clear; clc;
p=modelo_lab7();
assert(~p.validado && strcmp(p.origen_modelo,'GUIA_OFICIAL_NOMINAL'));
assert(norm(p.F-[-66.66666667 0;-212.76595745 -666.66666667],'fro')<1e-6);
assert(norm(p.G-[-212.76595745;0])<1e-6);
Gp=tf(ss(p.F,p.G,p.H,p.J));
fBW_hz=bandwidth(Gp)/(2*pi); fs_hz=1/p.Ts_s;
assert(abs(dcgain(Gp)-p.K_estatica)<1e-8);
assert(fs_hz/fBW_hz>30);
cuentas=round(p.Ts_s*p.reloj_timer_hz_antecedente);
assert(abs(cuentas/p.reloj_timer_hz_antecedente-p.Ts_s)<1e-12);
d=disenar_lab7(p);
assert(norm(d.A-[0.87517332 0;-0.21687099 0.26359714],'fro')<2e-7);
assert(norm(d.B-[-0.39838302;0.05792937])<2e-7);
assert(norm(d.K-[2.15692217 6.87132640])<2e-6);
assert(abs(d.Nr-1.09474803)<2e-6);
for i=1:2
  o=d.observadores(i);
  assert(max(abs(sort(eig(d.A-o.L_pred*d.C))-sort(o.polos(:))))<1e-7);
  assert(max(abs(sort(eig((eye(2)-o.L_actual*d.C)*d.A))-sort(o.polos(:))))<1e-7);
  for modo={'prediccion','actual'}
    s=simular_lab7(d,p,i,modo{1});
    assert(all(isfinite(s.y_V)) && all(isfinite(s.u_V)));
    assert(~any(s.saturado),'Saturacion a 50 mV nominal.');
    assert(abs(s.y_V(end)-p.referencia_V)<1e-4);
  end
end
fprintf('Kdc %.8f, fBW %.5f Hz, fs/fBW %.2f\n',p.K_estatica,fBW_hz,fs_hz/fBW_hz);
fprintf('Ts %.3f ms; reloj historico %d cuentas (Period %d supuesto).\n',1e3*p.Ts_s,cuentas,cuentas-1);
fprintf('K=[%.8f %.8f], Nr=%.8f\n',d.K,d.Nr);
fprintf('Verificacion nominal matematica lista; VALIDACION FISICA PENDIENTE.\n');
