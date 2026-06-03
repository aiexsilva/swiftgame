# Secrets of Time — Tracker de Tarefas

Ficheiro de acompanhamento das tarefas do projeto. Marca com `[x]` à medida que cada item fica concluído. O âmbito cobre o **jogo completo** (5 níveis + boss), não apenas o MVP.

**Legenda de prioridade:** 🔴 crítico · 🟡 importante · 🟢 polish/extra
**Donos:** A = Player/Combate · B = Mundo/Níveis · C = UI/Fluxo/Áudio · — = partilhado

---

## 0. Estado geral

- [x] MVP funcional (níveis 1 e 2 jogáveis ponta-a-ponta)
- [x] Jogo completo (5 níveis + boss) — todas as peças integradas, falta testar e polir
- [ ] Build final testada em dispositivo iOS real

---

## 1. Fundação do projeto 🔴 (—)

- [x] Criar estrutura de pastas: `Scenes/`, `Nodes/`, `Managers/`, `Resources/Levels`, `Resources/Sounds`, `Resources/Sprites`
- [x] Criar ficheiro `PhysicsCategory.swift` com bitmasks (Player, Enemy, Projectile, Artifact, Platform, Teleport, Hazard, Boss)
- [x] Configurar `GameViewController` para apresentar `MenuScene` por defeito
- [x] Definir resolução base e `scaleMode = .aspectFill`
- [x] Forçar orientação landscape no Info.plist
- [x] Remover código boilerplate da `GameScene.swift` default

---

## 2. Player Controller — `PlayerNode.swift` 🔴 (A)

- [x] 2.1 `SKSpriteNode` com placeholder colorido + `SKPhysicsBody` rectangular
- [x] 2.2 Movimento horizontal (esquerda/direita) com velocidade constante
- [x] 2.3 Salto (impulso vertical único)
- [x] 2.4 Detecção de "grounded" via `SKPhysicsContactDelegate`
- [x] 2.5 Bloquear duplo-salto enquanto não está no chão
- [x] 2.6 Direção do sprite (faceLeft/faceRight)
- [x] 2.7 Limite de velocidade máxima
- [x] 2.8 Sistema de vida do player (HP) + invulnerabilidade temporária após dano
- [x] 2.9 Estado de morte (animação/feedback + trigger game over)

---

## 3. Cena base de jogo + plataformas 🔴 (B)

- [x] Plataformas estáticas (`SKSpriteNode` + physics static)
- [x] Câmara (`SKCameraNode`) a seguir o player
- [x] Clamp da câmara aos limites do nível
- [x] Gravidade do mundo configurada
- [x] Background placeholder por estação
- [ ] Parallax simples no background 🟡

---

## 4. Input on-screen — controlos táteis 🔴 (C)

- [x] D-pad esquerda/direita
- [x] Botão de salto
- [x] Botão de tiro
- [x] Camada HUD fixa (filho da câmara)
- [x] Suporte multi-touch (mover e saltar ou disparar em simultâneo)

---

## 5. Sistema de combate 🔴 (A)

- [x] 5.1 `ProjectileNode.swift` — sprite + physics + `SKAction` de movimento
- [x] 5.2 Ataque a partir do player com cooldown
- [x] 5.3 `EnemyNode.swift` base — patrulha entre dois pontos
- [x] 5.4 Contacto Ataque↔Enemy → remover ambos
- [x] 5.5 Contacto Player↔Enemy → dano ao player
- [x] 5.6 Inimigo tipo 2 — saltador (introduzido no nível 3) 🟡
- [x] 5.7 Inimigo tipo 3 — voador (nível 4 ou 5) 🟡
- [x] 5.8 Inimigo tipo 4 — atirador (nível 4) 🟡 — TurretEnemy + EnemyProjectile + PenguinEnemy + SpiderEnemy implementados

---

## 6. Coletáveis e progressão 🔴 (B)

- [x] `CollectibleNode.swift` — puzzle piece coletável
- [x] `PortalNode.swift` — portal de saída por nível
- [x] Portal instanciado em cada nível com 1 collectible necessário
- [x] Transição de nível via portal com overlay do puzzle (Puzzle1-4)
- [x] Transição começa sem esperar que o overlay termine
- [ ] Persistência de progresso entre níveis (qual o nível desbloqueado) 🟡

---

## 7. UI / HUD 🔴 (C)

- [x] Indicador de vida do player (HealthHUD)
- [x] CollectibleHUD — estrutura existente
- [x] Counter no portal (x/N peças coletadas)
- [x] Botão de pausa + menu de pausa 🟡

---

## 8. Cenas e fluxo 🔴 (C)

