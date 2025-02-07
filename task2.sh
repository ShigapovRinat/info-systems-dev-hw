#!/bin/bash

# Функция для вывода содержимого стеков
print_stacks() {
    local max_height=8
    for ((i = max_height - 1; i >= 0; i--)); do
        printf "|%s|  |%s|  |%s|\n" \
            "${stack_A[i]:- }" \
            "${stack_B[i]:- }" \
            "${stack_C[i]:- }"
    done
    echo "+-+  +-+  +-+"
    echo " A    B    C"
}

# Функция для проверки победы
check_victory() {
    local target=(8 7 6 5 4 3 2 1)
    if [[ "${stack_B[*]}" == "${target[*]}" || "${stack_C[*]}" == "${target[*]}" ]]; then
        echo "🎉 Победа! Все диски успешно перенесены. 🎉"
        exit 0
    fi
}

# Инициализация стеков
stack_A=(8 7 6 5 4 3 2 1)
stack_B=()
stack_C=()

# Номер текущего хода
move_count=0

# Обработка сигнала SIGINT
trap 'echo "Завершить игру можно, введя q или Q";' SIGINT

# Основной цикл игры
while true; do
    # Увеличение номера хода
    move_count=$((move_count + 1))

    # Вывод состояния стеков
    echo "Ход № $move_count:"
    print_stacks

    # Запрос действия от пользователя
    read -p "Введите действие (например, A B или q/Q для выхода): " input

    # Проверка на выход
    if [[ "$input" == "q" || "$input" == "Q" ]]; then
        echo "Выход из игры. До встречи!"
        exit 0
    fi

    # Разделение введенных данных
    from=${input:0:1}
    to=${input: -1}

    # Преобразование букв в заглавные
    from=$(echo "$from" | tr '[:lower:]' '[:upper:]')
    to=$(echo "$to" | tr '[:lower:]' '[:upper:]')

    # Проверка корректности ввода
    if [[ -z "$from" || -z "$to" || "$from" == "$to" || ! "$from" =~ [ABC] || ! "$to" =~ [ABC] ]]; then
        echo "❌ Ошибка: введите два разных стека (A, B, C) или q/Q для выхода."
        continue
    fi

    # Определение массива-источника
    case "$from" in
        A) from_stack="stack_A" ;;
        😎 from_stack="stack_B" ;;
        C) from_stack="stack_C" ;;
    esac

    # Определение массива-получателя
    case "$to" in
        A) to_stack="stack_A" ;;
        😎 to_stack="stack_B" ;;
        C) to_stack="stack_C" ;;
    esac

    # Проверка, что стек-отправитель не пуст
    eval "from_size=\${#$from_stack[@]}"
    if [[ "$from_size" -eq 0 ]]; then
        echo "❌ Ошибка: стек $from пуст. Выберите другой."
        continue
    fi

    # Получение верхнего элемента стека-отправителя (правильный способ)
    eval "top_from=\${$from_stack[@]: -1}"

    # Проверка, что `top_from` получен корректно
    if [[ -z "$top_from" ]]; then
        echo "❌ Ошибка: невозможно извлечь диск из стека $from."
        continue
    fi

    # Получение верхнего элемента стека-получателя (или 0, если пуст)
    eval "to_size=\${#$to_stack[@]}"
    if [[ "$to_size" -eq 0 ]]; then
        top_to=0
    else
        eval "top_to=\${$to_stack[@]: -1}"
    fi

    # Проверка правила: нельзя положить большее число на меньшее
    if [[ "$top_from" -gt "$top_to" && "$top_to" -ne 0 ]]; then
        echo "🚫 Такое перемещение запрещено! Нельзя класть большой диск на маленький."
        continue
    fi

    # Удаление элемента из стека-отправителя
    eval "$from_stack=(\"\${$from_stack[@]:0:$(($from_size - 1))}\")"

    # Добавление элемента в стек-получатель
    eval "$to_stack+=(\"$top_from\")"

    # Проверка победы
    check_victory
done
