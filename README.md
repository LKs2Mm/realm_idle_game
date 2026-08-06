# Realm Idle

Protótipo de RPG idle em Flutter com fantasia medieval sombria, inscrições
rúnicas e pixel art rústica. O jogo concentra a progressão em ciclos
automáticos: o jogador escolhe uma atividade, receita, classe ou destino, e a
recompensa só é entregue quando o respectivo ciclo termina. Não existe ganho de
XP por clicar repetidamente.

A navegação principal está dividida em sete menus: **Habilidades**,
**Colheita**, **Combate**, **Itens**, **Mapas**, **Ferramentas** e **Conta**.

## Habilidades e classes livres

- Cavaleiro, Assassino, Mago e Arqueiro são caminhos independentes, não uma
  escolha permanente. A classe ativa pode ser trocada diretamente no Combate.
- Cada vitória concede XP de Ataque e também XP para a maestria da classe que
  estava ativa. Níveis e número de vitórias são mantidos separadamente para as
  quatro classes.
- O poder do conjunto equipado da classe ativa reduz o tempo dos ciclos de
  combate. Cada classe possui seu próprio equipamento e seu próprio loadout.
- O painel de Habilidades acompanha Mineração, Corte de madeira, Pesca,
  Culinária, Forja, Artesanato, Ofício do Véu, Arcanismo, Alquimia, Ataque,
  Defesa, Magia e as quatro maestrias de classe.
- A progressão usa a curva `100 + 40n + 10n²`, em que `n = nível - 1`, e o XP
  é armazenado em décimos para preservar ganhos pequenos sem saltos visuais.

## Colheita

- Mineração, Corte de madeira e Pesca usam o mesmo sistema idle.
- O jogador seleciona um recurso uma vez e os ciclos continuam sozinhos.
- XP e itens são concedidos somente ao concluir ciclos.
- Uma nova seleção entra na fila e começa após o ciclo atual.
- A atividade continua ao trocar de menu e recupera o progresso offline.
- Combate e Colheita são atividades exclusivas: iniciar uma interrompe a
  outra, evitando que ouro e materiais sejam produzidos simultaneamente.
- Os bônus fracionários de rendimento são acumulados entre ciclos; nenhuma
  fração conquistada por ferramenta ou poção é perdida.
- Saves antigos de mineração e inventário são migrados automaticamente.

### Progressão de Mineração

- O cobre concede `5,6 XP` em `3s`, a Essência rúnica concede `1,3 XP` em
  `1s` e o ferro concede `15 XP` em `5s`.
- O Carvão mineral é liberado no nível 5, concede `6,8 XP` em `4s` e funciona
  como combustível das receitas de Fundição e Culinária.
- Depois do recurso inicial, novos minérios são liberados a cada 10 níveis.
- São necessários `3.389.430 XP` para chegar ao nível 100, cerca de 218 horas
  contínuas nas taxas-base usando sempre o melhor minério liberado.
- A Essência rúnica é a base das inscrições mágicas do Arcanista; minérios de
  tiers superiores também abastecem equipamentos, ferramentas, magias e
  alquimia.

### Progressão de Pesca

A Pesca possui exatamente dez capturas, liberadas no nível 1 e depois a cada
dez níveis. Tempos, XP e identidade das criaturas avançam das marés costeiras
até as águas abissais e rúnicas:

| Nível | Captura | ID | Ciclo | XP |
|---:|---|---|---:|---:|
| 1 | Camarão | `shrimp` | 3s | 10 |
| 10 | Sardinha | `sardine` | 4s | 14 |
| 20 | Truta | `trout` | 5s | 18,5 |
| 30 | Salmão | `salmon` | 7s | 27,3 |
| 40 | Atum | `tuna` | 9s | 36,9 |
| 50 | Lagosta | `lobster` | 12s | 51,6 |
| 60 | Peixe-espada | `swordfish` | 16s | 72 |
| 70 | Tubarão | `shark` | 21s | 98,7 |
| 80 | Enguia abissal | `abyssal_eel` | 27s | 132,3 |
| 90 | Leviatã rúnico | `runic_leviathan` | 34s | 173,4 |

