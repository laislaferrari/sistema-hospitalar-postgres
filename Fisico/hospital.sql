-- Cria o banco de dados hospital_db
create database hospital_db;

-- Remove as tabelas na ordem reversa de dependência (garante que as constraints não atrapalhem os drops)
drop table if exists usuario cascade;                   -- Tabela dos usuários do sistema (admin, médicos, enfermeiras, etc)
drop table if exists pesquisa_satisfacao cascade;       -- Tabela das pesquisas de satisfação dos pacientes
drop table if exists paciente_medico cascade;           -- Relacionamento entre pacientes e médicos
drop table if exists atendimento_enfermeira cascade;    -- Relacionamento entre atendimento e enfermeiras vinculadas
drop table if exists fatura cascade;                    -- Faturas para cobrança dos atendimentos/exames/internações
drop table if exists prescricao_medicamento cascade;    -- Prescrições de medicamentos
drop table if exists internacao cascade;                -- Registros de internação dos pacientes
drop table if exists exame cascade;                     -- Exames realizados
drop table if exists leito cascade;                     -- Leitos hospitalares
drop table if exists medicamento cascade;               -- Medicamentos cadastrados
drop table if exists atendimento cascade;               -- Atendimentos realizados
drop table if exists medico cascade;                    -- Médicos cadastrados
drop table if exists enfermeira cascade;                -- Enfermeiras cadastradas
drop table if exists ala cascade;                       -- Alas do hospital
drop table if exists laboratorio cascade;               -- Laboratórios vinculados (próprios ou parceiros)
drop table if exists hospital_plano cascade;            -- Relacionamento entre hospitais e planos de saúde
drop table if exists plano_saude cascade;               -- Planos de saúde cadastrados
drop table if exists hospital cascade;                  -- Hospitais cadastrados
drop table if exists paciente cascade;					-- Tabela dos pacientes cadastrados

-- Drop de tipos ENUM
drop type if exists perfil_usuario;
drop type if exists enum_turno;
drop type if exists tipo_ala;
drop type if exists status_leito;
drop type if exists tipo_atendimento;
drop type if exists status_atendimento;
drop type if exists tipo_cobertura;
drop type if exists status_fatura;
drop type if exists tipo_exame;
drop type if exists resultado_exame;
drop type if exists tipo_pagamento;
drop type if exists tipo_leito;
drop type if exists status_exame;

-- CRIAÇÃO DE ENUMS
-- Turnos de trabalho
create type enum_turno as enum ('manha', 'tarde', 'noite');

-- Tipos de ala hospitalar
create type tipo_ala as enum ('uti', 'enfermaria', 'pediatria', 'maternidade', 'isolamento', 'cirurgica', 'outros');

-- Status dos leitos do hospital
create type status_leito as enum ('ocupado', 'livre', 'em_manutencao', 'reservado', 'desativado');

-- Tipo de atendimento realizado
create type tipo_atendimento as enum ('consulta', 'emergencia', 'revisao', 'triagem');

-- Status do atendimento
create type status_atendimento as enum ('realizado', 'cancelado', 'agendado', 'em_espera');

-- Abrangência da cobertura do plano de saúde
create type tipo_cobertura as enum ('regional', 'nacional', 'internacional');

-- Status da fatura (pagamento/cobrança)
create type status_fatura as enum ('pendente', 'pago', 'cancelado', 'em_analise', 'reembolsado');

-- Tipos de exame possíveis
create type tipo_exame as enum ('sangue', 'imagem', 'urina', 'bacteriologico', 'citologico', 'outros', 'genetico');

-- Resultado padrão dos exames
create type resultado_exame as enum ('normal', 'alterado', 'critico', 'indeterminado');

-- Forma de pagamento das faturas
create type tipo_pagamento as enum ('dinheiro', 'cartao', 'boleto', 'transferencia', 'pix', 'outros');

-- Perfis de usuário do sistema (admin, médico, enfermeira, paciente)
create type perfil_usuario as enum ('admin', 'medico', 'enfermeira', 'paciente');

--Tipos de leitos
create type tipo_leito as enum ('pos-cirurgico', 'semi-intensivo', 'quimioterapia', 'isolamento', 'bercario', 'cirurgico', 'monitorado', 'infantil');

-- Status exames:
create type status_exame as enum ('concluido', 'pendente', 'em processamento');

--DDL criacao de Tabelas:
-- tabela dos hospitais cadastrados
create table hospital (
    id_hospital serial primary key,
    nome varchar(120) not null,
    cnpj varchar(18) not null unique,
    inscricao_estadual varchar(20),
    data_fundacao date,
    endereco varchar(255)
);

-- tabela das alas dos hospitais
create table ala (
    id_ala serial primary key,
    id_hospital int not null references hospital(id_hospital)
	    on update cascade
	    on delete cascade,
    nome varchar(100) not null,
    tipo tipo_ala not null,
    numero_leitos integer not null check (numero_leitos > 0), 
    id_enfermeira_responsavel int,
    andar int,
    capacidade_maxima int check (capacidade_maxima > 0),
    constraint unique_nomesala_hospital unique (id_hospital, nome)
);

-- tabela dos planos de saúde cadastrados
create table plano_saude (
    id_plano_saude serial primary key,
    nome varchar(120) not null unique,
    telefone varchar(20),
    cobertura tipo_cobertura not null,
    cnpj varchar(18) unique,
    observacao text
);

-- relaciona hospitais com planos de saúde credenciados
create table hospital_plano (                                           
    id_hospital_plano serial primary key,
    id_hospital int not null references hospital(id_hospital)
        on update cascade
        on delete cascade,
    id_plano_saude int not null references plano_saude(id_plano_saude)
        on update cascade
        on delete cascade, 
    data_credenciamento date not null,
    status varchar(30) default 'ativo',
    constraint unique_plano_hospital unique (id_hospital, id_plano_saude)
);

-- tabela dos pacientes cadastrados
create table paciente (
    id_paciente serial primary key,
    nome_completo varchar(100) not null,
    cpf varchar(14) not null unique,
    rg varchar(20),
    data_nascimento date not null,
    sexo char(1) check (sexo in ('m','f','o')), 
    telefone varchar(20) not null,
    email varchar(100),
    endereco varchar(200),
    nome_mae varchar(100),
    contato_emergencia varchar(100),
    tipo_sanguineo varchar(3), 
    id_plano_saude integer references plano_saude(id_plano_saude)
        on update cascade
        on delete set null,
    alergias text,
    observacao text
);

-- tabela de enfermeiras/os cadastradas
create table enfermeira (
    id_enfermeira serial primary key,
    nome_completo varchar(100) not null,
    cpf varchar(14) not null unique,
    cre varchar(15) not null unique, 
    turno enum_turno not null,
    id_ala integer references ala(id_ala) 
        on update cascade 
        on delete no action,
    id_enfermeira_chefe integer references enfermeira(id_enfermeira) 
        on update cascade 
        on delete no action,
    telefone varchar(20),
    email varchar(100),
    data_admissao date not null default current_date,
    data_demissao date,
    ativo boolean default true
);

-- tabela dos médicos cadastrados
create table medico (
    id_medico serial primary key,
    nome_completo varchar(100) not null,
    cpf varchar(14) not null unique,
    crm varchar(15) not null unique,         
    especialidade varchar(60) not null,
    telefone varchar(20),
    email varchar(100),
    data_admissao date not null default current_date,
    data_demissao date,
    ativo boolean default true,
    conselho_regional varchar(5)    
);

-- tabela de leitos hospitalares
create table leito (
    id_leito serial primary key,
    id_ala integer not null references ala(id_ala)
	    on update cascade
	    on delete cascade,
    codigo_leito varchar(20) not null,       
    status status_leito,
    observacao text,
    tipo_leito tipo_leito,
    constraint unique_codigo_leito_ala unique (id_ala, id_leito)
);

-- tabela de atendimentos realizados
create table atendimento (
    id_atendimento serial primary key,
    id_paciente integer not null references paciente(id_paciente)
	    on update cascade
	    on delete cascade,
    id_medico integer not null references medico(id_medico)
	    on update cascade
	    on delete cascade,
    data_atendimento date not null,
    hora_atendimento time not null,
    tipo tipo_atendimento not null,
    status status_atendimento not null,
    observacoes text,
    id_leito integer references leito(id_leito)
    on update cascade
    on delete no action,
    prioridade integer check (prioridade between 1 and 5)
);

-- cadastro dos medicamentos disponíveis
create table medicamento (
    id_medicamento serial primary key,
    nome varchar(100) not null,
    laboratorio_fabricante varchar(100),
    descricao text,
    principio_ativo varchar(200),
    tarja varchar(20),
    tipo_administracao varchar(50),
    quantidade_estoque integer default 0
);

-- registra prescrição de medicamentos em atendimentos
create table prescricao_medicamento (
    id_prescricao_medicamento serial primary key,
    id_atendimento integer not null references atendimento(id_atendimento)
	    on update cascade
	    on delete cascade,
    id_medico integer not null references medico(id_medico),
    id_medicamento integer not null references medicamento(id_medicamento)
	    on update cascade
	    on delete cascade,
    data_prescricao timestamp not null,
    dosagem varchar(60) not null,
    instrucoes text,
    quantidade integer check (quantidade > 0)
);

