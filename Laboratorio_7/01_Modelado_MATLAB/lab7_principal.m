% LABORATORIO 7 - Diseno y comparacion de dos observadores y dos dinamicas.
% Usa el modelo identificado como base de diseño. No ejecuta hardware.
clear; clc; close all;
p=modelo_lab7();
d=disenar_lab7(p);
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
    tipo_dato=repmat("SIMULACION_MODELO_IDENTIFICADO",numel(s.u_V),1);
    tu=table(tipo_dato,s.t_s(1:end-1).',s.r_V(1:end-1).', ...
       s.y_V(1:end-1).',s.u_V(:),s.norma_error(1:end-1).', ...
       s.saturado(:), 'VariableNames', ...
       {'tipo_dato','tiempo_s','referencia_V','salida_V','mando_V','error_estimacion','saturado'});
    writetable(tu,fullfile(destino,[nombre,'.csv']));
    f=figure('Color','w','Name',nombre,'Visible','off');
    tl=tiledlayout(f,3,1,'TileSpacing','compact','Padding','compact');
    ax1=nexttile(tl);stairs(ax1,s.t_s,s.y_V,'LineWidth',1.5);hold(ax1,'on');
       stairs(ax1,s.t_s,s.r_V,'--','LineWidth',1.0);hold(ax1,'off');
       grid(ax1,'on');ylabel(ax1,'Salida (V)');
       legend(ax1,'y[k]','r[k]','Location','best');
       title(ax1,['Observador ',modo{1},' - ',d.observadores(i).nombre]);
    ax2=nexttile(tl);plot(ax2,s.t_s,s.norma_error,'LineWidth',1.4);
       ylabel(ax2,'||x-xhat||');grid(ax2,'on');
    ax3=nexttile(tl);stairs(ax3,s.t_s(1:end-1),s.u_V,'LineWidth',1.4);
       ylabel(ax3,'u aplicada (V)');xlabel(ax3,'Tiempo (s)');grid(ax3,'on');
    exportgraphics(f,fullfile(destino,'figuras',[nombre,'.png']),'Resolution',300);
    close(f);
    if any(s.saturado)
       warning('%s: saturacion en %d muestras. La asignacion de polos lineal no describe completamente el ensayo.', ...
           nombre,nnz(s.saturado));
    end
  end
end
save(fullfile(destino,'lab7_diseno.mat'),'d','p');
fprintf('Generados %d conjuntos con diseño sobre MODELO IDENTIFICADO.\n',n);
fprintf('Las simulaciones no sustituyen una nueva validación experimental.\n');
