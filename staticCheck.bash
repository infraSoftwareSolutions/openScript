ccheck_lib() {
    local include_dir="$1"
    local target_dir="$2"

    cppcheck \
        --std=c11 \
        --enable=warning,style,performance,portability \
        -I "$include_dir" \
        --suppress=unusedFunction \
        --suppress=missingInclude \
        --suppress=missingIncludeSystem \
        "$target_dir"
}

cxxcheck_lib() {
    local include_dir="$1"
    local target_dir="$2"

    cppcheck \
        --std=c++20 \
        --enable=warning,style,performance,portability \
        -I "$include_dir" \
        --suppress=unusedFunction \
        --suppress=missingInclude \
        --suppress=missingIncludeSystem \
        "$target_dir"
}

cppcheck_lib() {
    local includes="$1"
    local target="$2"

    local IARGS=()
    for dir in $includes; do
        IARGS+=(-I "$dir")
    done

    cppcheck \
        --std=c++20 \
        --enable=warning,style,performance,portability \
        "${IARGS[@]}" \
        --suppress=unusedFunction \
        --suppress=missingInclude \
        --suppress=missingIncludeSystem \
        "$target"
}