-- tabela dos laboratórios parceiros/cadastrados
create table laboratorio (
    id_laboratorio serial primary key,
    nome varchar(100) not null,
    tipo varchar(20) not null,
    telefone varchar(20),
    endereco varchar(200),
    cnpj varchar(18),
    responsavel_tecnico varchar(100)
);

-- tabela de exames realizados pelos pacientes
create table exame (
    id_exame serial primary key,
    id_paciente integer not null references paciente(id_paciente)
	    on update cascade
	    on delete no action,
    id_medico_solicitante integer not null references medico(id_medico)
	    on update cascade
	    on delete no action,
    id_laboratorio integer not null references laboratorio(id_laboratorio)
	    on update cascade
	    on delete no action,
    tipo tipo_exame not null,
    data_solicitacao timestamp not null,
    data_resultado timestamp,
    descricao text not null,
    custo numeric(10,2) not null check (custo >= 0),
    resultado resultado_exame,
    arquivo_laudo bytea,  -- Suporta arquivos de ~1MB com ótima performance
    arquivo_nome varchar (),
    arquivo_tipo varchar (),
    arquivo_tamanho_bytes integer,
    observacao text,
    urgencia boolean default false,
    status status_exame default 'pendente'
);

-- cria um índice para otimizar as consultas na tabela 'exame' que buscam exames com laudo anexado (arquivo_laudo não nulo)
create index idx_exame_tem_laudo on exame (id_exame) 
where arquivo_laudo is not null;

comment on column exame.arquivo_laudo is 'armazena o binário do laudo (pdf/imagem) de até 1gb via sistema toast';

-- internações de pacientes com vínculo ao leito e responsável
create table internacao (
    id_internacao serial primary key,
    id_paciente integer not null references paciente(id_paciente)
	    on update cascade
	    on delete cascade,
    id_leito integer not null references leito(id_leito)
	    on update cascade
	    on delete cascade,
    data_entrada timestamp not null,
    data_saida timestamp,
    motivo text,
    responsavel_internacao varchar(100),
    constraint chk_datas_internacao check (data_saida is null or data_saida > data_entrada)
);

-- registro de vínculo entre paciente e médico (histórico de relação)
create table paciente_medico (
    id_paciente_medico serial primary key,
    id_paciente integer not null references paciente(id_paciente)
	    on update cascade
	    on delete no action,
    id_medico integer not null references medico(id_medico)
	    on update cascade
	    on delete no action,
    data_inicio_relacionamento date not null default current_date,
    data_fim_relacionamento date,
    constraint unique_paciente_medico unique(id_paciente, id_medico, data_inicio_relacionamento)
);

-- tabela de faturas geradas
create table fatura (
    id_fatura serial primary key,
    id_paciente integer not null references paciente(id_paciente)
	    on update cascade
	    on delete no action,
    id_plano_saude integer not null references plano_saude(id_plano_saude)
	    on update cascade
	    on delete no action,
    id_atendimento integer references atendimento(id_atendimento)
	    on update cascade
	    on delete no action,
    id_exame integer references exame(id_exame)
	    on update cascade
	    on delete no action,
    id_internacao integer references internacao(id_internacao)
	    on update cascade
	    on delete no action,
    valor numeric(12,2) not null check (valor >= 0),
    status status_fatura not null,
    forma_pagamento tipo_pagamento,
    data_emissao date not null,
    data_vencimento date not null,
    data_pagamento date,
    desconto_aplicado numeric(8,2) default 0,
    numero_nf varchar(30),
    observacao text
);

-- pesquisa de satisfação dos pacientes após o atendimento
create table pesquisa_satisfacao (
    id_satisfacao serial primary key,
    id_atendimento integer not null references atendimento(id_atendimento)
	    on update cascade
	    on delete no action,
    data_resposta date not null,
    nota_geral integer check (nota_geral between 1 and 5),
    comentario text,
    recomendaria boolean not null,
    tempo_espera_avaliacao integer check (tempo_espera_avaliacao between 1 and 5),
    resolvido boolean,
    sugestoes text
);

--tabela para cadastro de historico de users:
create table usuario (
    id_usuario serial primary key,
    login_cpf varchar(14) not null unique,
    senha_hash varchar(255) not null,
    id_perfil perfil_usuario not null,
    status boolean not null default true
);

-- ADD FOREIGN KEYS EM MOMENTO OPORTUNO
alter table ala add constraint fk_ala_enfermeira_resp foreign key (id_enfermeira_responsavel) references enfermeira(id_enfermeira);

-- garante que apenas uma internação ativa de paciente por vez (data_saida nula significa ainda ativo)
create unique index idx_unica_internacao_ativa on internacao(id_paciente) where data_saida is null;

-- TRIGGERS E FUNÇÕES DE NEGÓCIO 
-- trigger: após prescrição de medicamento, decrementa o estoque automaticamente
create or replace function decrementa_estoque_medicamento()
returns trigger as $$
begin
    update medicamento
    set quantidade_estoque = quantidade_estoque - new.quantidade
    where id_medicamento = new.id_medicamento;
    if (select quantidade_estoque from medicamento where id_medicamento = new.id_medicamento) < 0 then
        raise exception 'estoque de medicamento insuficiente!';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger tr_decrementa_estoque_medicamento
after insert on prescricao_medicamento
for each row execute function decrementa_estoque_medicamento();

-- trigger: ao internar paciente, seta o leito como ocupado
create or replace function ocupar_leito()
returns trigger as $$
begin
    update leito set status = 'ocupado'
    where id_leito = new.id_leito;
    return new;
end; 
$$ language plpgsql;

create trigger tr_ocupa_leito_internacao
after insert on internacao
for each row execute function ocupar_leito();


-- trigger: ao dar alta (data_saida preenchida), libera leito automaticamente
create or replace function libera_leito_internacao()
returns trigger as $$
begin
    if new.data_saida is not null and old.data_saida is null then
        update leito set status = 'livre' where id_leito = new.id_leito;
    end if;
    return new;
end;
$$ language plpgsql;

create trigger tr_libera_leito_internacao
after update of data_saida on internacao
for each row execute function libera_leito_internacao();

-- trigger: impede exclusão de paciente com movimentação em atendimento, internacao, exame ou fatura em aberto
create or replace function impede_remocao_paciente()
returns trigger as $$
begin
    if exists (select 1 from atendimento where id_paciente = old.id_paciente)
    or exists (select 1 from internacao where id_paciente = old.id_paciente)
    or exists (select 1 from exame where id_paciente = old.id_paciente)
    or exists (select 1 from fatura where id_paciente = old.id_paciente)
    then raise exception 'Não é possível remover paciente com registros vinculados!';
    end if;
    return old;
end;
$$ language plpgsql;

create trigger tr_impede_remocao_paciente
before delete on paciente
for each row execute function impede_remocao_paciente();

-- trigger: impede estoque negativo em atualização manual
create or replace function impede_estoque_negativo()
returns trigger as $$
begin
    if new.quantidade_estoque < 0 then
        raise exception 'Não é permitido estoque negativo!';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger tr_impede_estoque_negativo
before update of quantidade_estoque on medicamento
for each row execute function impede_estoque_negativo();

-- trigger: ao preencher data_pagamento, status da fatura vira "pago" automaticamente
create or replace function atualiza_status_fatura_pago()
returns trigger as $$
begin
    if new.data_pagamento is not null and old.data_pagamento is null then
        new.status := 'pago';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger tr_status_fatura_pago
before update of data_pagamento on fatura
for each row execute function atualiza_status_fatura_pago();

-- trigger: ao preencher resultado do exame, seta data_resultado para agora()
create or replace function preenche_data_resultado_exame()
returns trigger as $$
begin
    if new.resultado is not null and old.resultado is null then
        new.data_resultado := now();
    end if;
    return new;
end;
$$ language plpgsql;

create trigger tr_preenche_data_resultado_exame
before update of resultado on exame
for each row execute function preenche_data_resultado_exame();



-- relação das views criadas - estarão explicadas nos queries de cada exercicio:
select * from vw_faturamento_plano_2026;
select * from vw_medicos_maior_atendimento;
select * from vw_internacoes_ativas;
select * from vw_leitos_alas;
select * from vw_medicos_maior_atendimento; 
select * from vw_ocupacao_leitos;
select * from vw_qtd_exame_lab;
select * from vw_qtd_paciente_medico;
select * from vw_resultado_pendente;
select * from vw_todas_enfermeiras;
select * from vw_todos_medicos;
select * from vw_total_faturado_atendimento;

