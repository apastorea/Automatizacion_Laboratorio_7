% SIMULAR_NO_IDEAL_OBSERVADORES_LAB7
% Simulacion de PRUEBA con cuantizacion DAC/ADC y ruido hipotetico.
% No usa hardware; NO valida ni autoriza control fisico.
% Datos identificados Lab5: K=1.002941, tau1=9.06915ms, tau2=0.774399ms.
% Para el ruido se usa escenario de estres de 10mV RMS en salida, NO
% es una estimacion medida en la entrada del ADC del PSoC.
clear;clc; rng(7);
p=modelo_lab7("nominal");d=disenar_lab7(p);
Ts=p.Ts_s; N=256;
K5=1.002941; t1=.00906915;t2=.000774399;
a=-p.F(2,1);
F5=[-1/t1 0;-a -1/t2];
G5=[-K5/(a*t1*t2);0];
[Ap,Bp,Cp,~]=ssdata(c2d(ss(F5,G5,[0 1],0),Ts,'zoh'));
nivelesRuido=[0 0.010]; % V RMS salida, solo escenario simulado
incrementoADCSalida_V=0.00114/0.210251951; % aprox. 5.42mV/salida
qPos=0.004*3.842612; % voltios de J5 por codigo de DAC positivo
qNeg=0.004*2.640105691; % magnitud por codigo DAC negativo
caso=strings(8,1);
ruido_RMS_V=zeros(8,1);
maxAbsU_V=zeros(8,1);
maxAbsY_V=zeros(8,1);
rmsY_cola_V=zeros(8,1);
promY_cola_V=zeros(8,1);
nSaturaciones=zeros(8,1);
fila=0;
for i=1:2
    for celda={'prediccion','actual'}
        modo=celda{1};
        for nr=1:numel(nivelesRuido)
            fila=fila+1;
            caso(fila)=string(sprintf('%s_E%d',modo,i));
            ruido_RMS_V(fila)=nivelesRuido(nr);
            rng(7); ruido=nivelesRuido(nr)*randn(N,1);
            x=zeros(2,1); mem=zeros(2,1);
            ylog=zeros(N,1); ulog=zeros(N,1); saturaciones=0;
            for k=1:N
                y=Cp*x;  % Planta identificada, sin ruido
                yMedida=round((y+ruido(k))/incrementoADCSalida_V)*incrementoADCSalida_V;
                innovacion=yMedida-d.C*mem;
                if strcmp(modo,'actual')
                    utilizado=mem+d.observadores(i).L_actual*innovacion;
                else
                    utilizado=mem;
                end
                referencia=0;
                if k>=33, referencia=p.referencia_V; end % t=64ms
                uIdeal=d.Nr*referencia-d.K*utilizado;
                uPedida=min(.120,max(-.120,uIdeal));
                saturaciones=saturaciones+(abs(uIdeal-uPedida)>1e-8);
                if uPedida>=0
                    uAplicada=qPos*round(uPedida/qPos);
                else
                    uAplicada=-qNeg*round(-uPedida/qNeg);
                end
                % Replica la diferencia entre mando pedido y mando DAC.
                if strcmp(modo,'actual')
                    mem=d.A*utilizado+d.B*uAplicada;
                else
                    mem=d.A*utilizado+d.B*uAplicada+ ...
                        d.observadores(i).L_pred*innovacion;
                end
                x=Ap*x+Bp*uAplicada;
                ylog(k)=y;
                ulog(k)=uAplicada;
            end
            maxAbsU_V(fila)=max(abs(ulog));
            maxAbsY_V(fila)=max(abs(ylog));
            rmsY_cola_V(fila)=std(ylog(end-49:end));
            promY_cola_V(fila)=mean(ylog(end-49:end));
            nSaturaciones(fila)=saturaciones;
            if i==1 && nr==1
                f=figure('Color','w','Visible','off');
                tiledlayout(2,1);
                nexttile;stairs((0:N-1)*Ts*1e3,ylog*1e3);hold on;
                yline(p.referencia_V*1e3,'--');
                ylabel('Salida (mV)');grid on;title(['E1 ',modo],'Interpreter','none');
                nexttile;stairs((0:N-1)*Ts*1e3,ulog*1e3);
                ylabel('u DAC (mV)');xlabel('Tiempo (ms)');grid on;
                carpetaFig=fullfile(fileparts(mfilename('fullpath')),'..', ...
                    '05_Resultados','figuras');
                if ~isfolder(carpetaFig),mkdir(carpetaFig);end
                exportgraphics(f,fullfile(carpetaFig, ...
                    ['ensayo_no_ideal_' modo '_E1.png']),'Resolution',220);
                close(f);
            end
        end
    end
end
T=table(caso,ruido_RMS_V,maxAbsU_V,maxAbsY_V, ...
  rmsY_cola_V,promY_cola_V,nSaturaciones);
disp(T);
destino=fullfile(fileparts(mfilename('fullpath')),'..','05_Resultados');
if ~isfolder(destino),mkdir(destino);end
writetable(T,fullfile(destino,'simulacion_no_ideal_lab7.csv'));
fprintf(['ADVERTENCIA: esta simulacion supone una planta identificada, ', ...
         'una cuantizacion nominal y ruido hipotetico; NO es una ', ...
         'medicion ni una autorizacion para cerrar el lazo.\n']);
