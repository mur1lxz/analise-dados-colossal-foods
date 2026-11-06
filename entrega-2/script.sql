-- ============================================================================
-- COLOSSAL FOODS — SCRIPT SQL COMPLETO (MySQL 8.0.16+) 
-- Entrega 2 — Modelo lógico, implementação SQL e consultas gerenciais/auditoria
-- Massa de dados integralmente fictícia, criada apenas para demonstração acadêmica.
-- Charset: utf8mb4 | Engine: InnoDB
-- ============================================================================
-- ATENÇÃO: este script cria o banco 'colossal_foods' caso ele não exista.
-- Para executar novamente do zero, primeiro rode manualmente:
-- DROP DATABASE IF EXISTS colossal_foods;
-- A linha acima apaga todos os dados desse banco. Não a execute em produção.

CREATE DATABASE IF NOT EXISTS colossal_foods
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;
USE colossal_foods;

-- ============================================================================
-- 1. CRIAÇÃO DAS TABELAS (20 tabelas)
-- ============================================================================

CREATE TABLE IF NOT EXISTS CATEGORIA (
    id_categoria BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome VARCHAR(80) NOT NULL,
    descricao VARCHAR(255) NULL,
    CONSTRAINT pk_categoria PRIMARY KEY (id_categoria),
    CONSTRAINT uq_categoria_nome UNIQUE (nome)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS CLIENTE (
    id_cliente BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome VARCHAR(120) NOT NULL,
    telefone VARCHAR(20) NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    INDEX idx_cliente_telefone (telefone)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS FORNECEDOR (
    id_fornecedor BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome VARCHAR(150) NOT NULL,
    telefone VARCHAR(20) NULL,
    email VARCHAR(150) NULL,
    CONSTRAINT pk_fornecedor PRIMARY KEY (id_fornecedor),
    INDEX idx_fornecedor_nome (nome)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS MOTOBOY (
    id_motoboy BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome VARCHAR(120) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    CONSTRAINT pk_motoboy PRIMARY KEY (id_motoboy)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS FUNCIONARIO (
    id_funcionario BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome VARCHAR(120) NOT NULL,
    funcao VARCHAR(30) NOT NULL,
    telefone VARCHAR(20) NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario),
    CONSTRAINT ck_funcionario_ativo CHECK (ativo IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS INGREDIENTE (
    id_ingrediente BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome VARCHAR(120) NOT NULL,
    unidade_medida VARCHAR(20) NOT NULL,
    estoque_minimo DECIMAL(12,3) NULL,
    CONSTRAINT pk_ingrediente PRIMARY KEY (id_ingrediente),
    CONSTRAINT ck_ingrediente_estoque_minimo CHECK (estoque_minimo IS NULL OR estoque_minimo >= 0),
    INDEX idx_ingrediente_nome (nome)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS AREA_ENTREGA (
    id_area_entrega BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    bairro VARCHAR(100) NOT NULL,
    taxa_padrao DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT pk_area_entrega PRIMARY KEY (id_area_entrega),
    CONSTRAINT uq_area_entrega_bairro UNIQUE (bairro),
    CONSTRAINT ck_area_entrega_taxa CHECK (taxa_padrao >= 0),
    CONSTRAINT ck_area_entrega_ativo CHECK (ativo IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS FECHAMENTO_CAIXA (
    id_fechamento BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_funcionario_responsavel BIGINT UNSIGNED NULL,
    data_hora_inicio DATETIME NULL,
    data_hora_fim DATETIME NOT NULL,
    observacao TEXT NULL,
    CONSTRAINT pk_fechamento_caixa PRIMARY KEY (id_fechamento),
    CONSTRAINT fk_fechamento_funcionario FOREIGN KEY (id_funcionario_responsavel)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_fechamento_periodo CHECK (data_hora_inicio IS NULL OR data_hora_inicio <= data_hora_fim),
    INDEX idx_fechamento_data (data_hora_fim)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS COMPRA (
    id_compra BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_fornecedor BIGINT UNSIGNED NOT NULL,
    id_funcionario_conferente BIGINT UNSIGNED NULL,
    data_pedido DATETIME NOT NULL,
    data_recebimento DATETIME NULL,
    numero_nota_fiscal VARCHAR(50) NULL,
    status_compra VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',
    resultado_conferencia VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',
    observacao_conferencia TEXT NULL,
    CONSTRAINT pk_compra PRIMARY KEY (id_compra),
    CONSTRAINT fk_compra_fornecedor FOREIGN KEY (id_fornecedor)
        REFERENCES FORNECEDOR (id_fornecedor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_compra_funcionario FOREIGN KEY (id_funcionario_conferente)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_compra_status CHECK (status_compra IN ('PENDENTE', 'RECEBIDA', 'CANCELADA')),
    CONSTRAINT ck_compra_conferencia CHECK (resultado_conferencia IN ('PENDENTE', 'CONFORME', 'DIVERGENTE')),
    INDEX idx_compra_data (data_pedido),
    INDEX idx_compra_status (status_compra)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS PRODUTO (
    id_produto BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_categoria BIGINT UNSIGNED NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT NULL,
    preco DECIMAL(10,2) NOT NULL,
    disponivel TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT pk_produto PRIMARY KEY (id_produto),
    CONSTRAINT fk_produto_categoria FOREIGN KEY (id_categoria)
        REFERENCES CATEGORIA (id_categoria)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_produto_preco CHECK (preco > 0),
    CONSTRAINT ck_produto_disponivel CHECK (disponivel IN (0, 1)),
    INDEX idx_produto_nome (nome),
    INDEX idx_produto_categoria (id_categoria)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS PEDIDO (
    id_pedido BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_cliente BIGINT UNSIGNED NOT NULL,
    id_funcionario_registro BIGINT UNSIGNED NOT NULL,
    id_funcionario_preparo BIGINT UNSIGNED NULL,
    data_hora DATETIME NOT NULL,
    tipo_pedido VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'RECEBIDO',
    CONSTRAINT pk_pedido PRIMARY KEY (id_pedido),
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente)
        REFERENCES CLIENTE (id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pedido_func_registro FOREIGN KEY (id_funcionario_registro)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pedido_func_preparo FOREIGN KEY (id_funcionario_preparo)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_pedido_tipo CHECK (tipo_pedido IN ('RETIRADA', 'DELIVERY')),
    CONSTRAINT ck_pedido_status CHECK (status IN ('RECEBIDO', 'EM_PREPARACAO', 'PRONTO', 'FINALIZADO', 'CANCELADO')),
    INDEX idx_pedido_status_data (status, data_hora),
    INDEX idx_pedido_cliente_data (id_cliente, data_hora),
    INDEX idx_pedido_tipo_status (tipo_pedido, status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ITEM_COMPRA (
    id_item_compra BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_compra BIGINT UNSIGNED NOT NULL,
    id_ingrediente BIGINT UNSIGNED NOT NULL,
    quantidade_solicitada DECIMAL(12,3) NOT NULL,
    quantidade_recebida DECIMAL(12,3) NOT NULL DEFAULT 0.000,
    custo_unitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_item_compra PRIMARY KEY (id_item_compra),
    CONSTRAINT fk_item_compra_compra FOREIGN KEY (id_compra)
        REFERENCES COMPRA (id_compra)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_item_compra_ingrediente FOREIGN KEY (id_ingrediente)
        REFERENCES INGREDIENTE (id_ingrediente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_item_compra_compra_ingrediente UNIQUE (id_compra, id_ingrediente),
    CONSTRAINT ck_item_compra_qtd_solicitada CHECK (quantidade_solicitada > 0),
    CONSTRAINT ck_item_compra_qtd_recebida CHECK (quantidade_recebida >= 0),
    CONSTRAINT ck_item_compra_custo CHECK (custo_unitario >= 0),
    INDEX idx_item_compra_ingrediente (id_ingrediente)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS PRODUTO_INGREDIENTE (
    id_produto BIGINT UNSIGNED NOT NULL,
    id_ingrediente BIGINT UNSIGNED NOT NULL,
    quantidade_utilizada DECIMAL(12,3) NOT NULL,
    CONSTRAINT pk_produto_ingrediente PRIMARY KEY (id_produto, id_ingrediente),
    CONSTRAINT fk_produto_ingrediente_produto FOREIGN KEY (id_produto)
        REFERENCES PRODUTO (id_produto)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_produto_ingrediente_ingrediente FOREIGN KEY (id_ingrediente)
        REFERENCES INGREDIENTE (id_ingrediente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_produto_ingrediente_qtd CHECK (quantidade_utilizada > 0),
    INDEX idx_produto_ingrediente_ingrediente (id_ingrediente)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS FORNECEDOR_INGREDIENTE (
    id_fornecedor BIGINT UNSIGNED NOT NULL,
    id_ingrediente BIGINT UNSIGNED NOT NULL,
    CONSTRAINT pk_fornecedor_ingrediente PRIMARY KEY (id_fornecedor, id_ingrediente),
    CONSTRAINT fk_fornecedor_ingrediente_fornecedor FOREIGN KEY (id_fornecedor)
        REFERENCES FORNECEDOR (id_fornecedor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fornecedor_ingrediente_ingrediente FOREIGN KEY (id_ingrediente)
        REFERENCES INGREDIENTE (id_ingrediente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_fornecedor_ingrediente_ingrediente (id_ingrediente)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ITEM_PEDIDO (
    id_item_pedido BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_pedido BIGINT UNSIGNED NOT NULL,
    id_produto BIGINT UNSIGNED NOT NULL,
    quantidade INT UNSIGNED NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    observacao VARCHAR(255) NULL,
    CONSTRAINT pk_item_pedido PRIMARY KEY (id_item_pedido),
    CONSTRAINT fk_item_pedido_pedido FOREIGN KEY (id_pedido)
        REFERENCES PEDIDO (id_pedido)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_item_pedido_produto FOREIGN KEY (id_produto)
        REFERENCES PRODUTO (id_produto)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_item_pedido_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_item_pedido_preco CHECK (preco_unitario > 0),
    INDEX idx_item_pedido_pedido (id_pedido),
    INDEX idx_item_pedido_produto (id_produto)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS MOVIMENTACAO_ESTOQUE (
    id_movimentacao BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_ingrediente BIGINT UNSIGNED NOT NULL,
    id_funcionario BIGINT UNSIGNED NOT NULL,
    id_item_compra BIGINT UNSIGNED NULL,
    tipo_movimentacao VARCHAR(20) NOT NULL,
    quantidade DECIMAL(12,3) NOT NULL,
    data_hora DATETIME NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    CONSTRAINT pk_movimentacao_estoque PRIMARY KEY (id_movimentacao),
    CONSTRAINT fk_mov_estoque_ingrediente FOREIGN KEY (id_ingrediente)
        REFERENCES INGREDIENTE (id_ingrediente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_mov_estoque_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_mov_estoque_item_compra FOREIGN KEY (id_item_compra)
        REFERENCES ITEM_COMPRA (id_item_compra)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_mov_estoque_tipo CHECK (tipo_movimentacao IN ('ENTRADA', 'SAIDA', 'AJUSTE_ENTRADA', 'AJUSTE_SAIDA')),
    CONSTRAINT ck_mov_estoque_quantidade CHECK (quantidade > 0),
    INDEX idx_mov_estoque_ingrediente_data (id_ingrediente, data_hora)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS PAGAMENTO (
    id_pagamento BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_pedido BIGINT UNSIGNED NOT NULL,
    id_fechamento BIGINT UNSIGNED NULL,
    forma_pagamento VARCHAR(20) NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    data_hora DATETIME NOT NULL,
    CONSTRAINT pk_pagamento PRIMARY KEY (id_pagamento),
    CONSTRAINT fk_pagamento_pedido FOREIGN KEY (id_pedido)
        REFERENCES PEDIDO (id_pedido)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pagamento_fechamento FOREIGN KEY (id_fechamento)
        REFERENCES FECHAMENTO_CAIXA (id_fechamento)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_pagamento_pedido UNIQUE (id_pedido),
    CONSTRAINT ck_pagamento_forma CHECK (forma_pagamento IN ('PIX', 'DINHEIRO', 'CARTAO_DEBITO', 'CARTAO_CREDITO')),
    CONSTRAINT ck_pagamento_valor CHECK (valor > 0),
    INDEX idx_pagamento_data_forma (data_hora, forma_pagamento),
    INDEX idx_pagamento_fechamento (id_fechamento)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ENTREGA (
    id_entrega BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_pedido BIGINT UNSIGNED NOT NULL,
    id_motoboy BIGINT UNSIGNED NOT NULL,
    id_area_entrega BIGINT UNSIGNED NOT NULL,
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    complemento VARCHAR(100) NULL,
    cep VARCHAR(9) NULL,
    taxa_entrega_aplicada DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    data_hora_saida DATETIME NULL,
    data_hora_entrega DATETIME NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AGUARDANDO',
    CONSTRAINT pk_entrega PRIMARY KEY (id_entrega),
    CONSTRAINT fk_entrega_pedido FOREIGN KEY (id_pedido)
        REFERENCES PEDIDO (id_pedido)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_entrega_motoboy FOREIGN KEY (id_motoboy)
        REFERENCES MOTOBOY (id_motoboy)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_entrega_area FOREIGN KEY (id_area_entrega)
        REFERENCES AREA_ENTREGA (id_area_entrega)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_entrega_pedido UNIQUE (id_pedido),
    CONSTRAINT ck_entrega_taxa CHECK (taxa_entrega_aplicada >= 0),
    CONSTRAINT ck_entrega_status CHECK (status IN ('AGUARDANDO', 'EM_ROTA', 'ENTREGUE')),
    CONSTRAINT ck_entrega_horarios CHECK (data_hora_entrega IS NULL OR (data_hora_saida IS NOT NULL AND data_hora_entrega >= data_hora_saida)),
    INDEX idx_entrega_status (status),
    INDEX idx_entrega_area (id_area_entrega)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS CONFERENCIA_CAIXA (
    id_conferencia BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_fechamento BIGINT UNSIGNED NOT NULL,
    forma_pagamento VARCHAR(20) NOT NULL,
    valor_contado DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_conferencia_caixa PRIMARY KEY (id_conferencia),
    CONSTRAINT fk_conferencia_fechamento FOREIGN KEY (id_fechamento)
        REFERENCES FECHAMENTO_CAIXA (id_fechamento)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_conferencia_forma UNIQUE (id_fechamento, forma_pagamento),
    CONSTRAINT ck_conferencia_forma CHECK (forma_pagamento IN ('PIX', 'DINHEIRO', 'CARTAO_DEBITO', 'CARTAO_CREDITO')),
    CONSTRAINT ck_conferencia_valor CHECK (valor_contado >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS HISTORICO_STATUS_PEDIDO (
    id_historico BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_pedido BIGINT UNSIGNED NOT NULL,
    id_funcionario_responsavel BIGINT UNSIGNED NOT NULL,
    id_funcionario_autorizador BIGINT UNSIGNED NULL,
    status_anterior VARCHAR(20) NULL,
    status_novo VARCHAR(20) NOT NULL,
    data_hora DATETIME NOT NULL,
    motivo VARCHAR(255) NULL,
    CONSTRAINT pk_historico_status_pedido PRIMARY KEY (id_historico),
    CONSTRAINT fk_hist_status_pedido FOREIGN KEY (id_pedido)
        REFERENCES PEDIDO (id_pedido)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_hist_status_func_resp FOREIGN KEY (id_funcionario_responsavel)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_hist_status_func_aut FOREIGN KEY (id_funcionario_autorizador)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_hist_status_anterior CHECK (status_anterior IS NULL OR status_anterior IN ('RECEBIDO', 'EM_PREPARACAO', 'PRONTO', 'FINALIZADO', 'CANCELADO')),
    CONSTRAINT ck_hist_status_novo CHECK (status_novo IN ('RECEBIDO', 'EM_PREPARACAO', 'PRONTO', 'FINALIZADO', 'CANCELADO')),
    INDEX idx_hist_pedido_data (id_pedido, data_hora)
) ENGINE=InnoDB;

-- ============================================================================
-- 2. TRIGGERS DE INTEGRIDADE (regras que dependem de mais de uma tabela)
-- ============================================================================
DELIMITER $$
CREATE TRIGGER trg_item_pedido_bi
BEFORE INSERT ON ITEM_PEDIDO
FOR EACH ROW
BEGIN
    DECLARE v_disponivel TINYINT DEFAULT NULL;
    SELECT disponivel INTO v_disponivel
      FROM PRODUTO WHERE id_produto = NEW.id_produto;
    IF v_disponivel IS NULL OR v_disponivel <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN05: produto indisponivel nao pode entrar em novo pedido';
    END IF;
END$$

CREATE TRIGGER trg_item_pedido_bu
BEFORE UPDATE ON ITEM_PEDIDO
FOR EACH ROW
BEGIN
    DECLARE v_disponivel TINYINT DEFAULT NULL;
    SELECT disponivel INTO v_disponivel
      FROM PRODUTO WHERE id_produto = NEW.id_produto;
    IF v_disponivel IS NULL OR v_disponivel <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN05: produto indisponivel nao pode entrar em novo pedido';
    END IF;
END$$

CREATE TRIGGER trg_pagamento_bi
BEFORE INSERT ON PAGAMENTO
FOR EACH ROW
BEGIN
    DECLARE v_total_itens DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_taxa_entrega DECIMAL(10,2) DEFAULT 0.00;
    SELECT COALESCE(SUM(quantidade * preco_unitario), 0.00)
      INTO v_total_itens FROM ITEM_PEDIDO WHERE id_pedido = NEW.id_pedido;
    SELECT COALESCE(MAX(taxa_entrega_aplicada), 0.00)
      INTO v_taxa_entrega FROM ENTREGA WHERE id_pedido = NEW.id_pedido;
    IF v_total_itens <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN02: pedido precisa ter ao menos um item antes do pagamento';
    END IF;
    IF ABS(NEW.valor - (v_total_itens + v_taxa_entrega)) > 0.01 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN08/RN19: valor pago deve corresponder aos itens mais a taxa de entrega';
    END IF;
END$$

CREATE TRIGGER trg_pagamento_bu
BEFORE UPDATE ON PAGAMENTO
FOR EACH ROW
BEGIN
    DECLARE v_total_itens DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_taxa_entrega DECIMAL(10,2) DEFAULT 0.00;
    SELECT COALESCE(SUM(quantidade * preco_unitario), 0.00)
      INTO v_total_itens FROM ITEM_PEDIDO WHERE id_pedido = NEW.id_pedido;
    SELECT COALESCE(MAX(taxa_entrega_aplicada), 0.00)
      INTO v_taxa_entrega FROM ENTREGA WHERE id_pedido = NEW.id_pedido;
    IF v_total_itens <= 0 OR ABS(NEW.valor - (v_total_itens + v_taxa_entrega)) > 0.01 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN08/RN19: valor do pagamento divergente do total do pedido';
    END IF;
END$$

CREATE TRIGGER trg_entrega_bi
BEFORE INSERT ON ENTREGA
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(10) DEFAULT NULL;
    DECLARE v_area_ativa TINYINT DEFAULT NULL;
    DECLARE v_taxa_padrao DECIMAL(10,2) DEFAULT NULL;
    SELECT tipo_pedido INTO v_tipo FROM PEDIDO WHERE id_pedido = NEW.id_pedido;
    IF v_tipo IS NULL OR v_tipo <> 'DELIVERY' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN10: somente pedidos DELIVERY podem possuir entrega';
    END IF;
    SELECT ativo, taxa_padrao INTO v_area_ativa, v_taxa_padrao
      FROM AREA_ENTREGA WHERE id_area_entrega = NEW.id_area_entrega;
    IF v_area_ativa IS NULL OR v_area_ativa <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: area de entrega inexistente ou inativa';
    END IF;
    IF ABS(NEW.taxa_entrega_aplicada - v_taxa_padrao) > 0.01 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN19: taxa aplicada deve corresponder a taxa cadastrada para a area';
    END IF;
END$$

CREATE TRIGGER trg_entrega_bu
BEFORE UPDATE ON ENTREGA
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(10) DEFAULT NULL;
    SELECT tipo_pedido INTO v_tipo FROM PEDIDO WHERE id_pedido = NEW.id_pedido;
    IF v_tipo IS NULL OR v_tipo <> 'DELIVERY' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN10: somente pedidos DELIVERY podem possuir entrega';
    END IF;
END$$

CREATE TRIGGER trg_pedido_bu
BEFORE UPDATE ON PEDIDO
FOR EACH ROW
BEGIN
    DECLARE v_status_entrega VARCHAR(20) DEFAULT NULL;
    IF NEW.status = 'FINALIZADO' AND NEW.tipo_pedido = 'DELIVERY' THEN
        SELECT status INTO v_status_entrega FROM ENTREGA WHERE id_pedido = NEW.id_pedido;
        IF v_status_entrega IS NULL OR v_status_entrega <> 'ENTREGUE' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN14: delivery somente pode finalizar apos a entrega';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_compra_bi
BEFORE INSERT ON COMPRA
FOR EACH ROW
BEGIN
    IF NEW.status_compra = 'RECEBIDA' AND
       (NEW.numero_nota_fiscal IS NULL OR TRIM(NEW.numero_nota_fiscal) = ''
        OR NEW.data_recebimento IS NULL OR NEW.id_funcionario_conferente IS NULL
        OR NEW.resultado_conferencia = 'PENDENTE') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN20/RN21: compra recebida exige nota fiscal, data, conferente e resultado da conferencia';
    END IF;
END$$

CREATE TRIGGER trg_compra_bu
BEFORE UPDATE ON COMPRA
FOR EACH ROW
BEGIN
    DECLARE v_itens INT DEFAULT 0;
    DECLARE v_qtd_recebida DECIMAL(14,3) DEFAULT 0.000;
    IF NEW.status_compra = 'RECEBIDA' AND OLD.status_compra <> 'RECEBIDA' THEN
        SELECT COUNT(*), COALESCE(SUM(quantidade_recebida), 0.000)
          INTO v_itens, v_qtd_recebida
          FROM ITEM_COMPRA WHERE id_compra = OLD.id_compra;
        IF NEW.numero_nota_fiscal IS NULL OR TRIM(NEW.numero_nota_fiscal) = ''
           OR NEW.data_recebimento IS NULL
           OR NEW.id_funcionario_conferente IS NULL
           OR NEW.resultado_conferencia = 'PENDENTE'
           OR v_itens = 0 OR v_qtd_recebida <= 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN20/RN21: compra recebida exige nota, data, conferente e itens conferidos';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_movimentacao_estoque_bi
BEFORE INSERT ON MOVIMENTACAO_ESTOQUE
FOR EACH ROW
BEGIN
    DECLARE v_ingrediente BIGINT UNSIGNED DEFAULT NULL;
    DECLARE v_quantidade_recebida DECIMAL(12,3) DEFAULT 0.000;
    DECLARE v_quantidade_ja_lancada DECIMAL(14,3) DEFAULT 0.000;
    IF NEW.id_item_compra IS NOT NULL THEN
        SELECT id_ingrediente, quantidade_recebida
          INTO v_ingrediente, v_quantidade_recebida
          FROM ITEM_COMPRA WHERE id_item_compra = NEW.id_item_compra;
        SELECT COALESCE(SUM(quantidade), 0.000)
          INTO v_quantidade_ja_lancada
          FROM MOVIMENTACAO_ESTOQUE
          WHERE id_item_compra = NEW.id_item_compra AND tipo_movimentacao = 'ENTRADA';
        IF v_ingrediente IS NULL OR v_ingrediente <> NEW.id_ingrediente
           OR NEW.tipo_movimentacao <> 'ENTRADA' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Movimentacao de compra deve ser ENTRADA do mesmo ingrediente do item de compra';
        END IF;
        IF v_quantidade_ja_lancada + NEW.quantidade > v_quantidade_recebida THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantidade de entrada supera a quantidade recebida na compra';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_historico_status_bi
BEFORE INSERT ON HISTORICO_STATUS_PEDIDO
FOR EACH ROW
BEGIN
    IF NEW.status_novo = 'CANCELADO' THEN
        IF NEW.motivo IS NULL OR TRIM(NEW.motivo) = '' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN17: cancelamento exige justificativa';
        END IF;
        IF NEW.status_anterior IN ('EM_PREPARACAO', 'PRONTO')
           AND NEW.id_funcionario_autorizador IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN17: cancelamento apos inicio do preparo exige autorizador';
        END IF;
        IF NEW.status_anterior IS NULL OR NEW.status_anterior NOT IN ('RECEBIDO', 'EM_PREPARACAO', 'PRONTO') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RN17: status anterior nao permite cancelamento';
        END IF;
    END IF;
END$$
DELIMITER ;

-- ============================================================================
-- 3. MASSA DE DADOS FICTÍCIA
-- A amostra cobre três dias: 34 pedidos em um dia útil, 39 em outro e 65 no sábado.
-- O volume abaixo é demonstrativo e não reproduz clientes, telefones ou endereços reais.
-- A distribuição foi montada para exercitar retirada, delivery, cancelamentos,
-- várias formas de pagamento, compras, conferência e alerta de estoque.
-- ============================================================================

INSERT INTO CATEGORIA (id_categoria, nome, descricao) VALUES
    (1, 'Hambúrgueres', 'Lanches preparados na chapa'),
    (2, 'Acompanhamentos', 'Porções e acompanhamentos'),
    (3, 'Bebidas', 'Bebidas industrializadas'),
    (4, 'Sobremesas', 'Sobremesas individuais'),
    (5, 'Combos', 'Combinações promocionais');

INSERT INTO CLIENTE (id_cliente, nome, telefone) VALUES
    (1, 'Cliente Ficticio 001', '(11) 90000-0001'),
    (2, 'Cliente Ficticio 002', '(11) 90000-0002'),
    (3, 'Cliente Ficticio 003', '(11) 90000-0003'),
    (4, 'Cliente Ficticio 004', '(11) 90000-0004'),
    (5, 'Cliente Ficticio 005', '(11) 90000-0005'),
    (6, 'Cliente Ficticio 006', '(11) 90000-0006'),
    (7, 'Cliente Ficticio 007', '(11) 90000-0007'),
    (8, 'Cliente Ficticio 008', '(11) 90000-0008'),
    (9, 'Cliente Ficticio 009', '(11) 90000-0009'),
    (10, 'Cliente Ficticio 010', '(11) 90000-0010'),
    (11, 'Cliente Ficticio 011', '(11) 90000-0011'),
    (12, 'Cliente Ficticio 012', '(11) 90000-0012'),
    (13, 'Cliente Ficticio 013', '(11) 90000-0013'),
    (14, 'Cliente Ficticio 014', '(11) 90000-0014'),
    (15, 'Cliente Ficticio 015', '(11) 90000-0015'),
    (16, 'Cliente Ficticio 016', '(11) 90000-0016'),
    (17, 'Cliente Ficticio 017', '(11) 90000-0017'),
    (18, 'Cliente Ficticio 018', '(11) 90000-0018'),
    (19, 'Cliente Ficticio 019', '(11) 90000-0019'),
    (20, 'Cliente Ficticio 020', '(11) 90000-0020');

INSERT INTO FORNECEDOR (id_fornecedor, nome, telefone, email) VALUES
    (1, 'Padaria Modelo Ltda.', '(11) 90000-1001', 'contato@padariammodelo.example'),
    (2, 'Açougue Modelo Ltda.', '(11) 90000-1002', 'compras@acougue-modelo.example'),
    (3, 'Hortifruti Modelo Ltda.', '(11) 90000-1003', 'vendas@hortifruti-modelo.example'),
    (4, 'Distribuidora Modelo Ltda.', '(11) 90000-1004', 'contato@distribuidora-modelo.example');

INSERT INTO MOTOBOY (id_motoboy, nome, telefone) VALUES
    (1, 'Entregador Ficticio 01', '(11) 90000-2001');

INSERT INTO FUNCIONARIO (id_funcionario, nome, funcao, telefone, ativo) VALUES
    (1, 'Funcionario Ficticio 01', 'ATENDIMENTO', '(11) 90000-3001', 1),
    (2, 'Funcionario Ficticio 02', 'ATENDIMENTO', '(11) 90000-3002', 1),
    (3, 'Funcionario Ficticio 03', 'CHAPA', '(11) 90000-3003', 1),
    (4, 'Funcionario Ficticio 04', 'CHAPA', '(11) 90000-3004', 1);

INSERT INTO INGREDIENTE (id_ingrediente, nome, unidade_medida, estoque_minimo) VALUES
    (1, 'Pao brioche', 'un', 50),
    (2, 'Carne bovina', 'g', 1000),
    (3, 'Queijo cheddar', 'g', 500),
    (4, 'Alface', 'g', 300),
    (5, 'Tomate', 'g', 300),
    (6, 'Cebola', 'g', 300),
    (7, 'Bacon', 'g', 250),
    (8, 'Molho especial', 'ml', 200),
    (9, 'Batata congelada', 'g', 1000),
    (10, 'Oleo vegetal', 'ml', 500),
    (11, 'Refrigerante lata', 'un', 20),
    (12, 'Chocolate', 'g', 250),
    (13, 'Leite', 'ml', 2000);

INSERT INTO AREA_ENTREGA (id_area_entrega, bairro, taxa_padrao, ativo) VALUES
    (1, 'Jardim Arantes', 5.0, 1),
    (2, 'Bairro Exemplo 01', 6.0, 1),
    (3, 'Bairro Exemplo 02', 7.0, 1);

INSERT INTO FECHAMENTO_CAIXA (id_fechamento, id_funcionario_responsavel, data_hora_inicio, data_hora_fim, observacao) VALUES
    (1, 1, '2026-10-28 18:00:00', '2026-10-28 23:15:00', 'Fechamento demonstrativo com conferência coletiva.'),
    (2, 2, '2026-10-29 18:00:00', '2026-10-29 23:15:00', 'Fechamento demonstrativo com conferência coletiva.'),
    (3, 1, '2026-10-31 18:00:00', '2026-11-01 00:30:00', 'Fechamento demonstrativo de sábado com conferência coletiva.');

INSERT INTO FORNECEDOR_INGREDIENTE (id_fornecedor, id_ingrediente) VALUES
    (1, 1),
    (2, 2),
    (2, 7),
    (3, 4),
    (3, 5),
    (3, 6),
    (3, 9),
    (4, 3),
    (4, 8),
    (4, 10),
    (4, 11),
    (4, 12),
    (4, 13);

INSERT INTO PRODUTO (id_produto, id_categoria, nome, descricao, preco, disponivel) VALUES
    (1, 1, 'Colossal Burger', 'Hamburguer classico da casa', 29.9, 1),
    (2, 1, 'Bacon Burger', 'Hamburguer com bacon e cheddar', 34.9, 1),
    (3, 1, 'X-Salada', 'Hamburguer com salada', 31.9, 1),
    (4, 1, 'Double Burger', 'Hamburguer duplo', 39.9, 1),
    (5, 2, 'Batata Frita', 'Porcao de batatas fritas', 14.9, 1),
    (6, 2, 'Onion Rings', 'Porcao de aneis de cebola', 16.9, 1),
    (7, 3, 'Refrigerante Lata', 'Bebida industrializada', 6.0, 1),
    (8, 3, 'Agua Mineral', 'Bebida industrializada', 4.0, 1),
    (9, 4, 'Brownie', 'Sobremesa de chocolate', 12.0, 1),
    (10, 4, 'Milk-shake Chocolate', 'Milk-shake de chocolate', 15.0, 1),
    (11, 5, 'Combo Colossal', 'Combo com hamburguer, acompanhamento e bebida', 44.9, 1);

INSERT INTO COMPRA (id_compra, id_fornecedor, id_funcionario_conferente, data_pedido, data_recebimento, numero_nota_fiscal, status_compra, resultado_conferencia, observacao_conferencia) VALUES
    (1, 1, 3, '2026-10-20 10:00:00', '2026-10-20 12:00:00', 'NF-DEMO-0001', 'PENDENTE', 'CONFORME', 'Conferencia demonstrativa conforme nota fiscal.'),
    (2, 2, 3, '2026-10-22 10:30:00', '2026-10-22 12:20:00', 'NF-DEMO-0002', 'PENDENTE', 'CONFORME', 'Conferencia demonstrativa conforme nota fiscal.'),
    (3, 3, 4, '2026-10-26 09:45:00', '2026-10-26 11:30:00', 'NF-DEMO-0003', 'PENDENTE', 'CONFORME', 'Conferencia demonstrativa conforme nota fiscal.'),
    (4, 4, 4, '2026-10-29 10:15:00', '2026-10-29 12:00:00', 'NF-DEMO-0004', 'PENDENTE', 'CONFORME', 'Conferencia demonstrativa conforme nota fiscal.'),
    (5, 2, 3, '2026-11-02 11:00:00', '2026-11-02 12:30:00', 'NF-DEMO-0005', 'PENDENTE', 'CONFORME', 'Conferencia demonstrativa conforme nota fiscal.');

INSERT INTO ITEM_COMPRA (id_item_compra, id_compra, id_ingrediente, quantidade_solicitada, quantidade_recebida, custo_unitario) VALUES
    (1, 1, 1, 300, 300, 1.2),
    (2, 2, 2, 15000, 15000, 0.04),
    (3, 2, 7, 1500, 1500, 0.06),
    (4, 3, 4, 1500, 1500, 0.02),
    (5, 3, 5, 1500, 1500, 0.03),
    (6, 3, 6, 1200, 1200, 0.02),
    (7, 3, 9, 9000, 9000, 0.01),
    (8, 4, 3, 3000, 3000, 0.05),
    (9, 4, 8, 2500, 2500, 0.02),
    (10, 4, 10, 6000, 6000, 0.01),
    (11, 4, 11, 48, 48, 3.5),
    (12, 4, 12, 1200, 1200, 0.08),
    (13, 4, 13, 10000, 10000, 0.006),
    (14, 5, 2, 10000, 10000, 0.041),
    (15, 5, 7, 1000, 1000, 0.062);


INSERT INTO PRODUTO_INGREDIENTE (id_produto, id_ingrediente, quantidade_utilizada) VALUES
    (1, 1, 1),
    (1, 2, 180),
    (1, 3, 30),
    (1, 4, 15),
    (1, 5, 20),
    (1, 8, 20),
    (2, 1, 1),
    (2, 2, 180),
    (2, 3, 30),
    (2, 7, 40),
    (2, 8, 20),
    (3, 1, 1),
    (3, 2, 160),
    (3, 4, 20),
    (3, 5, 30),
    (3, 6, 10),
    (4, 1, 2),
    (4, 2, 320),
    (4, 3, 60),
    (4, 8, 30),
    (5, 9, 250),
    (5, 10, 20),
    (6, 6, 100),
    (6, 10, 20),
    (9, 12, 80),
    (10, 12, 30),
    (10, 13, 250),
    (11, 1, 1),
    (11, 2, 180),
    (11, 3, 30),
    (11, 9, 150),
    (11, 11, 1);

INSERT INTO MOVIMENTACAO_ESTOQUE (id_movimentacao, id_ingrediente, id_funcionario, id_item_compra, tipo_movimentacao, quantidade, data_hora, motivo) VALUES
    (1, 1, 3, 1, 'ENTRADA', 300, '2026-10-20 12:00:00', 'Recebimento da compra demonstrativa 1'),
    (2, 2, 3, 2, 'ENTRADA', 15000, '2026-10-22 12:20:00', 'Recebimento da compra demonstrativa 2'),
    (3, 7, 3, 3, 'ENTRADA', 1500, '2026-10-22 12:20:00', 'Recebimento da compra demonstrativa 2'),
    (4, 4, 4, 4, 'ENTRADA', 1500, '2026-10-26 11:30:00', 'Recebimento da compra demonstrativa 3'),
    (5, 5, 4, 5, 'ENTRADA', 1500, '2026-10-26 11:30:00', 'Recebimento da compra demonstrativa 3'),
    (6, 6, 4, 6, 'ENTRADA', 1200, '2026-10-26 11:30:00', 'Recebimento da compra demonstrativa 3'),
    (7, 9, 4, 7, 'ENTRADA', 9000, '2026-10-26 11:30:00', 'Recebimento da compra demonstrativa 3'),
    (8, 3, 4, 8, 'ENTRADA', 3000, '2026-10-29 12:00:00', 'Recebimento da compra demonstrativa 4'),
    (9, 8, 4, 9, 'ENTRADA', 2500, '2026-10-29 12:00:00', 'Recebimento da compra demonstrativa 4'),
    (10, 10, 4, 10, 'ENTRADA', 6000, '2026-10-29 12:00:00', 'Recebimento da compra demonstrativa 4'),
    (11, 11, 4, 11, 'ENTRADA', 48, '2026-10-29 12:00:00', 'Recebimento da compra demonstrativa 4'),
    (12, 12, 4, 12, 'ENTRADA', 1200, '2026-10-29 12:00:00', 'Recebimento da compra demonstrativa 4'),
    (13, 13, 4, 13, 'ENTRADA', 10000, '2026-10-29 12:00:00', 'Recebimento da compra demonstrativa 4'),
    (14, 2, 3, 14, 'ENTRADA', 10000, '2026-11-02 12:30:00', 'Recebimento da compra demonstrativa 5'),
    (15, 7, 3, 15, 'ENTRADA', 1000, '2026-11-02 12:30:00', 'Recebimento da compra demonstrativa 5'),
    (16, 1, 3, NULL, 'SAIDA', 250, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (17, 2, 3, NULL, 'SAIDA', 18000, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (18, 3, 3, NULL, 'SAIDA', 2200, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (19, 4, 3, NULL, 'SAIDA', 1000, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (20, 5, 3, NULL, 'SAIDA', 1200, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (21, 6, 3, NULL, 'SAIDA', 850, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (22, 7, 3, NULL, 'SAIDA', 1000, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (23, 8, 3, NULL, 'SAIDA', 1500, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (24, 9, 3, NULL, 'SAIDA', 8000, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (25, 10, 3, NULL, 'SAIDA', 3000, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (26, 11, 3, NULL, 'SAIDA', 30, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (27, 12, 3, NULL, 'SAIDA', 1100, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo'),
    (28, 13, 3, NULL, 'SAIDA', 5000, '2026-10-31 23:00:00', 'Consumo operacional consolidado do periodo');

INSERT INTO PEDIDO (id_pedido, id_cliente, id_funcionario_registro, id_funcionario_preparo, data_hora, tipo_pedido, status) VALUES
    (1, 8, 1, 3, '2026-10-28 18:00:00', 'RETIRADA', 'FINALIZADO'),
    (2, 15, 2, 4, '2026-10-28 18:08:00', 'RETIRADA', 'FINALIZADO'),
    (3, 4, 1, 3, '2026-10-28 18:17:00', 'DELIVERY', 'FINALIZADO'),
    (4, 11, 2, 4, '2026-10-28 18:25:00', 'RETIRADA', 'FINALIZADO'),
    (5, 18, 1, 3, '2026-10-28 18:34:00', 'RETIRADA', 'FINALIZADO'),
    (6, 7, 2, 4, '2026-10-28 18:43:00', 'DELIVERY', 'FINALIZADO'),
    (7, 14, 1, 3, '2026-10-28 18:51:00', 'RETIRADA', 'FINALIZADO'),
    (8, 3, 2, 4, '2026-10-28 19:00:00', 'RETIRADA', 'FINALIZADO'),
    (9, 10, 1, 3, '2026-10-28 19:09:00', 'DELIVERY', 'FINALIZADO'),
    (10, 17, 2, 4, '2026-10-28 19:17:00', 'RETIRADA', 'FINALIZADO'),
    (11, 6, 1, 3, '2026-10-28 19:26:00', 'RETIRADA', 'PRONTO'),
    (12, 13, 2, 4, '2026-10-28 19:35:00', 'DELIVERY', 'FINALIZADO'),
    (13, 2, 1, 3, '2026-10-28 19:43:00', 'RETIRADA', 'EM_PREPARACAO'),
    (14, 9, 2, 4, '2026-10-28 19:52:00', 'RETIRADA', 'FINALIZADO'),
    (15, 16, 1, 3, '2026-10-28 20:00:00', 'DELIVERY', 'FINALIZADO'),
    (16, 5, 2, 4, '2026-10-28 20:09:00', 'RETIRADA', 'FINALIZADO'),
    (17, 12, 1, NULL, '2026-10-28 20:18:00', 'RETIRADA', 'RECEBIDO'),
    (18, 1, 2, 4, '2026-10-28 20:26:00', 'DELIVERY', 'FINALIZADO'),
    (19, 8, 1, 3, '2026-10-28 20:35:00', 'RETIRADA', 'FINALIZADO'),
    (20, 15, 2, 4, '2026-10-28 20:44:00', 'RETIRADA', 'FINALIZADO'),
    (21, 4, 1, 3, '2026-10-28 20:52:00', 'DELIVERY', 'FINALIZADO'),
    (22, 11, 2, 4, '2026-10-28 21:01:00', 'RETIRADA', 'PRONTO'),
    (23, 18, 1, NULL, '2026-10-28 21:10:00', 'RETIRADA', 'CANCELADO'),
    (24, 7, 2, 4, '2026-10-28 21:18:00', 'DELIVERY', 'FINALIZADO'),
    (25, 14, 1, 3, '2026-10-28 21:27:00', 'RETIRADA', 'FINALIZADO'),
    (26, 3, 2, 4, '2026-10-28 21:35:00', 'RETIRADA', 'EM_PREPARACAO'),
    (27, 10, 1, 3, '2026-10-28 21:44:00', 'DELIVERY', 'FINALIZADO'),
    (28, 17, 2, 4, '2026-10-28 21:53:00', 'RETIRADA', 'FINALIZADO'),
    (29, 6, 1, 3, '2026-10-28 22:01:00', 'RETIRADA', 'FINALIZADO'),
    (30, 13, 2, 4, '2026-10-28 22:10:00', 'DELIVERY', 'FINALIZADO'),
    (31, 2, 1, 3, '2026-10-28 22:19:00', 'RETIRADA', 'FINALIZADO'),
    (32, 9, 2, 4, '2026-10-28 22:27:00', 'RETIRADA', 'FINALIZADO'),
    (33, 16, 1, 3, '2026-10-28 22:36:00', 'DELIVERY', 'PRONTO'),
    (34, 5, 2, NULL, '2026-10-28 22:45:00', 'RETIRADA', 'RECEBIDO'),
    (35, 12, 1, 3, '2026-10-29 18:00:00', 'RETIRADA', 'FINALIZADO'),
    (36, 1, 2, 4, '2026-10-29 18:07:00', 'DELIVERY', 'FINALIZADO'),
    (37, 8, 1, 3, '2026-10-29 18:15:00', 'RETIRADA', 'FINALIZADO'),
    (38, 15, 2, 4, '2026-10-29 18:22:00', 'RETIRADA', 'FINALIZADO'),
    (39, 4, 1, 3, '2026-10-29 18:30:00', 'DELIVERY', 'EM_PREPARACAO'),
    (40, 11, 2, 4, '2026-10-29 18:37:00', 'RETIRADA', 'FINALIZADO'),
    (41, 18, 1, 3, '2026-10-29 18:45:00', 'RETIRADA', 'FINALIZADO'),
    (42, 7, 2, 4, '2026-10-29 18:52:00', 'DELIVERY', 'FINALIZADO'),
    (43, 14, 1, 3, '2026-10-29 19:00:00', 'RETIRADA', 'FINALIZADO'),
    (44, 3, 2, 4, '2026-10-29 19:07:00', 'RETIRADA', 'PRONTO'),
    (45, 10, 1, 3, '2026-10-29 19:15:00', 'DELIVERY', 'FINALIZADO'),
    (46, 17, 2, NULL, '2026-10-29 19:22:00', 'RETIRADA', 'CANCELADO'),
    (47, 6, 1, 3, '2026-10-29 19:30:00', 'RETIRADA', 'FINALIZADO'),
    (48, 13, 2, 4, '2026-10-29 19:37:00', 'DELIVERY', 'FINALIZADO'),
    (49, 2, 1, 3, '2026-10-29 19:45:00', 'RETIRADA', 'FINALIZADO'),
    (50, 9, 2, 4, '2026-10-29 19:52:00', 'RETIRADA', 'FINALIZADO'),
    (51, 16, 1, NULL, '2026-10-29 20:00:00', 'DELIVERY', 'RECEBIDO'),
    (52, 5, 2, 4, '2026-10-29 20:07:00', 'RETIRADA', 'EM_PREPARACAO'),
    (53, 12, 1, 3, '2026-10-29 20:15:00', 'RETIRADA', 'FINALIZADO'),
    (54, 1, 2, 4, '2026-10-29 20:22:00', 'DELIVERY', 'FINALIZADO'),
    (55, 8, 1, 3, '2026-10-29 20:30:00', 'RETIRADA', 'PRONTO'),
    (56, 15, 2, 4, '2026-10-29 20:37:00', 'RETIRADA', 'FINALIZADO'),
    (57, 4, 1, 3, '2026-10-29 20:45:00', 'DELIVERY', 'FINALIZADO'),
    (58, 11, 2, 4, '2026-10-29 20:52:00', 'RETIRADA', 'FINALIZADO'),
    (59, 18, 1, 3, '2026-10-29 21:00:00', 'RETIRADA', 'FINALIZADO'),
    (60, 7, 2, 4, '2026-10-29 21:07:00', 'DELIVERY', 'FINALIZADO'),
    (61, 14, 1, 3, '2026-10-29 21:15:00', 'RETIRADA', 'FINALIZADO'),
    (62, 3, 2, 4, '2026-10-29 21:22:00', 'RETIRADA', 'FINALIZADO'),
    (63, 10, 1, 3, '2026-10-29 21:30:00', 'DELIVERY', 'FINALIZADO'),
    (64, 17, 2, 4, '2026-10-29 21:37:00', 'RETIRADA', 'FINALIZADO'),
    (65, 6, 1, 3, '2026-10-29 21:45:00', 'RETIRADA', 'EM_PREPARACAO'),
    (66, 13, 2, 4, '2026-10-29 21:52:00', 'DELIVERY', 'PRONTO'),
    (67, 2, 1, 3, '2026-10-29 22:00:00', 'RETIRADA', 'FINALIZADO'),
    (68, 9, 2, NULL, '2026-10-29 22:07:00', 'RETIRADA', 'RECEBIDO'),
    (69, 16, 1, NULL, '2026-10-29 22:15:00', 'DELIVERY', 'CANCELADO'),
    (70, 5, 2, 4, '2026-10-29 22:22:00', 'RETIRADA', 'FINALIZADO'),
    (71, 12, 1, 3, '2026-10-29 22:30:00', 'RETIRADA', 'FINALIZADO'),
    (72, 1, 2, 4, '2026-10-29 22:37:00', 'DELIVERY', 'FINALIZADO'),
    (73, 8, 1, 3, '2026-10-29 22:45:00', 'RETIRADA', 'FINALIZADO'),
    (74, 15, 2, 4, '2026-10-31 18:00:00', 'RETIRADA', 'FINALIZADO'),
    (75, 4, 1, 3, '2026-10-31 18:05:00', 'DELIVERY', 'FINALIZADO'),
    (76, 11, 2, 4, '2026-10-31 18:10:00', 'RETIRADA', 'FINALIZADO'),
    (77, 18, 1, 3, '2026-10-31 18:16:00', 'RETIRADA', 'PRONTO'),
    (78, 7, 2, 4, '2026-10-31 18:21:00', 'DELIVERY', 'EM_PREPARACAO'),
    (79, 14, 1, 3, '2026-10-31 18:26:00', 'RETIRADA', 'FINALIZADO'),
    (80, 3, 2, 4, '2026-10-31 18:32:00', 'RETIRADA', 'FINALIZADO'),
    (81, 10, 1, 3, '2026-10-31 18:37:00', 'DELIVERY', 'FINALIZADO'),
    (82, 17, 2, 4, '2026-10-31 18:43:00', 'RETIRADA', 'FINALIZADO'),
    (83, 6, 1, 3, '2026-10-31 18:48:00', 'RETIRADA', 'FINALIZADO'),
    (84, 13, 2, 4, '2026-10-31 18:53:00', 'DELIVERY', 'FINALIZADO'),
    (85, 2, 1, NULL, '2026-10-31 18:59:00', 'RETIRADA', 'RECEBIDO'),
    (86, 9, 2, 4, '2026-10-31 19:04:00', 'RETIRADA', 'FINALIZADO'),
    (87, 16, 1, 3, '2026-10-31 19:10:00', 'DELIVERY', 'FINALIZADO'),
    (88, 5, 2, 4, '2026-10-31 19:15:00', 'RETIRADA', 'PRONTO'),
    (89, 12, 1, 3, '2026-10-31 19:20:00', 'RETIRADA', 'FINALIZADO'),
    (90, 1, 2, 4, '2026-10-31 19:26:00', 'DELIVERY', 'FINALIZADO'),
    (91, 8, 1, 3, '2026-10-31 19:31:00', 'RETIRADA', 'EM_PREPARACAO'),
    (92, 15, 2, NULL, '2026-10-31 19:37:00', 'RETIRADA', 'CANCELADO'),
    (93, 4, 1, 3, '2026-10-31 19:42:00', 'DELIVERY', 'FINALIZADO'),
    (94, 11, 2, 4, '2026-10-31 19:47:00', 'RETIRADA', 'FINALIZADO'),
    (95, 18, 1, 3, '2026-10-31 19:53:00', 'RETIRADA', 'FINALIZADO'),
    (96, 7, 2, 4, '2026-10-31 19:58:00', 'DELIVERY', 'FINALIZADO'),
    (97, 14, 1, 3, '2026-10-31 20:03:00', 'RETIRADA', 'FINALIZADO'),
    (98, 3, 2, 4, '2026-10-31 20:09:00', 'RETIRADA', 'FINALIZADO'),
    (99, 10, 1, 3, '2026-10-31 20:14:00', 'DELIVERY', 'PRONTO'),
    (100, 17, 2, 4, '2026-10-31 20:20:00', 'RETIRADA', 'FINALIZADO'),
    (101, 6, 1, 3, '2026-10-31 20:25:00', 'RETIRADA', 'FINALIZADO'),
    (102, 13, 2, NULL, '2026-10-31 20:30:00', 'DELIVERY', 'RECEBIDO'),
    (103, 2, 1, 3, '2026-10-31 20:36:00', 'RETIRADA', 'FINALIZADO'),
    (104, 9, 2, 4, '2026-10-31 20:41:00', 'RETIRADA', 'EM_PREPARACAO'),
    (105, 16, 1, 3, '2026-10-31 20:47:00', 'DELIVERY', 'FINALIZADO'),
    (106, 5, 2, 4, '2026-10-31 20:52:00', 'RETIRADA', 'FINALIZADO'),
    (107, 12, 1, 3, '2026-10-31 20:57:00', 'RETIRADA', 'FINALIZADO'),
    (108, 1, 2, 4, '2026-10-31 21:03:00', 'DELIVERY', 'FINALIZADO'),
    (109, 8, 1, 3, '2026-10-31 21:08:00', 'RETIRADA', 'FINALIZADO'),
    (110, 15, 2, 4, '2026-10-31 21:14:00', 'RETIRADA', 'PRONTO'),
    (111, 4, 1, 3, '2026-10-31 21:19:00', 'DELIVERY', 'FINALIZADO'),
    (112, 11, 2, 4, '2026-10-31 21:24:00', 'RETIRADA', 'FINALIZADO'),
    (113, 18, 1, 3, '2026-10-31 21:30:00', 'RETIRADA', 'FINALIZADO'),
    (114, 7, 2, 4, '2026-10-31 21:35:00', 'DELIVERY', 'FINALIZADO'),
    (115, 14, 1, NULL, '2026-10-31 21:41:00', 'RETIRADA', 'CANCELADO'),
    (116, 3, 2, 4, '2026-10-31 21:46:00', 'RETIRADA', 'FINALIZADO'),
    (117, 10, 1, 3, '2026-10-31 21:51:00', 'DELIVERY', 'EM_PREPARACAO'),
    (118, 17, 2, 4, '2026-10-31 21:57:00', 'RETIRADA', 'FINALIZADO'),
    (119, 6, 1, NULL, '2026-10-31 22:02:00', 'RETIRADA', 'RECEBIDO'),
    (120, 13, 2, 4, '2026-10-31 22:07:00', 'DELIVERY', 'FINALIZADO'),
    (121, 2, 1, 3, '2026-10-31 22:13:00', 'RETIRADA', 'PRONTO'),
    (122, 9, 2, 4, '2026-10-31 22:18:00', 'RETIRADA', 'FINALIZADO'),
    (123, 16, 1, 3, '2026-10-31 22:24:00', 'DELIVERY', 'FINALIZADO'),
    (124, 5, 2, 4, '2026-10-31 22:29:00', 'RETIRADA', 'FINALIZADO'),
    (125, 12, 1, 3, '2026-10-31 22:34:00', 'RETIRADA', 'FINALIZADO'),
    (126, 1, 2, 4, '2026-10-31 22:40:00', 'DELIVERY', 'FINALIZADO'),
    (127, 8, 1, 3, '2026-10-31 22:45:00', 'RETIRADA', 'FINALIZADO'),
    (128, 15, 2, 4, '2026-10-31 22:51:00', 'RETIRADA', 'FINALIZADO'),
    (129, 4, 1, 3, '2026-10-31 22:56:00', 'DELIVERY', 'FINALIZADO'),
    (130, 11, 2, 4, '2026-10-31 23:01:00', 'RETIRADA', 'EM_PREPARACAO'),
    (131, 18, 1, 3, '2026-10-31 23:07:00', 'RETIRADA', 'FINALIZADO'),
    (132, 7, 2, 4, '2026-10-31 23:12:00', 'DELIVERY', 'PRONTO'),
    (133, 14, 1, 3, '2026-10-31 23:18:00', 'RETIRADA', 'FINALIZADO'),
    (134, 3, 2, 4, '2026-10-31 23:23:00', 'RETIRADA', 'FINALIZADO'),
    (135, 10, 1, 3, '2026-10-31 23:28:00', 'DELIVERY', 'FINALIZADO'),
    (136, 17, 2, NULL, '2026-10-31 23:34:00', 'RETIRADA', 'RECEBIDO'),
    (137, 6, 1, 3, '2026-10-31 23:39:00', 'RETIRADA', 'FINALIZADO'),
    (138, 13, 2, NULL, '2026-10-31 23:45:00', 'DELIVERY', 'CANCELADO');

INSERT INTO ITEM_PEDIDO (id_item_pedido, id_pedido, id_produto, quantidade, preco_unitario, observacao) VALUES
    (1, 1, 2, 2, 34.9, NULL),
    (2, 1, 5, 1, 14.9, NULL),
    (3, 2, 3, 1, 31.9, NULL),
    (4, 2, 6, 2, 16.9, NULL),
    (5, 2, 9, 1, 12.0, NULL),
    (6, 3, 4, 2, 39.9, NULL),
    (7, 4, 5, 1, 14.9, NULL),
    (8, 4, 8, 2, 4.0, NULL),
    (9, 5, 6, 2, 16.9, NULL),
    (10, 5, 9, 1, 12.0, NULL),
    (11, 5, 1, 2, 29.9, NULL),
    (12, 6, 7, 1, 6.0, NULL),
    (13, 7, 8, 2, 4.0, NULL),
    (14, 7, 11, 1, 44.9, NULL),
    (15, 8, 9, 1, 12.0, NULL),
    (16, 8, 1, 2, 29.9, NULL),
    (17, 8, 4, 1, 39.9, NULL),
    (18, 9, 10, 2, 15.0, NULL),
    (19, 10, 11, 1, 44.9, NULL),
    (20, 10, 3, 2, 31.9, NULL),
    (21, 11, 1, 2, 29.9, NULL),
    (22, 11, 4, 1, 39.9, NULL),
    (23, 11, 7, 2, 6.0, NULL),
    (24, 12, 2, 1, 34.9, NULL),
    (25, 13, 3, 2, 31.9, NULL),
    (26, 13, 6, 1, 16.9, NULL),
    (27, 14, 4, 1, 39.9, NULL),
    (28, 14, 7, 2, 6.0, NULL),
    (29, 14, 10, 1, 15.0, NULL),
    (30, 15, 5, 2, 14.9, NULL),
    (31, 16, 6, 1, 16.9, NULL),
    (32, 16, 9, 2, 12.0, NULL),
    (33, 17, 7, 2, 6.0, NULL),
    (34, 17, 10, 1, 15.0, NULL),
    (35, 17, 2, 2, 34.9, 'Sem cebola (dado ficticio)'),
    (36, 18, 8, 1, 4.0, NULL),
    (37, 19, 9, 2, 12.0, 'Sem cebola (dado ficticio)'),
    (38, 19, 1, 1, 29.9, NULL),
    (39, 20, 10, 1, 15.0, NULL),
    (40, 20, 2, 2, 34.9, NULL),
    (41, 20, 5, 1, 14.9, NULL),
    (42, 21, 11, 2, 44.9, NULL),
    (43, 22, 1, 1, 29.9, NULL),
    (44, 22, 4, 2, 39.9, NULL),
    (45, 23, 2, 2, 34.9, NULL),
    (46, 23, 5, 1, 14.9, NULL),
    (47, 23, 8, 2, 4.0, NULL),
    (48, 24, 3, 1, 31.9, NULL),
    (49, 25, 4, 2, 39.9, NULL),
    (50, 25, 7, 1, 6.0, NULL),
    (51, 26, 5, 1, 14.9, NULL),
    (52, 26, 8, 2, 4.0, NULL),
    (53, 26, 11, 1, 44.9, NULL),
    (54, 27, 6, 2, 16.9, NULL),
    (55, 28, 7, 1, 6.0, NULL),
    (56, 28, 10, 2, 15.0, NULL),
    (57, 29, 8, 2, 4.0, NULL),
    (58, 29, 11, 1, 44.9, NULL),
    (59, 29, 3, 2, 31.9, NULL),
    (60, 30, 9, 1, 12.0, NULL),
    (61, 31, 10, 2, 15.0, NULL),
    (62, 31, 2, 1, 34.9, NULL),
    (63, 32, 11, 1, 44.9, NULL),
    (64, 32, 3, 2, 31.9, NULL),
    (65, 32, 6, 1, 16.9, NULL),
    (66, 33, 1, 2, 29.9, NULL),
    (67, 34, 2, 1, 34.9, NULL),
    (68, 34, 5, 2, 14.9, NULL),
    (69, 35, 3, 2, 31.9, NULL),
    (70, 35, 6, 1, 16.9, NULL),
    (71, 35, 9, 2, 12.0, NULL),
    (72, 36, 4, 1, 39.9, NULL),
    (73, 37, 5, 2, 14.9, NULL),
    (74, 37, 8, 1, 4.0, 'Sem cebola (dado ficticio)'),
    (75, 38, 6, 1, 16.9, 'Sem cebola (dado ficticio)'),
    (76, 38, 9, 2, 12.0, NULL),
    (77, 38, 1, 1, 29.9, NULL),
    (78, 39, 7, 2, 6.0, NULL),
    (79, 40, 8, 1, 4.0, NULL),
    (80, 40, 11, 2, 44.9, NULL),
    (81, 41, 9, 2, 12.0, NULL),
    (82, 41, 1, 1, 29.9, NULL),
    (83, 41, 4, 2, 39.9, NULL),
    (84, 42, 10, 1, 15.0, NULL),
    (85, 43, 11, 2, 44.9, NULL),
    (86, 43, 3, 1, 31.9, NULL),
    (87, 44, 1, 1, 29.9, NULL),
    (88, 44, 4, 2, 39.9, NULL),
    (89, 44, 7, 1, 6.0, NULL),
    (90, 45, 2, 2, 34.9, NULL),
    (91, 46, 3, 1, 31.9, NULL),
    (92, 46, 6, 2, 16.9, NULL),
    (93, 47, 4, 2, 39.9, NULL),
    (94, 47, 7, 1, 6.0, NULL),
    (95, 47, 10, 2, 15.0, NULL),
    (96, 48, 5, 1, 14.9, NULL),
    (97, 49, 6, 2, 16.9, NULL),
    (98, 49, 9, 1, 12.0, NULL),
    (99, 50, 7, 1, 6.0, NULL),
    (100, 50, 10, 2, 15.0, NULL),
    (101, 50, 2, 1, 34.9, NULL),
    (102, 51, 8, 2, 4.0, NULL),
    (103, 52, 9, 1, 12.0, NULL),
    (104, 52, 1, 2, 29.9, NULL),
    (105, 53, 10, 2, 15.0, NULL),
    (106, 53, 2, 1, 34.9, NULL),
    (107, 53, 5, 2, 14.9, NULL),
    (108, 54, 11, 1, 44.9, NULL),
    (109, 55, 1, 2, 29.9, NULL),
    (110, 55, 4, 1, 39.9, NULL),
    (111, 56, 2, 1, 34.9, NULL),
    (112, 56, 5, 2, 14.9, 'Sem cebola (dado ficticio)'),
    (113, 56, 8, 1, 4.0, NULL),
    (114, 57, 3, 2, 31.9, 'Sem cebola (dado ficticio)'),
    (115, 58, 4, 1, 39.9, NULL),
    (116, 58, 7, 2, 6.0, NULL),
    (117, 59, 5, 2, 14.9, NULL),
    (118, 59, 8, 1, 4.0, NULL),
    (119, 59, 11, 2, 44.9, NULL),
    (120, 60, 6, 1, 16.9, NULL),
    (121, 61, 7, 2, 6.0, NULL),
    (122, 61, 10, 1, 15.0, NULL),
    (123, 62, 8, 1, 4.0, NULL),
    (124, 62, 11, 2, 44.9, NULL),
    (125, 62, 3, 1, 31.9, NULL),
    (126, 63, 9, 2, 12.0, NULL),
    (127, 64, 10, 1, 15.0, NULL),
    (128, 64, 2, 2, 34.9, NULL),
    (129, 65, 11, 2, 44.9, NULL),
    (130, 65, 3, 1, 31.9, NULL),
    (131, 65, 6, 2, 16.9, NULL),
    (132, 66, 1, 1, 29.9, NULL),
    (133, 67, 2, 2, 34.9, NULL),
    (134, 67, 5, 1, 14.9, NULL),
    (135, 68, 3, 1, 31.9, NULL),
    (136, 68, 6, 2, 16.9, NULL),
    (137, 68, 9, 1, 12.0, NULL),
    (138, 69, 4, 2, 39.9, NULL),
    (139, 70, 5, 1, 14.9, NULL),
    (140, 70, 8, 2, 4.0, NULL),
    (141, 71, 6, 2, 16.9, NULL),
    (142, 71, 9, 1, 12.0, NULL),
    (143, 71, 1, 2, 29.9, NULL),
    (144, 72, 7, 1, 6.0, NULL),
    (145, 73, 8, 2, 4.0, NULL),
    (146, 73, 11, 1, 44.9, NULL),
    (147, 74, 9, 1, 12.0, NULL),
    (148, 74, 1, 2, 29.9, NULL),
    (149, 74, 4, 1, 39.9, 'Sem cebola (dado ficticio)'),
    (150, 75, 10, 2, 15.0, NULL),
    (151, 76, 11, 1, 44.9, 'Sem cebola (dado ficticio)'),
    (152, 76, 3, 2, 31.9, NULL),
    (153, 77, 1, 2, 29.9, NULL),
    (154, 77, 4, 1, 39.9, NULL),
    (155, 77, 7, 2, 6.0, NULL),
    (156, 78, 2, 1, 34.9, NULL),
    (157, 79, 3, 2, 31.9, NULL),
    (158, 79, 6, 1, 16.9, NULL),
    (159, 80, 4, 1, 39.9, NULL),
    (160, 80, 7, 2, 6.0, NULL),
    (161, 80, 10, 1, 15.0, NULL),
    (162, 81, 5, 2, 14.9, NULL),
    (163, 82, 6, 1, 16.9, NULL),
    (164, 82, 9, 2, 12.0, NULL),
    (165, 83, 7, 2, 6.0, NULL),
    (166, 83, 10, 1, 15.0, NULL),
    (167, 83, 2, 2, 34.9, NULL),
    (168, 84, 8, 1, 4.0, NULL),
    (169, 85, 9, 2, 12.0, NULL),
    (170, 85, 1, 1, 29.9, NULL),
    (171, 86, 10, 1, 15.0, NULL),
    (172, 86, 2, 2, 34.9, NULL),
    (173, 86, 5, 1, 14.9, NULL),
    (174, 87, 11, 2, 44.9, NULL),
    (175, 88, 1, 1, 29.9, NULL),
    (176, 88, 4, 2, 39.9, NULL),
    (177, 89, 2, 2, 34.9, NULL),
    (178, 89, 5, 1, 14.9, NULL),
    (179, 89, 8, 2, 4.0, NULL),
    (180, 90, 3, 1, 31.9, NULL),
    (181, 91, 4, 2, 39.9, NULL),
    (182, 91, 7, 1, 6.0, NULL),
    (183, 92, 5, 1, 14.9, NULL),
    (184, 92, 8, 2, 4.0, NULL),
    (185, 92, 11, 1, 44.9, NULL),
    (186, 93, 6, 2, 16.9, NULL),
    (187, 94, 7, 1, 6.0, NULL),
    (188, 94, 10, 2, 15.0, 'Sem cebola (dado ficticio)'),
    (189, 95, 8, 2, 4.0, 'Sem cebola (dado ficticio)'),
    (190, 95, 11, 1, 44.9, NULL),
    (191, 95, 3, 2, 31.9, NULL),
    (192, 96, 9, 1, 12.0, NULL),
    (193, 97, 10, 2, 15.0, NULL),
    (194, 97, 2, 1, 34.9, NULL),
    (195, 98, 11, 1, 44.9, NULL),
    (196, 98, 3, 2, 31.9, NULL),
    (197, 98, 6, 1, 16.9, NULL),
    (198, 99, 1, 2, 29.9, NULL),
    (199, 100, 2, 1, 34.9, NULL),
    (200, 100, 5, 2, 14.9, NULL),
    (201, 101, 3, 2, 31.9, NULL),
    (202, 101, 6, 1, 16.9, NULL),
    (203, 101, 9, 2, 12.0, NULL),
    (204, 102, 4, 1, 39.9, NULL),
    (205, 103, 5, 2, 14.9, NULL),
    (206, 103, 8, 1, 4.0, NULL),
    (207, 104, 6, 1, 16.9, NULL),
    (208, 104, 9, 2, 12.0, NULL),
    (209, 104, 1, 1, 29.9, NULL),
    (210, 105, 7, 2, 6.0, NULL),
    (211, 106, 8, 1, 4.0, NULL),
    (212, 106, 11, 2, 44.9, NULL),
    (213, 107, 9, 2, 12.0, NULL),
    (214, 107, 1, 1, 29.9, NULL),
    (215, 107, 4, 2, 39.9, NULL),
    (216, 108, 10, 1, 15.0, NULL),
    (217, 109, 11, 2, 44.9, NULL),
    (218, 109, 3, 1, 31.9, NULL),
    (219, 110, 1, 1, 29.9, NULL),
    (220, 110, 4, 2, 39.9, NULL),
    (221, 110, 7, 1, 6.0, NULL),
    (222, 111, 2, 2, 34.9, NULL),
    (223, 112, 3, 1, 31.9, NULL),
    (224, 112, 6, 2, 16.9, NULL),
    (225, 113, 4, 2, 39.9, NULL),
    (226, 113, 7, 1, 6.0, 'Sem cebola (dado ficticio)'),
    (227, 113, 10, 2, 15.0, NULL),
    (228, 114, 5, 1, 14.9, 'Sem cebola (dado ficticio)'),
    (229, 115, 6, 2, 16.9, NULL),
    (230, 115, 9, 1, 12.0, NULL),
    (231, 116, 7, 1, 6.0, NULL),
    (232, 116, 10, 2, 15.0, NULL),
    (233, 116, 2, 1, 34.9, NULL),
    (234, 117, 8, 2, 4.0, NULL),
    (235, 118, 9, 1, 12.0, NULL),
    (236, 118, 1, 2, 29.9, NULL),
    (237, 119, 10, 2, 15.0, NULL),
    (238, 119, 2, 1, 34.9, NULL),
    (239, 119, 5, 2, 14.9, NULL),
    (240, 120, 11, 1, 44.9, NULL),
    (241, 121, 1, 2, 29.9, NULL),
    (242, 121, 4, 1, 39.9, NULL),
    (243, 122, 2, 1, 34.9, NULL),
    (244, 122, 5, 2, 14.9, NULL),
    (245, 122, 8, 1, 4.0, NULL),
    (246, 123, 3, 2, 31.9, NULL),
    (247, 124, 4, 1, 39.9, NULL),
    (248, 124, 7, 2, 6.0, NULL),
    (249, 125, 5, 2, 14.9, NULL),
    (250, 125, 8, 1, 4.0, NULL),
    (251, 125, 11, 2, 44.9, NULL),
    (252, 126, 6, 1, 16.9, NULL),
    (253, 127, 7, 2, 6.0, NULL),
    (254, 127, 10, 1, 15.0, NULL),
    (255, 128, 8, 1, 4.0, NULL),
    (256, 128, 11, 2, 44.9, NULL),
    (257, 128, 3, 1, 31.9, NULL),
    (258, 129, 9, 2, 12.0, NULL),
    (259, 130, 10, 1, 15.0, NULL),
    (260, 130, 2, 2, 34.9, NULL),
    (261, 131, 11, 2, 44.9, NULL),
    (262, 131, 3, 1, 31.9, NULL),
    (263, 131, 6, 2, 16.9, 'Sem cebola (dado ficticio)'),
    (264, 132, 1, 1, 29.9, NULL),
    (265, 133, 2, 2, 34.9, 'Sem cebola (dado ficticio)'),
    (266, 133, 5, 1, 14.9, NULL),
    (267, 134, 3, 1, 31.9, NULL),
    (268, 134, 6, 2, 16.9, NULL),
    (269, 134, 9, 1, 12.0, NULL),
    (270, 135, 4, 2, 39.9, NULL),
    (271, 136, 5, 1, 14.9, NULL),
    (272, 136, 8, 2, 4.0, NULL),
    (273, 137, 6, 2, 16.9, NULL),
    (274, 137, 9, 1, 12.0, NULL),
    (275, 137, 1, 2, 29.9, NULL),
    (276, 138, 7, 1, 6.0, NULL);

INSERT INTO ENTREGA (id_entrega, id_pedido, id_motoboy, id_area_entrega, logradouro, numero, complemento, cep, taxa_entrega_aplicada, data_hora_saida, data_hora_entrega, status) VALUES
    (1, 3, 1, 3, 'Rua Ficticia 003', '13', NULL, '00000-000', 7.00, '2026-10-28 18:39:00', '2026-10-28 18:59:00', 'ENTREGUE'),
    (2, 6, 1, 3, 'Rua Ficticia 006', '16', NULL, '00000-000', 7.00, '2026-10-28 19:05:00', '2026-10-28 19:25:00', 'ENTREGUE'),
    (3, 9, 1, 3, 'Rua Ficticia 009', '19', NULL, '00000-000', 7.00, '2026-10-28 19:31:00', '2026-10-28 19:51:00', 'ENTREGUE'),
    (4, 12, 1, 3, 'Rua Ficticia 012', '22', NULL, '00000-000', 7.00, '2026-10-28 19:57:00', '2026-10-28 20:17:00', 'ENTREGUE'),
    (5, 15, 1, 3, 'Rua Ficticia 015', '25', NULL, '00000-000', 7.00, '2026-10-28 20:22:00', '2026-10-28 20:42:00', 'ENTREGUE'),
    (6, 18, 1, 3, 'Rua Ficticia 018', '28', NULL, '00000-000', 7.00, '2026-10-28 20:48:00', '2026-10-28 21:08:00', 'ENTREGUE'),
    (7, 21, 1, 3, 'Rua Ficticia 021', '31', NULL, '00000-000', 7.00, '2026-10-28 21:14:00', '2026-10-28 21:34:00', 'ENTREGUE'),
    (8, 24, 1, 3, 'Rua Ficticia 024', '34', NULL, '00000-000', 7.00, '2026-10-28 21:40:00', '2026-10-28 22:00:00', 'ENTREGUE'),
    (9, 27, 1, 3, 'Rua Ficticia 027', '37', NULL, '00000-000', 7.00, '2026-10-28 22:06:00', '2026-10-28 22:26:00', 'ENTREGUE'),
    (10, 30, 1, 3, 'Rua Ficticia 030', '40', NULL, '00000-000', 7.00, '2026-10-28 22:32:00', '2026-10-28 22:52:00', 'ENTREGUE'),
    (11, 33, 1, 3, 'Rua Ficticia 033', '43', NULL, '00000-000', 7.00, NULL, NULL, 'AGUARDANDO'),
    (12, 36, 1, 3, 'Rua Ficticia 036', '46', NULL, '00000-000', 7.00, '2026-10-29 18:29:00', '2026-10-29 18:49:00', 'ENTREGUE'),
    (13, 39, 1, 3, 'Rua Ficticia 039', '49', NULL, '00000-000', 7.00, NULL, NULL, 'AGUARDANDO'),
    (14, 42, 1, 3, 'Rua Ficticia 042', '52', NULL, '00000-000', 7.00, '2026-10-29 19:14:00', '2026-10-29 19:34:00', 'ENTREGUE'),
    (15, 45, 1, 3, 'Rua Ficticia 045', '55', NULL, '00000-000', 7.00, '2026-10-29 19:37:00', '2026-10-29 19:57:00', 'ENTREGUE'),
    (16, 48, 1, 3, 'Rua Ficticia 048', '58', NULL, '00000-000', 7.00, '2026-10-29 19:59:00', '2026-10-29 20:19:00', 'ENTREGUE'),
    (17, 51, 1, 3, 'Rua Ficticia 051', '61', NULL, '00000-000', 7.00, NULL, NULL, 'AGUARDANDO'),
    (18, 54, 1, 3, 'Rua Ficticia 054', '64', NULL, '00000-000', 7.00, '2026-10-29 20:44:00', '2026-10-29 21:04:00', 'ENTREGUE'),
    (19, 57, 1, 3, 'Rua Ficticia 057', '67', NULL, '00000-000', 7.00, '2026-10-29 21:07:00', '2026-10-29 21:27:00', 'ENTREGUE'),
    (20, 60, 1, 3, 'Rua Ficticia 060', '70', NULL, '00000-000', 7.00, '2026-10-29 21:29:00', '2026-10-29 21:49:00', 'ENTREGUE'),
    (21, 63, 1, 3, 'Rua Ficticia 063', '73', NULL, '00000-000', 7.00, '2026-10-29 21:52:00', '2026-10-29 22:12:00', 'ENTREGUE'),
    (22, 66, 1, 3, 'Rua Ficticia 066', '76', NULL, '00000-000', 7.00, NULL, NULL, 'AGUARDANDO'),
    (23, 72, 1, 3, 'Rua Ficticia 072', '82', NULL, '00000-000', 7.00, '2026-10-29 22:59:00', '2026-10-29 23:19:00', 'ENTREGUE'),
    (24, 75, 1, 3, 'Rua Ficticia 075', '85', NULL, '00000-000', 7.00, '2026-10-31 18:27:00', '2026-10-31 18:47:00', 'ENTREGUE'),
    (25, 78, 1, 3, 'Rua Ficticia 078', '88', NULL, '00000-000', 7.00, NULL, NULL, 'AGUARDANDO'),
    (26, 81, 1, 3, 'Rua Ficticia 081', '91', NULL, '00000-000', 7.00, '2026-10-31 18:59:00', '2026-10-31 19:19:00', 'ENTREGUE'),
    (27, 84, 1, 3, 'Rua Ficticia 084', '94', NULL, '00000-000', 7.00, '2026-10-31 19:15:00', '2026-10-31 19:35:00', 'ENTREGUE'),
    (28, 87, 1, 3, 'Rua Ficticia 087', '97', NULL, '00000-000', 7.00, '2026-10-31 19:32:00', '2026-10-31 19:52:00', 'ENTREGUE'),
    (29, 90, 1, 3, 'Rua Ficticia 090', '100', NULL, '00000-000', 7.00, '2026-10-31 19:48:00', '2026-10-31 20:08:00', 'ENTREGUE'),
    (30, 93, 1, 3, 'Rua Ficticia 093', '103', NULL, '00000-000', 7.00, '2026-10-31 20:04:00', '2026-10-31 20:24:00', 'ENTREGUE'),
    (31, 96, 1, 3, 'Rua Ficticia 096', '106', NULL, '00000-000', 7.00, '2026-10-31 20:20:00', '2026-10-31 20:40:00', 'ENTREGUE'),
    (32, 99, 1, 3, 'Rua Ficticia 099', '109', NULL, '00000-000', 7.00, NULL, NULL, 'AGUARDANDO'),
    (33, 102, 1, 3, 'Rua Ficticia 102', '112', NULL, '00000-000', 7.00, NULL, NULL, 'AGUARDANDO'),
    (34, 105, 1, 3, 'Rua Ficticia 105', '115', NULL, '00000-000', 7.00, '2026-10-31 21:09:00', '2026-10-31 21:29:00', 'ENTREGUE'),
    (35, 108, 1, 3, 'Rua Ficticia 108', '118', NULL, '00000-000', 7.00, '2026-10-31 21:25:00', '2026-10-31 21:45:00', 'ENTREGUE'),
    (36, 111, 1, 3, 'Rua Ficticia 111', '121', NULL, '00000-000', 7.00, '2026-10-31 21:41:00', '2026-10-31 22:01:00', 'ENTREGUE'),
    (37, 114, 1, 3, 'Rua Ficticia 114', '124', NULL, '00000-000', 7.00, '2026-10-31 21:57:00', '2026-10-31 22:17:00', 'ENTREGUE'),
    (38, 117, 1, 3, 'Rua Ficticia 117', '127', NULL, '00000-000', 7.00, NULL, NULL, 'AGUARDANDO'),
    (39, 120, 1, 3, 'Rua Ficticia 120', '130', NULL, '00000-000', 7.00, '2026-10-31 22:29:00', '2026-10-31 22:49:00', 'ENTREGUE'),
    (40, 123, 1, 3, 'Rua Ficticia 123', '133', NULL, '00000-000', 7.00, '2026-10-31 22:46:00', '2026-10-31 23:06:00', 'ENTREGUE'),
    (41, 126, 1, 3, 'Rua Ficticia 126', '136', NULL, '00000-000', 7.00, '2026-10-31 23:02:00', '2026-10-31 23:22:00', 'ENTREGUE'),
    (42, 129, 1, 3, 'Rua Ficticia 129', '139', NULL, '00000-000', 7.00, '2026-10-31 23:18:00', '2026-10-31 23:38:00', 'ENTREGUE'),
    (43, 132, 1, 3, 'Rua Ficticia 132', '142', NULL, '00000-000', 7.00, NULL, NULL, 'AGUARDANDO'),
    (44, 135, 1, 3, 'Rua Ficticia 135', '145', NULL, '00000-000', 7.00, '2026-10-31 23:50:00', '2026-11-01 00:10:00', 'ENTREGUE');

INSERT INTO PAGAMENTO (id_pagamento, id_pedido, id_fechamento, forma_pagamento, valor, data_hora) VALUES
    (1, 1, 1, 'PIX', 84.70, '2026-10-28 18:25:00'),
    (2, 2, 1, 'DINHEIRO', 77.70, '2026-10-28 18:33:00'),
    (3, 3, 1, 'CARTAO_DEBITO', 86.80, '2026-10-28 18:42:00'),
    (4, 4, 1, 'CARTAO_CREDITO', 22.90, '2026-10-28 18:50:00'),
    (5, 5, 1, 'PIX', 105.60, '2026-10-28 18:59:00'),
    (6, 6, 1, 'DINHEIRO', 13.00, '2026-10-28 19:08:00'),
    (7, 7, 1, 'CARTAO_DEBITO', 52.90, '2026-10-28 19:16:00'),
    (8, 8, 1, 'CARTAO_CREDITO', 111.70, '2026-10-28 19:25:00'),
    (9, 9, 1, 'PIX', 37.00, '2026-10-28 19:34:00'),
    (10, 10, 1, 'DINHEIRO', 108.70, '2026-10-28 19:42:00'),
    (11, 11, 1, 'CARTAO_DEBITO', 111.70, '2026-10-28 19:51:00'),
    (12, 12, 1, 'CARTAO_CREDITO', 41.90, '2026-10-28 20:00:00'),
    (13, 13, 1, 'PIX', 80.70, '2026-10-28 20:08:00'),
    (14, 14, 1, 'DINHEIRO', 66.90, '2026-10-28 20:17:00'),
    (15, 15, 1, 'CARTAO_DEBITO', 36.80, '2026-10-28 20:25:00'),
    (16, 16, 1, 'CARTAO_CREDITO', 40.90, '2026-10-28 20:34:00'),
    (17, 17, 1, 'PIX', 96.80, '2026-10-28 20:43:00'),
    (18, 18, 1, 'DINHEIRO', 11.00, '2026-10-28 20:51:00'),
    (19, 19, 1, 'CARTAO_DEBITO', 53.90, '2026-10-28 21:00:00'),
    (20, 20, 1, 'CARTAO_CREDITO', 99.70, '2026-10-28 21:09:00'),
    (21, 21, 1, 'PIX', 96.80, '2026-10-28 21:17:00'),
    (22, 22, 1, 'DINHEIRO', 109.70, '2026-10-28 21:26:00'),
    (23, 24, 1, 'CARTAO_CREDITO', 38.90, '2026-10-28 21:43:00'),
    (24, 25, 1, 'PIX', 85.80, '2026-10-28 21:52:00'),
    (25, 26, 1, 'DINHEIRO', 67.80, '2026-10-28 22:00:00'),
    (26, 27, 1, 'CARTAO_DEBITO', 40.80, '2026-10-28 22:09:00'),
    (27, 28, 1, 'CARTAO_CREDITO', 36.00, '2026-10-28 22:18:00'),
    (28, 29, 1, 'PIX', 116.70, '2026-10-28 22:26:00'),
    (29, 30, 1, 'DINHEIRO', 19.00, '2026-10-28 22:35:00'),
    (30, 31, 1, 'CARTAO_DEBITO', 64.90, '2026-10-28 22:44:00'),
    (31, 32, 1, 'CARTAO_CREDITO', 125.60, '2026-10-28 22:52:00'),
    (32, 33, 1, 'PIX', 66.80, '2026-10-28 23:01:00'),
    (33, 34, 1, 'DINHEIRO', 64.70, '2026-10-28 23:10:00'),
    (34, 35, 2, 'CARTAO_DEBITO', 104.70, '2026-10-29 18:25:00'),
    (35, 36, 2, 'CARTAO_CREDITO', 46.90, '2026-10-29 18:32:00'),
    (36, 37, 2, 'PIX', 33.80, '2026-10-29 18:40:00'),
    (37, 38, 2, 'DINHEIRO', 70.80, '2026-10-29 18:47:00'),
    (38, 39, 2, 'CARTAO_DEBITO', 19.00, '2026-10-29 18:55:00'),
    (39, 40, 2, 'CARTAO_CREDITO', 93.80, '2026-10-29 19:02:00'),
    (40, 41, 2, 'PIX', 133.70, '2026-10-29 19:10:00'),
    (41, 42, 2, 'DINHEIRO', 22.00, '2026-10-29 19:17:00'),
    (42, 43, 2, 'CARTAO_DEBITO', 121.70, '2026-10-29 19:25:00'),
    (43, 44, 2, 'CARTAO_CREDITO', 115.70, '2026-10-29 19:32:00'),
    (44, 45, 2, 'PIX', 76.80, '2026-10-29 19:40:00'),
    (45, 47, 2, 'CARTAO_DEBITO', 115.80, '2026-10-29 19:55:00'),
    (46, 48, 2, 'CARTAO_CREDITO', 21.90, '2026-10-29 20:02:00'),
    (47, 49, 2, 'PIX', 45.80, '2026-10-29 20:10:00'),
    (48, 50, 2, 'DINHEIRO', 70.90, '2026-10-29 20:17:00'),
    (49, 51, 2, 'CARTAO_DEBITO', 15.00, '2026-10-29 20:25:00'),
    (50, 52, 2, 'CARTAO_CREDITO', 71.80, '2026-10-29 20:32:00'),
    (51, 53, 2, 'PIX', 94.70, '2026-10-29 20:40:00'),
    (52, 54, 2, 'DINHEIRO', 51.90, '2026-10-29 20:47:00'),
    (53, 55, 2, 'CARTAO_DEBITO', 99.70, '2026-10-29 20:55:00'),
    (54, 56, 2, 'CARTAO_CREDITO', 68.70, '2026-10-29 21:02:00'),
    (55, 57, 2, 'PIX', 70.80, '2026-10-29 21:10:00'),
    (56, 58, 2, 'DINHEIRO', 51.90, '2026-10-29 21:17:00'),
    (57, 59, 2, 'CARTAO_DEBITO', 123.60, '2026-10-29 21:25:00'),
    (58, 60, 2, 'CARTAO_CREDITO', 23.90, '2026-10-29 21:32:00'),
    (59, 61, 2, 'PIX', 27.00, '2026-10-29 21:40:00'),
    (60, 62, 2, 'DINHEIRO', 125.70, '2026-10-29 21:47:00'),
    (61, 63, 2, 'CARTAO_DEBITO', 31.00, '2026-10-29 21:55:00'),
    (62, 64, 2, 'CARTAO_CREDITO', 84.80, '2026-10-29 22:02:00'),
    (63, 65, 2, 'PIX', 155.50, '2026-10-29 22:10:00'),
    (64, 66, 2, 'DINHEIRO', 36.90, '2026-10-29 22:17:00'),
    (65, 67, 2, 'CARTAO_DEBITO', 84.70, '2026-10-29 22:25:00'),
    (66, 68, 2, 'CARTAO_CREDITO', 77.70, '2026-10-29 22:32:00'),
    (67, 70, 2, 'DINHEIRO', 22.90, '2026-10-29 22:47:00'),
    (68, 71, 2, 'CARTAO_DEBITO', 105.60, '2026-10-29 22:55:00'),
    (69, 72, 2, 'CARTAO_CREDITO', 13.00, '2026-10-29 23:02:00'),
    (70, 73, 2, 'PIX', 52.90, '2026-10-29 23:10:00'),
    (71, 74, 3, 'DINHEIRO', 111.70, '2026-10-31 18:25:00'),
    (72, 75, 3, 'CARTAO_DEBITO', 37.00, '2026-10-31 18:30:00'),
    (73, 76, 3, 'CARTAO_CREDITO', 108.70, '2026-10-31 18:35:00'),
    (74, 77, 3, 'PIX', 111.70, '2026-10-31 18:41:00'),
    (75, 78, 3, 'DINHEIRO', 41.90, '2026-10-31 18:46:00'),
    (76, 79, 3, 'CARTAO_DEBITO', 80.70, '2026-10-31 18:51:00'),
    (77, 80, 3, 'CARTAO_CREDITO', 66.90, '2026-10-31 18:57:00'),
    (78, 81, 3, 'PIX', 36.80, '2026-10-31 19:02:00'),
    (79, 82, 3, 'DINHEIRO', 40.90, '2026-10-31 19:08:00'),
    (80, 83, 3, 'CARTAO_DEBITO', 96.80, '2026-10-31 19:13:00'),
    (81, 84, 3, 'CARTAO_CREDITO', 11.00, '2026-10-31 19:18:00'),
    (82, 85, 3, 'PIX', 53.90, '2026-10-31 19:24:00'),
    (83, 86, 3, 'DINHEIRO', 99.70, '2026-10-31 19:29:00'),
    (84, 87, 3, 'CARTAO_DEBITO', 96.80, '2026-10-31 19:35:00'),
    (85, 88, 3, 'CARTAO_CREDITO', 109.70, '2026-10-31 19:40:00'),
    (86, 89, 3, 'PIX', 92.70, '2026-10-31 19:45:00'),
    (87, 90, 3, 'DINHEIRO', 38.90, '2026-10-31 19:51:00'),
    (88, 91, 3, 'CARTAO_DEBITO', 85.80, '2026-10-31 19:56:00'),
    (89, 93, 3, 'PIX', 40.80, '2026-10-31 20:07:00'),
    (90, 94, 3, 'DINHEIRO', 36.00, '2026-10-31 20:12:00'),
    (91, 95, 3, 'CARTAO_DEBITO', 116.70, '2026-10-31 20:18:00'),
    (92, 96, 3, 'CARTAO_CREDITO', 19.00, '2026-10-31 20:23:00'),
    (93, 97, 3, 'PIX', 64.90, '2026-10-31 20:28:00'),
    (94, 98, 3, 'DINHEIRO', 125.60, '2026-10-31 20:34:00'),
    (95, 99, 3, 'CARTAO_DEBITO', 66.80, '2026-10-31 20:39:00'),
    (96, 100, 3, 'CARTAO_CREDITO', 64.70, '2026-10-31 20:45:00'),
    (97, 101, 3, 'PIX', 104.70, '2026-10-31 20:50:00'),
    (98, 102, 3, 'DINHEIRO', 46.90, '2026-10-31 20:55:00'),
    (99, 103, 3, 'CARTAO_DEBITO', 33.80, '2026-10-31 21:01:00'),
    (100, 104, 3, 'CARTAO_CREDITO', 70.80, '2026-10-31 21:06:00'),
    (101, 105, 3, 'PIX', 19.00, '2026-10-31 21:12:00'),
    (102, 106, 3, 'DINHEIRO', 93.80, '2026-10-31 21:17:00'),
    (103, 107, 3, 'CARTAO_DEBITO', 133.70, '2026-10-31 21:22:00'),
    (104, 108, 3, 'CARTAO_CREDITO', 22.00, '2026-10-31 21:28:00'),
    (105, 109, 3, 'PIX', 121.70, '2026-10-31 21:33:00'),
    (106, 110, 3, 'DINHEIRO', 115.70, '2026-10-31 21:39:00'),
    (107, 111, 3, 'CARTAO_DEBITO', 76.80, '2026-10-31 21:44:00'),
    (108, 112, 3, 'CARTAO_CREDITO', 65.70, '2026-10-31 21:49:00'),
    (109, 113, 3, 'PIX', 115.80, '2026-10-31 21:55:00'),
    (110, 114, 3, 'DINHEIRO', 21.90, '2026-10-31 22:00:00'),
    (111, 116, 3, 'CARTAO_CREDITO', 70.90, '2026-10-31 22:11:00'),
    (112, 117, 3, 'PIX', 15.00, '2026-10-31 22:16:00'),
    (113, 118, 3, 'DINHEIRO', 71.80, '2026-10-31 22:22:00'),
    (114, 119, 3, 'CARTAO_DEBITO', 94.70, '2026-10-31 22:27:00'),
    (115, 120, 3, 'CARTAO_CREDITO', 51.90, '2026-10-31 22:32:00'),
    (116, 121, 3, 'PIX', 99.70, '2026-10-31 22:38:00'),
    (117, 122, 3, 'DINHEIRO', 68.70, '2026-10-31 22:43:00'),
    (118, 123, 3, 'CARTAO_DEBITO', 70.80, '2026-10-31 22:49:00'),
    (119, 124, 3, 'CARTAO_CREDITO', 51.90, '2026-10-31 22:54:00'),
    (120, 125, 3, 'PIX', 123.60, '2026-10-31 22:59:00'),
    (121, 126, 3, 'DINHEIRO', 23.90, '2026-10-31 23:05:00'),
    (122, 127, 3, 'CARTAO_DEBITO', 27.00, '2026-10-31 23:10:00'),
    (123, 128, 3, 'CARTAO_CREDITO', 125.70, '2026-10-31 23:16:00'),
    (124, 129, 3, 'PIX', 31.00, '2026-10-31 23:21:00'),
    (125, 130, 3, 'DINHEIRO', 84.80, '2026-10-31 23:26:00'),
    (126, 131, 3, 'CARTAO_DEBITO', 155.50, '2026-10-31 23:32:00'),
    (127, 132, 3, 'CARTAO_CREDITO', 36.90, '2026-10-31 23:37:00'),
    (128, 133, 3, 'PIX', 84.70, '2026-10-31 23:43:00'),
    (129, 134, 3, 'DINHEIRO', 77.70, '2026-10-31 23:48:00'),
    (130, 135, 3, 'CARTAO_DEBITO', 86.80, '2026-10-31 23:53:00'),
    (131, 136, 3, 'CARTAO_CREDITO', 22.90, '2026-10-31 23:59:00'),
    (132, 137, 3, 'PIX', 105.60, '2026-11-01 00:04:00');

INSERT INTO HISTORICO_STATUS_PEDIDO (id_historico, id_pedido, id_funcionario_responsavel, id_funcionario_autorizador, status_anterior, status_novo, data_hora, motivo) VALUES
    (1, 1, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 18:00:00', NULL),
    (2, 1, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 18:05:00', NULL),
    (3, 1, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 18:20:00', NULL),
    (4, 1, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 18:30:00', NULL),
    (5, 2, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 18:08:00', NULL),
    (6, 2, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 18:13:00', NULL),
    (7, 2, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 18:28:00', NULL),
    (8, 2, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 18:38:00', NULL),
    (9, 3, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 18:17:00', NULL),
    (10, 3, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 18:22:00', NULL),
    (11, 3, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 18:37:00', NULL),
    (12, 3, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 19:05:00', NULL),
    (13, 4, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 18:25:00', NULL),
    (14, 4, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 18:30:00', NULL),
    (15, 4, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 18:45:00', NULL),
    (16, 4, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 18:55:00', NULL),
    (17, 5, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 18:34:00', NULL),
    (18, 5, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 18:39:00', NULL),
    (19, 5, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 18:54:00', NULL),
    (20, 5, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 19:04:00', NULL),
    (21, 6, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 18:43:00', NULL),
    (22, 6, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 18:48:00', NULL),
    (23, 6, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 19:03:00', NULL),
    (24, 6, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 19:31:00', NULL),
    (25, 7, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 18:51:00', NULL),
    (26, 7, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 18:56:00', NULL),
    (27, 7, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 19:11:00', NULL),
    (28, 7, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 19:21:00', NULL),
    (29, 8, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 19:00:00', NULL),
    (30, 8, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 19:05:00', NULL),
    (31, 8, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 19:20:00', NULL),
    (32, 8, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 19:30:00', NULL),
    (33, 9, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 19:09:00', NULL),
    (34, 9, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 19:14:00', NULL),
    (35, 9, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 19:29:00', NULL),
    (36, 9, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 19:57:00', NULL),
    (37, 10, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 19:17:00', NULL),
    (38, 10, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 19:22:00', NULL),
    (39, 10, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 19:37:00', NULL),
    (40, 10, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 19:47:00', NULL),
    (41, 11, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 19:26:00', NULL),
    (42, 11, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 19:31:00', NULL),
    (43, 11, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 19:46:00', NULL),
    (44, 12, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 19:35:00', NULL),
    (45, 12, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 19:40:00', NULL),
    (46, 12, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 19:55:00', NULL),
    (47, 12, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 20:23:00', NULL),
    (48, 13, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 19:43:00', NULL),
    (49, 13, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 19:48:00', NULL),
    (50, 14, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 19:52:00', NULL),
    (51, 14, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 19:57:00', NULL),
    (52, 14, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 20:12:00', NULL),
    (53, 14, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 20:22:00', NULL),
    (54, 15, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 20:00:00', NULL),
    (55, 15, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 20:05:00', NULL),
    (56, 15, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 20:20:00', NULL),
    (57, 15, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 20:48:00', NULL),
    (58, 16, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 20:09:00', NULL),
    (59, 16, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 20:14:00', NULL),
    (60, 16, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 20:29:00', NULL),
    (61, 16, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 20:39:00', NULL),
    (62, 17, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 20:18:00', NULL),
    (63, 18, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 20:26:00', NULL),
    (64, 18, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 20:31:00', NULL),
    (65, 18, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 20:46:00', NULL),
    (66, 18, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 21:14:00', NULL),
    (67, 19, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 20:35:00', NULL),
    (68, 19, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 20:40:00', NULL),
    (69, 19, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 20:55:00', NULL),
    (70, 19, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 21:05:00', NULL),
    (71, 20, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 20:44:00', NULL),
    (72, 20, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 20:49:00', NULL),
    (73, 20, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 21:04:00', NULL),
    (74, 20, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 21:14:00', NULL),
    (75, 21, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 20:52:00', NULL),
    (76, 21, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 20:57:00', NULL),
    (77, 21, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 21:12:00', NULL),
    (78, 21, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 21:40:00', NULL),
    (79, 22, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 21:01:00', NULL),
    (80, 22, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 21:06:00', NULL),
    (81, 22, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 21:21:00', NULL),
    (82, 23, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 21:10:00', NULL),
    (83, 23, 1, NULL, 'RECEBIDO', 'CANCELADO', '2026-10-28 21:13:00', 'Cliente solicitou cancelamento antes do inicio do preparo (exemplo ficticio)'),
    (84, 24, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 21:18:00', NULL),
    (85, 24, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 21:23:00', NULL),
    (86, 24, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 21:38:00', NULL),
    (87, 24, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 22:06:00', NULL),
    (88, 25, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 21:27:00', NULL),
    (89, 25, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 21:32:00', NULL),
    (90, 25, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 21:47:00', NULL),
    (91, 25, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 21:57:00', NULL),
    (92, 26, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 21:35:00', NULL),
    (93, 26, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 21:40:00', NULL),
    (94, 27, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 21:44:00', NULL),
    (95, 27, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 21:49:00', NULL),
    (96, 27, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 22:04:00', NULL),
    (97, 27, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 22:32:00', NULL),
    (98, 28, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 21:53:00', NULL),
    (99, 28, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 21:58:00', NULL),
    (100, 28, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 22:13:00', NULL),
    (101, 28, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 22:23:00', NULL),
    (102, 29, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 22:01:00', NULL),
    (103, 29, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 22:06:00', NULL),
    (104, 29, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 22:21:00', NULL),
    (105, 29, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 22:31:00', NULL),
    (106, 30, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 22:10:00', NULL),
    (107, 30, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 22:15:00', NULL),
    (108, 30, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 22:30:00', NULL),
    (109, 30, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 22:58:00', NULL),
    (110, 31, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 22:19:00', NULL),
    (111, 31, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 22:24:00', NULL),
    (112, 31, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 22:39:00', NULL),
    (113, 31, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 22:49:00', NULL),
    (114, 32, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 22:27:00', NULL),
    (115, 32, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 22:32:00', NULL),
    (116, 32, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 22:47:00', NULL),
    (117, 32, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-28 22:57:00', NULL),
    (118, 33, 1, NULL, NULL, 'RECEBIDO', '2026-10-28 22:36:00', NULL),
    (119, 33, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-28 22:41:00', NULL),
    (120, 33, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-28 22:56:00', NULL),
    (121, 34, 2, NULL, NULL, 'RECEBIDO', '2026-10-28 22:45:00', NULL),
    (122, 35, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 18:00:00', NULL),
    (123, 35, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 18:05:00', NULL),
    (124, 35, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 18:20:00', NULL),
    (125, 35, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 18:30:00', NULL),
    (126, 36, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 18:07:00', NULL),
    (127, 36, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 18:12:00', NULL),
    (128, 36, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 18:27:00', NULL),
    (129, 36, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 18:55:00', NULL),
    (130, 37, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 18:15:00', NULL),
    (131, 37, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 18:20:00', NULL),
    (132, 37, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 18:35:00', NULL),
    (133, 37, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 18:45:00', NULL),
    (134, 38, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 18:22:00', NULL),
    (135, 38, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 18:27:00', NULL),
    (136, 38, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 18:42:00', NULL),
    (137, 38, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 18:52:00', NULL),
    (138, 39, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 18:30:00', NULL),
    (139, 39, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 18:35:00', NULL),
    (140, 40, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 18:37:00', NULL),
    (141, 40, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 18:42:00', NULL),
    (142, 40, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 18:57:00', NULL),
    (143, 40, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 19:07:00', NULL),
    (144, 41, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 18:45:00', NULL),
    (145, 41, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 18:50:00', NULL),
    (146, 41, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 19:05:00', NULL),
    (147, 41, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 19:15:00', NULL),
    (148, 42, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 18:52:00', NULL),
    (149, 42, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 18:57:00', NULL),
    (150, 42, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 19:12:00', NULL),
    (151, 42, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 19:40:00', NULL),
    (152, 43, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 19:00:00', NULL),
    (153, 43, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 19:05:00', NULL),
    (154, 43, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 19:20:00', NULL),
    (155, 43, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 19:30:00', NULL),
    (156, 44, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 19:07:00', NULL),
    (157, 44, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 19:12:00', NULL),
    (158, 44, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 19:27:00', NULL),
    (159, 45, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 19:15:00', NULL),
    (160, 45, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 19:20:00', NULL),
    (161, 45, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 19:35:00', NULL),
    (162, 45, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 20:03:00', NULL),
    (163, 46, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 19:22:00', NULL),
    (164, 46, 2, NULL, 'RECEBIDO', 'CANCELADO', '2026-10-29 19:25:00', 'Cliente solicitou cancelamento antes do inicio do preparo (exemplo ficticio)'),
    (165, 47, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 19:30:00', NULL),
    (166, 47, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 19:35:00', NULL),
    (167, 47, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 19:50:00', NULL),
    (168, 47, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 20:00:00', NULL),
    (169, 48, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 19:37:00', NULL),
    (170, 48, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 19:42:00', NULL),
    (171, 48, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 19:57:00', NULL),
    (172, 48, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 20:25:00', NULL),
    (173, 49, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 19:45:00', NULL),
    (174, 49, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 19:50:00', NULL),
    (175, 49, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 20:05:00', NULL),
    (176, 49, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 20:15:00', NULL),
    (177, 50, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 19:52:00', NULL),
    (178, 50, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 19:57:00', NULL),
    (179, 50, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 20:12:00', NULL),
    (180, 50, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 20:22:00', NULL),
    (181, 51, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 20:00:00', NULL),
    (182, 52, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 20:07:00', NULL),
    (183, 52, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 20:12:00', NULL),
    (184, 53, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 20:15:00', NULL),
    (185, 53, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 20:20:00', NULL),
    (186, 53, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 20:35:00', NULL),
    (187, 53, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 20:45:00', NULL),
    (188, 54, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 20:22:00', NULL),
    (189, 54, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 20:27:00', NULL),
    (190, 54, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 20:42:00', NULL),
    (191, 54, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 21:10:00', NULL),
    (192, 55, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 20:30:00', NULL),
    (193, 55, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 20:35:00', NULL),
    (194, 55, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 20:50:00', NULL),
    (195, 56, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 20:37:00', NULL),
    (196, 56, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 20:42:00', NULL),
    (197, 56, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 20:57:00', NULL),
    (198, 56, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 21:07:00', NULL),
    (199, 57, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 20:45:00', NULL),
    (200, 57, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 20:50:00', NULL),
    (201, 57, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 21:05:00', NULL),
    (202, 57, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 21:33:00', NULL),
    (203, 58, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 20:52:00', NULL),
    (204, 58, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 20:57:00', NULL),
    (205, 58, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 21:12:00', NULL),
    (206, 58, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 21:22:00', NULL),
    (207, 59, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 21:00:00', NULL),
    (208, 59, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 21:05:00', NULL),
    (209, 59, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 21:20:00', NULL),
    (210, 59, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 21:30:00', NULL),
    (211, 60, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 21:07:00', NULL),
    (212, 60, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 21:12:00', NULL),
    (213, 60, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 21:27:00', NULL),
    (214, 60, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 21:55:00', NULL),
    (215, 61, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 21:15:00', NULL),
    (216, 61, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 21:20:00', NULL),
    (217, 61, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 21:35:00', NULL),
    (218, 61, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 21:45:00', NULL),
    (219, 62, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 21:22:00', NULL),
    (220, 62, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 21:27:00', NULL),
    (221, 62, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 21:42:00', NULL),
    (222, 62, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 21:52:00', NULL),
    (223, 63, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 21:30:00', NULL),
    (224, 63, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 21:35:00', NULL),
    (225, 63, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 21:50:00', NULL),
    (226, 63, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 22:18:00', NULL),
    (227, 64, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 21:37:00', NULL),
    (228, 64, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 21:42:00', NULL),
    (229, 64, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 21:57:00', NULL),
    (230, 64, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 22:07:00', NULL),
    (231, 65, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 21:45:00', NULL),
    (232, 65, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 21:50:00', NULL),
    (233, 66, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 21:52:00', NULL),
    (234, 66, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 21:57:00', NULL),
    (235, 66, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 22:12:00', NULL),
    (236, 67, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 22:00:00', NULL),
    (237, 67, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 22:05:00', NULL),
    (238, 67, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 22:20:00', NULL),
    (239, 67, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 22:30:00', NULL),
    (240, 68, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 22:07:00', NULL),
    (241, 69, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 22:15:00', NULL),
    (242, 69, 1, NULL, 'RECEBIDO', 'CANCELADO', '2026-10-29 22:18:00', 'Cliente solicitou cancelamento antes do inicio do preparo (exemplo ficticio)'),
    (243, 70, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 22:22:00', NULL),
    (244, 70, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 22:27:00', NULL),
    (245, 70, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 22:42:00', NULL),
    (246, 70, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 22:52:00', NULL),
    (247, 71, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 22:30:00', NULL),
    (248, 71, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 22:35:00', NULL),
    (249, 71, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 22:50:00', NULL),
    (250, 71, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 23:00:00', NULL),
    (251, 72, 2, NULL, NULL, 'RECEBIDO', '2026-10-29 22:37:00', NULL),
    (252, 72, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 22:42:00', NULL),
    (253, 72, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 22:57:00', NULL),
    (254, 72, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 23:25:00', NULL),
    (255, 73, 1, NULL, NULL, 'RECEBIDO', '2026-10-29 22:45:00', NULL),
    (256, 73, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-29 22:50:00', NULL),
    (257, 73, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-29 23:05:00', NULL),
    (258, 73, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-29 23:15:00', NULL),
    (259, 74, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 18:00:00', NULL),
    (260, 74, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:05:00', NULL),
    (261, 74, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 18:20:00', NULL),
    (262, 74, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 18:30:00', NULL),
    (263, 75, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 18:05:00', NULL),
    (264, 75, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:10:00', NULL),
    (265, 75, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 18:25:00', NULL),
    (266, 75, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 18:53:00', NULL),
    (267, 76, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 18:10:00', NULL),
    (268, 76, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:15:00', NULL),
    (269, 76, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 18:30:00', NULL),
    (270, 76, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 18:40:00', NULL),
    (271, 77, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 18:16:00', NULL),
    (272, 77, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:21:00', NULL),
    (273, 77, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 18:36:00', NULL),
    (274, 78, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 18:21:00', NULL),
    (275, 78, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:26:00', NULL),
    (276, 79, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 18:26:00', NULL),
    (277, 79, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:31:00', NULL),
    (278, 79, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 18:46:00', NULL),
    (279, 79, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 18:56:00', NULL),
    (280, 80, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 18:32:00', NULL),
    (281, 80, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:37:00', NULL),
    (282, 80, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 18:52:00', NULL),
    (283, 80, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 19:02:00', NULL),
    (284, 81, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 18:37:00', NULL),
    (285, 81, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:42:00', NULL),
    (286, 81, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 18:57:00', NULL),
    (287, 81, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 19:25:00', NULL),
    (288, 82, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 18:43:00', NULL),
    (289, 82, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:48:00', NULL),
    (290, 82, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 19:03:00', NULL),
    (291, 82, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 19:13:00', NULL),
    (292, 83, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 18:48:00', NULL),
    (293, 83, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:53:00', NULL),
    (294, 83, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 19:08:00', NULL),
    (295, 83, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 19:18:00', NULL),
    (296, 84, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 18:53:00', NULL),
    (297, 84, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 18:58:00', NULL),
    (298, 84, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 19:13:00', NULL),
    (299, 84, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 19:41:00', NULL),
    (300, 85, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 18:59:00', NULL),
    (301, 86, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 19:04:00', NULL),
    (302, 86, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 19:09:00', NULL),
    (303, 86, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 19:24:00', NULL),
    (304, 86, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 19:34:00', NULL),
    (305, 87, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 19:10:00', NULL),
    (306, 87, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 19:15:00', NULL),
    (307, 87, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 19:30:00', NULL),
    (308, 87, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 19:58:00', NULL),
    (309, 88, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 19:15:00', NULL),
    (310, 88, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 19:20:00', NULL),
    (311, 88, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 19:35:00', NULL),
    (312, 89, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 19:20:00', NULL),
    (313, 89, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 19:25:00', NULL),
    (314, 89, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 19:40:00', NULL),
    (315, 89, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 19:50:00', NULL),
    (316, 90, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 19:26:00', NULL),
    (317, 90, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 19:31:00', NULL),
    (318, 90, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 19:46:00', NULL),
    (319, 90, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 20:14:00', NULL),
    (320, 91, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 19:31:00', NULL),
    (321, 91, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 19:36:00', NULL),
    (322, 92, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 19:37:00', NULL),
    (323, 92, 2, NULL, 'RECEBIDO', 'CANCELADO', '2026-10-31 19:40:00', 'Cliente solicitou cancelamento antes do inicio do preparo (exemplo ficticio)'),
    (324, 93, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 19:42:00', NULL),
    (325, 93, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 19:47:00', NULL),
    (326, 93, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 20:02:00', NULL),
    (327, 93, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 20:30:00', NULL),
    (328, 94, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 19:47:00', NULL),
    (329, 94, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 19:52:00', NULL),
    (330, 94, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 20:07:00', NULL),
    (331, 94, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 20:17:00', NULL),
    (332, 95, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 19:53:00', NULL),
    (333, 95, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 19:58:00', NULL),
    (334, 95, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 20:13:00', NULL),
    (335, 95, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 20:23:00', NULL),
    (336, 96, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 19:58:00', NULL),
    (337, 96, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 20:03:00', NULL),
    (338, 96, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 20:18:00', NULL),
    (339, 96, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 20:46:00', NULL),
    (340, 97, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 20:03:00', NULL),
    (341, 97, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 20:08:00', NULL),
    (342, 97, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 20:23:00', NULL),
    (343, 97, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 20:33:00', NULL),
    (344, 98, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 20:09:00', NULL),
    (345, 98, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 20:14:00', NULL),
    (346, 98, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 20:29:00', NULL),
    (347, 98, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 20:39:00', NULL),
    (348, 99, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 20:14:00', NULL),
    (349, 99, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 20:19:00', NULL),
    (350, 99, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 20:34:00', NULL),
    (351, 100, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 20:20:00', NULL),
    (352, 100, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 20:25:00', NULL),
    (353, 100, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 20:40:00', NULL),
    (354, 100, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 20:50:00', NULL),
    (355, 101, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 20:25:00', NULL),
    (356, 101, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 20:30:00', NULL),
    (357, 101, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 20:45:00', NULL),
    (358, 101, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 20:55:00', NULL),
    (359, 102, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 20:30:00', NULL),
    (360, 103, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 20:36:00', NULL),
    (361, 103, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 20:41:00', NULL),
    (362, 103, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 20:56:00', NULL),
    (363, 103, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 21:06:00', NULL),
    (364, 104, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 20:41:00', NULL),
    (365, 104, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 20:46:00', NULL),
    (366, 105, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 20:47:00', NULL),
    (367, 105, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 20:52:00', NULL),
    (368, 105, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 21:07:00', NULL),
    (369, 105, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 21:35:00', NULL),
    (370, 106, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 20:52:00', NULL),
    (371, 106, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 20:57:00', NULL),
    (372, 106, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 21:12:00', NULL),
    (373, 106, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 21:22:00', NULL),
    (374, 107, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 20:57:00', NULL),
    (375, 107, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 21:02:00', NULL),
    (376, 107, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 21:17:00', NULL),
    (377, 107, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 21:27:00', NULL),
    (378, 108, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 21:03:00', NULL),
    (379, 108, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 21:08:00', NULL),
    (380, 108, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 21:23:00', NULL),
    (381, 108, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 21:51:00', NULL),
    (382, 109, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 21:08:00', NULL),
    (383, 109, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 21:13:00', NULL),
    (384, 109, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 21:28:00', NULL),
    (385, 109, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 21:38:00', NULL),
    (386, 110, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 21:14:00', NULL),
    (387, 110, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 21:19:00', NULL),
    (388, 110, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 21:34:00', NULL),
    (389, 111, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 21:19:00', NULL),
    (390, 111, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 21:24:00', NULL),
    (391, 111, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 21:39:00', NULL),
    (392, 111, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 22:07:00', NULL),
    (393, 112, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 21:24:00', NULL),
    (394, 112, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 21:29:00', NULL),
    (395, 112, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 21:44:00', NULL),
    (396, 112, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 21:54:00', NULL),
    (397, 113, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 21:30:00', NULL),
    (398, 113, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 21:35:00', NULL),
    (399, 113, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 21:50:00', NULL),
    (400, 113, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 22:00:00', NULL),
    (401, 114, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 21:35:00', NULL),
    (402, 114, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 21:40:00', NULL),
    (403, 114, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 21:55:00', NULL),
    (404, 114, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 22:23:00', NULL),
    (405, 115, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 21:41:00', NULL),
    (406, 115, 1, NULL, 'RECEBIDO', 'CANCELADO', '2026-10-31 21:44:00', 'Cliente solicitou cancelamento antes do inicio do preparo (exemplo ficticio)'),
    (407, 116, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 21:46:00', NULL),
    (408, 116, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 21:51:00', NULL),
    (409, 116, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 22:06:00', NULL),
    (410, 116, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 22:16:00', NULL),
    (411, 117, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 21:51:00', NULL),
    (412, 117, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 21:56:00', NULL),
    (413, 118, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 21:57:00', NULL),
    (414, 118, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 22:02:00', NULL),
    (415, 118, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 22:17:00', NULL),
    (416, 118, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 22:27:00', NULL),
    (417, 119, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 22:02:00', NULL),
    (418, 120, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 22:07:00', NULL),
    (419, 120, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 22:12:00', NULL),
    (420, 120, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 22:27:00', NULL),
    (421, 120, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 22:55:00', NULL),
    (422, 121, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 22:13:00', NULL),
    (423, 121, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 22:18:00', NULL),
    (424, 121, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 22:33:00', NULL),
    (425, 122, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 22:18:00', NULL),
    (426, 122, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 22:23:00', NULL),
    (427, 122, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 22:38:00', NULL),
    (428, 122, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 22:48:00', NULL),
    (429, 123, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 22:24:00', NULL),
    (430, 123, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 22:29:00', NULL),
    (431, 123, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 22:44:00', NULL),
    (432, 123, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 23:12:00', NULL),
    (433, 124, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 22:29:00', NULL),
    (434, 124, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 22:34:00', NULL),
    (435, 124, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 22:49:00', NULL),
    (436, 124, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 22:59:00', NULL),
    (437, 125, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 22:34:00', NULL),
    (438, 125, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 22:39:00', NULL),
    (439, 125, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 22:54:00', NULL),
    (440, 125, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 23:04:00', NULL),
    (441, 126, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 22:40:00', NULL),
    (442, 126, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 22:45:00', NULL),
    (443, 126, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 23:00:00', NULL),
    (444, 126, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 23:28:00', NULL),
    (445, 127, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 22:45:00', NULL),
    (446, 127, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 22:50:00', NULL),
    (447, 127, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 23:05:00', NULL),
    (448, 127, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 23:15:00', NULL),
    (449, 128, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 22:51:00', NULL),
    (450, 128, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 22:56:00', NULL),
    (451, 128, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 23:11:00', NULL),
    (452, 128, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 23:21:00', NULL),
    (453, 129, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 22:56:00', NULL),
    (454, 129, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 23:01:00', NULL),
    (455, 129, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 23:16:00', NULL),
    (456, 129, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 23:44:00', NULL),
    (457, 130, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 23:01:00', NULL),
    (458, 130, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 23:06:00', NULL),
    (459, 131, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 23:07:00', NULL),
    (460, 131, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 23:12:00', NULL),
    (461, 131, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 23:27:00', NULL),
    (462, 131, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 23:37:00', NULL),
    (463, 132, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 23:12:00', NULL),
    (464, 132, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 23:17:00', NULL),
    (465, 132, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 23:32:00', NULL),
    (466, 133, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 23:18:00', NULL),
    (467, 133, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 23:23:00', NULL),
    (468, 133, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 23:38:00', NULL),
    (469, 133, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 23:48:00', NULL),
    (470, 134, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 23:23:00', NULL),
    (471, 134, 4, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 23:28:00', NULL),
    (472, 134, 4, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 23:43:00', NULL),
    (473, 134, 2, NULL, 'PRONTO', 'FINALIZADO', '2026-10-31 23:53:00', NULL),
    (474, 135, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 23:28:00', NULL),
    (475, 135, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 23:33:00', NULL),
    (476, 135, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 23:48:00', NULL),
    (477, 135, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-11-01 00:16:00', NULL),
    (478, 136, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 23:34:00', NULL),
    (479, 137, 1, NULL, NULL, 'RECEBIDO', '2026-10-31 23:39:00', NULL),
    (480, 137, 3, NULL, 'RECEBIDO', 'EM_PREPARACAO', '2026-10-31 23:44:00', NULL),
    (481, 137, 3, NULL, 'EM_PREPARACAO', 'PRONTO', '2026-10-31 23:59:00', NULL),
    (482, 137, 1, NULL, 'PRONTO', 'FINALIZADO', '2026-11-01 00:09:00', NULL),
    (483, 138, 2, NULL, NULL, 'RECEBIDO', '2026-10-31 23:45:00', NULL),
    (484, 138, 2, NULL, 'RECEBIDO', 'CANCELADO', '2026-10-31 23:48:00', 'Cliente solicitou cancelamento antes do inicio do preparo (exemplo ficticio)');

INSERT INTO CONFERENCIA_CAIXA (id_conferencia, id_fechamento, forma_pagamento, valor_contado) VALUES
    (1, 1, 'PIX', 770.90),
    (2, 1, 'DINHEIRO', 538.50),
    (3, 1, 'CARTAO_DEBITO', 447.80),
    (4, 1, 'CARTAO_CREDITO', 517.60),
    (5, 2, 'PIX', 691.00),
    (6, 2, 'DINHEIRO', 451.00),
    (7, 2, 'CARTAO_DEBITO', 820.80),
    (8, 2, 'CARTAO_CREDITO', 618.20),
    (9, 3, 'PIX', 1221.60),
    (10, 3, 'DINHEIRO', 1099.90),
    (11, 3, 'CARTAO_DEBITO', 1259.70),
    (12, 3, 'CARTAO_CREDITO', 898.70);

INSERT INTO CLIENTE (id_cliente, nome, telefone) VALUES
    (9999, 'Cliente temporario para demonstracao de DELETE', NULL);

-- ============================================================================
-- 4. SELECT COM JOIN — CONSULTAS DE RELACIONAMENTO
-- ============================================================================
-- Lista pedidos, clientes, funcionários, itens, produtos e pagamentos.
SELECT p.id_pedido, p.data_hora, c.nome AS cliente, p.tipo_pedido, p.status,
       f.nome AS funcionario_registro, pr.nome AS produto,
       ip.quantidade, ip.preco_unitario, pg.forma_pagamento, pg.valor AS valor_pago
FROM PEDIDO p
JOIN CLIENTE c ON c.id_cliente = p.id_cliente
JOIN FUNCIONARIO f ON f.id_funcionario = p.id_funcionario_registro
JOIN ITEM_PEDIDO ip ON ip.id_pedido = p.id_pedido
JOIN PRODUTO pr ON pr.id_produto = ip.id_produto
LEFT JOIN PAGAMENTO pg ON pg.id_pedido = p.id_pedido
ORDER BY p.data_hora, p.id_pedido
LIMIT 20;

-- Compras, fornecedores, ingredientes, quantidades e custos.
SELECT co.id_compra, fo.nome AS fornecedor, co.data_pedido, co.status_compra,
       i.nome AS ingrediente, ic.quantidade_solicitada, ic.quantidade_recebida, ic.custo_unitario
FROM COMPRA co
JOIN FORNECEDOR fo ON fo.id_fornecedor = co.id_fornecedor
JOIN ITEM_COMPRA ic ON ic.id_compra = co.id_compra
JOIN INGREDIENTE i ON i.id_ingrediente = ic.id_ingrediente
ORDER BY co.data_pedido, co.id_compra;

-- ============================================================================
-- 5. UPDATE — ATUALIZAÇÃO DE REGISTROS
-- ============================================================================
-- As compras só passam de PENDENTE para RECEBIDA depois que os itens foram
-- cadastrados; o trigger confere nota, data, responsável e quantidade recebida.
UPDATE COMPRA SET status_compra = 'RECEBIDA' WHERE id_compra BETWEEN 1 AND 5;
SELECT id_compra, status_compra, resultado_conferencia FROM COMPRA ORDER BY id_compra;
-- Atualiza o preço atual do Colossal Burger. Os preços históricos em ITEM_PEDIDO
-- permanecem inalterados (RN07), permitindo comparar preço atual e preço praticado.
UPDATE PRODUTO SET preco = 31.90 WHERE id_produto = 1;
SELECT id_produto, nome, preco AS preco_atual FROM PRODUTO WHERE id_produto = 1;
SELECT id_pedido, preco_unitario AS preco_historico
FROM ITEM_PEDIDO WHERE id_produto = 1 ORDER BY id_pedido LIMIT 10;

-- ============================================================================
-- 6. DELETE — EXCLUSÃO CONTROLADA DE REGISTRO SEM DEPENDÊNCIAS
-- ============================================================================
-- O cliente temporário 9999 foi inserido apenas para demonstrar DELETE.
-- Nenhum pedido referencia esse cliente; dados operacionais reais não são apagados.
DELETE FROM CLIENTE WHERE id_cliente = 9999;
SELECT COUNT(*) AS cliente_temporario_restante FROM CLIENTE WHERE id_cliente = 9999;

-- ============================================================================
-- 7. CONSULTAS GERENCIAIS (G01...G08)
-- ============================================================================

-- G01 — Qual é o tempo médio de preparo e de deslocamento dos deliveries concluídos?
-- Atende: P1 (acompanhar tempo de expedição/preparo).
SELECT DATE(p.data_hora) AS dia,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, h.inicio_recebido, h.hora_pronto)), 2) AS minutos_medios_ate_pronto,
       ROUND(AVG(CASE WHEN e.data_hora_saida IS NOT NULL AND e.data_hora_entrega IS NOT NULL
                  THEN TIMESTAMPDIFF(MINUTE, e.data_hora_saida, e.data_hora_entrega) END), 2) AS minutos_medios_em_rota
FROM PEDIDO p
JOIN (
    SELECT id_pedido,
           MIN(CASE WHEN status_novo = 'RECEBIDO' THEN data_hora END) AS inicio_recebido,
           MIN(CASE WHEN status_novo = 'PRONTO' THEN data_hora END) AS hora_pronto
    FROM HISTORICO_STATUS_PEDIDO GROUP BY id_pedido
) h ON h.id_pedido = p.id_pedido
LEFT JOIN ENTREGA e ON e.id_pedido = p.id_pedido
WHERE p.tipo_pedido = 'DELIVERY' AND p.status = 'FINALIZADO'
  AND h.inicio_recebido IS NOT NULL AND h.hora_pronto IS NOT NULL
GROUP BY DATE(p.data_hora)
ORDER BY dia;

-- G02 — Qual foi o preço médio efetivamente praticado por produto?
-- Atende: P2 (acompanhar a precificação histórica dos produtos).
SELECT pr.id_produto, pr.nome, pr.preco AS preco_atual,
       ROUND(AVG(ip.preco_unitario), 2) AS preco_medio_praticado,
       MIN(ip.preco_unitario) AS menor_preco_praticado,
       MAX(ip.preco_unitario) AS maior_preco_praticado,
       COUNT(*) AS linhas_vendidas
FROM ITEM_PEDIDO ip JOIN PRODUTO pr ON pr.id_produto = ip.id_produto
JOIN PEDIDO pe ON pe.id_pedido = ip.id_pedido
WHERE pe.status <> 'CANCELADO'
GROUP BY pr.id_produto, pr.nome ORDER BY pr.nome;

-- G03 — Como variou o custo médio de aquisição dos ingredientes por mês?
-- Atende: P2 (comparar custo de ingredientes ao longo do tempo).
SELECT i.nome AS ingrediente, DATE_FORMAT(co.data_recebimento, '%Y-%m') AS mes,
       ROUND(SUM(ic.quantidade_recebida * ic.custo_unitario) / NULLIF(SUM(ic.quantidade_recebida), 0), 4) AS custo_unitario_medio_ponderado,
       MIN(ic.custo_unitario) AS menor_custo, MAX(ic.custo_unitario) AS maior_custo
FROM ITEM_COMPRA ic
JOIN COMPRA co ON co.id_compra = ic.id_compra
JOIN INGREDIENTE i ON i.id_ingrediente = ic.id_ingrediente
WHERE co.status_compra = 'RECEBIDA'
GROUP BY i.nome, DATE_FORMAT(co.data_recebimento, '%Y-%m')
ORDER BY mes, ingrediente;

-- G04 — Quais ingredientes estão abaixo do estoque mínimo?
-- Atende: P3 (acompanhar níveis de estoque e necessidade de reposição).
SELECT i.id_ingrediente, i.nome, i.unidade_medida, i.estoque_minimo,
       COALESCE(SUM(CASE
           WHEN m.tipo_movimentacao IN ('ENTRADA', 'AJUSTE_ENTRADA') THEN m.quantidade
           WHEN m.tipo_movimentacao IN ('SAIDA', 'AJUSTE_SAIDA') THEN -m.quantidade
           ELSE 0 END), 0) AS saldo_atual
FROM INGREDIENTE i LEFT JOIN MOVIMENTACAO_ESTOQUE m ON m.id_ingrediente = i.id_ingrediente
GROUP BY i.id_ingrediente, i.nome, i.unidade_medida, i.estoque_minimo
HAVING i.estoque_minimo IS NOT NULL AND saldo_atual < i.estoque_minimo
ORDER BY saldo_atual;

-- G05 — Quantos pedidos foram cancelados e qual o percentual por dia?
-- Atende: P4 (acompanhar cancelamentos).
SELECT DATE(data_hora) AS dia, COUNT(*) AS total_pedidos,
       SUM(status = 'CANCELADO') AS pedidos_cancelados,
       ROUND(100 * SUM(status = 'CANCELADO') / NULLIF(COUNT(*),0), 2) AS percentual_cancelado
FROM PEDIDO GROUP BY DATE(data_hora) ORDER BY dia;

-- G06 — Qual a diferença entre o valor esperado e o valor contado no fechamento?
-- Atende: P5 (conferência diária do caixa).
SELECT fc.id_fechamento, DATE(fc.data_hora_fim) AS dia, pg.forma_pagamento,
       pg.valor_esperado, cc.valor_contado,
       ROUND(cc.valor_contado - pg.valor_esperado, 2) AS diferenca,
       CASE WHEN cc.id_conferencia IS NULL THEN 'SEM CONFERENCIA'
            WHEN ABS(cc.valor_contado - pg.valor_esperado) > 0.01 THEN 'DIVERGENCIA'
            ELSE 'CONFERIDO' END AS situacao
FROM (
    SELECT id_fechamento, forma_pagamento, SUM(valor) AS valor_esperado
    FROM PAGAMENTO WHERE id_fechamento IS NOT NULL
    GROUP BY id_fechamento, forma_pagamento
) pg
JOIN FECHAMENTO_CAIXA fc ON fc.id_fechamento = pg.id_fechamento
LEFT JOIN CONFERENCIA_CAIXA cc
  ON cc.id_fechamento = pg.id_fechamento AND cc.forma_pagamento = pg.forma_pagamento
ORDER BY fc.data_hora_fim, pg.forma_pagamento;

-- G07 — Quanto foi comprado de cada fornecedor e ingrediente?
-- Atende: P6 (acompanhar compras e fornecedores).
SELECT fo.nome AS fornecedor, i.nome AS ingrediente,
       SUM(ic.quantidade_recebida) AS quantidade_recebida,
       ROUND(SUM(ic.quantidade_recebida * ic.custo_unitario), 2) AS custo_total
FROM COMPRA co JOIN FORNECEDOR fo ON fo.id_fornecedor = co.id_fornecedor
JOIN ITEM_COMPRA ic ON ic.id_compra = co.id_compra
JOIN INGREDIENTE i ON i.id_ingrediente = ic.id_ingrediente
WHERE co.status_compra = 'RECEBIDA'
GROUP BY fo.nome, i.nome ORDER BY fo.nome, i.nome;

-- G08 — Quantas entregas e quanto foi cobrado por área/bairro?
-- Atende: P7 (acompanhar delivery e taxas por área).
SELECT a.bairro, COUNT(e.id_entrega) AS total_entregas,
       ROUND(SUM(e.taxa_entrega_aplicada), 2) AS total_taxas_aplicadas,
       ROUND(AVG(e.taxa_entrega_aplicada), 2) AS taxa_media
FROM AREA_ENTREGA a LEFT JOIN ENTREGA e ON e.id_area_entrega = a.id_area_entrega
GROUP BY a.id_area_entrega, a.bairro ORDER BY total_entregas DESC;

-- ============================================================================
-- 8. CONSULTAS DE AUDITORIA (A01...A12)
-- ============================================================================

-- A01 — Existe pedido registrado sem nenhum item?
-- Verifica: RN02 (todo pedido deve conter pelo menos um produto).
SELECT p.id_pedido, p.data_hora, p.status
FROM PEDIDO p LEFT JOIN ITEM_PEDIDO ip ON ip.id_pedido = p.id_pedido
WHERE ip.id_item_pedido IS NULL;

-- A02 — Existe pagamento diferente do total dos itens mais a taxa de entrega?
-- Verifica: RN08 e RN19 (pagamento igual ao total do pedido, incluindo taxa de delivery).
SELECT p.id_pedido, pg.valor AS valor_pago,
       COALESCE(it.total_itens,0) + COALESCE(e.taxa_entrega_aplicada,0) AS total_calculado
FROM PAGAMENTO pg JOIN PEDIDO p ON p.id_pedido = pg.id_pedido
LEFT JOIN (SELECT id_pedido, SUM(quantidade * preco_unitario) AS total_itens
           FROM ITEM_PEDIDO GROUP BY id_pedido) it ON it.id_pedido = p.id_pedido
LEFT JOIN ENTREGA e ON e.id_pedido = p.id_pedido
WHERE ABS(pg.valor - (COALESCE(it.total_itens,0) + COALESCE(e.taxa_entrega_aplicada,0))) > 0.01;

-- A03 — Há entrega para retirada ou pedido delivery ativo sem entrega?
-- Verifica: RN10 e RN11 (retirada sem entrega; delivery ativo com uma entrega).
SELECT p.id_pedido, p.tipo_pedido, p.status, e.id_entrega
FROM PEDIDO p LEFT JOIN ENTREGA e ON e.id_pedido = p.id_pedido
WHERE (p.tipo_pedido = 'RETIRADA' AND e.id_entrega IS NOT NULL)
   OR (p.tipo_pedido = 'DELIVERY' AND p.status <> 'CANCELADO' AND e.id_entrega IS NULL);

-- A04 — Existe entrega sem motoboy responsável?
-- Verifica: RN12 (toda entrega possui um motoboy). A FK e NOT NULL já impedem novos casos.
SELECT id_entrega, id_pedido FROM ENTREGA WHERE id_motoboy IS NULL;

-- A05 — Existe saldo negativo em algum ingrediente?
-- Verifica: RN22 (saldo de estoque apurado pelas movimentações; saldo negativo é inconsistência).
SELECT i.id_ingrediente, i.nome,
       COALESCE(SUM(CASE WHEN m.tipo_movimentacao IN ('ENTRADA','AJUSTE_ENTRADA') THEN m.quantidade
                         WHEN m.tipo_movimentacao IN ('SAIDA','AJUSTE_SAIDA') THEN -m.quantidade ELSE 0 END),0) AS saldo
FROM INGREDIENTE i LEFT JOIN MOVIMENTACAO_ESTOQUE m ON m.id_ingrediente = i.id_ingrediente
GROUP BY i.id_ingrediente, i.nome HAVING saldo < 0;

-- A06 — Existe entrada de compra associada ao ingrediente errado ou com tipo diferente de ENTRADA?
-- Verifica: RN23 (entrada de compra vinculada ao mesmo ingrediente e limitada à quantidade recebida).
SELECT m.id_movimentacao, m.id_ingrediente, ic.id_ingrediente AS ingrediente_item_compra, m.tipo_movimentacao
FROM MOVIMENTACAO_ESTOQUE m JOIN ITEM_COMPRA ic ON ic.id_item_compra = m.id_item_compra
WHERE m.id_ingrediente <> ic.id_ingrediente OR m.tipo_movimentacao <> 'ENTRADA';

-- A07 — Há cancelamento sem justificativa ou sem autorização obrigatória?
-- Verifica: RN17 (cancelamento e autorização após início do preparo).
SELECT h.id_historico, h.id_pedido, h.status_anterior, h.motivo, h.id_funcionario_autorizador
FROM HISTORICO_STATUS_PEDIDO h
WHERE h.status_novo = 'CANCELADO'
  AND (h.motivo IS NULL OR TRIM(h.motivo) = ''
       OR (h.status_anterior IN ('EM_PREPARACAO','PRONTO') AND h.id_funcionario_autorizador IS NULL));

-- A08 — Existem formas de pagamento sem conferência ou com valor divergente?
-- Verifica: RN18 (total por forma de pagamento deve bater com o fechamento).
SELECT fc.id_fechamento, pg.forma_pagamento, cc.valor_contado, pg.valor_esperado,
       ROUND(cc.valor_contado - pg.valor_esperado, 2) AS diferenca,
       CASE WHEN cc.id_conferencia IS NULL THEN 'SEM CONFERENCIA' ELSE 'DIVERGENCIA' END AS ocorrencia
FROM (
    SELECT id_fechamento, forma_pagamento, SUM(valor) AS valor_esperado
    FROM PAGAMENTO WHERE id_fechamento IS NOT NULL
    GROUP BY id_fechamento, forma_pagamento
) pg
JOIN FECHAMENTO_CAIXA fc ON fc.id_fechamento = pg.id_fechamento
LEFT JOIN CONFERENCIA_CAIXA cc
  ON cc.id_fechamento = pg.id_fechamento AND cc.forma_pagamento = pg.forma_pagamento
WHERE cc.id_conferencia IS NULL OR ABS(cc.valor_contado - pg.valor_esperado) > 0.01
UNION ALL
SELECT fc.id_fechamento, cc.forma_pagamento, cc.valor_contado, 0.00 AS valor_esperado,
       cc.valor_contado AS diferenca, 'CONFERENCIA SEM PAGAMENTO' AS ocorrencia
FROM CONFERENCIA_CAIXA cc
JOIN FECHAMENTO_CAIXA fc ON fc.id_fechamento = cc.id_fechamento
LEFT JOIN PAGAMENTO pg ON pg.id_fechamento = cc.id_fechamento AND pg.forma_pagamento = cc.forma_pagamento
WHERE pg.id_pagamento IS NULL AND cc.valor_contado <> 0;

-- A09 — O status atual do pedido corresponde ao último evento do histórico?
-- Verifica: RN24 (o status atual deve corresponder ao último evento do histórico).
SELECT p.id_pedido, p.status AS status_atual, h.status_novo AS ultimo_status_historico
FROM PEDIDO p
JOIN HISTORICO_STATUS_PEDIDO h ON h.id_historico = (
    SELECT h2.id_historico FROM HISTORICO_STATUS_PEDIDO h2
    WHERE h2.id_pedido = p.id_pedido ORDER BY h2.data_hora DESC, h2.id_historico DESC LIMIT 1
)
WHERE p.status <> h.status_novo;

-- A10 — Há compra marcada como recebida sem nota fiscal, data, conferente ou item recebido?
-- Verifica: RN20/RN21 (recebimento conferido com nota fiscal e item recebido).
SELECT co.id_compra, co.numero_nota_fiscal, co.data_recebimento, co.id_funcionario_conferente
FROM COMPRA co
WHERE co.status_compra = 'RECEBIDA'
  AND (co.numero_nota_fiscal IS NULL OR co.data_recebimento IS NULL OR co.id_funcionario_conferente IS NULL
       OR co.resultado_conferencia = 'PENDENTE'
       OR NOT EXISTS (SELECT 1 FROM ITEM_COMPRA ic WHERE ic.id_compra = co.id_compra AND ic.quantidade_recebida > 0));

-- A11 — Existe fechamento sem nenhuma conferência registrada?
-- Verifica: RN18 (todo fechamento deve possuir valores conferidos por forma de pagamento usada).
SELECT fc.id_fechamento, fc.data_hora_fim
FROM FECHAMENTO_CAIXA fc LEFT JOIN CONFERENCIA_CAIXA cc ON cc.id_fechamento = fc.id_fechamento
WHERE cc.id_conferencia IS NULL;

-- A12 — Há pedido delivery finalizado sem entrega concluída?
-- Verifica: RN14 (delivery só é finalizado após a entrega).
SELECT p.id_pedido, p.status AS status_pedido, e.status AS status_entrega
FROM PEDIDO p LEFT JOIN ENTREGA e ON e.id_pedido = p.id_pedido
WHERE p.tipo_pedido = 'DELIVERY' AND p.status = 'FINALIZADO'
  AND (e.id_entrega IS NULL OR e.status <> 'ENTREGUE');

-- FIM DO SCRIPT