% COMPARAR_E1_ORIGINAL_Y_REDISENADO_LAB7
% Compara los polos E1 del informe original con una ALTERNATIVA.
% Datos de planta: modelo identificado Lab5; el controlador sigue siendo
% el diseñado con el modelo nominal. SIN programar PSoC ni modificar
% modelo_lab7.m o las cuatro simulaciones originales.
% Escenarios con ruido 0 y 10 mV RMS HIPOTETICO sobre la salida de la
% planta; la cuantizacion es aproximada segun antecedentes Lab5.
% La respuesta es a escalon de referencia 50mV en t=64ms, NO pulso abierto.
clear; clc; rng(7);
p=modelo_lab7("nominal");
d=disenar_lab7(p);
Ts=p.Ts_s; N=256;
A=d.A; B=d.B; C=d.C; K=d.K; Nr=d.Nr;
% Misma realizacion fisica equivalente usada en el chequeo de robustez:
a=-p.F(2,1);
t1=.00906915; t2=.000774399; K5=1.002941;
F5=[-1/t1,0;-a,-1/t2];
G5=[-K5/(a*t1*t2);0];
[Ap,Bp,Cp,~]=ssdata(c2d(ss(F5,G5,[0,1],0),Ts,'zoh'));

polos={ [0.40+0.25i,0.40-0.25i], ...
        [0.35+0.10i,0.35-0.10i] };
nombres=["E1 original","E1 alternativo"];
Lpred=cell(2,1);Lactual=cell(2,1);
for i=1:2
    Lpred{i}=place(A',C',polos{i}).';
    Lactual{i}=place(A',(C*A)',polos{i}).';
end
disp('GANANCIAS NUEVAS (solo para analisis, NO firmware):');
fprintf('Lpred E1 alternativo: [%.9f; %.9f]\n',Lpred{2});
fprintf('Lactual E1 alternativo: [%.9f; %.9f]\n',Lactual{2});

% REVISION 2 (2026-11-24): recorte del CODIGO DAC tras redondeo.
% Cuantizacion aproximada desde antecedentes del Lab5:
deltaADC=0.00114/0.210251951; % V de salida por cuenta ADC
deltaDACpos=0.004*3.842612;    % V en J5 por codigo DAC+
deltaDACneg=0.004*2.640105691;% V en J5 por codigo DAC-
limiteU=0.120;
% No redondear el DAC fuera del limite fisico. Codigos maximos admitidos:
codigoMaxPos=floor(limiteU/deltaDACpos);
codigoMaxNeg=floor(limiteU/deltaDACneg);
fprintf('DAC positivo maximo: %d codigos (%.3f mV)\n', ...
    codigoMaxPos,1000*codigoMaxPos*deltaDACpos);
fprintf('DAC negativo maximo: %d codigos (%.3f mV)\n', ...
    codigoMaxNeg,1000*codigoMaxNeg*deltaDACneg);