--DML - DADOS INICIAIS (INSERTS)
-- Hospital
insert into hospital (nome, cnpj, inscricao_estadual, data_fundacao, endereco) values
	('Hospital Albert Einstein', '60.765.823/0001-30', '110.123.456.111', '1955-06-04', 'Av. Albert Einstein, 627, Morumbi, São Paulo - SP'),
	('Hospital Sírio-Libanês', '60.390.283/0001-40', '110.987.654.222', '1921-11-28', 'Rua Dona Adma Jafet, 91, Bela Vista, São Paulo - SP'),
	('Hospital das Clínicas', '60.448.015/0001-54', 'ISENTO', '1944-04-19', 'Av. Dr. Enéas Carvalho de Aguiar, 255, Cerqueira César, São Paulo - SP'),
	('Hospital Moinhos de Vento', '92.685.833/0001-51', '096/0123456', '1927-10-02', 'Rua Ramiro Barcelos, 910, Moinhos de Vento, Porto Alegre - RS'),
	('Hospital Santa Izabel', '15.153.745/0001-15', '063.123.456-78', '1549-03-29', 'Praça Conselheiro Almeida Couto, 500, Nazaré, Salvador - BA'),
	('Hospital Mater Dei', '17.213.912/0001-60', '062.555.444.0011', '1980-06-01', 'Rua Mato Grosso, 1100, Santo Agostinho, Belo Horizonte - MG'),
	('Hospital de Base do DF', '00.031.706/0001-20', NULL, '1960-09-12', 'SMHS - Área Especial, Q. 101, Asa Sul, Brasília - DF'),
	('Hospital Copa D''Or', '33.644.642/0001-90', '77.888.999-10', '2000-05-15', 'Rua Figueiredo de Magalhães, 875, Copacabana, Rio de Janeiro - RJ'),
	('Hospital Português de Pernambuco', '10.345.000/0001-01', '18.1.001.0055443-2', '1855-11-16', 'Av. Gov. Agamenon Magalhães, 4760, Paissandu, Recife - PE'),
	('Hospital Adventista de Manaus', '04.814.770/0001-25', '04.123.987-0', '1978-08-20', 'Av. Gov. Danilo de Matos Areosa, 139, Distrito Industrial, Manaus - AM');

select * from hospital h;

-- Planos de Saúde
insert into plano_saude (id_plano_saude, nome, cnpj, telefone, cobertura) values 
	(1, 'Amil Assistência', '29.309.127/0001-79', '(11) 3004-1000', 'nacional'),
	(2, 'Bradesco Saúde', '92.693.118/0001-60', '0800-701-2700', 'nacional'),
	(3, 'Sulamérica Saúde', '01.685.053/0001-56', '4004-4100', 'nacional'),
	(4, 'Unimed', '00.281.245/0001-32', '0800-942-0011', 'nacional'),
	(5, 'Golden Cross', '33.111.139/0001-20', '0800-728-2001', 'regional'),
	(6, 'Porto Seguro Saúde', '61.198.164/0001-60', '(11) 3366-3003', 'regional'),
	(7, 'NotreDame Intermédica', '44.649.812/0001-38', '0800-015-3855', 'regional'),
	(8, 'Hapvida', '63.554.067/0001-13', '4002-3633', 'regional'),
	(9, 'Care Plus', '66.216.730/0001-08', '0800-13-2992', 'internacional'),
	(10, 'Allianz Saúde', '04.439.627/0001-00', '0800-232-2222', 'nacional');

select * from plano_saude ps;

-- Hospitais x Planos
insert into hospital_plano (id_hospital, id_plano_saude, data_credenciamento, status) values 
	(1, 1, '2026-03-15', 'ativo'),
	(1, 2, '2026-03-20', 'ativo'),
	(2, 2, '2026-03-10', 'ativo'),
	(3, 4, '2026-03-05', 'ativo'),
	(4, 3, '2026-03-22', 'ativo'),
	(5, 8, '2026-03-30', 'suspenso'),
	(6, 5, '2026-03-14', 'ativo'),
	(8, 6, '2026-03-01', 'ativo'),
	(9, 9, '2026-03-28', 'em análise'),
	(10, 7, '2026-03-12', 'inativo');

select * from hospital_plano;

-- Alas
insert into ala (id_hospital, nome, tipo, numero_leitos, andar, capacidade_maxima) values
    (1, 'UTI Adulto - Bloco A', 'uti', 20, 3, 25),
    (1, 'Maternidade Rosa', 'maternidade', 15, 2, 20),
    (2, 'Ala Pediátrica Central', 'pediatria', 12, 1, 15),
    (2, 'Centro Cirúrgico Leste', 'cirurgica', 8, 4, 10),
    (3, 'Pronto Atendimento 24h', 'outros', 30, 0, 40),
    (4, 'Unidade Coronariana', 'uti', 10, 5, 12),
    (5, 'Ala Geriátrica', 'enfermaria', 25, 1, 30),
    (6, 'Oncologia Integrada', 'enfermaria', 18, 6, 22),
    (8, 'Ala de Recuperação Pós-Anestésica', 'cirurgica', 6, 4, 8),
    (10, 'Isolamento Infectologia', 'isolamento', 5, 2, 6);

select * from ala a;

-- Leitos
insert into leito (id_ala, codigo_leito, status, tipo_leito, observacao) values
	(1, 'UTI-01', 'livre', 'monitorado', 'Leito com respirador de reserva'),
	(1, 'UTI-02', 'ocupado', 'monitorado', 'Paciente estável'),
	(2, 'MAT-101', 'livre', 'bercario', 'Próximo ao posto de enfermagem'),
	(3, 'PED-05', 'ocupado', 'infantil', 'Decoração temática'),
	(4, 'CC-01', 'em_manutencao', 'cirurgico', 'Aguardando reparo na maca elétrica'),
	(5, 'GER-20', 'livre', 'semi-intensivo', 'Barreiras laterais reforçadas'),
	(6, 'ONCO-03', 'ocupado', 'quimioterapia', 'Poltrona reclinável elétrica'),
	(8, 'REC-01', 'livre', 'pos-cirurgico', 'Equipado com monitor multiparamétrico'),
	(10, 'ISO-01', 'ocupado', 'isolamento', 'Pressão negativa ativa'),
	(2, 'MAT-102', 'livre', 'bercario', NULL);

select * from leito l;

-- Medicamentos
insert into medicamento (nome, laboratorio_fabricante, principio_ativo, tarja, tipo_administracao, quantidade_estoque, descricao) values
	('Dipirona Monoidratada', 'Medley', 'Dipirona', 'Livre', 'Oral/Injetável', 500, 'Analgésico e antitérmico comum.'),
	('Amoxicilina + Clavulanato', 'EMS', 'Amoxicilina', 'Vermelha', 'Oral', 120, 'Antibiótico de amplo espectro.'),
	('Rivotril', 'Roche', 'Clonazepam', 'Preta', 'Oral', 45, 'Benzodiazepínico para controle de ansiedade e convulsão.'),
	('Insulina Regular', 'Novo Nordisk', 'Insulina Humana', 'Vermelha', 'Subcutânea', 80, 'Controle de glicemia hospitalar.'),
	('Morfina', 'Cristália', 'Sulfato de Morfina', 'Preta', 'Injetável', 30, 'Analgésico opióide para dor intensa.'),
	('Losartana Potássica', 'Eurofarma', 'Losartana', 'Vermelha', 'Oral', 300, 'Anti-hipertensivo.'),
	('Dexametasona', 'Aché', 'Dexametasona', 'Vermelha', 'Injetável', 150, 'Corticosteroide anti-inflamatório.'),
	('Omeprazol', 'Neo Química', 'Omeprazol', 'Vermelha', 'Oral', 250, 'Inibidor da bomba de prótons para proteção gástrica.'),
	('Adrenalina', 'Hipolabor', 'Epinefrina', 'Vermelha', 'Injetável', 20, 'Uso em emergências e paradas cardiorrespiratórias.'),
	('Cloreto de Sódio 0,9%', 'JP Farma', 'Soro Fisiológico', 'Livre', 'Intravenosa', 1000, 'Solução para hidratação e diluição de medicamentos.');

select * from medicamento m;

-- Laboratórios
insert into laboratorio (nome, tipo, telefone, endereco, cnpj, responsavel_tecnico) values
	('Laboratório Central de Análises', 'Geral', '(11) 4002-8922', 'Av. Paulista, 1500, São Paulo - SP', '11.222.333/0001-44', 'Dra. Márcia Fernandes'),
	('BioImagem Diagnósticos', 'Imagem', '(21) 3344-5566', 'Rua das Palmeiras, 45, Rio de Janeiro - RJ', '22.333.444/0001-55', 'Dr. Roberto Souza'),
	('Hematocentro Especializado', 'Hematologia', '(31) 2233-4455', 'Av. Afonso Pena, 900, Belo Horizonte - MG', '33.444.555/0001-66', 'Dr. Carlos Medeiros'),
	('LabPath Patologia Clínica', 'Patologia', '(41) 3012-9000', 'Rua Sete de Abril, 210, Curitiba - PR', '44.555.666/0001-77', 'Dra. Helena Prestes'),
	('Genética Avançada Lab', 'Genética', '(51) 3211-4400', 'Av. Ipiranga, 6681, Porto Alegre - RS', '55.666.777/0001-88', 'Dr. André Luiz'),
	('EcoDiagnóstico Infantil', 'Imagem', '(81) 3441-2233', 'Rua do Futuro, 120, Recife - PE', '66.777.888/0001-99', 'Dra. Beatriz Santos'),
	('Toxicologia Express', 'Exames', '(61) 3322-1100', 'Setor Comercial Sul, Bloco C, Brasília - DF', '77.888.999/0001-00', 'Dr. Ricardo Nunes'),
	('Lab Imune Imunologia', 'Análises', '(71) 3240-5500', 'Av. Tancredo Neves, 400, Salvador - BA', '88.999.000/0001-11', 'Dra. Patrícia Lima'),
	('CardioLab Diagnósticos', 'Cardiologia', '(85) 3261-7788', 'Rua Barão de Studart, 50, Fortaleza - CE', '99.000.111/0001-22', 'Dr. Sergio Morocho'),
	('Laboratório Escola de Manaus', 'Pesquisa', '(92) 3611-3030', 'Av. Rodrigo Otávio, 6200, Manaus - AM', '00.111.222/0001-33', 'Dr. Wilson Amaral');

