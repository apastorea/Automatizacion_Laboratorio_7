function s = simular_lab7(d,p,idx,modo)
%SIMULAR_LAB7 Simulacion discreta de planta y observador.
% modo: 'prediccion' o 'actual'. Los estados de control siempre son ESTIMADOS.
% Los limites de la accion se modelan sobre el u REALMENTE aplicado.
arguments
    d struct
    p struct
    idx (1,1) double {mustBeInteger,mustBePositive}
    modo (1,:) char
end
assert(any(strcmp(modo,{'prediccion','actual'})), 'Modo invalido.');
o=d.observadores(idx);
N=round(p.t_sim_s/p.Ts_s)+1;
t=(0:N-1)*p.Ts_s;
x=zeros(2,N);x(:,1)=p.x0(:);
xh=zeros(2,N); % xh(:,k) = estimacion utilizada en control
xh_mem=p.xestimado0(:);
y=zeros(1,N);r=zeros(1,N);u=zeros(1,N-1);
u_ideal=zeros(1,N-1);innovacion=zeros(1,N-1);
saturado=false(1,N-1);
for k=1:N-1
    y(k)=d.C*x(:,k)+d.D*0;
    r(k)=p.referencia_V*(t(k)>=p.referencia_inicio_s);
    if strcmp(modo,'actual')
        % Corregir estimacion previa utilizando la medicion y[k] ACTUAL.
        innovacion(k)=y(k)-d.C*xh_mem;
        xh(:,k)=xh_mem+o.L_actual*innovacion(k);
    else
        % El predictor usa estimacion calculada en la muestra anterior.
        xh(:,k)=xh_mem;
        innovacion(k)=y(k)-d.C*xh_mem;
    end
    u_ideal(k)=-d.K*xh(:,k)+d.Nr*r(k);
    u(k)=min(p.u_max_V,max(p.u_min_V,u_ideal(k)));
    saturado(k)=abs(u(k)-u_ideal(k))>1e-9;
    x(:,k+1)=d.A*x(:,k)+d.B*u(k);
    if strcmp(modo,'actual')
        % Prediccion para la siguiente muestra DESPUES del control.
        xh_mem=d.A*xh(:,k)+d.B*u(k);
    else
        % La innovacion y[k] modifica la estimacion de la muestra k+1.
        xh_mem=d.A*xh(:,k)+d.B*u(k)+o.L_pred*innovacion(k);
    end
end
y(N)=d.C*x(:,N);
r(N)=p.referencia_V*(t(N)>=p.referencia_inicio_s);
if strcmp(modo,'actual')
    xh(:,N)=xh_mem+o.L_actual*(y(N)-d.C*xh_mem);
else
    xh(:,N)=xh_mem;
end
s=struct('t_s',t,'x',x,'x_estimado',xh,'y_V',y,'r_V',r, ...
         'u_V',u,'u_ideal_V',u_ideal,'innovacion_V',innovacion, ...
         'norma_error',vecnorm(x-xh,2,1),'saturado',saturado, ...
         'modo',modo,'caso',o.nombre);
end
