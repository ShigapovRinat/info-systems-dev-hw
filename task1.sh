#!/bin/bash

# Функция для генерации случайного 4-значного числа с неповторяющимися цифрами
generate_secret_number() {
    while true; do
        secret=$(printf "%04d" $(( RANDOM % 10000 )))
        if [[ $(echo "$secret" | grep -o . | sort | uniq | wc -l) -eq 4 ]]; then
            echo "$secret"
            return
        fi
    done
}

# Функция для проверки корректности введенного числа
is_valid_number() {
    local number="$1"
    if [[ ${#number} -ne 4 || ! "$number" =~ ^[0-9]+$ || $(echo "$number" | grep -o . | sort | uniq | wc -l) -ne 4 ]]; then
        return 1
    fi
    return 0
}

# Функция для подсчета быков и коров
count_bulls_and_cows() {
    local secret="$1"
    local guess="$2"
    local bulls=0
    local cows=0

    for (( i=0; i<4; i++ )); do
        if [[ "${guess:$i:1}" == "${secret:$i:1}" ]]; then
            ((bulls++))
        elif [[ "$secret" == *"${guess:$i:1}"* ]]; then
            ((cows++))
        fi
    done

    echo "$bulls $cows"
}

# Обработка сигнала SIGINT
trap 'echo "Завершить игру можно, введя q или Q";' SIGINT

# Генерация загаданного числа
secret_number=$(generate_secret_number)

# Инициализация переменных
moves=()
move_count=0

# Основной цикл игры
while true; do
    # Вывод истории ходов
    echo "История ходов:"
    for move in "${moves[@]}"; do
        echo "$move"
    done
    echo ""

    # Запрос числа от пользователя
    read -p "Введите 4-значное число с неповторяющимися цифрами (или q/Q для выхода): " user_input

    # Проверка на выход
    if [[ "$user_input" == "q" || "$user_input" == "Q" ]]; then
        exit 1
    fi

    # Проверка корректности ввода
    if ! is_valid_number "$user_input"; then
        echo "Ошибка: введите корректное 4-значное число с неповторяющимися цифрами."
        continue
    fi

    # Подсчет быков и коров
    result=$(count_bulls_and_cows "$secret_number" "$user_input")
    bulls=$(echo "$result" | cut -d ' ' -f1)
    cows=$(echo "$result" | cut -d ' ' -f2)

    # Добавление хода в историю
    move_count=$((move_count + 1))
    moves+=("$move_count: $user_input -> Быки: $bulls, Коровы: $cows")

    # Проверка на победу
    if [[ $bulls -eq 4 ]]; then
        echo "Вы угадали число! Загаданное число было: $secret_number"
        exit 0
    fi
done