select * from laboratorio l;

-- Pacientes
insert into paciente (nome_completo, cpf, rg, data_nascimento, sexo, telefone, email, endereco, nome_mae, contato_emergencia, tipo_sanguineo, id_plano_saude, alergias, observacao) values
	('João Ricardo Silva', '111.222.333-44', '12.345.678-9', '1985-04-12', 'm', '(11) 91234-5678', 'joao.ricardo@email.com', 'Rua Augusta, 500, SP', 'Maria da Silva', 'Esposa: Ana (11) 98888-7777', 'O+', 1, 'Dipirona', 'Paciente hipertenso'),
	('Mariana Souza Oliveira', '222.333.444-55', '23.456.789-0', '1992-08-25', 'f', '(21) 92345-6789', 'mari.souza@email.com', 'Av. Atlântica, 100, RJ', 'Sônia Souza', 'Mãe: Sônia (21) 97777-6666', 'A-', 2, 'Poeira, Ácaro', NULL),
	('Carlos Eduardo Pontes', '333.444.555-66', '34.567.890-1', '1970-01-30', 'm', '(31) 93456-7890', 'carlos.pontes@email.com', 'Rua da Bahia, 300, MG', 'Teresa Pontes', 'Filha: Julia (31) 96666-5555', 'AB+', 4, NULL, 'Atleta amador'),
	('Ana Beatriz Lima', '444.555.666-77', '45.678.901-2', '2015-05-10', 'f', '(41) 94567-8901', 'ana.beatriz@email.com', 'Rua XV de Novembro, 45, PR', 'Letícia Lima', 'Pai: Roberto (41) 95555-4444', 'O-', 3, 'Amendoim', 'Paciente pediátrico'),
	('Alex Santos Luz', '555.666.777-88', '56.789.012-3', '1998-11-20', 'o', '(71) 95678-9012', 'alex.luz@email.com', 'Av. Sete de Setembro, 80, BA', 'Carmen Luz', 'Irmão: Igor (71) 94444-3333', 'B+', 8, 'Contraste iodado', NULL),
	('Roberto Carlos Gomes', '666.777.888-99', '67.890.123-4', '1955-03-05', 'm', '(51) 96789-0123', 'roberto.gomes@email.com', 'Rua dos Andradas, 12, RS', 'Alzira Gomes', 'Esposa: Vera (51) 93333-2222', 'A+', NULL, 'Penicilina', 'Usa marcapasso'),
	('Fernanda Montes', '777.888.999-00', '78.901.234-5', '1988-07-14', 'f', '(81) 97890-1234', 'fer.montes@email.com', 'Rua da Aurora, 200, PE', 'Rosa Montes', 'Amigo: Paulo (81) 92222-1111', 'O+', 7, NULL, 'Gestante 2º trimestre'),
	('Ricardo Ferreira', '888.999.000-11', '89.012.345-6', '2002-12-01', 'm', '(61) 98901-2345', 'ricardo.f@email.com', 'Asa Norte, Bloco B, DF', 'Marta Ferreira', 'Mãe: Marta (61) 91111-0000', 'AB-', 10, 'Frutos do mar', NULL),
	('Patrícia Silva', '999.000.111-22', '90.123.456-7', '1995-09-18', 'f', '(85) 99012-3456', 'patty.silva@email.com', 'Beira Mar, 50, CE', 'Antônia Silva', 'Pai: José (85) 90000-9999', 'B-', 5, 'Lactose', NULL),
	('Gabriel Américo', '000.111.222-33', '01.234.567-8', '2010-06-22', 'm', '(92) 90123-4567', 'gabriel.a@email.com', 'Rua Maceió, 15, AM', 'Sônia Américo', 'Mãe: Sônia (92) 99999-8888', 'O-', NULL, NULL, 'Tipo sanguíneo confirmado');

select * from paciente p;

-- Enfermeiras
insert into enfermeira (nome_completo, cpf, cre, turno, id_ala, id_enfermeira_chefe, telefone, email, data_admissao) values
	('Ana Paula Souza', '654.486.155-12', 'COREN/SP 001', 'manha', 1, NULL, '(11) 91111-1111', 'ana.souza@hospital.com', '2010-05-20'),
	('Beatriz Ferreira', '222.212.227-22', 'COREN/RJ 002', 'manha', 1, 1, '(21) 92222-2222', 'beatriz.f@hospital.com', '2015-08-10'),
	('Carla Mendes', '333.313.339-33', 'COREN/MG 003', 'tarde', 2, NULL, '(31) 93333-3333', 'carla.mendes@hospital.com', '2012-03-15'),
	('Daniela Prates', '444.445.444-44', 'COREN/PR 004', 'tarde', 2, 3, '(41) 94444-4444', 'daniela.p@hospital.com', '2018-11-22'),
	('Elaine Santos', '555.555.585-55', 'COREN/SC 005', 'noite', 3, NULL, '(48) 95555-5555', 'elaine.santos@hospital.com', '2014-06-30'),
	('Fernanda Lima', '666.666.668-66', 'COREN/BA 006', 'noite', 3, 5, '(71) 96666-6666', 'fernanda.lima@hospital.com', '2020-01-15'),
	('Gisele Oliveira', '777.777.747-77', 'COREN/PE 007', 'manha', 4, NULL, '(81) 97777-7777', 'gisele.o@hospital.com', '2016-09-05'),
	('Heloísa Ramos', '888.888.889-88', 'COREN/RS 008', 'tarde', 5, NULL, '(51) 98888-8888', 'heloisa.r@hospital.com', '2013-02-28'),
	('Isabela Costa', '999.999.992-99', 'COREN/CE 009', 'noite', 6, NULL, '(85) 99999-9999', 'isabela.c@hospital.com', '2021-07-12'),
	('Juliana Alves', '000.000.001-00', 'COREN/DF 010', 'manha', 1, 1, '(61) 90000-0000', 'juliana.alves@hospital.com', '2023-03-01');

select * from enfermeira e;

-- Médicos
insert into medico (nome_completo, cpf, crm, especialidade, telefone, email, data_admissao, ativo, conselho_regional) values
	('Dr. Arnaldo Silva Rocha', '123.476.789-01', 'CRM/SP 121456', 'Cardiologia', '(11) 98888-7777', 'arnaldo.rocha@hospital.com', '2015-03-10', true, 'CRM'),
	('Dra. Beatriz Helena Matos', '244.567.890-12', 'CRM/RJ 231567', 'Pediatria', '(21) 97777-6666', 'beatriz.matos@hospital.com', '2018-06-15', true, 'CRM'),
	('Dr. Cláudio Mendes Junior', '385.678.901-23', 'CRM/MG 341678', 'Ortopedia', '(31) 96666-5555', 'claudio.mendes@hospital.com', '2010-01-20', true, 'CRM'),
	('Dra. Daniela Pires', '456.789.011-34', 'CRM/PR 456189', 'Ginecologia', '(41) 95555-4444', 'daniela.pires@hospital.com', '2020-11-02', true, 'CRM'),
	('Dr. Eduardo Ferreira', '567.890.153-45', 'CRM/SC 567110', 'Neurologia', '(48) 94444-3333', 'eduardo.ferreira@hospital.com', '2012-05-22', true, 'CRM'),
	('Dra. Fernanda Oliveira', '678.971.234-56', 'CRM/BA 678101', 'Dermatologia', '(71) 93333-2222', 'fernanda.oliveira@hospital.com', '2019-08-30', true, 'CRM'),
	('Dr. Gabriel Souza Lima', '789.018.345-67', 'CRM/PE 789112', 'Infectologia', '(81) 92222-1111', 'gabriel.lima@hospital.com', '2021-02-14', true, 'CRM'),
	('Dra. Heloísa Castro', '890.123.756-78', 'CRM/RS 891123', 'Oncologia', '(51) 91111-0000', 'heloisa.castro@hospital.com', '2017-12-01', true, 'CRM'),
	('Dr. Ítalo Bruno Santos', '901.214.567-89', 'CRM/CE 901214', 'Psiquiatria', '(85) 90000-9999', 'italo.santos@hospital.com', '2014-04-10', false, 'CRM'),
	('Dra. Julia Almeida', '012.345.679-90', 'CRM/DF 012315', 'Clínica Geral', '(61) 99999-8888', 'julia.almeida@hospital.com', '2023-01-05', true, 'CRM');

