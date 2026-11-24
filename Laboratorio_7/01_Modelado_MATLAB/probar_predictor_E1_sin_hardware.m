% PROBAR_PREDICTOR_E1_SIN_HARDWARE
% Prueba guiada del modelo de control y auditoria ESTATICA de C.
% NO abre COM4, NO conecta Rigol, NO programa PSoC.
% IMPORTANTE: no prueba la ejecucion real de la ISR ni la HAL.
clear;clc;
fprintf('\n=== LABORATORIO 7 | PRUEBAS SIN HARDWARE ===\n');
Ts=0.002; N=256; ref=0.050;
A=[.87517332 0;-.21687099 .26359714];
B=[-.39838302;.05792937];
C=[0 1];
K=[2.15692217 6.87132640];
L=[-1.31786653;.43877046];
Nr=1.09474803;
umin=-.115;umax=.107;limiteFisico=.120;
pasoPos=.004*3.842612;
pasoNeg=.004*2.640105691;
nmaxPos=floor(limiteFisico/pasoPos);
nmaxNeg=floor(limiteFisico/pasoNeg);
assert(nmaxPos==7 && nmaxNeg==11,'Codigos maximos inesperados');
fprintf('1) PRUEBA DE CALCULO: inicial xhat=0, y=0, referencia=50 mV\n');
uIdeal=Nr*ref-K*[0;0];
assert(abs(uIdeal-.0547374015)<1e-7,'Control inicial incorrecto');
uLimit=max(umin,min(umax,uIdeal));
codigo=round(uLimit/pasoPos);
uDAC=codigo*pasoPos;
fprintf('   u ideal=%.3f mV, codigo DAC+=%d, u nominal=%.3f mV\n', ...
        uIdeal*1e3,codigo,uDAC*1e3);
assert(codigo==4,'Codigo DAC inicial distinto del esperado');
fprintf('   OK (calculo numerico, no medicion fisica)\n');

fprintf('2) PRUEBA DE LIMITES DAC con mandos extremos\n');
pedidos=[-10 -0.120 -0.115 -0.05 0 .05 .107 .120 10];
for i=1:numel(pedidos)
   cmd=max(umin,min(umax,pedidos(i)));
   if cmd>=0
       cod=min(nmaxPos,round(cmd/pasoPos));
       uAplicada=cod*pasoPos;
   else
       cod=min(nmaxNeg,round(-cmd/pasoNeg));
       uAplicada=-cod*pasoNeg;
   end
   fprintf('   Pedido %+8.2f mV -> DAC %+8.2f mV\n', ...
      pedidos(i)*1000,uAplicada*1000);
   assert(abs(uAplicada)<=limiteFisico+1e-12, ...
          'Se supero el limite de 120mV');
end
fprintf('   OK: ningun codigo matematico supero el limite\n');

fprintf('3) PRUEBA LOGICA DE SALIDA SEGURA\n');
% Esto comprueba la regla prevista, NO ejecuta main.c del PSoC.
errores=[0 1 2 4 8 16 32];
for i=1:numel(errores)
  f=errores(i);
  uPropuesto=.05;
  if f~=0, uDespues=0; parada=true;
  else, uDespues=uPropuesto; parada=false;
  end
  if f~=0, assert(parada && uDespues==0);end
end
fprintf('   OK: modelo de regla de parada para cada bandera\n');

fprintf('4) AUDITORIA DE TEXTO del main.c ACTIVO (sin ejecutarlo)\n');
raiz=fullfile(fileparts(mfilename('fullpath')),'..','02_Firmware_PSoC_5LP',...
   'Preparacion_E1_Alternativo');
% Primero auditar la PROPUESTA versionada, cuya ruta SI existe en Git.
% No confundirla con el proyecto compilado dentro de PSoC Creator:
% este puede estar fuera del arbol versionado o excluido por .gitignore.
archivo=fullfile(raiz,'Propuesta','main.c');
cfg=fullfile(raiz,'Propuesta','lab7_config.h');
assert(isfile(archivo)&&isfile(cfg), ...
    'No se hallaron los dos archivos de Propuesta; revisar git pull.');
fprintf('   Fuente revisada (NO necesariamente el firmware compilado):\\n');
fprintf('   %s\\n',archivo);
fprintf('   %s\\n',cfg);
codigoC=fileread(archivo);config=fileread(cfg);
assert(contains(codigoC,'-1.31786653f') && ...
       contains(codigoC,'0.43877046f'), ...
       'Ganancias E1 alternativas no encontradas en main.c.');
assert(contains(codigoC,'Lab5HardwareZeroOutput()'), ...
       'No se encontro funcion de salida a cero.');
assert(contains(codigoC,'F_LIMITE') && ...
       contains(codigoC,'LAB7_U_LIMITE_FISICO_V'), ...
       'No se encontro comprobacion del limite DAC.');
assert(contains(config,'LAB7_MODO_PREDICCION'), ...
       'No se encontro definicion del modo predictor.');
fprintf('   OK: cadenas clave en PROPUESTA. No verifica el proyecto compilado.\n');
fprintf('\nRESULTADO: 4 pruebas basicas OK. No programar placa solo con esto.\n');
fprintf('Pendiente: pruebas dinamicas del C compilado y protecciones en banco.\n');
