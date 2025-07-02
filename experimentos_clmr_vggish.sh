#!/bin/bash

CONFIG_DIR="configs"
REPETITIONS=10

# Agora coloque apenas o NOME BASE do arquivo de configuração (sem .yml)
declare -A CONFIGS
CONFIGS["clmr"]="clmr_config"
CONFIGS["vggish"]="vggish_config"

for FEATURE in "${!CONFIGS[@]}"; do
    CONFIG_NAME="${CONFIGS[$FEATURE]}"   # já é só o nome base

    BASE_LOG_DIR="results_${FEATURE}"

    echo "=========================================="
    echo ">>> Iniciando execuções para FEATURE=${FEATURE}"
    echo "     Usando config: $CONFIG_NAME"
    echo "=========================================="

    for RUN_ID in $(seq 1 $REPETITIONS); do
        LOG_DIR="$BASE_LOG_DIR/run_${RUN_ID}"
        mkdir -p "$LOG_DIR"

        # Checkpoint: pula se já rodou
        CHECKPOINT_FILE="$LOG_DIR/run_done.flag"
        if [ -f "$CHECKPOINT_FILE" ]; then
            echo "Checkpoint encontrado para $FEATURE run $RUN_ID. Pulando esta execução."
            continue
        fi

        GERAL_LOG="$LOG_DIR/execucao_geral.log"
        echo "Iniciando execução $RUN_ID para feature $FEATURE" > "$GERAL_LOG"
        echo "Data: $(date)" >> "$GERAL_LOG"
        echo "----------------------------------------" >> "$GERAL_LOG"

        SECONDS=0

        echo ">>> [${FEATURE}][${RUN_ID}] Extract..."
        echo ">>> [${FEATURE}][${RUN_ID}] Extract..." | tee -a "$GERAL_LOG"
        python run.py extract -c "$CONFIG_NAME" | tee "$LOG_DIR/extract.log" | tee -a "$GERAL_LOG"
        if [ "${PIPESTATUS[0]}" -ne 0 ]; then
            echo "Erro na etapa extract para $FEATURE, run $RUN_ID. Abortando." | tee -a "$GERAL_LOG"
            exit 1
        fi

        echo ">>> [${FEATURE}][${RUN_ID}] Train..."
        echo ">>> [${FEATURE}][${RUN_ID}] Train..." | tee -a "$GERAL_LOG"
        python run.py train -c "$CONFIG_NAME" | tee "$LOG_DIR/train.log" | tee -a "$GERAL_LOG"
        if [ "${PIPESTATUS[0]}" -ne 0 ]; then
            echo "Erro na etapa train para $FEATURE, run $RUN_ID. Abortando." | tee -a "$GERAL_LOG"
            exit 1
        fi

        echo ">>> [${FEATURE}][${RUN_ID}] Evaluate..."
        echo ">>> [${FEATURE}][${RUN_ID}] Evaluate..." | tee -a "$GERAL_LOG"
        python run.py evaluate -c "$CONFIG_NAME" | tee "$LOG_DIR/evaluate.log" | tee -a "$GERAL_LOG"
        if [ "${PIPESTATUS[0]}" -ne 0 ]; then
            echo "Erro na etapa evaluate para $FEATURE, run $RUN_ID. Abortando." | tee -a "$GERAL_LOG"
            exit 1
        fi

        TEMPO_TOTAL=$SECONDS
        echo "Tempo de execução total (segundos): $TEMPO_TOTAL" | tee -a "$GERAL_LOG"
        echo "Tempo de execução total formatado: $(date -ud "@$TEMPO_TOTAL" +'%H:%M:%S')" | tee -a "$GERAL_LOG"

        echo ">>> Execução ${RUN_ID} para $FEATURE concluída!" | tee -a "$GERAL_LOG"
        echo "----------------------------------------" | tee -a "$GERAL_LOG"

        # Marca como concluído
        touch "$CHECKPOINT_FILE"
    done

    echo ">>> Todas as execuções para $FEATURE concluídas."
    echo "=========================================="
done

echo "Todos os experimentos para todas as features foram executados!"