select * from medico;

-- Atendimentos
insert into atendimento (id_paciente, id_medico, data_atendimento, hora_atendimento, tipo, status, prioridade, id_leito, observacoes) values
	(1, 1, '2026-03-01', '08:30', 'consulta', 'realizado', 1, NULL, 'Retorno cardiológico de rotina.'),
	(2, 2, '2026-03-01', '09:15', 'emergencia', 'realizado', 4, NULL, 'Febre alta e desidratação.'),
	(3, 3, '2026-03-02', '10:00', 'triagem', 'em_espera', 3, 4, 'Pós-operatório de joelho.'),
	(4, 2, '2026-03-02', '11:30', 'consulta', 'agendado', 1, NULL, 'Check-up pediátrico.'),
	(5, 5, '2026-03-03', '14:00', 'emergencia', 'realizado', 5, 1, 'Crise convulsiva severa.'),
	(6, 1, '2026-03-03', '15:45', 'consulta', 'realizado', 2, NULL, 'Ajuste de medicação hipertensiva.'),
	(7, 8, '2026-03-04', '08:00', 'triagem', 'em_espera', 4, 7, 'Início de ciclo de quimioterapia.'),
	(8, 7, '2026-03-04', '10:20', 'emergencia', 'realizado', 3, NULL, 'Suspeita de infecção viral.'),
	(9, 9, '2026-03-05', '13:00', 'consulta', 'agendado', 1, NULL, 'Acompanhamento psiquiátrico.'),
	(10, 10, '2026-03-05', '16:30', 'consulta', 'realizado', 2, NULL, 'Sintomas gripais leves.'),
	(1, 10, '2026-03-06', '09:00', 'emergencia', 'em_espera', 5, 9, 'Falta de ar aguda.'),
	(3, 3, '2026-03-06', '11:15', 'revisao', 'realizado', 2, NULL, 'Retirada de pontos.'),
	(2, 4, '2026-03-07', '08:45', 'consulta', 'agendado', 1, NULL, 'Exame ginecológico preventivo.'),
	(5, 5, '2026-03-07', '14:30', 'consulta', 'realizado', 2, NULL, 'Avaliação de exames neurológicos.'),
	(6, 6, '2026-03-08', '10:00', 'consulta', 'agendado', 1, NULL, 'Avaliação dermatológica.'),
	(7, 8, '2026-03-08', '13:15', 'triagem', 'em_espera', 3, 7, 'Monitoramento pós-quimio.'),
	(4, 2, '2026-03-09', '15:00', 'emergencia', 'realizado', 4, 3, 'Reação alérgica alimentar.'),
	(8, 10, '2026-03-09', '09:30', 'consulta', 'realizado', 1, NULL, 'Dores lombares crônicas.'),
	(9, 9, '2026-03-10', '11:00', 'consulta', 'agendado', 2, NULL, 'Sessão de terapia mensal.'),
	(10, 1, '2026-03-10', '16:00', 'triagem', 'em_espera', 5, 1, 'Infarto agudo do miocárdio.');

select * from atendimento;

-- Exames
insert into exame (id_paciente, id_medico_solicitante, id_laboratorio, tipo, data_solicitacao, data_resultado, descricao, custo, resultado, urgencia, status) values
	(1, 1, 1, 'sangue', '2026-03-01 08:00', '2026-03-01 16:00', 'Hemograma Completo', 45.00, 'normal', false, 'concluido'),
	(1, 10, 9, 'imagem', '2026-03-06 09:30', '2026-03-06 11:00', 'Ecocardiograma Doppler', 350.00, 'alterado', true, 'concluido'),
	(1, 1, 1, 'sangue', '2026-03-10 10:00', NULL, 'Glicemia de Jejum', 25.00, NULL, false, 'pendente'),
	(2, 2, 6, 'imagem', '2026-03-01 10:00', '2026-03-01 12:00', 'Ultrassonografia Abdominal', 220.00, 'alterado', true, 'concluido'),
	(2, 4, 1, 'urina', '2026-03-07 09:00', '2026-03-08 14:00', 'EAS e Cultura', 40.00, 'normal', false, 'concluido'),
	(2, 2, 8, 'outros', '2026-03-12 15:00', NULL, 'Teste Alérgico Cutâneo', 150.00, NULL, false, 'pendente'),
	(3, 3, 2, 'imagem', '2026-03-02 11:00', '2026-03-02 14:00', 'Raio-X Joelho Esquerdo', 95.00, 'alterado', false, 'concluido'),
	(3, 3, 2, 'imagem', '2026-03-06 12:00', '2026-03-06 15:00', 'Tomografia de Articulação', 450.00, 'normal', true, 'concluido'),
	(3, 3, 1, 'sangue', '2026-03-15 08:30', NULL, 'Proteína C Reativa', 60.00, NULL, false, 'em processamento'),
	(4, 2, 6, 'imagem', '2026-03-02 14:00', '2026-03-02 16:00', 'Raio-X de Tórax (Ped)', 85.00, 'normal', false, 'concluido'),
	(4, 2, 1, 'sangue', '2026-03-09 10:00', '2026-03-10 09:00', 'Dosagem de Ferro', 55.00, 'normal', false, 'concluido'),
	(5, 5, 2, 'imagem', '2026-03-03 14:30', '2026-03-03 16:30', 'Ressonância Magnética Crânio', 850.00, 'alterado', true, 'concluido'),
	(5, 5, 5, 'genetico', '2026-03-03 15:00', NULL, 'Sequenciamento de Exoma', 2500.00, NULL, false, 'pendente'),
	(5, 5, 1, 'sangue', '2026-03-07 08:00', '2026-03-07 18:00', 'Nível Sérico Anticonvulsivante', 120.00, 'normal', false, 'concluido'),
	(6, 1, 9, 'imagem', '2026-03-03 16:00', '2026-03-04 10:00', 'Eletrocardiograma', 70.00, 'normal', false, 'concluido'),
	(6, 6, 8, 'outros', '2026-03-08 11:00', NULL, 'Biópsia de Lesão Cutânea', 320.00, NULL, false, 'em processamento'),
	(7, 8, 3, 'sangue', '2026-03-04 09:00', '2026-03-04 17:00', 'Marcadores Tumorais CEA', 210.00, 'alterado', true, 'concluido'),
	(7, 8, 1, 'sangue', '2026-03-08 07:30', '2026-03-08 14:00', 'Função Hepática TGO/TGP', 65.00, 'normal', false, 'concluido'),
	(7, 8, 2, 'imagem', '2026-03-15 13:00', NULL, 'PET-Scan Corpo Inteiro', 3500.00, NULL, true, 'pendente'),
	(8, 7, 7, 'outros', '2026-03-04 10:45', '2026-03-05 15:00', 'Painel Toxicológico 10 Substâncias', 180.00, 'normal', false, 'concluido'),
	(8, 10, 1, 'sangue', '2026-03-09 11:00', '2026-03-09 17:00', 'Creatinina e Ureia', 45.00, 'normal', false, 'concluido'),
	(9, 9, 1, 'sangue', '2026-03-05 13:30', '2026-03-06 09:00', 'TSH e T4 Livre', 90.00, 'normal', false, 'concluido'),
	(9, 9, 1, 'sangue', '2026-03-10 08:00', NULL, 'Dosagem de Lítio', 110.00, NULL, false, 'pendente'),
	(10, 10, 10, 'outros', '2026-03-05 17:00', '2026-03-05 18:00', 'Teste Rápido Antígeno COVID', 100.00, 'normal', true, 'concluido'),
	(10, 1, 9, 'imagem', '2026-03-10 16:30', NULL, 'Angiotomografia Coronariana', 1200.00, NULL, true, 'em processamento'),
	(2, 2, 4, 'citologico', '2026-03-11 09:00', NULL, 'Citopatológico Cervical', 130.00, NULL, false, 'pendente'),
	(4, 2, 1, 'sangue', '2026-03-11 10:30', '2026-03-11 16:00', 'Glicose Pós-Prandial', 30.00, 'normal', false, 'concluido'),
	(6, 6, 8, 'outros', '2026-03-12 08:15', NULL, 'Mapeamento de Nevus', 400.00, NULL, false, 'pendente'),
	(8, 10, 2, 'imagem', '2026-03-13 14:20', '2026-03-13 17:00', 'RM de Coluna Lombar', 780.00, 'critico', false, 'concluido'),
	(1, 10, 1, 'sangue', '2026-03-14 09:00', '2026-03-14 15:00', 'Troponina Ultra-sensível', 140.00, 'critico', true, 'concluido');

select * from exame e;

