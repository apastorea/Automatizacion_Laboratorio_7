% LABORATORIO 7 - Diseno y comparacion de dos observadores y dos dinamicas.
% No ejecuta ensayos fisicos ni supone resultados medidos.
clear; clc; close all;
p=modelo_lab7();
d=disenar_lab7(p);  % Nominal SOLO para simulaciones.
carpeta=fileparts(mfilename('fullpath'));
destino=fullfile(carpeta,'..','05_Resultados');
if ~isfolder(destino), mkdir(destino);end
if ~isfolder(fullfile(destino,'figuras')),mkdir(fullfile(destino,'figuras'));end
n=0;
for i=1:numel(d.observadores)
  for modo={'prediccion','actual'}
    s=simular_lab7(d,p,i,modo{1});
    n=n+1;
    nombre=sprintf('lab7_%s_%s',modo{1},d.observadores(i).nombre);
    tipo_dato=repmat(string('SIMULACION_NOMINAL_GUIA'),numel(s.u_V),1);
    tu=table(tipo_dato,s.t_s(1:end-1).',s.r_V(1:end-1).', ...
       s.y_V(1:end-1).',s.u_V(:),s.norma_error(1:end-1).', ...
       s.saturado(:), 'VariableNames', ...
       {'tipo_dato','tiempo_s','referencia_V','salida_V','mando_V','error_estimacion','saturado'});
    writetable(tu,fullfile(destino,[nombre,'.csv']));
    f=figure('Color','w','Name',nombre,'Visible','off');
    tiledlayout(3,1,'TileSpacing','compact');
    nexttile;stairs(s.t_s,s.y_V,'LineWidth',1.5);hold on; ...
       stairs(s.t_s,s.r_V,'--','LineWidth',1.0);
       grid on;ylabel('Salida (V)');legend('y[k]','r[k]','Location','best');
       title(['Observador ',modo{1},' - ',d.observadores(i).nombre]);
    nexttile;plot(s.t_s,s.norma_error,'LineWidth',1.4);
       ylabel('||x-xhat||');grid on;
    nexttile;stairs(s.t_s(1:end-1),s.u_V,'LineWidth',1.4);
       ylabel('u aplicada (V)');xlabel('Tiempo (s)');grid on;
    exportgraphics(f,fullfile(destino,'figuras',[nombre,'.png']),'Resolution',300);
    close(f);
    if any(s.saturado)
       warning('%s: saturacion en %d muestras. La asignacion de polos lineal no describe completamente el ensayo.', ...
           nombre,nnz(s.saturado));
    end
  end
end
save(fullfile(destino,'lab7_diseno.mat'),'d','p');
fprintf('Generados %d conjuntos SIMULADOS CON MODELO NOMINAL.\n',n);
fprintf('NINGUNO es medicion de Lab7 ni ajuste listo para hardware.\n');