- [x] `MenuScene.swift` — botão Play, título do jogo
- [x] `GameOverScene.swift` — Win/Lose, botões Retry e Menu
- [ ] `LevelSelectScene.swift` — escolher nível desbloqueado 🟡
- [x] Transições com `SKTransition.fade` entre cenas
- [ ] Ecrã de créditos 🟢
- [x] Overlay do puzzle (narrativa visual entre níveis)

---

## 9. Conteúdo dos níveis

### Nível 1 — Spring 🔴 (B)
- [x] Layout de plataformas
- [x] Inimigos: Slime + FlowerPot
- [x] Collectible + Portal instanciados
- [x] NPC KittyCat com diálogo sobre inimigos
- [ ] Música/ambiente

### Nível 2 — Summer 🔴 (B)
- [x] Layout (praia)
- [x] Inimigos: Snake + Flyer
- [x] Collectible + Portal instanciados
- [x] NPC KittyCat com diálogo
- [ ] Música/ambiente

### Nível 3 — Autumn 🟡 (B)
- [x] Layout
- [x] Inimigos: Jumper + Spider (novo inimigo imoral oscilatório)
- [x] Collectible + Portal instanciados
- [x] NPC KittyCat com diálogo
- [ ] Música/ambiente

### Nível 4 — Winter 🟡 (B)
- [x] Layout com plataformas
- [x] Inimigos: Turret + Penguin (novos)
- [x] Collectible + Portal instanciados
- [x] NPC KittyCat Winter com diálogo
- [ ] Música/ambiente

### Nível 5 — Vazio/Boss 🟡 (B)
- [x] Layout da arena
- [x] Trigger de câmara visível (retângulo laranja)
- [x] Lerp zoom-out (0.65→0.90) ao cruzar o trigger
- [ ] Música/ambiente boss

### Boss fight 🟡 (A + B)
- [x] `BossNode.swift` com HP e callback de derrota
- [x] `BossAIController` com grid 3×3 e padrões de ataque
- [x] `BarrierNode` (3 hits para destruir)
- [x] `BossAttackHitbox` com telegraph + hitbox ativa
- [x] Dano ao player por bossAttack e bossBody
- [x] Ecrã de vitória (BossDefeatOverlay → goToMainMenu)
- [ ] Barra de vida do boss no HUD 🟡
- [ ] Sons do boss (a adicionar)

---

## 10. Áudio 🟡 (C)

- [x] Música de fundo — Main_music.mp3 em loop (SKAudioNode)
- [ ] Música específica por nível 🟡
- [ ] Música do boss
- [x] SFX: tiro do turret — fireball.mp3
- [x] SFX: coletar artefacto — coin-catch.mp3
- [x] SFX: portal desbloqueado — upgrade_levelup.mp3
- [x] SFX: morte de inimigo — enemy-kill.mp3
- [ ] SFX: dano em inimigo (a fornecer)
- [x] SFX: dano ao player — explosion_2.mp3
- [x] SFX: morte do player — player-death.mp3
- [x] SFX: salto — jumping-sound-effect.mp3
- [x] SFX: entrada no portal — woosh.mp3
- [x] SFX: abertura de diálogo — chime.mp3 + meow.mp3
- [x] SFX: boss derrotado — groan.mp3
- [ ] Controlo de volume / mute 🟢

---

## 11. Arte e animação 🟢 (—)

- [x] Sprite sheet do player com animações (idle, walk, jump, shoot, hit)
- [ongoing] Sprite sheet de cada tipo de inimigo (Slime/Snake/FlowerPot OK; Flyer/Jumper/Spider/Turret/Penguin placeholder)
- [x] Sprite dos collectibles (Puzzle1-4)
- [x] Sprite do portal com animação (Portal1-4)
- [ ] Sprite do boss (placeholder roxo)
- [ ] Tilesets por estação
- [ ] Partículas (`SKEmitterNode`) para tiro, morte, teleporte

---

## 12. Polish & QA 🟡 (—)

- [x] Testar colisões em isolamento
- [ongoing] Playtesting de cada nível + ajuste de thresholds
- [ongoing] Bugfixing
- [ongoing] Verificar performance em dispositivo real
- [ ] Testar pausa/retoma da app (background → foreground)
- [ ] Save/load entre sessões (UserDefaults) 🟡
- [x] Acessibilidade básica (tamanho de botões, contraste) 🟢

---

## 13. Entrega final

- [ ] README atualizado com instruções de build
- [ ] Build de release a correr sem warnings críticos
- [ ] Vídeo/gameplay de demonstração 🟢
- [ ] Documentação técnica para a defesa do projeto