## Combate, classes e espólios

- O jogador escolhe um inimigo uma vez e a caça se repete automaticamente;
  selecionar outro alvo o coloca na fila para o próximo ciclo.
- Tocar na classe já ativa (em vez de trocar de classe) abre um painel para
  equipar arma e cada peça de armadura individualmente, com a aba do
  Grimório disponível ali mesmo para o Mago vincular magias, sem sair do
  Combate.
- O personagem possui vida atual e vida máxima. A vida máxima parte de `100`,
  cresce com a maestria da classe ativa e recebe a Vitalidade dos equipamentos
  vinculados ao conjunto dessa classe.
- Cada vitória causa dano. Nível de Defesa, defesa dos equipamentos e buffs
  defensivos reduzem esse valor, sempre preservando ao menos 1 ponto de dano
  para ataques que originalmente causariam dano.
- Um lote automático ou offline é limitado à quantidade de vitórias que a vida
  atual suporta. Ao chegar a `0 HP`, o personagem é derrotado, o combate é
  interrompido e uma nova caçada fica bloqueada até que ele se recupere.
- Ouro, XP de Ataque e XP da classe ativa são concedidos somente após uma
  vitória completa. O combate recupera em lote as vitórias ocorridas offline.
- Seis inimigos sombrios são liberados nos níveis de Ataque 1, 10, 20, 40, 60
  e 80. O melhor alvo disponível leva aproximadamente 150 horas do nível 1 ao
  100 de Ataque.
- A renda cresce de 30 moedas por minuto no Rato Sepulcral até 5.000 moedas por
  minuto no Lorde das Runas. A moeda é distinta do recurso `Minério de ouro`.
- Equipamentos, poções e determinadas propriedades da magia vinculada
  participam do cálculo de eficiência do combate. Os efeitos do grimório são
  aplicados quando o Mago está ativo.
- O catálogo possui 12 espólios vinculados a inimigos: Pó sepulcral, Presa
  maculada, Tecido do cultista, Tinta rúnica, Couro da cripta, Ectoplasma
  velado, Aço oco, Estilhaço de juramento, Escama abissal, Ícor do vazio,
  Núcleo rúnico e Sigilo do lorde.
- As chances e quantidades médias dos drops usam um acumulador fracionário.
  Assim, o progresso de muitas vitórias é preservado e também funciona na
  recuperação offline.

## Itens, equipamentos e oficinas

O menu Itens possui seis áreas: **Equipados**, **Arsenal**, **Oficinas**,
**Alquimia**, **Grimório** e **Materiais**. O Arsenal permite combinar classe,
slot, material e raridade, conferir atributos e custos, iniciar a fabricação e
equipar peças já concluídas. Materiais coletados, espólios e produtos
processados são reunidos no inventário de Materiais.

### Conjuntos das quatro classes

Cada classe possui seis slots — cabeça, torso, pernas, pés, arma e mão
secundária — com identidade própria:

- **Cavaleiro:** Elmo do Bastião, Armadura do Juramento, Grevas da Fortaleza,
  Botas da Marcha, espada e Escudo do Guardião.
- **Assassino:** Capuz do Véu, Gibão Sombrio, Perneiras do Silêncio, Botas do
  Passo Morto, Lâminas Gêmeas e Relicário do Véu.
- **Mago:** Coroa dos Sigilos, Manto do Conjurador, Vestes do Círculo,
  Sandálias do Éter, cajado e Grimório Rúnico.
- **Arqueiro:** Capuz da Vigília, Couraça do Ermo, Perneiras do Batedor, Botas
  do Rastro, arco e Aljava e Flechas do Caçador.

As armas recebem nomes próprios conforme o minério usado. Todas as peças
possuem atributos de poder físico, poder arcano, defesa, vitalidade, precisão e
evasão; o orçamento de atributos varia por classe, slot, material e raridade.

### 2.400 variações fabricáveis

O catálogo é gerado pela combinação de:

