<div align=center>

# Sensor-Digital-em-FPGA-utilizando-Comunicacao-Serial
</div>

## Breve descrição do problema:

Este repositório é o resultado do trabalho de uma equipe de estudantes para criar um protótipo de sistema IoT para monitorar a temperatura e umidade de ambientes usando uma plataforma FPGA. Como sensor, o projeto conta com o DHT11 que por sua vez é acoplado a FPGA Mercurio IV Devkit. Assim a FPGA implementa uma interface UART para receber, executar e responder a comandos enviados através de uma porta serial por um computador. Para que a interação com o computador seja possível, a equipe também desenvolveu um sistema de teste em C para enviar comandos e exibir respostas nos computadores. Será discriminado durante este relatório os conceitos envolvidos durante a construção do protótipo, bem como as decisões de projetos da equipe.

<a name="ancora"></a>

## Indice:
1. [Requisitos do projeto](#ancoraRequisitos)
2. [Protocolo](#ancoraProtocolo)
3. [Fluxograma geral](#ancoraFluxograma)
4. [Módulos utilizados](#ancoraModulos)
     - [UART](#ancoraUART)
     - [DHT11](#ancoraDHT11)
     - [Main State Machine](#ancoraMainStateMachine)
     - [Request Separator](#ancoraRequest)
     - [Instr Decoder](#ancoraInstr)
     - [Data Selector](#ancoraSelector)
     - [Packer](#ancoraPacker)
     - [Send Pc](#ancoraSend)
5. [Interfaces em C](#ancoraC)
6. [Conclusão](#ancoraConclusao)

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

<a id="ancoraProtocolo"></a>

## Protocolo:

O protocolo de comunicação projetado para este projeto possui como base as duas tabelas a seguir, que representam, respectivamente, os comandos de requisição e de resposta.

</br>
<div align=center>

|        |           **Comandos de requisição**           |   |        |                      **Comandos de resposta.**                      |
|--------|:----------------------------------------------:|---|--------|:-------------------------------------------------------------------:|
|**Código**|          **Descrição do comando**              |   |**Código**|                        **Descrição**                              |
|  0x00  |       Solicita a situação atual do sensor      |   |  0x1F  |                         Sensor com problema                         |
|  0x01  |     Solicita a medida de temperatura atual     |   |  0x07  |                    Sensor funcionando normalmente                   |
|  0x02  |       Solicita a medida de umidade atual       |   |  0x08  |                          Medida de umidade                          |
|  0x03  |   Ativa sensoriamento contínuo de temperatura  |   |  0x09  |                        Medida de temperatura                        |
|  0x04  |     Ativa sensoriamento contínuo de umidade    |   |  0x0A  | Confirmação de desativação de sensoriamento contínuo de temperatura |
|  0x05  | Desativa sensoriamento contínuo de temperatura |   |  0x0B  |   Confirmação de desativação de sensoriamento contínuo  de umidade  |
|  0x06  |   Desativa sensoriamento contínuo  de umidade  |   |        |                                                                     |
</div>
</br>

#### Todo o processo de comunicação entre o computador e a FPGA se baseia no envio sempre de 2 bytes. Portanto analisando individualmente:
  
### Envio Computador -> FPGA
- Os 2 bytes enviados do computador para a FPGA representam, em ordem de envio, o comando de instrução e o endereço de sensor desejado.

### Envio FPGA -> Computador
- Para este projeto, foi convencionado que todas as respostas serão enviadas em 2 grupos de 2 bytes. Os primeiros 2 bytes, em todos os casos independentemente da requisição, representam o comando de resposta correspondente ao pedido realizado. Caso a requisição seja uma relacionada ao envio de valores medidos pelo DHT11, tal como medida de temperatura ou umidade, contínuos ou não, os próximos 2 bytes estarão relacionados aos valores inteiros e fracionários adquiridos por meio do sensor. Entretanto, caso seja uma requisição que não necessita de nenhum tipo de valor medido, ou caso haja um erro na medição do DHT11, os 4 bytes de resposta serão todos iguais, sendo compostos apenas dos comandos de resposta.

<a id="ancoraFluxograma"></a>

## Fluxograma geral:
<div align=center>

![Alt text](image.png)
</div>

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
No contexto geral do projeto, o módulo `DHT11` permite a coleta de dados de um sensor DHT11 e disponibiliza as medições de temperatura e umidade para uso no projeto. O sinal `error` indica se ocorreu algum erro durante a coleta de dados, enquanto `done` indica quando a coleta foi concluída. Este módulo pode ser entendido como uma MEF, a seguir é possivél observar a função de cada estado:

#### s1 - Idle: 
- O módulo aguarda um sinal de `start` para a ativação. Quando esse sinal é detectado, ele muda para o estado `s2`.

#### s2 - Start Signal: 
- Após a detecção de `start`, o módulo espera 19 ms antes de iniciar a comunicação com o sensor. Depois disso, ele muda para o estado `s3`.

#### s3 - Data Request: 
- O módulo envia uma solicitação de dados ao sensor DHT11 e aguarda a resposta. Se a resposta for detectada, ele muda para o estado `s4`. Caso contrário, ele pode entrar em um estado de erro.

#### s4 - Data Response: 
- O módulo aguarda a resposta do sensor indicando que está pronto para transmitir dados. Quando a resposta é detectada, ele muda para o estado `s5`.

#### s5 - Data Transmission: 
- O módulo recebe os bits de dados do sensor DHT11. Ele detecta transações de bits e registra os valores recebidos no registrador `data_buf`.

#### s6 - Data Bit Start Detection: 
- Neste estado, o módulo aguarda o início do próximo bit de dados. Ele monitora o sinal de entrada `din` e aguarda até que ocorra uma transição de `din` de 1 (baixo) para 0 (alto), o que indica o início de um novo bit de dados. Assim que essa transição é detectada, o módulo muda para o estado `s7`.

#### s7 - Data Bit Reception: 
- Neste estado, o módulo está na posição correta para receber os bits de dados. Ele monitora o sinal `din` e registra o valor de `din` no registrador `data_buf` à medida que os bits são recebidos. O registrador `data_cnt` é usado para rastrear quantos bits de dados já foram recebidos. O estado permanece em `s7` até que todos os 40 bits de dados tenham sido lidos, momento em que o módulo muda para o estado `s9`.

#### s8 - Data Bit Validation: 
- Neste estado, o módulo verifica a integridade dos bits de dados recebidos. Ele conta o tempo para determinar se a duração do sinal `din` representa um 0 lógico ou um 1 lógico. Os bits de dados válidos são registrados no `data_buf` e o `data_cnt` é incrementado. Se o tempo estiver dentro dos limites esperados, o valor do bit é considerado válido e é armazenado no `data_buf`. Se o tempo estiver fora dos limites esperados, pode indicar um erro nos dados recebidos. O módulo permanece em `s8` até que todos os 40 bits de dados tenham sido validados e registrados.

#### s9 - Data Reception Complete: 
- Após a recepção dos 40 bits de dados, o módulo verifica se os dados são válidos (checksum). Se os dados forem válidos, eles são armazenados no barramento `data` e o módulo fica pronto para iniciar outra leitura. Caso contrário, pode entrar em um estado de erro.

#### STOP - Stop State: 
- Este estado é usado para garantir um intervalo de 5 segundos entre as leituras dos sensores para evitar leituras excessivas. Após 5 segundos, o módulo volta ao estado `s1` para iniciar uma nova leitura.

<div align=center>

![Alt text](image-1.png)
</div>

<a id="ancoraMainStateMachine"></a>

### **Main State Machine:**

O módulo `main_state_machine` desempenha um papel crítico na coordenação das várias etapas do sistema e na comunicação entre os módulos envolvidos. Os estados e operações realizadas pelo `main_state_machine` são:


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

![Alt text](image-3.png)
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

- Para verificar a transmissão da FPGA para o computador, atribui-se pinos de propósito geral aos transmissores da UART, assim, ao ligar tais pinos no osciloscopio é possivel constatar o funcionamento do transmissor da placa.

#### Recepção:

- Para testar a recepção, envia-se os dados através do computador que já teve sua transmissão validada. Desta forma é possivel atribuir pinos na matriz de led da placa e validar a recepção dos dados.

### DHT11


### Teste do produto:
- Para testar o produto como um todo, fez-se todas as solicitações possiveis ao sistema. Assim, para definir se as informações obtidas estavam corretas, observou-se se os dados obtidos estavam dentro do raio do sensor (20% a 80% para umidade e 0°C a 50°C para temperatura). Com estes dados validádos, para testar as funcionalidades do código, bastou fazer as solicitações ao sistema e observar suas respostas. As figuras a seguir mostram um exemplo do funcionamento do sistema.



<a id="ancoraConclusao"></a>

## Conclusão

- Finalizados o planejamento do circuito e a descrição do mesmo na linguagem Verilog, foi realizada a compilação e síntese do mesmo por meio do Quartus II. Com o relatório de utilização de recursos, este gerado pelo próprio Quartus II ao compilar o projeto, pôde-se verificar que o circuito se aproveita de 401 dos 28848 elementos lógicos presentes da FPGA para o qual foi projetado, sendo 156 combinacionais sem registros, 40 de apenas registros e 205 combinacionais com registros, com todos eles sendo utilizados em seu modo normal. Desses 401 elementos lógicos, 146 são de LUT (Lookup Table) de quatro entradas, 77 são de três entradas e 138 são de duas ou menos entradas. Além disso, foram utilizados, parcial ou completamente, 33 dos 1803 LABs disponíveis.


- A partir dos testes realizados, foi possível comprovar o funcionamento do sistema como se era esperado. As respostas eram sempre recebidas no devido tempo definido, e os resultados demonstrados eram consistentes e condizentes com o ambiente de testes. Além disso, todos os devidos bytes de envio previstos no protocolo foram corretamente recebidos no computador.
Dessa forma, é possível afirmar que o projeto cumpre ao que se promete, atendendo aos requisitos propostos pelo texto problema. Com o projeto em questão, é possível realizar diferentes requisições de medidas e respostas para a FPGA, que, por sua vez, consegue entregar os devidos resultados coletados do sensor DHT11 de volta para o computador.