-- Internação
insert into internacao (id_paciente, id_leito, data_entrada, data_saida, motivo, responsavel_internacao) values
	(1, 1, '2026-03-01 10:00', '2026-03-05 14:30', 'Observação pós-arritmia', 'Dr. Arnaldo Silva Rocha'),
	(2, 3, '2026-03-02 08:15', '2026-03-03 10:00', 'Desidratação severa', 'Dra. Beatriz Helena Matos'),
	(4, 3, '2026-03-10 15:20', '2026-03-12 09:00', 'Crise asmática', 'Dra. Beatriz Helena Matos'),
	(6, 1, '2026-03-15 22:00', '2026-03-17 11:45', 'Pico hipertensivo', 'Dr. Arnaldo Silva Rocha'),
	(8, 8, '2026-03-20 14:00', '2026-03-21 16:30', 'Reação alérgica a medicamento', 'Dra. Julia Almeida'),
	(10, 9, '2026-03-25 07:45', '2026-03-26 18:00', 'Suspeita de COVID-19', 'Dra. Julia Almeida'),
	(3, 4, '2026-03-02 10:00', '2026-03-04 15:00', 'Pós-operatório ortopédico', 'Dr. Cláudio Mendes Junior'),
	(5, 1, '2026-03-03 14:00', '2026-03-05 12:00', 'Estabilização pós-convulsão', 'Dr. Eduardo Ferreira'),
	(1, 1, '2026-03-06 09:00', '2026-03-08 10:00', 'Insuficiência respiratória', 'Dra. Julia Almeida'),
	(9, 6, '2026-03-07 11:30', '2026-03-07 23:00', 'Ajuste de dosagem de Lítio', 'Dr. Ítalo Bruno Santos'),
	(7, 7, '2026-03-04 08:00', NULL, 'Tratamento quimioterápico cíclico', 'Dra. Heloísa Castro'),
	(10, 1, '2026-03-10 16:00', NULL, 'Recuperação infarto miocárdio', 'Dr. Arnaldo Silva Rocha'),
	(2, 3, '2026-03-12 09:00', NULL, 'Pneumonia aspirativa', 'Dra. Beatriz Helena Matos'),
	(5, 10, '2026-03-13 14:20', NULL, 'Isolamento por infecção bacteriana', 'Dr. Gabriel Souza Lima'),
	(3, 5, '2026-03-14 11:00', NULL, 'Recuperação cirúrgica complexa', 'Dr. Cláudio Mendes Junior'),
	(8, 4, '2026-03-15 08:30', NULL, 'Traumatismo craniano leve', 'Dr. Cláudio Mendes Junior'),
	(4, 3, '2026-03-15 10:15', NULL, 'Infecção urinária persistente', 'Dra. Beatriz Helena Matos'),
	(1, 2, '2026-03-16 07:00', NULL, 'Monitoramento cardíaco 48h', 'Dr. Arnaldo Silva Rocha'),
	(6, 6, '2026-03-16 13:45', NULL, 'Complicação oncológica', 'Dra. Heloísa Castro'),
	(9, 10, '2026-03-17 06:20', NULL, 'Isolamento preventivo', 'Dra. Julia Almeida'),
	(5, 1, '2026-02-01 12:00', '2026-02-05 10:00', 'Investigação neurológica', 'Dr. Eduardo Ferreira'),
	(7, 7, '2026-02-10 09:00', '2026-02-12 18:00', 'Ciclo 1 quimioterapia', 'Dra. Heloísa Castro'),
	(2, 3, '2026-02-15 14:00', '2026-02-16 09:00', 'Viroses tropicais', 'Dra. Beatriz Helena Matos'),
	(10, 9, '2026-02-20 20:00', '2026-02-22 11:00', 'Crise de ansiedade aguda', 'Dr. Ítalo Bruno Santos'),
	(4, 3, '2026-02-25 15:30', '2026-02-27 12:00', 'Bronquiolite', 'Dra. Beatriz Helena Matos'),
	(6, 5, '2026-01-01 08:00', '2026-01-15 14:00', 'Reabilitação motora longa', 'Dr. Cláudio Mendes Junior'),
	(8, 2, '2026-01-20 10:00', '2026-01-21 16:00', 'Check-up invasivo', 'Dr. Arnaldo Silva Rocha'),
	(3, 4, '2026-01-10 09:00', '2026-01-12 11:00', 'Artroscopia', 'Dr. Cláudio Mendes Junior'),
	(1, 1, '2026-01-15 14:00', '2026-01-20 10:00', 'Angina instável', 'Dr. Arnaldo Silva Rocha'),
	(5, 10, '2026-01-01 08:00', '2026-01-03 09:00', 'Febre de origem desconhecida', 'Dr. Gabriel Souza Lima');

select * from internacao i;

-- Prescrição de Medicamento
insert into prescricao_medicamento (id_atendimento, id_medico, id_medicamento, data_prescricao, dosagem, quantidade, instrucoes) values
	(1, 1, 1, '2026-03-01', '500mg', 1, 'Tomar se houver dor ou febre.'),
	(2, 2, 2, '2026-03-01', '875mg + 125mg', 14, 'Tomar 1 comprimido de 12/12h por 7 dias.'),
	(3, 3, 5, '2026-03-02', '10mg/ml', 2, 'Aplicar via IV para dor intensa pós-operatória.'),
	(5, 5, 3, '2026-03-03', '2mg', 30, '1 comprimido ao deitar para controle de crises.'),
	(5, 5, 3, '2026-03-01', '2mg', 10, '1 comprimido de SOS quando estiver com crise.'),
	(7, 8, 7, '2026-03-04', '4mg/ml', 5, 'Aplicar via IM antes da quimioterapia.'),
	(10, 10, 8, '2026-03-05', '20mg', 30, 'Tomar 1 cápsula em jejum para proteção gástrica.'),
	(11, 10, 9, '2026-03-06', '1mg/ml', 5, 'Uso restrito em caso de parada cardiorrespiratória.'),
	(17, 2, 1, '2026-03-09', '200mg/ml', 1, '40 gotas se necessário.'),
	(20, 1, 10, '2026-03-10', '500ml', 4, 'Infusão contínua para hidratação venosa.'),
	(12, 3, 1, '2026-03-06', '500mg', 10, 'Uso conforme necessidade para dor.');

select * from prescricao_medicamento;

-- Fatura
insert into fatura (id_paciente, id_plano_saude, id_atendimento, id_exame, id_internacao, valor, status, forma_pagamento, data_emissao, data_vencimento, data_pagamento, desconto_aplicado, numero_nf) values
	(1, 1, 1, NULL, NULL, 150.00, 'pago', 'cartao', '2026-03-01', '2026-03-15', '2026-03-01', 10.00, 'NF-2026-001'),
	(2, 2, NULL, 2, NULL, 220.00, 'pago', 'pix', '2026-03-01', '2026-03-10', '2026-03-02', 0.00, 'NF-2026-002'),
	(3, 4, NULL, NULL, 7, 1500.00, 'pendente', NULL, '2026-03-04', '2026-03-30', NULL, 0.00, 'NF-2026-003'),
	(5, 5, NULL, 5, NULL, 2500.00, 'cancelado', NULL, '2026-03-03', '2026-03-17', NULL, 250.00, NULL),
	(5, 5, 5, NULL, NULL, 850.00, 'pago', 'boleto', '2026-03-03', '2026-03-10', '2026-03-05', 50.00, 'NF-2026-005'),
	(7, 8, NULL, NULL, 11, 4500.00, 'pendente', NULL, '2026-03-15', '2026-04-05', NULL, 0.00, 'NF-2026-006'),
	(8, 1, NULL, 21, NULL, 45.00, 'pago', 'dinheiro', '2026-03-09', '2026-03-15', '2026-03-09', 0.00, 'NF-2026-007'),
	(9, 9, 9, NULL, NULL, 300.00, 'em_analise', NULL, '2026-03-05', '2026-03-12', NULL, 0.00, 'NF-2026-008'),
	(10, 7, NULL, 24, NULL, 100.00, 'pago', 'pix', '2026-03-05', '2026-03-10', '2026-03-05', 0.00, 'NF-2026-009'),
	(1, 1, NULL, NULL, 15, 3200.00, 'pendente', NULL, '2026-03-20', '2026-04-10', NULL, 100.00, 'NF-2026-010');

select * from fatura f;

