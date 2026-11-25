% EVALUAR_ROBUSTEZ_OBSERVADORES_LAB7
% ANALISIS LINEAL ABIERTO A COMPROBACION: control por estados estimados.
% Compara estabilidad de los 4 diseños al reemplazar la planta nominal
% por la transferencia identificada en el Laboratorio 5.
% NO cambia el firmware, no autoriza activar lazo cerrado.
% Requiere Control System Toolbox (ss, c2d, ssdata).
clear; clc;
p=modelo_lab7("nominal");
d=disenar_lab7(p);
Ts=p.Ts_s;

% Transferencia identificada previamente (Lab5), sin refit con datos Lab7
K5=1.002941;
tau1_5=0.00906915;
tau2_5=0.000774399;
% Realizacion de 2 estados que conserva exactamente esta transferencia;
% el estado intermedio NO se identifica como magnitud fisica independiente.
acoplamiento=-p.F(2,1);
F5=[-1/tau1_5 0; -acoplamiento -1/tau2_5];
G5=[-K5/(acoplamiento*tau1_5*tau2_5);0];
H5=[0 1]; J5=0;
[Ap,Bp,Cp,~]=ssdata(c2d(ss(F5,G5,H5,J5),Ts,'zoh'));

% Matrices del diseño nominal
A=d.A; B=d.B; C=d.C; K=d.K; I=eye(2);
n=2*numel(d.observadores);
caso=strings(n,1);
rho_nominal=zeros(n,1);
rho_identificado_lab5=zeros(n,1);
polo_critico_identificado=strings(n,1);
fila=0;
for i=1:numel(d.observadores)
    Lp=d.observadores(i).L_pred;
    La=d.observadores(i).L_actual;
    for variante={'prediccion','actual'}
        modo=variante{1};
        fila=fila+1;
        caso(fila)=string(sprintf('%s_E%d',modo,i));
        if strcmp(modo,'prediccion')
            % Estados ampliados [x_planta; xhat_prevista]
            MN=[A, -B*K; Lp*C, A-B*K-Lp*C];
            MI=[Ap, -Bp*K; Lp*Cp, A-B*K-Lp*C];
        else
            % Correccion ACTUAL antes de calcular la accion u[k].
            % xcor=(I-La*C)*xhat + La*Cp*x
            E=I-La*C;
            MN=[A-B*K*La*C, -B*K*E; ...
                (A-B*K)*La*C,(A-B*K)*E];
            MI=[Ap-Bp*K*La*Cp, -Bp*K*E; ...
                (A-B*K)*La*Cp,(A-B*K)*E];
        end
        eN=eig(MN);
        eI=eig(MI);
        rho_nominal(fila)=max(abs(eN));
        rho_identificado_lab5(fila)=max(abs(eI));
        [~,im]=max(abs(eI));
        polo_critico_identificado(fila)=string(sprintf('%.6f%+.6fi', ...
                            real(eI(im)),imag(eI(im))));
        fprintf('%-16s nominal rho=%.6f; identificado rho=%.6f; %s\n', ...
            char(caso(fila)),rho_nominal(fila),rho_identificado_lab5(fila), ...
            char(polo_critico_identificado(fila)));
    end
end
apto_lineal_identificado=rho_identificado_lab5<1;
T=table(caso,rho_nominal,rho_identificado_lab5, ...
        apto_lineal_identificado,polo_critico_identificado);
disp(T);
destino=fullfile(fileparts(mfilename('fullpath')),'..','05_Resultados');
if ~isfolder(destino), mkdir(destino);end
writetable(T,fullfile(destino,'robustez_observadores_lab7.csv'));

f=figure('Color','w','Name','Robustez lineal observadores Lab7');
bar(categorical(caso),[rho_nominal,rho_identificado_lab5]);
hold on;yline(1,'--','Limite estabilidad','LineWidth',1.2);
ylabel('Radio espectral del sistema aumentado');
legend('Planta nominal','Planta identificada Lab5','Location','best');
title('Controlador y observador sobre el mismo modelo de planta');
grid on;
carpetaFig=fullfile(destino,'figuras');
if ~isfolder(carpetaFig),mkdir(carpetaFig);end
exportgraphics(f,fullfile(carpetaFig,'robustez_lineal_observadores_lab7.png'), ...
               'Resolution',220);

fprintf('\nCRITERIO: radio espectral < 1 => estabilidad ASINTOTICA LINEAL discreta.\n');
if any(~apto_lineal_identificado)
    warning(['Hay diseños NO ESTABLES con la planta Lab5 identificada. ', ...
             'NO habilitar lazo cerrado en esas variantes.']);
end
fprintf(['No contempla saturacion, ruido, cuantizacion ADC/DAC ni cambios ', ...
         'de topologia. No es una autorizacion de ensayo fisico.\n']);