ruidos=[0,0.010];  % V RMS salida hipotética, NO medida ADC
fila=0;
for i=1:2
    for m=1:2
        for nr=1:2
            fila=fila+1;
            esActual=(m==2);
            if esActual
                modo="actual";L=Lactual{i};
            else
                modo="prediccion";L=Lpred{i};
            end
            rng(7);
            perturbacion=ruidos(nr)*randn(N,1);
            x=zeros(2,1);xh_mem=zeros(2,1);
            ys=zeros(N,1);uap=zeros(N,1);sat=0;satCodigo=0;
            for k=1:N
                y=Cp*x;
                yCuant=deltaADC*round((y+perturbacion(k))/deltaADC);
                innovacion=yCuant-C*xh_mem;
                if esActual, xutil=xh_mem+L*innovacion;
                else, xutil=xh_mem;
                end
                referencia=0.05*(k>=33); % k=33 => t=64 ms
                uIdeal=Nr*referencia-K*xutil;
                uPedida=min(limiteU,max(-limiteU,uIdeal));
                sat=sat+(abs(uIdeal-uPedida)>1e-9);
                if uPedida>=0
                    codigoDeseado=round(uPedida/deltaDACpos);
                    codigoAplicado=min(codigoMaxPos,max(0,codigoDeseado));
                    uReal=deltaDACpos*codigoAplicado;
                else
                    codigoDeseado=round(-uPedida/deltaDACneg);
                    codigoAplicado=min(codigoMaxNeg,max(0,codigoDeseado));
                    uReal=-deltaDACneg*codigoAplicado;
                end
                satCodigo=satCodigo+(codigoDeseado>codigoAplicado);
                assert(abs(uReal)<=limiteU+1e-12, ...
                    'DAC simulado fuera de limite fisico.');
                xh_mem=A*xutil+B*uReal;
                if ~esActual
                    xh_mem=xh_mem+L*innovacion;
                end
                x=Ap*x+Bp*uReal;
                ys(k)=y;uap(k)=uReal;
            end
            if m==1, modoA="Predicción";
            else, modoA="Actual";
            end
            caso(fila,1)=nombres(i)+" / "+modoA; %#ok<SAGROW>
            ruido_RMS_mV(fila,1)=ruidos(nr)*1000; %#ok<SAGROW>
            salida_max_mV(fila,1)=max(abs(ys))*1000; %#ok<SAGROW>
            salida_cola_mV(fila,1)=mean(ys(end-49:end))*1000; %#ok<SAGROW>
            control_max_mV(fila,1)=max(abs(uap))*1000; %#ok<SAGROW>
            saturaciones(fila,1)=sat; %#ok<SAGROW>
            saturaciones_codigo_DAC(fila,1)=satCodigo; %#ok<SAGROW>
            respuesta{i,m,nr}=ys; %#ok<SAGROW>
        end
    end
end
T=table(caso,ruido_RMS_mV,salida_max_mV,salida_cola_mV, ...
   control_max_mV,saturaciones,saturaciones_codigo_DAC);
disp(T);

destino=fullfile(fileparts(mfilename('fullpath')),'..','05_Resultados');
if ~isfolder(destino),mkdir(destino);end
writetable(T,fullfile(destino,'comparacion_E1_original_alternativo.csv'));
fig=figure('Name','Lab7 - estudio de E1 alternativo','Color','w');
t=(0:N-1)*Ts*1000;
tl=tiledlayout(fig,2,2,'TileSpacing','compact');
for m=1:2
    for nr=1:2
        nexttile(tl,(nr-1)*2+m);
        plot(t,respuesta{1,m,nr}*1000,'LineWidth',1.1);hold on;
        plot(t,respuesta{2,m,nr}*1000,'LineWidth',1.4);
        plot(t,50*(t>=64),'k--','LineWidth',.9);
        grid on; xlabel('Tiempo (ms)'); ylabel('Salida (mV)');
        if m==1, etiqueta='Predictor';else, etiqueta='Actual';end
        title(sprintf('%s - ruido hipotético %.0f mV RMS', ...
            etiqueta,ruidos(nr)*1000));
        legend('E1 original','E1 alternativo','Referencia','Location','best');
    end
end
sgtitle('Planta identificada Lab5 + ADC/DAC cuantizados (SIMULACIÓN)');
carpetaFig=fullfile(destino,'figuras');
if ~isfolder(carpetaFig),mkdir(carpetaFig);end
exportgraphics(fig,fullfile(carpetaFig, ...
   'comparacion_E1_original_alternativo.png'),'Resolution',220);
fprintf('\nATENCION: SIMULACION REVISION 2, con limite fisico DAC; no comparar\n');
fprintf('directamente con capturas MATLAB anteriores sin esta correccion.\n');
fprintf('No es una medicion del hardware ni garantiza seguridad fisica.\n');
fprintf('Antes de cualquier control cerrado se requieren revisar codigo PSoC,\n');
fprintf('limites fisicos de DAC, protecciones y condiciones de lazo.\n');
