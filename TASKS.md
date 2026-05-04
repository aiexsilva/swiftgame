# Secrets of Time — Tracker de Tarefas

Ficheiro de acompanhamento das tarefas do projeto. Marca com `[x]` à medida que cada item fica concluído. O âmbito cobre o **jogo completo** (5 níveis + boss), não apenas o MVP.

**Legenda de prioridade:** 🔴 crítico · 🟡 importante · 🟢 polish/extra
**Donos:** A = Player/Combate · B = Mundo/Níveis · C = UI/Fluxo/Áudio · — = partilhado

---

## 0. Estado geral

- [ ] MVP funcional (níveis 1 e 2 jogáveis ponta-a-ponta)
- [ ] Jogo completo (5 níveis + boss)
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
- [ ] 2.5 Bloquear duplo-salto enquanto não está no chão
- [ ] 2.6 Direção do sprite (faceLeft/faceRight)
- [x] 2.7 Limite de velocidade máxima
- [ ] 2.8 Sistema de vida do player (HP) + invulnerabilidade temporária após dano
- [ ] 2.9 Estado de morte (animação/feedback + trigger game over)

---

## 3. Cena base de jogo + plataformas 🔴 (B)

- [ ] Plataformas estáticas (`SKSpriteNode` + physics static)
- [ ] Câmara (`SKCameraNode`) a seguir o player
- [ ] Clamp da câmara aos limites do nível
- [x] Gravidade do mundo configurada
- [ ] Background placeholder por estação
- [ ] Parallax simples no background 🟡

---

## 4. Input on-screen — controlos táteis 🔴 (C)

- [x] D-pad esquerda/direita
- [x] Botão de salto
- [x] Botão de tiro
- [ ] Camada HUD fixa (filho da câmara)
- [x] Suporte multi-touch (mover e saltar ou disparar em simultâneo)

---

## 5. Sistema de combate 🔴 (A)

- [ ] 5.1 `ProjectileNode.swift` — sprite + physics + `SKAction` de movimento
- [ ] 5.2 Disparo a partir do player com cooldown
- [ ] 5.3 Remoção do projétil ao sair do ecrã
- [ ] 5.4 `EnemyNode.swift` base — patrulha entre dois pontos
- [ ] 5.5 Contacto Projectile↔Enemy → remover ambos + score
- [ ] 5.6 Contacto Player↔Enemy → dano ao player
- [ ] 5.7 Inimigo tipo 2 — saltador (introduzido no nível 3) 🟡
- [ ] 5.8 Inimigo tipo 3 — voador (nível 4 ou 5) 🟡
- [ ] 5.9 Inimigo tipo 4 — atirador (nível 4) 🟡

---

## 6. Coletáveis e progressão 🔴 (B)

- [ ] `ArtifactNode.swift` — coletável estático
- [ ] `ScoreManager.swift` — score atual + threshold do nível
- [ ] `LevelManager.swift` — config de cada nível e próximo nível
- [ ] Teleporte aparece/ativa quando score ≥ threshold
- [ ] Contacto Player↔Teleporte → transição para próximo nível
- [ ] Persistência de progresso entre níveis (qual o nível desbloqueado) 🟡

---

## 7. UI / HUD 🔴 (C)

- [ ] Label de score
- [ ] Barra de progresso do threshold
- [ ] Indicador de vida do player
- [ ] Indicador "teleporte ativo"
- [ ] Botão de pausa + menu de pausa 🟡

---

## 8. Cenas e fluxo 🔴 (C)

- [ ] `MenuScene.swift` — botão Play, título do jogo
- [ ] `GameOverScene.swift` — Win/Lose, botões Retry e Menu
- [ ] `LevelSelectScene.swift` — escolher nível desbloqueado 🟡
- [ ] Transições com `SKTransition` entre cenas
- [ ] Ecrã de créditos 🟢
- [ ] Cartões de texto narrativos entre níveis 🟡

---

## 9. Conteúdo dos níveis

### Nível 1 — Spring 🔴 (B)
- [ ] Layout de plataformas (tutorial, fácil)
- [ ] Posicionamento de inimigos
- [ ] Posicionamento de artefactos
- [ ] Threshold de score balanceado
- [ ] Música/ambiente

### Nível 2 — Summer 🔴 (B)
- [ ] Layout (deserto/praia)
- [ ] Inimigos mais rápidos
- [ ] Artefactos
- [ ] Threshold balanceado
- [ ] Música/ambiente

### Nível 3 — Autumn 🟡 (B)
- [ ] Layout (floresta escura, plataforming mais técnico)
- [ ] Introduzir inimigo tipo 2 (saltador)
- [ ] Artefactos
- [ ] Threshold balanceado
- [ ] Música/ambiente

### Nível 4 — Winter 🟡 (B)
- [ ] Layout com plataformas geladas
- [ ] Física escorregadia (atrito reduzido no chão)
- [ ] Inimigos mais agressivos / atirador
- [ ] Artefactos
- [ ] Threshold balanceado
- [ ] Música/ambiente

### Nível 5 — Lost Time 🟡 (B)
- [ ] Layout do void/dimensão final
- [ ] Ambiente visual distintivo (sem cor / partículas)
- [ ] Threshold ou condição especial para desbloquear o boss
- [ ] Música/ambiente

### Boss fight 🟡 (A + B)
- [ ] `BossNode.swift` com HP
- [ ] Padrão de ataque 1
- [ ] Padrão de ataque 2
- [ ] Fases (mudança de comportamento conforme HP)
- [ ] Barra de vida do boss no HUD
- [ ] Ecrã de vitória final / final do jogo

---

## 10. Áudio 🟡 (C)

- [ ] Música de fundo por nível (5 tracks)
- [ ] Música do menu
- [ ] Música do boss
- [ ] SFX: tiro
- [ ] SFX: coletar artefacto
- [ ] SFX: morte de inimigo
- [ ] SFX: dano ao player
- [ ] SFX: salto
- [ ] SFX: teleporte
- [ ] SFX: botões de UI
- [ ] Controlo de volume / mute 🟢

---

## 11. Arte e animação 🟢 (—)

- [ ] Sprite sheet do player com animações (idle, walk, jump, shoot, hit)
- [ ] Sprite sheet de cada tipo de inimigo
- [ ] Sprite do projétil com efeito visual
- [ ] Sprite dos artefactos por estação
- [ ] Sprite do teleporte com animação
- [ ] Sprite do boss
- [ ] Tilesets por estação
- [ ] Partículas (`SKEmitterNode`) para tiro, morte, teleporte

---

## 12. Polish & QA 🟡 (—)

- [ ] Testar colisões em isolamento
- [ ] Playtesting de cada nível + ajuste de thresholds
- [ ] Bugfixing
- [ ] Verificar performance em dispositivo real
- [ ] Verificar safe area em diferentes iPhones
- [ ] Testar pausa/retoma da app (background → foreground)
- [ ] Save/load entre sessões (UserDefaults) 🟡
- [ ] Acessibilidade básica (tamanho de botões, contraste) 🟢

---

## 13. Entrega final

- [ ] README atualizado com instruções de build
- [ ] Build de release a correr sem warnings críticos
- [ ] Vídeo/gameplay de demonstração 🟢
- [ ] Documentação técnica para a defesa do projeto
