% GENERAR_16_FIGURAS_LAB7
% Exporta 16 figuras separadas de SIMULACIONES (4 por caso).
% En nuestro modelo C=[0 1], y=x2; no se presenta x1 como salida medida.
% Requiere Control System Toolbox. No modifica firmware.
clear; clc;
carpeta=fileparts(mfilename('fullpath'));
p=modelo_lab7();
d=disenar_lab7(p);
destino=fullfile(carpeta,'..','05_Resultados','figuras','16_figuras_individuales');
if ~isfolder(destino), mkdir(destino); end
n=0;
for i=1:numel(d.observadores)
    for c={'prediccion','actual'}
        modo=c{1}; s=simular_lab7(d,p,i,modo); n=n+1;
        etiqueta=sprintf('%s_%s',modo,d.observadores(i).nombre);
        t=s.t_s*1000;
        yhat=d.C*s.x_estimado;
        eSalida=s.y_V-yhat;
        f=figure('Color','w','Visible','off');
        stairs(t,s.y_V,'LineWidth',1.5); hold on;
        stairs(t,s.r_V,'--','LineWidth',1.3); grid on;
        xlabel('Tiempo (ms)');ylabel('Tension (V)');
        legend('y[k]','r[k]','Location','best');
        title(['SIMULACION - Respuesta ',etiqueta],'Interpreter','none');
        exportgraphics(f,fullfile(destino,[etiqueta '_01_respuesta.png']),'Resolution',220);close(f);
        f=figure('Color','w','Visible','off');
        stairs(t(1:end-1),s.u_V,'LineWidth',1.5);grid on;
        xlabel('Tiempo (ms)');ylabel('u aplicada (V)');
        title(['SIMULACION - Control ',etiqueta],'Interpreter','none');
        exportgraphics(f,fullfile(destino,[etiqueta '_02_control.png']),'Resolution',220);close(f);
        f=figure('Color','w','Visible','off');
        stairs(t,s.y_V,'LineWidth',1.5);hold on;
        stairs(t,yhat,'--','LineWidth',1.3);grid on;
        xlabel('Tiempo (ms)');ylabel('Tension (V)');
        legend('y[k]=C x[k]','yhat[k]=C xhat[k]','Location','best');
        title(['SIMULACION - Estimacion ',etiqueta],'Interpreter','none');
        exportgraphics(f,fullfile(destino,[etiqueta '_03_estimacion.png']),'Resolution',220);close(f);
        f=figure('Color','w','Visible','off');
        stairs(t,eSalida,'LineWidth',1.5);grid on;
        xlabel('Tiempo (ms)');ylabel('e_y=y-yhat (V)');
        title(['SIMULACION - Error ',etiqueta],'Interpreter','none');
        exportgraphics(f,fullfile(destino,[etiqueta '_04_error.png']),'Resolution',220);close(f);
        caso(n,1)=string(etiqueta); %#ok<SAGROW>
        e_rms(n,1)=sqrt(mean(eSalida.^2)); %#ok<SAGROW>
        e_max(n,1)=max(abs(eSalida)); %#ok<SAGROW>
        u_rms(n,1)=sqrt(mean(s.u_V.^2)); %#ok<SAGROW>
        u_min(n,1)=min(s.u_V); %#ok<SAGROW>
        u_max(n,1)=max(s.u_V); %#ok<SAGROW>
    end
end
T=table(caso,e_rms,e_max,u_rms,u_min,u_max);
writetable(T,fullfile(destino,'metricas_16_figuras_simuladas.csv'));
disp(T);
fprintf('Generadas %d figuras de SIMULACION en: %s\n',n*4,destino);
fprintf('Advertencia: condiciones iniciales t=0; NO hay reinicio de estimador a 16 ms.\n');
