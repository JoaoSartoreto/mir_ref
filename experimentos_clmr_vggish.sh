#!/bin/bash

CONFIG_DIR="configs"
REPETITIONS=10

declare -A CONFIGS
CONFIGS["clmr"]="clmr_config"
CONFIGS["vggish"]="vggish_config"

for FEATURE in "${!CONFIGS[@]}"; do
    CONFIG_NAME="${CONFIGS[$FEATURE]}"
    BASE_LOG_DIR="results_${FEATURE}"

    echo "=========================================="
    echo ">>> Iniciando execuções para FEATURE=${FEATURE}"
    echo "     Usando config: $CONFIG_NAME"
    echo "=========================================="

    # Extract apenas uma vez
    EXTRACT_CHECKPOINT="$BASE_LOG_DIR/extract_done.flag"
    if [ ! -f "$EXTRACT_CHECKPOINT" ]; then
        mkdir -p "$BASE_LOG_DIR"
        GERAL_LOG="$BASE_LOG_DIR/extract_geral.log"

        SECONDS=0
        echo ">>> [${FEATURE}] Extract..." | tee -a "$GERAL_LOG"
        python run.py extract -c "$CONFIG_NAME" | tee "$BASE_LOG_DIR/extract.log" | tee -a "$GERAL_LOG"
        if [ "${PIPESTATUS[0]}" -ne 0 ]; then
            echo "Erro na etapa extract para $FEATURE. Abortando." | tee -a "$GERAL_LOG"
            exit 1
        fi
        TEMPO_TOTAL=$SECONDS
        echo "Tempo de execução total (segundos): $TEMPO_TOTAL" | tee -a "$GERAL_LOG"
        echo "Tempo de execução total formatado: $(date -ud "@$TEMPO_TOTAL" +'%H:%M:%S')" | tee -a "$GERAL_LOG"
        touch "$EXTRACT_CHECKPOINT"
    else
        echo "Checkpoint de extract encontrado para $FEATURE. Pulando extração."
    fi

    # 10 execuções de treino+avaliação, mas só salva log da avaliação
    for RUN_ID in $(seq 1 $REPETITIONS); do
        LOG_DIR="$BASE_LOG_DIR/run_${RUN_ID}"
        mkdir -p "$LOG_DIR"

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

        # Não salva o train.log, só executa
        echo ">>> [${FEATURE}][${RUN_ID}] Train..."
        echo ">>> [${FEATURE}][${RUN_ID}] Train..." | tee -a "$GERAL_LOG"
        python run.py train -c "$CONFIG_NAME"
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

        touch "$CHECKPOINT_FILE"
    done

    echo ">>> Todas as execuções para $FEATURE concluídas."
    echo "=========================================="
done

echo "Todos os experimentos para todas as features foram executados!"
