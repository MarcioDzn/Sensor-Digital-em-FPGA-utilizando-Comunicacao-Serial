<div align=center>

# Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial
</div>

## Breve descrição do problema:

Este repositório é o resultado do trabalho de uma equipe de estudantes para criar um protótipo de sistema IoT para monitorar a temperatura e umidade de ambientes usando uma plataforma FPGA. Como sensor, o projeto conta com o DHT11 que por sua vez é acoplado a FPGA Mercurio IV Devkit. Assim a FPGA implementa uma interface UART para receber, executar e responder a comandos enviados através de uma porta serial por um computador. Para que a interação com o computador seja possível, a equipe também desenvolveu um sistema de teste em C para enviar comandos e exibir respostas nos computadores. Será discriminado durante este relatório os conceitos envolvidos durante a construção do protótipo, bem como as decisões de projetos da equipe.

## Componentes da equipe: 
- Antonio Vitor Costa da Silva [avcsilva](https://github.com/avcsilva)
- Gabriel Costa Baptista [BaptistaGabriel](https://github.com/BaptistaGabriel)
- Luis Pereira de Carvalho [LuisBaiano](https://github.com/LuisBaiano)
- Márcio Roberto Fernandes dos Santos Lima [MarcioDzn](https://github.com/MarcioDzn)

<a name="ancora"></a>

## Indice:
1. [Requisitos do projeto](#ancoraRequisitos)
2. [Recursos utilizados](#ancoraRecursos)
3. [Protocolo](#ancoraProtocolo)
4. [Fluxograma geral](#ancoraFluxograma)
5. [Módulos utilizados](#ancoraModulos)
     - [UART](#ancoraUART)
     - [DHT11](#ancoraDHT11)
     - [Main State Machine](#ancoraMainStateMachine)
     - [Request Separator](#ancoraRequest)
     - [Instr Decoder](#ancoraInstr)
     - [Data Selector](#ancoraSelector)
     - [Packer](#ancoraPacker)
     - [Send Pc](#ancoraSend)
6. [Testes](#ancoraTestes)
7. [Interfaces em C](#ancoraC)
8. [Conclusão](#ancoraConclusao)

<a id="ancoraRequisitos"></a>

## Requisitos do projeto:

- Utilização do sensor DHT11.
- Implementação de uma interface de comunicação serial (UART).
- Desenvolvimento de um sistema de testes em linguagem C.
- Escrita do código do FPGA em linguagem Verilog.
- Garantia de modularidade para permitir a substituição de componentes na versão de produção conforme necessário.
- Capacidade de ler, interpretar e executar comandos provenientes do computador, bem como retornar respostas para os comandos.
- Os comandos devem ser compostos por palavras de 8 bits.
- As requisições e respostas com 2 bytes.

<a id="ancoraRecursos"></a>

## Recursos utilizados

- FPGA Mercurio IV Devkit - Cyclone IV EP4CE30F23
- Sensor de temperatura e umidade DHT11
- Quartus 20.1
- Verilog HDL
- Visual Studio Code

<a id="ancoraProtocolo"></a>

## Protocolo:

O protocolo de comunicação projetado para este projeto possui como base as duas tabelas a seguir, que representam, respectivamente, os comandos de requisição e de resposta. Os códigos de endereço de sensor foram planejados para serem representados em códigos hexadecimais de 0x00 a 0x1F, podendo assim simbolizar até 32 sensores diferentes.

</br>
<div align=center>

 Comandos de requisição. | Descrição do comando                            |   | Comandos de resposta. | Descrição                                                            |
-------------------------|-------------------------------------------------|---|-----------------------|----------------------------------------------------------------------|
 0x00                    | Solicita a situação atual do sensor             |   | 0x1F                  | Sensor com problema                                                  | 
 0x01                    | Solicita a medida de temperatura atual          |   | 0x07                  | Sensor funcionando normalmente                                       | 
 0x02                    | Solicita a medida de umidade atual              |   | 0x08                  | Medida de umidade                                                    | 
 0x03                    | Ativa sensoriamento contínuo de temperatura     |   | 0x09                  | Medida de temperatura                                                | 
 0x04                    | Ativa sensoriamento contínuo de umidade         |   | 0x0A                  | Confirmação de desativação de sensoriamento contínuo de temperatura  | 
 0x05                    | Desativa sensoriamento contínuo de temperatura  |   | 0x0B                  | Confirmação de desativação de sensoriamento contínuo  de umidade     | 
 0x06                    | Desativa sensoriamento contínuo  de umidade     |   | 0xFF                  | Resposta nula (SUPER_IDLE)                                           | 

</div>
</br>

#### Todo o processo de comunicação entre o computador e a FPGA se baseia no envio sempre de 2 bytes. Portanto analisando individualmente:
  
### Envio Computador -> FPGA
- Enviados 2 bytes, em ordem: 1 byte de instrução + 1 byte de endereço.
- Exemplo: (requisição de status): [0x00], [0x00].


### Envio FPGA -> Computador
- Enviados inicialmente 2 bytes de retorno, que representarão a resposta de dados a ser enviada pela FPGA (tabela de comandos de resposta.
- Enviados, se necessário, 2 bytes referentes aos dados coletados pela FPGA através do DHT11 (exemplo: medida de temperatura ou de umidade).
- Requisições como a observação do status de funcionamento ou desativação de sensoriamento contínuo não necessitam de bytes de dados. Portanto, os últimos 2 bytes serão os comandos de resposta mais uma vez.
     - Exemplo 1 (resposta de status): [0x07], [0x07], [0x07], [0x07].
     - Exemplo 2 (resposta de medida de temperatura): [0x09], [0x09], [Medida do DHT11: Inteiro], [Medida do DHT11: Fracionário].


<a id="ancoraFluxograma"></a>

## Fluxograma geral:
<div align=center>

![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/4b8a7a81-7b3c-4c92-ab3f-c270d1367f4f)
</br>
</br>
Figura 1 - Fluxograma geral do sistema
</br>
</br>

</div>

- De forma resumida, o projeto funciona sob uma máquina de estados que serve de módulo controlador para cada etapa do processo, o qual possui 4 estados: espera (IDLE), coleta (RECEIVE), empacotamento (ORGANIZE) e envio (SEND). 
- De início, com a máquina em estado de espera, devem ser recebidos do computador, por meio da UART, os 2 bytes que se referem à requisição e ao endereço do sensor. Recebidos estes, a máquina passa para o estado de coleta e lá permanece até que o módulo DHT11 determine que sua leitura foi finalizada. Após a coleta, a máquina em estado de empacotamento ordena que sejam organizados os dados que deverão ser enviados de volta ao computador mais posteriormente. Com os dados devidamente selecionados e organizados, a máquina entra em estado de envio, e não retorna ao estado de espera até que todo o processo de envio tenha sido finalizado corretamente. A figura 1 representa, de forma simplificada e resumida, o caminho dos dados no funcionamento do projeto.


<a id="ancoraModulos"></a>

## Módulos utilizados:

<a id="ancoraUART"></a>

### **UART:**
O módulo UART lida com a comunicação serial entre a FPGA e o computador, bem como entre o computador e a placa. Este é composto por três submódulos, nos subtópicos seguintes é possivél observar cada um deles:

#### Gerador da taxa de transmissão (`baud_rate_gen`): 
- Este módulo é responsável pela geração da taxa de transmissão para a comunicação serial. Ele recebe o sinal de clock de 50 MHz (`clk_50m`) nativo da FPGA e gera os sinais `rxclk_en` e `txclk_en` que são usados para habilitar os clocks de recepção e transmissão, respectivamente. 

#### Transmissor: 
- O módulo do transmissor (`transmitter`) é responsável por enviar dados da FPGA para o dispositivo externo. Ele recebe os dados paralelos de entrada (`din`), um sinal de escrita habilitado (`wr_en`), o sinal de clock de 50MHz (`clk_50m`), e o sinal de habilitação de clock de transmissão (`clken`). O transmissor então gera o sinal de transmissão (`tx`) e um sinal indicando se o transmissor está ocupado (`tx_busy`).

#### Receptor: 
- O módulo do receptor (receiver) é responsável por receber dados do dispositivo externo e transmiti-los para a FPGA. Ele recebe o sinal de recepção (`rx`), um sinal indicando se está pronto para receber dados (`rdy`), um sinal para limpar o indicador de prontidão (`rdy_clr`), o sinal de clock de 50 MHz (`clk_50m`), e o sinal de habilitação de clock de recepção (`clken`). O receptor também gera os dados de saída (`dout`).

<a id="ancoraDHT11"></a>

### **DHT11:**
No contexto geral do projeto, o módulo `DHT11` permite a coleta de dados de um sensor DHT11 e disponibiliza as medições de temperatura e umidade para uso no projeto. O sinal `error` indica se ocorreu algum erro durante a coleta de dados, enquanto `done` indica quando a coleta foi concluída. Este módulo pode ser entendido como uma MEF (Figura 2), a seguir é possivél observar a função de cada estado:

#### Estado s1 - Preparação para Envio de Nível Baixo para o DHT11:
- Neste estado, a máquina de estados se prepara para iniciar a comunicação com o sensor DHT11.
- Se o sinal de `start` subir e o dado de entrada `din` for alto (`1'b1`), a máquina de estados transita para o próximo estado (`s2`).
- A variável `read_flag` é configurada para `1'b0`, indicando que a comunicação é do PC para o DHT11.
- O sinal `dout` é configurado para `1'b0`, indicando um valor a ser enviado para o DHT11.
- Contadores e registradores são inicializados.

#### Estado s2 - Contagem de Tempo para Nível Baixo: 
- Neste estado, a máquina de estados conta o tempo em que o sinal de `dout` está em nível baixo.
- O contador `cnt` é usado para contar até 19000 ciclos de clock, o que corresponde a 19 ms.
- Quando o contador atinge esse valor, a máquina de estados avança para o próximo estado (`s3`).

#### Estado s3 - Contagem de Tempo em Nível Alto: 
- Aqui, a máquina de estados conta o tempo em que o sinal `dout` está em nível alto.
- O contador `cnt` é usado para contar até 20 ciclos de clock, correspondendo a 20 µs.
- Quando o contador atinge esse valor, a máquina de estados avança para o próximo estado (`s4`).

#### Estado s4 - Preparação para Receber Resposta do DHT11: 
- Neste estado, a máquina de estados está pronta para receber a resposta do DHT11.
- Ela verifica se o sinal de entrada `din` é baixo (`1'b0`). Se sim, transita para o próximo estado (`s5`).
- Se o sinal `din` permanecer alto por muito tempo (mais de 65500 ciclos de clock), um erro é detectado, e a máquina de estados vai para o estado `STOP`.

#### Estado s5 - Aguardando Resposta em Nível Baixo: 
- Este estado aguarda o sinal `din` entrar em nível alto, indicando o início da resposta do DHT11.
- Se o sinal `din` subir, a máquina de estados transita para o próximo estado (`s6`).
- Da mesma forma que no estado anterior, um tempo muito longo em nível baixo gera um erro e mudança para o estado `STOP`.

#### Estado s6 - Aguardando Resposta em Nível Alto: 
- Aqui, a máquina de estados aguarda o sinal `din` entrar em nível baixo novamente, indicando o início da transmissão de dados pelo DHT11.
- Se o sinal `din` entrar em nível baixo, a máquina de estados transita para o próximo estado (`s7`).
- Um tempo muito longo em nível alto gera um erro e transição para `STOP`.

#### Estado s7 - Início da Transmissão de Dados: 
- Neste estado, a máquina de estados inicia a transmissão de dados pelo DHT11.
- Ela verifica se o sinal `din` é alto (`1'b1`). Se for, a máquina de estados transita para o próximo estado (`s8`).
- Novamente, um tempo muito longo em nível baixo gera um erro e transição para o estado `STOP`.

#### Estado s8 - Recebendo Bits de Dados: 
- Neste estado, a máquina de estados recebe os bits de dados transmitidos pelo DHT11.
- Ela conta o tempo em que o sinal `din` permanece em nível alto e, dependendo desse tempo, atribui um valor de `0` ou `1` ao dado recebido. Caso o sinal passe um tempo muito longo em nível baixo, o sinal de erro é gerado e há transição para o estado `STOP`.
- A máquina de estados continua a receber bits até que todos os 40 bits de dados tenham sido recebidos, então ela transita para o próximo estado (`s9`).

#### Estado s9 - Finalização da Recepção de Dados: 
- Neste estado, a máquina de estados armazena os dados recebidos no registrador `data`.
- Ela verifica se o sinal `din` é alto (`1'b1`). Se sim, a máquina de estados transita para o próximo estado (`s10`). Senão, caso passe um tempo maior que o devido em nível baixo, é gerado um sinal de erro e o estado é transitado para `STOP`.

#### Estado s10 - Fim da Comunicação:
- Neste estado, a máquina de estados indica que a comunicação foi concluída e que os dados foram recebidos com sucesso.
- Ela configura o sinal `error_reg` para `1'b0` para indicar a ausência de erros e encaminha para o próximo estado (`STOP`).

#### Estado STOP - Gerenciamento de Erros e Cooldown: 
- Estado final de todo o processo de leitura, sendo tanto para quando há alguma detecção de erro quanto para leituras bem sucedidas.
- O sinal `error_reg` é conservado desde quando tiver sido definido. Ou seja, se tiver ocorrido um erro, o sinal `error_reg` permanecerá `1'b1` para indicar o erro, senão permanecerá `1’b0` tal como definido pelo estado `s10`.
- A máquina de estados aguarda um período de cooldown de 5 segundos antes de configurar o sinal `done_reg` para nível alto e de retornar ao estado inicial (`s1`).


<div align=center>

![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/98599229/2182766a-d40b-46d1-aa48-89292ea88f90)
</br>
</br>
Figura 2 - Máquina de estados DHT11
</br>
</br>

</div>

<a id="ancoraMainStateMachine"></a>

### **Main State Machine:**

O módulo `main_state_machine` (Figura 3) desempenha um papel crítico na coordenação das várias etapas do sistema e na comunicação entre os módulos envolvidos. Os estados e operações realizadas pelo `main_state_machine` são:


#### IDLE: 
- No estado IDLE, o sistema aguarda a conclusão da recepção dos dois bytes de dados recebidos pelo receiver do UART. O sinal `done_uart_rx` indica quando os dados foram totalmente recebidos. Quando em nível baixo, permanece em IDLE, já em nível alto, duas situações podem ocorrer, a depender do tipo de solicitação enviada pelo usuário. Se não houver uma solicitação para interromper o sensoriamento contínuo (indicado pelo sinal `break_continuous` em nível baixo), o sistema passa para o estado RECEIVE e envia um sinal de start (`dht_out`) para o módulo DHT11. Entretanto, se foi solicitado para interromper o sensoriamento contínuo, o sistema passa diretamente para o estado ORGANIZE. 

#### RECEIVE: 
- Neste estado, o sistema aguarda até que o módulo DHT11 tenha concluído a coleta e decodificação dos dados de temperatura e umidade. Essa finalização é indicada pelo sinal `done_dht`. Quando `done_dht` se torna igual a 1, a coleta de dados advindos do DHT11 foi concluída, e o sistema passa para o estado ORGANIZE.

#### ORGANIZE: 
- No estado ORGANIZE, o sistema está se preparando para enviar os dados coletados pelo DHT11. Nesse sentido, um sinal `pack` em nível alto é enviado ao módulo [`packer`](#ancoraPacker), onde as respostas cabíveis são empacotadas para serem enviadas. Em seguida, o sistema passa para o estado SEND, a fim de iniciar o envio de dados.

#### SEND: 
- No estado SEND, os 4 bytes de resposta são enviados para o computador. O sistema aguarda até que o módulo UART tenha concluído o envio dessas informações, indicando com `done_uart_tx` em nível alto a finalização.

</br>
<div align=center>

![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/06d12ff0-dde6-49d4-abf3-ce215e78093a)

Figura 3 - Máquina de estados DHT11

</div>
</br>

<a id="ancoraRequest"></a>

### **Request Separator:**
O módulo `request_separator` é responsável por receber os dados do UART, separar o código de instrução e o endereço do sensor e controlar a indicação de conclusão (`DONE_OUT`) com base nas ações da máquina de estados finitos e na interpretação da instrução como uma solicitação de sensoriamento contínuo ou não. Isso permite que o sistema processe corretamente as solicitações do usuário e coordene a coleta de dados de sensores. Vamos analisar seu funcionamento em detalhes:

#### Variáveis de Registro: 
- O módulo possui duas variáveis de registro, `INSTR_REG` e `ADDR_REG`, para armazenar temporariamente o código de instrução e o endereço do sensor, respectivamente. Além disso, há uma variável de registro `counter` para controlar se o módulo está atualmente recebendo o código de instrução ou o endereço do sensor.

#### Processo Always: 
- O bloco `always @(posedge EN)` é sensível à borda de subida do sinal `EN` (sinal de enable do UART). Ele lida com a atribuição dos dados recebidos às variáveis de registro apropriadas. Quando o `counter` está em 0, o módulo está na fase de receber o código de instrução. Quando o `counter` está em 1, ele está na fase de receber o endereço do sensor. Após receber o endereço do sensor, o sinal `DONE` é definido como 1 para indicar que os dois bytes foram recebidos.

#### Controle de Estado: 
- O módulo monitora o estado do sistema por meio do sinal `IDLE` que vem da máquina de estados finitos (MEF) (presumivelmente, o `main_state_machine`). Quando o sistema está em um estado que não é IDLE (indicado por `!IDLE`), o módulo verifica o sinal `CONTINUOUS_EN`. Se `CONTINUOUS_EN` estiver alto, significa que a instrução é referente a sensoriamento contínuo, e `DONE_OUT` permanece alto para permitir que a MEF solicite novos dados. Se `CONTINUOUS_EN` estiver baixo, `DONE_OUT` é definido como 0, indicando que os dados foram processados e que a MEF pode mudar de estado.

#### Saídas: 
- O módulo possui duas saídas: `INSTR` e `ADDR` que refletem os valores dos registradores `INSTR_REG` e `ADDR_REG`, respectivamente. Isso permite que os dados separados sejam usados em outros lugares do sistema.

<a id="ancoraInstr"></a>

### **instr_decoder:**

O módulo `instr_decoder` interpreta as instruções recebidas e gera os sinais `CONTINUOUS_EN` e `BREAK_CONTINUOUS` para controlar o sensoriamento contínuo e parar o sensoriamento contínuo, respectivamente. Além disso, ele determina o tipo de dado desejado com base na instrução e gera o sinal `DATA_TYPE` para uso posterior no sistema.

#### Parâmetros Locais: 
- O módulo define parâmetros locais `STATUS`, `TEMP`, `HUMID`, `TEMP_CONT`, `HUMID_CONT`, `X_TEMP_CONT`, `X_HUMID_CONT` e `IDLE` para representar diferentes instruções. Por exemplo, `STATUS` representa a instrução relacionada ao status, `TEMP` à temperatura, `HUMID` à umidade, `TEMP_CONT` à instrução de sensoriamento contínuo de temperatura e assim por diante.

#### Operador Ternário para `CONTINUOUS_EN`: 
- O módulo utiliza operadores ternários para determinar o valor do sinal `CONTINUOUS_EN`. Se a instrução for igual a `TEMP_CONT` ou `HUMID_CONT`, o sinal `CONTINUOUS_EN` é definido como 1, indicando que ocorreu uma instrução de sensoriamento contínuo. Caso contrário, é definido como 0.

#### Operador Ternário para `BREAK_CONTINUOUS`: 
- Similar ao caso anterior, o módulo usa operadores ternários para determinar o valor do sinal `BREAK_CONTINUOUS`. Se a instrução for igual a `X_TEMP_CONT` ou `X_HUMID_CONT`, o sinal `BREAK_CONTINUOUS` é definido como 1, indicando que ocorreu uma instrução para parar o sensoriamento contínuo. Caso contrário, é definido como 0.

#### Operador Ternário para `DATA_TYPE`: 
- O módulo usa operadores ternários para determinar o valor do sinal `DATA_TYPE`, que representa o tipo de dado desejado (temperatura, umidade, status ou nenhum). Se a instrução for igual a `STATUS`, `DATA_TYPE` é definido como `S`, indicando status. Se a instrução for igual a `TEMP`, `TEMP_CONT` ou `X_TEMP_CONT`, `DATA_TYPE` é definido como `T`, indicando temperatura. Se a instrução for igual a `HUMID`, `HUMID_CONT` ou `X_HUMID_CONT`, `DATA_TYPE` é definido como `H`, indicando umidade. Caso contrário, `DATA_TYPE` é definido como `N`, indicando nenhum dado específico.


<a id="ancoraSelector"></a>

### **Data Selector:**

O módulo `data_selector` atua como um multiplexador para selecionar os dados corretos com base no tipo de dado desejado (`DATA_TYPE`) e encaminhá-los para as saídas `DATA_INT` e `DATA_FLOAT`. Vamos analisar o código em detalhes:

#### Parâmetros Locais: 
- O módulo define um parâmetro local `T`, que representa a opção de seleção de dados para temperatura, e `H`, que representa a opção de seleção de dados para umidade, e `S` para status. Esses parâmetros são usados posteriormente para determinar quais dados serão selecionados.

#### Atribuição de `DATA_INT`: 
- A instrução `assign DATA_INT = (DATA_TYPE == T) ? TEMP_INT : HUMI_INT;` seleciona os dados inteiros com base no tipo de dado (`DATA_TYPE`). Se `DATA_TYPE` for igual a `T` (temperatura), os dados inteiros da temperatura (`TEMP_INT`) são selecionados; caso contrário, se `DATA_TYPE` for igual a `H` (umidade), os dados inteiros da umidade (`HUMI_INT`) são selecionados. Se `DATA_TYPE` for igual a `S` (status) ou qualquer outro valor, os dados inteiros correspondentes não são selecionados.

#### Atribuição de `DATA_FLOAT`: 
- A instrução `assign DATA_FLOAT = (DATA_TYPE == T) ? TEMP_FLOAT : HUMI_FLOAT;` seleciona os dados fracionários com base no tipo de dado (`DATA_TYPE`). Da mesma forma que no caso anterior, se `DATA_TYPE` for igual a `T`, os dados fracionários da temperatura (`TEMP_FLOAT`) são selecionados; caso contrário, se `DATA_TYPE` for igual a `H`, os dados fracionários da umidade (`HUMI_FLOAT`) são selecionados. Se `DATA_TYPE` for igual a `S` ou qualquer outro valor, os dados fracionários correspondentes não são selecionados.

<a id="ancoraPacker"></a>

### **Packer:**

O módulo `packer` é responsável por empacotar os dados corretos com base nas informações fornecidas pelos módulos anteriores e gerar os bytes de saída correspondentes para transmissão. Ele também lida com situações de erro e interrupção de sensoriamento contínuo, conforme apropriado. Os bytes empacotados serão posteriormente enviados para a transmissão de dados.

#### Parâmetros Locais: 
- O módulo define alguns parâmetros locais que representam códigos específicos, como `SENSOR_ISSUE` para indicar problemas no sensor, `SENSOR_OK` para indicar que o sensor está funcionando corretamente, `HUMIDITY_MEASURE` para indicar uma medição de umidade, `TEMPERATURE_MEASURE` para indicar uma medição de temperatura, `DIS_TEMP_CONT` para indicar a interrupção do sensoriamento contínuo de temperatura, `DIS_HUMI_CONT` para indicar a interrupção do sensoriamento contínuo de umidade e `SUPER_IDLE` para indicar um estado de repouso especial.

#### Sempre na Borda de Subida de EN: 
- O bloco `always @(posedge EN)` é ativado na borda de subida do sinal `EN`. Isso significa que ele é sensível ao sinal de habilitação para empacotar os dados.

#### Condições de Erro: 
- A primeira parte do bloco lida com condições de erro. Se o sinal `ERROR` estiver ativo (indicando um erro no módulo DHT11) ou se os dados de temperatura estiverem fora dos limites aceitáveis (0 a 50) ou os dados de umidade estiverem fora dos limites aceitáveis (20 a 90), então o módulo gera códigos de erro (`SENSOR_ISSUE`) para os bytes de saída `BYTE1`, `BYTE2` e `BYTE3`.

#### Processamento Norma: 
- Se não houver erros, o bloco entra na seção de processamento normal. Ele utiliza um bloco `case` baseado no valor de `DATA_TYPE` para determinar que tipo de dado está sendo empacotado.

   - Se `DATA_TYPE` for igual a `T` (temperatura), ele verifica se `BREAK_CONTINUOUS` está ativo. Se estiver, ele gera um código de interrupção de sensoriamento contínuo (`DIS_TEMP_CONT`) para os bytes de saída. Caso contrário, ele gera códigos apropriados para medições de temperatura (`TEMPERATURE_MEASURE`) nos bytes de saída `BYTE1`, `BYTE2` e `BYTE3`, onde `BYTE2` contém a parte inteira e `BYTE3` contém a parte fracionária.
   
   - Se `DATA_TYPE` for igual a `H` (umidade), ele segue um processo semelhante ao da temperatura, gerando códigos de interrupção de sensoriamento contínuo (`DIS_HUMI_CONT`) se `BREAK_CONTINUOUS` estiver ativo ou códigos apropriados para medições de umidade (`HUMIDITY_MEASURE`) caso contrário.

   - Se `DATA_TYPE` for igual a `S` (status), ele gera códigos de status (`SENSOR_OK`) para todos os bytes de saída.

   - Se `DATA_TYPE` não corresponder a nenhum dos casos anteriores (neste caso, "Nada" ou qualquer outro valor não reconhecido), ele gera um código especial (`SUPER_IDLE`) para todos os bytes de saída para indicar um estado de repouso especial.



<a id="ancoraSend"></a>

### **Send Pc:**

O módulo `send_pc` controla o envio dos dados empacotados em resposta às solicitações do módulo principal. Ele utiliza uma máquina de estados simples para garantir que os bytes sejam enviados sequencialmente e de forma controlada para o módulo de transmissão UART. O sinal `DONE` é usado para indicar quando a transmissão foi concluída.

#### Registradores e Inicialização: 
- O módulo começa com a declaração de um registrador de 3 bits chamado `count` que é usado para controlar o estado da máquina de estados. Além disso, inicializa `RESPONSE_DATA` com 8 bits de "1" (todos os bits altos) e define `DONE` e `EN_TX` como 0 (baixo).

#### Máquina de Estados: 
- A principal lógica do módulo está dentro de um bloco `always` sensível à borda de subida do sinal de clock `clk`. Esse bloco implementa uma máquina de estados que controla o envio dos bytes empacotados.

   - Se o sinal `EN` estiver ativo (indicando que o módulo principal deseja iniciar a transmissão), o bloco verifica o sinal `BUSY_TX`. Se o módulo de transmissão estiver ocupado (`BUSY_TX` ativo), ele mantém os valores atuais de `RESPONSE_DATA`, `EN_TX`, `DONE`, e `count`.

   - Se o módulo de transmissão não estiver ocupado (`BUSY_TX` inativo), ele entra em um estado de máquina de estados controlado por `count`. Dependendo do valor atual de `count`, ele atribui os valores apropriados a `RESPONSE_DATA`, `EN_TX`, e `DONE`. 

      - Quando `count` for `3'b000`, ele configura `RESPONSE_DATA` para `BYTE1`, define `EN_TX` para 1 (ativo), e `DONE` para 0.

      - Quando `count` for `3'b010`, ele faz o mesmo para `BYTE1`.

      - Quando `count` for `3'b100`, ele configura `RESPONSE_DATA` para `BYTE2`, define `EN_TX` para 1 (ativo), e `DONE` para 0.

      - Quando `count` for `3'b110`, ele configura `RESPONSE_DATA` para `BYTE3`, define `EN_TX` para 1 (ativo), e `DONE` para 0.

      - Quando `count` for `3'b111`, ele mantém `RESPONSE_DATA` inalterado, define `EN_TX` para 0 (inativo), e `DONE` para 1. Este é o estado de conclusão.

#### Finalização: 
- Se o sinal `EN` não estiver ativo (indicando que o módulo principal não deseja iniciar a transmissão), ele mantém os valores atuais de `RESPONSE_DATA`, `EN_TX`, `DONE`, e redefine `count` para `3'b000`.


<a id="ancoraC"></a>

### **Interfaces em C**
As duas interfaces em C desempenham papéis cruciais no projeto geral, permitindo a comunicação entre um computador e a FPGA para controle e monitoramento de sensores. Aqui está uma descrição da utilidade de cada interface em relação ao projeto geral:

### Interface do Receiver (Receptor):

#### Objetivo:

A interface do Receiver é projetada para ser executada em um computador e se comunica com a FPGA por meio de uma conexão serial. Ela é responsável por receber as respostas e dados enviados pela FPGA em resposta às solicitações feitas pelo usuário.
  
#### Utilidade:
  
- Permite ao usuário verificar o status do sensor e as medições de temperatura e umidade capturadas pela FPGA.
- Recebe os dados enviados pela FPGA, incluindo medições e informações sobre o funcionamento dos sensores.
- Exibe as informações de maneira legível para o usuário, como temperatura, umidade e status do sensor.
- Facilita a detecção de erros ou problemas de comunicação entre o computador e a FPGA.

#### Benefícios:

- Permite ao usuário monitorar as medições de sensores em tempo real.
- Ajuda a identificar qualquer problema ou falha no funcionamento do sensor ou na comunicação com a FPGA.
- Torna o projeto mais acessível, fornecendo uma interface amigável para interação com o hardware FPGA.
   
### Interface do Transmitter (Transmissor):

#### Objetivo: 
- A interface do Transmitter também é executada em um computador e é usada para enviar comandos e solicitações à FPGA por meio da comunicação serial. Ela permite ao usuário selecionar diferentes modos de operação e solicitar medições específicas dos sensores.

#### Utilidade:

- Facilita a interação do usuário com a FPGA, permitindo que ele escolha entre várias opções, como leitura única de temperatura/umidade ou solicitação de leituras contínuas.
- Configura os comandos necessários, incluindo instruções e endereços de sensores, para serem enviados à FPGA.
- Envia as solicitações para a FPGA e aguarda as respostas.

#### Benefícios:

- Permite ao usuário controlar as operações do dispositivo FPGA a partir de um computador de forma conveniente.
- Possibilita a escolha entre diferentes modos de funcionamento, como leitura única ou contínua, para atender às necessidades específicas do projeto.
- Simplifica o processo de envio de comandos à FPGA, tornando-o mais acessível mesmo para usuários não técnicos.

No geral, essas duas interfaces desempenham um papel fundamental no projeto, proporcionando ao usuário a capacidade de interagir com a FPGA e acessar as medições dos sensores de maneira eficiente e amigável. Elas tornam o projeto mais versátil, permitindo diferentes modos de operação e facilitando a detecção de problemas ou erros durante a comunicação e a coleta de dados. Além disso, tornam a FPGA uma solução mais acessível para monitoramento e controle de sensores em um ambiente de computação pessoal.


<a id="ancoraTestes"></a>

## Testes

A fim de se averiguar o funcionamento do projeto como um todo, foram realizados diversos diversos testes em ambiente controlado. Para assegurar as diversas possibilidades de requisições possíveis, foram realizados testes envolvendo diferentes instruções das presentes no protocolo tendo sido registrados os resultados das: requisição de sensoriamento contínuo de temperatura, desativação do sensoriamento contínuo, solicitação do status atual do sensor, medida de temperatura e medida de umidade. Os resultados desses podem ser visto nas imagens a seguir.


### Interfaces em C

Para verificar o funcionamento das interfaces em C como um todo, se fez necessário conferir o funcionamento das partes que compoem as interfaces.

#### Transmissão:
- A transmissão foi testada ligando a porta serial do computador a um osciloscópio. Desta forma, foi possível garantir que os dados são enviados uma vez que podemos observa-los.

#### Recepção:
- A recepção foi testada ligando a saída da transmissão diretamente na entrada de recepção. Assim, foi possível assegurar-se que o dado está sendo enviado e que qualquer eventual falha seria algum problema no receptor.

### UART

#### Transmissão:

- Para verificar a transmissão da FPGA para o computador, atribui-se pinos de propósito geral aos transmissores da UART, assim, ao ligar tais pinos no osciloscópio é possivel constatar o funcionamento do transmissor da placa (Figura 4 e Figura 5).

<div align=center>

![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/2a75ed4a-6e00-44b3-b553-cc231557712d)
</br>
Figura 4 - Ponta de prova do osciloscópio conectada a porta serial.
</br>
</br>

![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/c9a00bd5-eed9-42f3-8826-a496edb33bc0)

Figura 5 - Resposta no osciloscópio.
</br>
</br>

</div>


#### Recepção:

- Para testar a recepção, envia-se os dados através do computador que já teve sua transmissão validada. Desta forma é possivel atribuir pinos na matriz de led da placa e validar a recepção dos dados.

### DHT11

- Para testar o sensor DHT11, conduzimos um teste conectando-o diretamente ao osciloscópio. Durante o teste, monitoramos os sinais elétricos gerados pelo sensor, incluindo os pulsos de dados que representam as leituras de temperatura e umidade. Essa abordagem nos permitiu verificar a saída do sensor e confirmar seu funcionamento adequado. A imagem abaixo (Figura 6) é uma captura da tela do osciloscópio dos dados recebidos do DHT11.

<div align=center>

![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/e394a092-f9b7-4998-9b3c-c8ff77738e20)
</br>
Figura 6 - Resposta sensor DHT11.
</br>
</br>
</div>

### Teste do produto:
- Para testar o produto como um todo, fez-se todas as solicitações possiveis ao sistema. Assim, para definir se as informações obtidas estavam corretas, observou-se se os dados obtidos estavam dentro do raio do sensor (20% a 80% para umidade e 0°C a 50°C para temperatura). Com estes dados validádos, para testar as funcionalidades do código, bastou fazer as solicitações ao sistema e observar suas respostas. As figuras a seguir mostram um exemplo do funcionamento do sistema.

<div align=center>

![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/009cebea-bd12-46d4-9367-db1e532dc2c5)
</br>
Figura 7 - Solicitação do status do sensor na esquerda e comando de resposta na direita.
</br>
</br>
![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/3d28a7c8-339a-4a31-8a5f-1d8f9d1a2668)
</br>
Figura 8 - Solicitação da temperatura atual na esquerda e comando de resposta na direita.
</br>
</br>
![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/2476ad1c-94ca-45a9-ab4a-b6312fe43111)
</br>
Figura 9 - Solicitação da umidade atual na esquerda e comando de resposta na direita.
</br>
</br>
![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/c990a6a1-cda3-47ef-9708-9114d620113c)
</br>
Figura 10 - Solicitação da temperatura continua na esquerda e comando de resposta na direita.
</br>
</br>
![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/d50f6ad6-3bb1-44a4-9cbf-180966a79a9e)
</br>
Figura 11 - Solicitação da interrupção da medida de temperatura continua na esquerda e comando de resposta na direita.
</br>
</br>

</div>


<a id="ancoraConclusao"></a>

## Conclusão

- Finalizados o planejamento do circuito e a descrição do mesmo na linguagem Verilog, foi realizada a compilação e síntese do mesmo por meio do Quartus II. Com o relatório de utilização de recursos, este gerado pelo próprio Quartus II ao compilar o projeto, pôde-se verificar que o circuito se aproveita de 401 dos 28848 elementos lógicos presentes da FPGA para o qual foi projetado, sendo 156 combinacionais sem registros, 40 de apenas registros e 205 combinacionais com registros, com todos eles sendo utilizados em seu modo normal. Desses 401 elementos lógicos, 146 são de LUT (Lookup Table) de quatro entradas, 77 são de três entradas e 138 são de duas ou menos entradas. Além disso, foram utilizados, parcial ou completamente, 33 dos 1803 LABs disponíveis. Essas informações podem ser visualizadas no relatório de uso de recursos (figura 12).
- Para o funcionamento principal do projeto, são necessários apenas 4 pinos principais, sendo eles: entrada de clock de 50 MHz, entrada da porta serial, bidirecional (inout) para o DHT11 e saída da porta serial. Entretanto, com a finalidade de testar e averiguar o funcionamento do projeto, foram criados dois barramentos de 8 bits e um de 2 bits como saída, de forma a se atribuir a estas, respectivamente: dois dos bytes que devem ter sido enviados para o computador pela porta serial e o estado atual da máquina de estados. Com isso, somando-se os pinos principais com os pinos para testes, obtém-se ao final um total de 22 pinos utilizados, como visto no relatório de uso de recursos na figura 12.

<div align=center>
</br>

![image](https://github.com/MarcioDzn/Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial/assets/91295529/a429c3aa-cdfa-4dff-97d3-5cf0bd49f499)
</br>
Figura 12 - Relatório de uso da FPGA.
</br>
</div>


- A partir dos testes realizados, foi possível comprovar o funcionamento do sistema como se era esperado. As respostas eram sempre recebidas no devido tempo definido, e os resultados demonstrados eram consistentes e condizentes com o ambiente de testes. Além disso, todos os devidos bytes de envio previstos no protocolo foram corretamente recebidos no computador.
Dessa forma, é possível afirmar que o projeto cumpre ao que se promete, atendendo aos requisitos propostos pelo texto problema. Com o projeto em questão, é possível realizar diferentes requisições de medidas e respostas para a FPGA, que, por sua vez, consegue entregar os devidos resultados coletados do sensor DHT11 de volta para o computador.

## Referências
- Módulo DHT11 original: https://www.kancloud.cn/dlover/fpga/1637659
- DHT11 Datasheet: https://www.mouser.com/datasheet/2/758/DHT11-Technical-Data-Sheet-Translated-Version-1143054.pdf
- Manual Mercurio IV Devkit: https://www.macnicadhw.com.br/sites/default/files/documents/downloads/manual_mercurioiv_v2.pdf
- Repositório com módulos UART originais: https://github.com/jamieiles/uart/tree/master