-- Pesquisa de Satisfação
insert into pesquisa_satisfacao (id_atendimento, data_resposta, nota_geral, comentario, recomendaria, tempo_espera_avaliacao, resolvido, sugestoes) values
	(1, '2026-03-01', 5, 'Dr. Arnaldo foi muito atencioso no retorno.', true, 5, true, 'Nenhuma'),
	(2, '2026-03-01', 3, 'Médica excelente, mas recepção confusa.', true, 2, true, 'Treinar recepcionistas'),
	(3, '2026-03-04', 5, 'A cirurgia de joelho correu muito bem.', true, 4, true, 'TV do quarto falhando'),
	(4, '2026-03-02', 5, 'Dra. Beatriz é a melhor pediatra.', true, 4, true, 'Área kids limpa'),
	(5, '2026-03-03', 3, 'Equipe técnica boa, mas fria.', true, 3, true, 'Atendimento humanizado'),
	(6, '2026-03-03', 5, 'Sempre sou bem tratado aqui.', true, 5, true, NULL),
	(7, '2026-03-04', 5, 'Equipe da oncologia é nota 10.', true, 4, true, 'Cadeiras da quimio confortáveis'),
	(8, '2026-03-04', 2, 'Muitos formulários para preencher.', false, 2, true, 'Digitalizar processos'),
	(9, '2026-03-05', 5, 'Terapia muito produtiva.', true, 5, true, NULL),
	(10, '2026-03-05', 4, 'Sintomas gripais tratados com rapidez.', true, 4, true, NULL),
	(11, '2026-03-06', 4, 'Atendimento de emergência rápido.', true, 4, true, 'Melhorar lanche da espera'),
	(12, '2026-03-06', 4, 'Retirada de pontos rápida.', true, 5, true, NULL),
	(13, '2026-03-07', 5, 'Exame ginecológico muito tranquilo.', true, 5, true, NULL),
	(14, '2026-03-07', 4, 'Neurologista explicou tudo muito bem.', true, 4, true, NULL),
	(15, '2026-03-08', 4, 'Dermatologista pontual.', true, 5, true, NULL),
	(16, '2026-03-08', 4, 'Monitoramento constante, me senti segura.', true, 4, true, NULL),
	(17, '2026-03-09', 2, 'Demora excessiva para medicação infantil.', false, 1, false, 'Mais enfermeiras na pediatria'),
	(18, '2026-03-09', 4, 'Dr. Julia resolveu minha dor lombar.', true, 3, true, NULL),
	(19, '2026-03-10', 4, 'Ambiente calmo e acolhedor.', true, 4, true, NULL),
	(20, '2026-03-10', 5, 'Enfermeiras do isolamento muito prestativas.', true, 5, true, 'Melhorar o tempero da comida');

select * from pesquisa_satisfacao ps;

-- Usuários
insert into usuario (login_cpf, senha_hash, id_perfil, status) values
	('123.456.789-01', 'med123#hash', 'medico', true),
	('234.567.890-12', 'med234#hash', 'medico', true),
	('345.678.901-23', 'med345#hash', 'medico', true),
	('456.789.012-34', 'med456#hash', 'medico', true),
	('567.890.123-45', 'med567#hash', 'medico', true),
	('678.901.234-56', 'med678#hash', 'medico', true),
	('789.012.345-67', 'med789#hash', 'medico', true),
	('890.123.456-78', 'med890#hash', 'medico', true),
	('901.234.567-89', 'med901#hash', 'medico', false), 
	('012.345.678-90', 'med012#hash', 'medico', true),
	('111.111.111-11', 'enf111#hash', 'enfermeira', true),
	('222.222.222-22', 'enf222#hash', 'enfermeira', true),
	('333.333.333-33', 'enf333#hash', 'enfermeira', true),
	('444.444.444-44', 'enf444#hash', 'enfermeira', true),
	('555.555.555-55', 'enf555#hash', 'enfermeira', true),
	('111.222.333-44', 'pac111#hash', 'paciente', true),
	('222.333.444-55', 'pac222#hash', 'paciente', true),
	('333.444.555-66', 'pac333#hash', 'paciente', true),
	('999.888.777-66', 'adm999#hash', 'admin', true),
	('888.777.666-55', 'adm888#hash', 'admin', true);

select * from usuario u;

-- Paciente-Médico
insert into paciente_medico (id_paciente, id_medico, data_inicio_relacionamento, data_fim_relacionamento) values
	(1, 1, '2026-03-01', NULL),
	(2, 2, '2026-03-02', NULL),
	(3, 3, '2026-03-03', NULL),
	(4, 2, '2026-03-04', NULL),
	(5, 5, '2026-03-05', NULL),
	(6, 1, '2026-03-06', NULL),
	(7, 8, '2026-03-07', NULL),
	(8, 7, '2026-03-08', NULL),
	(9, 9, '2026-03-09', NULL),
	(10, 10, '2026-03-10', NULL),
	(1, 10, '2026-03-01', '2026-03-10'),
	(2, 4, '2026-03-02', '2026-03-05'),
	(5, 7, '2026-03-05', '2026-03-09'),
	(8, 10, '2026-03-08', '2026-03-10'),
	(3, 10, '2026-03-03', '2026-03-09'),
	(1, 4, '2026-03-04', NULL),
	(4, 6, '2026-03-06', NULL),
	(6, 8, '2026-03-08', NULL),
	(9, 5, '2026-03-09', NULL),
	(10, 2, '2026-03-10', NULL);

select * from paciente_medico pm;

-- Um comando SQL de atualização em algum registro em uma tabela (DML)
update medicamento set quantidade_estoque = 100 where id_medicamento = 3;  

select nome, quantidade_estoque from medicamento where id_medicamento = 3;

update paciente set  telefone = '24-98853-1977' where id_paciente = 2;

select nome_completo, telefone from paciente where id_paciente = 2;

-- Um comando SQL de exclusão de algum registro em uma tabela (DML)
--mas antes vamos criar uma trigger para automatizar a data de demissao quando um id de enfermeira for excluido:
--por motivos de auditorias e registros internos, criamos uma tabela para o historico das enfermeiras:
drop table if exists historico_enfermeira;

create table historico_enfermeira (
    id_historico_enfermeira serial primary key,
    id_enfermeira int,
    nome_completo varchar(100),
    cre varchar(15),
    data_demissao date
);

drop trigger if exists registrar_demissao_enfermeira on enfermeira;

create or replace function registrar_demissao_enfermeira()
returns trigger as $$
begin
    insert into historico_enfermeira (id_historico_enfermeira, nome_completo, cre, data_demissao)
    values (old.id_enfermeira, old.nome_completo, old.cre, current_date);
    return old;
end;
$$ language plpgsql;

create trigger trg_demissao_enfermeira
before delete on enfermeira
for each row execute function registrar_demissao_enfermeira();


--agora sim, vamos efetuar o delete do id da enfermeira:
delete from enfermeira where id_enfermeira = 4;

--verificando a exclusão da enfermeira;
select * from enfermeira e;

--verificando se a tabela do historico foi atualizada com a data de demissao atual:
select * from historico_enfermeira;

--como não faz mais sentido ter na tabela principal de enfermeiras a linha "data_demissao", vamos exclui-la e criar uma view para visializar TODAS as enfermeiras que passaram pelo sistema:
alter table enfermeira drop column data_demissao;

--criar um view para ver todas a enfermeiras:
create or replace view vw_todas_enfermeiras as
select 
    e.id_enfermeira,
    e.nome_completo,
    e.cre,
    null::date as data_demissao
from enfermeira e
union
select 
    h.id_enfermeira,
    h.nome_completo,
    h.cre,
    h.data_demissao
from historico_enfermeira h;

--visualizar a view:
select * from vw_todas_enfermeiras;

-- decidimos aplicar também na tabela médicos:
drop table if exists historico_medico;

create table historico_medico (
    id_historico_medico serial primary key,
    id_medico int,
    nome_completo varchar(100),
    cpf varchar(14),
    crm varchar(15),
    especialidade varchar(60),
    telefone varchar(20),
    email varchar(100),
    data_admissao date,
    data_demissao date,
    conselho_regional varchar(5)
);

create or replace function registrar_demissao_medico()
returns trigger as $$
begin
    insert into historico_medico (
        id_medico, nome_completo, cpf, crm, especialidade, telefone, email, data_admissao, data_demissao, conselho_regional
    )
    values (
        old.id_medico, old.nome_completo, old.cpf, old.crm, old.especialidade, old.telefone, old.email, old.data_admissao, current_date, old.conselho_regional
    );
    return old;
end;
$$ language plpgsql;

drop trigger if exists trg_demissao_medico on medico;

create trigger trg_demissao_medico
before delete on medico
for each row execute function registrar_demissao_medico();

delete from medico where id_medico = 3;

--como não faz mais sentido ter na tabela principal de medico a linha "data_demissao", vamos exclui-la e criar uma view para visializar TODAS as enfermeiras que passaram pelo sistema:
alter table medico drop column data_demissao;

--criar um view para ver todos os medicos ja cadastrados no sistema:
create or replace view vw_todos_medicos as
select m.id_medico, m.nome_completo, m.crm,
    null::date as data_demissao
from medico m
union
select 
    hm.id_medico, hm.nome_completo, hm.crm, hm.data_demissao
from historico_medico hm;

--visualizar a view:
select * from vw_todos_medicos;


-- Consultas Leitos e Alas
--view select:
drop view if exists vw_leitos_alas;

create or replace view vw_leitos_alas as
select
	h.nome as hospital, a.nome as ala,
    l.id_leito, l.codigo_leito, l.status, l.tipo_leito, l.observacao
from leito l
join ala a on l.id_ala = a.id_ala
join hospital h on a.id_hospital = h.id_hospital
order by h.nome, a.nome, l.id_leito;

--select da view:
select * from vw_leitos_alas;

