% Reproducir comparacion de cuatro ensayos UART del Laboratorio 7
% Ejecutar desde la carpeta que contiene este .m y ../datos/originales/.
clear; clc; close all;
base = fileparts(mfilename('fullpath'));
claves = ["Pred_E1", "Act_E1", "Pred_E2", "Act_E2"];
leyendas = ["Predictor E1 alternativo", "Actual E1 alternativo", ...
            "Predictor E2 original", "Actual E2 original"];
resumen = table('Size',[4 6], 'VariableTypes',{'string','double','double','double','double','double'}, ...
    'VariableNames',{'Caso','Pico_mV','Sobrepasamiento_pct','Tp_ms','Media_final_mV','Error_final_pct'});
figure('Name','LAB7 cuatro observadores');hold on;grid on;
for i=1:numel(claves)
    f=fullfile(base,'..','datos','originales',claves(i)+'_UART.csv');
    D=readtable(f);
    j=find(D.r_mV>0,1,'first');
    [pico,ind]=max(D.y_rel_mV(j:end));ind=ind+j-1;
    media=mean(D.y_rel_mV(end-49:end));
    resumen.Caso(i)=leyendas(i);
    resumen.Pico_mV(i)=pico;
    resumen.Sobrepasamiento_pct(i)=100*(pico-50)/50;
    resumen.Tp_ms(i)=(D.t_us(ind)-D.t_us(j))/1000;
    resumen.Media_final_mV(i)=media;
    resumen.Error_final_pct(i)=100*(50-media)/50;
    stairs(D.t_us/1000,D.y_rel_mV,'LineWidth',1.2,'DisplayName',leyendas(i));
end
yline(50,'--','Referencia');xlim([55 170]);legend('Location','best');
xlabel('Tiempo (ms)');ylabel('Salida ADC (mV)');
disp(resumen);
