% PRUEBA SINTETICA: valida dimensiones y ecuaciones sin usar la planta REAL.
% No incluir estas curvas como resultados de laboratorio.
clear;clc;
p=modelo_lab7();
p.F=[-10 0;10 -20]; p.G=[1;0];p.H=[0 1];p.J=0;
p.Ts_s=0.02;
p.revision_modelo='PRUEBA_SINTETICA_NO_EXPERIMENTAL';
p.validado=true; % valido SOLO para prueba matematico/numerica artificial
p.t_sim_s=1.0;p.referencia_V=0.05;
d=disenar_lab7(p);
for i=1:numel(d.observadores)
  sp=simular_lab7(d,p,i,'prediccion');
  sa=simular_lab7(d,p,i,'actual');
  assert(all(isfinite(sp.y_V)) && all(isfinite(sa.y_V)));
  fprintf('Prueba E%d correcta: predictor y actual con %d muestras.\n', ...
      i,numel(sp.t_s));
end