-- Quais são os nomes e telefones de todos os médicos da especialidade “Cardiologia”?
select nome_completo, telefone from medico 
where especialidade = 'Cardiologia';

-- Liste o nome e o CPF de todos os pacientes que possuem o plano de saúde “Unimed”.
select p.nome_completo, p.cpf from paciente p
join plano_saude ps on p.id_plano_saude = ps.id_plano_saude
where ps.nome ilike 'Unimed';

-- Quais exames ainda não têm resultado (data_resultado IS NULL) e foram solicitados no mês atual?
--View do select:
create or replace view vw_resultado_pendente as
select 
    e.id_exame,
    p.nome_completo as paciente,
    e.tipo as tipo_exame,
    e.data_solicitacao, e.status, e.urgencia
from exame e
join paciente p on e.id_paciente = p.id_paciente
where e.data_resultado is null;

--exibir a view:
select * from vw_resultado_pendente;

-- Quantidade de exames por laboratório.
create or replace view vw_qtd_exame_lab as
select 
    l.nome as laboratorio,
    count(e.id_exame) as quantidade_exames
from exame e
join laboratorio l on e.id_laboratorio = l.id_laboratorio
group by l.nome
order by quantidade_exames desc;

select * from vw_qtd_exame_lab;

-- Liste o nome do paciente, o número do leito e a data de entrada para todas as internações ativas (data_saida IS NULL).
create or replace view vw_internacoes_ativas as
select
	l.id_leito, p.nome_completo as nome_paciente,
    l.codigo_leito, i.data_entrada from internacao i
join paciente p on i.id_paciente = p.id_paciente
join leito l on i.id_leito = l.id_leito
where i.data_saida is null;

select * from vw_internacoes_ativas;

-- Quantos atendimentos cada médico realizou no último mês? Apresente o nome do médico e a quantidade.
create or replace view vw_consultas_ultimo_mes as
select m.nome_completo, count(*) as qtd_atendimentos from atendimento a
join medico m on a.id_medico = m.id_medico
where date_trunc('month', a.data_atendimento) = date_trunc('month', current_date - interval '1 month')
group by m.nome_completo;

--como a consulta não obteve resultados, vamos fazer alguns inserts que atendam o que foi pedido para que tenhamos dados na pesquisa:
insert into atendimento (id_paciente, id_medico, data_atendimento, hora_atendimento, tipo, status, observacoes, prioridade) values
(1, 2, '2026-02-05', '10:30:00', 'consulta', 'realizado', 'paciente apresentou sintomas leves.', 3),
(2, 3, '2026-02-12', '14:00:00', 'emergencia', 'realizado', 'paciente chegou com dor intensa.', 5),
(3, 1, '2026-02-20', '09:15:00', 'revisao', 'realizado', 'revisão pós-cirúrgica.', 2),
(4, 2, '2026-02-25', '16:45:00', 'consulta', 'cancelado', 'paciente não compareceu.', 1);


-- agora a verificação da view com a consulta já criada:
select * from vw_consultas_ultimo_mes;

-- Top 10 médicos com maior número de atendimentos?
create or replace view vw_medicos_maior_atendimento as
select m.nome_completo, count(a.id_atendimento) as total
from atendimento a
join medico m on a.id_medico = m.id_medico 
group by m.nome_completo 
order by total desc
limit 10;

--view do select:
select * from vw_medicos_maior_atendimento;

-- Qual a porcentagem de leitos ocupados em cada ala? Apresente o nome da ala e a porcentagem.
create or replace view vw_ocupacao_leitos as
select h.nome as hospital, a.nome as ala, a.tipo,
    (count(*) filter (where l.status = 'ocupado') * 100.0 / count(*)) as porcentagem_ocupacao
from ala a
join hospital h on a.id_hospital = h.id_hospital
join leito l on l.id_ala = a.id_ala
group by h.nome, a.nome, a.tipo
order by porcentagem_ocupacao asc;

--visualizacao da view criada com os resultados da porcentagem de leitos ocupados:
select * from vw_ocupacao_leitos;

-- Qual o valor total faturado para cada plano de saúde no ano de 2026? Apresente o nome do plano e o valor total.
create or replace view vw_faturamento_plano_2026 as
select 
    ps.nome as plano_saude,
    coalesce(sum(f.valor), 0) as valor_total_faturado
from plano_saude ps
left join fatura f on ps.id_plano_saude = f.id_plano_saude
where extract(year from f.data_emissao) = 2026
group by ps.id_plano_saude, ps.nome
order by valor_total_faturado desc;

--view do select:
select * from vw_faturamento_plano_2026;

-- Quais são os dois medicamentos mais prescritos no hospital? Apresente o nome do medicamento e a quantidade de prescrições.
select 
    m.nome as medicamento,
    count(pm.id_medicamento) as quantidade_prescricoes
from medicamento m
left join prescricao_medicamento pm on m.id_medicamento = pm.id_medicamento
group by m.id_medicamento, m.nome
order by quantidade_prescricoes desc limit 2;

-- Liste o nome do médico, a especialidade e a quantidade de pacientes atendidos por cada médico.
create or replace view vw_qtd_paciente_medico as
select
    m.nome_completo as medico, m.especialidade,
    count(distinct a.id_paciente) as quant_pacientes_atendidos -- adicionamos o distic pq estava contando o mesmo paciente mais de 1 vez
from medico m
left join atendimento a on m.id_medico = a.id_medico
group by m.id_medico, m.nome_completo, m.especialidade
order by quant_pacientes_atendidos desc, m.nome_completo;

select * from vw_qtd_paciente_medico;

-- Quais leitos estão ocupados há mais de 15 dias? Apresente o número do leito, o nome do paciente e a data de entrada
select l.id_leito, l.codigo_leito, p.nome_completo as paciente, i.data_entrada
from internacao i
join leito l on i.id_leito = l.id_leito
join paciente p on i.id_paciente = p.id_paciente
where i.data_saida is null and extract(day from age(current_date, i.data_entrada)) > 15;

-- Qual o valor total faturado por tipo de atendimento (consulta, exame, internação)
create or replace view vw_total_faturado_atendimento as
select 
    case 
		when f.id_atendimento is not null then 'atendimento'
		when f.id_exame is not null then 'exame'
		when f.id_internacao is not null then 'internacao'
		else 'valor total:'
	end as tipo, sum(f.valor) as total_faturado from fatura f
where extract (year from f.data_emissao) = 2026
group by tipo;

--view do select:
select * from vw_total_faturado_atendimento;

-- Qual o valor total faturado por por um determinado plano de saúde
create or replace view vw_total_faturado_plano as
select ps.nome as plano_saude, sum(f.valor) as valor_total
from fatura f
join plano_saude ps on ps.id_plano_saude = f.id_plano_saude
group by ps.nome;

--view do select:
select * from vw_total_faturado_plano;

-- Use um plano específico, por exemplo:
select ps.nome, sum(f.valor) as total_faturado
from fatura f
join plano_saude ps on f.id_plano_saude = ps.id_plano_saude 
where lower(ps.nome) = 'unimed'
group by ps.nome;




------------------------------------------------------------------------------
--criação de usuarios:
set role postgres;

--administrador do hospital / gerente geral(acesso total):
create user admin_hospital with password 'admin123';

--médico (apenas leitura e inserção em atendimentos e prescrições):
create user arnaldo_rocha with password 'medico123';

--recepcionista (apenas leitura e inserção em pacientes e internações):
create user recepcionista with password 'recepcao123';

--permissoes:
-- permissões ao administrador / gerente geral:
grant all privileges on all tables in schema public to admin_hospital;

-- permissões para médico:
grant select, insert on atendimento to arnaldo_rocha;
grant select, insert on prescricao_medicamento to arnaldo_rocha;
grant select on paciente to arnaldo_rocha;

-- tem que dar permissão de uso e atualização da sequência ao médico
grant usage, select, update on sequence atendimento_id_atendimento_seq to arnaldo_rocha;

-- permissões para recepcionista:
grant select, insert on paciente to recepcionista;
grant select, insert on internacao to recepcionista;
grant select on leito to recepcionista;
--tem que dar permissão de uso e atualização da sequência para a recepcionista:
grant usage, select, update on sequence paciente_id_paciente_seq to recepcionista;

--testes medico:
set role arnaldo_rocha;

--pode fazer:
insert into atendimento (id_paciente, id_medico, data_atendimento, hora_atendimento, tipo, status, prioridade)
values (1, 2, '2026-02-28', '09:00:00', 'consulta', 'realizado', 3);

-- não pode fazer: (sem permissão):
delete from paciente where id_paciente = 1;

--visualização no perfil master:
set role postgres;
select * from atendimento;

--testes recepcionista:
set role recepcionista;

-- pode fazer:
insert into paciente (nome_completo, data_nascimento, cpf, telefone, id_plano_saude) values 
('Maria Souza','23-01-2026', '123.456.789-00', '2499856647', 1);

-- não pode fazer: (sem permissão):
insert into prescricao_medicamento (id_medicamento, id_prescricao_medicamento)
values (5, 10);

--visualização no perfil master:
set role postgres;
select * from paciente;