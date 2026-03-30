# sistema-hospitalar-postgres
Banco de dados relacional em PostgreSQL para gestão hospitalar, incluindo pacientes, médicos, enfermeiras, internações, exames, prescrições, faturamento e pesquisas de satisfação.
# Sistema de Gestão Hospitalar

## Descrição
Banco de dados relacional em **PostgreSQL** para gerenciamento hospitalar, cobrindo pacientes, médicos, enfermeiras, internações, exames, prescrições, faturamento e pesquisas de satisfação.  
Inclui auditoria de desligamentos e relatórios prontos via views, garantindo rastreabilidade e suporte a relatórios administrativos e financeiros.

---
## Estrutura
sistema-hospitalar/
│
├── README.md              # Documentação completa do projeto
├── schema.sql             # Criação de enums, tabelas, índices, constraints e triggers
├── inserts.sql            # Dados iniciais (DML) para popular o banco
├── views.sql              # Criação de todas as views analíticas e operacionais
├── users.sql              # Criação de usuários e permissões
├── auditoria.sql          # Histórico de médicos e enfermeiras + triggers de auditoria
└── exemplos_consultas.sql # Consultas práticas para demonstração

### Enums
- `enum_turno` → turnos de trabalho  
- `tipo_ala` → tipos de ala hospitalar  
- `status_leito` → ocupação de leitos  
- `tipo_atendimento` → consulta, emergência, revisão, triagem  
- `status_atendimento` → realizado, cancelado, agendado, em espera  
- `tipo_cobertura` → abrangência dos planos  
- `status_fatura` → pendente, pago, cancelado, etc.  
- `tipo_exame`, `resultado_exame`, `status_exame`  
- `tipo_pagamento` → formas de pagamento  
- `perfil_usuario` → admin, médico, enfermeira, paciente  
- `tipo_leito` → pós-cirúrgico, infantil, isolamento etc.  

### Tabelas principais
- `hospital`, `ala`, `leito`  
- `plano_saude`, `hospital_plano`  
- `paciente`, `medico`, `enfermeira`  
- `atendimento`, `medicamento`, `prescricao_medicamento`  
- `laboratorio`, `exame`  
- `internacao`, `fatura`  
- `pesquisa_satisfacao`, `usuario`  
- Auxiliares: `paciente_medico`, `historico_enfermeira`, `historico_medico`  

### Índices e Constraints
- `idx_exame_tem_laudo` → otimiza consultas de exames com laudo anexado  
- `idx_unica_internacao_ativa` → garante apenas uma internação ativa por paciente  
- Constraints de unicidade em alas, planos e leitos  

---

## Triggers e Funções
- **Medicamentos**  
  - `tr_decrementa_estoque_medicamento` → decrementa estoque ao prescrever  
  - `tr_impede_estoque_negativo` → evita estoque negativo  

- **Internações/Leitos**  
  - `tr_ocupa_leito_internacao` → ocupa leito ao internar  
  - `tr_libera_leito_internacao` → libera leito ao dar alta  

- **Pacientes**  
  - `tr_impede_remocao_paciente` → bloqueia exclusão com registros vinculados  

- **Faturas/Exames**  
  - `tr_status_fatura_pago` → atualiza status para “pago”  
  - `tr_preenche_data_resultado_exame` → preenche data do resultado automaticamente  

- **Auditoria**  
  - `trg_demissao_enfermeira` → registra desligamento em `historico_enfermeira`  
  - `trg_demissao_medico` → registra desligamento em `historico_medico`  

---

## Views
- **Auditoria**: `vw_todas_enfermeiras`, `vw_todos_medicos`  
- **Estrutura**: `vw_leitos_alas`  
- **Operacionais**: `vw_internacoes_ativas`, `vw_resultado_pendente`, `vw_qtd_exame_lab`, `vw_consultas_ultimo_mes`  
- **Financeiro**: `vw_faturamento_plano_2026`, `vw_total_faturado_atendimento`, `vw_total_faturado_plano`  
- **Produtividade**: `vw_medicos_maior_atendimento`, `vw_qtd_paciente_medico`  

---

## Usuários e Perfis
- **Admin (`admin_hospital`)** → acesso total  
- **Médico (`arnaldo_rocha`)** → atendimentos e prescrições  
- **Recepcionista (`recepcionista`)** → pacientes e internações  
- **Paciente** → acesso restrito a seus próprios dados  

---

## Dados iniciais
O banco já vem populado com exemplos reais:  
- Hospitais renomados (Albert Einstein, Sírio-Libanês, HC, etc.)  
- Planos de saúde (Amil, Bradesco, Sulamérica, Unimed, etc.)  
- Alas, leitos, medicamentos, laboratórios  
- Pacientes, médicos e enfermeiras  
- Atendimentos, exames, internações, prescrições, faturas  
- Pesquisas de satisfação  


