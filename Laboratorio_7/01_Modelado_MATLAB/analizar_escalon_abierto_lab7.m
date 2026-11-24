% ANALIZAR_ESCALON_ABIERTO_LAB7
% Analiza el ULTIMO ensayo UART ABIERTO guardado por MATLAB.
% No accede al hardware ni modifica ADC/DAC/firmware.
% Solo valores fisicos medidos del ADC y mando NOMINAL estimado del DAC.
clearvars; clc;

carpetaCodigo = fileparts(mfilename('fullpath'));
carpetaEnsayos = fullfile(carpetaCodigo, '..', '04_Ensayos');
carpetas = dir(fullfile(carpetaEnsayos, 'Lab7_UART_*'));
carpetas = carpetas([carpetas.isdir]);
assert(~isempty(carpetas), 'No hay carpetas Lab7_UART_* en 04_Ensayos.');

% Elegir el ensayo ABIERTO mas reciente con un pulso de mando real en CSV
[~, orden] = sort(string({carpetas.name}), 'descend');
archivo = '';
for j = orden
    candidato = fullfile(carpetas(j).folder, carpetas(j).name, 'monitor_lab7.csv');
    if ~isfile(candidato), continue; end
    datosPrueba = readtable(candidato);
    if ismember('u_solicitada_mV',datosPrueba.Properties.VariableNames) && ...
       any(datosPrueba.u_solicitada_mV > 0) && height(datosPrueba) >= 128
        archivo = candidato;
        break
    end
end
assert(~isempty(archivo), 'No se encontro un ensayo ABIERTO completo con pulso.');
T = readtable(archivo);

campos = {'t_us','y_rel_mV','u_solicitada_mV', ...
          'u_nominal_mV','flags','intervalo_us'};
assert(all(ismember(campos,T.Properties.VariableNames)), ...
       'El archivo CSV no tiene todas las columnas esperadas.');

t_ms = double(T.t_us(:))/1000;
y_mV = double(T.y_rel_mV(:));
u_mV = double(T.u_nominal_mV(:));
usol_mV = double(T.u_solicitada_mV(:));
flags = double(T.flags(:));
Ts = median(diff(t_ms))/1000;
N = numel(t_ms);
assert(all(isfinite(t_ms)) && all(diff(t_ms)>0));
indOn = find(usol_mV>0,1,'first');
indUlt = find(usol_mV>0,1,'last');
assert(~isempty(indOn) && indUlt < N, 'No se identifica el pulso completo.');
tOn = t_ms(indOn); tOff = t_ms(indUlt+1);
dur_ms = tOff-tOn;

% Ventanas sin transitorios, con estadistica robusta ante cuantizacion
previo = t_ms >= max(t_ms(1),tOn-40) & t_ms <= (tOn-12);
meseta = t_ms >= (tOff-0.35*dur_ms) & t_ms <= (tOff-2*Ts*1000);
assert(nnz(previo)>=5 && nnz(meseta)>=5,'Ventanas insuficientes.');
u0 = median(u_mV(previo)); u1 = median(u_mV(meseta));
y0 = median(y_mV(previo)); y1 = median(y_mV(meseta));
du = u1-u0; dy = y1-y0;
assert(abs(du)>1e-6,'No se detecto un cambio de mando nominal.');

Kaparente = dy/du;
Knominal = 1.018560434586;
% Antecedente identificado del Laboratorio 5 (solo comparacion)
Klab5 = 1.002941;
tauLab5 = [0.00906915,0.000774399];
tauNom = [0.015,0.0015];

% El DAC se registra como mando NOMINAL; aun falta medir fisicamente J5.
% Se reconstruye una simulacion ZOH con el mismo pulso almacenado en UART.
tmodelo = (0:N-1)'*Ts;
entrada_V = (u_mV-u0)/1000;
Gnom = tf(Knominal,conv([tauNom(1) 1],[tauNom(2) 1]));
G5 = tf(Klab5,conv([tauLab5(1) 1],[tauLab5(2) 1]));
yNom_mV = 1000*lsim(c2d(Gnom,Ts,'zoh'),entrada_V,tmodelo);
yLab5_mV = 1000*lsim(c2d(G5,Ts,'zoh'),entrada_V,tmodelo);
yDelta = y_mV-y0;
rmseNom = sqrt(mean((yDelta-yNom_mV).^2));
rmseLab5 = sqrt(mean((yDelta-yLab5_mV).^2));

fprintf('\nLAB7 — PRIMER ESCALON ABIERTO (UART)\n');
fprintf('Archivo: %s\n',archivo);
fprintf('Muestras: %d; Ts mediano: %.4f ms\n',N,1000*Ts);
fprintf('Pulso desde %.3f hasta %.3f ms; duracion %.3f ms\n',tOn,tOff,dur_ms);
fprintf('u0 nominal %.3f mV, u1 nominal %.3f mV, Delta u %.3f mV\n',u0,u1,du);
fprintf('y0 %.3f mV, y1 %.3f mV, Delta y %.3f mV\n',y0,y1,dy);
fprintf('Ganancia aparente (ADC / DAC nominal): %.5f V/V\n',Kaparente);
fprintf('Ganancia nominal esquema: %.5f V/V\n',Knominal);
fprintf('Desviacion aparente frente nominal: %.2f %%\n',100*(Kaparente/Knominal-1));
fprintf('RMSE nominal %.3f mV; RMSE antecedente Lab5 %.3f mV\n',rmseNom,rmseLab5);
fprintf('Filas con flags distintos de cero: %d\n',nnz(flags));
fprintf('ADVERTENCIA: K aparente NO es ganancia fisica final; falta medir Delta V J5 con Rigol.\n');

fig = figure('Name','Lab7 — Ensayo abierto: contraste de modelos','Color','w');
tl = tiledlayout(fig,2,1,'TileSpacing','compact');
nexttile(tl);
stairs(t_ms,usol_mV,'--','LineWidth',1.1); hold on;
stairs(t_ms,u_mV,'LineWidth',1.3);
ylabel('Mando (mV)');grid on;
legend('Solicitado','DAC nominal','Location','best');
title('Pulso aplicado en modo abierto');
nexttile(tl);
stairs(t_ms,yDelta,'LineWidth',1.2);hold on;
plot(tmodelo*1000,yNom_mV,'LineWidth',1.5);
plot(tmodelo*1000,yLab5_mV,'LineWidth',1.5);
xlabel('Tiempo (ms)');ylabel('Cambio de salida (mV)');grid on;
legend('ADC real, corregido por offset', ...
       'Modelo nominal de la guia','Modelo identificado Lab5','Location','best');
title('Comparacion experimental frente a dos modelos (mando DAC nominal)');
sgtitle('Laboratorio 7 — Un unico ensayo abierto, sin reajustar calibraciones');

carpetaSalida = fileparts(archivo);
exportgraphics(fig, fullfile(carpetaSalida,'comparacion_modelos_abierto.png'), ...
               'Resolution',180);
resumen = table(N,Ts,tOn,tOff,du,dy,Kaparente,Knominal,rmseNom,rmseLab5,nnz(flags), ...
'VariableNames',{'N_muestras','Ts_s','t_inicio_ms','t_fin_ms', ...
'delta_u_nominal_mV','delta_y_adc_mV','K_aparente','K_nominal', ...
'rmse_nominal_mV','rmse_Lab5_mV','filas_con_flags'});
writetable(resumen,fullfile(carpetaSalida,'resumen_escalon_abierto.csv'));
fprintf('Graficas y resumen exportados a: %s\n',carpetaSalida);