- 4 classes;
- 6 slots;
- 10 materiais: Cobre, Ferro, Prata, Ouro, Platina, Mitril, Adamantita,
  Runita, Oricalco e Cristal Arcano;
- 10 raridades: Comum, Incomum, Raro, Épico, Lendário, Mítico, Rúnico,
  Amaldiçoado, Nascido do Vazio e Abissal.

O resultado é `4 × 6 × 10 × 10 = 2.400` equipamentos. Cada raridade define
cor de destaque, estilo de borda, intensidade da aura e densidade de runas. A
receita escala custo, requisito de oficina, duração, XP e atributos conforme o
tier do material e da raridade.

### Oficinas e progressão separada

- **Ferreiro / Forja:** produz o conjunto do Cavaleiro em metal e fogo.
- **Guilda dos Véus / Ofício do Véu:** o Artesão do Véu, apoiado por coureiros
  sombrios e armeiros secretos, produz o conjunto do Assassino.
- **Arcanista / Arcanismo:** tece o conjunto do Mago e inscreve as magias.
- **Artesão / Artesanato:** fabrica o conjunto, arco e aljava do Arqueiro.
- **Laboratório de Alquimia / Alquimia:** prepara poções de efeito temporário.

Cada oficina ganha XP somente ao concluir suas receitas. Portanto, evoluir uma
oficina não aumenta automaticamente o nível das outras.

### Produção temporizada e offline

- Existe uma fila compartilhada com uma encomenda ativa por vez para
  equipamentos, magias, poções, Fundição, Culinária e entalhe de espetos.
- As receitas de processamento podem ser iniciadas pelos atalhos de lote
  `1`, `5` ou `10`. Custo, produção, duração e XP são multiplicados pela
  quantidade escolhida.
- O custo é validado e descontado de forma atômica no início. Equipamentos
  consomem ouro e barras ou lingote da variação; magias, poções e processamento
  consomem os materiais especificados em suas receitas, vindos da Colheita,
  dos espólios de Combate ou de uma etapa anterior de processamento.
- Uma encomenda cancelada devolve integralmente o ouro e os materiais
  registrados na sessão.
- A produção tem duração real, atualiza o progresso automaticamente e pode
  continuar em paralelo à Colheita ou ao Combate.
- A sessão é salva com horário, duração e tempo restante. Ao reabrir ou voltar
  ao jogo, o serviço calcula o tempo transcorrido e conclui a receita offline
  quando necessário.
- Item, magia, poção e XP da oficina só são entregues na conclusão, nunca no
  clique que inicia a encomenda.

## Processamento, Fundição e Culinária

O processamento cria uma cadeia entre Colheita, oficinas, equipamentos e
recuperação de vida:

```text
1 Tronco                    → 3 Hastes talhadas (ou 5 Espetos, se for Tronco comum)
1 Minério + Carvão          → 1 Barra do metal
1 Cristal arcano + Essência → 1 Lingote arcano (Consagração Arcana)
1 Peixe + Carvão + 1 Espeto → 1 Refeição assada
```

- O catálogo possui nove receitas de Fundição no Ferreiro, uma para cada
  metal comum: Cobre, Ferro, Prata, Ouro, Platina, Mitril, Adamantita, Runita
  e Oricalco.
- Fundir minério concede XP de Forja. Materiais mais avançados exigem nível,
  tempo e uma quantidade maior de carvão.
- O Cristal Arcano não é fundido: o Arcanista o refina numa Consagração
  Arcana própria, trocando o carvão da forja por Essência Rúnica como
  catalisador, e produzindo o mesmo Lingote Arcano usado por equipamentos e
  ferramentas de ponta.
- O Artesão talha Hastes a partir de cada tora de madeira (Artesanato). Elas
  são o segundo insumo — ao lado da barra de metal correspondente — do Arco e
  da Aljava e Flechas do Arqueiro e do Cajado do Mago; as demais peças de
  equipamento continuam usando só a barra. Entalhar espetos continua sendo a
  única receita que transforma Tronco comum em cinco insumos reutilizáveis
  nas receitas de peixe assado.
