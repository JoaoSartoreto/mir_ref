#!/bin/bash

CONFIG_DIR="configs"
BASE_LOG_DIR="results_mfcc_evaluate"
REPETITIONS=5

# Lista de valores para MAX_FRAMES
FRAME_VALUES=(5 7 10 15 20 30 50 100 250 500)

for MAX_FRAMES in "${FRAME_VALUES[@]}"; do
    export MAX_FRAMES

    echo "=========================================="
    echo ">>> Iniciando execuções para MAX_FRAMES=$MAX_FRAMES"
    echo "=========================================="

    for RUN_ID in $(seq 1 $REPETITIONS); do
        LOG_DIR="$BASE_LOG_DIR/frames_${MAX_FRAMES}/run_${RUN_ID}"
        DONE_FILE="$LOG_DIR/done.log"

        echo ">>> Repetição $RUN_ID de $REPETITIONS"
        mkdir -p "$LOG_DIR"
        touch "$DONE_FILE"

        GERAL_LOG="$LOG_DIR/execucao_geral.log"
        echo "Iniciando execução $RUN_ID com MAX_FRAMES=$MAX_FRAMES" >> "$GERAL_LOG"
        echo "Data: $(date)" >> "$GERAL_LOG"
        echo "----------------------------------------" >> "$GERAL_LOG"

        for config_file in ${CONFIG_DIR}/*.yml; do
            config_name=$(basename "$config_file" .yml)

            if grep -q "$config_name" "$DONE_FILE"; then
                echo ">>> Pulando (já concluído): $config_name"
                continue
            fi

            echo ">>> Iniciando: $config_name"
            echo ">>> Iniciando: $config_name" >> "$GERAL_LOG"

            start_time=$(date +%s)

            export MFCC_CONFIG_NAME="$config_name"

            python run.py extract -c "$config_name"
            if [ $? -ne 0 ]; then
                echo "Erro na etapa extract para $config_name. Abortando." | tee -a "$GERAL_LOG"
                exit 1
            fi

            python run.py train -c "$config_name"
            if [ $? -ne 0 ]; then
                echo "Erro na etapa train para $config_name. Abortando." | tee -a "$GERAL_LOG"
                exit 1
            fi

            LOG_FILE="$LOG_DIR/${config_name}_evaluate.log"
            echo "=== Configuração Utilizada ===" | tee "$LOG_FILE" >> "$GERAL_LOG"
            cat "$config_file" | tee -a "$LOG_FILE" >> "$GERAL_LOG"
            echo -e "\n=== Resultado da Avaliação ===" | tee -a "$LOG_FILE" >> "$GERAL_LOG"

            python run.py evaluate -c "$config_name" | tee -a "$LOG_FILE" >> "$GERAL_LOG"
            if [ $? -ne 0 ]; then
                echo "Erro na etapa evaluate para $config_name. Abortando." | tee -a "$GERAL_LOG"
                exit 1
            fi

            end_time=$(date +%s)
            duration=$((end_time - start_time))

            hours=$((duration / 3600))
            minutes=$(((duration % 3600) / 60))
            seconds=$((duration % 60))

            if [ $hours -gt 0 ]; then
                formatted_time="${hours} horas, ${minutes} minutos e ${seconds} segundos"
            elif [ $minutes -gt 0 ]; then
                formatted_time="${minutes} minutos e ${seconds} segundos"
            else
                formatted_time="${seconds} segundos"
            fi

            echo ">>> Tempo total de execução para $config_name: $formatted_time" | tee -a "$LOG_FILE" >> "$GERAL_LOG"

            echo "$config_name" >> "$DONE_FILE"
            echo ">>> Concluído: $config_name" | tee -a "$GERAL_LOG"
            echo "-----------------------------------" | tee -a "$GERAL_LOG"
        done
    done

    echo ">>> Todas as execuções com MAX_FRAMES=$MAX_FRAMES concluídas." | tee -a "$GERAL_LOG"
    echo "==========================================" | tee -a "$GERAL_LOG"
done

echo "Todos os experimentos foram executados com todos os valores de MAX_FRAMES!"
