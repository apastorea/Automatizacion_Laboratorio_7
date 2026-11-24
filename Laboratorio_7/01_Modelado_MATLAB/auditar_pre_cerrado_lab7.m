% AUDITAR_PRE_CERRADO_LAB7
% Verifica por software matrices y ganancias de la plantilla PSoC vs MATLAB.
% No activa control cerrado ni escribe en el PSoC.
clear;clc;
p=modelo_lab7();
p.u_min_V=-.120;p.u_max_V=+.120;
d=disenar_lab7(p);
% Coeficientes del firmware de la plantilla Lab7.cydsn/main.c
A_fw=[.87517332 0;-.21687099 .26359714];
B_fw=[-.39838302;.05792937];
C_fw=[0 1];
K_fw=[2.15692217 6.87132640];
Nr_fw=1.09474803;
Lp_fw=[-1.32931421 -2.14809283;.33877046 .73877046];
La_fw=[-1.51891537 -2.45447706;.03551549 .78326191];
maxError=max([max(abs(d.A(:)-A_fw(:))),max(abs(d.B(:)-B_fw(:))),...
              max(abs(d.C(:)-C_fw(:))),max(abs(d.K(:)-K_fw(:))),...
              abs(d.Nr-Nr_fw)]);
for i=1:2
    maxError=max([maxError,max(abs(d.observadores(i).L_pred-Lp_fw(:,i))),...
              max(abs(d.observadores(i).L_actual-La_fw(:,i)))]);
end
fprintf('Maxima diferencia MATLAB/plantilla PSoC: %.3g\n',maxError);
assert(maxError<2e-5,'Coeficientes distintos: no habilitar control cerrado.');
fprintf('Polos de A-BK: ');disp(eig(d.A-d.B*d.K).');
for i=1:2
    fprintf('E%d predictor: ',i);disp(eig(d.A-d.observadores(i).L_pred*d.C).');
    fprintf('E%d actual: ',i);
    disp(eig((eye(2)-d.observadores(i).L_actual*d.C)*d.A).');
end
for i=1:2
    for c={'prediccion','actual'}
        s=simular_lab7(d,p,i,c{1});
        fprintf('%s E%d: max(|u|)=%.4f V, saturaciones=%d\n',...
            c{1},i,max(abs(s.u_V)),nnz(s.saturado));
    end
end
fprintf('Verificacion MATEMATICA nominal, no aprobacion de hardware real.\n');