- A Culinária possui dez receitas, uma para cada captura da Pesca. Cada lote
  consome peixe cru, carvão e espeto; a comida pronta vai para o inventário de
  consumíveis e concede XP de Culinária somente ao terminar.
- As dez curas, do Camarão assado ao Leviatã rúnico assado, restauram
  respectivamente `8`, `12`, `18`, `26`, `38`, `55`, `78`, `110`, `150` e
  `210 HP`. A cura nunca ultrapassa a vida máxima, alimento não é gasto quando
  a vida já está cheia e uma refeição pode reanimar o personagem a partir de
  `0 HP`.
- Equipamentos usam a barra correspondente à aparência/material selecionado;
  o Cristal Arcano usa `Lingote arcano`. Arco, Aljava e Flechas (Arqueiro) e
  Cajado (Mago) também exigem a Haste de madeira equivalente ao tier do
  material, ao lado da barra. Compras e melhorias de ferramentas também
  passaram a exigir barras, combinadas com ouro e outros materiais quando a
  receita determina.

## Grimório e magia rúnica

O Arcanista possui 12 inscrições, liberadas pelo nível de Arcanismo. Todas
usam Essência rúnica, combinada com minérios, madeira mágica ou espólios de
Combate conforme a receita:

1. Brasa Rúnica;
2. Estilhaço de Geada Fúnebre;
3. Agulha da Tempestade;
4. Pacto Carmesim;
5. Égide da Runa Férrea;
6. Garra Abissal;
7. Corrente da Pira;
8. Coroa do Inverno Morto;
9. Veredito do Trovão;
10. Eclipse Carmesim;
11. Portal do Nada;
12. Égide da Última Runa.

As escolas presentes são Chama, Geada, Tempestade, Sangue, Proteção e Vazio.
Uma magia concluída fica registrada no inventário e pode ser vinculada ao
grimório de combate. O save mantém tanto as inscrições possuídas quanto a magia
ativa.

## Alquimia e buffs reais

Há oito receitas de poção. Seus efeitos entram diretamente nos cálculos do
jogo e permanecem ativos pelo tempo indicado:

| Poção | Efeito | Potência | Duração |
|---|---|---:|---:|
| Tônico da Fúria Sepulcral | Poder de ataque | +8% | 5 min |
| Elixir da Pele de Cripta | Defesa | +10% | 6 min |
| Destilado da Mão de Prata | Velocidade de Colheita | +12% | 7 min |
| Presságio do Coletor | Rendimento de Colheita | +10% | 8 min |
| Tônico de Sangue Lupino | Velocidade de Combate | +14% | 7 min |
| Ícor Dourado | Ouro recebido | +18% | 10 min |
| Filtro do Olho Abissal | Chance de espólio | +15% | 10 min |
| Poção do Despertar Rúnico | XP recebido | +20% | 10 min |

O bônus de XP alcança Colheita, Combate e produção. Poções são fabricadas com
tempo e XP de Alquimia, ficam no inventário de consumíveis e só ativam o efeito
quando usadas. Cada tipo de buff possui uma duração persistida no save; usar
outra poção do mesmo tipo substitui o efeito anterior.

## Mapas e regiões

O mapa rúnico reúne oito regiões com lore, paleta, sigilo, oficinas presentes
e requisitos progressivos de Combate, Colheita e acesso à região anterior:

1. Encruzilhada das Cinzas;
2. Bosque dos Sussurros;
3. Costa dos Afogados;
4. Criptas Ocas;
5. Bastião de Obsidiana;
6. Confins Abissais;
7. Ermos Rúnicos;
8. Trono do Eclipse.

A tela distingue regiões abertas, bloqueadas e selecionadas, apresenta os
requisitos ainda não cumpridos e permite escolher qualquer destino liberado. A
região selecionada e o histórico de regiões alcançadas são salvos; o destino
atual também aparece no cabeçalho do Combate.

## Ferramentas

