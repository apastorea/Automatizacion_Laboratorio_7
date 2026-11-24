% ANALIZAR_PREDICTOR_E1_EXPERIMENTAL_LAB7
% Lee SOLO una captura PREDICCION valida del sistema sincronizado.
% Produce 4 graficas individuales segun categorias del informe Luis Morel
% y estadisticas de seguridad. Nunca modifica firmware/hardware.
clear;clc;
carpeta=fileparts(mfilename('fullpath'));
root=fullfile(carpeta,'..','04_Ensayos','Capturas_Sincronizadas');
assert(isfolder(root),'No existe carpeta Capturas_Sincronizadas');
d=dir(root);d=d([d.isdir]);
d=d(~ismember({d.name},{'.','..'}));
[~,orden]=sort(string({d.name}),'descend');
fuente='';
for k=orden
    ruta=fullfile(d(k).folder,d(k).name);
    fm=fullfile(ruta,'metadatos.json');
    fu=fullfile(ruta,'psoc_uart.csv');
    if ~(isfile(fm)&&isfile(fu)),continue;end
    meta=jsondecode(fileread(fm));
    if ~isfield(meta,'modo_detectado')||~strcmp(meta.modo_detectado,'PREDICCION')
        continue;
    end
    % La validacion automatica previa basada en pulsos ABIERTO no decide
    % por si sola si el escalon cerrado es valido. Verificar con UART.
    fuente=ruta;break;
end
assert(~isempty(fuente),'Falta captura PREDICCION; no inventar datos');
T=readtable(fullfile(fuente,'psoc_uart.csv'));
assert(height(T)>=2,'Captura UART demasiado corta');
campos={'k','t_us','y_rel_mV','r_mV','u_nominal_mV', ...
        'xhat2_mV','flags','cpu_us','intervalo_us','dac_pos','dac_neg'};
assert(all(ismember(campos,T.Properties.VariableNames)), ...
       'CSV con columnas no esperadas');
fprintf('Carpeta fuente: %s\n',fuente);
fprintf('Muestras UART: %d (esperadas 256)\n',height(T));
fprintf('Flags no nulas: %d\n',nnz(T.flags~=0));
fprintf('Max CPU: %d us, Ts mediana: %.2f us\n', ...
        max(T.cpu_us),median(T.intervalo_us(2:end)));
fprintf('Maximo DAC nominal: %.3f mV\n',max(abs(T.u_nominal_mV)));
fprintf('Codigos DAC maximos: +%d; -%d\n',max(T.dac_pos),max(T.dac_neg));
if height(T)~=256 || any(T.flags~=0) || ...
   any(abs(T.u_nominal_mV)>120) || ...
   any(T.dac_pos>7) || any(T.dac_neg>11)
    warning(['Captura con fallos, incompleta o fuera de limites: ', ...
             'NO usar para afirmar control valido.']);
end
idx=(T.k>=32);
tiempo=T.t_us(idx)/1000;
y=T.y_rel_mV(idx);
r=T.r_mV(idx);
u=T.u_nominal_mV(idx);
% En este modelo C=[0 1], la estimacion observable es xhat2.
yh=T.xhat2_mV(idx);
e=y-yh;
n=numel(tiempo);
fprintf('Post-pretrigger: %d muestras\n',n);
out=fullfile(carpeta,'..','05_Resultados','figuras','Predictor_E1_Experimental');
if ~isfolder(out),mkdir(out);end
names={'01_respuesta','02_control','03_salida_estimacion','04_error_salida'};
for j=1:4
    fig=figure('Visible','off','Color','w');
    switch j
        case 1
            stairs(tiempo,y,'LineWidth',1.2);hold on;
            stairs(tiempo,r,'--','LineWidth',1.3);
            ylabel('Salida y / referencia r (mV)');
            legend('y[k] de ADC','r[k]','Location','best');
            title('EXPERIMENTAL - Predictor E1: respuesta');
        case 2
            stairs(tiempo,u,'LineWidth',1.2);
            ylabel('u DAC nominal (mV)');
            title('EXPERIMENTAL - Predictor E1: accion de control');
        case 3
            stairs(tiempo,y,'LineWidth',1.2);hold on;
            stairs(tiempo,yh,'--','LineWidth',1.3);
            ylabel('Tension (mV)');
            legend('y[k] medido','yhat[k]=xhat2[k]','Location','best');
            title('EXPERIMENTAL - Predictor E1: salida y estimacion');
        case 4
            stairs(tiempo,e,'LineWidth',1.2);
            ylabel('e_y=y-yhat (mV)');
            title('EXPERIMENTAL - Predictor E1: error observable');
    end
    xlabel('Tiempo (ms)');grid on;
    exportgraphics(fig,fullfile(out,[names{j} '.png']),'Resolution',220);
    close(fig);
end
resumen=table(string(fuente),height(T),nnz(T.flags~=0),max(T.cpu_us), ...
   median(T.intervalo_us(2:end)),max(abs(T.u_nominal_mV)), ...
   sqrt(mean(e.^2)),mean(y(max(1,n-49):n)), ...
   'VariableNames',{'fuente','muestras','errores','cpu_max_us', ...
   'Ts_mediana_us','u_max_mV','error_y_rms_mV','y_cola_promedio_mV'});
writetable(resumen,fullfile(out,'metricas_predictor_E1_exp.csv'));
disp(resumen);
fprintf('Figuras generadas en %s\n',out);
fprintf(['Los datos provienen de UART. No son CH1/CH2 medidos; ', ...
         'comprobar el PNG y los CSV Rigol por separado.\n']);