- Picaretas, machados e varas usam o mesmo sistema de equipamento.
- Cada disciplina possui seis tiers, liberados nos níveis 1, 20, 40, 60, 80
  e 100, e cada ferramenta aceita até cinco melhorias.
- Novas ferramentas e melhorias consomem moedas de ouro do Combate junto dos
  materiais processados, especialmente barras metálicas; tiers de machados e
  varas também podem combinar madeira, Essência rúnica e outros ingredientes.
  A transação é atômica: se faltar ouro ou qualquer ingrediente, nada é
  descontado.
- Ferramentas não concedem XP ao clicar; elas fornecem bônus passivos de
  velocidade e rendimento aos ciclos automáticos.
- A velocidade é calculada em milissegundos e o rendimento fracionário fica
  acumulado, portanto até um bônus pequeno produz um ganho real.
- Trocas e melhorias entram em vigor no ciclo seguinte. Saves antigos de
  picareta são convertidos automaticamente para o sistema unificado.

## Conta, crônica e save

- O perfil permite editar nome e título do personagem.
- A Conta mostra nível, vitórias e poder de equipamento separadamente para as
  quatro classes, reforçando que nenhuma escolha é permanente.
- A crônica registra criação do personagem, ciclos de coleta, vitórias,
  criações concluídas, poções consumidas e regiões alcançadas.
- O painel de identidade exibe criação e último save, permite salvar
  manualmente e copiar o identificador local da jornada.

O estado é armazenado localmente em JSON por `SharedPreferences`. O schema
atual é a versão `7` e inclui ouro, habilidades, `currentHealth`, inventário de
recursos, produtos processados e drops, restos fracionários, sessões ativas de
Colheita, Combate e produção, ferramentas, equipamentos e loadouts, magias,
poções, comidas, buffs com expiração, perfil, classe e magia ativas, vitórias
por classe e regiões visitadas. O carregamento limita a vida salva ao máximo
derivado atual; saves antigos sem `currentHealth` começam com a vida cheia. As
migrações anteriores de XP, mineração, inventário e picaretas permanecem
compatíveis.

## Direção visual

- Fantasia medieval sombria com ferro escurecido, couro, pedra, madeira negra
  e bronze gasto.
- O toque rúnico aparece em divisores, sigilos, glifos de seleção, bordas de
  raridade e cantos gravados.
- Pixel art rústica no fundo, brasão, emblemas de Colheita, arsenal das quatro
  classes, salão de oficinas e mapa do reino.
- Painéis angulares, brilho contido e cores dessaturadas preservam a leitura em
  telas pequenas.
- Os assets visuais ficam centralizados em `assets/images/medieval/`, incluindo
  `class-armory.png`, `workshop-hall.png` e `world-map.png`. Retratos únicos
  já existem para os 6 inimigos e as 4 classes, em
  `assets/images/medieval/gathering/criaturas/` e `.../gathering/classes/`.

## Executar

Na pasta `realm_idle_game`:

```powershell
..\flutter\bin\flutter.bat pub get
..\flutter\bin\flutter.bat run
```

## Validar

```powershell
..\flutter\bin\flutter.bat analyze
..\flutter\bin\flutter.bat test
```

Para validar também a versão web:

```powershell
..\flutter\bin\flutter.bat build web
```

## Organização

```text
lib/
├── app/         Bootstrap visual, ciclo de vida e navegação principal
├── core/        Tema, assets e infraestrutura visual compartilhada
├── features/    Combate, conteúdo, equipamentos, Colheita, processamento, produção e ferramentas
├── models/      Estado central e regras gerais do jogo
├── screens/     Habilidades, Combate, Itens, Mapas e Conta
├── services/    Persistência compartilhada
└── widgets/     Componentes reutilizáveis
test/            Testes de domínio, integração, serviços, telas e widgets
docs/reference/  Referências visuais do projeto
```

As pastas de plataforma (`android`, `ios`, `web`, `windows`, `linux` e
`macos`) permanecem disponíveis para builds multiplataforma. Diretórios como
`build` e `.dart_tool` são gerados pelo Flutter e não devem ser versionados.
